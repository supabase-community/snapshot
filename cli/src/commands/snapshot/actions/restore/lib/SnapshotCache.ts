import {
  CloudSnapshot,
  generateSnapshotBasePath,
  getSnapshotFilePaths,
} from '@snaplet/sdk/cli'
import terminalLink from 'terminal-link'

export default class SnapshotCache {
  cachePath?: string
  summary: CloudSnapshot

  constructor(summary: CloudSnapshot) {
    this.summary = summary
  }

  get paths() {
    if (!this.cachePath) {
      if (this.summary.cachePath) {
        this.cachePath = this.summary.cachePath
      } else {
        const { name, date } = this.summary.summary
        this.cachePath = generateSnapshotBasePath({ name, date })
      }
    }

    return getSnapshotFilePaths(this.cachePath)
  }

  get restoreLogTerminalLink() {
    return terminalLink('restore.log', 'file://' + this.paths.restoreLog)
  }
}
