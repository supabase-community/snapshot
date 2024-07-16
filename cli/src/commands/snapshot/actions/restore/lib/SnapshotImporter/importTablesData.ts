import {
  decompressAndDecrypt,
  decompressTable,
  SnapshotTable,
  MAX_POOL_SIZE,
  EncryptionPayload,
  withDbClient,
  execQueryNext,
  buildSchemaExclusionClause,
  escapeIdentifier,
} from '@snaplet/sdk/cli'
import pMap from 'p-map'
import firstline from 'firstline'
import fs from 'fs'
import { pathExists, unlink } from 'fs-extra'
import path from 'path'
import { DatabaseError } from 'pg'
import { from } from 'pg-copy-streams'
import createProgressStream from 'progress-stream'
import { pipeline as nodePipeline } from 'stream'
import type TypedEmitter from '~/lib/typed-emitter.js'
import { promisify } from 'util'
import { stringify as csvStringify } from 'csv-stringify'

import SnapshotCache from '../SnapshotCache.js'
import { readNthLine } from '../readNthLine.js'
import { RestoreContext, RestoreError } from '../restoreError.js'
import { parse as csvParse } from 'csv-parse'
import { groupBy } from 'lodash'

const pipeline = promisify(nodePipeline)

export type ImportTablesDataEvents = {
  'importTablesData:start': (payload: {
    schema: string
    table: string
    totalDataSize: number
  }) => void
  'importTablesData:update': (payload: {
    schema: string
    table: string
    totalDataSize: number
    totalDataRead: number
  }) => void
  'importTablesData:complete': () => void
  'importTablesData:error': (payload: {
    error: Error
    schema: string
    table: string
  }) => void
}

type ImportTableContext = {
  cache: SnapshotCache
  connString: string
  eventEmitter: TypedEmitter<ImportTablesDataEvents>
  encryptionPayload?: EncryptionPayload
}

export async function getSnapshotColumns(csvPath: string): Promise<string[]> {
  const firstLine = await firstline(csvPath)
  return new Promise((resolve, reject) => {
    csvParse(firstLine, {}, (err, output) => {
      if (err) {
        reject(err)
        return
      }
      // The output is an array of arrays, but we only have one row, so take the first one
      resolve(output[0])
    })
  })
}

async function getTablePath(
  ctx: { cache: SnapshotCache },
  schema: string,
  table: string
) {
  const csvName = schema + '.' + table + '.csv'
  const zipName = csvName + '.br'
  const csvPath = path.join(ctx.cache.paths.tables, csvName)
  const zipPath = path.join(ctx.cache.paths.tables, zipName)
  let compressed = false

  if (!fs.existsSync(csvPath) && !fs.existsSync(zipPath)) {
    throw new Error('Cannot determine cache path for ' + schema + '.' + table)
  }

  if (fs.existsSync(zipPath)) {
    compressed = true
  }

  return { csvPath, zipPath, compressed }
}

async function prepareSnapshotTableFile(
  ctx: Pick<ImportTableContext, 'encryptionPayload'>,
  filePath: Awaited<ReturnType<typeof getTablePath>>
) {
  if (!fs.existsSync(filePath.csvPath)) {
    if (filePath.compressed) {
      if (ctx.encryptionPayload) {
        await decompressAndDecrypt(
          filePath.zipPath,
          filePath.csvPath,
          ctx.encryptionPayload
        )
      } else {
        await decompressTable(filePath.zipPath, filePath.csvPath)
      }
    }
  }
}

async function importFullTableData(
  ctx: ImportTableContext,
  schema: string,
  tableName: string
) {
  await withDbClient(
    async (client) => {
      const filePath = await getTablePath(
        { cache: ctx.cache },
        schema,
        tableName
      )
      try {
        await prepareSnapshotTableFile(ctx, filePath)
        const insertableColumns = await getSnapshotColumns(filePath.csvPath)
        if (insertableColumns.length == 0) {
          return
        }
        const restoreContext: RestoreContext = {
          filePath: filePath.csvPath,
          columns: insertableColumns,
          schema,
          table: tableName,
        }
        const readerStream = fs.createReadStream(filePath.csvPath)
        const { size: totalDataSize } = fs.statSync(filePath.csvPath)

        const progressStream = createProgressStream({
          length: totalDataSize,
          time: 100,
        })
        const identifier = `${client.escapeIdentifier(
          schema
        )}.${client.escapeIdentifier(tableName)}`
        const columnList = insertableColumns
          .map((c) => client.escapeIdentifier(c))
          .join(',')
        const { handlePipelineError } = setupImportTableEvents(
          ctx,
          restoreContext,
          progressStream,
          totalDataSize
        )
        ctx.eventEmitter.emit('importTablesData:start', {
          schema,
          table: tableName,
          totalDataSize,
        })
        const writerStream = client.query(
          from(`COPY ${identifier}(${columnList}) FROM stdin CSV HEADER`)
        )
        await pipeline(readerStream, progressStream, writerStream).catch(
          handlePipelineError
        )
      } catch (error: any) {
        ctx.eventEmitter.emit('importTablesData:error', {
          schema,
          table: tableName,
          error,
        })
      } finally {
        if (filePath.compressed && (await pathExists(filePath.csvPath))) {
          await unlink(filePath.csvPath)
        }
        ctx.eventEmitter.emit('importTablesData:complete')
      }
    },
    { connString: ctx.connString }
  )
}

async function fetchTargetDatabaseColumns(connString: string) {
  const results = await execQueryNext<{
    tableId: string
    name: string
  }>(
    `
    SELECT
      concat(columns.table_schema, '.', columns.table_name) AS "tableId",
      "column_name" AS "name"
    FROM information_schema.columns
    WHERE  ${buildSchemaExclusionClause('table_schema')} AND
      -- We don't want to import columns that are generated by the database as they are excluded from the snapshot anyway
      is_generated = 'NEVER'
  `,
    connString
  )
  return results.rows
}

function setupImportTableEvents(
  ctx: Pick<ImportTableContext, 'eventEmitter'>,
  restoreContext: RestoreContext,
  progressStream: ReturnType<typeof createProgressStream>,
  totalDataSize: number
) {
  progressStream.on('progress', (progress) => {
    ctx.eventEmitter.emit('importTablesData:update', {
      schema: restoreContext.schema,
      table: restoreContext.table,
      totalDataSize,
      totalDataRead: progress.transferred,
    })
  })

  const handlePipelineError = async (error: Error) => {
    if (error instanceof DatabaseError && error.where) {
      const result = /^COPY.+, line (?<line>\d+)/.exec(error.where)
      if (result?.groups?.line) {
        const line = parseInt(result.groups.line) + 1
        restoreContext.row = {
          line,
          value: await readNthLine(line, restoreContext.filePath),
        }
      }
    }
    ctx.eventEmitter.emit('importTablesData:error', {
      schema: restoreContext.schema,
      table: restoreContext.table,
      error: new RestoreError(restoreContext, error.message),
    })
  }

  return { handlePipelineError }
}

function getColumnsToImportInTable(
  targetDatabaseTableColumns: { name: string }[],
  snapshotColumns: string[]
) {
  // If the table is present but the columns are different we'll filter the columns that are not present in the target database
  // and show a warning message to the user to notice him about the schema drift
  const columnsToImport: string[] = []
  const columnsToSkip: string[] = []
  for (const column of snapshotColumns) {
    // if the column is present in the target database we'll add it to the list of columns to import for this table
    if (targetDatabaseTableColumns.findIndex((c) => c.name === column) > -1) {
      columnsToImport.push(column)
    } else {
      // if the column is not present in the target database we'll add it to the list of columns to skip for this table
      columnsToSkip.push(column)
    }
  }
  return {
    columnsToImport,
    columnsToSkip,
  }
}

const pickColumns = (insertableColumns: string[]) =>
  async function* pickColumnsGen(
    source: AsyncIterable<Record<string, unknown>>
  ) {
    for await (const row of source) {
      yield insertableColumns.map((c) => row[c])
    }
  }

// In some cases, we only want to import a subset of the data from the snapshot into the table
// This is used when restoring a table in a target database that have less columns than the snapshot we're trying to restore
// This is partically useful in the case of supabase restoration when the user use --no-reset and --no-schema options
async function importPartialTableData(
  ctx: ImportTableContext,
  schema: string,
  tableName: string,
  targetDatabaseTableColumns: { name: string }[]
) {
  await withDbClient(
    async (client) => {
      const filePath = await getTablePath(
        { cache: ctx.cache },
        schema,
        tableName
      )
      try {
        await prepareSnapshotTableFile(ctx, filePath)
        const snapshotTableColumns = await getSnapshotColumns(filePath.csvPath)
        const { columnsToImport, columnsToSkip } = getColumnsToImportInTable(
          targetDatabaseTableColumns,
          snapshotTableColumns
        )
        // If there is no columns to import we can skip the table but we still warn the user as it's likely an issue
        if (columnsToImport.length == 0) {
          console.log(
            `⚠️  The table ${schema}.${tableName} has no data that can be imported to the target database`
          )
          return
        }
        // If there is no columns to skip we can import the whole table and avoid parsing and stringifying each line of the csv
        if (columnsToSkip.length == 0) {
          // This must be awaited before the return, otherwise the finally clause will be executed before the import is complete, and will delete the extracted csv
          await importFullTableData(ctx, schema, tableName)
          return
        }
        // If there is columns to skip we'll show a warning message to the user to notice him about the schema drift
        if (columnsToSkip.length > 0) {
          console.log(
            `⚠️  The table ${schema}.${tableName} has a schema drift. The following columns are not present in the target database: [${columnsToSkip
              .map(escapeIdentifier)
              .join(
                ', '
              )}] but are present in the snapshot we will skip them and perform a partial restore.`
          )
        }
        const restoreContext: RestoreContext = {
          filePath: filePath.csvPath,
          columns: columnsToImport,
          schema,
          table: tableName,
        }
        const readerStream = fs.createReadStream(filePath.csvPath)
        const { size: totalDataSize } = fs.statSync(filePath.csvPath)
        const progressStream = createProgressStream({
          length: totalDataSize,
          time: 100,
        })
        const identifier = `${escapeIdentifier(schema)}.${escapeIdentifier(
          tableName
        )}`
        const columnList = columnsToImport
          .map((c) => escapeIdentifier(c))
          .join(',')
        const { handlePipelineError } = setupImportTableEvents(
          ctx,
          restoreContext,
          progressStream,
          totalDataSize
        )
        ctx.eventEmitter.emit('importTablesData:start', {
          schema,
          table: tableName,
          totalDataSize,
        })
        const csvFilterStream = pickColumns(columnsToImport)
        const writerStream = client.query(
          from(`COPY ${identifier}(${columnList}) FROM stdin CSV`)
        )
        const parseStream = csvParse({
          columns: true,
          cast: (value, { quoting }) =>
            value === '' && !quoting ? null : value,
        })
        const stringifyStream = csvStringify({
          columns: columnsToImport,
          header: false,
          quoted_match: /\r|^$/,
          record_delimiter: 'unix',
        })
        await pipeline(
          readerStream,
          progressStream,
          parseStream,
          csvFilterStream,
          stringifyStream,
          writerStream
        ).catch(handlePipelineError)
      } catch (error: any) {
        ctx.eventEmitter.emit('importTablesData:error', {
          schema,
          table: tableName,
          error,
        })
      } finally {
        if (filePath.compressed && (await pathExists(filePath.csvPath))) {
          await unlink(filePath.csvPath)
        }
        ctx.eventEmitter.emit('importTablesData:complete')
      }
    },
    { connString: ctx.connString }
  )
}

export async function importTablesData(
  ctx: ImportTableContext,
  tables: SnapshotTable[],
  partialRestore: boolean
) {
  const nonEmptyTables = tables
    // We only want to import tables that have data
    .filter((t) => Number(t.bytes) > 1)
  // If the user is using either --no-reset or --no-schema, we need to import the data in a different way
  // this is due to the fact that the target database might have less columns than the snapshot we're trying to restore
  if (partialRestore === false) {
    const tablesParameters = nonEmptyTables.map(({ schema, table }) => ({
      ctx,
      schema,
      tableName: table,
    }))
    await pMap(
      tablesParameters,
      (params) =>
        importFullTableData(params.ctx, params.schema, params.tableName),
      {
        // TODO: make this user configurable
        concurrency: MAX_POOL_SIZE - 1,
      }
    )
  } else {
    // We will do a partial restore first we want to introspect all of the current tables and columns in the target database
    const targetDatabaseColumns = await fetchTargetDatabaseColumns(
      ctx.connString
    )
    const targetDatabaseColumnsMap = groupBy(targetDatabaseColumns, 'tableId')
    const tablesParameters = nonEmptyTables.map(({ schema, table }) => ({
      ctx,
      schema,
      tableName: table,
    }))
    await pMap(
      tablesParameters,
      (params) =>
        importPartialTableData(
          params.ctx,
          params.schema,
          params.tableName,
          targetDatabaseColumnsMap[`${params.schema}.${params.tableName}`]
        ),
      {
        // TODO: make this user configurable
        concurrency: MAX_POOL_SIZE - 1,
      }
    )
  }
}
