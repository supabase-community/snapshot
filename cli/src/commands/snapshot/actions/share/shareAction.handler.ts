import { getHosts } from '~/lib/hosts/hosts.js'
import type { CommandOptions } from './shareAction.types.js'
import { findSnapshotSummary } from '~/components/findSnapshotSummary.js'
import { exitWithError } from '~/lib/exit.js'
import { encryptAndCompressTables } from './steps/encryptAndCompressTables.js'
import SnapshotCache from '../restore/lib/SnapshotCache.js'

import { encryptionPayloadStep } from './steps/encryptionPayload.js'
import { activity } from '~/lib/spinner.js'
import { uploadSnapshot } from '~/lib/snapshotStorage.js'
import { getOrCreateSnapshotIdStep } from './steps/getOrCreateSnapshot.js'
import { needs } from '~/components/needs/index.js'
import { snapshotListStorage } from '../list/lib/storage.js'
import path from 'path'

export async function handler(options: CommandOptions) {
  const { snapshotName: startsWith, latest, tags, noEncrypt } = await options

  const isEncryptionSelected = noEncrypt === false

  const settings = await needs.s3Settings()

  const hosts = await getHosts({ only: ['local', 'abspath'] })
  const sss = await findSnapshotSummary(
    {
      latest,
      startsWith,
      tags,
    },
    hosts
  )

  if (!sss.cachePath) {
    console.log('Error: A snapshot must be cached in order to be shared')
    await exitWithError('UNHANDLED_ERROR')

    return
  }

  const cache = new SnapshotCache(sss)

  /**
   * if encryption is enabled, read the user config and
   * generate a payload we use to encrypt a snapshot.
   * */
  const encryptionPayload = isEncryptionSelected
    ? await encryptionPayloadStep()
    : undefined

  await encryptAndCompressTables({ paths: cache.paths, encryptionPayload })

  /**
   * upload snapshot to object storage
   */
  const snapshotId = await getOrCreateSnapshotIdStep(sss)
  const act = activity('Snapshot', 'Uploading...')

  try {
    await uploadSnapshot(snapshotId, cache.paths, {
      onProgress: async (percentage) => {
        act.info(`Uploading... [${percentage}%]`)
      },
      settings,
    })
  } catch (err: any) {
    act.fail(err?.message)
    await exitWithError('SNAPSHOT_CAPTURE_INCOMPLETE_ERROR')
  } finally {
    act.done()
  }

  const storage = await snapshotListStorage(
    settings,
    path.join(cache.paths.base, '..')
  )

  storage.insertSnapshot({
    id: snapshotId,
    name: sss.summary.name,
    tags: sss.summary.tags,
    createdAt: new Date().toString(),
  })

  await storage.commit()

  console.log(`Snapshot "${sss.summary.name}" shared`)
}
