import { flatten } from 'lodash'

import { IntrospectedStructure } from './db/introspect/introspectDatabase.js'

export const NULL_PG_TYPE = 'NULL'

export class JsonNull {}

export const PG_DATE_TYPES = new Set([
  'datetime',
  'timestamp',
  'date',
  'timestamptz',
  'datetime2',
  'smalldatetime',
  'datetimeoffset',
])

export const PG_NUMBER_TYPES = new Set([
  'tinyint',
  'int',
  'numeric',
  'integer',
  'real',
  'smallint',
  'decimal',
  'float',
  'float4',
  'float8',
  'double precision',
  'double',
  'dec',
  'fixed',
  'year',
  'smallserial',
  'serial',
  'serial2',
  'serial4',
  'serial8',
  'bigserial',
  'int2',
  'int4',
  'int8',
  'int16',
  'int32',
  'bigint',
])

export const PG_GEOMETRY_TYPES = new Set([
  'point',
  'line',
  'lseg',
  'box',
  'path',
  'circle',
])

// TODO: Find official list of types
export const JS_TO_PG_TYPES = {
  string: [
    'bpchar',
    'character_data',
    'varchar',
    'text',
    'character',
    'character varying',
    'inet',
    'cidr',
    'point',
    'lseg',
    'path',
    'box',
    'line',
    'circle',
    'macaddr',
    'macaddr8',
    'interval',
    'tsquery',
    'tsvector',
    'pg_lsn',
    'xml',
    'bit',
    'varbit',
    'bit varying',
    'uuid',
    'bytea',
    'money',
    'smallmoney',
    'datetime',
    'timestamp',
    'date',
    'time',
    'timetz',
    'timestamptz',
    'datetime2',
    'smalldatetime',
    'datetimeoffset',
    'citext',
  ],
  number: [
    'tinyint',
    'int',
    'numeric',
    'integer',
    'real',
    'smallint',
    'decimal',
    'float',
    'float4',
    'float8',
    'double precision',
    'double',
    'dec',
    'fixed',
    'year',
    'smallserial',
    'serial',
    'serial2',
    'serial4',
    'serial8',
    'bigserial',
    'int2',
    'int4',
    'int8',
    'int16',
    'int32',
    'bigint',
  ],
  boolean: ['boolean', 'bool'],
  Json: ['json', 'jsonb', 'TVP'],
  Buffer: ['binary', 'varbinary', 'image', 'UDT'],
} as const
export type JsToPgTypes = typeof JS_TO_PG_TYPES
export type NonNullableJsTypeName = keyof JsToPgTypes
export type JsTypeName = NonNullableJsTypeName | 'null'
export type PgTypeName = JsToPgTypes[NonNullableJsTypeName][number]

export const PG_TO_JS_TYPES: Record<PgTypeName, JsTypeName> =
  Object.fromEntries(
    flatten(
      Object.entries(JS_TO_PG_TYPES).map(([jsType, pgTypes]) =>
        pgTypes.map((pgType) => [pgType, jsType])
      )
    )
  ) as Record<PgTypeName, JsTypeName>

// context(justinvdm, 30 Aug 2023): The `_` checks in the code below are around for backwards compatibility -
// our older introspection queries give back nested types prefixed with an `_`, while our newer introspection
// queries give us `[]` for each nesting level
export const isNestedArrayPgType = (pgType: string): boolean =>
  pgType.startsWith('_') || pgType.endsWith('[]')

export const getPgTypeArrayDimensions = (pgType: string): number => {
  if (pgType.startsWith('_')) {
    return 1
  }

  return pgType.split('[]').length - 1
}

export const extractPrimitivePgType = (pgType: string): PgTypeName => {
  if (isNestedArrayPgType(pgType)) {
    if (pgType.startsWith('_')) {
      return pgType.slice(1) as PgTypeName
    } else {
      return pgType.replaceAll('[]', '') as PgTypeName
    }
  }

  return pgType as PgTypeName
}

export const createColumnTypeLookup = (
  structure: Pick<IntrospectedStructure, 'tables'>,
  schemaName: string,
  tableName: string
): Record<string, PgTypeName> => {
  const table = structure.tables.find(
    (d) => d.name === tableName && d.schema === schemaName
  )

  if (!table) {
    return {}
  }

  return Object.fromEntries(
    table.columns.map((column) => [column.name, column.type as PgTypeName])
  )
}
