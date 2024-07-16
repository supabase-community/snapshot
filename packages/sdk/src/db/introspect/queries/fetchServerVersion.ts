import type { DatabaseClient } from '../../../db/client.js'

type FetchServerVersionResult = {
  server_version: string
}

const FETCH_SERVER_VERSION = `SHOW server_version`

export async function fetchServerVersion(client: DatabaseClient) {
  const schemas = await client.query<FetchServerVersionResult>({
    text: FETCH_SERVER_VERSION,
  })
  return schemas.rows[0].server_version
}
