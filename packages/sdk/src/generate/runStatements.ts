import { ConnectionString } from '../db/connString/ConnectionString.js'
import { execQueryNext } from '../db/client.js'
import { DatabaseError } from 'pg-protocol'

const createForeignKeyViolationError = (dbError: DatabaseError) => {
  const message = `
${dbError.message}

Details: ${dbError.detail}

One cause of this could be schemas or tables excluded in the \`select\` config in your \`snaplet.config.ts\`.
In these cases, Snaplet will try generate data for a table without considering a relation for that table if the
related tables has been excluded.
`

  const error = new Error(message)

  Object.assign(error, {
    ...dbError,
    dbError,
  })

  throw error
}

export const runStatements = async (
  connString: ConnectionString,
  statements: Iterable<string>,
  abortSignal?: AbortSignal
) => {
  for (const statement of statements) {
    try {
      await execQueryNext(statement, connString)
    } catch (e) {
      if (e instanceof DatabaseError) {
        if (e.code === '23503') {
          throw createForeignKeyViolationError(e)
        } else {
          throw e
        }
      }
    }
    abortSignal?.throwIfAborted()
  }
}
