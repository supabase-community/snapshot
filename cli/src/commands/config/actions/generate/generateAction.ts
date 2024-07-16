import type { CommandModule } from 'yargs'

import { CommandOptions } from './generateAction.types.js'

export const generateAction: CommandModule<any, CommandOptions> = {
  command: 'generate',
  describe: 'generate configuration files',
  // @ts-expect-error
  builder(y) {
    return y
      .option('type', {
        alias: 't',
        choices: ['typedefs', 'transform', 'keys'],
        default: ['typedefs'],
      })
      .option('dry-run', {
        type: 'boolean',
        default: false,
      })
      .option('connection-string', {
        type: 'string',
        describe: 'The connection string to use for introspecting the database',
      })
  },
  async handler(args) {
    const { handler } = await import('./generateAction.handler.js')
    await handler(args)
  },
}
