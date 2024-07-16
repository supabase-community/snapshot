import type { DatabaseClient as Client } from '@snaplet/sdk/cli'
import type TypedEmitter from '~/lib/typed-emitter.js'

import { splitSchema } from '../pgSchemaTools.js'

export type ImportSchemaEvents = {
  'importSchema:start': () => void
  'importSchema:update': (payload: { schema: string; table: string }) => void
  'importSchema:complete': () => void
  'importSchema:parsingError': (payload: {
    error: Error
    schemaPath: string
  }) => void
  'importSchema:statementError': (payload: {
    error: Error
    statement: string
  }) => void
}

export async function importSchema(
  ctx: {
    client: Client
    eventEmitter: TypedEmitter<ImportSchemaEvents>
  },
  schemaPath: string,
  schemaContent: string
) {
  ctx.eventEmitter.emit('importSchema:start')
  try {
    const statements = splitSchema(schemaContent)
    for (const statement of statements) {
      try {
        await ctx.client.query(statement)
      } catch (e) {
        ctx.eventEmitter.emit('importSchema:statementError', {
          error: e as Error,
          statement,
        })
      }
    }
  } catch (e) {
    ctx.eventEmitter.emit('importSchema:parsingError', {
      error: e as Error,
      schemaPath,
    })
  }
  ctx.eventEmitter.emit('importSchema:complete')
}
