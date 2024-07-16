import { endAllPools } from '@snaplet/sdk/cli'
import { xdebug } from '@snaplet/sdk/cli'

import { IS_PRODUCTION } from './constants.js'
import { closeSentry } from './sentry.js'
import { teardownTelemetry } from './telemetry.js'
import { closeHttpServer } from './server.js'

const teardownDebug = xdebug.extend('teardown')
const MAX_TEARDOWN_TIME = 5000

// Should always be executed, might the command exit with success, or with an error
async function handleTeardown() {
  const teardownActions = [endAllPools()]

  // In the case of a successful exit, we still want to possibly send some
  // errors we might have logged to sentry during the program execution
  if (IS_PRODUCTION) {
    teardownActions.push(closeSentry())
    teardownActions.push(teardownTelemetry())
    teardownActions.push(closeHttpServer())
  }
  // Execute all teardown actions concurrently
  await Promise.allSettled(teardownActions)
}

// Should only be called for non error, 0 code exit
// otherwise, call the exitWithError method instead
export async function teardownAndExit(exitCode: number): Promise<never> {
  // A guard to make sure our teardown will never taker longer than
  // specified amount of time before exiting the process
  const timeout = setTimeout(() => {
    teardownDebug('teardown did not finished in time, cleanup might be altered')
    process.exit(exitCode)
  }, MAX_TEARDOWN_TIME)
  await handleTeardown()
  clearTimeout(timeout)
  process.exit(exitCode)
}
