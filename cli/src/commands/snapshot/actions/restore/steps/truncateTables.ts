import { activity } from '~/lib/spinner.js'

import SnapshotImporter from '../lib/SnapshotImporter/SnapshotImporter.js'

export const truncateTables = async (importer: SnapshotImporter) => {
  const act = activity('Truncate tables', 'Truncating...')
  const errors: string[] = []

  importer.on('truncateTables:error', (payload) => {
    errors.push(
      `[Data] Warning: ${payload.error.message} (${payload.schema}.${payload.table})`
    )
  })

  await importer.truncateTables()

  if (errors.length) {
    act.fail('Truncated with errors (See restore.log)')
  } else {
    act.pass('Truncated')
  }

  return errors
}
