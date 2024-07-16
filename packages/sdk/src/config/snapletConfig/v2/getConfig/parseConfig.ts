import { Json } from '~/types.js'
import { introspectConfigSchema } from '../../introspectConfig.js'
import { TRANSFORM_OPTIONS_DEFAULTS } from '~/v2/transform.js'
import { ZodError, z } from 'zod'
import { SnapletParseConfigError } from './errors.js'

const literalSchema = z.union([z.string(), z.number(), z.boolean(), z.null()])
const jsonSchema: z.ZodType<Json> = z.lazy(() =>
  z.union([literalSchema, z.array(jsonSchema), z.record(jsonSchema)])
)
const jsonObjectSchema = z.record(z.string(), jsonSchema)

const scalarFieldSchema = z.object({
  name: z.string(),
  type: z.string(),
})

const objectFieldSchema = z.intersection(
  scalarFieldSchema,
  z.object({
    relationFromFields: z.array(z.string()),
    relationToFields: z.array(z.string()),
  })
)

const oppositeBaseNameMapSchema = z.record(z.string(), z.string())

const seedConfigAliasSchema = z.object({
  inflection: z
    .union([
      z.object({
        modelName: z.function().args(z.string()).returns(z.string()).optional(),
        scalarField: z
          .function()
          .args(scalarFieldSchema)
          .returns(z.string())
          .optional(),
        parentField: z
          .function()
          .args(objectFieldSchema, oppositeBaseNameMapSchema)
          .returns(z.string())
          .optional(),
        childField: z
          .function()
          .args(objectFieldSchema, objectFieldSchema, oppositeBaseNameMapSchema)
          .returns(z.string())
          .optional(),
        oppositeBaseNameMap: oppositeBaseNameMapSchema.optional(),
      }),
      z.boolean(),
    ])
    .optional()
    .default(true),
  override: z
    .record(
      z.string(),
      z.object({
        name: z.string().optional(),
        fields: z.record(z.string(), z.string()).optional(),
      })
    )
    .optional(),
})

const seedConfigFingerprintSchema = z.record(
  z.string().describe('modelName'),
  z.record(
    z.string().describe('modelField'),
    z.union([
      z.object({
        count: z.union([
          z.number(),
          z.object({ min: z.number(), max: z.number() }),
        ]),
      }),
      z.object({
        options: z.record(z.string(), z.any()),
      }),
      z.object({
        schema: z.record(z.string(), z.any()).describe('jsonSchema'),
      }),
    ])
  )
)

export type GenerateConfigFingerprint = z.infer<
  typeof seedConfigFingerprintSchema
>

const seedConfigSchema = z.object({
  alias: seedConfigAliasSchema.optional(),
  fingerprint: seedConfigFingerprintSchema.optional(),
})

const selectConfigDefaultSchema = z.union([z.boolean(), z.literal('structure')])
const selectConfigExtensionsSchema = z.union([
  z.boolean(),
  z.record(z.string(), z.boolean()),
])
const selectConfigSchemaObjectSchema = z.intersection(
  z.object({
    $default: selectConfigDefaultSchema.optional(),
    $extensions: selectConfigExtensionsSchema.optional(),
  }),
  z.record(
    z.string().refine((s) => s !== '$default' && s !== '$extensions'),
    z.union([selectConfigDefaultSchema, selectConfigExtensionsSchema])
  )
)
const selectConfigSchemaSchema = z.union([
  selectConfigDefaultSchema,
  selectConfigSchemaObjectSchema,
])

export const selectConfigSchema = z.intersection(
  z.object({
    $default: selectConfigDefaultSchema.optional(),
  }),
  z.record(
    z.string(),
    z.union([
      selectConfigSchemaSchema,
      z.intersection(
        z.object({
          $default: selectConfigDefaultSchema.optional(),
          $extensions: selectConfigExtensionsSchema.optional(),
        }),
        z.record(z.string(), selectConfigSchemaSchema)
      ),
    ])
  )
)
export type SelectConfig = z.infer<typeof selectConfigSchema>

const TRANSFORM_MODES = z.union([
  z.literal('auto'),
  z.literal('strict'),
  z.literal('unsafe'),
])

export type TransformModes = z.infer<typeof TRANSFORM_MODES>

const transformConfigOptionsSchema = z.object({
  $mode: TRANSFORM_MODES.optional(),
  $parseJson: z.boolean().optional(),
})

export type TransformConfigOptions = z.infer<
  typeof transformConfigOptionsSchema
>

const columnTransformFunctionSchema = z
  .function()
  .args(
    z.object({
      row: jsonObjectSchema,
      value: jsonSchema,
    })
  )
  .returns(jsonSchema)
export type ColumnTransformFunction = z.infer<
  typeof columnTransformFunctionSchema
>
export type ColumnTransformScalar = z.infer<typeof jsonSchema>

// Final transform function always return a litleral object like `{colA: '1', colB: 2, ...}`
// representing the data of the row to insert
const columnTransformSchema = z.record(
  z.string(),
  z.union([jsonSchema, columnTransformFunctionSchema])
)

const tableTransformFunctionSchema = z
  .function()
  .args(
    z.object({
      rowIndex: z.number(),
      row: jsonObjectSchema,
    })
  )
  .returns(columnTransformSchema)

export type TableTransformFunction = z.infer<
  typeof tableTransformFunctionSchema
>
export type TableTransformScalar = z.infer<typeof columnTransformSchema>

const tableTransformSchema = z.union([
  columnTransformSchema,
  tableTransformFunctionSchema,
])

// Table transform is a dictionary of either json objects or functions
// eg:
// { tableA: { colA: 1, colB: 2 }, tableB: ({row}) => ({colA: 1, colB: 2}) }
export const transformConfigTableSchema = z.record(
  z.string().describe('table'),
  tableTransformSchema
)

type TransformConfigTable = z.infer<typeof transformConfigTableSchema>
export type Transform = Record<string, TransformConfigTable>

// This is shit but we need to use a cutom validatior until this issue
// on Zod is resolved
// https://github.com/colinhacks/zod/issues/2195
const customTransformConfigValidator = (transformConfig: any) => {
  if (typeof transformConfig !== 'object' || !transformConfig) {
    throw new ZodError([
      {
        code: 'invalid_type',
        expected: 'object',
        received: transformConfig as any,
        path: ['transform'],
        fatal: true,
        message: 'Transform is not a valid object',
      },
    ])
  }

  const { $mode, $parseJson, ...schemas } = transformConfig
  transformConfigOptionsSchema.parse({
    $mode,
    $parseJson,
  })
  for (const schemaTransforms of Object.values(schemas)) {
    transformConfigTableSchema.parse(schemaTransforms)
  }
  return true
}
type CustomTransformConfigType = Record<
  string,
  z.infer<typeof transformConfigTableSchema>
> &
  z.infer<typeof transformConfigOptionsSchema>

const customTransformConfigSchema = z.custom<CustomTransformConfigType>(
  customTransformConfigValidator
)

export function isMode(
  value: unknown
): value is z.infer<typeof transformConfigOptionsSchema>['$mode'] {
  return typeof value === 'string' && Boolean(TRANSFORM_MODES.safeParse(value))
}

export function isParseJson(
  value: unknown
): value is z.infer<typeof transformConfigOptionsSchema>['$parseJson'] {
  return typeof value === 'boolean'
}

export type TransformConfig = z.infer<typeof customTransformConfigSchema>

const exclusiveRowLimitOrPercentUnion = z.union([
  z.object({
    percent: z.never().optional(),
    rowLimit: z.number(),
  }),
  z.object({
    percent: z.number(),
    rowLimit: z.never().optional(),
  }),
])
const whereUnion = z.union([
  // If where is defined, we can omit both rowLimit and percent or provide one of them
  z.object({ where: z.string() }).and(exclusiveRowLimitOrPercentUnion),
  z.object({
    where: z.string(),
    percent: z.never().optional(),
    rowLimit: z.never().optional(),
  }),
  // If where is not defined, we need to provide either rowLimit or percent
  z
    .object({ where: z.string().optional() })
    .and(exclusiveRowLimitOrPercentUnion),
])
const targetCommonSchema = z.object({
  table: z.string().nonempty(),
  orderBy: z.string().optional(),
  where: z.string().optional(),
})
const targetSchema = targetCommonSchema.and(whereUnion)

export const subsetConfigV2Schema = z.object({
  enabled: z.boolean().default(true),
  version: z.union([z.literal('1'), z.literal('2'), z.literal('3')]).optional(),
  targets: z.array(targetSchema).nonempty(),
  keepDisconnectedTables: z.boolean().optional(),
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
        z.union([z.number().nonnegative(), z.record(z.number().nonnegative())])
      ),
    ])
    .default(1),
  maxChildrenPerNode: z
    .union([
      z.number().nonnegative(),
      z.record(
        z.union([z.number().nonnegative(), z.record(z.number().nonnegative())])
      ),
    ])
    .optional(),
  eager: z.boolean().optional(),
  taskSortAlgorithm: z
    .union([z.literal('children'), z.literal('idsCount')])
    .optional(),
  targetTraversalMode: z
    .union([z.literal('together'), z.literal('sequential')])
    .optional(),
})
export type SubsetConfigV2 = z.infer<typeof subsetConfigV2Schema>

// We divide the schema between the "base" and the "full" config
// to exclude the "generate" key from the base config
// This is because the way types are declared by generate raises an error
// when trying to re-use the type in the web app
// TODO: find why generate types throw a 'not likely portable' error on web
const baseSnapletConfigParams = {
  select: selectConfigSchema.optional(),
  transform: customTransformConfigSchema.optional(),
  subset: subsetConfigV2Schema.optional(),
  introspect: introspectConfigSchema.optional(),
}
const snapletConfigSchema = z
  .object({
    seed: seedConfigSchema.optional(),
    ...baseSnapletConfigParams,
  })
  .strict()
const baseSnapletConfigSchema = z.object(baseSnapletConfigParams)
export type SnapletConfig = z.infer<typeof snapletConfigSchema>
export type SnapletConfigV2 = SnapletConfig
export type BaseSnapletConfigV2 = z.infer<typeof baseSnapletConfigSchema>

export function parseConfig(config: any, filepath?: string) {
  try {
    const result = snapletConfigSchema.parse(config)
    // For the transform we must define the default values for the options at this level
    // for some reason zod fail to do it properly with the custom validator
    if (result.transform) {
      result.transform = {
        ...TRANSFORM_OPTIONS_DEFAULTS,
        ...result.transform,
      } as CustomTransformConfigType
    }
    return result as ReturnType<typeof snapletConfigSchema.parse>
  } catch (e) {
    if (e instanceof ZodError) {
      throw new SnapletParseConfigError(filepath, e)
    }
    throw new SnapletParseConfigError(filepath)
  }
}
