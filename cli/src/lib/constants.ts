import { xdebug } from '@snaplet/sdk/cli'
import fs from 'fs'
import globalDirectories from 'global-dirs'
import path from 'path'

const xdebugStartup = xdebug.extend('startup')

type InstallationType = 'npm' | 'yarn' | 'bash'
type InstallationDetails =
  | { isGlobal: true; type: InstallationType }
  | { isGlobal: false; type: 'npm' | 'yarn' }

function isBashInstall() {
  xdebugStartup(`checking if isBashInstall`)
  // If argv[0] is ~/.local/bin/snaplet it means we are running from binary
  const runtimePath = fs.realpathSync(process.argv[0])
  xdebugStartup(`current binary is located ${runtimePath}`)
  if (
    runtimePath &&
    runtimePath.indexOf(path.join('.local', 'bin', 'snaplet')) > -1
  ) {
    xdebugStartup(
      'is located at bash install ~/.local/bin/snaplet location, this is bash install'
    )
    return true
  }
  return false
}

// returns if current bin is installed globally
function getRuntimeInstallDetails(): InstallationDetails {
  xdebugStartup('getRuntimeInstallDetails')
  try {
    const realPath = fs.realpathSync(process.argv[0])
    xdebugStartup(`executed script path: ${realPath}`)
    const isGlobalYarnInstall = realPath.startsWith(
      globalDirectories.yarn.packages
    )
    xdebugStartup(
      `looking if it match yarn global packages path: ${globalDirectories.yarn.packages} :: ${isGlobalYarnInstall}`
    )
    const isGlobalNpmInstall = realPath.startsWith(
      globalDirectories.npm.packages
    )
    xdebugStartup(
      `looking if it match npm global packages path: ${globalDirectories.npm.packages} :: ${isGlobalNpmInstall}`
    )
    const isGlobalPnpmInstall =
      process.env.PNPM_HOME &&
      realPath.startsWith(path.join(process.env.PNPM_HOME, 'global'))
    // The binary start with something like ~/.config/yarn/global/node_modules/...
    if (isGlobalYarnInstall) {
      return {
        isGlobal: true,
        type: 'yarn',
      }
      // npm automatically alias to pnpm if installed
    } else if (isGlobalNpmInstall || isGlobalPnpmInstall) {
      return {
        isGlobal: true,
        type: 'npm',
      }
    } else if (isBashInstall()) {
      return {
        isGlobal: true,
        type: 'bash',
      }
      // We check if we currently use yarn runtime
      // yarn 'yarn/1.22.4 npm/? node/v12.14.1 darwin x64'
      // npm 'npm/6.14.7 node/v12.14.1 darwin x64'
    } else if (process.env.npm_config_user_agent?.includes('yarn') === true) {
      return {
        isGlobal: false,
        type: 'yarn',
      }
    } else {
      return {
        isGlobal: false,
        type: 'npm',
      }
    }
  } catch (e) {
    xdebugStartup(
      `an error happened while trying to determine client install: ${e}`
    )
    // Note that we should never go to this branch but if an unexpected error occurs
    // we fallback onto local npm and show an error message to the user
    console.log(
      'WARNING: we were not able to properly determine your snaplet installation, the upgrade command might not be adequate for you'
    )
    return {
      isGlobal: false,
      type:
        process.env.npm_config_user_agent?.includes('yarn') === true
          ? 'yarn'
          : 'npm',
    }
  }
}

export const RUNTIME_INSTALL_DETAILS = getRuntimeInstallDetails()
export const CLI_VERSION =
  process.env.SNAPLET_CLI_VERSION ??
  JSON.parse(
    fs.readFileSync(path.join(__dirname, '../../package.json'), 'utf8')
  ).version
xdebugStartup('RUNTIME_INSTALL_DETAILS: ', RUNTIME_INSTALL_DETAILS)
xdebugStartup('CLI_VERSION: ', CLI_VERSION)

function isProduction() {
  if (typeof process.env.NODE_ENV === 'string') {
    return process.env.NODE_ENV === 'production'
    // @ts-expect-error - `process.pkg` added by Vercel's PKG.
  } else if (process.pkg) {
    return true
  }
  return false
}
export const IS_PRODUCTION = isProduction()

export const SNAPLET_HOSTNAME =
  process.env.SNAPLET_HOSTNAME ?? 'https://app.snaplet.dev'

export const SNAPLET_API_HOSTNAME =
  process.env.SNAPLET_API_HOSTNAME ?? 'https://api.snaplet.dev'

// https://github.com/watson/ci-info/blob/master/index.js#L53
export const IS_CI = typeof process.env.CI !== 'undefined'
export const IS_EXEC_TASK =
  typeof process.env.SNAPLET_EXEC_TASK_ID !== 'undefined'
