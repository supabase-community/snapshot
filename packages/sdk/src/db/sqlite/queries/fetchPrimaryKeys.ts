import { queryNext, type SqliteClient } from '../client.js'
import {
  FETCH_TABLE_COLUMNS_LIST,
  FetchTableAndColumnsResultRaw,
  mapCommonTypesToAffinity,
  SQLiteAffinity,
} from './fetchTablesAndColumns.js'

type FetchPrimaryKeysResult = {
  tableId: string
  table: string
  // Simple boolean who'll allows us to always know if the primary keys we are using
  // are the one retrieved from the database or the one we fallback on
  dirty: boolean
  keys: Array<{ name: string; type: string; affinity: SQLiteAffinity }>
}

type FetchCompositePrimaryKeysResultRaw = {
  tableName: string
  idxOrigin: 'pk'
  idxName: string
  idxPartial: 0 | 1
  idxColName: string
}

// Fetch all unique constraints defined as indexes
const FETCH_PRIMARY_COMPOSITE_PRIMARY_KEYS = `
SELECT
  alltables.name AS tableName,
  indexlist.origin AS idxOrigin,
  indexlist.name AS idxName,
  indexlist.partial as idxPartial,
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

// Fetch all primary keys constraints
const FETCH_PRIMARY_KEYS_CONSTRAINTS = `
SELECT
  	alltables.name AS tableName,
	  colinfo.name AS colName,
    colinfo.type AS colType,
    colinfo."notnull" AS colNotNull
	FROM
	  sqlite_master AS alltables,
	  pragma_table_info(alltables.name) AS colinfo
	WHERE
	  alltables.type = 'table' AND alltables.name NOT LIKE 'sqlite_%'
	  AND colinfo.pk = 1
	ORDER BY
		alltables.name, colinfo.name
`

export async function fetchPrimaryKeys(
  client: SqliteClient
): Promise<FetchPrimaryKeysResult[]> {
  const results: FetchPrimaryKeysResult[] = []
  const compositePrimaryKeysIndexes =
    await queryNext<FetchCompositePrimaryKeysResultRaw>(
      FETCH_PRIMARY_COMPOSITE_PRIMARY_KEYS,
      { client }
    )
  const tableColumnsInfos = await queryNext<FetchTableAndColumnsResultRaw>(
    FETCH_TABLE_COLUMNS_LIST,
    { client }
  )
  const primaryKeysResponse = await queryNext<{
    tableName: string
    colName: string
    colType: string
    colNotNull: 0 | 1
  }>(FETCH_PRIMARY_KEYS_CONSTRAINTS, { client })
  const groupedTableColumnsInfos = tableColumnsInfos.reduce(
    (acc, row) => {
      if (!acc[row.tableId]) {
        acc[row.tableId] = []
      }
      acc[row.tableId].push({
        ...row,
        affinity: mapCommonTypesToAffinity(row.colType, row.colNotNull === 0),
      })
      return acc
    },
    {} as Record<
      string,
      (FetchTableAndColumnsResultRaw & { affinity: SQLiteAffinity })[]
    >
  )
  const groupedCompositePrimaryKeys = compositePrimaryKeysIndexes.reduce(
    (acc, result) => {
      if (!acc[result.tableName]) {
        acc[result.tableName] = []
      }
      acc[result.tableName].push(result)
      return acc
    },
    {} as Record<string, FetchCompositePrimaryKeysResultRaw[]>
  )
  const groupedPrimaryKeys = primaryKeysResponse.reduce(
    (acc, result) => {
      if (!acc[result.tableName]) {
        acc[result.tableName] = {
          tableName: result.tableName,
          colName: result.colName,
          colType: result.colType,
          affinity: mapCommonTypesToAffinity(
            result.colType,
            result.colNotNull === 0
          ),
        }
      }
      return acc
    },
    {} as Record<
      string,
      {
        tableName: string
        colName: string
        colType: string
        affinity: SQLiteAffinity
      }
    >
  )
  for (const tableName in groupedTableColumnsInfos) {
    const tableColumns = groupedTableColumnsInfos[tableName]
    if (groupedCompositePrimaryKeys[tableName]) {
      const compositePkColumns = groupedCompositePrimaryKeys[tableName]
      results.push({
        tableId: tableName,
        table: tableName,
        dirty: false,
        keys: compositePkColumns.map((column) => {
          const columnInfos = tableColumns.find(
            (c) => c.colName === column.idxColName
          )
          return {
            name: column.idxColName,
            type: columnInfos?.colType || 'INTEGER',
            affinity: columnInfos?.affinity || 'integer',
          }
        }),
      })
      // If the table has a primary key, we use it
    } else if (groupedPrimaryKeys[tableName]) {
      const primaryKey = groupedPrimaryKeys[tableName]
      results.push({
        tableId: tableName,
        table: tableName,
        dirty: false,
        keys: [
          {
            name: primaryKey.colName,
            type: primaryKey.colType,
            affinity: primaryKey.affinity,
          },
        ],
      })
      // Otherwise if the table has no primary key, we fallback on the rowid
    } else {
      results.push({
        tableId: tableName,
        table: tableName,
        dirty: false,
        keys: [
          {
            name: 'rowid',
            type: 'INTEGER',
            affinity: 'integer',
          },
        ],
      })
    }
  }
  return results
}
