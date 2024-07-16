import {
  DatabaseClient,
  escapeIdentifier,
  escapeLiteral,
} from '@snaplet/sdk/cli'
import pgCopy from 'pg-copy-streams'
import { Readable } from 'stream'
import { Table, SubsettingTable } from '../lib/types.js'
import { SubsettingStorage } from '../storage/types.js'

// When we use the "followNullableRelation: true" or when we extract from database with
// nullable columns, at some point to do the comparaison using the `= ANY(VALUES)` syntax
// we need everything to be casted to the same text type, and NON NULL.
// This random string is there to ensure the COALESCE of string columns into text will
// not conflict with actual user data.
// NOTE: this is not full proof and there is still a slight chance of conflict but since we have moving parts changing at each
// runtime, even if the is a conflict, next time it's ran, the conflict should be gone. And in terms of tradeoff between complexity
// and corner-case handling, this is a reasonable solution. Also performance-wise the COALESCE/DEFAULT_STRING_CAST method add no overhead
// to the query execution time in the opposite of some other alteratives like LATERAL JOIN.
const NULL_TO_STRING_CAST = escapeLiteral(
  `NULL_9Xr8pPc5zAaKlN0oR3yT1gVb6Hs7qQe2uWm8jDf4hE3iSw5xBv6Cc1kY7lZ8oGn9pUt0_${Date.now()}${(
    Math.random() * 10000
  ).toFixed(0)}`
)

export type SubsetOptions = {
  storage: SubsettingStorage
  rowsToCopy: number
  // When you use the "followNullableRelation: false" we need to nullate the columns
  // to avoid foreign key constraint errors
  columnsToNullate: Set<string>
}

// Take our list of columns name and ensure it's properly escaped
function generateColumnsSelector(
  columns: Array<Pick<Table['columns'][number], 'name'>>
) {
  return columns.map((c) => `${escapeIdentifier(c.name)}`)
}

function isCopyable(column: Pick<Table['columns'][number], 'generated'>) {
  // You cannot COPY a genereated columns as it depends from other columns
  return column.generated !== 'ALWAYS'
}

// Take our list of columns name and ensure it's properly escaped
// casted into text and coalesced to avoid null values for the comparison
function generatePrimaryKeysSelector(
  columns: Array<Pick<Table['columns'][number], 'name' | 'nullable'>>
) {
  return columns.map((c) =>
    c.nullable
      ? // COALESCE will cause the query planned to use sequential scan instead of index scan
        // This should only be used when the table had no primary keys and we fallback on a custom mad one
        `COALESCE(${escapeIdentifier(c.name)}::text, ${NULL_TO_STRING_CAST})`
      : `${escapeIdentifier(c.name)}::text`
  )
}

function selectHeadersOnlyQuery(
  table: Pick<Table, 'columns' | 'name' | 'schema'>
): string {
  const columnNamesSelector = generateColumnsSelector(
    table.columns.filter(isCopyable)
  ).join(', ')
  return `SELECT ${columnNamesSelector} FROM ${escapeIdentifier(
    table.schema
  )}.${escapeIdentifier(table.name)} WHERE 1 = 0`
}

function generatePlaceholders(values: Array<Array<string | null>>) {
  return values.reduce((acc, row, rowIndex) => {
    const rowPlaceholders = row.reduce(
      (rowAcc, value, colIndex) =>
        `${rowAcc}${colIndex > 0 ? ', ' : ''}${
          // if the value is null, then we use our default string cast
          value === null ? NULL_TO_STRING_CAST : escapeLiteral(value)
        }`,
      ''
    )
    return `${acc}${rowIndex > 0 ? ', ' : ''}(${rowPlaceholders})`
  }, '')
}

function selectRowsQuery(
  table: Pick<SubsettingTable, 'columns' | 'name' | 'schema' | 'primaryKeys'>,
  values: Array<Array<string | null>>
): string {
  const columnsListSelector = generateColumnsSelector(
    table.columns.filter(isCopyable)
  ).join(', ')
  const tablePrimaryKeys = table.primaryKeys.keys.map((pk) => ({
    ...pk,
    nullable: table.primaryKeys.dirty
      ? // If the primary keys are coming from our fallback on all the columns, then some columns might be nullable
        table.columns.find((c) => c.name === pk.name && c.type === pk.type)!
          .nullable
      : // Otherwise if it's coming from our introspection, then we know it's not nullable
        false,
  }))
  // Since all our values has been casted to string, all the primary keys
  // must be casted to ::text as well to allow postgres to compare them
  const primaryKeysListSelector = generatePrimaryKeysSelector(
    // At this point, the primaryKeys will always exist because we already replaced
    // tables with no primary keys by a table with all the columns as a composite keys
    // this is suboptimal but it's the best we can do to still fetch the right data
    tablePrimaryKeys
  ).join(',')
  const placeholders = generatePlaceholders(values)
  // We use ANY(VALUES) to avoid the 65535 limit of the IN operator
  // and also to avoid the stack overflow error that can happen when
  // using the IN operator with a large number of values since IN operator
  // will generate a large number of OR conditions in the WHERE clause or
  // will allocate a large array in the stack.
  // Where the ANY(VALUES) will create a temporary table and perform a join
  // working onto memory instead of the stack.
  return `SELECT ${columnsListSelector}
  FROM ${escapeIdentifier(table.schema)}.${escapeIdentifier(table.name)}
  WHERE (${primaryKeysListSelector}) = ANY(VALUES ${placeholders})`
}

// Will copy the entire table
export const queryTableStream = (
  client: DatabaseClient,
  table: Pick<Table, 'columns' | 'name' | 'schema'>
): Readable => {
  const columnsListSelector = generateColumnsSelector(
    table.columns.filter(isCopyable)
  ).join(', ')
  const query = `COPY (SELECT ${columnsListSelector} FROM ${escapeIdentifier(
    table.schema
  )}.${escapeIdentifier(table.name)}) TO STDOUT CSV HEADER`
  return client.query(pgCopy.to(query))
}

// Will copy a subset of the table
export const querySubsetStream = (
  client: DatabaseClient,
  table: Pick<
    SubsettingTable,
    'id' | 'columns' | 'name' | 'schema' | 'primaryKeys'
  >,
  subsetOptions: SubsetOptions,
  limitOffset: { limit: number; offset: number }
): Readable => {
  const values = subsetOptions.storage.getIds(table.id, limitOffset)

  if (values.length > 0) {
    const query = selectRowsQuery(table, values)
    // Copy the tables selected from the subsetting
    return client.query(
      pgCopy.to(`
      COPY (
        ${query}
      ) TO STDOUT CSV HEADER
    `)
    )
  }
  // Copy only the headers of the table
  return client.query(
    pgCopy.to(`COPY ( ${selectHeadersOnlyQuery(table)} ) TO STDOUT CSV HEADER`)
  )
}
