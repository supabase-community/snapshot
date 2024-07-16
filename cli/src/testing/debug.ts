import { xdebugRaw } from '@snaplet/sdk/cli'

const testDebug = xdebugRaw.extend('testing')
// Useful to log into afterEach/after/afterAll cleanup
const afterDebug = testDebug.extend('afterDebug')

export { testDebug, afterDebug }
