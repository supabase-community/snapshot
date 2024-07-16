import {
  Client,
  ClientConfig,
  CustomTypesConfig,
  Pool,
  PoolClient,
  PoolConfig,
  QueryResult,
  QueryResultRow,
  QueryConfig,
  QueryArrayConfig,
} from 'pg'

import { xdebug } from '../x/xdebug.js'
import {
  findWorkingDbConnString,
  ConnectionString,
  ConnectionStringShape,
} from './connString/index.js'
import { isSupabaseUrl } from './connString/isSupabaseUrl.js'

export const MAX_POOL_SIZE = 10
export type DatabaseClient = Client | PoolClient

export interface ConnectionOptions {
  client?: DatabaseClient
  connString?: string
  dbName?: string
  admin?: boolean
}

type ExclusiveConnectionOptions =
  | { client: DatabaseClient; connString?: never }
  | { client?: never; connString: string }

export type ValidatedConnectionOptions = ConnectionOptions &
  ExclusiveConnectionOptions

type DbPoolConfig = Omit<PoolConfig, 'connectionString'> & {
  connectionString: ConnectionStringShape
}

const xdebugConnections = xdebug.extend('db:client')
const noopDebugger = (...args: any) => xdebugConnections('noop: ', args)

export const CLIENT_CONFIG_DEFAULTS: Partial<ClientConfig> = {
  keepAlive: true,
}

export const POOL_DEFAULTS: Partial<PoolConfig> = {
  max: MAX_POOL_SIZE,
  idleTimeoutMillis: 30_000,
}

const POOL_CACHE = new Map<string, Pool>()

export const releaseDbClient = async (
  client: DatabaseClient,
  error?: Error
): Promise<void> => {
  if (typeof (client as any).release === 'function') {
    return (client as PoolClient).release(error)
  } else {
    return await (client as Client).end()
  }
}

function setupPoolEventListeners(pool: Pool) {
  // context(justinvdm, 13 Mar 2022): From [docs](https://node-postgres.com/apis/pool#error)
  // > You probably want to add an event listener to the pool to catch background errors errors!
  // > Just like other event emitters, if a pool emits an error event and no listeners are added
  // > node will emit an uncaught error and potentially crash your node process.
  //
  // Error events would be emitted for idle clients - this is fine for us, since we'll still
  // find out about errors we do need to know about next time we try acquire a client, these
  // will be given as promise rejections on `.connect()`. For example:
  // ```
  // 1. pool created with no-op event listener
  // 2. pool.connect() fulfills to a client
  // 3. client.release() => client connected still, but idle
  // 4. server terminates connection => pool error silently ignored, idle client considered disconnected
  // 5. next pool.connect() attempted => server refuses connection (e.g. if server is down)
  // (we would have simply gotten the idle client instead, but it got disconnected on step 4)
  // ```
  pool.on('error', noopDebugger)

  pool.on('connect', (client) => {
    //@ts-expect-error
    client.snapletId = `${Date.now()}-${Math.random().toString(36).slice(2)}`
    //@ts-expect-error
    xdebugConnections(`new client connected: ${client.snapletId}`)
    // context(justinvdm, 13 Mar 2022): Originally a comment from avallete, 13 Mar 2022:
    // We need to bind a default "error" to the pg client to avoid unexpected node process exit
    // See: https://github.com/brianc/node-postgres/issues/1611#issuecomment-736939235
    // See: https://github.com/brianc/node-postgres/issues/2820#issuecomment-1257585975
    client.on('error', noopDebugger)
  })

  pool.on('acquire', () => {
    const { totalCount, waitingCount, idleCount } = pool

    xdebugConnections('new client acquired:', {
      totalCount,
      waitingCount,
      idleCount,
    })
  })

  pool.on('remove', (client) => {
    client.off('error', noopDebugger)

    const { totalCount, waitingCount, idleCount } = pool

    xdebugConnections(
      // @ts-expect-error
      `client '${client.snapletId}' closed and removed from pool:`,
      {
        totalCount,
        waitingCount,
        idleCount,
      }
    )
  })
}

const createDbPool = async (inputConfig: DbPoolConfig) => {
  const config = {
    ...POOL_DEFAULTS,
    ...CLIENT_CONFIG_DEFAULTS,
    ...inputConfig,
    ssl: { rejectUnauthorized: false },
  }

  let connectionString = new ConnectionString(inputConfig.connectionString)

  // to solve this issue: https://github.com/brianc/node-postgres/issues/2757
  if (connectionString.password === '') {
    connectionString = connectionString.setPassword(' ')
  }

  delete process.env.PGUSER
  delete process.env.PGPASSWORD
  delete process.env.PGHOST
  delete process.env.PGDATABASE
  delete process.env.PGPORT

  const serializedConfig = {
    ...config,
    connectionString: connectionString.toString(),
  }

  let pool = new Pool(serializedConfig)
  let client: PoolClient
  setupPoolEventListeners(pool)

  try {
    client = await pool.connect()
  } catch (e: any) {
    if (e?.message?.includes('The server does not support SSL connections')) {
      await pool.end()
      pool = new Pool({
        ...serializedConfig,
        ssl: false,
      })
      setupPoolEventListeners(pool)
      client = await pool.connect()
    } else {
      throw e
    }
  }
  client.release()

  return pool
}

export const endAllPools = async () => {
  const pools = [...POOL_CACHE.entries()]
  // We use allSettled because we don't want to stop at the first pool we can't end
  await Promise.allSettled(
    pools.map(([name, pool]) =>
      pool
        .end()
        .then(() => POOL_CACHE.delete(name))
        .catch(noopDebugger)
    )
  )
}

export const endPool = async (name: string) => {
  const pool = POOL_CACHE.get(name)
  if (pool) {
    await pool.end().catch(noopDebugger)
  }
}

export const getDbPool = async (config: DbPoolConfig) => {
  const key = config.connectionString.toString()
  let pool = POOL_CACHE.get(key)

  if (pool) {
    return pool
  }

  pool = await createDbPool(config)
  POOL_CACHE.set(key, pool)
  return pool
}

export const acquireDbClient = async (config: DbPoolConfig) => {
  const pool = await getDbPool(config)
  return await pool.connect()
}

export async function getDbClient(
  rawConnectionString: string,
  inputConfig: ClientConfig = {},
  databaseName?: string
): Promise<PoolClient> {
  // context(peterp, 2nd May 2022): We use the same code for local and remote database connections.
  // Local database connections typically don't support SSL. We will first try to connect via SSL -
  // if that fails we try without SSL.
  // https://github.com/prisma/specs/issues/325

  const { connectionString: _, ...config } = inputConfig
  let connectionString = new ConnectionString(rawConnectionString ?? '')

  if (databaseName) {
    connectionString = connectionString.setDatabase(databaseName)
  }

  return acquireDbClient({
    ...config,
    connectionString,
  })
}

/**
 * Opens a connection to the `_snaplet` management database.
 * If it doesn't exist then it's created.
 */
export async function getDbAdminClient(
  connString: string
): Promise<PoolClient> {
  // context(justinvdm, 27 Jan 2021): https://discord.com/channels/788353076129038346/933371031513604187/936226832670416957
  if (isSupabaseUrl(connString)) {
    return await getDbClient(connString, {}, 'postgres')
  }

  try {
    const client = await getDbClient(connString, {}, '_snaplet')
    return client
  } catch (e: any) {
    if (e.message === 'database "_snaplet" does not exist') {
      await createAdminDatabase(connString)
      return getDbAdminClient(connString)
    } else {
      throw e
    }
  }
}

export async function withDbClient<Result>(
  fn: (client: DatabaseClient) => Result,
  options: ValidatedConnectionOptions
): Promise<Result> {
  const client =
    options.client ??
    (options.dbName || options.connString
      ? await getDbClient(options.connString, {}, options.dbName)
      : await getDbAdminClient(options.connString))
  try {
    const result = await fn(client)
    await releaseDbClient(client)
    return result
  } catch (e) {
    await releaseDbClient(client, e as Error)
    throw e
  }
}

/** @deprecated: Please use `execQueryNext`. For more, see: https://github.com/snaplet/snaplet/issues/791 */
export async function execQuery<Result extends QueryResultRow>(
  query: string,
  options: ValidatedConnectionOptions
): Promise<QueryResult<Result>> {
  const queryFn = (client: DatabaseClient) => client.query(query)
  return await withDbClient(queryFn, options)
}

/**
 * Attempts to create the "_snaplet" admin database with the
 * user's target database credentials.
 */
// TODO: Move to pg-tools.
export async function createAdminDatabase(connString: string) {
  connString = await findWorkingDbConnString(connString)
  await withDbClient(
    async (client) => {
      try {
        await client.query('CREATE DATABASE "_snaplet"')
      } catch (e: any) {
        if (e.message !== 'database "_snaplet" already exists') {
          const error = new Error(
            'Could not create "_snaplet" database: ' + e?.message
          )
          error.name = 'DB_CREATE_ADMIN_DATABASE'
          throw error
        }
      }
    },
    { connString }
  )
}

const rawModeParser = (value: unknown) => value
const customRawModeParser: CustomTypesConfig = {
  getTypeParser(_, __) {
    // Whatever the id we will always return the raw value
    return rawModeParser
  },
}

export async function execQueryNext<Result extends QueryResultRow>(
  query:
    | string
    | QueryConfig
    | QueryArrayConfig
    | ((db: DatabaseClient) => Promise<QueryResult<Result>>),
  connectionString: ConnectionStringShape,
  databaseName?: string,
  useRawParser = false
): Promise<QueryResult<Result>> {
  connectionString = new ConnectionString(connectionString).toString()
  let client
  try {
    client = await getDbClient(connectionString, {}, databaseName)
    const result =
      typeof query !== 'function'
        ? await client.query<Result>(
            typeof query === 'string'
              ? {
                  text: query,
                  types: useRawParser ? customRawModeParser : undefined,
                }
              : {
                  ...query,
                  types: useRawParser ? customRawModeParser : query.types,
                }
          )
        : await query(client)
    return result
  } finally {
    await client?.release()
  }
}
