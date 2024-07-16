import { exitWithError } from '~/lib/exit.js'
import { fmt } from '~/lib/format.js'
import { discordLink } from '~/lib/links.js'
import { getSentry } from '~/lib/sentry.js'
import { spinner } from '~/lib/spinner.js'

import SnapshotImporter from '../lib/SnapshotImporter/SnapshotImporter.js'

export const importSchema = async (importer: SnapshotImporter) => {
  const act = spinner()
  const errors: string[] = []

  importer
    .on('importSchema:start', () => {
      act.start('Import schema: Starting...')
    })
    .on('importSchema:complete', () => {
      if (errors.length) {
        act.warn('Import schema: Imported with errors (See restore.log)')
      } else {
        act.succeed('Import schema: Imported')
      }
    })
    .on('importSchema:parsingError', async (payload) => {
      act.fail('Import schema: Fatal parsing error')
      console.log(
        fmt(`
Error: ${payload.error}

We could not restore your snapshot because we failed to parse
the ${importer.schemasTerminalLink} file.

Context: This should not ordinarily happen, since your schema is exported
from a working database. We have been notified of this exception,
but please reach out to us on ${discordLink}.
          `)
      )
      await exitWithError('IMPORTER_SCHEMA_PARSE')
    })
    .on('importSchema:statementError', async (payload) => {
      // It can happen that some specific statements from the schema fail to import, this is where we log it
      // e.g. A table uses an extension but the extension is in another schema that is not included.
      errors.push(
        `[Schema] Warning: ${payload.error.message}, statement: "${payload.statement}"`
      )
    })

  try {
    await importer.importSchema()
  } catch (e) {
    if (e instanceof Error) {
      errors.push(e.message)
    }
    const Sentry = await getSentry()
    Sentry.captureException(e)
  }

  return errors
}
