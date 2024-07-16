import { removeSync } from 'fs-extra'
import { dirSync } from 'tmp-promise'

import { afterDebug } from './debug.js'

interface State {
  capturePaths: Array<{
    keep: boolean
    name: string
  }>
}

const defineCreateTestCapturePath = (state: State) => {
  const createTestCapturePath = (
    keep = false
  ): State['capturePaths'][number] => {
    const x = dirSync()
    removeSync(x.name)
    state.capturePaths.push({ keep, name: x.name })
    return x
  }

  createTestCapturePath.afterEach = () => {
    const capturePaths = state.capturePaths
    state.capturePaths = []
    afterDebug(
      `createTestCapturePath afterEach cleanup: ${capturePaths.length}`
    )

    for (const capturePath of capturePaths) {
      if (capturePath.keep === false) {
        removeSync(capturePath.name)
      }
    }
  }

  return createTestCapturePath
}

export const createTestCapturePath = defineCreateTestCapturePath({
  capturePaths: [],
})

afterEach(createTestCapturePath.afterEach)
