import type { CommandModule } from 'yargs'

import type { CommandOptions } from './shareAction.types.js'

export const shareAction: CommandModule<unknown, CommandOptions> = {
  command: 'share [snapshot-name|snapshot-path]',
  describe: 'Share a snapshot',
  aliases: ['upload'],
  // @ts-expect-error
  builder: (y) => {
    return y
      .parserConfiguration({
        'boolean-negation': false,
      })
      .option('no-encrypt', {
        type: 'boolean',
        default: false,
        describe: 'Disable encryption',
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
        describe: 'Share the latest snapshot',
      })
  },
  async handler(props) {
    const { handler } = await import('./shareAction.handler.js')
    await handler(props)
  },
}
