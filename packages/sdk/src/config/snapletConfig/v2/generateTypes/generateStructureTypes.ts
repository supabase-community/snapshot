import { snakeCase, groupBy } from 'lodash'
import os from 'os'

import {
  isNestedArrayPgType,
  extractPrimitivePgType,
  PG_TO_JS_TYPES,
  getPgTypeArrayDimensions,
} from '../../../../pgTypes.js'
import { IntrospectedStructure } from '../../../../db/introspect/introspectDatabase.js'
import { escapeKey } from './escapeKey.js'

export function generateStructureTypes(structure: IntrospectedStructure) {
  return `//#region structure
${generateStructureExtraTypes()}
${generateEnumTypes(structure['enums'])}
${generateTableTypes(structure)}
${generateSchemaTypes(structure)}
${generateDatabaseType(structure)}
${generateExtensionType(structure)}
${generateTableRelationsType(structure)}
//#endregion`
}

function generateStructureExtraTypes() {
  return `type JsonPrimitive = null | number | string | boolean;
type Nested<V> = V | { [s: string]: V | Nested<V> } | Array<V | Nested<V>>;
type Json = Nested<JsonPrimitive>;`
}

/**
 * enum typedef name from database structure
 */
const enumTypeName = (e: IntrospectedStructure['enums'][number]) => {
  return `Enum_${snakeCase(e.schema)}_${snakeCase(e.name)}`
}

const generateEnumTypes = (enums: IntrospectedStructure['enums']) => {
  return enums
    .map((e) => {
      const v = e.values.map((v) => `'${v}'`).join(' | ')
      return `type ${enumTypeName(e)} = ${v};`
    })
    .join(os.EOL)
}

function pg2tsTypeName(
  enums: IntrospectedStructure['enums'],
  postgresType: string
) {
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
  nullable: boolean,
  { enums }: { enums: IntrospectedStructure['enums'] }
) => {
  let type = pg2tsTypeName(enums, postgresType)

  if (isNestedArrayPgType(postgresType)) {
    type = `${type}${'[]'.repeat(getPgTypeArrayDimensions(postgresType))}`
  }

  if (nullable) {
    type = `${type} | null`
  }

  return type
}

/**
 * table typedef name from database structure
 */
const tableTypeName = (table: IntrospectedStructure['tables'][number]) => {
  return `Table_${snakeCase(table.schema)}_${snakeCase(table.name)}`
}

const generateTableTypes = ({
  tables,
  enums,
}: Pick<IntrospectedStructure, 'tables' | 'enums'>) => {
  return tables
    .map((table) => {
      const columnTypes = table.columns
        // If a column is generated ALWAYS, it's a computed column it won't have any data in the snapshot
        // and we won't be able to apply tranformations to it so we hide them
        .filter((column) => column.generated !== 'ALWAYS')
        .map((column) => {
          const pgTsType = pg2tsType(column.type, column.nullable, { enums })
          // If we can't determine the type, we'll just use unknown and add a comment
          // to the type definition asking the user to report the issue and manually type it
          if (pgTsType.startsWith('unknown')) {
            return [
              `  /**`,
              `  * We couldn't determine the type of this column. The type might be coming from an unknown extension`,
              `  * or be specific to your database. Please if it's a common used type report this issue so we can fix it!`,
              `  * Otherwise, please manually type this column by casting it to the correct type.`,
              `  * @example`,
              `  * Here is a cast example for copycat use:`,
              '  * ```',
              `  * copycat.scramble(row.unknownColumn as string)`,
              '  * ```',
              `  */`,
              `  ${escapeKey(column.name)}: ${pgTsType};`,
            ].join(os.EOL)
          }
          return `  ${escapeKey(column.name)}: ${pgTsType};`
        })
        .join(os.EOL)
      return `interface ${tableTypeName(table)} {
${columnTypes}
}`
    })
    .join(os.EOL)
}

const generateSchemaTypes = (structure: IntrospectedStructure) => {
  return structure.schemas
    .map((schemaName) => {
      // We must cast here because the IntrospectedStructure union have some uncompatibles types
      // TODO: remove this cast when we finish the migration from DbStructure to IntrospectedStructure everywhere
      // including in the DbInfo type
      const tableFields = structure.tables
        .filter((table) => table.schema === schemaName)
        .map((table) => {
          return `  ${escapeKey(table.name)}: ${tableTypeName(table)};`
        })
        .join(os.EOL)

      return `interface Schema_${snakeCase(schemaName)} {
${tableFields}
}`
    })
    .join(os.EOL)
}

const generateDatabaseType = (
  structure: Pick<IntrospectedStructure, 'schemas'>
) => {
  const schemaTypes = structure.schemas
    .map((schemaName) => `  ${escapeKey(schemaName)}: Schema_${schemaName};`)
    .join(os.EOL)

  return `interface Database {
${schemaTypes}
}`
}

const generateExtensionType = (
  structure: Pick<IntrospectedStructure, 'extensions'>
) => {
  const extensionsBySchema = groupBy(structure.extensions, 'schema')
  const extensionTypes = Object.entries(extensionsBySchema)
    .map(
      ([schema, extensions]) =>
        `  ${escapeKey(schema)}: ${extensions
          .sort((a, b) => a.name.localeCompare(b.name))
          .map((e) => `"${e.name}"`)
          .join(' | ')};`
    )
    .join(os.EOL)

  return `interface Extension {
${extensionTypes}
}`
}

const generateTableParentChildRelations = (
  table: Pick<IntrospectedStructure, 'tables'>['tables'][number]
) => {
  const parentRelations = table.parents
    .map((parent) => {
      return `       ${escapeKey(parent.id)}: ${escapeKey(parent.targetTable)};`
    })
    .join(os.EOL)
  const childRelations = table.children
    .map((child) => {
      return `       ${escapeKey(child.id)}: ${escapeKey(child.fkTable)};`
    })
    .join(os.EOL)
  const parentDestinationsTables = Array.from(
    new Set(
      table.parents.map((parent) => {
        return `${escapeKey(parent.targetTable)}`
      })
    )
  ).join(` | `)
  const childDestinationsTables = Array.from(
    new Set(
      table.children.map((child) => {
        return `${escapeKey(child.fkTable)}`
      })
    )
  ).join(` | `)
  return `parent: {
${parentRelations}
    };
    children: {
${childRelations}
    };
    parentDestinationsTables: ${parentDestinationsTables} | {};
    childDestinationsTables: ${childDestinationsTables} | {};
    `
}

const generateTableRelationsType = (
  structure: Pick<IntrospectedStructure, 'tables'>
) => {
  const tableWithRelationsIds = structure.tables
    .filter((t) => t.parents.length > 0 || t.children.length > 0)
    .map(
      (table) => `  ${escapeKey(table.id)}: {
    ${generateTableParentChildRelations(table)}
  };`
    )
    .join(os.EOL)
  return `interface Tables_relationships {
${tableWithRelationsIds}
}`
}
