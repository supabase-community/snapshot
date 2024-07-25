import type { CommandModule } from 'yargs'
import yargs from 'yargs'

import { generateAction } from './actions/generate/generateAction.js'

export const configCommand: CommandModule = {
  command: 'config [action]',
  describe: 'manage configuration',
  builder(yargs) {
    return yargs.command(generateAction).showHelpOnFail(false)
  },
  handler() {
    yargs.showHelp()
  },
}
