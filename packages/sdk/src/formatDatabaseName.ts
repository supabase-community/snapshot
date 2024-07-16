import { kebabCase } from 'lodash'

export function formatDatabaseName(databaseName: string) {
  // postgresql maximum identifier length is 63 characters
  return kebabCase(databaseName.trim()).slice(0, 63)
}
