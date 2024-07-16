import { ConnectionString } from '@snaplet/sdk/cli'
import { MiddlewareFunction } from 'yargs'

export const removePgEnvarMiddleware: MiddlewareFunction = () => {
  const { PGUSER, PGPASSWORD, PGHOST, PGDATABASE, PGPORT } = process.env

  process.env.PGENV_CONNECTION_URL = ConnectionString.fromObject({
    username: PGUSER,
    password: PGPASSWORD,
    hostname: PGHOST,
    port: PGPORT !== '' && PGPORT != null ? +PGPORT : null,
    database: PGDATABASE,
  }).toString()

  // We do not want these defined because node-postgres uses them,
  // and we want the user to be explicit about the credentials.
  delete process.env.PGUSER
  delete process.env.PGPASSWORD
  delete process.env.PGHOST
  delete process.env.PGDATABASE
  delete process.env.PGPORT
}
