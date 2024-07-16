import dotenv from 'dotenv-defaults'
import path from 'path'
import {
  ensureDirSync,
  pathExistsSync,
  copyFileSync,
  removeSync,
} from 'fs-extra'

const CLI_BASE_DIR = path.resolve(__dirname, '../../../../cli')

dotenv.config({
  defaults: path.resolve(CLI_BASE_DIR, '../.env.defaults'),
})

export function setup() {
  process.env.COPYCAT_HASH_KEY =
    '[1363698228, 607151991, 1148352113, 2032805430]'
  const SHOULD_USE_SNAPLET_BINARY =
    process.env.SNAPLET_CLI_PATH ||
    (process.env.CI && process.platform === 'linux')
  // We want to move our compiled cli outside of the project directory
  // where the node_modules lives, so that we can make sure every depedencies
  // has been properly compiled into the binary.
  const SNAPLET_BIN_CLI = '/tmp/snaplet/bin/cli'
  function setupSnapletCli() {
    if (SHOULD_USE_SNAPLET_BINARY) {
      if (!pathExistsSync(SNAPLET_BIN_CLI!)) {
        const SNAPLET_COMPILED_BINARY =
          process.env.SNAPLET_CLI_PATH ||
          path.resolve(CLI_BASE_DIR, './bin/cli')
        ensureDirSync(path.dirname(SNAPLET_BIN_CLI))
        copyFileSync(SNAPLET_COMPILED_BINARY, SNAPLET_BIN_CLI)
      }
    }
  }

  try {
    setupSnapletCli()
  } catch (e) {
    console.log(`Error setting up snaplet cli: ${e}`)
  }
}

export function teardown() {
  removeSync('/tmp/snaplet')
}
