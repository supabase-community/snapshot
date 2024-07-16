import { createTestDb, createTestRole } from '../../../testing.js'
import { execQueryNext, withDbClient } from '../../client.js'
import { fetchForbiddenTablesIds } from './fetchForbiddenTablesIds.js'

test('should return empty array since nothing forbidden', async () => {
  const connString = await createTestDb()
  const tableIds = await withDbClient(fetchForbiddenTablesIds, {
    connString: connString.toString(),
  })
  expect(tableIds).toEqual([])
})

test('should fetch the forbidden tables from private schema', async () => {
  const structure = `
    CREATE SCHEMA private;
  `
  const connString = await createTestDb(structure)
  const testRoleConnString = await createTestRole(connString)
  await execQueryNext(
    `
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "${testRoleConnString.username}";
      CREATE TABLE public."publicTable" (id SERIAL PRIMARY KEY);
      CREATE TABLE public."privateInPublic" (id SERIAL PRIMARY KEY);
      CREATE TABLE private."table2" (id SERIAL PRIMARY KEY);
      REVOKE ALL PRIVILEGES ON TABLE public."privateInPublic" FROM "${testRoleConnString.username}";
    `,
    connString
  )
  const tableIds = await withDbClient(fetchForbiddenTablesIds, {
    connString: testRoleConnString.toString(),
  })
  expect(tableIds).toEqual(['private.table2', 'public.privateInPublic'])
})

test('tables the user cannot access', async () => {
  const connectionString = await createTestDb()

  const restrictedString = await createTestRole(connectionString)
  const otherString = await createTestRole(connectionString)

  await execQueryNext(
    `CREATE TABLE "public"."table1" ("value" text)`,
    connectionString
  )

  await execQueryNext(
    `GRANT SELECT ON TABLE "public"."table1" TO "${restrictedString.username}"`,
    connectionString
  )

  await execQueryNext(
    `CREATE TABLE "public"."table2" ("value" text)`,
    connectionString
  )

  await execQueryNext(
    `CREATE SCHEMA "someSchema" AUTHORIZATION "${otherString.username}"`,
    connectionString
  )

  await execQueryNext(
    `CREATE TABLE "someSchema"."table3" ("value" text)`,
    connectionString
  )

  const tables = await withDbClient(fetchForbiddenTablesIds, {
    connString: restrictedString.toString(),
  })

  expect(tables).toEqual([`public.table2`, `someSchema.table3`])
})
