import execa from 'execa'
import semver from 'semver'

import { RUNTIME_INSTALL_DETAILS, CLI_VERSION } from '~/lib/constants.js'
import { refreshState, makeInstallCommand } from '~/lib/upgrade.js'

export async function handler() {
  const state = await refreshState()
  const needUpdate = semver.gt(state.latestVersion, CLI_VERSION)

  if (!needUpdate) {
    return console.log('No available update')
  }

  if (RUNTIME_INSTALL_DETAILS.type === 'bash') {
    execa.sync('curl -sL https://app.snaplet.dev/get-cli/ | bash', {
      stdio: 'inherit',
      shell: true,
    })
  } else {
    const command = makeInstallCommand(state.latestVersion)
    console.log(`Please upgrade using your package manager: ${command}`)
  }
}
