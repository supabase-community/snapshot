import { createId } from '@paralleldrive/cuid2'
import SnapshotCache from '../../restore/lib/SnapshotCache.js'
import { CloudSnapshot } from '@snaplet/sdk/api'

import { checkIfObjectExists, generateSnapshotFileKey } from '~/lib/s3.js'

/**
 * create using cuid2, thats if a snapshot summary does not
 * have a `snaphotId` field, if the `snapshotId` field is present
 * use it to check if the snapshot hasn't already been downloaded
 */
export const getOrCreateSnapshotIdStep = async (
  snapshotSummary: CloudSnapshot,
  options?: { skipFileCheck: boolean }
) => {
  const snapshotId = snapshotSummary.summary.snapshotId

  if (snapshotId) {
    const snaphotSummaryKey = generateSnapshotFileKey({
      filename: 'summary.json',
      snapshotId,
    })

    const isFileFound = await checkIfObjectExists(snaphotSummaryKey, snaphotSummaryKey)
    if (isFileFound) {
      // warn the user, and ask if they happy to proceed.
    }

    return snapshotId
  } else {
    return createId()
  }
}
