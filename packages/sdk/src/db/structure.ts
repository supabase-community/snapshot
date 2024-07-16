import z from 'zod'

import { Shape, ShapeContext } from '../shapes.js'
import { SubsetConfig } from '../config/snapletConfig/subsetConfig.js'
import { ShapeGenerate } from '~/shapesGenerate.js'

export interface PredictedShape {
  input: string
  column: string
  shape?: Shape | ShapeGenerate
  confidence?: number
  context?: ShapeContext
  confidenceContext?: number
}

export interface TableShapePredictions {
  schemaName: string
  tableName: string
  predictions: PredictedShape[]
}

export type DataExample = {
  shape?: string
  input?: string
  examples: string[]
}

export type DatabaseStoredSnapshotConfig = {
  schemas?: Record<string, any>
  transform?: string
  subsetting?: string
  publicKey?: string
  oldTransformations?: Record<string, any>
  override?: {
    subset?: SubsetConfig
  }
}

export type DatabaseStoredProjectConfig = Omit<
  DatabaseStoredSnapshotConfig,
  'override'
>

export const databaseStoredProjectConfigSchema = z.object({
  schemas: z.record(z.any()).optional(),
  transform: z.string().optional(),
  subsetting: z.string().optional(),
  publicKey: z.string().optional(),
  oldTransformations: z.record(z.any()).optional(),
}) satisfies z.ZodType<DatabaseStoredProjectConfig>

export const databaseStoredSnapshotConfigSchema = z.object({
  ...databaseStoredProjectConfigSchema.shape,
  override: z
    .object({
      // Using subsetConfigSchema fail with a type error on satifies for some reason
      subset: z.any(),
    })
    .optional(),
}) satisfies z.ZodType<DatabaseStoredSnapshotConfig>
