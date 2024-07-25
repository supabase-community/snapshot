import { trpc } from '~/lib/trpc.js'

import type { FilterSnapshotRules, Host } from './hosts.js'
import { CloudSnapshot, determineExecTaskStatus } from '@snaplet/sdk/cli'

import { type SnapshotListStorage } from '~/commands/snapshot/actions/list/lib/storage.js'

type DbRetrievedSnapshot = NonNullable<
  Awaited<ReturnType<typeof trpc.snapshot.latest.query>>
>

function getSnapshotStatus(
  snapshot: DbRetrievedSnapshot
): CloudSnapshot['status'] {
  const { summary } = snapshot
  // If the snapshot was taken locally, we can't know the status via execTask
  // so we need to determine it via the summary
  if (summary.origin === 'LOCAL') {
    return summary.totalSize > 0 ? 'SUCCESS' : 'FAILURE'
  }
  // If it has been taken to the cloud, we can determine the status via the
  // execTask status
  return snapshot.execTask
    ? determineExecTaskStatus({
        exitCode: snapshot.execTask.exitCode,
        updatedAt: new Date(snapshot.execTask.updatedAt),
      })
    : 'FAILURE'
}

function snapshotToCloudSnapshot(result: DbRetrievedSnapshot): CloudSnapshot {
  const cs: CloudSnapshot = {
    id: result.id,
    totalSize: result.summary.totalSize,
    projectId: result.projectId,
    uniqueName: result.uniqueName,
    failureCount: result.failureCount,
    errors: result.errors,
    // Whatever was the original origin of the snapshot, for the user since it come
    // from our api it's always a cloud snapshot. But we still use the original
    // origin information to determine the status of the snapshot
    origin: 'CLOUD',
    createdAt: new Date(result.createdAt),
    status: getSnapshotStatus(result),
    summary: result.summary
      ? { ...result.summary, date: new Date(result.summary.date) }
      : {
          date: new Date(result.createdAt),
          name: result.uniqueName,
        },
    cachePath: undefined,
    encryptedSessionKey: result.summary.encryptedSessionKey,
  }
  return cs
}

export class CloudSnapshotHost implements Host {
  storage: SnapshotListStorage
  constructor(storage: SnapshotListStorage) {
    this.storage = storage
  }

  getLatestSnapshot = async () => {
    const result = this.storage.getLatestSnapshot()
    return snapshotToCloudSnapshot(result)
  }

  getAllSnapshots = async () => {
    const snapshots = this.storage.getSnapshotsMany()
    return snapshots
  }

  filterSnapshots = async (rules: FilterSnapshotRules) => {
    const snaphots = this.storage.getSnapshotsMany(rules)
    return snapshots.map(snapshotToCloudSnapshot)
  }
}
