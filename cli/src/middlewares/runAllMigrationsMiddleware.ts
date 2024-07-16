import {
  findProjectPath,
  safeReadJson,
  saveJson,
  readSystemManifest,
  updateSystemManifest,
} from '@snaplet/sdk/cli'
import { xdebug } from '@snaplet/sdk/cli'
import { last, takeRightWhile } from 'lodash'
import path from 'path'
import semver from 'semver'
import type { MiddlewareFunction } from 'yargs'

import { IS_CI, CLI_VERSION } from '~/lib/constants.js'
import { display } from '~/lib/display.js'

const xdebugMigrations = xdebug.extend('migrations')

const PROJECT_MANIFEST_FILENAME = 'manifest.json'

type Migration = () => void | Promise<void>

type MigrationsRecord = Record<string, Migration>

interface ProjectManifest {
  version: string
}

export const systemMigrations: MigrationsRecord = {}

export const projectMigrations: MigrationsRecord = {}

export function computeApplicableMigrations(
  migrations: MigrationsRecord,
  previousVersion = '0.0.0'
): Migration[] {
  xdebugMigrations(
    `computeApplicableMigrations from: ${Object.keys(migrations)}`
  )
  const allVersions = Object.keys(migrations).sort(semver.compare)
  xdebugMigrations(`allVersions: ${allVersions}`)
  const applicableMigrations = takeRightWhile(allVersions, (version) =>
    semver.gt(version, previousVersion)
  ).map((version) => migrations[version])
  xdebugMigrations(`applicableMigrations: ${applicableMigrations}`)
  return applicableMigrations
}

async function runSystemMigrations() {
  xdebugMigrations('runSystemMigrations')
  const manifest = await readSystemManifest()

  const migrations = computeApplicableMigrations(
    systemMigrations,
    manifest?.version
  )

  if (migrations.length) {
    display('Running system-level migration steps for snaplet cli...')

    for (const migration of migrations) {
      await migration()
    }
  }

  // We always want to upgrade the global system-manifest.json to stay in sync with package.json
  const nextVersion = computeNextManifestVersion(systemMigrations)
  // if the versions are already the sames, there is nothing new to write on the disk
  if (nextVersion !== manifest?.version) {
    xdebugMigrations(`Next system manifest computed version: ${nextVersion}`)
    await updateSystemManifest({ version: nextVersion })
  }
}

// context(justinvdm, 13 Apr 2022): For snaplet devs, if we are on outdated branches
// we could end up downgrading the manifest version. So instead we take the max of the
// latest migration version and the package.json version.
const computeNextManifestVersion = (migrations: MigrationsRecord) =>
  last(Object.keys(migrations).concat(CLI_VERSION).sort(semver.compare))

async function runProjectMigrations() {
  let projectDir
  try {
    projectDir = findProjectPath()
  } catch {
    return
  }

  if (!projectDir) {
    return
  }
  xdebugMigrations(`runProjectMigrations for project in: ${projectDir}`)

  const manifestPath = path.resolve(projectDir, PROJECT_MANIFEST_FILENAME)
  const manifest = await safeReadJson<ProjectManifest>(manifestPath)

  const migrations = computeApplicableMigrations(
    projectMigrations,
    manifest?.version
  )

  if (migrations.length) {
    display('Running project-level migration steps for snaplet cli...')

    for (const migration of migrations) {
      await migration()
    }
    // We only re-write project manifest version if we actually ran some migrations over
    // to avoid flooding users version control manager with unnecessary upgrade changes
    display()
    const nextVersion = computeNextManifestVersion(projectMigrations)
    xdebugMigrations(`Next project manifest computed version: ${nextVersion}`)

    await saveJson(manifestPath, {
      ...manifest,
      version: nextVersion,
    })
  }
}

export const runAllMigrationsMiddleware: MiddlewareFunction = async () => {
  xdebugMigrations('Run all migrations')
  // context(peterp, 8th April 2022): We do not want version migrations to run in CI.
  if (IS_CI) {
    return
  }
  await runSystemMigrations()
  await runProjectMigrations()
}
