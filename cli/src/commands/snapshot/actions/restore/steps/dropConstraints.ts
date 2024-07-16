import { activity } from '~/lib/spinner.js'

import SnapshotImporter from '../lib/SnapshotImporter/SnapshotImporter.js'

export const dropConstraints = async (importer: SnapshotImporter) => {
  const act = activity('Drop constraints', 'Dropping...')
  const errors: string[] = []

  importer.on('dropConstraints:error', (payload) => {
    errors.push(
      `[Drop constraints] Warning: ${payload.error.message} (${payload.schema}.${payload.table})`
    )
  })

  await importer.dropConstraints()

  if (errors.length) {
    act.fail('Dropped with errors (See restore.log)')
  } else {
    act.pass('Dropped')
  }

  return errors
}
