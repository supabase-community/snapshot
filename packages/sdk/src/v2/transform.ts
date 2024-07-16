import {
  IntrospectedStructure,
  IntrospectedTableColumn,
} from '../db/introspect/introspectDatabase.js'
import { types as pgTypes } from 'pg'

import {
  ColumnTransform,
  RowTransform,
  RowTransformObject,
  Transform,
} from '../config/index.js'
import {
  TransformConfig,
  isMode,
  isParseJson,
  TransformModes,
} from '../config/snapletConfig/v2/getConfig/parseConfig.js'

import { ErrorList, SnapletError, isError } from '../errors.js'
import {
  getTransform,
  GenerateTransformModule,
} from '../generate/generateTransform.js'
import { findShape } from '../shapes.js'
import { TransformError } from '../transformError.js'
import {
  extractPrimitivePgType,
  PgTypeName,
  PG_TO_JS_TYPES,
} from '../pgTypes.js'
import type { Json, RowShape, TransformContext } from '../types.js'
import {
  COLUMN_CONSTRAINTS,
  TYPE_CATEGORY_DISPLAY_NAMES,
} from '~/db/introspect/queries/fetchTablesAndColumns.js'
import { AUTO_TRANSFORM_STRING_TEMPLATES } from '~/templates/sets/autoTransformStrings.js'

type NestedArray<Value> = Value | Array<NestedArray<Value>>

const AUTO_TRANSFORM_TRUNCATE_THRESHOLD = 1_000

export const TRANSFORM_MODES: Array<TransformModes> = [
  'auto',
  'strict',
  'unsafe',
]
const DEFAULT_TRANSFORM_MODE: TransformModes = 'unsafe'

let generateTransform: GenerateTransformModule

interface FullTransformOptions {
  $mode: TransformModes
  $parseJson: boolean
}

type TransformOptions = Partial<FullTransformOptions>

class Transformer {
  options: FullTransformOptions
  structure: Pick<IntrospectedStructure, 'enums' | 'tables'>
  transform: Transform

  constructor(
    transform: Transformer['transform'],
    structure: Transformer['structure'],
    options: Transformer['options']
  ) {
    this.transform = transform
    this.structure = structure
    this.options = options
  }

  transformRow<Row extends RowShape>(ctx: TransformContext<Row>): Row {
    try {
      return applyRowTransform<Row>(ctx, this)
    } catch (e) {
      if (
        isError(e) &&
        !(e instanceof TransformError) &&
        !(e instanceof ErrorList)
      ) {
        throw new TransformError(ctx, e)
      } else {
        throw e
      }
    }
  }
}

export const TRANSFORM_OPTIONS_DEFAULTS = {
  $mode: DEFAULT_TRANSFORM_MODE,
  $parseJson: true,
}

export async function createTransformer(
  ctx: { structure: IntrospectedStructure },
  transformConfig?: TransformConfig,
  optionsOverrides?: TransformOptions
) {
  const transform: Transform = {}
  const { $mode, $parseJson, ...schemasTransforms } = transformConfig ?? {}
  const configOptions = {
    $mode:
      (isMode($mode) ? $mode : TRANSFORM_OPTIONS_DEFAULTS.$mode) ??
      TRANSFORM_OPTIONS_DEFAULTS.$mode,
    $parseJson:
      (isParseJson($parseJson)
        ? $parseJson
        : TRANSFORM_OPTIONS_DEFAULTS.$parseJson) ??
      TRANSFORM_OPTIONS_DEFAULTS.$parseJson,
  }
  for (const [schemaName, schemaConfig] of Object.entries(
    schemasTransforms ?? {}
  )) {
    transform[schemaName] = schemaConfig
  }

  const options = {
    ...configOptions,
    ...optionsOverrides,
  }

  return new Transformer(transform, ctx.structure, options)
}

const applyColumnTransform = <Row extends RowShape>(
  row: Row,
  initialValue: Json,
  columnTransform: ColumnTransform<Row>
): Json => {
  if (initialValue === null) {
    return initialValue
  } else if (typeof columnTransform === 'function') {
    return columnTransform({ row, value: initialValue })
  } else {
    return columnTransform
  }
}

const timestampParser = pgTypes.getTypeParser(pgTypes.builtins.TIMESTAMP)

const generateDate = (key: unknown): Date =>
  new Date(getCopycat().int(key, { min: 0, max: 1683037352632 }))

// context(justinvdm, 2 May 2023): Typescript doesn't like us giving `Date`s to `isNaN`, but we
// need to in order detect invalid dates (e.g. `new Date('infinity')`)
const ensureDate = <Value>(key: Value, fn: () => Date): Date => {
  let value

  try {
    value = fn()
  } catch {
    return generateDate(key)
  }

  return value instanceof Date && !isNaN(value as unknown as number)
    ? value
    : generateDate(key)
}

const applyAutoFallbackByType: Partial<
  Record<PgTypeName, (value: unknown) => unknown>
> = {
  time(value) {
    const date = ensureDate(value, () => timestampParser(`1970-01-01 ${value}`))
    const scrambled = applyDefaultAutoFallback(date)
    const scrambledString = scrambled.toISOString()
    return scrambledString.split('T')[1]
  },
  timetz(value) {
    const date = ensureDate(value, () =>
      pgTypes.getTypeParser(pgTypes.builtins.TIMESTAMPTZ)(`1970-01-01 ${value}`)
    )
    const scrambled = applyDefaultAutoFallback(date)
    const scrambledString = scrambled.toISOString()
    return scrambledString.split('T')[1]
  },
  date(value) {
    const date = ensureDate(value, () =>
      timestampParser(`${value} 00:00:00.000Z`)
    )
    const scrambled = applyDefaultAutoFallback(date)
    const scrambledString = scrambled.toISOString()
    return scrambledString.split('T')[0]
  },
  timestamp(value) {
    const date = ensureDate(value, () =>
      pgTypes.getTypeParser(pgTypes.builtins.TIMESTAMP)(value)
    )
    const scrambled = applyDefaultAutoFallback(date)
    return scrambled.toISOString()
  },
  timestamptz(value) {
    const date = ensureDate(value, () =>
      pgTypes.getTypeParser(pgTypes.builtins.TIMESTAMPTZ)(value)
    )
    const scrambled = applyDefaultAutoFallback(date)
    return scrambled.toISOString()
  },
  interval(value) {
    const date = ensureDate(value, () =>
      timestampParser(`1970-01-01 ${value}Z`)
    )
    const scrambled = applyDefaultAutoFallback(date)
    const scrambledString = scrambled.toISOString()
    return scrambledString.split('T')[1].slice(0, -'Z'.length)
  },
}

const deepMap = <A, B>(
  value: NestedArray<A>,
  fn: (a: A) => B
): NestedArray<B> =>
  Array.isArray(value) ? value.map((a) => deepMap(a, fn)) : fn(value)

const getCopycat = () => require('@snaplet/copycat').copycat

const applyDefaultAutoFallback = <Value>(value: Value) =>
  getCopycat().scramble(value)

// context(justinvdm, 18 October 2022): In this case, `code` will always be from the templates we defined ourselves
// (not from user input). In addition, the code path this is part of is evaluated inside of the transform.ts vm already.
// So we use `eval` for simplicity.
const applyCodeAutoFallback = <Value>(code: string, value: Value) => {
  value! // context(justinvdm, 18 October 2022): `value` is eval context, we did this here to dodge linting
  return eval(`
var { copycat } = require('@snaplet/copycat');
${code}`)
}

const bugMessage = [
  '\n\nThis is likely a bug in Snaplet.',
  "We've received an error report about this to help us look into it.",
  'You can also reach out to us in #help on Discord: https://app.snaplet.dev/chat',
].join(' ')

const applyAutoFallback = <Row extends RowShape>(
  ctx: TransformContext<Row>,
  columnName: keyof Row,
  column: IntrospectedTableColumn | null,
  config: Transformer
) => {
  let value = ctx.row.parsed[columnName]

  if (value === null) {
    return null
  }

  if (!column) {
    throw new Error(
      [
        `Snaplet could find not any info about the column "${ctx.schema}"."${
          ctx.table
        }"."${columnName.toString()}". Snaplet needs this info for auto-transform mode, and cannot proceed further.`,
        bugMessage,
      ].join('')
    )
  }

  if (column.typeCategory === 'E') {
    const enumType = config.structure.enums.find(
      (d) => d.name === column.type && column.schema === ctx.schema
    )
    const values = enumType?.values ?? []

    if (!values.length) {
      throw new Error(
        [
          `Snaplet could find not any enum values for the enum type "${column.type}".`,
          bugMessage,
        ].join('')
      )
    }
    return getCopycat().oneOf([ctx.row.raw, columnName], enumType?.values ?? [])
  }

  const columnType = extractPrimitivePgType(column.type)
  const typeFallbackFn = applyAutoFallbackByType[columnType]
  const jsType = PG_TO_JS_TYPES[columnType as keyof typeof PG_TO_JS_TYPES]

  const isRawJson =
    jsType === 'Json' && typeof value === 'string' && !config.options.$parseJson

  if (isRawJson) {
    const rawValue = ctx.row.raw[columnName as string]
    value = rawValue === null ? null : JSON.parse(rawValue)
  }

  if (!typeFallbackFn && !jsType) {
    if (column.nullable) {
      return null
    }

    throw new Error(
      [
        `Snaplet could not transform column "${ctx.schema}"."${
          ctx.table
        }"."${columnName.toString()}" - we do not yet support auto-transforming the ${
          TYPE_CATEGORY_DISPLAY_NAMES[column.typeCategory ?? 'X']
        } type ${column.type}.`,
        `We've received an error report about this to help us solve this.`,
        'Until then, you can still work around this by telling Snaplet how to transform this column in your snaplet.config.ts file.',
        `Here's our docs for more on this: https://docs.snaplet.dev/reference/configuration#transform`,
      ].join(' ')
    )
  }

  let code: string | null = null

  if (!typeFallbackFn && jsType) {
    const shape = findShape(column.name, jsType)?.shape ?? null

    if (shape) {
      const api = generateTransform.createTemplateContext(
        'value',
        column,
        shape,
        jsType
      )

      const template = api.shape && AUTO_TRANSFORM_STRING_TEMPLATES[api.shape]
      code = template?.(api) ?? null
    }
  }

  const applyAutoFallbackEach = <Value>(v: Value) => {
    if (typeof v === 'string' && v.length > AUTO_TRANSFORM_TRUNCATE_THRESHOLD) {
      v = v.slice(0, AUTO_TRANSFORM_TRUNCATE_THRESHOLD) as unknown as Value
    }

    if (typeFallbackFn) {
      return typeFallbackFn(v)
    }

    if (code) {
      return applyCodeAutoFallback(code, v)
    }

    return applyDefaultAutoFallback(v)
  }

  try {
    const result = deepMap(value, applyAutoFallbackEach)
    return isRawJson ? JSON.stringify(result) : result
  } catch (e) {
    if (e instanceof TypeError && e.name === 'ScrambleTypeError') {
      throw new Error(
        [
          `Snaplet could not transform column "${ctx.schema}"."${
            ctx.table
          }"."${columnName.toString()}: the type of the value (${typeof value}) isn't a type supported for auto-transform mode.`,
          'To fix this error, add a value for this field in your snaplet.config.ts file',
        ].join('')
      )
    } else {
      throw e
    }
  }
}

const applyFallbackColumnTransform = <Row extends RowShape>(
  ctx: TransformContext<Row>,
  columnName: keyof Row,
  config: Transformer
): Row[keyof Row] => {
  const value = ctx.row.parsed[columnName]
  const { $mode } = config.options

  if ($mode == null || $mode == 'unsafe') {
    return value
  }

  const column =
    config.structure.tables
      .find((table) => table.name === ctx.table && table.schema === ctx.schema)
      ?.columns.find((column) => column.name === columnName) ?? null

  if (
    column &&
    (column.constraints.includes(COLUMN_CONSTRAINTS.FOREIGN_KEY) ||
      column.constraints.includes(COLUMN_CONSTRAINTS.PRIMARY_KEY))
  ) {
    return value
  }

  if ($mode === 'strict') {
    if (!column) {
      throw new Error(
        [
          `Snaplet could find not any info about the column "${ctx.schema}"."${
            ctx.table
          }"."${columnName.toString()}". Snaplet needs this info for strict transform mode, and cannot proceed further.`,
          bugMessage,
        ].join('')
      )
    }

    throw new SnapletError('CONFIG_STRICT_TRANSFORM_MISSING_COLUMN', {
      schema: column.schema,
      table: column.table,
      column: column.name,
    })
  } else {
    if (!config.structure) {
      throw new Error(
        [
          `Snaplet could find not any info about the db structure to transform "${
            ctx.schema
          }"."${ctx.table}"."${columnName.toString()}`,
          bugMessage,
        ].join('')
      )
    }

    return applyAutoFallback(ctx, columnName, column, config)
  }
}

const applyRowTransformObject = <Row extends RowShape>(
  ctx: TransformContext<Row>,
  transform: RowTransformObject<Row>,
  config: Transformer
): Row => {
  const results: Partial<Row> = {}

  const columnNames = Object.keys(ctx.row.parsed) as (keyof Row)[]
  const errors: Error[] = []

  for (const columnName of columnNames) {
    try {
      if (typeof transform?.[columnName] !== 'undefined') {
        results[columnName] = applyColumnTransform(
          ctx.row.parsed,
          ctx.row.parsed[columnName],
          transform[columnName] as ColumnTransform<Row>
        ) as Row[keyof Row]
      } else {
        results[columnName] = applyFallbackColumnTransform(
          ctx,
          columnName as string,
          config
        )
      }
    } catch (e) {
      let error: Error

      if (isError(e)) {
        error = new TransformError(
          {
            ...ctx,
            column: columnName.toString(),
          },
          e
        )
      } else {
        error = e as Error
      }

      errors.push(error)
    }
  }

  if (errors.length) {
    throw new ErrorList(errors)
  }

  return results as Row
}

const ensureRowTransform = <Row extends RowShape>(
  ctx: TransformContext<Row>,
  config: Transformer
): Partial<RowTransform<Row>> => {
  const schemaTransforms = config.transform?.[ctx.schema]

  if (!schemaTransforms) {
    if (config.options.$mode === 'strict') {
      throw new SnapletError('CONFIG_STRICT_TRANSFORM_MISSING_SCHEMA', {
        schema: ctx.schema,
      })
    }
  }

  const rowTransforms = schemaTransforms?.[ctx.table]

  if (!rowTransforms) {
    if (config.options.$mode === 'strict') {
      throw new SnapletError('CONFIG_STRICT_TRANSFORM_MISSING_TABLE', {
        schema: ctx.schema,
        table: ctx.table,
      })
    }
  }

  return rowTransforms
}

const applyRowTransform = <Row extends RowShape>(
  ctx: TransformContext<Row>,
  config: Transformer
): Row => {
  const transform = ensureRowTransform(ctx, config)

  const nextTransform =
    typeof transform === 'function'
      ? transform({
          row: ctx.row.parsed,
          rowIndex: ctx.row.line,
        })
      : transform

  return applyRowTransformObject(ctx, nextTransform, config)
}

export const importGenerateTransform = async () => {
  generateTransform = await getTransform()
}
