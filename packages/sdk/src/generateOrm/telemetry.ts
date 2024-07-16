import { Configuration } from '~/config/config.js'
import { type Telemetry, createTelemetry } from '~/telemetry.js'

export const EVENT_THROTTLE_INTERVAL = 1000 * 60 * 60 * 24

let telemetry: Telemetry | undefined

interface SetupSeedProps {
  version: string
  config: Configuration
}

export const setupSeedTelemetry = ({ config, version }: SetupSeedProps) => {
  telemetry = createTelemetry({
    source: 'seed',
    config,
    isProduction: true,
    properties() {
      return {
        version,
      }
    },
  })

  process.on('beforeExit', async () => {
    await telemetry?.teardownTelemetry()
  })
}

export const captureThrottledEvent = (name: string) => {
  // context(justinvdm, 9 Jan 2024): Schedule for start of next event loop to not block
  // the caller unnecessarily
  process.nextTick(async () => {
    await telemetry?.captureThrottledEvent(name, EVENT_THROTTLE_INTERVAL)
  })
}
