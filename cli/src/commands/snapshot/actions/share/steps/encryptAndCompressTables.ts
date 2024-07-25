import fs from 'fs-extra'
import fg from 'fast-glob'
import pMap from 'p-map'

import {
  EncryptionPayload,
  encryptAndCompressSnapshotFile,
  getSnapshotFilePaths,
} from '@snaplet/sdk/cli'

export const encryptAndCompressTables = async ({
  paths,
  encryptionPayload,
}: {
  paths: ReturnType<typeof getSnapshotFilePaths>
  encryptionPayload?: EncryptionPayload
}) => {
  const csvFiles = await fg(`*.csv`, { cwd: paths.tables, absolute: true })

  await pMap(
    csvFiles,
    async (p) => {
      await encryptAndCompressSnapshotFile(p, encryptionPayload)
      await fs.unlink(p)
    },
    // There is no need to try to compress/encrypt all files at once it'll just blow up the CPU usage
    // and create tons of child processes for nothing. Doing it in batches of 2 ensure that one single
    // long table won't block the other smaller ones.
    { concurrency: 2 }
  )
}
