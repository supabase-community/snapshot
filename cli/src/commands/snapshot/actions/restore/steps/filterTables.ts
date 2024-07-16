import { activity } from '~/lib/spinner.js'

import SnapshotImporter from '../lib/SnapshotImporter/SnapshotImporter.js'

export const filterTables = async (
  importer: SnapshotImporter,
  options: {
    tables: string[]
    excludeTables: string[]
  }
) => {
  const act = activity('Filter tables', 'Filter...')
  const errors: string[] = []

  importer.on('filterTables:error', (payload) => {
    errors.push(
      `[Filter Tables] Warning: ${payload.error.message} (${payload.schema}.${payload.table})`
    )
  })

  await importer.filterTables(options.tables, options.excludeTables)

  if (errors.length) {
    act.fail('Truncated with errors (See restore.log)')
  } else {
    act.pass('Truncated')
  }

  return errors
}
