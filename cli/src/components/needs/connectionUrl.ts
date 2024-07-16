import { config } from '~/lib/config.js'
import { exitWithError } from '~/lib/exit.js'
import { activity } from '~/lib/spinner.js'

import { logError } from './logError.js'
import { validConnectionString } from './validConnectionString.js'

export const sourceDatabaseUrl = async () => {
  const act = activity('Source database URL', 'Checking...')
  const projectConfig = await config.getProject()
  if (!projectConfig.sourceDatabaseUrl) {
    act.fail('Could not find a source database URL')
    logError(
      [
        'A source database URL is required:',
        'Run **snaplet setup** or use the **SNAPLET_SOURCE_DATABASE_URL** environment variable',
      ],
      'SNAPLET_SOURCE_DATABASE_URL=postgres://username:password@host:5432/database'
    )
    return await exitWithError('SOURCE_DATABASE_URL_REQUIRED')
  }
  act.done()
  const connectionString = await validConnectionString(
    projectConfig.sourceDatabaseUrl
  )
  return connectionString
}

export const targetDatabaseUrl = async () => {
  const act = activity('Target database URL', 'Checking...')
  const projectConfig = await config.getProject()
  if (!projectConfig.targetDatabaseUrl) {
    act.fail('Could not find a target database URL')
    logError(
      [
        'A target database URL is required:',
        'Run **snaplet setup** or use the **SNAPLET_TARGET_DATABASE_URL** environment variable',
      ],
      'SNAPLET_TARGET_DATABASE_URL=postgres://username:password@host:5432/database'
    )
    return await exitWithError('TARGET_DATABASE_URL_REQUIRED')
  }
  act.done()
  const connectionString = await validConnectionString(
    projectConfig.targetDatabaseUrl
  )
  return connectionString
}
