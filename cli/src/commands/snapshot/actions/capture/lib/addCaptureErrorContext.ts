import { ConnectionString, execQueryNext } from '@snaplet/sdk/cli'

import { config } from '~/lib/config.js'
import { IS_CI, IS_PRODUCTION } from '~/lib/constants.js'
import { getSentry } from '~/lib/sentry.js'

type Context = Record<string, unknown>
type Contexts = Record<string, Context>

const resolveValue = (v: unknown): unknown =>
  typeof v === 'function' ? v() : v

const resolveContext = async (unresolvedContext: Context): Promise<Context> => {
  const keys = Object.keys(unresolvedContext)

  const resultEntries = await Promise.allSettled(
    Object.keys(unresolvedContext).map((key) =>
      Promise.resolve(unresolvedContext[key]).then(resolveValue)
    )
  )

  const results: Context = {}
  const errors: Context = {}
  let i = -1

  for (const result of resultEntries) {
    const key = keys[++i]

    if (result.status === 'fulfilled') {
      results[key] = result.value
    } else {
      errors[key] = result.reason.toString()
    }
  }

  if (Object.keys(errors).length > 0) {
    results.__errors = errors
  }

  return results
}

const gatherContexts = async (contexts: Contexts): Promise<Contexts> => {
  const valueResults = await Promise.allSettled(
    Object.values(contexts).map(resolveContext)
  )
  const results: Contexts = {}
  let i = -1

  for (const key of Object.keys(contexts)) {
    const result = valueResults[++i]
    if (result.status === 'fulfilled') {
      results[key] = result.value
    }
  }

  return results
}

const fetchRoleInfo = (connString: ConnectionString) =>
  execQueryNext<{ rolpassword: unknown }>(
    `SELECT * FROM pg_roles WHERE rolname='${connString.username}'`,
    connString
  ).then(({ rows: [{ rolpassword: _, ...info }] }) => info)

const fetchDbSettings = (connString: ConnectionString) =>
  execQueryNext<{ name: string; setting: string }>(`SHOW ALL`, connString).then(
    ({ rows }) =>
      Object.fromEntries(rows.map(({ name, setting }) => [name, setting]))
  )

const fetchDbVersionInfo = (connString: ConnectionString) =>
  execQueryNext('SELECT version()', connString).then(
    ({ rows: [version] }) => version
  )

export const addCaptureErrorContext = async (
  error: Error,
  connString: ConnectionString
) => {
  if (!IS_PRODUCTION) {
    return
  }

  const [sentry, contexts] = await Promise.all([
    getSentry(),
    gatherContexts({
      db: {
        roleInfo: () => fetchRoleInfo(connString),
        dbSettings: () => fetchDbSettings(connString),
        versionInfo: () => fetchDbVersionInfo(connString),
      },
      snaplet: {
        IS_CI,
      },
      errorData: { ...error },
    }),
  ])

  for (const [name, context] of Object.entries(contexts)) {
    sentry.setContext(name, context)
  }
}
