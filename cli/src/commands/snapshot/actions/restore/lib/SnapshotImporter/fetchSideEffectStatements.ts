import type { DatabaseClient, SnapshotTable } from '@snaplet/sdk/cli'

export async function fetchSideEffectStatements(
  ctx: {
    client: DatabaseClient
    tables: SnapshotTable[]
  },
  schema: string,
  tableName: string
) {
  const triggers = await fetchTriggers(ctx, schema, tableName)
  const rules = await fetchRules(ctx, schema, tableName)
  const constraints = await fetchConstraints(ctx, schema, tableName)
  const indexes = await fetchIndexes(ctx, schema, tableName)
  return { triggers, rules, constraints, indexes }
}

export type SideEffectStatements = Awaited<
  ReturnType<typeof fetchSideEffectStatements>
>

export type Trigger = {
  definition: string
  schema: string
  table: string
  tgname: string
}
async function fetchTriggers(
  ctx: {
    client: DatabaseClient
  },
  schema: string,
  tableName: string
) {
  const { rows } = await ctx.client.query<Trigger>(
    `
    select t.tgname, pg_get_triggerdef(t.oid) as definition, n.nspname as schema, c.relname as table
    from pg_trigger t
    inner join pg_class c on t.tgrelid = c.oid
    inner join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = $1 and c.relname = $2 and tgenabled = 'O' and tgisinternal is false`,
    [schema, tableName]
  )
  return rows
}

export type Rule = { schema: string; table: string; rulename: string }
async function fetchRules(
  ctx: {
    client: DatabaseClient
  },
  schema: string,
  tableName: string
) {
  const { rows } = await ctx.client.query<Rule>(
    `
    select r.rulename, n.nspname as schema, c.relname as table
    from pg_rewrite r
    inner join pg_class c on r.ev_class = c.oid
    inner join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = $1 and c.relname = $2`,
    [schema, tableName]
  )
  return rows
}

export type Constraint = {
  conname: string
  contype: 'c' | 'f' | 'p' | 'u' | 't' | 'x'
  definition: string
  schema: string
  table: string
}
async function fetchConstraints(
  ctx: {
    client: DatabaseClient
    tables: SnapshotTable[]
  },
  schema: string,
  tableName: string
) {
  const tableOwnConstraints = await ctx.client.query<Constraint>(
    `
    select con.conname, con.contype, pg_get_constraintdef(con.oid) as definition, n.nspname as schema, c.relname as table
    from pg_constraint con
    inner join pg_class c ON c.oid = con.conrelid
    inner join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = $1 and c.relname = $2 and con.contype != 't'`,
    [schema, tableName]
  )

  // As we use CASCADE to drop constraints, we need to bring foreign keys linked to the table's primary key to recreate them after the table is restored
  const foreignKeyConstraintsFromTablePrimaryKey =
    await ctx.client.query<Constraint>(
      `
    select conf.conname, conf.contype, pg_get_constraintdef(conf.oid) as definition, nf.nspname as schema, cf.relname as table
    from pg_constraint con
    join pg_class c ON c.oid = con.conrelid
    join pg_namespace n on n.oid = c.relnamespace
    join pg_constraint conf on conf.confrelid = con.conrelid
    join pg_class cf ON cf.oid = conf.conrelid
    join pg_namespace nf on nf.oid = cf.relnamespace
    where n.nspname = $1 and c.relname = $2 and con.contype = 'p' and conf.contype = 'f' and cardinality(conf.confkey) = 1;`,
      [schema, tableName]
    )
  const cascadedForeignKeyConstraints =
    foreignKeyConstraintsFromTablePrimaryKey.rows.filter((row) => {
      return !ctx.tables.some(
        ({ schema, table }) => row.schema === schema && row.table === table
      )
    })

  return [...tableOwnConstraints.rows, ...cascadedForeignKeyConstraints]
}

export type Index = {
  indexname: string
  indexdef: string
  schema: string
  table: string
}
async function fetchIndexes(
  ctx: {
    client: DatabaseClient
  },
  schema: string,
  tableName: string
) {
  const { rows } = await ctx.client.query<Index>(
    `
    select indexname, indexdef, schemaname as schema, tablename as table
    from pg_indexes
    where schemaname = $1 and tablename = $2`,
    [schema, tableName]
  )
  return rows
}
