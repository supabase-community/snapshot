import { SnapletError } from '~/errors.js'
import { Exec, addDevDependencies } from './addDevDependencies.js'
import tmp from 'tmp-promise'
import execa from 'execa'

describe('addDevDependencies', () => {
  test('no workspace root', async () => {
    await expect(
      addDevDependencies(['a', 'b'], {
        currentWorkspaceRoot: null,
        packageManager: 'npm',
        dependencies: {},
      })
    ).rejects.toBeInstanceOf(SnapletError)
  })

  test('no package manager', async () => {
    const cwd = (await tmp.dir()).path

    await expect(
      addDevDependencies(['a', 'b'], {
        currentWorkspaceRoot: cwd,
        packageManager: null,
        dependencies: {},
      })
    ).rejects.toBeInstanceOf(SnapletError)
  })

  test('exec package manager', async () => {
    const cwd = (await tmp.dir()).path
    const exec = ((cmd: string) => execa('echo', [cmd])) as typeof execa

    for (const packageManager of ['npm', 'yarn', 'pnpm', 'bun'] as const) {
      expect(
        await addDevDependencies(
          ['a', 'b'],
          {
            currentWorkspaceRoot: cwd,
            packageManager,
            dependencies: {},
          },
          { exec }
        )
      ).toEqual(expect.objectContaining({ stdout: packageManager }))
    }
  })

  test('exec package manager error', async () => {
    const error = new Error('o_O')

    const exec = (async () => {
      throw error
    }) as unknown as Exec

    await expect(
      addDevDependencies(
        ['a', 'b'],
        {
          currentWorkspaceRoot: null,
          packageManager: 'npm',
          dependencies: {},
        },
        {
          exec,
        }
      )
    ).rejects.toEqual(new SnapletError('PACKAGE_MANAGER_RUN_ERROR', { error }))
  })
})
