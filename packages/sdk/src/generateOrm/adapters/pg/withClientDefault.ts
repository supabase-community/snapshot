import { Client } from 'pg'
import { type WithClient } from './pg.js'
import { getProjectConfigAsync } from '~/config/projectConfig/projectConfig.js'

export const withClientDefault: WithClient = async (fn) => {
  const connectionString = (await getProjectConfigAsync()).targetDatabaseUrl
  const client = new Client({ connectionString })
  await client.connect()

  try {
    await fn(client)
  } finally {
    await client.end()
  }
}
