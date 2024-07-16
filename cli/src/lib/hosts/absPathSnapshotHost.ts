import { readSnapshotSummary, CloudSnapshot } from '@snaplet/sdk/cli'
import fs from 'fs-extra'
import path from 'path'

import { FilterSnapshotRules, Host } from './hosts.js'

export class AbsPathSnapshotHost implements Host {
  public type = 'abspath' as const

  public getLatestSnapshot = async () => {
    return undefined
  }

  public getAllSnapshots = async () => {
    return []
  }

  public filterSnapshots = async (rules: FilterSnapshotRules) => {
    // if the string includes a path separator, it's probably a path
    if (rules.startsWith?.includes(path.sep)) {
      const summaryPath = path.join(rules.startsWith, 'summary.json')
      if (fs.existsSync(summaryPath)) {
        const s = await this.getSnapshotSummary(summaryPath)
        return [s]
      }
    }
    return []
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
}
