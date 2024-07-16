import { execQueryNext } from '../db/client.js'
import { ConnectionString } from '../db/connString/ConnectionString.js'
import { SelectedTable } from './getSelectedTables.js'

interface ClearDbOptions {
  connectionString: ConnectionString
  selectedTables: SelectedTable[]
}

export const clearDb = async ({
  selectedTables,
  connectionString,
}: ClearDbOptions) => {
  for (const table of selectedTables) {
    await execQueryNext(
      `TRUNCATE TABLE "${table.schema}"."${table.name}" CASCADE`,
      connectionString
    )
  }
}
