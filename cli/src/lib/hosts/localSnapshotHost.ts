import { readSnapshotSummary, CloudSnapshot } from '@snaplet/sdk/cli'
import fg from 'fast-glob'
import path from 'path'

import { FilterSnapshotRules, Host, sortSnapshots } from './hosts.js'

export class LocalSnapshotHost implements Host {
  public type = 'local' as const
  private storagePath: string

  constructor(o: { storagePath: string }) {
    this.storagePath = o.storagePath
  }

  public getLatestSnapshot = async () => {
    const snapshots = await this.getAllSnapshots()
    return snapshots?.[0]
  }

  public getAllSnapshots = async () => {
    const summaryPaths = await fg('**/summary.json', {
      cwd: this.storagePath,
      absolute: true,
    })

    const snapshots = await Promise.all(
      summaryPaths.map(async (summaryPath) => {
        return await this.getSnapshotSummary(summaryPath)
      })
    )
    return sortSnapshots(
      snapshots.filter((s) => typeof s?.summary?.snapshotId === 'undefined')
    )
  }

  private getSnapshotSummary = async (
    summaryPath: string
  ): Promise<CloudSnapshot> => {
    const summary = await readSnapshotSummary(summaryPath)
    return {
      summary,
      totalSize: summary?.totalSize,
      origin: summary.origin!,
      // TODO: This cannot always be SUCCESS!
      status: 'SUCCESS',
      cachePath: path.dirname(summaryPath),
    }
  }

  public filterSnapshots = async ({
    startsWith,
    tags,
  }: FilterSnapshotRules) => {
    let snapshots = await this.getAllSnapshots()

    if (typeof startsWith !== 'undefined') {
      snapshots = snapshots?.filter((s) =>
        s?.summary?.name?.startsWith(startsWith!)
      )
    }

    if (typeof tags != 'undefined' && tags?.length > 0) {
      snapshots = snapshots?.filter((s) =>
        tags.every((tag) => s.summary.tags?.includes(tag))
      )
    }

    return snapshots
  }
}
