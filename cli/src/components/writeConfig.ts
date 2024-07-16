import {
  ProjectConfig,
  writeEncryptionConfig,
  readPrivateKey,
  generatePublicKey,
  generateRSAKeys,
} from '@snaplet/sdk/cli'
import fs from 'fs-extra'
import path from 'path'
import terminalLink from 'terminal-link'

import { config } from '~/lib/config.js'
import { activity } from '~/lib/spinner.js'

import { needs } from './needs/index.js'

export const writeProjectFile = async (
  filePath: string,
  contents?: string | object
) => {
  const { dir, base } = path.parse(filePath)
  const link = terminalLink(base, 'file://' + filePath)

  const act = activity(`Project file ${link}`, 'Creating...')
  if (typeof contents === 'undefined') {
    act.info('Contents empty, skipping...')
  } else {
    try {
      await fs.mkdir(path.dirname(dir), { recursive: true })
      await fs.writeFile(
        filePath,
        typeof contents === 'string'
          ? contents
          : JSON.stringify(contents, undefined, 2)
      )
      act.done()
    } catch (e: any) {
      act.fail(e.message)
    }
  }
}

export const writeProjectConfig = async (
  newConfig: Partial<ProjectConfig> | null = {}
) => {
  const paths = await needs.projectPathsV2({ create: true })
  const link = terminalLink('config.json', 'file://' + paths.config)
  const act = activity(`Project file ${link}`, 'Creating...')
  const oldConfig = await config.getProject()
  await config.saveProject({
    ...oldConfig,
    ...newConfig,
  })
  act.done()

  return paths
}

export const generateEncryptionConfig = async () => {
  const paths = await needs.projectPathsV2()

  const link = terminalLink('id_rsa', 'file://' + paths.privateKey)

  const existingPrivateKey = await readPrivateKey()

  const act = activity(
    `Private key ${link}`,
    existingPrivateKey ? 'Reading...' : 'Creating'
  )

  let keys: any
  if (existingPrivateKey) {
    keys = { publicKey: generatePublicKey(existingPrivateKey) }
  } else {
    keys = await generateRSAKeys()
  }

  await writeEncryptionConfig(keys)

  act.done()
}
