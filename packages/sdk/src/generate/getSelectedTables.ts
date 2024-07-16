import { Configuration } from '../config/config.js'
import { calculateIncludedTables } from '../config/snapletConfig/v2/calculateIncludedTables.js'
import type { IntrospectedStructure } from '~/db/introspect/introspectDatabase.js'
interface GetSelectedTablesOptions {
  introspection: IntrospectedStructure
  config: Configuration
}

export interface SelectedTable {
  id: string
  schema: string
  name: string
}

export const getSelectedTables = async ({
  introspection,
  config,
}: GetSelectedTablesOptions): Promise<SelectedTable[]> => {
  return calculateIncludedTables(
    introspection['tables'],
    await config.getSchemas(),
    true
  ).map((table) => ({
    id: table.id ?? `${table.schema}.${table.name}`,
    name: table.name,
    schema: table.schema,
  }))
}
