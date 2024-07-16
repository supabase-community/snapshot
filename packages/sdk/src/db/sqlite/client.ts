import DatabaseConstructor, { Database } from 'better-sqlite3'
import { Json } from '~/types.js'

export type SqliteClient = Database

async function getDbClient(connString: string, readOnly = false) {
  const db = new DatabaseConstructor(connString, { readonly: readOnly })
  return db
}

type ExclusiveConnectionOptions =
  | { client: SqliteClient; connString?: never }
  | { client?: never; connString: string }

export async function withDbClient<Result>(
  fn: (client: SqliteClient) => Result,
  options: ExclusiveConnectionOptions
): Promise<Result> {
  const client = options.client
    ? options.client
    : await getDbClient(options.connString)
  const result = await fn(client)
  return result
}

export async function execQueryNext(
  query: string | ((db: SqliteClient) => Promise<void>),
  connectionString: string
): Promise<void> {
  const client = await getDbClient(connectionString, false)
  typeof query !== 'function' ? await client.exec(query) : await query(client)
}

export async function queryNext<Result extends Json>(
  query: string | ((db: SqliteClient) => Promise<Array<Result>>),
  options: ExclusiveConnectionOptions
): Promise<Array<Result>> {
  const client = options.client
    ? options.client
    : await getDbClient(options.connString, true)
  const result =
    typeof query !== 'function'
      ? ((await client.prepare(query).all()) as Array<Result>)
      : await query(client)
  return result
}
