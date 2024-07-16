import type { DatabaseClient } from '../../../db/client.js'
import { buildSchemaExclusionClause } from './utils.js'

type FetchAuthorizedExtensionsResult = {
  name: string
  version: string
  schema: string
}

const FETCH_AUTHORIZED_EXTENSIONS = `
  WITH
  accessible_schemas AS (
    SELECT
      schema_name
    FROM information_schema.schemata
    WHERE
      ${buildSchemaExclusionClause('schema_name')} AND
      pg_catalog.has_schema_privilege(current_user, schema_name, 'USAGE')
  )
  SELECT
    e.extname AS "name",
    e.extversion AS "version",
    n.nspname AS "schema"
  FROM
    pg_catalog.pg_extension e
    INNER JOIN pg_catalog.pg_namespace n ON n.oid = e.extnamespace
    INNER JOIN pg_catalog.pg_description c ON c.objoid = e.oid AND c.classoid = 'pg_catalog.pg_extension'::pg_catalog.regclass
    INNER JOIN accessible_schemas s ON s.schema_name = n.nspname
  WHERE  ${buildSchemaExclusionClause('n.nspname')}
  ORDER BY schema_name
`

export async function fetchAuthorizedExtensions(client: DatabaseClient) {
  const schemas = await client.query<FetchAuthorizedExtensionsResult>({
    text: FETCH_AUTHORIZED_EXTENSIONS,
  })
  return schemas.rows
}
