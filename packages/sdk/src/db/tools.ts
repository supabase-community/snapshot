import type { DatabaseClient } from '~/db/index.js'

import { execQueryNext, withDbClient } from './client.js'
import {
  ConnectionString,
  ConnectionStringShape,
  findWorkingDbConnString,
} from './connString/index.js'
import { fetchAuthorizedSchemas } from './introspect/queries/fetchAuthorizedSchemas.js'
import { escapeIdentifier } from './introspect/queries/utils.js'

export async function disconnectClients(
  client: DatabaseClient,
  databaseName: string
) {
  await client.query(`SELECT pg_terminate_backend(pg_stat_activity.pid)
  FROM pg_stat_activity
  WHERE pg_stat_activity.datname = '${databaseName}'
    AND pid <> pg_backend_pid();`)
}

const resetDbFromClient = async (client: DatabaseClient): Promise<string[]> => {
  const errors: string[] = []

  const schemas = await fetchAuthorizedSchemas(client)
  for (const name of schemas) {
    try {
      await client.query(`DROP SCHEMA "${name}" CASCADE`)
    } catch (error) {
      errors.push(
        `Could not drop schema "${name}", Snaplet will try to truncate all tables and related objects as a fallback: ${error}`
      )
      errors.push(...(await clearSchema(client, name)))
    }
  }

  try {
    await client.query(`CREATE SCHEMA public`)
  } catch (error) {
    errors.push(String(error))
  }
  return errors
}

export const clearDb = async (client: DatabaseClient): Promise<string[]> => {
  const errors: string[] = []

  const schemas = await fetchAuthorizedSchemas(client)
  for (const name of schemas) {
    errors.push(...(await clearSchema(client, name)))
  }

  return errors
}

export const resetDb = async (
  rawConnString: ConnectionStringShape
): Promise<string[]> => {
  const connString = new ConnectionString(rawConnString)
  const errors: string[] = []
  try {
    return await withDbClient(resetDbFromClient, {
      connString: connString.toString(),
    })
  } catch (error) {
    errors.push(String(error))
    return errors
  }
}

export const clearSchema = async (
  client: DatabaseClient,
  schemaName: string
): Promise<string[]> => {
  interface DbObject {
    kind: string
    name: string
  }

  let tables

  try {
    const { rows: results } = await client.query<DbObject>(
      `select cls.relname as name
      from pg_class cls
      join pg_namespace nsp
        on nsp.oid = cls.relnamespace
      where nsp.nspname = '${schemaName}' and cls.relkind in ('p', 'r') and cls.relispartition is false`
    )
    tables = results
  } catch (error) {
    return [String(error)]
  }

  const errors: string[] = []

  for (const obj of tables) {
    try {
      await client.query(`TRUNCATE TABLE "${schemaName}"."${obj.name}" CASCADE`)
    } catch (error) {
      errors.push(
        `Could not truncate table "${schemaName}"."${obj.name}": ${error}`
      )
    }
  }

  return errors
}

export const dbExistsNext = async (
  connString: ConnectionStringShape
): Promise<boolean> => {
  connString = new ConnectionString(connString)
  const maintenanceConnString = await findWorkingDbConnString(
    connString.toString()
  )
  const result = await execQueryNext(
    `SELECT 1 FROM pg_database WHERE datname='${connString.database}'`,
    maintenanceConnString
  )

  return result.rows.length > 0
}

const identify = (schema: string, table: string) =>
  `${escapeIdentifier(schema)}.${escapeIdentifier(table)}`

export const truncateTables = async (
  client: DatabaseClient,
  tables: Array<{ schema: string; table: string }>
): Promise<string[]> => {
  const errors: string[] = []

  const allTablesToTruncate = tables
    .map(({ schema, table }) => identify(schema, table))
    .join(', ')

  try {
    await client.query(`TRUNCATE ${allTablesToTruncate} CASCADE`)
  } catch (error) {
    errors.push(
      `Could not truncate tables ${allTablesToTruncate}: ${
        (error as Error)?.message ?? error
      }`
    )
  }

  return errors
}
