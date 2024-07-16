import {
  IntrospectedStructure,
  TransformConfig,
  calculateIncludedTables,
  introspectDatabaseV3,
  withDbClient,
} from '@snaplet/sdk/cli'
import { setupSubsettingContext, subsetV3 } from '../index.js'
import { SubsetConfig, IntrospectConfig } from '@snaplet/sdk/cli'
import { dumpTablesToCSV } from './dumpTablesToCSV.js'
import { getSnapshotPaths } from '../../paths.js'
import { SnapshotCaptureEventEmitter } from './events.js'
import {
  createSubsettingStorageV3,
  readSubsettingStorageV3,
} from '../storage/sqlite/index.js'
import path from 'path'
import { PgSnapshotConnection, getPgSnapshotId } from '../lib/pgSnapshot.js'

function getTablesColumnsToNullate(
  tables: IntrospectedStructure['tables'],
  subsetStorage: ReturnType<typeof createSubsettingStorageV3>
) {
  const toNullate: Map<string, Set<string>> = new Map()
  for (const table of tables) {
    const columnsToNullate = subsetStorage.getColumnsToNullate(table.id)
    toNullate.set(table.id, columnsToNullate)
  }
  return toNullate
}

// Run only the subsetting and extract the result in a .sqlite file
// used for the subset command
async function runSubsetV3(
  connString: string,
  emitter: SnapshotCaptureEventEmitter,
  options: {
    subsetFilePath: string
    tablesToCopy: ReturnType<typeof calculateIncludedTables>
    subsetConfig: SubsetConfig
    introspectConfig: IntrospectConfig
  }
) {
  return await withDbClient(
    async (client) => {
      const { pgSnapshotId, transactionEnd } = await getPgSnapshotId(client)
      try {
        const { tablesToCopy, subsetConfig, introspectConfig } = options
        const structure = await introspectDatabaseV3(client, introspectConfig)
        const toCopy = structure.tables.filter((t) => {
          return tablesToCopy.some((tt) => `${tt.schema}.${tt.name}` === t.id)
        })
        const subsetStorage = createSubsettingStorageV3(options.subsetFilePath)
        await subsetV3({ client, connString, pgSnapshotId }, emitter, {
          storage: subsetStorage,
          structure,
          subsetConfig,
          tablesToCopy: toCopy,
        })
        subsetStorage.close()
      } finally {
        await transactionEnd()
      }
    },
    { connString }
  )
}

// Run the all process of subsetting + capture
async function runSubsetAndCaptureV3(
  connString: string,
  emitter: SnapshotCaptureEventEmitter,
  options: {
    tablesToCopy: ReturnType<typeof calculateIncludedTables>
    subsetConfig: SubsetConfig
    transform: TransformConfig
    introspectConfig: IntrospectConfig
    paths: Awaited<ReturnType<typeof getSnapshotPaths>>
  }
) {
  return await withDbClient(
    async (client) => {
      const { tablesToCopy, subsetConfig, transform, paths, introspectConfig } =
        options
      const structure = await introspectDatabaseV3(client, introspectConfig)
      const toCopy = structure.tables.filter((t) => {
        return tablesToCopy.some((tt) => `${tt.schema}.${tt.name}` === t.id)
      })
      const subsetStorage = createSubsettingStorageV3(
        path.join(paths.base, 'subset.sqlite')
      )
      const { pgSnapshotId, transactionEnd } = await getPgSnapshotId(client)
      const snapshotedConnection: PgSnapshotConnection = {
        pgSnapshotId,
        connString,
        client,
      }
      try {
        await subsetV3(snapshotedConnection, emitter, {
          storage: subsetStorage,
          structure,
          subsetConfig,
          tablesToCopy: toCopy,
        })
      } finally {
        // If the transactional capture is disabled we end the transaction as soon as we can
        // after the subset and capture without transaction id
        if (process.env.SNAPLET_DISABLE_TRANSACTIONAL_CAPTURE) {
          snapshotedConnection.pgSnapshotId = undefined
          await transactionEnd()
        }
      }
      try {
        const toNullate = getTablesColumnsToNullate(toCopy, subsetStorage)
        return await dumpTablesToCSV(snapshotedConnection, emitter, {
          tablesToCopy: toCopy,
          transform,
          storageBasedir: paths.tables,
          subsetOptions: {
            subsetStorage: subsetStorage,
            keepDisconnectedTables: Boolean(
              subsetConfig.keepDisconnectedTables
            ),
            toNullateColumns: toNullate,
          },
        })
      } finally {
        // If the transactional capture is not disabled then we need to end the transaction at the end of the capture process
        if (!process.env.SNAPLET_DISABLE_TRANSACTIONAL_CAPTURE) {
          await transactionEnd()
        }
        subsetStorage.close()
      }
    },
    { connString }
  )
}

// Run only the capture process with a pre-existing subset file
async function runCaptureV3(
  connString: string,
  emitter: SnapshotCaptureEventEmitter,
  options: {
    storagePath: string
    subsetConfig: SubsetConfig
    transform: TransformConfig
    introspectConfig: IntrospectConfig
    paths: Awaited<ReturnType<typeof getSnapshotPaths>>
  }
) {
  return await withDbClient(
    async (client) => {
      const { subsetConfig, transform, paths, introspectConfig } = options
      const structure = await introspectDatabaseV3(client, introspectConfig)
      const subsetStorage = readSubsettingStorageV3(options.storagePath)
      const toCopy = structure.tables.filter((t) => subsetStorage.has(t.id))
      emitter.emit('subsetEnd')
      const toNullate = getTablesColumnsToNullate(toCopy, subsetStorage)
      const { pgSnapshotId, transactionEnd } = await getPgSnapshotId(client)
      const snapshotedConnection: PgSnapshotConnection = {
        pgSnapshotId,
        connString,
        client,
      }
      // If the transactional capture is disabled we end the transaction as soon as we can
      if (process.env.SNAPLET_DISABLE_TRANSACTIONAL_CAPTURE) {
        await transactionEnd()
        snapshotedConnection.pgSnapshotId = undefined
      }
      try {
        return await dumpTablesToCSV(snapshotedConnection, emitter, {
          tablesToCopy: toCopy,
          transform,
          storageBasedir: paths.tables,
          subsetOptions: {
            subsetStorage: subsetStorage,
            keepDisconnectedTables: Boolean(
              subsetConfig.keepDisconnectedTables
            ),
            toNullateColumns: toNullate,
          },
        })
      } finally {
        if (!process.env.SNAPLET_DISABLE_TRANSACTIONAL_CAPTURE) {
          await transactionEnd()
        }
        subsetStorage.close()
      }
    },
    { connString }
  )
}

// Run only the capture process for all tables without any subset file
export async function runOnlyCaptureV3(
  connString: string,
  emitter: SnapshotCaptureEventEmitter,
  options: {
    tablesToCopy: ReturnType<typeof calculateIncludedTables>
    transform: TransformConfig
    paths: Awaited<ReturnType<typeof getSnapshotPaths>>
  }
) {
  return await withDbClient(
    async (client) => {
      const { transform, paths } = options
      const structure = await introspectDatabaseV3(client)
      const toCopy = structure.tables.filter((t) => {
        return options.tablesToCopy.some(
          (tt) => `${tt.schema}.${tt.name}` === t.id
        )
      })
      // Create a dummy empty storage to pass to the capture process
      const subsetStorage = createSubsettingStorageV3(
        path.join(paths.base, 'dummy.sqlite')
      )
      const subsettingContext = {
        tables: new Map(),
        tasks: [],
        client,
        storage: subsetStorage,
        visitedTables: new Set<string>(),
        currentSubsetdRows: 0,
      }

      setupSubsettingContext(
        subsettingContext,
        toCopy,
        // Mark all tables as disconnected since there is no targets
        new Set(toCopy.map((t) => t.id)),
        true,
        true
      )
      emitter.emit('subsetEnd')
      emitter.emit('dumpTablesStart', {
        totalRowsToCopy: 1,
      })
      const { pgSnapshotId, transactionEnd } = await getPgSnapshotId(client)
      const snapshotedConnection: PgSnapshotConnection = {
        pgSnapshotId,
        connString,
        client,
      }
      // If the transactional capture is disabled we end the transaction as soon as we can
      if (process.env.SNAPLET_DISABLE_TRANSACTIONAL_CAPTURE) {
        await transactionEnd()
        snapshotedConnection.pgSnapshotId = undefined
      }
      try {
        return await dumpTablesToCSV(snapshotedConnection, emitter, {
          tablesToCopy: toCopy,
          transform,
          storageBasedir: paths.tables,
          subsetOptions: {
            subsetStorage: subsetStorage,
            // Use the keepDisconnectedTable with empty subset storage to capture all tables
            keepDisconnectedTables: true,
            toNullateColumns: new Map(),
          },
        })
      } finally {
        if (!process.env.SNAPLET_DISABLE_TRANSACTIONAL_CAPTURE) {
          await transactionEnd()
        }
        subsetStorage.close()
      }
    },
    { connString }
  )
}

export { runSubsetAndCaptureV3, runCaptureV3, runSubsetV3 }
