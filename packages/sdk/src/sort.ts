import { TopologicalSort } from 'topological-sort'

import { IntrospectedStructure } from './db/introspect/introspectDatabase.js'
import { isError } from './errors.js'

export const topologicalSort = (tables: IntrospectedStructure['tables']) => {
  const nodes = new Map()
  for (const table of tables) {
    nodes.set(table.id, table)
  }
  const sortOp = new TopologicalSort<string, (typeof tables)[number]>(nodes)
  for (const table of tables) {
    for (const parent of table.parents) {
      // If at least one of the keys is non nullable, the relation is non nullable
      const isNullable = parent.keys.every((key) => key.nullable === true)

      if (isNullable === false) {
        try {
          sortOp.addEdge(parent.fkTable, parent.targetTable)
        } catch (e) {
          const isDoubleEdgeError =
            isError(e) &&
            e.message.includes('already has an adge to target node')
          if (!isDoubleEdgeError) {
            throw e
          }
        }
      }
    }
  }
  return sortOp.sort()
}
