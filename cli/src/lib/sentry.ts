import { memoize, kebabCase } from 'lodash'

import { CLI_VERSION } from './constants.js'

const MAX_CLOSING_TIMEOUT = 5000

async function _getSentry(): Promise<typeof import('@sentry/node')> {
  const Sentry = await import('@sentry/node')
  const { CaptureConsole, Dedupe } = await import('@sentry/integrations')
  Sentry.init({
    dsn: 'https://2fba2a090e8543889606914e0230ad1c@o503558.ingest.sentry.io/5588827',
    tracesSampleRate: 1.0,
    environment: process.env.STAGE
      ? kebabCase(process.env.STAGE).slice(0, 63)
      : 'production',
    integrations: [
      new Dedupe(),
      new CaptureConsole({
        levels: ['error', 'assert'],
      }),
    ],
    release: CLI_VERSION,
  })
  Sentry.setTag('side', 'cli')
  Sentry.setTag('cli-safe-mode', process.env.SNAPLET_SAFE_MODE)

  return Sentry
}

export const getSentry = memoize(_getSentry)

export const closeSentry = async () => {
  const sentry = await getSentry()
  // We leave 5s for sentry to send all his errors in his queue
  await sentry.close(MAX_CLOSING_TIMEOUT)
}
