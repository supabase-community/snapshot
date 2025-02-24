export interface CommandOptions {
  latest: boolean
  tags: string[]
  snapshotName?: string
  data: boolean
  schema: boolean
  reset: boolean
  yes: boolean
  tables: string[]
  excludeTables: string[]
  progress: boolean
  isResetExplicitlySet: boolean
  truncate?: boolean
}
