import { IntrospectedStructure, SNAPSHOT_STEPS } from '@snaplet/sdk/cli'

import type TypedEmitter from '~/lib/typed-emitter.js'

type CopyTableBaseData = {
  schema: string
  tableName: string
}

export interface SnapshotProgress {
  step: (typeof SNAPSHOT_STEPS)[number]
  completed: number
  metadata?: Record<string, any>
}

type SnapshotCaptureEventMap = {
  progress: (data: SnapshotProgress) => void
  structure: (data: IntrospectedStructure) => void
  tables: (
    data: Array<
      Pick<IntrospectedStructure['tables'][number], 'schema' | 'name'>
    >
  ) => void
  schema: (data: string) => void
  subsetStart: () => void
  subsetProgress: (data: {
    tableId: string
    percentCompleted: number
    currentSubsetdRows: number
  }) => void
  subsetEnd: () => void
  dumpTablesStart: (data: { totalRowsToCopy: number }) => void
  dumpTablesEnd: () => void
  copyTableStart: (
    data: CopyTableBaseData & { totalRowsToCopy: number }
  ) => void
  copyTableProgress: (
    data: CopyTableBaseData & {
      currentCopiedRows: number
    }
  ) => void
  copyTableEnd: (
    data:
      | (CopyTableBaseData & {
          status: 'SUCCESS'
          timeToDump: number
          timeToCompress: number
          rowsDumped: number
        })
      | (CopyTableBaseData & {
          status: 'FAILURE'
          error: Error
        })
  ) => void
}

type SnapshotCaptureEventEmitter = TypedEmitter<SnapshotCaptureEventMap>

export { SnapshotCaptureEventEmitter }
