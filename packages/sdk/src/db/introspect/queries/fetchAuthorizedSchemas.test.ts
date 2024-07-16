import { createTestDb, createTestRole } from '../../../testing.js'
import { execQueryNext, withDbClient } from '../../client.js'
import { fetchAuthorizedSchemas } from './fetchAuthorizedSchemas.js'

test('should fetch only the public schema', async () => {
  const connString = await createTestDb()
  const schemas = await withDbClient(fetchAuthorizedSchemas, {
    connString: connString.toString(),
  })
  expect(schemas).toEqual(['public'])
})

test('should fetch all schemas where the user can read', async () => {
  const structure = `
    CREATE SCHEMA other;
    CREATE SCHEMA private;
  `
  const connString = await createTestDb(structure)
  const testRoleConnString = await createTestRole(connString)
  await execQueryNext(
    `REVOKE ALL PRIVILEGES ON SCHEMA private FROM "${testRoleConnString.username}";
    GRANT ALL PRIVILEGES ON SCHEMA other TO "${testRoleConnString.username}";`,
    connString
  )
  const schemas = await withDbClient(fetchAuthorizedSchemas, {
    connString: testRoleConnString.toString(),
  })
  expect(schemas.length).toBe(2)
  expect(schemas).toEqual(expect.arrayContaining(['other', 'public']))
})
