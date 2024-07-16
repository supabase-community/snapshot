import type { CommandModule } from 'yargs'

export const upgradeCommand: CommandModule = {
  command: 'upgrade',
  describe: 'upgrade this binary',
  async handler() {
    const { handler } = await import('./upgradeCommand.handler.js')
    await handler()
  },
}
