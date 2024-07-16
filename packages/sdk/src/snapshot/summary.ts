import fs from 'fs-extra'
import { PublicEncryptionPayload } from './crypto.js'

export interface SnapshotSummary {
  /* A snapshot that's uploaded to the cloud has a stable reference */
  snapshotId?: string
  date: Date
  name: string
  origin?: SnapshotOrigin
  tables?: SnapshotTable[]
  totalSize?: number
  message?: string
  tags?: string[]
  // This is how we enable encryption
  encryptedSessionKey?: string
  encryptionPayload?: PublicEncryptionPayload
  /**
   * this key is used to let us know if we are restoring from a supabase
   * connection or not. As we may be restoring to a supabase local development
   * database, which is hosted on localhost. This allows to warn the user
   * if they are missing any flags (e.g. --no-reset) or have not excluded specific tables.
   * */
  isSupabaseConnection?: boolean
}

export type SnapshotOrigin = 'LOCAL' | 'CLOUD' | 'UNKNOWN'

export interface SnapshotTable {
  id?: string
  schema: string
  table: string
  filename: string
  timeToDump?: number
  copiedRows: number
  bytes: number
  message?: string
}

export const readSnapshotSummary = async (
  file: string
): Promise<SnapshotSummary> => {
  return await fs.readJSON(file)
}

export const writeSnapshotSummary = async (
  file: string,
  summary: SnapshotSummary
) => {
  return await fs.writeJSON(file, summary, { spaces: 2 })
}
