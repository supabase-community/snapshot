import cliProgress from 'cli-progress'

import { prettyBytes } from '~/lib/prettyBytes.js'
import { activity } from '~/lib/spinner.js'

import SnapshotImporter from '../lib/SnapshotImporter/SnapshotImporter.js'
import { RestoreError } from '../lib/restoreError.js'

function setupImportTableProgressReport(importer: SnapshotImporter) {
  const multibar = new cliProgress.MultiBar(
    {
      format: '{bar} | {tableName} [{totalDataSize}]',
      clearOnComplete: false,
      barsize: 20,
      noTTYOutput: !process.stderr.isTTY,
      notTTYSchedule: 9999999,
      forceRedraw: true,
    },
    cliProgress.Presets.shades_classic
  )

  const tablesToImport = importer.tables

  const progressBarMap = tablesToImport.reduce(
    (acc, table) => {
      acc[table.table] = multibar.create(100, 0, {
        tableName: table.table,
        totalDataSize: '--',
      })
      return acc
    },
    {} as Record<string, cliProgress.SingleBar>
  )

  importer
    .on('importTablesData:start', (payload) => {
      progressBarMap[payload.table].update(0, {
        totalDataSize: prettyBytes(payload.totalDataSize),
      })
    })
    .on('importTablesData:update', (payload) => {
      const importPercentage =
        (payload.totalDataRead / payload.totalDataSize) * 100
      progressBarMap[payload.table].update(importPercentage, {
        importPercentage: importPercentage.toFixed(2),
      })
    })
    .on('importTablesData:complete', () => {
      multibar.stop()
    })
}

export const importTablesData = async (importer: SnapshotImporter) => {
  const errors: string[] = []

  if (importer.showProgress) {
    setupImportTableProgressReport(importer)
  }

  importer.on('importTablesData:error', (payload) => {
    if (payload.error instanceof RestoreError) {
      const table = `"${payload.error.context.schema}"."${payload.error.context.table}"`
      errors.push(
        [
          `[Data] Error: Received the following error when inserting into ${table}:`,
          payload.error.toString(),
          `The table ${table} restoration failed, this error might be an indication of an issue in your data`,
        ].join('\n')
      )
    } else {
      errors.push(
        `[Data] Warning: ${payload.error.message} (${payload.schema}.${payload.table})`
      )
    }
  })

  await importer.importTablesData(importer.encryptionPayload)

  // TODO: this is weird, we should have a global spinner above the multibar from the beginning
  const act = activity('Table data', 'Importing...')
  if (errors.length) {
    act.fail('Imported with errors (See restore.log)')
  } else {
    act.pass('Imported')
  }
  return errors
}
