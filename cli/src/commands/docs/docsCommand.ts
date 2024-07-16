import type { CommandModule } from 'yargs'

export const docsCommand: CommandModule = {
  command: 'documentation',
  aliases: ['docs'],
  describe: 'opens the Snaplet Documentation in your browser',
  async handler() {
    const { handler } = await import('./docsCommand.handler.js')
    await handler()
  },
}
