import type { CloudSnapshot, SnapshotStatus } from '@snaplet/sdk/cli'
import { SnapshotOrigin } from '@snaplet/sdk/cli'
import c from 'ansi-colors'
import columnify from 'columnify'
import * as timeago from 'timeago.js'

import { getHosts } from '~/lib/hosts/hosts.js'
import { prettyBytes } from '~/lib/prettyBytes.js'
import { activity } from '~/lib/spinner.js'

import { CommandOptions } from './listAction.types.js'
import { findSnapshotSummary } from '~/components/findSnapshotSummary.js'

export async function handler({ tags, latest, nameOnly }: CommandOptions) {
  const act = activity('Snapshots', 'Fetching...')
  const hosts = await getHosts()

  let snapshots: CloudSnapshot[]
  if (latest) {
    const latestSnapshot = await findSnapshotSummary(
      {
        latest: true,
        tags,
      },
      hosts
    )
    snapshots = [latestSnapshot]
  } else if (tags?.length) {
    snapshots = await hosts.filterSnapshots({ tags })
  } else {
    snapshots = await hosts.getAllSnapshots()
  }
  act.done()

  const data = snapshots.map((s) => {
    return {
      name: s?.summary?.name,
      status: formatStatus(s?.status),
      created: formatDate(s.summary.date),
      size: formatSize(s?.summary?.totalSize),
      tags: formatTags(s?.summary?.tags),
      src: formatOrigin(s?.summary?.origin),
      cached: typeof s?.cachePath === 'string',
    }
  })
  if (nameOnly) {
    nameOnlyLog(data)
  } else {
    fullLog(data)
  }
}

function nameOnlyLog(data: Array<{ name: string }>) {
  for (const { name } of data) {
    console.log(name)
  }
}

function fullLog(
  data: Array<{
    name: string
    status: string
    created: string
    size: string
    tags: string
    src: string | undefined
    cached: boolean
  }>
) {
  console.log(
    columnify(data, {
      columns: ['name', 'status', 'created', 'size', 'tags', 'src'],
      config: { message: { maxWidth: 40, truncateMarker: '...' } },
      columnSplitter: ' '.repeat(4),
      showHeaders: true,
      truncate: true,
    })
  )
  console.log()
  console.log(`Found ${data.length} snapshot${data.length === 1 ? '' : 's'}`)
}

const formatOrigin = (origin?: SnapshotOrigin) => {
  switch (origin) {
    case 'CLOUD':
      return '☁️'
    case 'LOCAL':
      return '💻'
    case 'UNKNOWN':
      return '?'
  }
}

const formatDate = (date?: Date) => {
  if (date) {
    return timeago.format(date)
  } else {
    return '--'
  }
}

const formatSize = (totalSize?: number) => {
  if (totalSize) {
    return totalSize >= 0 ? prettyBytes(totalSize.toString()) : '--'
  }
  return '--'
}

const formatStatus = (status: keyof typeof SnapshotStatus) => {
  const statusColors = {
    IN_PROGRESS: c.grey,
    TIMEOUT: c.red,
    FAILURE: c.red,
    SUCCESS: c.green,
  }

  const humanReadableStatus: Record<string, string> = {
    IN_PROGRESS: 'IN PROGRESS',
  }

  const colorForStatus = statusColors[status] || c.grey

  const humanReadable = humanReadableStatus[status] || status

  return colorForStatus(humanReadable)
}

const formatTags = (tags?: string[]) => {
  return tags?.join(',') ?? ''
}
