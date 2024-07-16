import fs from 'fs'
import path from 'path'

import { findConfig } from './findConfig.js'
import { loadConfig } from './loadConfig.js'
import { parseConfig, SnapletConfig } from './parseConfig.js'

const DEFAULT_CONFIG: SnapletConfig = {}

export async function getConfig(configPath = findConfig()) {
  if (!configPath) {
    return DEFAULT_CONFIG
  }

  const rawConfig = {
    filepath: configPath,
    filename: path.basename(configPath),
    source: fs.readFileSync(configPath, 'utf8'),
  }

  return await getConfigFromSource(rawConfig)
}

export async function getConfigFromSource(
  rawConfig: {
    filepath: string
    filename: string
    source: string
  } | null
) {
  if (!rawConfig) {
    return DEFAULT_CONFIG
  }

  const loadedConfig = await loadConfig(rawConfig?.filepath, rawConfig.source)

  const parsedConfig = parseConfig(loadedConfig, rawConfig.filepath)

  return parsedConfig
}
