import type { CloudSnapshot } from '@snaplet/sdk/cli'
import { formatTime } from '@snaplet/sdk/cli'

import { isSnapshotDeployable } from '@snaplet/sdk/cli'

import c from 'ansi-colors'
import columnify from 'columnify'
import prompts from 'prompts'

import { IS_CI } from '~/lib/constants.js'
import { exitWithError } from '~/lib/exit.js'
import type { Hosts } from '~/lib/hosts/hosts.js'
import { activity } from '~/lib/spinner.js'

export const findSnapshotSummary = async (
  rules: {
    latest?: boolean
    startsWith?: string
    tags?: string[]
    interactive?: boolean
    includeEncrypted?: boolean
  },
  hosts: Hosts,
  options?: {
    hint?: string
    markDisabledSnapshots?: boolean
  }
) => {
  rules = {
    latest: false,
    interactive: true,
    includeEncrypted: true,
    ...rules,
  }
  const defaultOptions = { hint: 'Select a snapshot' }
  options = options ? { ...defaultOptions, ...options } : defaultOptions

  const act = activity('Snapshot', 'Finding...')

  let snapshot: CloudSnapshot | undefined
  let snapshots: CloudSnapshot[]

  if (rules?.startsWith || rules?.tags) {
    snapshots = await hosts.filterSnapshots(rules)
  } else {
    snapshots = await hosts.getAllSnapshots()
  }
  // We can only restore successful snapshots
  snapshots = snapshots.filter((ss) => ss.status === 'SUCCESS')

  if (rules.includeEncrypted === false) {
    snapshots = snapshots.filter((ss) => ss.encryptedSessionKey === undefined)
  }

  act.done()

  if (snapshots.length === 0) {
    act.fail('0 successful snapshots found')
    return await exitWithError('SNAPSHOT_NONE_AVAILABLE')
  }

  if (snapshots.length === 1) {
    return snapshots[0]
  }

  if (rules.latest) {
    snapshot = snapshots[0]
  } else if (rules.interactive === true && IS_CI === false) {
    const result = await prompts({
      type: 'select',
      message: 'Snapshot',
      hint: options.hint,
      name: 'snapshot',
      choices: createSnapshotsChoices(snapshots, {
        markDisabledSnapshots: options.markDisabledSnapshots,
      }),
    })
    snapshot = result.snapshot as CloudSnapshot
  } else if (snapshots.length > 1) {
    act.fail(`Found ${snapshots.length} snapshots`)
    console.log(`Narrow search string, use --latest or --tags`)
    console.log('Found:')
    for (const s of snapshots) {
      console.log('-', s?.summary?.name)
    }
    return await exitWithError('UNHANDLED_ERROR')
  }

  if (!snapshot) {
    act.fail('0 successful snapshots found')
    return await exitWithError('SNAPSHOT_NONE_AVAILABLE')
  }

  return snapshot
}

const createSnapshotsChoices = (
  summaries: CloudSnapshot[],
  options = { markDisabledSnapshots: false as boolean | undefined }
) => {
  return columnify(
    summaries.map((s) => {
      return [
        c.bold(s.summary.name),
        formatTime(s.summary.date),
        s.summary.tags?.join(',') ?? '',
        options.markDisabledSnapshots &&
        isSnapshotDeployable(s.summary).isDeployable === false
          ? 'not supported'
          : undefined,
      ]
    }),
    { showHeaders: false }
  )
    .split('\n')
    .map((line, i) => ({ title: line, value: summaries[i] }))
}
