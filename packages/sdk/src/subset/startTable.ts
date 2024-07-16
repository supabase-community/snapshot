import * as levensthein from 'fastest-levenshtein'

import { IntrospectedStructure } from '../db/introspect/introspectDatabase.js'
import { topologicalSort } from '../sort.js'

export const subsetStartTable = (structure: IntrospectedStructure) => {
  // Filter out tables that dont have relationships
  const tablesFiltered = structure.tables.filter(
    (t) =>
      (t.parents && t.parents.length > 0) ||
      (t.children && t.children.length > 0)
  )
  if (tablesFiltered.length === 0) {
    // If no tables have relationships, just use the first table
    return structure.tables[0]
  }

  let sortedTables = tablesFiltered
  try {
    sortedTables = [...topologicalSort(tablesFiltered).values()]
      .reverse()
      .map((t) => t.node)
  } catch (e) {
    // If we can't sort the tables, just use the filtered tables
    sortedTables = tablesFiltered
  }

  const TYPICAL_START_TABLES = [
    'user',
    'customer',
    'account',
    'tenant',
    'organization',
    'company',
    'project',
  ]

  const bestMatch = sortedTables.reduce(
    (acc, table) => {
      const tableStr = table.name.toLowerCase()
      const closest = levensthein.closest(tableStr, TYPICAL_START_TABLES)
      const distance = levensthein.distance(tableStr, closest)
      if (distance <= 4 && distance < acc.distance) {
        return { table, distance }
      }
      return acc
    },
    { table: sortedTables[0], distance: Infinity }
  )

  return bestMatch.table
}
