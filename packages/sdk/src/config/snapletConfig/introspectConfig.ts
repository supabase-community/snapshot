import { z, ZodError } from 'zod'
import {
  IntrospectedStructureBase,
  Relationships,
} from '../../db/introspect/introspectDatabase.js'

export const introspectConfigSchema = z.object({
  virtualForeignKeys: z
    .array(
      z.object({
        fkTable: z.string(),
        targetTable: z.string(),
        keys: z
          .array(
            z.object({
              fkColumn: z.string(),
              targetColumn: z.string(),
            })
          )
          .min(1),
      })
    )
    .optional(),
})

export type IntrospectConfig = z.infer<typeof introspectConfigSchema>

export function parseIntrospectConfig(config: Record<string, unknown>) {
  try {
    return introspectConfigSchema.parse(config)
  } catch (e) {
    if (e instanceof ZodError) {
      throw new Error(`Could not parse introspect config: ${e.message}`)
    }
    throw e
  }
}

function getIntrospectionColumnInfos(
  tables: IntrospectedStructureBase['tables'],
  schema: string,
  tableName: string,
  columnName: string
) {
  return tables
    .find((table) => table.schema === schema && table.name === tableName)
    ?.columns.find((column) => column.name === columnName)
}

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

export function mergeConfigWithRelationshipsResult(
  introspectConfig: IntrospectConfig,
  introspection: {
    relationships: Relationships
    tables: IntrospectedStructureBase['tables']
  }
): Relationships {
  if (!introspectConfig.virtualForeignKeys) {
    return introspection.relationships
  }
  // Clone the relationships array
  const result = [...introspection.relationships]
  for (const virtualKey of introspectConfig.virtualForeignKeys) {
    const fkTable = introspection.tables.find(
      (t) => t.id === virtualKey.fkTable
    )
    const targetTable = introspection.tables.find(
      (t) => t.id === virtualKey.targetTable
    )
    if (!fkTable || !targetTable) {
      console.log(
        new Error(
          `Could not find table ${virtualKey.fkTable} or ${virtualKey.targetTable}`
        )
      )
      return introspection.relationships
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
        const isDuplicate = hasSameRelationship(
          introspection.relationships,
          virtualKey
        )
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
          introspection.tables,
          fkTable.schema,
          fkTable.name,
          key.fkColumn
        )
        const targetColumnInfos = getIntrospectionColumnInfos(
          introspection.tables,
          targetTable.schema,
          targetTable.name,
          key.targetColumn
        )
        return {
          fkColumn: key.fkColumn,
          fkType: fkColumnInfos?.type ?? 'text',
          targetColumn: key.targetColumn,
          targetType: targetColumnInfos?.type ?? 'text',
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
