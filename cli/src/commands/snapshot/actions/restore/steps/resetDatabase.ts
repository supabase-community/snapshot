import { resetDb } from '@snaplet/sdk/cli'

import { spinner } from '~/lib/spinner.js'

import SnapshotImporter from '../lib/SnapshotImporter/SnapshotImporter.js'

export const resetDatabase = async (importer: SnapshotImporter) => {
  const act = spinner('Database: Dropping schemas...').start()
  const errors = await resetDb(importer.connString)

  if (!errors.length) {
    act.succeed('Database: Schemas dropped')
  } else {
    act.warn('Database: Not all schemas dropped')
  }

  return errors
}
