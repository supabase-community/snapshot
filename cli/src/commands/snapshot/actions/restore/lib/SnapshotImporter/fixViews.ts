import type { DatabaseClient as Client } from '@snaplet/sdk/cli'
import type TypedEmitter from '~/lib/typed-emitter.js'

import { splitSchema } from '../pgSchemaTools.js'

export type FixViewsEvents = {
  'fixViews:start': () => void
  'fixViews:update': (payload: { schema: string; table: string }) => void
  'fixViews:complete': () => void
  'fixViews:parsingError': (payload: {
    error: Error
    schemaPath: string
  }) => void
  'fixViews:statementError': (payload: {
    error: Error
    statement: string
  }) => void
}

export async function fixViews(
  ctx: {
    client: Client
    eventEmitter: TypedEmitter<FixViewsEvents>
  },
  schemaPath: string,
  schemaContent: string
) {
  ctx.eventEmitter.emit('fixViews:start')
  try {
    const viewStatements = splitSchema(schemaContent).filter((s) =>
      /^CREATE.+VIEW/gim.test(s)
    )
    for (const statement of viewStatements) {
      try {
        await ctx.client.query(statement)
      } catch (e) {
        ctx.eventEmitter.emit('fixViews:statementError', {
          error: e as Error,
          statement,
        })
      }
    }
  } catch (e) {
    ctx.eventEmitter.emit('fixViews:parsingError', {
      error: e as Error,
      schemaPath,
    })
  }
  ctx.eventEmitter.emit('fixViews:complete')
}
