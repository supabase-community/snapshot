import { execQueryNext } from '../db/client.js'
import { ConnectionString } from '../db/connString/ConnectionString.js'
import { v4 } from 'uuid'

import { afterDebug } from './debug.js'

interface State {
  roleNames: string[]
}

const defineCreateTestRole = (state: State) => {
  const databaseUrl = process.env.DATABASE_URL
  if (!databaseUrl) {
    throw new Error(
      'Could not determine connections string from configuration.'
    )
  }
  const connString = new ConnectionString(databaseUrl)

  const createTestRole = async (
    connString: ConnectionString
  ): Promise<ConnectionString> => {
    const roleName = `testrole-${v4()}`

    await execQueryNext(
      `CREATE ROLE "${roleName}" WITH LOGIN PASSWORD 'password'`,
      connString
    )
    state.roleNames.push(roleName)

    return connString.setUsername(roleName).setPassword('password')
  }

  createTestRole.afterAll = async () => {
    const roleNames = state.roleNames
    state.roleNames = []
    afterDebug(`createTestRole afterAll cleanup: ${roleNames.length}`)

    const failures: { roleName: string; error: Error }[] = []

    for (const roleName of roleNames) {
      try {
        await execQueryNext(`DROP ROLE IF EXISTS "${roleName}"`, connString)
      } catch (error: any) {
        // If the database has already been dropped, ignore the error
        if (error.code !== '3D000') {
          failures.push({ roleName, error: error as Error })
        }
      }
    }

    if (failures.length) {
      throw new Error(
        [
          'Failed to delete all roles, note that these will need to be manually cleaned up:',
          JSON.stringify(failures, null, 2),
        ].join('\n')
      )
    }
  }

  return createTestRole
}

export const createTestRole = defineCreateTestRole({ roleNames: [] })

afterAll(createTestRole.afterAll)
