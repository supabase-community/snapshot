import { CommandModule } from 'yargs'

import { CommandOptions } from './restoreAction.types.js'

export const restoreAction: CommandModule<unknown, CommandOptions> = {
  command: 'restore [snapshot-name|snapshot-path]',
  describe: 'restore a snapshot',
  aliases: ['r'],
  // @ts-expect-error
  builder(yargs) {
    return yargs
      .option('data', {
        describe: 'Restore data on the database (skip with --no-data)',
        type: 'boolean',
        default: true,
        boolean: true,
      })
      .option('schema', {
        describe: 'Restore schema on the database (skip with --no-schema)',
        type: 'boolean',
        default: true,
      })
      .option('progress', {
        describe:
          'Report the restore progress into the terminal (silence with --no-progress)',
        type: 'boolean',
        default: true,
      })
      .option('reset', {
        describe:
          'Drop destination database before restoring schemas (skip with --no-reset)',
        type: 'boolean',
        boolean: true,
        default: true,
      })
      .positional('snapshot-name|snapshot-path', {
        describe: 'the unique name or path of the snapshot',
        type: 'string',
      })
      .option('tags', {
        describe: 'Filter snapshots by tags',
        type: 'array',
        coerce: (values: string[]) => {
          return values.flatMap((v) => v.split(','))
        },
        default: [],
      })
      .option('latest', {
        type: 'boolean',
        default: false,
        describe: 'Restore the latest snapshot',
      })
      .option('yes', {
        describe: 'Performs a restore without a confirmation message',
        alias: 'y',
        type: 'boolean',
        default: false,
      })
      .option('tables', {
        describe: 'Restore only the specified tables to the target database',
        type: 'array',
        coerce: (values: string[]) => {
          return values.flatMap((v) => v.split(','))
        },
        default: [],
      })
      .option('exclude-tables', {
        describe:
          'Exclude the specified tables from being restored to the target database',
        type: 'array',
        coerce: (values: string[]) => {
          return values.flatMap((v) => v.split(','))
        },
        default: [],
      })
      .option('truncate', {
        type: 'boolean',
        default: true,
        description: 'Whether to truncate tables before importing data (skip with --no-truncate)',
        negatable: true,
      })
  },
  async handler(options) {
    const { handler } = await import('./restoreAction.handler.js')

    // does the user explicitly set the reset option?
    // example: `snapshot ss restore --reset`
    // when restoring to supabase we add the `--no-reset` flag by default
    const isResetExplicitlySet = process.argv.some((arg) =>
      ['--reset'].includes(arg)
    )

    await handler({
      ...options,
      isResetExplicitlySet,
    })
  },
}
