import c from 'ansi-colors'
import type { Argv } from 'yargs'

import { IS_PRODUCTION } from './constants.js'
import { exitWithError } from './exit.js'
import { fmt } from './format.js'
import { discordLink } from './links.js'
import { getSentry } from './sentry.js'

export async function handleFail(msg: string, e: Error, _: Argv) {
  if (msg) {
    console.log(c.red(msg))
  } else {
    if (IS_PRODUCTION) {
      const Sentry = await getSentry()
      Sentry.captureException(e)
    }

    if (!IS_PRODUCTION || process.env.DEBUG) {
      console.log('*'.repeat(80))
      console.log(e)
      console.log('*'.repeat(80))
    }

    console.log(
      fmt(`
Unhandled error: ${e?.message}

We have been notified, but if you need help now please contact us on ${discordLink}
`)
    )
  }
  return await exitWithError('UNHANDLED_ERROR')
}
