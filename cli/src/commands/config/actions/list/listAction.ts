import { CommandModule } from 'yargs'

export const listAction: CommandModule = {
  command: 'list',
  describe: 'list config variables',
  aliases: ['ls'],
  async handler() {
    const { handler } = await import('./listAction.handler.js')
    await handler()
  },
}
