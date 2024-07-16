import c from 'ansi-colors'
import semver from 'semver'

import { config } from '~/lib/config.js'
import { CLI_VERSION } from '~/lib/constants.js'
import { getState, refreshState, makeInstallCommand } from '~/lib/upgrade.js'

const ONE_DAY = 24 * 60 * 60 * 1000

async function checkForUpdates() {
  let state = await getState()
  if (
    !state ||
    Date.now() - new Date(state.lastCheckedAt).getTime() >= ONE_DAY
  ) {
    state = await refreshState({ timeout: 1000 })
  }
  if (semver.gt(state.latestVersion, CLI_VERSION)) {
    const command = makeInstallCommand(state.latestVersion)
    return c.yellow(
      `\nUpdate available ${CLI_VERSION} -> ${
        state!.latestVersion
      }, run "${command}" to upgrade.`
    )
  }
}

export const checkForUpdatesMiddleware = async () => {
  const systemConfig = await config.getSystem()
  if (!process.env.CI && !systemConfig.silenceUpgradeNotifications) {
    return checkForUpdates()
  }
}
