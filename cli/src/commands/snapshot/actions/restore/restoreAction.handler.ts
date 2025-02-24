import {
  EncryptionPayload,
  hydrateEncryptionPayload,
  isSupabaseUrl,
} from '@snaplet/sdk/cli'
import fs from 'fs'
import prompts from 'prompts'

import { findSnapshotSummary } from '~/components/findSnapshotSummary.js'
import { needs } from '~/components/needs/index.js'
import { exitWithError } from '~/lib/exit.js'
import { fmt } from '~/lib/format.js'
import { teardownAndExit } from '~/lib/handleTeardown.js'
import { getHosts } from '~/lib/hosts/hosts.js'

import SnapshotCache from './lib/SnapshotCache.js'
import SnapshotImporter from './lib/SnapshotImporter/SnapshotImporter.js'
import { CommandOptions } from './restoreAction.types.js'
import { createConstraints } from './steps/createConstraints.js'
import { displaySnapshotSummary } from './steps/displayInfo.js'
import { dropConstraints } from './steps/dropConstraints.js'
import { fixSequences } from './steps/fixSequences.js'
import { fixViews } from './steps/fixViews.js'
import { importSchema } from './steps/importSchema.js'
import { importTablesData } from './steps/importTableData.js'
import { resetDatabase } from './steps/resetDatabase.js'
import { truncateTables } from './steps/truncateTables.js'
import { vacuumTables } from './steps/vacuumTables.js'
import { filterTables } from './steps/filterTables.js'

export async function handler(options: CommandOptions) {
  const connString = await needs.targetDatabaseUrl()
  await needs.databaseConnection(connString)

  const isLocalhost =
    connString.domain === 'localhost' || connString.host === '127.0.0.1'

  if (options.yes === false && !isLocalhost) {
    const result = await prompts({
      type: 'confirm',
      name: 'input',
      message: `Restored snapshot to database not on localhost? "${connString.toScrubbedString()}". This is destructive. Proceed?`,
    })
    // When Ctrl-C is pressed, the result is undefined, so we default to false.
    const confirmed = result?.input ?? false
    if (!confirmed) {
      console.log('Aborted')
      return await teardownAndExit(0)
    }
  }

  if (options.data === false && options.schema === false) {
    console.log("Error: You can't specify both --no-data and --no-schema")
    return await exitWithError('UNHANDLED_ERROR')
  }

  if (options.tables.length > 0 && options.excludeTables.length > 0) {
    console.log("Error: You can't specify both --tables and --exclude-tables")
    return await exitWithError('UNHANDLED_ERROR')
  }
  const { snapshotName, progress, latest, tags, reset, data, schema } = options

  console.log('┌ Resolution step')

  const hosts = await getHosts()
  const sss = await findSnapshotSummary(
    { latest, startsWith: snapshotName, tags },
    hosts
  )
  if (!sss?.summary) {
    throw new Error('Summary not found for snapshot. This should not happen.')
  }

  // if a user is restoring to a supabase target, we will automatically add the `--no-reset` flag
  if (
    isSupabaseUrl(connString) ||
    // supabase local dev instances run on `localhost:54322`, so we first check if the snapshot
    // was taken from a supabase instance, and then check if the target is a local dev instance
    (sss.summary.isSupabaseConnection &&
      isLocalhost &&
      connString.port === 54322)
  ) {
    // the user has not told us how to handle `reset`
    // so we add the `--no-reset` flag automatically.
    if (!options.isResetExplicitlySet && options.reset !== false) {
      options.reset = false
    }
  }

  displaySnapshotSummary(sss)

  // TODO: Move these into a seperate functions.
  let encryptionPayload: EncryptionPayload | undefined

  // todo(justinvdm, 13 June 2023): Remove once all users are using v2 encryption snapshots
  if (!sss?.summary?.encryptionPayload && sss?.summary?.encryptedSessionKey) {
    // sss.summary.encryptionPayload = // TODO_BEFORE_REVIEW: read encryption file from a value
  }

  if (sss?.summary?.encryptionPayload) {
    const privateKey = await needs.privateKey()
    try {
      encryptionPayload = hydrateEncryptionPayload(
        privateKey,
        sss.summary.encryptionPayload
      )
    } catch (err: any) {
      if (
        // handle private key mismatch
        err.message.includes('error:02000079:rsa routines::oaep decoding error')
      ) {
        await failDueToPrivateKeyMismatch()
      } else if (
        // handle invalid private key
        err.message.includes('error:1E08010C:DECODER routines::unsupported')
      ) {
        await failDueToInvalidPrivateKey()
      } else {
        throw err
      }
    }
  }

  const snapshotCache = new SnapshotCache(sss)
  console.log('┌ Fetch step')

  const resetDatabaseSteps = [resetDatabase]
  const importSchemaSteps = [importSchema]
  const dataRestoreSteps = [
    filterTables,
    dropConstraints,
    ...(options.truncate !== false ? [truncateTables] : []),
    importTablesData,
    createConstraints,
    fixViews,
    fixSequences,
    vacuumTables,
  ]
  const restoreSteps = [
    // if --no-reset (or --data-only or --no-schema) flag skip the reset
    ...(reset && schema ? resetDatabaseSteps : []),
    // if --no-schema (or --data-only) skip the schema import
    ...(schema ? importSchemaSteps : []),
    // if --no-data (or --schema-only) skip the data import
    ...(data ? dataRestoreSteps : []),
  ]
  if (!schema) {
    console.log('┌ Restore step (data-only)')
  } else {
    console.log(`┌ Restore step${!reset ? ' (no-reset)' : ''}`)
  }

  const importer = new SnapshotImporter({
    summary: sss,
    cache: snapshotCache as SnapshotCache,
    connString,
    encryptionPayload,
    showProgress: progress,
    // if --no-schema or --no-reset flag we need to do a partial restore skipping columns who are not already in the target database
    partialRestore: !schema || !reset,
  })
  let errors: string[] = []
  for (const step of restoreSteps) {
    const stepErrors = await step(importer, {
      tables: options.tables ?? [],
      excludeTables: options.excludeTables ?? [],
    })
    errors = [...errors, ...stepErrors]
  }

  if (errors) {
    fs.writeFileSync(snapshotCache.paths.restoreLog, errors.join('\n'))
    console.log()
    console.log(errors.slice(0, 10).join('\n'))
    if (errors.length >= 10) {
      console.log(`... and ${errors.length - 10} other warnings.`)
    }
    console.log(`Wrote ${snapshotCache?.restoreLogTerminalLink}`)
    if (errors.some((e) => e.startsWith('[Data] Error:'))) {
      await exitWithError('SNAPSHOT_RESTORE_ERROR')
    }
  }

  console.log()
  console.log('🎉 Snapshot restored')
}

const failDueToPrivateKeyMismatch = async () => {
  console.log(
    fmt(`***ERROR***

Private key mismatch. The private key you have saved to *.snaplet/id_rsa* does not match the public key saved in your project config.

Please run *snaplet setup* or save a private key to *.snaplet/id_rsa*`)
  )
  await exitWithError('CONFIG_PK_ERROR')
}

const failDueToInvalidPrivateKey = async () => {
  console.log(
    fmt(`***ERROR***

    Invalid private key. The private key you have saved to *.snaplet/id_rsa* may be invalid.

    Please run *snaplet setup* or save a private key to *.snaplet/id_rsa*
    `)
  )
  await exitWithError('CONFIG_PK_ERROR')
}
