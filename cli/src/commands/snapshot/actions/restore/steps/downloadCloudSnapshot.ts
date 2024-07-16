import { activity } from '~/lib/spinner.js'

import SnapshotCache from '../lib/SnapshotCache.js'
import {
  downloadSnapshot,
  downloadSnapshotFile,
} from '~/lib/snapshotStorage.js'
import { writeSnapshotSummary } from '@snaplet/sdk/cli'

interface DownloadCloudOptions {
  snapshotId: string
  snapshotCache: SnapshotCache
  schemaOnly: boolean
  showProgress: boolean
}

export const downloadCloudSnapshot = async ({
  snapshotId,
  snapshotCache,
  schemaOnly,
  showProgress,
}: DownloadCloudOptions) => {
  const act = activity('Snapshot', 'Downloading...')
  let transferred = 0
  if (schemaOnly) {
    await downloadSnapshotFile({
      filename: 'schemas.sql',
      snapshotId,
      destination: snapshotCache.paths.schemas,
    })
  } else {
    transferred = await downloadSnapshot({
      paths: snapshotCache.paths,
      snapshotId,
      onProgress: async (percentage) => {
        if (!showProgress) return
        act.info(`Downloading... [${percentage}%]`)
      },
    })
  }
  // TODO: Grab summary from API.
  await writeSnapshotSummary(
    snapshotCache.paths.summary,
    snapshotCache.summary.summary
  )
  act.done()

  return transferred
}
