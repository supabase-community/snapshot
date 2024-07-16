import {
  ConnectionString,
  findWorkingDbConnString,
  execQueryNext,
} from '@snaplet/sdk/cli'
import c from 'ansi-colors'

import { exitWithError } from '~/lib/exit.js'
import { activity } from '~/lib/spinner.js'

import { logError } from './logError.js'
import { fmt } from '~/lib/format.js'

const noopActivity = { done: () => {}, fail: () => {}, info: () => {} }

export const databaseConnection = async (
  connString: ConnectionString,
  options?: {
    silent?: boolean
    shouldCreate?: boolean
  }
) => {
  const shouldCreate = options?.shouldCreate ?? true
  const connectionInfo = c.gray(
    `📡 Connected to database with "${connString.toScrubbedString()}"`
  )
  const act = options?.silent
    ? noopActivity
    : activity('Database connection', 'Testing...')
  try {
    await execQueryNext('SELECT 1', connString.toString())
    act.done()
    if (!options?.silent) {
      // eslint-disable-next-line no-console
      console.log(connectionInfo)
    }
  } catch (e: any) {
    if (e?.message.includes('password authentication failed for user')) {
      act.fail()
      logError([
        `Error: ${e?.message}`,
        fmt(
          'You may have to encode your password using **encodeURIComponent()** [learn more](https://docs.snaplet.dev/guides/postgresql#troubleshooting-connection-strings)'
        ),
      ])
      await exitWithError('DATABASE_PASSWORD_AUTH_FAILED')
    } else if (e?.message.endsWith('does not exist') && shouldCreate) {
      try {
        act.info('Creating database...')
        const maintenanceConnectionString = await findWorkingDbConnString(
          connString.toString()
        )
        const dbName = connString.database
        await execQueryNext(
          `CREATE DATABASE "${dbName}"`,
          maintenanceConnectionString
        )
        act.done()
        if (!options?.silent) {
          // eslint-disable-next-line no-console
          console.log(connectionInfo)
        }
      } catch (createError: any) {
        act.fail('Could not create database')
        logError([
          `Connected to database server, but the database "${connString.database}" does not exist and it could not be created:`,
          createError?.message,
        ])
        await exitWithError('DATABASE_CONNECTION_CANNOT_CREATE')
      }
    } else {
      act.fail()
      logError(['Unable to connect to database:', e?.message])
      await exitWithError('DATABASE_CONNECTION_FAILED')
    }
  }
}
