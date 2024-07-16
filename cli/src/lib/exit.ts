import { ERROR_CODES } from '@snaplet/sdk/cli'

import { teardownAndExit } from './handleTeardown.js'

export async function exitWithError(code: keyof typeof ERROR_CODES) {
  const exitCode = ERROR_CODES[code] || 1
  // TODO: Display link to help docs for these error codes.
  return await teardownAndExit(exitCode)
}
