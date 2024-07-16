import type { DatabaseClient } from '../../../db/client.js'
import { buildSchemaExclusionClause } from './utils.js'

type FetchSequencesResult = {
  schema: string
  name: string
  start: number
  min: number
  max: number
  current: number
  interval: number
}

const FETCH_SEQUENCES = `
SELECT
  schemaname AS schema,
  sequencename AS name,
  start_value AS start,
  min_value AS min,
  max_value AS max,
  COALESCE(last_value, start_value) AS current,
  increment_by AS interval
FROM
 pg_sequences
WHERE ${buildSchemaExclusionClause('pg_sequences.schemaname')}
`

export async function fetchSequences(client: DatabaseClient) {
  const sequences = await client.query<FetchSequencesResult>({
    text: FETCH_SEQUENCES,
  })

  return sequences.rows.map((r) => ({
    ...r,
    start: Number(r.start),
    min: Number(r.min),
    max: Number(r.max),
    // When a sequence is created, the current value is the start value and is available for use
    // but when the sequence is used for the first time, the current values is the last used one not available for use
    // so we increment it by one to get the next available value instead
    current: r.start === r.current ? Number(r.current) : Number(r.current) + 1,
    interval: Number(r.interval),
  }))
}
