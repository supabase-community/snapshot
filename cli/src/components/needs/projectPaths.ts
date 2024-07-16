import { findProjectPath, getPathsV2 } from '@snaplet/sdk/cli'
import { exitWithError } from '~/lib/exit.js'

import { logError } from './logError.js'
import { ensureDir } from 'fs-extra'
import path from 'path'

export const projectPathsV2 = async (options?: { create?: boolean }) => {
  if (options?.create) {
    const projectPath = findProjectPath()
    if (!projectPath) {
      const snapletPath = process.env.SNAPLET_CWD
        ? path.join(process.env.SNAPLET_CWD, '.snaplet')
        : '.snaplet'
      await ensureDir(snapletPath)
    }
  }
  const paths = getPathsV2()
  if (!paths.project) {
    logError(
      [
        'A **.snaplet** project directory is required:',
        'Run **snaplet project setup** in your git repo or use the **SNAPLET_CWD** environment variable.',
      ],
      'SNAPLET_CWD=~/path/to/gh/code snaplet snapshot restore'
    )
    return await exitWithError('CONFIG_NOT_FOUND')
  } else {
    return paths.project
  }
}
