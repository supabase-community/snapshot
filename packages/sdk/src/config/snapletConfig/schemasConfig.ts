import fs from 'fs-extra'
import { z, ZodError } from 'zod'

import { getPaths } from '../../paths.js'

export const schemasConfigSchema = z.record(
  z.union([z.boolean(), z.object({ extensions: z.record(z.boolean()) })])
)

export type SchemasConfig = z.infer<typeof schemasConfigSchema>

export function parseSchemasConfig(config: Record<string, unknown>) {
  try {
    return schemasConfigSchema.parse(config)
  } catch (e) {
    if (e instanceof ZodError) {
      throw new Error(`Could not parse schemas config: ${e.message}`)
    }
    throw e
  }
}

export function getSchemasConfig(configPath = getPaths().project.schemas) {
  let config = {}
  if (configPath && fs.existsSync(configPath)) {
    config = JSON.parse(fs.readFileSync(configPath, 'utf-8'))
  }
  return parseSchemasConfig(config)
}

/**
 * We want to determine if we should dump the entire schema, or a subset of it via
 * the --schema flag.
 * The --schema flag prevents all extensions from being exported, and they have
 * to be manually specified.
 */
export const schemaIsModified = (schemasConfig?: object) => {
  return Object.keys(schemasConfig ?? {})?.length > 0
}
