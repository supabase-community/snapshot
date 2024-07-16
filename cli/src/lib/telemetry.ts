import { createTelemetry } from '@snaplet/sdk/cli'

import { IS_PRODUCTION, CLI_VERSION } from './constants.js'
import { config } from './config.js'

const telemetry = createTelemetry({
  source: 'cli',
  config,
  isProduction: IS_PRODUCTION,
  properties() {
    return {
      version: CLI_VERSION,
      isCloud: process.env.SNAPLET_EXEC_TASK_ID != null,
    }
  },
})

export const { captureUserLogin, captureEvent, teardownTelemetry } = telemetry
