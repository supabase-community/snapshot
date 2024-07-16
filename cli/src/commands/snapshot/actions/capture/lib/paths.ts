import { getSnapshotFilePaths } from '@snaplet/sdk/cli'
import fs from 'fs-extra'

export const getSnapshotPaths = async (destinationPath: string) => {
  if (
    fs.pathExistsSync(destinationPath) &&
    !fs.existsSync(destinationPath + '/subset.sqlite')
  ) {
    throw new Error(
      'The specified path already exists, either delete it or specify a new location.'
    )
  }
  const paths = getSnapshotFilePaths(destinationPath)
  await fs.mkdirs(paths.tables)
  return paths
}
