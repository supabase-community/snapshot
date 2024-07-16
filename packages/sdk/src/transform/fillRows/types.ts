import z from 'zod'
import { JsonNull } from '~/pgTypes.js'
import { Json } from '~/types.js'

const literalSchema = z.union([z.string(), z.number(), z.boolean(), z.null()])

const jsonValueSchema: z.ZodType<Json> = z.lazy(() =>
  z.union([literalSchema, z.array(jsonValueSchema), z.record(jsonValueSchema)])
)

const fillRowsInputRowSchema = z.object({
  line: z.number(),
  raw: z.record(z.string()),
  parsed: z.record(jsonValueSchema),
  replacement: z.record(jsonValueSchema),
})

const statusSchema = z.union([
  z.literal('original'),
  z.literal('replaced'),
  z.literal('filled'),
  z.literal('invalid'),
])

const fillRowsResultRowSchema = z.object({
  line: z.number(),
  raw: z.record(z.string().or(z.null())),
  parsed: z.record(jsonValueSchema),
  replacement: z.record(jsonValueSchema),
  filled: z.record(z.union([jsonValueSchema, z.instanceof(JsonNull)])),
  statuses: z.record(statusSchema),
})

export const fillRowsInputSchema = z.array(fillRowsInputRowSchema)

export const fillRowsResultSchema = z.array(fillRowsResultRowSchema)

export type FillRowsResultRow = z.infer<typeof fillRowsResultRowSchema>

export type FillRowsInput = z.infer<typeof fillRowsInputSchema>

export type FillRowsResult = z.infer<typeof fillRowsResultSchema>

export type FillRowsColumnStatus = z.infer<typeof statusSchema>
