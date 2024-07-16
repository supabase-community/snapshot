import execa from 'execa'
import { RepoIntrospection } from './introspectRepo.js'
import { SnapletError } from '~/errors.js'
import { packageManagers } from './packageManagers.js'

export type Exec = typeof execa

export const addDevDependencies = async (
  specs: string[],
  introspection: RepoIntrospection,
  options: Partial<{ exec: Exec }> = {}
) => {
  const { currentWorkspaceRoot, packageManager } = introspection

  if (!currentWorkspaceRoot) {
    throw new SnapletError('WORKSPACE_ROOT_NOT_FOUND')
  }

  if (!packageManager) {
    throw new SnapletError('PACKAGE_MANAGER_NOT_FOUND')
  }

  const { exec: baseExec = execa } = options

  const context = {
    ...options,
    specs,
    exec(cmd: string, args: string[]) {
      return baseExec(cmd, args, {
        cwd: currentWorkspaceRoot,
      })
    },
  }

  try {
    return await packageManagers[packageManager].addDev(context)
  } catch (error) {
    throw new SnapletError('PACKAGE_MANAGER_RUN_ERROR', {
      error,
    })
  }
}
