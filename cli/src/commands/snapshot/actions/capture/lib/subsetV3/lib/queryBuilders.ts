import { escapeIdentifier } from '@snaplet/sdk/cli'

import type { ConfigToSQL } from './configToSQL.js'
import type { SubsettingTable, Table } from './types'

export type JoinParams = {
  fromColumns: string[]
  fromTable: Pick<
    SubsettingTable,
    'id' | 'primaryKeys' | 'name' | 'schema' | 'partitioned'
  >
  toColumns: string[]
  toTable: Pick<
    SubsettingTable,
    'id' | 'primaryKeys' | 'name' | 'schema' | 'partitioned'
  >
}

function escapeTableIdentifier(table: Pick<Table, 'name' | 'schema'>) {
  return `${escapeIdentifier(table.schema)}.${escapeIdentifier(table.name)}`
}

// List of columns type who won't take too much space and can be use as pk fallback
const INVALID_PK_COLUMNS = new Set(['json', 'jsonb', 'bytea'])
// When no primary keys are defined we use the compositions of the table columns
// to create a composite primary key
export function columnsToPrimaryKeys(
  columns: Table['columns']
): NonNullable<Table['primaryKeys']> {
  return {
    schema: columns[0].schema,
    table: columns[0].table,
    tableId: `${columns[0].schema}.${columns[0].table}`,
    dirty: true,
    keys: columns
      .filter((c) => INVALID_PK_COLUMNS.has(c.type) === false)
      .map((c) => ({ name: c.name, type: c.type })),
  }
}

/**
 * To handle composite PK/FK we rely on postgresql tabloid and ctid
 * which is the internal id of a row.
 */
function getUniqueId(
  table: Pick<SubsettingTable, 'partitioned' | 'name'>,
  options?: {
    tableAlias?: string
    whereClause?: boolean
  }
) {
  const tableIdentifier = options?.tableAlias ?? escapeIdentifier(table.name)

  // TODO: handle partionned tables in a better way at "storage" level
  // This way of doing the query is not performant when a partitionned table is involved
  // because it can't leverage ctid indexing causing a seq scan which can be very slow
  // if there is a large number of ctids to look for
  if (table.partitioned) {
    return [
      `(${tableIdentifier}.tableoid::text || ${tableIdentifier}.ctid::text)`,
      ...(options?.whereClause ? [] : ['as ctid']),
    ].join(' ')
  }

  return `${tableIdentifier}.ctid`
}

function getAnyParamsClause(table: Pick<SubsettingTable, 'partitioned'>) {
  if (table.partitioned) {
    // In case of partitionned tables, we merge `tableoid` and `ctid` into a string
    return `$1::text[]`
  }
  return `$1::tid[]`
}

export function buildConfiguredFetchQuery(
  table: Pick<
    SubsettingTable,
    'primaryKeys' | 'name' | 'schema' | 'partitioned'
  >,
  configSql: ConfigToSQL
) {
  const columnsToSelectClause = table.primaryKeys.keys
    .map(
      (k) => `${escapeIdentifier(table.name)}.${escapeIdentifier(k.name)}::text`
    )
    .join(', ')

  const query = [
    `SELECT ${getUniqueId(table)}, ${columnsToSelectClause}`,
    `FROM ${escapeTableIdentifier(table)}`,
    ...(configSql.tableSubset ? [configSql.tableSubset] : []),
    ...(configSql.where ? [configSql.where] : []),
    ...(configSql.orderBy ? [configSql.orderBy] : []),
    ...(configSql.limit ? [configSql.limit] : []),
  ].join('\n')
  return query
}

export function buildReferencesFetchQuery(
  joinParameters: JoinParams,
  limit?: number
) {
  const targetExpr = joinParameters.fromColumns
    .map((f) => `target.${escapeIdentifier(f)}`)
    .join(', ')
  const parentExpr = joinParameters.toColumns
    .map((f) => `parent.${escapeIdentifier(f)}`)
    .join(', ')
  const columnsToSelectClause = joinParameters.toTable.primaryKeys.keys
    .map((k) => `parent.${escapeIdentifier(k.name)}::text`)
    .join(', ')
  const comparator = joinParameters.toTable.primaryKeys.dirty
    ? // If the primary keys are coming from our fallback on all the columns, then some columns might be null
      // In that case, we want to use the 'IS NOT DISTINCT FROM' instead of '=' operator as it allow to compare null as values
      // For example a relation like so:
      // db.entrypoint(id: TEXT, value: TEXT) = ('a', NULL), (NULL, 'b'), (NULL, NULL)
      // db.relation(entrypoint_id: TEXT REFERENCE entrypoint(id)) = ('a'), (NULL)
      // such data when retrieved with the '=' operator would result in: only ('a') being retrieved where we want ('a'), (NULL, 'b') and (NULL, NULL) to be retrieved
      'IS NOT DISTINCT FROM'
    : '='
  const limitSql = limit !== undefined ? `LIMIT ${limit}` : ''
  const query = `
    SELECT
      ${getUniqueId(joinParameters.toTable, {
        tableAlias: 'parent',
      })}, ${columnsToSelectClause}
    FROM ${escapeTableIdentifier(joinParameters.fromTable)} AS target
    JOIN ${escapeTableIdentifier(joinParameters.toTable)} AS parent
      ON (${parentExpr}) ${comparator} (${targetExpr})
    WHERE ${getUniqueId(joinParameters.fromTable, {
      tableAlias: 'target',
      whereClause: true,
    })} = ANY(${getAnyParamsClause(joinParameters.fromTable)})
    ORDER BY 1
    ${limitSql};
  `
  return query
}
