import { type IntrospectedStructure } from '../db/introspect/introspectDatabase.js'
import { type SelectedTable } from './getSelectedTables.js'

interface FilterSelectedTablesOptions {
  introspection: IntrospectedStructure
  selectedTables: SelectedTable[]
}

const filterSelectedTablesFromRelatives = (
  table: IntrospectedStructure['tables'][number],
  selectedTableIds: Set<string>
) => ({
  ...table,
  parents: table.parents.filter((parent) =>
    selectedTableIds.has(parent.targetTable)
  ),
  children: table.children.filter((child) =>
    selectedTableIds.has(child.fkTable)
  ),
})

export const filterSelectedTables = ({
  introspection,
  selectedTables,
}: FilterSelectedTablesOptions): IntrospectedStructure => {
  const selectedTableIds = new Set(selectedTables.map((table) => table.id))

  return {
    ...introspection,
    indexes: introspection.indexes.filter((index) =>
      selectedTableIds.has(`"${index.schema}"."${index.table}"`)
    ),
    tables: introspection.tables
      .filter((table) => selectedTableIds.has(table.id))
      .map((table) =>
        filterSelectedTablesFromRelatives(table, selectedTableIds)
      ),
  }
}
