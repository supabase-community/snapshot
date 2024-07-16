import fs from 'fs-extra'
import { merge } from 'lodash'
import path from 'path'
import { z, ZodError } from 'zod'

import { getSystemConfigPath } from '../../paths.js'

export type TimeFormat = 'RELATIVE' | 'PRECISE'
export const TIME_FORMATS: Array<TimeFormat> = ['RELATIVE', 'PRECISE']

export const SYSTEM_CONFIG_DEFAULTS: SystemConfig = {
  timeFormat: 'RELATIVE' as const,
  silenceUpgradeNotifications: false,
}

const systemConfigSchema = z.object({
  accessToken: z.string().optional(),
  anonymousId: z.string().optional(),
  userId: z.string().optional(),
  timeFormat: z
    .literal(TIME_FORMATS[0])
    .or(z.literal(TIME_FORMATS[1]))
    .default('RELATIVE'),
  silenceUpgradeNotifications: z
    .preprocess((x) => String(x).toLowerCase() !== 'false', z.boolean())
    .optional()
    .default(false),
})
export type SystemConfig = z.input<typeof systemConfigSchema>

export function parseSystemConfig(
  config: Record<string, unknown>,
  shouldOverrideWithEnv = true
) {
  if (shouldOverrideWithEnv) {
    config = merge(config, {
      accessToken: process.env.SNAPLET_ACCESS_TOKEN,
      timeFormat: process.env.SNAPLET_TIME_FORMAT,
      silenceUpgradeNotifications:
        process.env.SNAPLET_SILENCE_UPGRADE_NOTIFICATIONS,
    })
  }

  try {
    return systemConfigSchema.parse(config)
  } catch (e) {
    if (e instanceof ZodError) {
      throw new Error(`Could not parse system config: ${e.message}`)
    }
    throw e
  }
}

/**
 * This reads the system config from disk, merges the envars,
 * and validates that it's correct.
 */
export function getSystemConfig(
  configPath = getSystemConfigPath(),
  shouldOverrideWithEnv = true
) {
  let config = {}
  if (fs.existsSync(configPath)) {
    config = JSON.parse(fs.readFileSync(configPath, 'utf-8'))
  }
  return parseSystemConfig(config, shouldOverrideWithEnv)
}

export function saveSystemConfig(
  config: SystemConfig,
  configPath = getSystemConfigPath()
) {
  systemConfigSchema.parse(config)
  fs.mkdirSync(path.dirname(configPath), { recursive: true })
  fs.writeFileSync(configPath, JSON.stringify(config, undefined, 2))
}

export function updateSystemConfig(
  config: Partial<SystemConfig>,
  configPath = getSystemConfigPath()
): SystemConfig {
  const currentConfig = getSystemConfig(configPath, false)

  const nextConfig = {
    ...currentConfig,
    ...config,
  }

  saveSystemConfig(nextConfig)

  return nextConfig
}
