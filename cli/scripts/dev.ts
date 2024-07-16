import dotenv from 'dotenv-defaults'
import execa from 'execa'
import path from 'path'
import pg from 'pg'
import c from 'ansi-colors'
import { hashPassword } from '@snaplet/sdk/cli'

dotenv.config({
  defaults: path.resolve(__dirname, '../../.env.defaults'),
})

const logDev = (...args: any[]) => console.log(c.magenta(' DEV:'), ...args)

void main()

async function main() {
  try {
    logDev('Gathering requirements... Wait for ready...')

    // Setting up envars
    process.env.SNAPLET_DATABASE_URL ||=
      'postgresql://postgres@localhost/snaplet_cli_dev'
    logDev(`Using "DATABASE_URL" (${process.env.SNAPLET_DATABASE_URL}`)

    const command = `yarn start ${process.argv.slice(2).join(' ')}`

    logDev('Ready...')
    console.log('*'.repeat(80))
    const envs = Object.entries(process.env)
      .filter(([k]) => k.startsWith('SNAPLET_'))
      .map(([k, v]) => {
        return `${k}=${v}`
      })
      .join(' ')
    console.log(envs, command)
    console.log('*'.repeat(80))
    try {
      execa.commandSync(command, {
        cwd: path.resolve(__dirname, '../'),
        stdio: 'inherit',
        extendEnv: true,
        shell: true,
      })
    } catch (e) {
      logDev('Error: Could not run CLI', (e as Error)?.message)
      // Do nothing. The CLI should display the error output.
    }
  } catch (e) {
    logDev('Error: ', (e as Error)?.message)
    process.exit(1)
  }
}

async function getAccessToken() {
  const client = new pg.Client({ connectionString: process.env.DATABASE_URL })
  await client.connect()

  const password = process.env.SNAPLET_PROJECT_ID + '-' + new Date().getTime()
  const hash = await hashPassword(password)

  // Get access token id
  const r = await client.query(
    `
  SELECT "AccessToken".id, "AccessToken".hash FROM "AccessToken"
  	INNER JOIN "Member" ON "Member"."userId" = "AccessToken"."userId"
	  INNER JOIN "Project" ON "Project"."organizationId" = "Member"."organizationId"
  	WHERE "Project".id = '${process.env.SNAPLET_PROJECT_ID}'
  LIMIT 1;`
  )
  const accessTokenId = r?.rows[0]?.id
  if (!accessTokenId) {
    throw new Error('No access token. Please create one.')
  }

  await client.query(
    `UPDATE "AccessToken" SET hash = '${hash}' WHERE "AccessToken".id = '${accessTokenId}'`
  )
  await client?.end()
  return password
}
