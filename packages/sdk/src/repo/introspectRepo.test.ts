import fs from 'fs-extra'
import tmp from 'tmp-promise'

import { introspectRepo } from './introspectRepo.js'
import path from 'path'
import { LOCKFILES_BY_PACKAGE_MANAGER, PM } from './packageManagers.js'

describe('repo', () => {
  describe('introspectRepo', () => {
    test('no package.json', async () => {
      const tmpDir = await tmp.dir()

      expect((await introspectRepo(tmpDir.path)).currentWorkspaceRoot).toBe(
        null
      )
    })

    test('workspace root detection in single project repo - root', async () => {
      const tmpDir = await tmp.dir()
      await fs.writeJSON(path.join(tmpDir.path, 'package.json'), {})

      expect((await introspectRepo(tmpDir.path)).currentWorkspaceRoot).toBe(
        tmpDir.path
      )
    })

    test('workspace root detection in single project repo - subdir', async () => {
      const tmpDir = await tmp.dir()
      const subDir = path.join(tmpDir.path, 'a', 'b', 'c')
      await fs.mkdirp(subDir)
      await fs.writeJSON(path.join(tmpDir.path, 'package.json'), {})

      expect((await introspectRepo(subDir)).currentWorkspaceRoot).toBe(
        tmpDir.path
      )
    })

    test('workspace root detection in monorepo - workspace root', async () => {
      const tmpDir = await tmp.dir()
      const workspaceDir = path.join(tmpDir.path, 'workspace')
      await fs.mkdirp(workspaceDir)
      await fs.writeJSON(path.join(tmpDir.path, 'package.json'), {})
      await fs.writeJSON(path.join(workspaceDir, 'package.json'), {})

      expect((await introspectRepo(workspaceDir)).currentWorkspaceRoot).toBe(
        workspaceDir
      )
    })

    test('workspace root detection in monorepo - workspace subdir', async () => {
      const tmpDir = await tmp.dir()
      const workspaceDir = path.join(tmpDir.path, 'workspace')
      const subDir = path.join(workspaceDir, 'a', 'b', 'c')
      await fs.mkdirp(subDir)
      await fs.writeJSON(path.join(tmpDir.path, 'package.json'), {})
      await fs.writeJSON(path.join(workspaceDir, 'package.json'), {})

      expect((await introspectRepo(subDir)).currentWorkspaceRoot).toBe(
        workspaceDir
      )
    })

    test('package manager detection by lockfiles', async () => {
      for (const packageManagerName of Object.keys(
        LOCKFILES_BY_PACKAGE_MANAGER
      ) as PM[]) {
        const tmpDir = await tmp.dir()
        await fs.writeJSON(path.join(tmpDir.path, 'package.json'), {})
        const lockfileName = LOCKFILES_BY_PACKAGE_MANAGER[packageManagerName]

        await fs.writeFile(path.join(tmpDir.path, lockfileName), '')

        expect((await introspectRepo(tmpDir.path)).packageManager).toEqual(
          packageManagerName
        )
      }
    })

    test('package manager detection - no lockfile', async () => {
      const tmpDir = await tmp.dir()
      await fs.writeJSON(path.join(tmpDir.path, 'package.json'), {})
      expect((await introspectRepo(tmpDir.path)).packageManager).toBe(null)
    })

    test('package manager detection in workspace subdir', async () => {
      const tmpDir = await tmp.dir()
      const subDir = path.join(tmpDir.path, 'a', 'b', 'c')
      await fs.mkdirp(subDir)
      await fs.writeJSON(path.join(tmpDir.path, 'package.json'), {})
      await fs.writeFile(path.join(tmpDir.path, 'yarn.lock'), '')

      expect((await introspectRepo(subDir)).packageManager).toBe('yarn')
    })

    test('dependencies', async () => {
      const tmpDir = await tmp.dir()
      await fs.writeJSON(path.join(tmpDir.path, 'package.json'), {
        dependencies: {
          a: '^1.0.0',
          b: '^2.0.0',
        },
        devDependencies: {
          c: '^3.0.0',
        },
      })

      await fs.writeFile(path.join(tmpDir.path, 'yarn.lock'), '')

      expect((await introspectRepo(tmpDir.path)).dependencies).toEqual({
        a: {
          range: '^1.0.0',
          kind: 'production',
        },
        b: {
          range: '^2.0.0',
          kind: 'production',
        },
        c: {
          range: '^3.0.0',
          kind: 'dev',
        },
      })
    })
  })
})
