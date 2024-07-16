import type { CloudSnapshot } from '@snaplet/sdk/cli'
import { getPathsV2 } from '@snaplet/sdk/cli'
import _ from 'lodash'

import { config } from '~/lib/config.js'

import { AbsPathSnapshotHost } from './absPathSnapshotHost.js'
import { CloudSnapshotHost } from './cloudSnapshotHost.js'
import { LocalSnapshotHost } from './localSnapshotHost.js'

export interface FilterSnapshotRules {
  startsWith?: string
  tags?: string[]
}

export interface Host {
  type: 'cloud' | 'local' | 'abspath'

  getLatestSnapshot(): Promise<CloudSnapshot | undefined>
  getAllSnapshots(): Promise<CloudSnapshot[]>
  /**
   * @deprecated use filter snapshots
   */
  findSnapshots?(startsWith: string): Promise<CloudSnapshot[]>
  filterSnapshots(rules: FilterSnapshotRules): Promise<CloudSnapshot[]>
}

export class Hosts implements Omit<Host, 'type'> {
  private hosts: Host[]

  constructor({ hosts }: { hosts: Host[] }) {
    this.hosts = hosts
  }

  public getLatestSnapshot = async (): Promise<CloudSnapshot | undefined> => {
    let snaphots: CloudSnapshot[] = []
    for (const host of this.hosts) {
      const snapshot = await host.getLatestSnapshot()
      if (typeof snapshot !== 'undefined') {
        snaphots = [...snaphots, snapshot]
      }
    }
    return sortSnapshots(snaphots)?.[0]
  }

  public getAllSnapshots = async () => {
    let allSnapshots: CloudSnapshot[] = []
    for (const host of this.hosts) {
      const hostSnapshots = await host.getAllSnapshots()
      if (typeof hostSnapshots !== 'undefined') {
        allSnapshots = [...allSnapshots, ...hostSnapshots]
      }
    }
    return sortSnapshots(mergeUniqueSnapshots(allSnapshots))
  }

  public filterSnapshots = async (rules: {
    first?: boolean
    startsWith?: string
    tags?: string[]
  }) => {
    let found: CloudSnapshot[] = []
    for (const host of this.hosts) {
      const hostSnapshots = await host.filterSnapshots(rules)
      if (typeof hostSnapshots !== 'undefined') {
        found = [...found, ...hostSnapshots]
      }
    }
    return sortSnapshots(mergeUniqueSnapshots(found))
  }
}

const mergeUniqueSnapshots = (snapshots: CloudSnapshot[]) => {
  const withIds = _.chain(snapshots)
    .filter((s) => typeof s?.summary?.snapshotId !== 'undefined')
    .uniqWith((a, b) => {
      return a.summary.snapshotId === b.summary.snapshotId
    })
    .value()

  const withoutIds = snapshots.filter(
    (s) => typeof s?.summary?.snapshotId === 'undefined'
  )

  return [...withIds, ...withoutIds]
}

export const sortSnapshots = (snapshots: CloudSnapshot[]) => {
  return snapshots.sort(
    (s1, s2) =>
      new Date(s2?.summary?.date).getTime() -
      new Date(s1?.summary?.date).getTime()
  )
}

const getLocalHost = async () => {
  const paths = await getPathsV2()
  if (paths?.project?.snapshots) {
    return new LocalSnapshotHost({ storagePath: paths.project.snapshots })
  }
  return null
}

const getCloudHost = async () => {
  const projectConfig = await config.getProject()
  if (projectConfig.projectId) {
    return new CloudSnapshotHost({ projectId: projectConfig.projectId })
  }
  return null
}

export type HostType = Host['type']
type GetHostsOptions = {
  only?: HostType[]
}
export const getHosts = async (options?: GetHostsOptions) => {
  const hosts = await Promise.all([
    await getLocalHost(),
    await getCloudHost(),
    new AbsPathSnapshotHost(),
  ])
  return new Hosts({
    hosts: hosts.filter((host) => {
      if (host && options?.only) {
        return options.only.includes(host.type)
      }
      return host !== null
    }) as Host[],
  })
}
