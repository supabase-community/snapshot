import { getPathsV2 } from '@snaplet/sdk/cli'
import { mkdirpSync, removeSync } from 'fs-extra'
import path from 'path'
import tmp from 'tmp-promise'
import { afterDebug } from './debug.js'

type NullableProjectPaths = ReturnType<typeof getPathsV2>['project']

interface State {
  tmpPaths: string[]
  projectPaths: NonNullable<NullableProjectPaths>[]
}

const defineCreateTestProjectDir = (state: State) => {
  const createTestProjectDir = async () => {
    const tmpPath = (await tmp.dir()).path
    const projectBase = path.join(tmpPath, 'project')
    mkdirpSync(path.join(projectBase, '.snaplet'))

    process.env.SNAPLET_CWD = projectBase
    process.env.SNAPLET_OS_HOMEDIR = path.join(tmpPath, 'system')
    const paths = getPathsV2()

    if (!paths.project) {
      throw new Error('Could not determine project paths, base path is empty.')
    }

    state.tmpPaths.push(tmpPath)
    state.projectPaths.push(paths.project)
    return { ...paths.project, system: paths.system }
  }

  createTestProjectDir.afterEach = async () => {
    state.projectPaths = []
    const tmpPaths = state.tmpPaths
    state.tmpPaths = []
    afterDebug(
      `createTestProjectDir afterEach cleanup: ${state.tmpPaths.join(',')}`
    )
    for (const p of tmpPaths) {
      removeSync(p)
    }
  }

  return createTestProjectDir
}

export const createTestProjectDir = defineCreateTestProjectDir({
  tmpPaths: [],
  projectPaths: [],
})

afterAll(createTestProjectDir.afterEach)
