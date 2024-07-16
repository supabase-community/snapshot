import { getPaths } from '../../../../v2/paths.js'

export function findConfig() {
  return getPaths()?.project?.snapletConfig
}
