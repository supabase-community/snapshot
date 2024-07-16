import { exitWithError } from '~/lib/exit.js'

import { logError } from './logError.js'
import { config } from '~/lib/config.js'

export const publicKey = async () => {
  const publicKey = (await config.getProject()).publicKey

  if (!publicKey) {
    logError([
      'A private key is required:',
      'Run **snaplet config generate -t keys** to create one',
    ])
    return await exitWithError('CONFIG_PUBLIC_KEY_NOT_FOUND')
  }

  return publicKey
}
