import { pathExists } from 'fs-extra'
import path from 'path'

export type PM = 'npm' | 'yarn' | 'bun' | 'pnpm'

export const LOCKFILES_BY_PACKAGE_MANAGER: Record<PM, string> = {
  npm: 'package-lock.json',
  yarn: 'yarn.lock',
  bun: 'bun.lockb',
  pnpm: 'pnpm-lock.yaml',
}

export const detectPackageManager = async (cwd: string): Promise<PM | null> => {
  for (const packageManagerName of Object.keys(
    LOCKFILES_BY_PACKAGE_MANAGER
  ) as PM[]) {
    const lockfileName = LOCKFILES_BY_PACKAGE_MANAGER[packageManagerName]

    if (await pathExists(path.resolve(cwd, lockfileName))) {
      return packageManagerName
    }
  }

  return null
}

export const packageManagers: Record<
  PM,
  {
    addDev(context: {
      exec: (cmd: string, args: string[]) => Promise<unknown>
      specs: string[]
    }): Promise<unknown>
  }
> = {
  npm: {
    async addDev({ exec, specs }) {
      return await exec('npm', ['install', '--save-dev', ...specs])
    },
  },
  yarn: {
    async addDev({ exec, specs }) {
      return await exec('yarn', ['add', '--dev', ...specs])
    },
  },
  pnpm: {
    async addDev({ exec, specs }) {
      return await exec('pnpm', [
        'add',
        '--save-dev',
        '--ignore-workspace-root-check',
        ...specs,
      ])
    },
  },
  bun: {
    async addDev({ exec, specs }) {
      return await exec('bun', ['add', '--dev', ...specs])
    },
  },
}
