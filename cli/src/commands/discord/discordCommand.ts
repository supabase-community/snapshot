import type { CommandModule } from 'yargs'

export const discordCommand: CommandModule = {
  command: 'discord',
  aliases: ['chat'],
  describe: 'opens the Snaplet Discord chat window in your browser',
  async handler() {
    const { handler } = await import('./discordCommand.handler.js')
    await handler()
  },
}
