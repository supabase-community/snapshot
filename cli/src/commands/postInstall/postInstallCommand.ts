import type { CommandModule } from 'yargs'

export const postInstallCommand: CommandModule = {
  command: 'post-install',
  describe: false,
  async handler() {
    const { handler } = await import('./postInstallCommand.handler.js')
    await handler()
  },
}
