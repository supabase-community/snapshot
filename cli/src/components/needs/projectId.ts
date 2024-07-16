import { config } from '~/lib/config.js'
import { exitWithError } from '~/lib/exit.js'

import { logError } from './logError.js'

export const projectId = async (exit = true) => {
  const projectConfig = await config.getProject()
  if (!projectConfig.projectId) {
    if (!exit) {
      throw new Error('PROJECT_ID_REQUIRED')
    }
    logError(
      [
        'A Snaplet project is required:',
        'Run *snaplet project setup* or use the *SNAPLET_PROJECT_ID* environment variable.',
      ],
      'Example: SNAPLET_PROJECT_ID=42 snaplet config pull'
    )
    return await exitWithError('PROJECT_ID_REQUIRED')
  }
  return projectConfig.projectId
}
