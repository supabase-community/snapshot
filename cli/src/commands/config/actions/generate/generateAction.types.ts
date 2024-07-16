export type CommandOptions = {
  type: ('typedefs' | 'transform' | 'keys')[]
  dryRun: boolean
  connectionString?: string
}
