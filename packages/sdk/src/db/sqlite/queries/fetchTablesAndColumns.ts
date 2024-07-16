import { SqliteClient, queryNext } from '../client.js'
import { sortBy } from 'lodash'

// We crawl over the types to get the common SQL types
// so they must be ordered by
const COMMON_SQL_TYPES = [
  'INT2',
  'INT8',
  'INTEGER',
  'INT',
  'TINYINT',
  'SMALLINT',
  'MEDIUMINT',
  'BIGINT',
  'UNSIGNED BIG INT',
  'CHARACTER',
  'VARCHAR',
  'VARYING CHARACTER',
  'NCHAR',
  'NATIVE CHARACTER',
  'NVARCHAR',
  'TEXT',
  'CLOB',
  'BLOB',
  'ANY',
  'REAL',
  'DOUBLE PRECISION',
  'DOUBLE',
  'FLOAT',
  'NUMERIC',
  'DECIMAL',
  'BOOLEAN',
  'DATETIME',
  'DATE',
] as const

// We sort the types by length so we can match the type with the longest prefix
const SORTED_SQL_TYPES = sortBy(COMMON_SQL_TYPES, (t) => t.length)

const SQLITE_AFFINITY = ['null', 'integer', 'real', 'text', 'blob'] as const
export type SQLiteAffinity = (typeof SQLITE_AFFINITY)[number]

export function mapCommonTypesToAffinity(
  type: string,
  isNullable: boolean
): SQLiteAffinity {
  const upperCasedType = type.toUpperCase()
  const commonSQLType = SORTED_SQL_TYPES.find((t) =>
    upperCasedType.startsWith(t)
  )
  // If it's a common type, we return the affinity
  switch (commonSQLType) {
    case 'INT2':
    case 'INT8':
    case 'INTEGER':
    case 'INT':
    case 'TINYINT':
    case 'SMALLINT':
    case 'MEDIUMINT':
    case 'BIGINT':
    case 'UNSIGNED BIG INT':
    case 'DECIMAL':
      return 'integer'
    case 'DOUBLE':
    case 'DOUBLE PRECISION':
    case 'FLOAT':
    case 'REAL':
      return 'real'
    case 'CHARACTER':
    case 'VARCHAR':
    case 'VARYING CHARACTER':
    case 'NCHAR':
    case 'NATIVE CHARACTER':
    case 'NVARCHAR':
    case 'TEXT':
    case 'CLOB':
      return 'text'
    case 'BLOB':
      return 'blob'
    // If it's not a common type, we return null
    default:
      return isNullable ? 'null' : 'text'
  }
}

export const COLUMN_CONSTRAINTS = {
  PRIMARY_KEY: 'p',
  FOREIGN_KEY: 'f',
  UNIQUE: 'u',
} as const

export type ColumnConstraintType =
  (typeof COLUMN_CONSTRAINTS)[keyof typeof COLUMN_CONSTRAINTS]

type SelectColumnsResult = {
  id: string
  name: string
  type: string
  affinity: SQLiteAffinity
  table: string
  nullable: boolean
  default: string | null
  constraints: ColumnConstraintType[]
}

type SelectTablesResult = {
  schema: string
  name: string
  type: 'table' | 'view' | 'shadow' | 'virtual'
  ncol: number
  // Tables without rowid
  wr: 1 | 0
  strict: 1 | 0
}

type FetchTableAndColumnsResult = {
  id: SelectTablesResult['name']
  name: SelectTablesResult['name']
  type: 'table'
  // Tables without rowid
  wr: 1 | 0
  strict: 1 | 0
  columns: Array<SelectColumnsResult>
}

export type FetchTableAndColumnsResultRaw = {
  tableId: string
  tableName: string
  tableType: 'table'
  tableWr: 1 | 0
  tableStrict: 1 | 0
  colCid: number
  colName: string
  colType: string
  colNotNull: 0 | 1
  colDefaultValue: string | null
  colPk: 0 | 1
}

export const FETCH_TABLE_COLUMNS_LIST = `
  SELECT
    alltables.name  as tableId,
    alltables.name  as tableName,
    alltables.type  as tableType,
    tl.wr           as tableWr,
    tl.strict       as tableStrict,
    ti.cid	        as colCid,
    ti.name	        as colName,
    ti.type	        as colType,
    ti."notnull"    as colNotNull,
    ti.dflt_value   as colDefaultValue,
    ti.pk           as colPk
  FROM
      sqlite_master AS alltables,
      pragma_table_list(alltables.name) AS tl,
      pragma_table_info(tl.name) AS ti
  WHERE
    alltables.type = 'table' AND alltables.name NOT LIKE 'sqlite_%'
  ORDER BY
    alltables.name, ti.cid
`

type FetchTableForeignKeysResultRaw = {
  tableId: string
  tableName: string
  fkId: number
  fkSeq: number
  fkFromColumn: string
  fkToColumn: string
  fkToTable: string
}

const FETCH_TABLE_FOREIGN_KEYS = `
SELECT
	alltables.name  as tableId,
	alltables.name  as tableName,
	fk.id           as fkId,
	fk.seq          as fkSeq,
	fk."from"       as fkFromColumn,
	fk."to"         as fkToColumn,
	fk."table"      as fkToTable
FROM
  	sqlite_master AS alltables,
  	pragma_foreign_key_list(alltables.name) AS fk
WHERE
  alltables.type = 'table' AND alltables.name NOT LIKE 'sqlite_%'
ORDER BY
  alltables.name, fk.id
`

type FetchCompositePrimaryKeysResultRaw = {
  tableName: string
  idxColName: string
}

const FETCH_TABLE_COMPOSITE_PRIMARY_KEYS = `
SELECT
  alltables.name AS tableName,
  indexinfos.name AS idxColName
FROM
  sqlite_master AS alltables,
  pragma_index_list(alltables.name) AS indexlist,
  pragma_index_info(indexlist.name) AS indexinfos
WHERE
  alltables.type = 'table' AND alltables.name NOT LIKE 'sqlite_%' AND
  indexlist.origin = 'pk'
ORDER BY
	alltables.name, indexlist.name, indexinfos.seqno
`

export async function fetchTablesAndColumns(
  client: SqliteClient
): Promise<FetchTableAndColumnsResult[]> {
  const groupedResults: Record<string, FetchTableAndColumnsResult> = {}
  const resultsColumns = await queryNext<FetchTableAndColumnsResultRaw>(
    FETCH_TABLE_COLUMNS_LIST,
    { client }
  )
  const resultsForeignKeys = await queryNext<FetchTableForeignKeysResultRaw>(
    FETCH_TABLE_FOREIGN_KEYS,
    { client }
  )
  const resultsCompositePrimaryKeys =
    await queryNext<FetchCompositePrimaryKeysResultRaw>(
      FETCH_TABLE_COMPOSITE_PRIMARY_KEYS,
      { client }
    )
  const compositePrimaryKeysGroupedByTable = resultsCompositePrimaryKeys.reduce(
    (acc, result) => {
      if (!acc[result.tableName]) {
        acc[result.tableName] = []
      }
      acc[result.tableName].push(result)
      return acc
    },
    {} as Record<string, FetchCompositePrimaryKeysResultRaw[]>
  )
  const foreignKeysGroupedByTable = resultsForeignKeys.reduce(
    (acc, result) => {
      if (!acc[result.tableId]) {
        acc[result.tableId] = []
      }
      acc[result.tableId].push(result)
      return acc
    },
    {} as Record<string, FetchTableForeignKeysResultRaw[]>
  )

  for (const result of resultsColumns) {
    const tableId = result.tableId
    const table = groupedResults[tableId]
    const tableForeignKeys = foreignKeysGroupedByTable[tableId] || []
    const tableCompositePrimaryKeys =
      compositePrimaryKeysGroupedByTable[tableId] || []
    if (!table) {
      groupedResults[tableId] = {
        id: result.tableId,
        name: result.tableName,
        type: result.tableType,
        wr: result.tableWr,
        strict: result.tableStrict,
        columns: [],
      }
    }
    const columnIsForeignKey = tableForeignKeys.some(
      (fk) => fk.fkFromColumn === result.colName
    )
    const columnIsPrimaryKey = result.colPk
      ? true
      : tableCompositePrimaryKeys.some(
          (cpk) => cpk.idxColName === result.colName
        )
    const constraints: ColumnConstraintType[] = []
    if (columnIsForeignKey) {
      constraints.push(COLUMN_CONSTRAINTS.FOREIGN_KEY)
    }
    if (columnIsPrimaryKey) {
      constraints.push(COLUMN_CONSTRAINTS.PRIMARY_KEY)
    }
    groupedResults[tableId].columns.push({
      id: `${result.tableName}.${result.colName}`,
      name: result.colName,
      type: result.colType,
      affinity: mapCommonTypesToAffinity(
        result.colType,
        result.colNotNull === 0
      ),
      table: result.tableName,
      nullable: result.colNotNull === 0,
      default: result.colDefaultValue,
      constraints,
    })
  }

  for (const tableId of Object.keys(groupedResults)) {
    const hasAPrimaryKey = groupedResults[tableId].columns.some((column) =>
      column.constraints.includes(COLUMN_CONSTRAINTS.PRIMARY_KEY)
    )
    // If there is no declared single or composite primary key, sqlite will create an automatic rowid column to use a primary key
    if (!hasAPrimaryKey && groupedResults[tableId].wr === 0) {
      const rowidColumn = {
        id: `${groupedResults[tableId].name}.rowid`,
        table: groupedResults[tableId].name,
        name: 'rowid',
        type: 'INTEGER',
        affinity: 'integer' as const,
        nullable: false,
        default: null,
        constraints: [COLUMN_CONSTRAINTS.PRIMARY_KEY],
      }
      groupedResults[tableId].columns.unshift(rowidColumn)
    }
  }

  // We group under each table the columns
  return Object.values(groupedResults)
}
