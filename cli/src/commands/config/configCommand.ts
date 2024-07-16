import type { CommandModule } from 'yargs'
import yargs from 'yargs'

import { generateAction } from './actions/generate/generateAction.js'
import { listAction } from './actions/list/listAction.js'

export const configCommand: CommandModule = {
  command: 'config [action]',
  describe: 'manage configuration',
  builder(yargs) {
    return yargs
      .command(generateAction)
      .command(listAction)
      .showHelpOnFail(false)
  },
  handler() {
    yargs.showHelp()
  },
}
