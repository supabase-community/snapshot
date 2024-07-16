import { queryNext, type SqliteClient } from '../client.js'

type FetchServerVersionResult = {
  version: string
}

const FETCH_VERSION = `
SELECT
  sqlite_version() as version
`

export async function fetchServerVersion(client: SqliteClient) {
  const results = await queryNext<FetchServerVersionResult>(FETCH_VERSION, {
    client,
  })
  return results[0].version
}
