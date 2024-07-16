import { activity } from '~/lib/spinner.js'

import SnapshotImporter from '../lib/SnapshotImporter/SnapshotImporter.js'

export async function vacuumTables(importer: SnapshotImporter) {
  const errors: string[] = []

  const act = activity('Vacuum', 'Working...')

  importer
    .on('vacuumTables:complete', () => {
      if (errors.length) {
        act.fail('Complete with warnings (See restore.log)')
      } else {
        act.pass('Done')
      }
    })
    .on('vacuumTables:error', (payload) => {
      errors.push(`[Vacuum] Warning: ${payload.error.message}`)
    })

  await importer.vacuumTables()

  return errors
}
