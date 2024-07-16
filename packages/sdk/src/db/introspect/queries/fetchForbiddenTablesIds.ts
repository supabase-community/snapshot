import type { DatabaseClient } from '../../../db/client.js'
import { buildSchemaExclusionClause } from './utils.js'

type FetchFobiddenTablesIds = {
  id: string
}

const FETCH_FORBIDDEN_TABLES_IDS = `
  SELECT
    concat(n.nspname, '.', c.relname) AS id
  FROM pg_class c
  INNER JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE
    -- table objects
    c.relkind IN ('p', 'r') AND c.relispartition IS FALSE AND
    -- Exclude all system tables
    ${buildSchemaExclusionClause('n.nspname')} AND
    (
      NOT pg_catalog.has_schema_privilege(current_user, n.nspname, 'USAGE') OR
      NOT pg_catalog.has_table_privilege(current_user, concat(quote_ident(n.nspname), '.', quote_ident(c.relname)), 'SELECT')
    )
  ORDER BY n.nspname, c.relname
`

export async function fetchForbiddenTablesIds(client: DatabaseClient) {
  const results = await client.query<FetchFobiddenTablesIds>(
    FETCH_FORBIDDEN_TABLES_IDS
  )
  return results.rows.map((r) => r.id)
}
