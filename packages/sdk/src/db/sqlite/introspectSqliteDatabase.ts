import { IntrospectConfig } from '~/config/index.js'
import { SqliteClient } from './client.js'
import { fetchServerVersion } from './queries/fetchServerVersion.js'
import { fetchTablesAndColumns } from './queries/fetchTablesAndColumns.js'
import { fetchDatabaseRelationships } from './queries/fetchDatabaseRelationships.js'
import { fetchUniqueConstraints } from './queries/fetchUniqueConstraints.js'
import { groupParentsChildrenRelations } from '../introspect/groupParentsChildrenRelations.js'
import { groupBy } from 'lodash'
import { fetchSequences } from './queries/fetchSequences.js'
import { AsyncFunctionSuccessType } from '~/types.js'
import { mergeConfigWithRelationshipsResult } from './mergeIntrospectConfigRelationships.js'
import { fetchPrimaryKeys } from './queries/fetchPrimaryKeys.js'

export type Relationships = AsyncFunctionSuccessType<
  typeof fetchDatabaseRelationships
>
export type TableInfos = AsyncFunctionSuccessType<typeof fetchTablesAndColumns>

export const basicIntrospectDatabase = async (client: SqliteClient) => {
  const tableInfos = await fetchTablesAndColumns(client)
  const version = await fetchServerVersion(client)
  return {
    server: {
      version,
    },
    tables: tableInfos,
  }
}

export const introspectSqliteDatabase = async (
  client: SqliteClient,
  introspectConfig?: IntrospectConfig
) => {
  const { tables: tablesInfos, server } = await basicIntrospectDatabase(client)
  const baseRelationships = await fetchDatabaseRelationships(client)
  const constraints = await fetchUniqueConstraints(client)
  const sequences = await fetchSequences(client)
  const primaryKeys = await fetchPrimaryKeys(client)
  const tableIds = tablesInfos.map((t) => t.id)
  const relationships = introspectConfig
    ? mergeConfigWithRelationshipsResult(
        introspectConfig,
        baseRelationships,
        tablesInfos
      )
    : baseRelationships
  const groupedRelationships = groupParentsChildrenRelations(
    relationships,
    tableIds
  )
  const groupedConstraints = groupBy(constraints, (c) => c.tableId)
  const groupedPrimaryKeys = groupBy(primaryKeys, (k) => k.tableId)
  const tablesWithRelations = tablesInfos.map((table) => {
    const tableRelations = groupedRelationships.get(table.id) || {
      parents: [],
      children: [],
    }
    const tableConstraints = groupedConstraints[table.id] || []
    const primaryKeys = groupedPrimaryKeys[table.id]?.[0] ?? null
    const columns = table.columns.map((column) => {
      const sequence = sequences.find(
        (s) => s.tableId === table.id && s.colId === column.name
      )
      return {
        ...column,
        identity: sequence
          ? {
              current: sequence.current,
              name: sequence.name,
              start: sequence.start,
              interval: sequence.interval,
              min: sequence.min,
              max: sequence.max,
            }
          : null,
      }
    })
    return {
      ...table,
      ...tableRelations,
      columns,
      constraints: tableConstraints,
      primaryKeys,
    }
  })
  return {
    server,
    tables: tablesWithRelations,
    sequences,
  }
}
