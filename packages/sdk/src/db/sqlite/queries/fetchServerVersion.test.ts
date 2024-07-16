import { createSqliteTestDatabase } from '~/testing/createSqliteDb.js'
import { withDbClient } from '../client.js'
import { fetchServerVersion } from './fetchServerVersion.js'

test('should retrieve server version', async () => {
  const structure = `
    CREATE TABLE "Courses" (
        "CourseID" VARCHAR(255) PRIMARY KEY,
        "CourseName" VARCHAR(255) NOT NULL
    ) WITHOUT ROWID;
  `
  const connString = await createSqliteTestDatabase(structure)
  const serverVersion = await withDbClient(fetchServerVersion, {
    connString: connString.toString(),
  })
  expect(serverVersion).toMatch(/\d+\.\d+/)
})
