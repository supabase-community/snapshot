import { SnapshotCaptureEventEmitter } from './events.js'
import { displayMinimalSubsetProgress } from '../../displayProgress.js'
import { IntrospectedStructure } from '@snaplet/sdk/cli'

type CopyTablesUpdateEvent = {
  schema: string
  tableName: string
  status?: 'IN_PROGRESS' | 'SUCCESS'
  rows?: number
  bytes?: number
  totalRows?: number
  totalAllCopiedRows?: number
  totalAllRows?: number
  timeToDump?: number
  timeToCompress?: number
}

type CopyTablesFailureEvent = {
  schema: string
  tableName: string
  status: 'FAILURE'
  error: Error
}

export type CopyTablesEvent = CopyTablesUpdateEvent | CopyTablesFailureEvent

type SubsetProgresEventV3 = {
  step: 'subset'
  completed: number
  metadata?: {
    table: string
    currentSubsetdRows: number
  }
}

type DataProgresEventV3 = {
  step: 'data'
  completed: number
}

type SchemasProgresEventV3 = {
  step: 'schemas'
  completed: number
}

type EventHandler<T extends string, Data> = (
  type: T,
  data: Data
) => Promise<void>

type ProgressEventHanlder = EventHandler<
  'progress',
  SubsetProgresEventV3 | DataProgresEventV3 | SchemasProgresEventV3
>
type CopyProgressEventHandler = EventHandler<'copyProgress', CopyTablesEvent>
type StructureEventHandler = EventHandler<'structure', IntrospectedStructure>
type SchemaEventHandler = EventHandler<'schema', string>
type TableEventHandler = EventHandler<'tables', Array<{ name: string }>>
type Handlers =
  | ProgressEventHanlder
  | CopyProgressEventHandler
  | StructureEventHandler
  | SchemaEventHandler
  | TableEventHandler
export type OnChangeHandler = (
  ...[type, data]: Parameters<Handlers>
) => Promise<void>

// This should be refactored in favor of a fully event emitter all the way up
function emitterToOnUpdateProxy(
  eventsEmitter: SnapshotCaptureEventEmitter,
  onChange: OnChangeHandler
) {
  // TODO: Refactor the onChange function as the way we handle the update repoting will
  // not work / be bugged as soon as we introduce concurrency
  // Also it's a pain to deal with, for those kind of things we should
  // stronlgy type the events and use a proper event emitter to know what to send
  // and what to expect this logic does not belong here and should be pushed upward
  // as we should not have to repeat sending of those total rows at every progress step
  let totalAllRows = 0
  let totalAllCopiedRows = 0
  const tableTotalRowsToCopy = new Map<string, number>()
  // When we start dumping it means subset is done
  eventsEmitter.on('subsetProgress', (data) => {
    const payload: SubsetProgresEventV3 = {
      step: 'subset',
      completed: data.percentCompleted,
      metadata: {
        table: data.tableId,
        currentSubsetdRows: data.currentSubsetdRows,
      },
    }
    displayMinimalSubsetProgress({
      tableName: data.tableId,
      done: false,
      currentSubsetdRows: data.currentSubsetdRows,
    })
    void onChange('progress', payload)
  })
  eventsEmitter.on('subsetEnd', () => {
    const payload: SubsetProgresEventV3 = {
      step: 'subset',
      completed: 100,
    }
    displayMinimalSubsetProgress({
      tableName: '',
      done: true,
      currentSubsetdRows: 0,
    })
    void onChange('progress', payload)
  })
  eventsEmitter.on('dumpTablesStart', (data) => {
    void onChange('progress', {
      step: 'subset',
      completed: 100,
    })
    void onChange('progress', {
      step: 'data',
      completed: 0,
    })
    totalAllRows = data.totalRowsToCopy
  })
  eventsEmitter.on('dumpTablesEnd', () => {
    void onChange('progress', {
      step: 'data',
      completed: 100,
    })
  })
  eventsEmitter.on('copyTableStart', (data) => {
    tableTotalRowsToCopy.set(
      `${data.schema}.${data.tableName}`,
      data.totalRowsToCopy
    )
    const payload: CopyTablesEvent = {
      status: 'IN_PROGRESS',
      tableName: data.tableName,
      schema: data.schema,
      totalRows: data.totalRowsToCopy,
    }
    void onChange('copyProgress', payload)
  })
  eventsEmitter.on('copyTableProgress', (data) => {
    const totalRows = tableTotalRowsToCopy.get(
      `${data.schema}.${data.tableName}`
    )
    const payload: CopyTablesEvent = {
      tableName: data.tableName,
      schema: data.schema,
      rows: data.currentCopiedRows,
      totalAllCopiedRows: totalAllCopiedRows,
      totalAllRows: totalAllRows,
      totalRows: totalRows,
    }
    void onChange('copyProgress', payload)
  })
  eventsEmitter.on('copyTableEnd', (data) => {
    if (data.status === 'FAILURE') {
      const payload: CopyTablesEvent = {
        status: 'FAILURE',
        tableName: data.tableName,
        schema: data.schema,
        error: data.error,
      }
      void onChange('copyProgress', payload)
    } else {
      totalAllCopiedRows += data.rowsDumped
      const payload: CopyTablesEvent = {
        tableName: data.tableName,
        schema: data.schema,
        totalAllRows: totalAllRows,
        status: 'SUCCESS',
        totalAllCopiedRows: totalAllCopiedRows,
        // Sometimes the estimate rows count differ from the actual number of dumped rows
        // on success all which needed to be dumped has been dumped so we can safely set the same value
        rows: data.rowsDumped,
        totalRows: data.rowsDumped,
      }
      void onChange('copyProgress', payload)
    }
  })
}

export { emitterToOnUpdateProxy }
