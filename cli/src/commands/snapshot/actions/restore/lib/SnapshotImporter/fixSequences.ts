import type { SnapshotTable } from '@snaplet/sdk/cli'
import type { DatabaseClient as Client } from '@snaplet/sdk/cli'
import type TypedEmitter from '~/lib/typed-emitter.js'

export type FixSequencesEvents = {
  'fixSequences:start': () => void
  'fixSequences:update': (payload: { schema: string; table: string }) => void
  'fixSequences:complete': () => void
  'fixSequences:error': (payload: {
    error: Error
    schema: string
    table: string
  }) => void
}

export async function fixSequences(
  ctx: {
    client: Client
    eventEmitter: TypedEmitter<FixSequencesEvents>
  },
  tables: SnapshotTable[]
) {
  ctx.eventEmitter.emit('fixSequences:start')

  for (const { schema, table } of tables) {
    ctx.eventEmitter.emit('fixSequences:update', {
      schema,
      table,
    })
    const sequences = await fetchSequences(
      { client: ctx.client },
      schema,
      table
    )
    for (const sequence of sequences) {
      await fixSequence({ client: ctx.client }, sequence).catch((error) => {
        ctx.eventEmitter.emit('fixSequences:error', {
          error,
          table,
          schema,
        })
      })
    }
  }

  ctx.eventEmitter.emit('fixSequences:complete')
}

type Sequence = {
  seqname: string
  column: string
  schema: string
  table: string
}
async function fetchSequences(
  ctx: {
    client: Client
  },
  schema: string,
  tableName: string
) {
  const { rows } = await ctx.client.query<Sequence>(
    `
    select n.nspname as schema, t.relname as table, a.attname as column, s.relname as seqname
    from pg_class s
    inner join pg_depend d on d.objid = s.oid
    inner join pg_class t on d.objid = s.oid and d.refobjid = t.oid
    inner join pg_attribute a on (d.refobjid, d.refobjsubid) = (a.attrelid, a.attnum)
    inner join pg_namespace n on n.oid = s.relnamespace
    where s.relkind = 'S' and n.nspname = $1 and t.relname = $2`,
    [schema, tableName]
  )
  return rows
}

async function fixSequence(ctx: { client: Client }, sequence: Sequence) {
  const identifier = `${ctx.client.escapeIdentifier(
    sequence.schema
  )}.${ctx.client.escapeIdentifier(sequence.table)}`

  const columnIdentifier = ctx.client.escapeIdentifier(sequence.column)

  await ctx.client.query(
    `select setval(pg_get_serial_sequence($1, $2), coalesce(max(${columnIdentifier}), 1))
      from ${identifier}`,
    [identifier, sequence.column]
  )
}
