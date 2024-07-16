import type { MiddlewareFunction } from 'yargs'

import { config } from '~/lib/config.js'
import { IS_PRODUCTION } from '~/lib/constants.js'
import { getSentry } from '~/lib/sentry.js'

export const setupSentryMiddleware: MiddlewareFunction = async (argv) => {
  if (IS_PRODUCTION) {
    const Sentry = await getSentry()

    try {
      Sentry.setContext('context', {
        argv,
        databaseId: (await config.getProject()).projectId,
      })
    } catch (e: any) {
      // no-op.
    }
  }
}
