import fs from 'fs-extra'
import os from 'os'
import path from 'path'

import { getPathsV2 } from '../paths.js'
import { SNAPLET_CONFIG_FILENAME } from '../v2/paths.js'

export interface SnapshotFilePaths {
  base: string
  tables: string
  schemas: string
  summary: string
  structure: string
  restoreLog: string
  config: string
}

export const getSnapshotFilePaths = (base: string): SnapshotFilePaths => {
  return {
    base,
    tables: path.join(base, 'tables'),
    schemas: path.join(base, 'schemas.sql'),
    summary: path.join(base, 'summary.json'),
    structure: path.join(base, 'structure.json'),
    restoreLog: path.join(base, 'restore.log'),
    config: path.join(base, SNAPLET_CONFIG_FILENAME),
  }
}

export const generateSnapshotBasePath = (
  {
    date,
    name,
  }: {
    date: Date
    name: string
  },
  pathsFn = getPathsV2
) => {
  const ssPath = pathsFn()?.project?.snapshots

  let basePath
  if (ssPath) {
    basePath = ssPath
  } else {
    basePath = fs.mkdtempSync(path.join(os.tmpdir(), 'snaplet-'))
    // context(peterp, 15 Aug 2022): Our code requires an empty directory, so I delete it.
    fs.rmSync(basePath, { recursive: true })
  }

  const snapshotFolder = [new Date(date).getTime().toString(), name].join('-')

  return path.join(basePath, snapshotFolder)
}
