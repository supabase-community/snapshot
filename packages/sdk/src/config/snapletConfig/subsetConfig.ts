import fs from 'fs-extra'
import { z, ZodError } from 'zod'

import { getPaths } from '../../paths.js'
import { SubsetConfigV2 } from './v2/getConfig/parseConfig.js'

export const target = z
  .object({
    table: z.string().nonempty(),
    orderBy: z.string().optional(),
    where: z.string().optional(),
    rowLimit: z.number().nonnegative(),
    percent: z.number().gt(0).lte(100),
  })
  .partial({
    rowLimit: true,
    percent: true,
  })
  .refine((data) => {
    const bothSepcified =
      typeof data.rowLimit === 'number' && typeof data.percent === 'number'
    return !bothSepcified
  }, 'Either `rowLimit` or `percentage` required. Both supplied.')

export interface InitialTarget {
  table: string
  percent?: number
  where?: string
  order_by?: string
  row_limit?: number
}

interface SubsetConfigOld {
  eager?: boolean
  follow_nullable_relations?: boolean
  enabled: boolean
  version?: '1' | '2'
  excluded_tables?: string[]
  fk_augmentation?: []
  initial_targets?: InitialTarget[]
  keep_disconnected_tables?: boolean
  many_to_many_tables?: string[]
  foreign_keys?: {
    table: string
    column: string
    targetTable: string
    targetColumn: string
  }[]
}

export const subsetConfigSchema = z
  .object({
    enabled: z.boolean(),
    version: z.enum(['1', '2', '3']).default('1').optional(),
    targets: z.array(target).nonempty(),
    /**
     * Include table data that is not "traversed" in the targets above.
     */
    keepDisconnectedTables: z.boolean().default(false),
    eager: z.boolean().default(false),
    followNullableRelations: z
      .union([
        z.boolean(),
        z.record(z.union([z.boolean(), z.record(z.boolean())])),
      ])
      .default(true),
    maxCyclesLoop: z
      .union([
        z.number().nonnegative(),
        z.record(
          z.union([
            z.number().nonnegative(),
            z.record(z.number().nonnegative()),
          ])
        ),
      ])
      .default(1),
    maxChildrenPerNode: z
      .union([
        z.number().nonnegative(),
        z.record(
          z.union([
            z.number().nonnegative(),
            z.record(z.number().nonnegative()),
          ])
        ),
      ])
      .optional(),
  })
  .refine(
    (data) => {
      // In version 1 of subssetting we dont allow only having a where clause
      // in target config (Atleast need a rowLimit or percentage specified)
      if (data.version === undefined || data.version === '1') {
        for (const target of data.targets) {
          if (
            typeof target.rowLimit === 'undefined' &&
            typeof target.percent === 'undefined'
          ) {
            return false
          }
        }
      }
      return true
    },
    {
      message: `Invalid subset configuration - Every target requires either a rowLimit or percent.`,
    }
  )
export type Target = z.infer<typeof target>
export type SubsetConfig = SubsetConfigV2

export const parseSubsetConfig = (
  config: z.input<typeof subsetConfigSchema>
) => {
  try {
    return subsetConfigSchema.parse(config)
  } catch (e) {
    if (e instanceof ZodError) {
      throw new Error(`Could not parse subset config: ${e.message}`)
    }
    throw e
  }
}

export const getSubsetConfigFromFile = (
  filePath?: string
): SubsetConfigOld | undefined => {
  try {
    const path = filePath || getPaths().project.subsetting
    if (path) {
      return JSON.parse(fs.readFileSync(path, 'utf-8')) as SubsetConfigOld
    }
  } catch (_error) {
    // No subsetting config found - ignore
  }

  return undefined
}
