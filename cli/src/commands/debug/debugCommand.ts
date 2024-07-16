import { CommandModule } from 'yargs'

export const debugCommand: CommandModule = {
  command: 'debug <command>',
  describe: false,
  builder(yargs) {
    return yargs
      .command({
        command: 'throw',
        describe: 'throw an unhandled exception',
        async handler() {
          throw new Error('I am a test exception.')
        },
      })
      .showHelpOnFail(true)
  },
  handler() {},
}
