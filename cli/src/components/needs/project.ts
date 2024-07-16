import { exitWithError } from '~/lib/exit.js'
import { activity } from '~/lib/spinner.js'
import { trpc } from '~/lib/trpc.js'

import { logError } from './logError.js'

export const project = async (projectId: string) => {
  const act = activity('Snaplet project', 'Fetching...')
  const project = await trpc.project.getById.query({
    projectId,
  })
  if (!project) {
    act.fail('Not found')
    logError([
      'A Snaplet project matching "${projectId}" could not be found.',
      'Run **snaplet setup** to update your configuration.',
    ])
    return await exitWithError('PROJECT_ID_REQUIRED')
  }
  act.done()
  return project
}
