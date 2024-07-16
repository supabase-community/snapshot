import { createTRPCProxyClient, TRPCLink } from '@trpc/client'
import { httpLink } from '@trpc/client/links/httpLink'
import { loggerLink } from '@trpc/client/links/loggerLink'
import type { CLIRouterType } from 'api'
import createFetchRetry from 'fetch-retry'
import { observable } from '@trpc/server/observable'

import { config } from '~/lib/config.js'

import { CLI_VERSION } from './constants.js'
import { exitWithError } from './exit.js'
import { fmt } from './format.js'

const errorLink: TRPCLink<CLIRouterType> = () => {
  return ({ next, op }) => {
    return observable((observer) => {
      const unsubscribe = next(op).subscribe({
        next: (value) => {
          observer.next(value)
        },
        error: async (err) => {
          if (err?.data?.httpStatus === 401) {
            console.log(
              fmt(`
  # ERROR

  Authentication failed: "${err.message}"
  Run **snaplet auth setup** or use the **SNAPLET_ACCESS_TOKEN** environment variable.

  Example: SNAPLET_ACCESS_TOKEN=hunter2 snaplet snapshot list
            `)
            )
            await exitWithError('NET_REQUEST_AUTH')
          } else {
            observer.error(err)
          }
        },
        complete: () => {
          observer.complete()
        },
      })

      return unsubscribe
    })
  }
}

const fetch = createFetchRetry(global.fetch, {
  retries: 3,
  retryDelay: (attempt: number) => {
    return Math.pow(2, attempt) * 1000 // 1000, 2000, 4000
  },
})

export const trpc = createTRPCProxyClient<CLIRouterType>({
  links: [
    errorLink,
    loggerLink({ enabled: () => process.env.SNAPLET_DEBUG_TRPC === '1' }),
    httpLink({
      url:
        (process.env.SNAPLET_API_HOSTNAME || 'https://api.snaplet.dev') +
        '/cli',
      headers: async () => {
        const systemConfig = await config.getSystem()
        return {
          authorization: `Bearer ${systemConfig.accessToken}`,
          'user-agent': `Snaplet CLI / ${CLI_VERSION}`,
        }
      },
      fetch: async (url, init) => {
        const systemConfig = await config.getSystem()
        // NodeJS have an issue with TCP connection being closed by the server
        // This is a workaround until the issue is fixed
        // see: https://github.com/node-fetch/node-fetch/issues/1735
        await new Promise((resolve) => setTimeout(resolve, 0))

        const result = await fetch(url, init)

        const userId = result.headers.get('SNAPLET-USER-ID')

        if (
          typeof systemConfig.userId === 'undefined' &&
          typeof userId === 'string'
        ) {
          await config.updateSystem({ userId })
        }
        return result
      },
    }),
  ],
})
