import findup from 'findup-sync'
import fs from 'fs'
import os from 'os'
import path from 'path'

export const SNAPLET_CONFIG_FILENAME = 'transform.ts'

function getSnapletOsHomeDir() {
  return process.env.SNAPLET_OS_HOMEDIR ?? os.homedir()
}

export function getSystemPath(homedir = getSnapletOsHomeDir()) {
  return path.join(homedir, '.config', 'snaplet')
}

export function getSystemConfigPath(baseName = 'system') {
  return path.join(getSystemPath(), `${baseName}.json`)
}

export function getDefaultProjectConfigPath() {
  return path.join(
    process.env.SNAPLET_CWD ?? process.cwd(),
    '.snaplet/config.json'
  )
}

/**
 * Searches "upwards" for a `.snaplet` directory.
 *
 * Snaplet expects to be run in the same directory as your code,
 * because we pin your code against a data source via a `.snaplet/config.json` file.
 * @todo move this to `project/paths.ts`
 * @todo make this use `.git`
 */
export function findProjectPath(
  cwd = process.env.SNAPLET_CWD ?? process.cwd()
) {
  // It's possible that the specified SNAPLET_CWD is invalid.
  if (process.env.SNAPLET_CWD && !fs.existsSync(cwd)) {
    throw new Error(
      `The specified 'SNAPLET_CWD' directory '${cwd}' does not exist.`
    )
  }
  return findup('.snaplet', { cwd })
}

export function getProjectConfigPath(projectBase = findProjectPath()) {
  if (process.env.SNAPLET_CONFIG) {
    return process.env.SNAPLET_CONFIG
  } else if (projectBase) {
    return path.join(projectBase, 'config.json')
  } else {
    return null
  }
}

export { getPaths as getPathsV2, ensureProjectPaths } from './v2/paths.js'

/**
 * Snaplet has two configuration paths:
 *
 * 1. System: where the auth-token is stored.
 * 2. Project: where the database id, target-db connection credentials,
 *  and transform are stored.
 */
export function getPaths() {
  const systemBase = getSystemPath()
  const projectBase = findProjectPath()
  return {
    system: {
      base: systemBase,
      config: getSystemConfigPath(),
      /* @deprecated Use project.snapshots instead */
      snapshots: path.join(systemBase, 'snapshots'),
      versions: path.join(systemBase, 'versions.json'),
    },
    project: {
      base: projectBase,
      config:
        getProjectConfigPath(projectBase) ?? getDefaultProjectConfigPath(),
      transform: projectBase
        ? path.join(projectBase, SNAPLET_CONFIG_FILENAME)
        : null,
      transformTypeDef: projectBase
        ? path.join(projectBase, 'structure.d.ts')
        : null,
      privateKey: projectBase ? path.join(projectBase, 'id_rsa') : null,
      schemas: projectBase
        ? path.join(projectBase, 'schemasConfig.json')
        : null,
      snapshots: projectBase ? path.join(projectBase, 'snapshots') : null,
      subsetting: projectBase
        ? path.join(projectBase, 'subsetting.json')
        : null,
    },
  }
}
