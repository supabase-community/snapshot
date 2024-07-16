import fs from 'fs'
import path from 'path'

import { findConfig } from './findConfig.js'

export function getSource(configPath = findConfig()) {
  if (!configPath) {
    return null
  }
  const fileExist = fs.existsSync(configPath)
  if (!fileExist) {
    return null
  }

  return {
    filepath: configPath,
    filename: path.basename(configPath),
    source: fs.readFileSync(configPath, 'utf8'),
  }
}
