import path from 'path'
import { getSystemPath } from './paths.js'
import { safeReadJson, saveJson } from './fs.js'

const SYSTEM_MANIFEST_FILENAME = 'system-manifest.json'

interface SystemManifest {
  version?: string
  lastEventTimestamps?: Record<string, number>
}

const getSystemManifestPath = () => {
  const systemDir = getSystemPath()
  return path.resolve(systemDir, SYSTEM_MANIFEST_FILENAME)
}

export const saveSystemManifest = async (next: SystemManifest) => {
  await saveJson(getSystemManifestPath(), next)
}

export const updateSystemManifest = async (
  updates?: Partial<SystemManifest>
) => {
  const current = (await readSystemManifest()) ?? {}

  await saveSystemManifest({
    ...current,
    ...updates,
  })
}

export const readSystemManifest = async (): Promise<SystemManifest | null> => {
  try {
    return await safeReadJson<SystemManifest>(getSystemManifestPath())
  } catch {
    // context(justinvdm, 10 Jan 2024): We seem to get quite a few broken json files for the system manifest
    // Ideally this shouldn't break the cli for the user
    // https://snaplet.sentry.io/issues/4844572936/?project=5588827&query=is%3Aunresolved+system-manifest&referrer=issue-stream&statsPeriod=30d&stream_index=0
    // https://snaplet.sentry.io/issues/4844239775/?project=5588827&query=is%3Aunresolved+system-manifest&referrer=issue-stream&statsPeriod=30d&stream_index=1
    // https://snaplet.sentry.io/issues/4676927337/?project=5588827&query=is%3Aunresolved+system-manifest&referrer=issue-stream&statsPeriod=30d&stream_index=2
    return null
  }
}
