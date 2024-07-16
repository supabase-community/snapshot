import { queryNext, type SqliteClient } from '../client.js'
import {
  FETCH_TABLE_COLUMNS_LIST,
  FetchTableAndColumnsResultRaw,
  mapCommonTypesToAffinity,
  SQLiteAffinity,
} from './fetchTablesAndColumns.js'

type RelationKeyInfos = {
  fkColumn: string
  fkType: string
  fkAffinity: SQLiteAffinity
  targetColumn: string
  targetType: string
  targetAffinity: SQLiteAffinity
  nullable: boolean
}
type FetchRelationshipsInfosResult = {
  id: string
  fkTable: string
  targetTable: string
  keys: RelationKeyInfos[]
}

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

export const fetchDatabaseRelationships = async (client: SqliteClient) => {
  const results: FetchRelationshipsInfosResult[] = []
  const foreignKeysResult = await queryNext<FetchTableForeignKeysResultRaw>(
    FETCH_TABLE_FOREIGN_KEYS,
    { client }
  )
  const tableColumnsInfos = await queryNext<FetchTableAndColumnsResultRaw>(
    FETCH_TABLE_COLUMNS_LIST,
    { client }
  )
  const tableColumnsInfosGrouped = tableColumnsInfos.reduce(
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
  const groupedByTableResults = foreignKeysResult.reduce(
    (acc, row) => {
      if (!acc[row.tableId]) {
        acc[row.tableId] = []
      }
      acc[row.tableId].push(row)
      return acc
    },
    {} as Record<string, FetchTableForeignKeysResultRaw[]>
  )
  for (const tableId in groupedByTableResults) {
    const tableForeignKeys = groupedByTableResults[tableId]
    const groupedByFkId = tableForeignKeys.reduce(
      (acc, row) => {
        if (!acc[`${row.fkId}`]) {
          acc[`${row.fkId}`] = {
            id: `${row.fkId}`,
            fkTable: row.tableName,
            targetTable: row.fkToTable,
            keys: [],
          }
        }
        const columnInfosToTable = tableColumnsInfosGrouped[row.fkToTable]
        const columnInfosFromTable = tableColumnsInfosGrouped[row.tableName]
        const fkToColumnInfos = columnInfosToTable.find(
          (c) => c.colName === row.fkToColumn
        )
        const fkFromColumnInfos = columnInfosFromTable.find(
          (c) => c.colName === row.fkFromColumn
        )

        acc[`${row.fkId}`].keys.push({
          fkColumn: row.fkFromColumn,
          fkType: fkFromColumnInfos!.colType,
          fkAffinity: fkFromColumnInfos!.affinity,
          targetColumn: row.fkToColumn,
          targetType: fkToColumnInfos!.colType,
          targetAffinity: fkToColumnInfos!.affinity,
          nullable: fkFromColumnInfos!.colNotNull === 0,
        })
        return acc
      },
      {} as Record<string, FetchRelationshipsInfosResult>
    )
    for (const fkId in groupedByFkId) {
      const foreignKeyInfos = groupedByFkId[fkId]
      results.push({
        id: `${foreignKeyInfos.fkTable}_${foreignKeyInfos.keys.map((k) => k.fkColumn).join('_')}_fkey`,
        fkTable: foreignKeyInfos.fkTable,
        targetTable: foreignKeyInfos.targetTable,
        keys: foreignKeyInfos.keys,
      })
    }
  }

  return results
}
