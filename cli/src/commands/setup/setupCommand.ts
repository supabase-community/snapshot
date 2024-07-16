import { CommandModule } from 'yargs'

export const setupCommand: CommandModule = {
  command: 'setup',
  describe: 'Initialize or connect an existing Snaplet project',
  async handler() {
    const { handler } = await import('./setupCommand.handler.js')
    await handler()
  },
}