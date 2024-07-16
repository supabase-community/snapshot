import type { SnapshotTable } from '@snaplet/sdk/cli'
import { CloudSnapshot } from '@snaplet/sdk/cli'
import type TypedEmitter from '~/lib/typed-emitter.js'

export type FilterTablesEvents = {
  'filterTables:start': () => void
  'filterTables:complete': () => void
  'filterTables:error': (payload: {
    error: Error
    schema: string
    table: string
  }) => void
}

const parseTableString = (
  tables: string[]
): { schema: string; table: string }[] => {
  return tables.map((t) => {
    if (t.includes('.')) {
      const [schema, table] = t.split('.')
      return { schema, table }
    } else {
      return { schema: 'public', table: t }
    }
  })
}

export async function filterTables(
  ctx: {
    eventEmitter: TypedEmitter<FilterTablesEvents>
  },
  summary: CloudSnapshot,
  tables: string[],
  excludeTables: string[]
) {
  ctx.eventEmitter.emit('filterTables:start')
  const tablesInSnapshot = summary.summary.tables ?? []
  let filteredTables: SnapshotTable[] = []
  if (tables.length > 0) {
    const tablesToInclude = parseTableString(tables)
    for (const table of tablesToInclude) {
      const tableInSnapshot = tablesInSnapshot.find(
        (t) => t.table === table.table && t.schema === table.schema
      )

      if (!tableInSnapshot) {
        const error = new Error(
          `Table ${table.schema}.${table.table} not found in snapshot`
        )
        ctx.eventEmitter.emit('filterTables:error', { error, ...table })
      } else {
        filteredTables.push(tableInSnapshot)
      }
    }
  } else if (excludeTables.length > 0) {
    const tablesToExclude = parseTableString(excludeTables)
    filteredTables = tablesInSnapshot.filter(
      (table) =>
        !tablesToExclude.some(
          (t) => t.table === table.table && t.schema === table.schema
        )
    )
  } else {
    filteredTables = tablesInSnapshot
  }

  ctx.eventEmitter.emit('filterTables:complete')
  return filteredTables
}
