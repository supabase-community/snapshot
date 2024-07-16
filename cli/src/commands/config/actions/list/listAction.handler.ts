import { ConnectionString } from '@snaplet/sdk/cli'
import _ from 'lodash'

import { config } from '~/lib/config.js'
import { activity } from '~/lib/spinner.js'
import { trpc } from '~/lib/trpc.js'

export async function handler() {
  const act = activity('Snaplet Status', 'Gathering')
  act.info('Reading config')
  console.log()

  const projectConfig = await config.getProject()

  if (_.isEmpty(projectConfig)) {
    act.info('This does not appear to be a Snaplet project.')
    return act.done()
  }

  if (projectConfig.targetDatabaseUrl) {
    const connectionString = new ConnectionString(
      projectConfig.targetDatabaseUrl
    )
    console.log(
      `Snaplet configured to connect to target: ${connectionString.toScrubbedString()}`
    )
  }

  if (projectConfig.projectId) {
    const projects = await trpc.project.list.query()
    const project = projects.find(({ id }) => id == projectConfig.projectId)
    if (project?.name) {
      console.log(
        `Project is linked to the Snaplet Cloud project: ${project?.name}`
      )
    } else {
      console.log('Project is not linked to Snaplet Cloud')
    }
  } else {
    console.log('Project is not linked to Snaplet Cloud')
  }

  act.done()
  console.log()
}
