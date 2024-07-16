import type { SnapshotTable } from '@snaplet/sdk/cli'
import type { DatabaseClient as Client } from '@snaplet/sdk/cli'
import type TypedEmitter from '~/lib/typed-emitter.js'

export type VacuumTablesEvents = {
  'vacuumTables:start': () => void
  'vacuumTables:update': (payload: { schema: string; table: string }) => void
  'vacuumTables:complete': () => void
  'vacuumTables:error': (payload: {
    error: Error
    schema: string
    table: string
  }) => void
}

export async function vacuumTables(
  ctx: {
    client: Client
    eventEmitter: TypedEmitter<VacuumTablesEvents>
  },
  tables: SnapshotTable[]
) {
  ctx.eventEmitter.emit('vacuumTables:start')

  for (const { schema, table } of tables) {
    ctx.eventEmitter.emit('vacuumTables:update', {
      schema,
      table,
    })
    await vacuumTable(
      {
        client: ctx.client,
      },
      schema,
      table
    ).catch((error) => {
      ctx.eventEmitter.emit('vacuumTables:error', {
        error,
        table,
        schema,
      })
    })
  }

  ctx.eventEmitter.emit('vacuumTables:complete')
}

async function vacuumTable(
  ctx: {
    client: Client
  },
  schema: string,
  tableName: string
) {
  const identifier = `${ctx.client.escapeIdentifier(
    schema
  )}.${ctx.client.escapeIdentifier(tableName)}`

  await ctx.client.query(`vacuum ${identifier}`)
}
