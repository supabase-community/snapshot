import { CommandModule } from 'yargs'

import { CommandOptions } from './captureAction.types.js'

export const captureAction: CommandModule<unknown, CommandOptions> = {
  command: 'capture [destination-path]',
  describe: 'capture a new snapshot',
  aliases: ['c'],
  builder: (y) => {
    return y
      .options('message', {
        describe: 'Attach a message to the snapshot',
        alias: 'm',
        type: 'string',
        default: undefined,
      })
      .option('subset-path', {
        describe: 'Path to a subset config file',
        alias: 'subset',
        type: 'string',
        default: undefined,
      })
      .option('tags', {
        describe: 'Attach tags to the snapshot',
        type: 'array',
        coerce: (values: string[]) => {
          return values.flatMap((v) => v.split(','))
        },
        default: [],
      })
      .option('transform-mode', {
        describe: 'Transformation mode to apply to the snapshot',
        alias: 't',
        // note(justinvdm, 18 Oct 2022): Duplicate of TRANSFORM_MODES to avoid bloating startup time.
        // Please keep them in sync.
        // https://github.com/snaplet/snaplet/blob/2a6091e6c880aa2f502034e957f053095b17c847/packages/sdk/src/transform.ts#L39-L40
        choices: ['strict', 'unsafe', 'auto'],
        default: undefined,
      })
      .option('unique-name', {
        type: 'string',
        default: undefined,
        hidden: true,
      })
  },
  async handler(args) {
    const { handler } = await import('./captureAction.handler.js')
    await handler(args)
  },
}
