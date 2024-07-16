import { activity } from '~/lib/spinner.js'

import SnapshotImporter from '../lib/SnapshotImporter/SnapshotImporter.js'

export async function createConstraints(importer: SnapshotImporter) {
  const errors: string[] = []

  const act = activity('Constraints', 'Creating...')

  importer.on('createConstraints:error', (payload) => {
    errors.push(
      `[Create constraints] Warning: ${payload.error.message} (${payload.schema}.${payload.table})`
    )
  })

  await importer.createConstraints()

  if (errors.length) {
    act.fail('Created with errors (See restore.log)')
  } else {
    act.pass('Created')
  }

  return errors
}
