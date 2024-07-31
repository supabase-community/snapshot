import {
  TransformError,
  generateSnapshotBasePath,
  SnapshotSummary,
  generateUniqueName,
  calculateDirectorySize,
  writeSnapshotSummary,
  EncryptionPayload,
  generateEncryptionPayload,
  withDbClient,
  introspectDatabaseV3,
  SnapletConfigV2,
  isSupabaseUrl,
} from '@snaplet/sdk/cli'

import cliProgress, { SingleBar } from 'cli-progress'
import fs from 'fs-extra'

import { needs } from '~/components/needs/index.js'
import { exitWithError } from '~/lib/exit.js'

import { CommandOptions } from './captureAction.types.js'
import { addCaptureErrorContext } from './lib/addCaptureErrorContext.js'
import { getSnapshotPaths } from './lib/paths.js'
import { displayErrors } from './steps/errors.js'
import {
  displayMinimalCopyProgress,
  displayMultibarCopyProgress,
} from './lib/displayProgress.js'
import { xdebugCapture } from './lib/debugCapture.js'
import { captureSnapshot } from './steps/captureSnapshot.js'
import { CopyTablesEvent } from './lib/subsetV3/steps/emitterToOnUpdate.js'
import { SnapshotTable } from '@snaplet/sdk/cli'
import { writeSnapshotStructure } from '~/components/readConfig.js'
import { initConfigOrExit } from '~/lib/initConfigOrExit.js'
import { SnapshotProgress } from './lib/subsetV3/steps/events.js'

async function resilientUpdateSnapshotProgress(progress: SnapshotProgress) {
  if (progress.step === 'data' && progress.metadata) {
    displayMinimalCopyProgress({
      name: progress.metadata.table,
      done: progress.metadata.copiedRows === progress.metadata.totalRows,
      rows: progress.metadata.copiedRows,
      totalRows: progress.metadata.totalRows,
    })
  }
}

export async function handler(options: CommandOptions) {
  const connString = await needs.sourceDatabaseUrl()
  await needs.databaseConnection(connString)

  const date = new Date()

  const summary: SnapshotSummary = {
    snapshotId: process.env.SNAPLET_SNAPSHOT_ID,
    date,
    // context(peterp, 01 June 2023): This name is used to create a temporary storage location. We do not use this name in Snaplet Cloud.
    // this is causing a problem - in our tests we create a unique name using `snaplet ss create`
    // but we don't use that same value when sharing it.
    // i believe we overwrite it.
    name: options.uniqueName ?? generateUniqueName('ss'),
    tables: [],
    tags: options.tags,
    isSupabaseConnection: isSupabaseUrl(connString.toString()),
  }

  const destinationPath =
    options.destinationPath ??
    (await generateSnapshotBasePath({
      date: summary.date,
      name: summary.name,
    }))
  const paths = await getSnapshotPaths(destinationPath)

  // step one, introspect
  const structure = await withDbClient(introspectDatabaseV3, {
    connString: connString.toString(),
  })

  const { config } = await initConfigOrExit(
    undefined,
    // We override file config with the parameter comming from the CLI if it exists
    options.transformMode
      ? ({
          transform: {
            $mode: options.transformMode,
          },
        } as SnapletConfigV2)
      : undefined
  )
  await writeSnapshotStructure(paths, structure)
  await fs.writeFile(paths.config, await config.getSnapletSource())

  let multibar = new cliProgress.MultiBar(
    {
      format: '{displayName} | {bar} {percentage}% | {value}/{total}',
      clearOnComplete: false,
      hideCursor: true,
      noTTYOutput: !process.stderr.isTTY,
      notTTYSchedule: 9999999,
      forceRedraw: true,
    },
    cliProgress.Presets.shades_grey
  )

  const bars: { name: string; bar: SingleBar }[] = []
  const errors: Error[] = []
  let tables: SnapshotTable[] = []

  try {
    tables = await captureSnapshot(
      {
        structure: structure,
        paths: paths,
        config: config,
      },
      async (type: string, data: any): Promise<void> => {
        if (['tables', 'schema', 'structure'].indexOf(type) === -1) {
          xdebugCapture(`Event "${type}":`, data)
        }

        switch (type) {
          case 'progress':
            await resilientUpdateSnapshotProgress(data)
            break
          case 'subsetting':
            break
          case 'copyProgress':
            if (typeof data == 'object') {
              const event = data as CopyTablesEvent
              if (event.status === 'FAILURE') {
                errors.push(event.error)
              } else {
                displayMultibarCopyProgress(multibar, bars, event)
              }
            }
            break
        }
        // Ensure to any pending events are processed before continuing
        await setTimeout(() => {}, 0)
      }
    )
  } catch (e) {
    if (e instanceof TransformError) {
      console.log('-'.repeat(80))
      // eslint-disable-next-line no-console
      console.error(e.toString())
      console.log('-'.repeat(80))
      await exitWithError('SNAPSHOT_CAPTURE_TRANSFORM_ERROR')
    } else {
      await addCaptureErrorContext(e as Error, connString)
      throw e
    }
  }

  multibar.stop()

  // This summary is a bit of a nightmare.
  // We have fields in the "Snapshot table" that we are duplicating here
  // and the inconsistencies in that approach is going to suck.
  // We should probably just have a single source of truth for this.
  // Because we want to "mix" local and cloud snapshots I think we need to stick to the JSON format
  // but remove the duplicates in the snapshot table.
  // or not duplicate the data in the JSON file.
  // We can have a single point to "fetch" the summary, and construct it from the TABLE.

  let encryptionPayload: EncryptionPayload | undefined
  const publicKey = (await config.getProject()).publicKey
  if (publicKey) {
    encryptionPayload = await generateEncryptionPayload(publicKey)
  }

  await writeSnapshotSummary(paths.summary, {
    ...summary,
    // context(khaya, 15 July), if S3 mode is added,
    // origin may be set to "CLOUD", if for example
    // a AWS key is present.
    origin: 'LOCAL',
    tables,
    totalSize: calculateDirectorySize(paths.tables),
    message: options.message,
    encryptionPayload: encryptionPayload?.public,
    // todo(justinvdm, 13 June 2023): Remove once all users are using v2 of encryption
    encryptedSessionKey: encryptionPayload?.public.encryptedSessionKeyHex,
  })

  if (errors.length) {
    process.stderr.write('\nCapture failed:\n\n')
    process.stderr.write(displayErrors(errors) + '\n')
    return exitWithError('SNAPSHOT_CAPTURE_INCOMPLETE_ERROR')
  } else {
    console.log('\nCapture complete!')
    console.log(`To share this snapshot, run:`)
    console.log(`snaplet snapshot share ${summary.name}`)
  }
}
