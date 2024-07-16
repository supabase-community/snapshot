import type { CommandModule } from 'yargs'
import yargs from 'yargs'

import { captureAction } from './actions/capture/captureAction.js'
import { listAction } from './actions/list/listAction.js'
import { restoreAction } from './actions/restore/restoreAction.js'
import { updateAction } from './actions/update/updateAction.js'

export const snapshotCommand: CommandModule = {
  command: 'snapshot [action]',
  aliases: ['ss'],
  describe: 'manage snapshots',
  builder(yargs) {
    return yargs
      .command(captureAction)
      .command(listAction)
      .command(restoreAction)
      .command(updateAction)
      .showHelpOnFail(true)
  },
  handler() {
    yargs.showHelp()
  },
}
