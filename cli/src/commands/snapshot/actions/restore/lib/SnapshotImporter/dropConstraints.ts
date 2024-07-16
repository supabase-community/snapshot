import type { SnapshotTable } from '@snaplet/sdk/cli'
import type { DatabaseClient as Client } from '@snaplet/sdk/cli'
import type TypedEmitter from '~/lib/typed-emitter.js'

import {
  Constraint,
  fetchSideEffectStatements,
  Index,
  Rule,
  SideEffectStatements,
  Trigger,
} from './fetchSideEffectStatements.js'

export type DropConstraintsEvents = {
  'dropConstraints:start': () => void
  'dropConstraints:update': (payload: { schema: string; table: string }) => void
  'dropConstraints:complete': () => void
  'dropConstraints:error': (payload: {
    error: Error
    schema: string
    table: string
  }) => void
}

export async function dropConstraints(
  ctx: { client: Client; eventEmitter: TypedEmitter<DropConstraintsEvents> },
  tables: SnapshotTable[]
) {
  ctx.eventEmitter.emit('dropConstraints:start')
  const droppedConstraints = new Map<string, SideEffectStatements>()
  const constraintsToDrop: Array<
    [{ schema: string; table: string }, SideEffectStatements]
  > = []

  // We retrieve all the constraints before doing any drop
  // Since we are using CASCADE dropping a PK in one table
  // could result in a lost of a FK in another table
  for (const { schema, table } of tables) {
    const statements = await fetchSideEffectStatements(
      {
        client: ctx.client,
        tables,
      },
      schema,
      table
    )
    constraintsToDrop.push([{ schema, table }, statements])
  }
  // Then, we can now iterate over all our constraints and drop them
  for (const [{ schema, table }, statements] of constraintsToDrop) {
    ctx.eventEmitter.emit('dropConstraints:update', {
      schema,
      table,
    })
    await dropSideEffectStatements(
      { client: ctx.client, eventEmitter: ctx.eventEmitter },
      statements
    )
    droppedConstraints.set(`${schema}.${table}`, statements)
  }
  ctx.eventEmitter.emit('dropConstraints:complete')

  return droppedConstraints
}

async function dropSideEffectStatements(
  ctx: {
    client: Client
    eventEmitter: TypedEmitter<DropConstraintsEvents>
  },
  { triggers, rules, constraints, indexes }: SideEffectStatements
) {
  for (const trigger of triggers) {
    await disableTrigger(ctx, trigger).catch((error) => {
      ctx.eventEmitter.emit('dropConstraints:error', {
        schema: trigger.schema,
        table: trigger.table,
        error,
      })
    })
  }

  for (const rule of rules) {
    await disableRule(ctx, rule).catch((error) => {
      ctx.eventEmitter.emit('dropConstraints:error', {
        schema: rule.schema,
        table: rule.table,
        error,
      })
    })
  }

  for (const constraint of constraints) {
    await dropConstraint(ctx, constraint).catch((error) => {
      ctx.eventEmitter.emit('dropConstraints:error', {
        schema: constraint.schema,
        table: constraint.table,
        error,
      })
    })
  }

  for (const index of indexes) {
    await dropIndex(ctx, index).catch((error) => {
      ctx.eventEmitter.emit('dropConstraints:error', {
        schema: index.schema,
        table: index.table,
        error,
      })
    })
  }
}

async function disableTrigger(ctx: { client: Client }, trigger: Trigger) {
  const identifier = `${ctx.client.escapeIdentifier(
    trigger.schema
  )}.${ctx.client.escapeIdentifier(trigger.table)}`

  await ctx.client.query(
    `alter table ${identifier} disable trigger ${ctx.client.escapeIdentifier(
      trigger.tgname
    )}`
  )
}

async function disableRule(ctx: { client: Client }, rule: Rule) {
  const identifier = `${ctx.client.escapeIdentifier(
    rule.schema
  )}.${ctx.client.escapeIdentifier(rule.table)}`

  await ctx.client.query(
    `alter table ${identifier} disable rule ${ctx.client.escapeIdentifier(
      rule.rulename
    )}`
  )
}

async function dropConstraint(ctx: { client: Client }, constraint: Constraint) {
  const identifier = `${ctx.client.escapeIdentifier(
    constraint.schema
  )}.${ctx.client.escapeIdentifier(constraint.table)}`

  await ctx.client.query(
    `alter table ${identifier} drop constraint if exists ${ctx.client.escapeIdentifier(
      constraint.conname
    )} cascade`
  )
}

async function dropIndex(ctx: { client: Client }, index: Index) {
  const identifier = `${ctx.client.escapeIdentifier(
    index.schema
  )}.${ctx.client.escapeIdentifier(index.indexname)}`

  await ctx.client.query(`drop index if exists ${identifier} cascade`)
}
