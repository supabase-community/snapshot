import type { CommandModule } from 'yargs'

export const catchAllCommand: CommandModule = {
  command: '*',
  async handler(options) {
    const { handler } = await import('./catchAllCommand.handler.js')
    await handler(options)
  },
}
