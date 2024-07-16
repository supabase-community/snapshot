import { IntrospectedStructure } from './db/introspect/introspectDatabase.js'

type ColumnInfos = Pick<
  IntrospectedStructure['tables'][number]['columns'][number],
  'name' | 'type' | 'default' | 'nullable'
>
type TableInfos = Pick<
  IntrospectedStructure['tables'][number],
  'name' | 'schema'
> & {
  columns: Array<ColumnInfos>
}

const buildColumnMap = (
  columnMap: Record<string, any>,
  column: ColumnInfos
) => {
  columnMap[column.name] = {
    type: column.type,
    default: column.default,
    nullable: column.nullable,
  }

  return columnMap
}

const buildTableMap = (
  tableMap: Record<string, any>,
  columns: Array<ColumnInfos>,
  tableName: string
) => {
  const $columns = columns.map((c) => c.name)

  const columnMap = columns.reduce(buildColumnMap, {} as Record<string, any>)

  tableMap[tableName] = {
    $columns,
    ...columnMap,
  }

  return tableMap
}

const buildSchemaMap =
  (tables: Array<TableInfos>) =>
  (schemaMap: Record<string, any>, schema: string) => {
    const schemaTables = tables.filter((t) => t.schema === schema)

    const $tables = schemaTables.map((t) => t.name)

    const tableMap = schemaTables.reduce(
      (acc, currentValue) =>
        buildTableMap(acc, currentValue.columns, currentValue.name),
      {}
    )

    schemaMap[schema] = {
      $tables,
      ...tableMap,
    }

    return schemaMap
  }

export const createStructureObject = (
  dbStructure: Pick<IntrospectedStructure, 'schemas'> & {
    tables: Array<TableInfos>
  }
) => {
  const $schemas = dbStructure.schemas

  const schemaMap = dbStructure.schemas.reduce(
    buildSchemaMap(dbStructure.tables),
    {} as Record<string, any>
  )

  return {
    $schemas,
    ...schemaMap,
  }
}
