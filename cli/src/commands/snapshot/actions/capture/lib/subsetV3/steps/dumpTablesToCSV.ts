import { TransformConfig, SnapshotTable } from '@snaplet/sdk/cli'
import fs from 'fs'

import path from 'path'

import { PgCopyTableOptions, pgCopyTable } from './pgCopyTable.js'
import { getSentry } from '~/lib/sentry.js'
import { Table } from '../lib/types.js'

import { SubsetOptions } from './queryTableStream.js'
import { SnapshotCaptureEventEmitter } from './events.js'
import { SubsettingStorage } from '../storage/types.js'
import { PgSnapshotConnection } from '../lib/pgSnapshot.js'
import { xdebugCapture } from '../../debugCapture.js'

type CopyTableStatus = 'IN_PROGRESS' | 'FAILURE' | 'SUCCESS'

type CopiedTable = Pick<Table, 'schema' | 'name' | 'id' | 'bytes' | 'rows'>
interface BaseCopyTableEvent extends CopiedTable {
  status: CopyTableStatus
}

interface CopyTableCount {
  // Will take into account the subset configuration
  totalRowsToCopy: number
  // Number of rows who has currently been copied into the .csv file
  currentCopiedRows: number
  // The time it took to dump the currentCopiedRows from source database to our csv file
  timeToDump: number
  // The time we spent compressing the csv file
  timeToCompress: number
}

type CopyTableStatusSpecific = {
  [K in CopyTableStatus]: { status: K }
}

type CopyTableStartedEvent = BaseCopyTableEvent &
  CopyTableCount &
  CopyTableStatusSpecific['IN_PROGRESS']
type CopyTableSuccessEvent = BaseCopyTableEvent &
  CopyTableCount &
  CopyTableStatusSpecific['SUCCESS']
type CopyTableFailureEvent = BaseCopyTableEvent &
  Partial<CopyTableCount> &
  CopyTableStatusSpecific['FAILURE'] & {
    error: Error
  }

type CopyTableEvent =
  | CopyTableStartedEvent
  | CopyTableSuccessEvent
  | CopyTableFailureEvent

interface CopyTablesEvent {
  status: CopyTableStatus
  // The total number of rows to copy accross all tables
  totalRowsToCopy: number
  // The total number of rows who has currently been successfully copied/compressed into the .csv file accross all tables
  totalCurrentCopiedRows: number
  // The total time we spent dumping the rows from source database to our csv file accross all tables
  totalDumpTime: number
  // The total time we spent compressing the csv file accross all tables
  totalCompressTime: number
  details: Array<CopyTableEvent>
}

type TableId = string

type CopyTablesCount = Pick<CopyTablesEvent, 'totalRowsToCopy'> & {
  tablesCount: Map<TableId, Pick<CopyTableCount, 'totalRowsToCopy'>>
  disconnectedTables: Set<TableId>
}

function computeCopyTablesCount(
  tables: CopyTablesOptions['tablesToCopy'],
  subsetStorage: Pick<SubsettingStorage, 'countIds' | 'has'>,
  keepDisconnectedTables: boolean
): CopyTablesCount {
  const result = {
    totalRowsToCopy: 0,
    tablesCount: new Map(),
    disconnectedTables: new Set(),
  } as CopyTablesCount
  for (const table of tables) {
    // If we want to keep disconnected table and the table is not in the subsetStorage
    // it means it's disconnected from the graph of the initial targets
    if (keepDisconnectedTables && subsetStorage.has(table.id) === false) {
      const isEmpty = table.bytes === 0 && table.rows === 0
      // If the table is empty for sure, we can skip it
      // otherwise if it's not vacuumed (rows === null) or has been vacuumed with no rows (rows === 0)
      // we can assume it has at least 1 row
      const estimateRowsToCopy = isEmpty ? 0 : table.rows ? table.rows : 1
      result.totalRowsToCopy += estimateRowsToCopy
      result.tablesCount.set(table.id, {
        totalRowsToCopy: estimateRowsToCopy,
      })
      result.disconnectedTables.add(table.id)
    } else {
      const tableSubsetIds = subsetStorage.countIds(table.id)
      result.totalRowsToCopy += tableSubsetIds
      result.tablesCount.set(table.id, {
        totalRowsToCopy: tableSubsetIds,
      })
    }
  }
  xdebugCapture('computeCopyTablesCount result: ')
  xdebugCapture('totalRowsToCopy: ', result.totalRowsToCopy)
  xdebugCapture('disconnectedTables: ', Array.from(result.disconnectedTables))
  xdebugCapture('tablesCount: ', Object.fromEntries(result.tablesCount))
  return result
}

type CopyTableDataOptions = {
  table: PgCopyTableOptions['table']
  // Where the .csv or .csv.br for the table file will be saved
  storageBasedir: string
  transform: TransformConfig
  subsetStorage: SubsettingStorage
  // The number of rows to copy for this table should be equal to subsetIds.length or table.rows
  // depending on the subset configuration keepDisconnectedTables value
  rowsToCopy: number
  // The name of the columns to nullate for this table
  columnsToNullate: Set<string>
}

async function copyTableData(
  connection: PgSnapshotConnection,
  emitter: SnapshotCaptureEventEmitter,
  {
    storageBasedir,
    table,
    transform,
    subsetStorage,
    rowsToCopy,
    columnsToNullate,
  }: CopyTableDataOptions
): Promise<SnapshotTable & { timeToCompress: number; copiedRows: number }> {
  const subsetOptions: SubsetOptions = {
    storage: subsetStorage,
    rowsToCopy,
    columnsToNullate,
  }
  const csvPath = path.join(storageBasedir, `${table.id}.csv`)
  const writer = fs.createWriteStream(csvPath)
  const shouldDumpAllTable =
    subsetOptions.storage.countIds(table.id) < rowsToCopy
  xdebugCapture(`copyTableData:
    table: ${table.id}
    rowsToCopy: ${rowsToCopy}
    columnsToNullate: ${Array.from(columnsToNullate)}
    shouldDumpAllTable: ${shouldDumpAllTable}
  `)
  const { ms: timeToDump, rows } = await pgCopyTable(connection, emitter, {
    table,
    writer,
    transform,
    subsetOptions,
    dumpAllTable: shouldDumpAllTable,
  })
  xdebugCapture('pgCopyTable result: ', { timeToDump, rows })

  return {
    schema: table.schema,
    table: table.name,
    filename: path.basename(csvPath),
    timeToDump: timeToDump,
    timeToCompress: 0,
    copiedRows: rows,
    bytes: rows > 0 ? fs.statSync(csvPath).size : 0,
  }
}

type CopyTablesOptions = {
  // Will always be the full list of tables to copy according
  // to the ones selected to be excluded or included and the schemas allowed
  tablesToCopy: Array<
    CopyTableDataOptions['table'] & Pick<Table, 'rows' | 'bytes'>
  >
  subsetOptions: {
    subsetStorage: SubsettingStorage
    keepDisconnectedTables: boolean
    toNullateColumns: Map<TableId, Set<string>>
  }
} & Pick<CopyTableDataOptions, 'storageBasedir' | 'transform'>

/**
 * This task fetches the list of tables that need to be captured.
 * It iterates over each table, copies the rows, compresses them,
 * and returns a list of copied files.
 */
export async function dumpTablesToCSV(
  connection: PgSnapshotConnection,
  emitter: SnapshotCaptureEventEmitter,
  {
    tablesToCopy,
    transform,
    storageBasedir,
    subsetOptions: { subsetStorage, keepDisconnectedTables, toNullateColumns },
  }: CopyTablesOptions
): Promise<SnapshotTable[]> {
  const Sentry = await getSentry()
  const files: SnapshotTable[] = []
  const rowsToCopyCount = computeCopyTablesCount(
    tablesToCopy,
    subsetStorage,
    keepDisconnectedTables
  )
  const dumptTablesTransaction = Sentry.startTransaction({
    name: 'dumpTablesToCSV',
    data: {
      totalRowsToCopy: rowsToCopyCount.totalRowsToCopy,
    },
  })
  emitter.emit('dumpTablesStart', {
    totalRowsToCopy: rowsToCopyCount.totalRowsToCopy,
  })
  try {
    for (const table of tablesToCopy) {
      const rowsToCopy = rowsToCopyCount.tablesCount.get(
        table.id
      )!.totalRowsToCopy
      emitter.emit('copyTableStart', {
        tableName: table.name,
        schema: table.schema,
        totalRowsToCopy: rowsToCopy,
      })
      try {
        const file = await copyTableData(connection, emitter, {
          storageBasedir,
          table,
          transform,
          subsetStorage,
          rowsToCopy,
          columnsToNullate: toNullateColumns.get(table.id) ?? new Set(),
        })
        files.push(file)
        emitter.emit('copyTableEnd', {
          status: 'SUCCESS',
          schema: table.schema,
          tableName: table.name,
          timeToDump: file.timeToDump ?? 0,
          timeToCompress: file.timeToCompress ?? 0,
          rowsDumped: file.copiedRows,
        })
      } catch (e: any) {
        emitter.emit('copyTableEnd', {
          error: e,
          schema: table.schema,
          tableName: table.name,
          status: 'FAILURE',
        })
        // In the case of this pg core level error, we want to log on sentry additional details about
        // user current configuration to understand better why the connection interrupted
        if ((e as Error).message === 'Connection terminated unexpectedly') {
          const Sentry = await getSentry()
          Sentry.captureException(e)
        }
      }
    }
  } finally {
    emitter.emit('dumpTablesEnd')
  }
  dumptTablesTransaction.finish()
  return files
}
