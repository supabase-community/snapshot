import type { DatabaseClient } from '../../../db/client.js'
import { buildSchemaExclusionClause } from './utils.js'

type FetchAuthorizedEnumsResult = {
  id: string
  schema: string
  name: string
  values: string[]
}

const FETCH_AUTHORIZED_ENUMS = `
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
    pg_namespace.nspname AS schema,
    pg_type.typname AS name,
    concat(pg_namespace.nspname, '.', pg_type.typname) AS id,
    json_agg(pg_enum.enumlabel ORDER BY pg_enum.enumlabel) AS values
  FROM pg_type
  INNER JOIN pg_enum ON pg_enum.enumtypid = pg_type.oid
  INNER JOIN pg_namespace ON pg_namespace.oid = pg_type.typnamespace
  INNER JOIN accessible_schemas s ON s.schema_name = pg_namespace.nspname
  WHERE ${buildSchemaExclusionClause('pg_namespace.nspname')}
  GROUP BY pg_namespace.nspname, pg_type.typname
  ORDER BY concat(pg_namespace.nspname, '.', pg_type.typname)
`

export async function fetchAuthorizedEnums(client: DatabaseClient) {
  const schemas = await client.query<FetchAuthorizedEnumsResult>({
    text: FETCH_AUTHORIZED_ENUMS,
  })

  return schemas.rows
}
