import findup from 'findup-sync'
import fs from 'fs'
import fsExtra from 'fs-extra'
import os from 'os'
import path from 'path'
import { SnapletError } from '~/errors.js'
import { getPathsV2 } from '~/paths.js'

export const SNAPLET_CONFIG_FILENAME = 'snaplet.config.ts'

function getSnapletOsHomeDir() {
  return process.env.SNAPLET_OS_HOMEDIR ?? os.homedir()
}

function getSystemPath(homedir = getSnapletOsHomeDir()) {
  return path.join(homedir, '.config', 'snaplet')
}

function getSystemConfigPath(baseName = 'system') {
  return path.join(getSystemPath(), `${baseName}.json`)
}

/**
 * Searches "upwards" for a `.snaplet` directory.
 *
 * Snaplet expects to be run in the same directory as your code,
 * because we pin your code against a data source via a `.snaplet/config.json` file.
 * @todo move this to `project/paths.ts`
 * @todo make this use `.git`
 */
function findProjectPath(cwd = process.env.SNAPLET_CWD ?? process.cwd()) {
  // It's possible that the specified SNAPLET_CWD is invalid.
  if (process.env.SNAPLET_CWD && !fs.existsSync(cwd)) {
    throw new Error(
      `The specified 'SNAPLET_CWD' directory '${cwd}' does not exist.`
    )
  }
  return findup('.snaplet', { cwd })
}

function getSnapshotConfigPath(projectBase: string) {
  // search preference: ENV VAR, snaplet.config.ts, then transform.ts or the default config path, which is `snaplet.config.ts`
  if (process.env.SNAPLET_CONFIG) {
    return process.env.SNAPLET_CONFIG
  }

  const tsPath = path.join(projectBase, SNAPLET_CONFIG_FILENAME)
  if (fs.existsSync(tsPath)) {
    return tsPath
  }

  return getDefaultSnapletConfigPath(projectBase)
}

const getDefaultSnapletConfigPath = (projectBase: string) => {
  // The default config path is `snaplet.config.ts` will be at the root of the project at the same level of the `.snaplet` directory.
  return path.join(projectBase, '..', SNAPLET_CONFIG_FILENAME)
}

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

  const system = {
    base: systemBase,
    config: getSystemConfigPath(),
    /* @deprecated Use project.snapshots instead */
    snapshots: path.join(systemBase, 'snapshots'),
    versions: path.join(systemBase, 'versions.json'),
  }

  // context(peterp, 05 July 2023):
  // it would be good if the majority of these don't return null.
  // the reason for this is because we use it to inform "what exists on the filesystem",
  // but also "where it should exist".
  // This is very likely not a good way to write this code.
  if (!projectBase) {
    return {
      system,
      project: null,
    }
  }

  return {
    system,
    project: {
      /** @deprecated use `snapletConfig` as it will return the default value. */
      default: {
        snapletConfig: getDefaultSnapletConfigPath(projectBase),
      },
      base: projectBase,
      fingerprint: path.join(projectBase, 'fingerprint.json'),
      config: path.join(projectBase, 'config.json'),
      snapletConfig: getSnapshotConfigPath(projectBase),
      transformTypeDef: path.join(projectBase, 'snaplet.d.ts'),
      privateKey: path.join(projectBase, 'id_rsa'),
      snapshots: path.join(projectBase, 'snapshots'),
    },
  }
}

export async function ensureProjectPaths() {
  let projectPaths = getPathsV2().project

  if (!projectPaths) {
    await fsExtra.mkdirp(
      path.join(process.env.SNAPLET_CWD ?? process.cwd(), '.snaplet')
    )
    projectPaths = getPathsV2().project
  }

  if (!projectPaths) {
    throw new SnapletError('PROJECT_BASE_DIR_NOT_CREATED')
  }

  return projectPaths
}
