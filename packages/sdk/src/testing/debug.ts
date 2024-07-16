import { xdebugRaw } from '~/x/xdebug.js'

const testDebug = xdebugRaw.extend('testing')
// Useful to log into afterEach/after/afterAll cleanup
const afterDebug = testDebug.extend('afterDebug')

export { afterDebug }
