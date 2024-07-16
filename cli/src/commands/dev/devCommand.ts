import { CommandModule } from 'yargs'

import { CommandOptions } from './devCommand.types.js'

export const devCommand: CommandModule<unknown, CommandOptions> = {
  command: 'dev',
  aliases: ['d'],
  describe:
    "keeps your dev database and its data in sync with your git branch so you don't have to, powered by Neon",
  builder: (y) => {
    return y.option('port', {
      describe: 'the port to expose the proxy on',
      type: 'number',
      default: 2345,
    })
  },
  async handler(props) {
    const { handler } = await import('./devCommand.handler.js')
    await handler(props)
  },
}
