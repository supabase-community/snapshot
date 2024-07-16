import type { SnapshotTable } from '@snaplet/sdk/cli'
import type { DatabaseClient as Client } from '@snaplet/sdk/cli'
import type TypedEmitter from '~/lib/typed-emitter.js'

export type TruncateTablesEvents = {
  'truncateTables:start': () => void
  'truncateTables:update': (payload: { schema: string; table: string }) => void
  'truncateTables:complete': () => void
  'truncateTables:error': (payload: {
    error: Error
    schema: string
    table: string
  }) => void
}

export async function truncateTables(
  ctx: {
    client: Client
    eventEmitter: TypedEmitter<TruncateTablesEvents>
  },
  tables: SnapshotTable[]
) {
  ctx.eventEmitter.emit('truncateTables:start')

  for (const { schema, table } of tables) {
    ctx.eventEmitter.emit('truncateTables:update', {
      schema,
      table,
    })
    await truncateTable(
      {
        client: ctx.client,
      },
      schema,
      table
    ).catch((error) => {
      ctx.eventEmitter.emit('truncateTables:error', {
        error,
        table,
        schema,
      })
    })
  }

  ctx.eventEmitter.emit('truncateTables:complete')
}

async function truncateTable(
  ctx: {
    client: Client
  },
  schema: string,
  tableName: string
) {
  const identifier = `${ctx.client.escapeIdentifier(
    schema
  )}.${ctx.client.escapeIdentifier(tableName)}`

  await ctx.client.query(`truncate ${identifier}`)
}
