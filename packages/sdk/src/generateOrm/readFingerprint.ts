import { Fingerprint, getPathsV2 } from '~/exports/cli.js'

export function readFingerprint(): Fingerprint {
  const fingerprintPath = getPathsV2().project?.fingerprint

  if (fingerprintPath) {
    try {
      return require(fingerprintPath)
    } catch {
      // noop
    }
  }

  return {}
}
