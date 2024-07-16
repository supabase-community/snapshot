import type { SnapshotSummary } from './snapshot/summary.js'

type SnapshotDeployable =
  | {
      isDeployable: true
      reason: null
    }
  | {
      isDeployable: false
      reason: 'SNAPSHOT_ENCRYPTED' | 'SUPABASE_UNSUPPORTED_SCHEMAS_FOUND'
    }

/**
 * Checks if a snapshot is deployable to a preview database, by looking at the summary.
 */
export const isSnapshotDeployable = (
  summary: SnapshotSummary
): SnapshotDeployable => {
  // we need a private key to decrypt the snapshot, which we wont have.
  if (summary.encryptedSessionKey) {
    return { isDeployable: false, reason: 'SNAPSHOT_ENCRYPTED' }
  }

  // check if one schema is not "public" or "auth"
  const isUnsupportedSchemaIncluded = summary.tables?.some(
    (table) =>
      // schema is not "public" or "auth"
      !['auth', 'public'].includes(table.schema)
  )

  // As of this pr https://github.com/snaplet/snaplet/pull/2324
  // we decided that snapshots containing tables outside of the
  // "public" or "auth" schemas is not a supported path.
  if (summary.isSupabaseConnection === true && isUnsupportedSchemaIncluded) {
    return { isDeployable: false, reason: 'SUPABASE_UNSUPPORTED_SCHEMAS_FOUND' }
  }

  return { isDeployable: true, reason: null }
}
