import { SqliteClient, queryNext } from '../client.js'
import {
  FETCH_TABLE_COLUMNS_LIST,
  FetchTableAndColumnsResultRaw,
  mapCommonTypesToAffinity,
  SQLiteAffinity,
} from './fetchTablesAndColumns.js'

type FetchSequencesResult = {
  tableId: string
  colId: string
  name: string
  start: number
  min: number
  max: number
  current: number
  interval: number
}

export async function fetchSequences(client: SqliteClient) {
  const results: Array<FetchSequencesResult> = []
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
  for (const tableId in tableColumnsInfosGrouped) {
    const tableColumns = tableColumnsInfosGrouped[tableId]
    const tablePk = tableColumns.find((column) => column.colPk)
    // The table must have an autoincrement pk column or will have an implicit rowid column
    // used as a sequence
    const pkKey =
      tablePk && tablePk.affinity === 'integer' ? tablePk.colName : 'rowid'
    const maxSeqNo = await queryNext<{ currentSequenceValue: number }>(
      `
      SELECT MAX(${pkKey}) + 1 as currentSequenceValue FROM ${tableId}
    `,
      { client }
    )
    results.push({
      colId: pkKey,
      tableId,
      name: `${tableId}_${pkKey}_seq`,
      start: 1,
      min: 1,
      current: maxSeqNo[0].currentSequenceValue || 1,
      max: 2147483647,
      interval: 1,
    })
  }
  return results
}
