import execa from 'execa'

import { exitWithError } from '~/lib/exit.js'

import { logError } from './logError.js'

export const brotliCliCommand = async () => {
  try {
    execa.sync('brotli', ['--version'])
  } catch (error) {
    logError([
      'The **brotli** binary could not be located and is required. Please install **brotli** on your system.',
    ])
    await exitWithError('CLI_BIN_REQUIRE_BROTLI')
  }
}
