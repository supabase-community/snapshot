import { mkdirpSync, removeSync } from 'fs-extra'
import { dirSync } from 'tmp-promise'

import { afterDebug } from './debug.js'

interface State {
  tmpPaths: Array<{
    keep: boolean
    name: string
  }>
}

const defineCreateTestTmpDirectory = (state: State) => {
  const createTestTmpDirectory = (keep = false): State['tmpPaths'][number] => {
    const x = dirSync()
    removeSync(x.name)
    mkdirpSync(x.name)
    state.tmpPaths.push({ keep, name: x.name })
    return x
  }

  createTestTmpDirectory.afterAll = () => {
    const tmpPaths = state.tmpPaths
    state.tmpPaths = []
    afterDebug(`createTestTmpDirectory afterAll cleanup: ${tmpPaths.length}`)

    for (const capturePath of tmpPaths) {
      if (capturePath.keep === false) {
        removeSync(capturePath.name)
      }
    }
  }

  return createTestTmpDirectory
}

export const createTestTmpDirectory = defineCreateTestTmpDirectory({
  tmpPaths: [],
})

afterAll(createTestTmpDirectory.afterAll)
