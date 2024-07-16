/**
 * context(peterp, 4th Feb 2022): A sequence in PostgresQL is a value
 * that's inserted into a column when a new row is inserted,
 * the value is incremented from the previous value.
 *
 * When we bulk-insert data via Snaplet the sequences are no longer accuerate,
 * so we need to reset them.
 *
 * Tutorial: https://www.postgresqltutorial.com/postgresql-sequences/
 * Fixing sequences: https://til.codes/dont-forget-to-update-the-sequence-in-postgresql-after-a-copy-command/
 */
import type { AsyncFunctionSuccessType } from '~/types'

import { xdebug } from '../../x/xdebug.js'
import { execQueryNext } from '../client.js'
import { ConnectionStringShape } from '../connString/index.js'
import { fetchAuthorizedSequences } from './queries/fetchAuthorizedSequences.js'

const xd = xdebug.extend('restore').extend('sequences')

type Sequence = AsyncFunctionSuccessType<
  typeof fetchAuthorizedSequences
>[number]

export async function fixSequences(
  connString: ConnectionStringShape,
  sequences: Sequence[]
) {
  const batchSize = 10

  // Split the sequences into smaller groups
  const sequenceBatches: Sequence[][] = []
  for (let i = 0; i < sequences.length; i += batchSize) {
    sequenceBatches.push(sequences.slice(i, i + batchSize))
  }

  // Update each group with a single query in parallel
  await Promise.all(
    sequenceBatches.map(async (sequenceBatch) => {
      const sequenceQueries = sequenceBatch.map(
        ({ schema, table, column }) => `
          SELECT setval(
            pg_get_serial_sequence('${schema}."${table}"', '${column}'),
            COALESCE(MAX(${column}), 0) + 1,
            FALSE
          )
          FROM "${schema}"."${table}"
        `
      )

      const combinedStatement = sequenceQueries.join(' UNION ALL ')

      xd('Updating sequence batch: "%s"', combinedStatement)
      await execQueryNext(combinedStatement, connString)
    })
  )
}
