import { isUndefined } from 'lodash'

import { ConnectionString } from './ConnectionString.js'
import { getDbClient } from '../client.js'

/**
 * The user supplies a connection string to a database that may not exist,
 * we attempt to find a working connection via a list of known fallback databases.
 */
export async function findWorkingDbConnString(
  connString: string,
  fallbackDbPaths = ['postgres', 'template1']
) {
  const databaseName = new ConnectionString(connString).database

  const databases = new Set(
    [databaseName, ...fallbackDbPaths].filter(
      (x) => !isUndefined(x)
    ) as string[]
  )

  const errorMessages = []
  for (const database of databases) {
    let client = undefined
    try {
      const newConnString = new ConnectionString(connString)
        .setDatabase(database)
        .toString()

      client = await getDbClient(newConnString)
      return newConnString
    } catch (e: any) {
      errorMessages.push(
        `Attempt #${errorMessages.length + 1}: ${
          e.message
        }, tried database "${database}"`
      )
    } finally {
      await client?.release()
    }
  }
  const error = new Error('Could not validate database credentials.')
  error.name = 'DB_CONNECTION_AUTH'
  // @ts-expect-error
  error['errors'] = errorMessages
  throw error
}
