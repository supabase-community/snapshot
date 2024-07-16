import { snakeCase } from 'lodash'
import os from 'os'

import type {
  IntrospectedEnum,
  IntrospectedStructure,
  IntrospectedTable,
} from './db/introspect/introspectDatabase.js'
import { TRANSFORM_MODES } from './transform.js'
import {
  isNestedArrayPgType,
  extractPrimitivePgType,
  PG_TO_JS_TYPES,
  getPgTypeArrayDimensions,
} from './pgTypes.js'

/**
 * enum typedef name from database structure
 */
const enumTypeName = (e: IntrospectedEnum) => {
  return `Enum_${snakeCase(e.schema)}_${snakeCase(e.name)}`
}

export const generateEnumTypes = ({ enums }: IntrospectedStructure) => {
  return (enums ?? [])
    .map((e) => {
      const v = e.values.map((v) => `'${v}'`).join(' | ')
      return `type ${enumTypeName(e)} = ${v}`
    })
    .join(os.EOL)
}

function pg2tsTypeName(enums: IntrospectedEnum[], postgresType: string) {
  const primitiveType = extractPrimitivePgType(postgresType)

  const jsType = PG_TO_JS_TYPES[primitiveType]

  if (jsType) {
    return jsType
  }

  const e = enums.find(({ name }) => name === primitiveType)

  if (e) {
    return enumTypeName(e)
  }

  return 'unknown'
}

/**
 * Convert a PostgresQL field type to a TypeScript Type or Enum
 */
const pg2tsType = (
  postgresType: string,
  { enums }: { enums: IntrospectedEnum[] }
) => {
  let type = pg2tsTypeName(enums, postgresType)

  if (isNestedArrayPgType(postgresType)) {
    type = `${type}${'[]'.repeat(getPgTypeArrayDimensions(postgresType))}`
  }

  return type
}

/**
 * table typedef name from database structure
 */
const tableTypeName = (table: IntrospectedTable) => {
  return `Table_${snakeCase(table.schema)}_${snakeCase(table.name)}`
}

export const generateTableTypes = ({
  tables,
  enums,
}: IntrospectedStructure) => {
  return tables
    .map((table) => {
      const columnTypes = table.columns
        .map((column) => {
          return `  "${column.name}": ${pg2tsType(column.type, {
            enums: enums ?? [],
          })}`
        })
        .join(os.EOL)
      return `interface ${tableTypeName(table)} {
${columnTypes}
}`
    })
    .join(os.EOL)
}

export const generateSchemaTypes = (structure: IntrospectedStructure) => {
  return structure.schemas
    .map((schemaName) => {
      const tableFields = structure.tables
        .filter((table) => table.schema === schemaName)
        .map((table) => {
          return `  "${table.name}": false | ((ctx: { row: ${tableTypeName(
            table
          )}, rowIndex: number }) => Partial<${tableTypeName(table)}>)`
        })
        .join(os.EOL)

      return `interface Schema_${snakeCase(schemaName)} {
${tableFields}
}`
    })
    .join(os.EOL)
}

export const generateDatabaseType = (structure: IntrospectedStructure) => {
  const schemaTypes = structure.schemas
    .map((schemaName) => `  "${schemaName}": Partial<Schema_${schemaName}>`)
    .join(os.EOL)

  return `export interface Database {
${schemaTypes}
}`
}

export const generateStructureTypes = (structure: IntrospectedStructure) => {
  const schemaItems = structure.schemas.map((s) => `"${s}"`).join(', ')
  const schemaList = `$schemas: [${schemaItems}]`

  const schemas = structure.schemas
    .map((s) => {
      const schemaTables = structure.tables.filter((t) => t.schema === s)

      const tableItems = schemaTables.map((t) => `"${t.name}"`).join(', ')
      const tableList = `$tables: [${tableItems}]`

      const tables = schemaTables
        .map((t) => {
          const columnItems = t.columns.map((c) => `"${c.name}"`).join(', ')
          const columnList = `$columns: [${columnItems}]`

          const columns = t.columns
            .map((c) => {
              return `"${c.name}": {
  default: ${
    c.default === null || c.default === undefined
      ? c.default
      : `"${c.default.replace(/"/g, '\\"')}"`
  },
  nullable: ${c.nullable},
  type: "${c.type}",
},`
            })
            .join(os.EOL)

          return `"${t.name}": {
  ${columnList},
  ${columns}
},`
        })
        .join(os.EOL)

      return `"${s}": {
  ${tableList},
  ${tables}
},`
    })
    .join(os.EOL)

  return `export type Structure = {
  ${schemaList},
  ${schemas}
}`
}

export const generateTransformOptions =
  () => `export interface TransformOptions {
  mode?: ${Object.values(TRANSFORM_MODES)
    .map((v) => `'${v}'`)
    .join(' | ')}
  parseJson?: boolean
}`
