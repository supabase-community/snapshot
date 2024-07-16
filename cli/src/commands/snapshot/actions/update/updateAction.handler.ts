import { getHosts } from '~/lib/hosts/hosts.js'

import { CommandOptions } from './updateAction.types.js'
import { findSnapshotSummary } from '~/components/findSnapshotSummary.js'

export async function handler({ snapshotName }: CommandOptions) {
  const hosts = await getHosts({ only: ["abspath", "local"]})

  const snapshot = await findSnapshotSummary(
    {
      startsWith: snapshotName,
    },
    hosts
  )
  if (!snapshot.summary || !snapshot.summary.snapshotId) {
    throw new Error('Summary not found for snapshot. This should not happen.')
  }
}
