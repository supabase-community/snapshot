import { execQueryNext } from '../db/sqlite/client.js'
import { copyFile } from 'fs-extra'
import path from 'path'
import { createTestTmpDirectory } from './createTestTmpDirectory.js'

const CHINOOK_DATABASE_PATH = path.resolve(
  __dirname,
  '../../__fixtures__/sqlite/chinook.db'
)

export async function createSqliteTestDatabase(structure: string) {
  const tmp = await createTestTmpDirectory()
  const connString = path.join(tmp.name, 'test.sqlite3')
  await execQueryNext(structure, connString)
  return connString
}

// A sample database with data in it took from: https://www.sqlitetutorial.net/sqlite-sample-database/
export async function createChinookSqliteTestDatabase() {
  const tmp = await createTestTmpDirectory()
  const connString = path.join(tmp.name, 'chinook.sqlite3')
  // copy chinook database to tmp directory
  await copyFile(CHINOOK_DATABASE_PATH, connString)
  return connString
}
