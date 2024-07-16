import type { DatabaseClient } from '../../../db/client.js'
import { buildSchemaExclusionClause } from './utils.js'

type FetchForbiddenSchemasResult = {
  schemaName: string
}

const FETCH_FORBIDDEN_SCHEMAS = `
  SELECT nspname AS "schemaName"
    FROM pg_catalog.pg_namespace
  WHERE
    ${buildSchemaExclusionClause('nspname')} AND
    NOT pg_catalog.has_schema_privilege(current_user, nspname, 'USAGE')
  ORDER BY nspname
`
export async function fetchForbiddenSchemas(client: DatabaseClient) {
  const schemas = await client.query<FetchForbiddenSchemasResult>({
    text: FETCH_FORBIDDEN_SCHEMAS,
  })
  return schemas.rows.map((r) => r.schemaName)
}
