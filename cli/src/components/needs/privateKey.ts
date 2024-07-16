import { readPrivateKey } from '@snaplet/sdk/cli'

import { exitWithError } from '~/lib/exit.js'

import { logError } from './logError.js'

export const privateKey = async () => {
  const privateKey = await readPrivateKey()
  if (!privateKey) {
    logError([
      'A private key is required:',
      'Run **snaplet setup** or create one in **.snaplet/id_rsa**',
    ])
    return await exitWithError('CONFIG_PK_NOT_FOUND')
  }
  return privateKey
}
