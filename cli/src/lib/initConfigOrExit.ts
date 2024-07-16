import { exitWithError } from './exit.js'
import { config } from './config.js'
// eslint-disable-next-line @typescript-eslint/no-unused-vars
type Parameters<T> = T extends (...args: infer T) => any ? T : never

export async function initConfigOrExit(
  ...args: Parameters<typeof config.init>
) {
  const init = await config.init(...args)
  if (init.ok === true) {
    return { parsed: init.value, config }
  }
  // Those are handled expected errors if the user config is invalid or have syntax errors in it
  // in that case we show where the error is and exit with a non-zero code
  if (
    init.error._tag === 'SnapletExecuteConfigError' ||
    init.error._tag === 'SnapletCompileConfigError'
  ) {
    console.log(init.error.message)
    console.log(init.error.stack)
    return await exitWithError(init.error.code)
  }
  if (init.error._tag === 'SnapletParseConfigError') {
    console.log(init.error.message)
    return await exitWithError(init.error.code)
  }
  // Otherwise that's an unexpected error and we bubble it up
  throw init.error
}
