import { CommandModule } from 'yargs'

import { CommandOptions } from './listAction.types.js'

export const listAction: CommandModule<unknown, CommandOptions> = {
  command: 'list',
  aliases: ['ls'],
  describe: 'list all snapshots',
  //@ts-expect-error
  builder: (y) => {
    return y
      .option('tags', {
        type: 'array',
        coerce: (values: string[]) => {
          return values.flatMap((v) => v.split(','))
        },
        default: [],
      })
      .option('latest', {
        type: 'boolean',
        default: false,
        describe: 'show the most recent snapshot',
      })
      .option('name-only', {
        type: 'boolean',
        default: false,
        describe: 'show only the snapshot names',
      })
  },
  async handler(options) {
    const { handler } = await import('./listAction.handler.js')
    await handler(options)
  },
}
