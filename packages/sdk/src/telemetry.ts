import type { Configuration } from './config/config.js'
import os from 'os'
import { PostHog } from 'posthog-node'
import { v4 as uuidv4 } from 'uuid'
import ci from 'ci-info'

import { merge } from 'lodash'
import { memoize } from 'lodash'
import { readSystemManifest, updateSystemManifest } from './systemManifest.js'

type TelemetrySource = 'cli' | 'extension' | 'seed'

interface TelemetryOptions {
  source: TelemetrySource
  config: Configuration
  isProduction?: boolean
  properties?: () => Record<string, unknown>
}

let POSTHOG_INSTANCE: PostHog

const patchPosthogCapture = (
  posthog: PostHog,
  source: TelemetrySource
): PostHog => {
  const originalCapture = posthog.capture

  posthog.capture = (event, ...xargs) => {
    // context(justinvdm, 24 May 2023): We need a way to different www, web and cli, so use a `source` property.
    // On the web, we can use `register()` (https://posthog.com/docs/libraries/js#super-properties), but
    // the node posthog client doesn't provide this (maybe intentionally). So instead we patch the client
    const nextEvent = {
      ...event,
      properties: {
        source,
        ...event.properties,
      },
    }

    return originalCapture.call(posthog, nextEvent, ...xargs)
  }

  return posthog
}

const lazyPostHog = (
  isProduction: boolean,
  source: TelemetrySource
): PostHog => {
  if (process.env.SNAPLET_DISABLE_TELEMETRY === '1' || !isProduction) {
    // @ts-expect-error - No-op methods.
    // context(10th May 2022, peterp): When a user disables telemetry we honour that,
    // and prevent PostHog from "phoning home" by mocking it.
    return {
      alias() {},
      capture() {},
      async shutdownAsync() {},
    }
  }

  if (typeof POSTHOG_INSTANCE === 'undefined') {
    POSTHOG_INSTANCE = new PostHog(
      'phc_F2nspobfCOFDskuwSN7syqKyz8aAzRTw2MEsRvQSB5G',
      {
        host: 'https://app.posthog.com',
        flushAt: 0,
        flushInterval: 0,
      }
    )
    return patchPosthogCapture(POSTHOG_INSTANCE, source)
  } else {
    return POSTHOG_INSTANCE
  }
}

const createAnonymousId = async (config: Configuration) => {
  const anonymousId = uuidv4()
  await config.updateSystem({ anonymousId })
  return anonymousId
}

const getDistinctId = async (config: Configuration) => {
  const systemConfig = await config.getSystem()
  if (typeof systemConfig?.userId === 'string') {
    return systemConfig.userId
  } else if (typeof systemConfig?.anonymousId == 'string') {
    return systemConfig?.anonymousId
  } else {
    return await createAnonymousId(config)
  }
}

export const createTelemetry = (options: TelemetryOptions) => {
  const {
    source,
    config,
    properties: baseProperties = () => ({}),
    isProduction = process.env.NODE_ENV === 'production',
  } = options

  const getPostHog = () => lazyPostHog(isProduction, source)

  const captureUserLogin = async (userId: string) => {
    // Cache the userId in the system configuration.
    const systemConfig = await config.updateSystem({ userId })

    // Associate the old "anonymousId (alias)" to the new "userId (distinctId)"
    if (typeof systemConfig.anonymousId === 'string') {
      getPostHog().alias({
        distinctId: await getDistinctId(config),
        alias: systemConfig.anonymousId,
      })
    }

    await captureEvent('$actions:user:login')
  }

  const captureEvent = async (
    event: string,
    properties: Record<string, any> = {}
  ) => {
    let projectId
    const { userId } = await config.getSystem()
    try {
      projectId = process.env.SNAPLET_PROJECT_ID
        ? process.env.SNAPLET_PROJECT_ID
        : (await config.getProject()).projectId
    } catch (e) {
      // There is case where we capture events over the cli but there is no project config
    }

    properties = {
      ...properties,
      projectId,
      isCI: ci.isCI,
      ci: {
        isPR: ci.isPR,
        name: ci.name,
      },
      host: {
        platform: os.platform(),
        release: os.release(),
        arch: os.arch(),
      },
      $set: { userId },
    }

    properties = merge(baseProperties(), properties)

    getPostHog().capture({
      distinctId: await getDistinctId(config),
      event,
      properties,
    })
  }

  const captureFirstEvent = memoize(captureEvent, (event) => event)

  const teardownTelemetry = async () => {
    const posthog = getPostHog()
    await posthog.shutdownAsync()
  }

  const captureThrottledEvent = async (
    event: string,
    interval: number,
    properties: Record<string, any> = {}
  ) => {
    const now = Date.now()
    const manifest = (await readSystemManifest()) ?? {}
    const lastEventTimestamps = (manifest.lastEventTimestamps ??= {})
    const lastEventTimestamp = lastEventTimestamps[event] ?? 0

    if (now - lastEventTimestamp > interval) {
      await captureEvent(event, properties)
      lastEventTimestamps[event] = now
      await updateSystemManifest({ lastEventTimestamps })
    }
  }

  return {
    captureEvent,
    captureFirstEvent,
    captureUserLogin,
    teardownTelemetry,
    captureThrottledEvent,
  }
}

export type Telemetry = ReturnType<typeof createTelemetry>
