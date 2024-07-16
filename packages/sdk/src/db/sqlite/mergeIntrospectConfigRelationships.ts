import { IntrospectConfig } from '~/config/index.js'
import { mapCommonTypesToAffinity } from './queries/fetchTablesAndColumns.js'
import type { Relationships, TableInfos } from './introspectSqliteDatabase.js'

function hasSameRelationship(
  relationships: Relationships,
  virtualKey: {
    fkTable: string
    targetTable: string
    keys: Array<{ fkColumn: string; targetColumn: string }>
  }
) {
  return relationships.some((relationship) => {
    // First check if the relationship is between the same tables
    if (
      relationship.fkTable !== virtualKey.fkTable ||
      relationship.targetTable !== virtualKey.targetTable
    ) {
      return false
    }
    // Then check if the relationship has the same number of keys
    if (relationship.keys.length !== virtualKey.keys.length) {
      return false
    }
    // Finally check if the relationship has the same keys
    return virtualKey.keys.every((key) => {
      return relationship.keys.some(
        (relationshipKey) =>
          relationshipKey.fkColumn === key.fkColumn &&
          relationshipKey.targetColumn === key.targetColumn
      )
    })
  })
}

function getIntrospectionColumnInfos(
  tables: TableInfos,
  tableName: string,
  columnName: string
) {
  return tables
    .find((table) => table.name === tableName)
    ?.columns.find((column) => column.name === columnName)
}

export function mergeConfigWithRelationshipsResult(
  introspectConfig: IntrospectConfig,
  relationships: Relationships,
  tables: TableInfos
): Relationships {
  if (!introspectConfig.virtualForeignKeys) {
    return relationships
  }
  const result = [...relationships]
  for (const virtualKey of introspectConfig.virtualForeignKeys) {
    const fkTable = tables.find((t) => t.id === virtualKey.fkTable)
    const targetTable = tables.find((t) => t.id === virtualKey.targetTable)
    if (!fkTable || !targetTable) {
      console.log(
        new Error(
          `Could not find table ${virtualKey.fkTable} or ${virtualKey.targetTable}`
        )
      )
      return relationships
    }
    const keys = virtualKey.keys
      // Check if the relationship seems valid
      .filter((key) => {
        const fkColumn = fkTable.columns.find((c) => c.name === key.fkColumn)
        const targetColumn = targetTable.columns.find(
          (c) => c.name === key.targetColumn
        )
        if (!fkColumn || !targetColumn) {
          console.log(
            new Error(
              `Could not find column ${key.fkColumn} or ${key.targetColumn} it will be skipped`
            )
          )
          return false
        }
        const isDuplicate = hasSameRelationship(relationships, virtualKey)
        if (isDuplicate) {
          console.log(
            new Error(
              `Duplicate relationship found for ${virtualKey.fkTable}.${virtualKey.targetTable} it will be skipped`
            )
          )
          return false
        }
        return true
      })
      // Augment the relationship with the column types
      .map((key) => {
        const fkColumnInfos = getIntrospectionColumnInfos(
          tables,
          fkTable.name,
          key.fkColumn
        )
        const targetColumnInfos = getIntrospectionColumnInfos(
          tables,
          targetTable.name,
          key.targetColumn
        )
        return {
          fkColumn: key.fkColumn,
          fkType: fkColumnInfos?.type ?? 'TEXT',
          fkAffinity: mapCommonTypesToAffinity(
            fkColumnInfos?.type ?? 'TEXT',
            fkColumnInfos?.nullable ?? true
          ),
          targetColumn: key.targetColumn,
          targetType: targetColumnInfos?.type ?? 'TEXT',
          targetAffinity: mapCommonTypesToAffinity(
            targetColumnInfos?.type ?? 'TEXT',
            fkColumnInfos?.nullable ?? true
          ),
          nullable: fkColumnInfos?.nullable ?? true,
        }
      })
    if (keys.length > 0) {
      result.push({
        id: `${virtualKey.fkTable}_${virtualKey.targetTable}_${virtualKey.keys
          .map((k) => `${k.fkColumn}_${k.targetColumn}`)
          .join('_')}_fkey`,
        fkTable: virtualKey.fkTable,
        keys,
        targetTable: virtualKey.targetTable,
      })
    }
  }
  return result
}
