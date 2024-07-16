import { parse as parseArray } from 'postgres-array'

import {
  JsTypeName,
  PgTypeName,
  extractPrimitivePgType,
  PG_TO_JS_TYPES,
  isNestedArrayPgType,
  JsonNull,
  getPgTypeArrayDimensions,
} from './pgTypes.js'
import { Json } from './types.js'

type Parser = (v: string) => Json

type Serializer = (v: Json) => string

export type Parsers = Partial<Record<JsTypeName, Parser>>

export type Serializers = Partial<Record<JsTypeName, Serializer>>

const PARSERS: Parsers = {
  string: String,
  number: Number,
  boolean: (v: string) => (v === 'f' ? false : true),
  Json: (v: string) => JSON.parse(v),
}

const SERIALIZERS: Serializers = {
  string: String,
  number: String,
  boolean: (v) => (v ? 't' : 'f'),
  Json: (v) => JSON.stringify(v),
}

const parseArrayColumn = (raw: string, pgType: string): Json => {
  const primitivePgType = extractPrimitivePgType(pgType)

  const parseArrayColumnValue = (value: string) => {
    return parseColumn(value, primitivePgType)
  }

  return parseArray(raw, parseArrayColumnValue)
}

export const parseColumn = (
  value: string | null,
  pgType: string,
  parsers?: Parsers
): Json => {
  if (value === null) {
    return null
  }

  if (isNestedArrayPgType(pgType)) {
    return parseArrayColumn(value, pgType)
  }

  const jsType = PG_TO_JS_TYPES[extractPrimitivePgType(pgType)]
  if (!jsType) {
    return value
  }

  const parser = parsers?.[jsType] ?? PARSERS[jsType]
  if (!parser) {
    return value
  }

  return parser(value)
}

export const serializeArrayColumn = (value: Json, pgType: string): string => {
  const arrayDimension = getPgTypeArrayDimensions(pgType)
  const jsType = PG_TO_JS_TYPES[extractPrimitivePgType(pgType)]

  if (value === null) {
    return 'NULL'
  }

  if (arrayDimension === 0 && jsType === 'Json') {
    return JSON.stringify(JSON.stringify(value))
  }

  if (Array.isArray(value)) {
    const openingBracket = arrayDimension > 0 ? '{' : '['
    const closingBracket = arrayDimension > 0 ? '}' : ']'
    const nextPgType = arrayDimension > 0 ? pgType.slice(0, -2) : pgType
    return [
      openingBracket,
      value.map((v) => serializeArrayColumn(v, nextPgType)).join(','),
      closingBracket,
    ].join('')
  }

  if (!jsType) {
    return JSON.stringify(String(value))
  }

  const serializer = SERIALIZERS[jsType]

  const result = !serializer ? String(value) : serializer(value)

  return jsType === 'string' ? JSON.stringify(result) : result
}

export const serializeColumn = (
  value: Json | JsonNull,
  pgType: string,
  serializers?: Serializers
): string | null => {
  if (value === null) {
    return null
  }

  if (value instanceof JsonNull) {
    return 'null'
  }

  if (isNestedArrayPgType(pgType) && Array.isArray(value)) {
    return serializeArrayColumn(value, pgType)
  }

  const jsType = PG_TO_JS_TYPES[extractPrimitivePgType(pgType)]

  if (!jsType) {
    return String(value)
  }

  const serializer = serializers?.[jsType] ?? SERIALIZERS[jsType]

  if (!serializer) {
    return String(value)
  }

  return serializer(value)
}

export const parseRow = <ColumnName extends string>({
  row,
  columnTypes,
  parsers,
}: {
  row: Record<ColumnName, string | null>
  columnTypes: Record<ColumnName, PgTypeName>
  parsers?: Parsers
}): Record<ColumnName, Json> => {
  const result: Partial<Record<ColumnName, Json>> = {}

  for (const columnName of Object.keys(row) as ColumnName[]) {
    const columnType = columnTypes[columnName]
    result[columnName] =
      columnType != null
        ? parseColumn(row[columnName], columnType, parsers)
        : row[columnName]
  }

  return result as Record<ColumnName, Json>
}

export const serializeRow = <ColumnName extends string>({
  row,
  columnTypes,
  serializers,
}: {
  row: Record<ColumnName, Json | JsonNull>
  columnTypes: Record<ColumnName, PgTypeName>
  serializers?: Serializers
}): Record<ColumnName, string | null> => {
  const result: Partial<Record<ColumnName, string | null>> = {}

  for (const columnName of Object.keys(row) as ColumnName[]) {
    const columnType = columnTypes[columnName]

    // context(justinvdm, 5 July 2022): If we have no column type for this column,
    // it would have stayed a string during parsing, so if we don't find a column type
    // during serializing, we should still have a string
    result[columnName] =
      columnType != null
        ? serializeColumn(row[columnName], columnType, serializers)
        : String(row[columnName])
  }

  return result as Record<ColumnName, string | null>
}
