import { ConnectionString, execQueryNext, endAllPools } from '@snaplet/sdk/cli'
import { v4 } from 'uuid'

import { afterDebug } from './debug.js'

interface State {
  dbNames: Array<string>
}

export const defineCreateTestDb = (state: State) => {
  const databaseUrl = process.env.DATABASE_URL
  if (!databaseUrl) {
    throw new Error(
      'Could not determine connections string from configuration.'
    )
  }
  const connString = new ConnectionString(databaseUrl)

  const createTestDb = async (
    structure?: string
  ): Promise<ConnectionString> => {
    const dbName = 'testdb' + v4()
    await execQueryNext(`DROP DATABASE IF EXISTS "${dbName}"`, connString)
    await execQueryNext(`CREATE DATABASE "${dbName}"`, connString)

    state.dbNames.push(dbName)
    const newConnString = connString.setDatabase(dbName)
    if (structure) {
      await execQueryNext(structure, newConnString)
    }
    return newConnString
  }

  createTestDb.afterEach = async () => {
    const dbNames = state.dbNames
    state.dbNames = []

    const failures: { dbName: string; error: Error }[] = []
    afterDebug(`createTestDb afterEach cleanup: ${dbNames.length}`)

    // Close all pools connections on the database, if there is more than one to be able to drop it
    await endAllPools()

    for (const dbName of dbNames) {
      try {
        // During tests, calls to function creating connections using global POOL_CACHE variables (like execQueryNext)
        // Might end up not being properly terminated by `endAllPools` due to jest modules and globals mocking
        // WITH (force) ensure the remaining connections are forcefully dropped if necessary before dropping the database itself
        await execQueryNext(
          `DROP DATABASE IF EXISTS "${dbName}" WITH (force)`,
          connString
        )
      } catch (error) {
        failures.push({ dbName, error: error as Error })
      }
    }
    // Remove the last remaining connection from the database
    await endAllPools()

    if (failures.length) {
      throw new Error(
        [
          'Failed to delete all dbNames, note that these will need to be manually cleaned up:',
          JSON.stringify(failures, null, 2),
        ].join('\n')
      )
    }
  }

  return createTestDb
}

export const populateTestDb = async (connString: string) => {
  await execQueryNext(
    `CREATE TABLE "Tmp" (
       count int
    )`,
    connString
  )

  await execQueryNext(
    `INSERT INTO "Tmp" VALUES (
      42
    )`,
    connString
  )
}

export const createTestDb = defineCreateTestDb({ dbNames: [] })

afterEach(createTestDb.afterEach)
