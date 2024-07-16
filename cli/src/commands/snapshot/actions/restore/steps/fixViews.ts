import { getSentry } from '~/lib/sentry.js'

import SnapshotImporter from '../lib/SnapshotImporter/SnapshotImporter.js'

// This step is needed because dropping constraints with cascade can result in views being dropped as well.
export const fixViews = async (importer: SnapshotImporter) => {
  const errors: string[] = []

  try {
    await importer.fixViews()
  } catch (e) {
    if (e instanceof Error) {
      errors.push(e.message)
    }
    const Sentry = await getSentry()
    Sentry.captureException(e)
  }

  return errors
}
