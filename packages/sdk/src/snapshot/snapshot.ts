import { SnapshotOrigin, SnapshotSummary } from './summary.js'
import { SnapshotStatus } from './types.js'

export type CloudSnapshot = {
  /** @deprecated */
  totalSize?: number
  /** @deprecated */
  id?: string
  /** @deprecated */
  createdAt?: Date
  /** @deprecated */
  projectId?: string
  /** @deprecated */
  uniqueName?: string
  /** @deprecated */
  failureCount?: number
  /** @deprecated */
  errors?: string[]
  //----------
  origin: SnapshotOrigin
  status: keyof typeof SnapshotStatus
  summary: SnapshotSummary
  /**
   * Locally cached snapshots are stored on the disk (e.g. .snaplet/snapshots/**).
   * This is the absolute path to the cached snapshot.
   * Populated by `LocalSnapshotHost`
   */
  cachePath?: string
  encryptedSessionKey?: string
}
