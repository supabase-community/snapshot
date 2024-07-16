import { findSnapshotSummary } from '~/components/findSnapshotSummary.js'
import { exitWithError } from '~/lib/exit.js'
import { getHosts, HostType } from '~/lib/hosts/hosts.js'
import { logError } from './logError.js'

export const snapshot = async (props: {
  hosts: HostType[]
  tags: string[]
  latest: boolean
}) => {
  const hosts = await getHosts({ only: props.hosts })

  const snapshot = await findSnapshotSummary(
    {
      latest: props.latest,
      tags: props.tags,
    },
    hosts
  )

  if (!snapshot) {
    logError([
      `Could not find ${
        props.latest && 'latest'
      }} snapshot with tags "${props.tags.join(', ')}" in ${props.hosts.join(
        ', '
      )}`,
    ])
    return exitWithError('SNAPSHOT_NONE_AVAILABLE')
  }

  return snapshot
}
