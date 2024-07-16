import type { DatabaseClient } from '../../../db/client.js'
import { buildSchemaExclusionClause } from './utils.js'

type FetchIndexesResult = {
  schema: string
  table: string
  index: string
  definition: string
  type: string
  indexColumns: string[]
}

const FETCH_INDEXES = `
  SELECT n.nspname AS schema,
    tab.relname AS table,
    cls.relname AS index,
    pg_get_indexdef(idx.indexrelid) AS definition,
    am.amname AS type,
    json_agg(attname ORDER BY attname) AS "indexColumns"
  FROM pg_index idx
  JOIN pg_class cls ON cls.oid=idx.indexrelid
  JOIN pg_class tab ON tab.oid=idx.indrelid
  JOIN pg_am am ON am.oid=cls.relam
  JOIN pg_catalog.pg_namespace n ON n.oid = cls.relnamespace
  JOIN pg_attribute ON attrelid = idx.indrelid
  WHERE ${buildSchemaExclusionClause('n.nspname')}
  AND attnum = ANY(idx.indkey)
  GROUP BY n.nspname, tab.relname, cls.relname, idx.indexrelid, am.amname
  ORDER BY n.nspname
`
export async function fetchIndexes(client: DatabaseClient) {
  const schemas = await client.query<FetchIndexesResult>({
    text: FETCH_INDEXES,
  })
  return schemas.rows
}
