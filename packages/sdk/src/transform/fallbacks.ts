import { SnapletError } from '../errors.js'
import { types as pgTypes } from 'pg'
import {
  COLUMN_CONSTRAINTS,
  TYPE_CATEGORY_DISPLAY_NAMES,
} from '../db/introspect/queries/fetchTablesAndColumns.js'
import { findShape } from '../shapes.js'
import { getTransform } from '../generate/index.js'
import { GenerateTransformModule } from '../generate/index.js'
import {
  extractPrimitivePgType,
  PgTypeName,
  PG_TO_JS_TYPES,
  JsonNull,
} from '../pgTypes.js'
import type { Json, RowShape } from '../types.js'
import { ColumnInfos, StructureInfos } from './transform.js'
import { AUTO_TRANSFORM_STRING_TEMPLATES } from '~/templates/sets/autoTransformStrings.js'

type NestedArray<Value> = Value | Array<NestedArray<Value>>

// note(justinvdm, 18 Oct 2022): Also repeated in cli to avoid bloating startup time. Please keep them in sync.
// https://github.com/snaplet/snaplet/blob/bb2c37fe8dd33aec6b19fcab297daf9f0df96e69/cli/src/commands/snapshot/actions/capture/captureAction.ts#L30
export const TRANSFORM_MODES = {
  AUTO: 'auto',
  STRICT: 'strict',
  UNSAFE: 'unsafe',
} as const

const AUTO_TRANSFORM_TRUNCATE_THRESHOLD = 1_000

let generateTransform: GenerateTransformModule | undefined

export const DEFAULT_TRANSFORM_MODE: TransformFallbackMode =
  TRANSFORM_MODES.UNSAFE

export type TransformFallbackMode =
  (typeof TRANSFORM_MODES)[keyof typeof TRANSFORM_MODES]

const timestampParser = pgTypes.getTypeParser(pgTypes.builtins.TIMESTAMP)

export interface ApplyFallbackOptions {
  schemaName: string
  tableName: string
  columnName: string
  structure: StructureInfos
  mode: TransformFallbackMode
  parseJson?: boolean
  row: {
    line: number
    raw: Record<string, string | null>
    parsed: RowShape
  }
}

interface ApplyAutoFallbackOptions extends ApplyFallbackOptions {
  column: ColumnInfos
}

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

const applyAutoFallback = (options: ApplyAutoFallbackOptions) => {
  const {
    schemaName,
    tableName,
    columnName,
    structure,
    column,
    parseJson,
    row,
  } = options
  let value = row.parsed[columnName]

  if (value === null) {
    return null
  }

  if (column.typeCategory === 'E') {
    const enumType = (structure.enums ?? []).find(
      (d) => d.name === column.type && column.schema === schemaName
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

    return getCopycat().oneOf([row.raw, columnName], enumType?.values ?? [])
  }

  const columnType = extractPrimitivePgType(column.type)
  const typeFallbackFn = applyAutoFallbackByType[columnType]
  const jsType = PG_TO_JS_TYPES[columnType as keyof typeof PG_TO_JS_TYPES]

  let isRawJson

  if (
    (isRawJson = jsType === 'Json' && typeof value === 'string' && !parseJson)
  ) {
    value = JSON.parse(value as string)
  }

  if (!typeFallbackFn && !jsType) {
    if (column.nullable) {
      return null
    }

    throw new Error(
      [
        `Snaplet could not transform column "${schemaName}"."${tableName}"."${columnName.toString()}" - we do not yet support auto-transforming the ${
          TYPE_CATEGORY_DISPLAY_NAMES[column.typeCategory ?? 'X']
        } type ${column.type}.`,
        `We've received an error report about this to help us solve this.`,
        'Until then, you can still work around this by telling Snaplet how to transform this column in your transform.ts file.',
        `Here's our docs for more on this: https://docs.snaplet.dev/reference/configuration#transform`,
      ].join(' ')
    )
  }

  let code: string | null = null

  if (!typeFallbackFn && jsType) {
    const shape = findShape(column.name, jsType)?.shape ?? null

    if (shape) {
      const api = generateTransform?.createTemplateContext(
        'value',
        column,
        shape,
        jsType
      )

      if (api) {
        const template = api.shape && AUTO_TRANSFORM_STRING_TEMPLATES[api.shape]
        code = template?.(api) ?? null
      } else {
        code = null
      }
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
          `Snaplet could not transform column "${schemaName}"."${tableName}"."${columnName.toString()}: the type of the value (${typeof value}) isn't a type supported for auto-transform mode.`,
          'To fix this error, add a value for this field in your transform.ts file',
        ].join('')
      )
    } else {
      throw e
    }
  }
}

export const applyFallback = (
  options: ApplyFallbackOptions
): Json | JsonNull => {
  const { schemaName, tableName, columnName, mode, row, structure } = options
  const value = row.parsed[columnName]

  const column =
    structure.tables
      .find((table) => table.name === tableName && table.schema === schemaName)
      ?.columns.find((column) => column.name === columnName) ?? null

  if (column?.type === 'json' || column?.type === 'jsonb') {
    if (row.raw[columnName] === 'null') {
      return new JsonNull()
    }
  }

  if (mode == null || mode == TRANSFORM_MODES.UNSAFE) {
    if (options.structure.tables) return value
  }

  if (
    column &&
    (column.constraints?.includes(COLUMN_CONSTRAINTS.FOREIGN_KEY) ||
      column.constraints?.includes(COLUMN_CONSTRAINTS.PRIMARY_KEY))
  ) {
    return value
  }

  if (mode === TRANSFORM_MODES.STRICT) {
    if (!column) {
      throw new Error(
        [
          `Snaplet could find not any info about the column "${schemaName}"."${tableName}"."${columnName.toString()}". Snaplet needs this info for strict transform mode, and cannot proceed further.`,
          bugMessage,
        ].join('')
      )
    }

    throw new SnapletError('CONFIG_STRICT_TRANSFORM_MISSING_COLUMN', {
      schema: column.schema ?? schemaName,
      table: column.table ?? tableName,
      column: column.name,
    })
  } else {
    if (!structure) {
      throw new Error(
        [
          `Snaplet could find not any info about the db structure to transform "${schemaName}"."${tableName}"."${columnName.toString()}`,
          bugMessage,
        ].join('')
      )
    }

    if (!column) {
      throw new Error(
        [
          `Snaplet could find not any info about the column "${schemaName}"."${tableName}"."${columnName.toString()}". Snaplet needs this info for auto-transform mode, and cannot proceed further.`,
          bugMessage,
        ].join('')
      )
    }

    return applyAutoFallback({
      ...options,
      column,
    })
  }
}

export const importGenerateTransform = async () => {
  generateTransform = await getTransform()
}
