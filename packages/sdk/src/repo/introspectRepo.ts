import path from 'path'
import { findUp } from '../fs.js'

import { type PM, detectPackageManager } from './packageManagers.js'
import { readJSON } from 'fs-extra'

export interface Dependency {
  range: string
  kind: 'dev' | 'production'
}

export interface RepoIntrospection {
  currentWorkspaceRoot: string | null
  packageManager: PM | null
  dependencies: Record<string, Dependency>
}

const getDependencies = (packageJson: {
  dependencies?: Record<string, string>
  devDependencies?: Record<string, string>
}): Record<string, Dependency> => {
  const results: Record<string, Dependency> = {}
  const { dependencies = {}, devDependencies = {} } = packageJson

  for (const name of Object.keys(dependencies)) {
    results[name] = {
      kind: 'production',
      range: dependencies[name],
    }
  }

  for (const name of Object.keys(devDependencies)) {
    results[name] = {
      kind: 'dev',
      range: devDependencies[name],
    }
  }

  return results
}

export const introspectRepo = async (
  cwd: string
): Promise<RepoIntrospection> => {
  const packageJsonPath = await findUp('package.json', { cwd })
  const result: RepoIntrospection = {
    currentWorkspaceRoot: null,
    packageManager: null,
    dependencies: {},
  }

  if (packageJsonPath) {
    result.currentWorkspaceRoot = path.dirname(packageJsonPath)
    result.packageManager = await detectPackageManager(
      result.currentWorkspaceRoot
    )
    const packageJson = await readJSON(packageJsonPath)
    result.dependencies = getDependencies(packageJson)
  } else {
    result.packageManager = await detectPackageManager(cwd)
  }

  return result
}
