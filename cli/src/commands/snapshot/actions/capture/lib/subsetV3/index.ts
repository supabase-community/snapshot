import {
  DatabaseClient,
  SubsetConfig,
  IntrospectedStructure,
  withDbClient,
} from '@snaplet/sdk/cli'
import type { ConfigToSQL } from './lib/configToSQL.js'
import { configToSQL } from './lib/configToSQL.js'
import { debugSubset } from './lib/debug.js'
import {
  JoinParams,
  buildConfiguredFetchQuery,
  buildReferencesFetchQuery,
  columnsToPrimaryKeys,
} from './lib/queryBuilders.js'
import type {
  Reference,
  ReferenceDirection,
  Table,
  TableSegment,
  Task,
  SubsettingTable,
} from './lib/types'
import type { SubsettingStorage } from './storage/types.js'
import { SnapshotCaptureEventEmitter } from './steps/events.js'
import {
  PgSnapshotConnection,
  setTransactionSnapshotId,
} from './lib/pgSnapshot.js'
import { streamQueryWithChunk } from './lib/queryStreamUtils.js'
import { findDisconnectedTables } from './lib/findDisconnectedTables.js'
import { getSentry } from '~/lib/sentry.js'
import { getRelationshipOption } from './lib/getRelationshipOption.js'

// After how many rows the stream will be paused
// and call the next step in the pipe before resuming
const QUERY_STREAM_HIGH_WATER_MARK = 100000

type SubsettingContext = {
  client: DatabaseClient
  tasks: Array<Task>
  tables: Map<string, SubsettingTable>
  storage: SubsettingStorage
  visitedTables: Set<string>
  currentSubsetdRows: number
}

interface SubsettingOptions {
  structure: IntrospectedStructure
  subsetConfig: SubsetConfig
  tablesToCopy: Table[]
  storage: SubsettingStorage
}

function reverseJoinParameters(source: JoinParams): JoinParams {
  return {
    fromTable: source.toTable,
    fromColumns: source.toColumns,
    toColumns: source.fromColumns,
    toTable: source.fromTable,
  }
}

// Discover starting ids from the subset config starting point
async function discoverRootTable(
  ctx: SubsettingContext,
  targetIndex: string,
  table: Pick<
    SubsettingTable,
    'id' | 'primaryKeys' | 'name' | 'schema' | 'partitioned'
  >,
  condition: ConfigToSQL
): Promise<TableSegment[] | undefined> {
  debugSubset(`Finding rows from root table ${table.id}`)
  const query = buildConfiguredFetchQuery(table, condition)
  debugSubset(`Query: ${query}`)
  await streamQueryWithChunk<string[]>(
    ctx.client,
    { text: query, rowMode: 'array' },
    (chunk) => {
      ctx.storage.insertTemp(table.id, chunk)
    },
    QUERY_STREAM_HIGH_WATER_MARK
  )
  const commitResult = ctx.storage.commitTemp(table.id)
  debugSubset(
    `Found ${commitResult.foundIds} rows (${commitResult.newIds} new) as ${table.id}`
  )
  ctx.currentSubsetdRows += commitResult.newIds
  return commitResult.segmentIds.map((segmentId) => ({
    originRootId: `${table.id}::${targetIndex}`,
    segmentId,
    tableId: table.id,
  }))
}

// Discover new ids for the reference
async function discoverReference(
  ctx: SubsettingContext,
  task: Task,
  reference: Reference,
  direction: ReferenceDirection
): Promise<TableSegment[] | undefined> {
  reference.currentLoop += 1
  const segment = task.segment
  const referenceTable = ctx.tables.get(reference.targetTable)!
  const toTable = ctx.tables.get(reference.fkTable)!
  let joinParameters: JoinParams = {
    fromColumns: reference.fkColumns,
    fromTable: {
      id: toTable.id,
      primaryKeys: toTable.primaryKeys,
      name: toTable.name,
      schema: toTable.schema,
      partitioned: toTable.partitioned,
    },
    toColumns: reference.targetColumns,
    toTable: {
      id: referenceTable.id,
      primaryKeys: referenceTable.primaryKeys,
      name: referenceTable.name,
      schema: referenceTable.schema,
      partitioned: referenceTable.partitioned,
    },
  }
  // If we are going from reverse relation, we'll invert the order of our join
  if (direction === 'REVERSE') {
    joinParameters = reverseJoinParameters(joinParameters)
  }
  debugSubset(
    `Reference infos: ${reference.id} currentLoop: ${reference.currentLoop} / maxCyclesLoop: ${reference.maxCyclesLoop} / maxChildrenPerNode: ${reference.maxChildrenPerNode}`
  )
  const maxChildrenPerNode =
    (reference.maxCyclesLoop &&
      reference.currentLoop > reference.maxCyclesLoop) ||
    // If we have already visited this table currently deeper than reference.maxCyclesLoop into walk of the graph tree
    (reference.maxCyclesLoop !== undefined &&
      ctx.visitedTables.has(joinParameters.toTable.id) &&
      task.step >= reference.maxCyclesLoop)
      ? 0
      : reference.maxChildrenPerNode
  // If we are currently fecthing childrens and we reached the max children per node or max cycles loop
  // we don't need to hit the user database
  if (maxChildrenPerNode === 0 && direction === 'REVERSE') {
    debugSubset(
      `Max children per node reached for ${reference.id} in reverse direction, skipping`
    )
    return
  }
  const query = buildReferencesFetchQuery(
    joinParameters,
    // If we are are currently fecthing childrens
    direction === 'REVERSE' ? maxChildrenPerNode : undefined
  )
  debugSubset(
    `Finding rows from table ${joinParameters.toTable.id} using ${
      segment.tableId
    } via ${reference.id} with limit ${
      direction === 'REVERSE' ? maxChildrenPerNode : 'none'
    }`
  )
  const rowCTIDs = ctx.storage.getSegment(segment.segmentId)
  await streamQueryWithChunk<string[]>(
    ctx.client,
    { text: query, values: [rowCTIDs], rowMode: 'array' },
    (chunk) => {
      ctx.storage.insertTemp(joinParameters.toTable.id, chunk)
    },
    QUERY_STREAM_HIGH_WATER_MARK
  )
  const commitResult = ctx.storage.commitTemp(joinParameters.toTable.id)
  debugSubset(
    `Found ${commitResult.foundIds} rows (${commitResult.newIds} new) in table ${joinParameters.toTable.id} using ${segment.tableId} via ${reference.id} from origin target ${segment.originRootId}`
  )
  ctx.currentSubsetdRows += commitResult.newIds
  if (commitResult.newIds > 0) {
    ctx.visitedTables.add(joinParameters.toTable.id)
    return commitResult.segmentIds.map((segmentId) => ({
      originRootId: task.segment.originRootId,
      segmentId,
      tableId: joinParameters.toTable.id,
    }))
  }
}

async function processReference(
  ctx: SubsettingContext,
  task: Task,
  reference: Reference,
  direction: ReferenceDirection
) {
  if (reference.directions.includes(direction) === false) {
    return
  }

  // If we are not in eager fetching mode, early leave the discovery of new ids
  // if the source of the task was coming from the same reference in the other direction (FORWARD/REVERSE)
  // Let take an example:
  //                   +-----------+
  //                   |   team    |
  //                   +-----------+
  //                   | id (PK)   |
  //                   | name      |
  //                   +-----------+
  //                         |
  //                         | (1)
  //                         |
  //                         | (N)
  //                         |
  // +-----------+           v         +-----------+
  // |   user    | -------------------> |   team    |
  // +-----------+                     +-----------+
  // | id (PK)   |                     | id (PK)   |
  // | name      |                     | name      |
  // | team_id   | <------------------ |           |
  // +-----------+                     +-----------+
  //     user: 1, 2, 3, 4, 5         ->     team: 1
  //     user: 6, 7, 8               ->     team: NULL
  // Let say we gather from the entrypoint: user IN (1, 8)
  // In "lazy" mode, we will only fetch user: (1, 8) and team (1) then stop
  // In "eager" mode, we will keep following the relationship to the end:
  // since there is others users in "team 1", we'll end up with: user: (1,2,3,4,5,8) and team (1)
  if (!reference.eager && !task.sourceReference?.eager) {
    if (direction === 'FORWARD') {
      if (
        task.sourceDirection === 'REVERSE' &&
        task.sourceReference?.id === reference.id
      ) {
        return
      }
    }
    if (direction === 'REVERSE') {
      if (
        task.sourceDirection === 'FORWARD' &&
        task.sourceReference?.id === reference.id
      ) {
        return
      }
    }
  }
  const newSegment = await discoverReference(ctx, task, reference, direction)
  // if we have found new ids via the reference relation, we add those new ids as well
  // to the queue of tables where there is more things to discover
  if (newSegment) {
    const nextStep = task.step + 1
    for (const segment of newSegment) {
      ctx.tasks.push({
        step: nextStep,
        segment,
        sourceDirection: direction,
        sourceReference: reference,
      })
    }
  }
}

async function processNextTask(ctx: SubsettingContext, task: Task) {
  const table = ctx.tables.get(task.segment.tableId)!
  for (const reference of table.parents) {
    await processReference(ctx, task, reference, 'FORWARD')
  }
  for (const reference of table.children) {
    await processReference(ctx, task, reference, 'REVERSE')
  }
}

function isValidReference(ctx: SubsettingContext, reference: Reference) {
  const targetTable = ctx.tables.get(reference.targetTable)
  const fkTable = ctx.tables.get(reference.fkTable)
  if (!targetTable || !fkTable) {
    console.log(
      `WARN: one of the table in the reference cannot be found (${reference.targetTable}::${targetTable?.id} | ${reference.fkTable}::${fkTable?.id}) this reference will be skipped`
    )
    return false
  }
  if (reference.nullable && reference.followNullable === false) {
    console.log(
      `INFO: Skipping nullable reference ${reference.id} (followNullable=false)`
    )
    return false
  }
  return true
}

export function setupSubsettingContext(
  ctx: SubsettingContext,
  tablesToCopy: Table[],
  disconnectedTables: Set<string>,
  eager: boolean,
  followNullableRelations:
    | boolean
    | Record<string, boolean | Record<string, boolean>>,
  maxChildrenPerNode?: number | Record<string, number | Record<string, number>>,
  maxCyclesLoop?: number | Record<string, number | Record<string, number>>
) {
  for (const tc of tablesToCopy) {
    if (tc.primaryKeys) {
      ctx.tables.set(tc.id, {
        ...tc,
        parents: [],
        children: [],
        primaryKeys: tc.primaryKeys,
        isDisconnected: disconnectedTables.has(tc.id),
        columnsToNullate: new Set(),
      })
    } else {
      console.log(
        `WARNING: no primary keys or unique non nullable columns or unique index found for: ${tc.id} falling back to custom composite key made of other columns instead`
      )
      const primaryKeyablesColumns = columnsToPrimaryKeys(tc.columns)
      if (primaryKeyablesColumns.keys.length === 0) {
        console.log(
          `WARNING: no indexable columns found for: ${tc.id} skipping table`
        )
      } else {
        ctx.tables.set(tc.id, {
          ...tc,
          parents: [],
          children: [],
          primaryKeys: columnsToPrimaryKeys(tc.columns),
          isDisconnected: disconnectedTables.has(tc.id),
          columnsToNullate: new Set(),
        })
      }
    }
  }
  const relations = tablesToCopy
    .map((tc) => [
      ...tc.children.map((c) => ({
        sourceTableId: c.fkTable,
        relationId: c.id,
        destinationTableId: c.targetTable,
      })),
      ...tc.parents.map((p) => ({
        sourceTableId: p.fkTable,
        relationId: p.id,
        destinationTableId: p.targetTable,
      })),
    ])
    .flatMap((r) => r)
  for (const tc of tablesToCopy) {
    const table = ctx.tables.get(tc.id)
    if (table && !table?.isDisconnected) {
      for (const parent of tc.parents) {
        const relation = {
          sourceTableId: parent.fkTable,
          relationId: parent.id,
          destinationTableId: parent.targetTable,
        }
        const followNullableOption = getRelationshipOption({
          cascadingOptions: followNullableRelations,
          defaultValue: true,
          relations,
          relation,
        })
        const maxChildrenPerNodeOption = getRelationshipOption({
          cascadingOptions: maxChildrenPerNode,
          defaultValue: undefined,
          relations,
          relation,
        })
        const maxCyclesLoopOption = getRelationshipOption({
          cascadingOptions: maxCyclesLoop,
          defaultValue: undefined,
          relations,
          relation,
        })
        const nullable = parent.keys.every((k) => k.nullable)
        const reference: Reference = {
          id: parent.id,
          fkTable: parent.fkTable,
          targetTable: parent.targetTable,
          fkColumns: parent.keys.map((k) => k.fkColumn),
          targetColumns: parent.keys.map((k) => k.targetColumn),
          nullable,
          directions:
            // If followNullable is false and the relation is nullable, we don't follow it
            // because those columns will be set to null anyway
            followNullableOption === false && nullable === true
              ? []
              : ['FORWARD'],
          eager,
          followNullable: followNullableOption,
          maxChildrenPerNode: maxChildrenPerNodeOption,
          currentLoop: 0,
          maxCyclesLoop: maxCyclesLoopOption,
        }
        if (isValidReference(ctx, reference)) {
          table.parents.push(reference)
        } else {
          const fkTable = ctx.tables.get(reference.fkTable)
          if (
            fkTable &&
            reference.nullable === true &&
            reference.followNullable === false
          ) {
            for (const column of reference.fkColumns) {
              fkTable.columnsToNullate.add(column)
            }
          }
        }
      }
      for (const child of tc.children) {
        const relation = {
          sourceTableId: child.fkTable,
          relationId: child.id,
          destinationTableId: child.targetTable,
        }
        const followNullableOption = getRelationshipOption({
          cascadingOptions: followNullableRelations,
          defaultValue: true,
          relations,
          relation,
        })
        const maxChildrenPerNodeOption = getRelationshipOption({
          cascadingOptions: maxChildrenPerNode,
          defaultValue: undefined,
          relations,
          relation,
        })
        const maxCyclesLoopOption = getRelationshipOption({
          cascadingOptions: maxCyclesLoop,
          defaultValue: undefined,
          relations,
          relation,
        })
        const reference: Reference = {
          id: child.id,
          fkTable: child.fkTable,
          targetTable: child.targetTable,
          fkColumns: child.keys.map((k) => k.fkColumn),
          targetColumns: child.keys.map((k) => k.targetColumn),
          nullable: child.keys.every((k) => k.nullable),
          // For children relation, we only follow them if the followNullableRelatiion is false
          directions: followNullableOption ? ['REVERSE'] : [],
          eager,
          followNullable: followNullableOption,
          maxChildrenPerNode: maxChildrenPerNodeOption,
          currentLoop: 0,
          maxCyclesLoop: maxCyclesLoopOption,
        }
        if (isValidReference(ctx, reference)) {
          table.children.push(reference)
        } else {
          const fkTable = ctx.tables.get(reference.fkTable)
          if (
            fkTable &&
            reference.nullable === true &&
            reference.followNullable === false
          ) {
            for (const column of reference.fkColumns) {
              fkTable.columnsToNullate.add(column)
            }
          }
        }
      }
    }
  }
}

/**
 * Changing the order into which the tasks are processed can have a huge impact
 * on the performance of the subsetting process, reducing the number of queries
 * and the number of rows fetched.
 */
function sortTasks(config: SubsetConfig, ctx: SubsettingContext) {
  if (config.taskSortAlgorithm === 'children') {
    ctx.tasks.sort((a, b) => {
      return (
        ctx.tables.get(a.segment.tableId)!.children.length -
        ctx.tables.get(b.segment.tableId)!.children.length
      )
    })
  } else if (config.taskSortAlgorithm === 'idsCount') {
    ctx.tasks.sort((a, b) => {
      return (
        ctx.storage.countIds(a.segment.tableId) -
        ctx.storage.countIds(b.segment.tableId)
      )
    })
  }
}

const createSubsettingContext = (
  client: DatabaseClient,
  options: SubsettingOptions
) => {
  const eager = options.subsetConfig.eager
  const followNullableRelations = options.subsetConfig.followNullableRelations
  const maxChildrenPerNode = options.subsetConfig.maxChildrenPerNode
  const maxCyclesLoop = options.subsetConfig.maxCyclesLoop
  const disconnectedTables = findDisconnectedTables(
    options.tablesToCopy,
    options.subsetConfig.targets.map((t) => t.table)
  )

  const createContext = () => {
    const context: SubsettingContext = {
      tables: new Map(),
      tasks: [],
      client,
      storage: options.storage,
      visitedTables: new Set(),
      currentSubsetdRows: 0,
    }

    setupSubsettingContext(
      context,
      options.tablesToCopy,
      disconnectedTables,
      Boolean(eager),
      followNullableRelations,
      maxChildrenPerNode,
      maxCyclesLoop
    )

    return context
  }

  const subsettingContext = createContext()

  return {
    subsettingContext,
    resetSubsettingContext() {
      const nextSubsettingContext = createContext()
      const { currentSubsetdRows } = subsettingContext
      Object.assign(subsettingContext, nextSubsettingContext)
      nextSubsettingContext.currentSubsetdRows = currentSubsetdRows
      return nextSubsettingContext
    },
  }
}

export async function subsetV3(
  connection: PgSnapshotConnection,
  emitter: SnapshotCaptureEventEmitter,
  options: SubsettingOptions
): Promise<void> {
  const Sentry = await getSentry()
  const subsetTransaction = Sentry.startTransaction({
    name: 'subsetV3',
    data: options.subsetConfig,
  })

  await withDbClient(
    async (client) => {
      const { transactionEnd } = await setTransactionSnapshotId(
        client,
        connection.pgSnapshotId
      )

      const subsettingStorage = options.storage
      const { subsettingContext, resetSubsettingContext } =
        createSubsettingContext(client, options)

      try {
        emitter.emit('subsetStart')
        // We can't really know how many tasks we will have to do, so we just
        // emit a progress event every 5 seconds to still give some feedback
        let completePercent = 0
        let currentProcessedTable = ''
        let updateInterval: NodeJS.Timeout | undefined
        const updateProgress = () =>
          (updateInterval = setInterval(() => {
            completePercent += 1
            emitter.emit('subsetProgress', {
              tableId: currentProcessedTable,
              percentCompleted: Math.min(completePercent, 99),
              currentSubsetdRows: subsettingContext?.currentSubsetdRows ?? 0,
            })
          }, 5000))

        subsettingStorage.subsetInit(subsettingContext.tables)

        const processTasks = async () => {
          sortTasks(options.subsetConfig, subsettingContext)

          let task: Task | undefined
          // Will process the tasks per order as they come in (FIFO) rather than LIFO
          // this ensure that we will start by fetching the targets before digging into the graph
          while ((task = subsettingContext.tasks.shift())) {
            currentProcessedTable = task.segment.tableId
            await processNextTask(subsettingContext, task)
            // We can remove the segment from our sqlite storage now that the task has been processed
            subsettingStorage.deleteSegment(task.segment.segmentId)
            sortTasks(options.subsetConfig, subsettingContext)
          }
        }

        try {
          updateProgress()
          // First, we gather our entrypoint ids, and push their result into
          // our global queue of tasks to do
          for (const targetIndex in options.subsetConfig.targets) {
            const configTarget = options.subsetConfig.targets[targetIndex]
            const table = subsettingContext.tables.get(configTarget.table)
            if (!table) {
              throw new Error(
                `Cannot find the table in tablesToCopy: ${configTarget.table}`
              )
            }
            const newSegment = await discoverRootTable(
              subsettingContext,
              targetIndex,
              table,
              await configToSQL(client, configTarget, table)
            )
            if (newSegment) {
              for (const segment of newSegment) {
                subsettingContext.tasks.push({ segment, step: 0 })
              }
            }

            if (options.subsetConfig.targetTraversalMode === 'sequential') {
              await processTasks()
              resetSubsettingContext()
            }
          }

          if (
            options.subsetConfig.targetTraversalMode === 'together' ||
            !options.subsetConfig.targetTraversalMode
          ) {
            await processTasks()
          }
        } finally {
          if (updateInterval) {
            clearInterval(updateInterval)
          }

          subsettingStorage.subsetCleanup()
        }
      } finally {
        emitter.emit('subsetEnd')
        await transactionEnd()
      }
    },
    { connString: connection.connString }
  )
  subsetTransaction.finish()
}
