import {
  ConnectionString,
  introspectDatabaseV3,
  withDbClient,
} from '@snaplet/sdk/cli'
import prompts from 'prompts'

import { needs } from '~/components/needs/index.js'
import { writeProjectConfig } from '~/components/writeConfig.js'
import { config } from '~/lib/config.js'
import { fmt } from '~/lib/format.js'
import { teardownAndExit } from '~/lib/handleTeardown.js'

export const inputTargetDatabaseLocalUrl = async (
  rawDatabaseUrl?: string
): Promise<ConnectionString> => {
  console.log(`
${fmt(`# Target database credentials
Snaplet restores data __to__ your target database using the target database credentials.

Read more: https://docs.snaplet.dev/guides/postgresql#connection-strings`)}
`)

  if (!rawDatabaseUrl) {
    const projectConfig = await config.getProject()
    const { value } = await prompts({
      type: 'text',
      name: 'value',
      message: 'Target database connection string',
      hint: 'postgresql://user:password@localhost:5432/postgres',
      initial:
        projectConfig.targetDatabaseUrl || process.env.PGENV_CONNECTION_URL,
      validate(value) {
        return value.length > 0
      },
    })
    rawDatabaseUrl = value
  }

  if (typeof rawDatabaseUrl !== 'string') {
    console.log('Target database connection string empty. Exiting...')
    return await teardownAndExit(0)
  }

  const databaseUrl = new ConnectionString(rawDatabaseUrl)
  await needs.databaseConnection(databaseUrl)
  await writeProjectConfig({ targetDatabaseUrl: databaseUrl.toString() })

  return databaseUrl
}

export const inputTargetDatabaseCloudUrl = async (
  rawDatabaseUrl?: string
): Promise<ConnectionString> => {
  console.log(`
${fmt(`# Target database credentials
Snaplet restores data __to__ your target database using the target database credentials.

Read more: https://docs.snaplet.dev/guides/postgresql#connection-strings`)}
`)

  if (!rawDatabaseUrl) {
    const projectConfig = await config.getProject()
    const { value } = await prompts({
      type: 'text',
      name: 'value',
      message: 'Target database connection string',
      hint: 'postgresql://user:password@localhost:5432/postgres',
      initial:
        projectConfig.targetDatabaseUrl || process.env.PGENV_CONNECTION_URL,
      validate(value) {
        return value.length > 0
      },
    })
    rawDatabaseUrl = value
  }

  if (typeof rawDatabaseUrl !== 'string') {
    console.log('Target database connection string empty. Exiting...')

    return await teardownAndExit(0)
  }

  const databaseUrl = new ConnectionString(rawDatabaseUrl)
  await needs.databaseConnection(databaseUrl)
  await writeProjectConfig({ targetDatabaseUrl: databaseUrl.toString() })

  return databaseUrl
}

export const inputNonEmptyTargetDatabase = async (
  connectionString: ConnectionString,
  retryFn = inputTargetDatabaseLocalUrl
): Promise<ConnectionString> => {
  const connString = connectionString.toString()
  try {
    const structure = await withDbClient(introspectDatabaseV3, {
      connString,
    })
    const isNonEmptyStructure = structure.tables.length > 0
    if (isNonEmptyStructure) {
      return connectionString
      // If the database is empty we give a chance to the user to run his migrations scripts and try again
    } else {
      console.log(
        `Your database does not have a schema. Snaplet requires a database structure in order to generate type definitions.\nPlease run your migration script and try again.`
      )
      let tryAgain = true
      const res = await prompts({
        type: 'confirm',
        name: 'tryAgain',
        message: 'Did you run your migrations and want to try again?',
        initial: true,
      })
      tryAgain = res.tryAgain
      // If the user want to try again, prefill the target database url with the one he entered before
      if (tryAgain) {
        return await inputNonEmptyTargetDatabase(
          await retryFn(connectionString.toString())
        )
      }
      // If the user don't want to try again, ask him to enter a new target database url
      return await inputNonEmptyTargetDatabase(await retryFn())
    }
  } catch (e) {
    console.log(
      `Cannot use the target database:\nCannot introspect database, please ensure you have the correct credentials and that the database exist:\n${e}`
    )
    return await inputNonEmptyTargetDatabase(await retryFn())
  }
}
