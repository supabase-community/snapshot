import type { DatabaseClient as Client } from '@snaplet/sdk/cli'
import type TypedEmitter from '~/lib/typed-emitter.js'

import {
  Constraint,
  Index,
  Rule,
  SideEffectStatements,
  Trigger,
} from './fetchSideEffectStatements.js'

export type CreateConstraintsEvents = {
  'createConstraints:start': () => void
  'createConstraints:update': (payload: {
    schema: string
    table: string
  }) => void
  'createConstraints:complete': () => void
  'createConstraints:error': (payload: {
    error: Error
    schema: string
    table: string
  }) => void
}

export async function createConstraints(
  ctx: { client: Client; eventEmitter: TypedEmitter<CreateConstraintsEvents> },
  sideEffectStatements: Map<string, SideEffectStatements>
) {
  ctx.eventEmitter.emit('createConstraints:start')

  // First pass we omit foreign keys creation
  for (const [schemaTable, statements] of sideEffectStatements) {
    const [schema, table] = schemaTable.split('.')
    ctx.eventEmitter.emit('createConstraints:update', { schema, table })

    const nonForeignKeyConstraints = statements.constraints.filter(
      (c) => c.contype !== 'f'
    )
    await createSideEffectStatements(
      { client: ctx.client, eventEmitter: ctx.eventEmitter },
      {
        ...statements,
        constraints: nonForeignKeyConstraints,
      }
    )
  }

  // Second pass we create foreign keys
  for (const [schemaTable, statements] of sideEffectStatements) {
    const [schema, table] = schemaTable.split('.')
    ctx.eventEmitter.emit('createConstraints:update', { schema, table })

    const foreignKeyConstraints = statements.constraints.filter(
      (c) => c.contype === 'f'
    )
    await createSideEffectStatements(
      { client: ctx.client, eventEmitter: ctx.eventEmitter },
      {
        constraints: foreignKeyConstraints,
        indexes: [],
        rules: [],
        triggers: [],
      }
    )
  }

  ctx.eventEmitter.emit('createConstraints:complete')
}

async function createSideEffectStatements(
  ctx: {
    client: Client
    eventEmitter: TypedEmitter<CreateConstraintsEvents>
  },
  { triggers, rules, constraints, indexes }: SideEffectStatements
) {
  for (const trigger of triggers) {
    await enableTrigger(ctx, trigger).catch((error) => {
      ctx.eventEmitter.emit('createConstraints:error', {
        schema: trigger.schema,
        table: trigger.table,
        error,
      })
    })
  }

  for (const rule of rules) {
    await enableRule(ctx, rule).catch((error) => {
      ctx.eventEmitter.emit('createConstraints:error', {
        schema: rule.schema,
        table: rule.table,
        error,
      })
    })
  }

  for (const constraint of constraints) {
    await createConstraint(ctx, constraint).catch((error) => {
      ctx.eventEmitter.emit('createConstraints:error', {
        schema: constraint.schema,
        table: constraint.table,
        error,
      })
    })
  }

  for (const index of indexes) {
    await createIndex(ctx, index).catch((error) => {
      // ignore errors about indexes that already exist from creating primary keys
      if (
        error instanceof Error &&
        !/relation.+already exists/.test(error.message)
      ) {
        ctx.eventEmitter.emit('createConstraints:error', {
          schema: index.schema,
          table: index.table,
          error,
        })
      }
    })
  }
}

async function enableTrigger(ctx: { client: Client }, trigger: Trigger) {
  const identifier = `${ctx.client.escapeIdentifier(
    trigger.schema
  )}.${ctx.client.escapeIdentifier(trigger.table)}`

  await ctx.client.query(
    `alter table ${identifier} enable trigger ${ctx.client.escapeIdentifier(
      trigger.tgname
    )}`
  )
}

async function enableRule(ctx: { client: Client }, rule: Rule) {
  const identifier = `${ctx.client.escapeIdentifier(
    rule.schema
  )}.${ctx.client.escapeIdentifier(rule.table)}`

  await ctx.client.query(
    `alter table ${identifier} enable rule ${ctx.client.escapeIdentifier(
      rule.rulename
    )}`
  )
}

async function createConstraint(
  ctx: { client: Client },
  constraint: Constraint
) {
  const identifier = `${ctx.client.escapeIdentifier(
    constraint.schema
  )}.${ctx.client.escapeIdentifier(constraint.table)}`

  await ctx.client.query(
    `alter table ${identifier} add constraint ${ctx.client.escapeIdentifier(
      constraint.conname
    )} ${constraint.definition}`
  )
}

async function createIndex(ctx: { client: Client }, index: Index) {
  await ctx.client.query(index.indexdef)
}
