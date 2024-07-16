// REMOVE_THIS
import { SNAPSHOT_STEPS } from '@snaplet/sdk/cli'

import { trpc } from './trpc.js'
import { IS_EXEC_TASK } from './constants.js'

interface ExecTaskProgress {
  steps: string[]
  step: number
  completed: number
  metadata?: Record<string, unknown>
}

type AsyncFunction = (...args: any[]) => Promise<any>

function throttleAsyncFunction(
  asyncFn: AsyncFunction,
  delay: number
): AsyncFunction {
  let lastCall = 0

  return async function (...args: any[]) {
    const now = Date.now()
    if (lastCall + delay <= now) {
      lastCall = now
      await asyncFn(...args)
    }
  }
}

const updateExecTaskProgress = throttleAsyncFunction(
  async (subjectIdentifier: string, progress: ExecTaskProgress) => {
    if (progress) {
      // Update progress often raises an ECONNRESET error which make the whole capture process fail.
      // This is a workaround to prevent the process from failing for this reason.
      try {
        await trpc.execTask.updateProgress.mutate({
          subjectIdentifier,
          progress,
        })
      } catch {
        // We discard the error
      }
    }
  },
  1_000
)

export interface SnapshotProgress {
  step: (typeof SNAPSHOT_STEPS)[number]
  completed: number
  metadata?: Record<string, any>
}

export const updateSnapshotProgress = async (
  snapshotProgress: SnapshotProgress
) => {
  if (IS_EXEC_TASK) {
    await updateExecTaskProgress(process.env.SNAPLET_SNAPSHOT_ID, {
      steps: [...SNAPSHOT_STEPS],
      step: SNAPSHOT_STEPS.indexOf(snapshotProgress.step),
      completed: snapshotProgress.completed,
      metadata: snapshotProgress.metadata,
    })
  }
}
