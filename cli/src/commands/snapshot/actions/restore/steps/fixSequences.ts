import { activity } from '~/lib/spinner.js'

import SnapshotImporter from '../lib/SnapshotImporter/SnapshotImporter.js'

export const fixSequences = async (importer: SnapshotImporter) => {
  const errors: string[] = []

  const act = activity('Database sequences', 'Resetting...')

  importer
    .on('fixSequences:complete', () => {
      if (errors.length) {
        act.fail('Reset with warnings (See restore.log)')
      } else {
        act.pass('Reset')
      }
    })
    .on('fixSequences:error', (payload) => {
      errors.push(`[Sequences] Warning: ${payload.error.message}`)
    })

  await importer.fixSequences()

  return errors
}
