import { createTRPCProxyClient } from '@trpc/client'
import { httpLink } from '@trpc/client/links/httpLink'
import { loggerLink } from '@trpc/client/links/loggerLink'
import type { SnapshotWorkerRouter } from 'api'

import { config } from '~/lib/config.js'

import { CLI_VERSION } from '~/lib/constants.js'

export const trpc = createTRPCProxyClient<SnapshotWorkerRouter>({
  links: [
    loggerLink({ enabled: () => process.env.SNAPLET_DEBUG_TRPC === '1' }),
    httpLink({
      url:
        (process.env.SNAPLET_API_HOSTNAME || 'https://api.snaplet.dev') +
        '/snapshot-worker',
      // This function is called on every request.
      headers: async () => {
        const { SNAPLET_SNAPSHOT_ID } = process.env
        const headers: Record<string, string | undefined> = {
          authorization: `Bearer ${(await config.getSystem()).accessToken}`,
          'database-id': (await config.getProject()).projectId,
          'user-agent': `Snaplet Worker / ${CLI_VERSION}`,
        }

        if (SNAPLET_SNAPSHOT_ID) {
          headers['snapshot-id'] = SNAPLET_SNAPSHOT_ID
        }
        return headers
      },
    }),
  ],
})
