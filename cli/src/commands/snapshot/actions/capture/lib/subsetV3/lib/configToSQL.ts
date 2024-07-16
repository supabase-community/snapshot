import { copycat } from '@snaplet/copycat'
import { DatabaseClient, SubsetConfig } from '@snaplet/sdk/cli'

import { Table } from './types.js'

export type ConfigToSQL = {
  where?: string
  tableSubset?: string
  limit?: string
  orderBy?: string
}

async function getPreciseCount(
  client: DatabaseClient,
  table: { schema: string; name: string }
) {
  const {
    rows: [{ count }],
  } = await client.query<{ count: number }>(
    `SELECT COUNT(*) as count FROM ${client.escapeIdentifier(
      table.schema
    )}.${client.escapeIdentifier(table.name)}`
  )

  return count
}

export async function configToSQL(
  client: DatabaseClient,
  configTarget: SubsetConfig['targets'][number],
  target: Pick<Table, 'id' | 'schema' | 'name'>
) {
  const sql: ConfigToSQL = {}
  let subsetRowCount: number | undefined
  if (configTarget.percent) {
    const count = await getPreciseCount(client, target)
    subsetRowCount = Math.round((count * configTarget.percent) / 100)
    // TODO: figure out why it's needed, I can of understand that sometimes the percentage can be less than what we expect
    // for example we have 100 rows and TABLESAMPLE BERNOULLI (10) will return 9 rows so we increase the percentage and use LIMIT to get the exact count
    const percentage = calculateSubsetSize(subsetRowCount, count)
    // A good read on table subsetting: https://www.2ndquadrant.com/en/blog/tablesubset-in-postgresql-9-5-2/
    sql.tableSubset = `TABLESAMPLE BERNOULLI (${
      // configTarget.percent
      percentage
    }) REPEATABLE(${copycat.int(target.id)})`
  } else if (configTarget.rowLimit) {
    const count = await getPreciseCount(client, target)
    subsetRowCount = Math.min(count, configTarget.rowLimit)
  }

  if (subsetRowCount) {
    sql.limit = `LIMIT ${subsetRowCount}`
  }

  if (configTarget.where) {
    sql.where = `WHERE ${configTarget.where}`
  }

  if (configTarget.orderBy) {
    sql.orderBy = `ORDER BY ${configTarget.orderBy}`
  }

  return sql
}

function calculateSubsetSize(
  subsetRowCount: number,
  totalRowCount: number
): number {
  // Protect against divide 0 NaN result on empty table
  if (totalRowCount > 0) {
    // Subset from table double the size of the subset
    const percentageDoubled =
      Math.ceil(subsetRowCount / totalRowCount) * 100 * 2

    if (percentageDoubled > 100) {
      return 100
    } else {
      return percentageDoubled
    }
  } else {
    return 0
  }
}
