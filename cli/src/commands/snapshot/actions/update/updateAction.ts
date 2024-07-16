import { CommandModule } from 'yargs'

import { CommandOptions } from './updateAction.types.js'

export const updateAction: CommandModule<unknown, CommandOptions> = {
  command: 'update <snapshot-name>',
  aliases: [],
  describe: 'update metadata of a snapshot',
  //@ts-expect-error
  builder: (y) => {
    return y
      .positional('snapshot-name', {
        describe: 'the unique name of the snapshot',
        type: 'string',
      })
  },
  async handler(options) {
    const { handler } = await import('./updateAction.handler.js')
    await handler(options)
  },
}
