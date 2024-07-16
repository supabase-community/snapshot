import yargs, { ArgumentsCamelCase } from 'yargs'

import './bootstrap.js'
import { catchAllCommand } from './commands/catchAll/catchAllCommand.js'
import { configCommand } from './commands/config/configCommand.js'
import { debugCommand } from './commands/debug/debugCommand.js'
import { devCommand } from './commands/dev/devCommand.js'
import { discordCommand } from './commands/discord/discordCommand.js'
import { docsCommand } from './commands/docs/docsCommand.js'
import { postInstallCommand } from './commands/postInstall/postInstallCommand.js'
import { snapshotCommand } from './commands/snapshot/snapshotCommand.js'
import { upgradeCommand } from './commands/upgrade/upgradeCommand.js'
import { setupCommand } from "./commands/setup/setupCommand.js"

let upgradeNotice: string | undefined

process.on('exit', () => {
  if (upgradeNotice) {
    console.log(upgradeNotice)
  }
})

const cli = yargs
  .scriptName('snaplet')
  .middleware([
    async () => {
      if (
        process.env.SNAPLET_NO_UPDATE_NOTIFIER !== undefined &&
        process.argv.slice(2)[0] !== 'upgrade'
      ) {
        const { checkForUpdatesMiddleware } = await import(
          './middlewares/index.js'
        )
        await checkForUpdatesMiddleware()
          ?.then((notice) => {
            upgradeNotice = notice
          })
          .catch(() => {})
      }
    },
    async (args: ArgumentsCamelCase) =>
      (await import('./middlewares/index.js')).removePgEnvarMiddleware(args),
    async (args: ArgumentsCamelCase) =>
      (await import('./middlewares/index.js')).setupSentryMiddleware(args),
    async (args: ArgumentsCamelCase) =>
      (await import('./middlewares/index.js')).runAllMigrationsMiddleware(args),
  ])
  .usage('snaplet <command> <subcommand> [flags]')
  .command(configCommand)
  .command(debugCommand)
  .command(devCommand)
  .command(discordCommand)
  .command(docsCommand)
  .command(snapshotCommand)
  .command(upgradeCommand)
  .command(catchAllCommand)
  .command(setupCommand)
  .command(postInstallCommand)
  .completion('completion')
  .version(
    process.env.SNAPLET_CLI_VERSION ?? require('../package.json').version
  )
  .alias('version', 'v')
  .help()
  .alias('help', 'h')
  .showHelpOnFail(false)
  .fail(async (...args) =>
    (await import('./lib/handleFail.js')).handleFail(...args)
  )

if (process.env.YARGS_DISABLE_WRAP) {
  cli.wrap(null)
}

cli
  .parseAsync()
  .then(async () => {
    const exitCode = process.exitCode || 0
    await (await import('./lib/handleTeardown.js')).teardownAndExit(exitCode)
  })
  .catch((_) => {})
