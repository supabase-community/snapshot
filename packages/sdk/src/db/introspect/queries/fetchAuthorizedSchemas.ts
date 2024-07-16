import type { DatabaseClient } from '../../../db/client.js'
import { buildSchemaExclusionClause } from './utils.js'

type FetchAuthorizedSchemasResult = {
  schemaName: string
}
const FETCH_AUTHORIZED_SCHEMAS = `
  SELECT
    schema_name as "schemaName"
  FROM
    information_schema.schemata
  WHERE
    ${buildSchemaExclusionClause('schema_name')} AND
    pg_catalog.has_schema_privilege(current_user, schema_name, 'USAGE')
  ORDER BY schema_name
`
export async function fetchAuthorizedSchemas(client: DatabaseClient) {
  const schemas = await client.query<FetchAuthorizedSchemasResult>({
    text: FETCH_AUTHORIZED_SCHEMAS,
  })
  return schemas.rows.map((r) => r.schemaName)
}
