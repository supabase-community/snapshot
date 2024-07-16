import { createTestDb, createTestRole } from '../../../testing.js'
import { execQueryNext, withDbClient } from '../../client.js'
import { fetchForbiddenSchemas } from './fetchForbiddenSchemas.js'

test('should return empty array since no schemas are forbidden', async () => {
  const connString = await createTestDb()
  const schemas = await withDbClient(fetchForbiddenSchemas, {
    connString: connString.toString(),
  })
  expect(schemas).toEqual([])
})

test('should fetch the forbidden schemas', async () => {
  const connectionString = await createTestDb()

  const restrictedString = await createTestRole(connectionString)
  const otherString = await createTestRole(connectionString)

  await execQueryNext(
    `CREATE SCHEMA "someSchema" AUTHORIZATION "${otherString.username}"`,
    connectionString
  )

  await execQueryNext(
    `CREATE TABLE "public"."table1" ("value" text)`,
    connectionString
  )

  await execQueryNext(
    `GRANT SELECT ON TABLE "public"."table1" TO "${restrictedString.username}"`,
    connectionString
  )

  await execQueryNext(
    `CREATE TABLE "someSchema"."table2" ("value" text)`,
    connectionString
  )

  const schemas = await withDbClient(fetchForbiddenSchemas, {
    connString: restrictedString.toString(),
  })

  expect(schemas).toEqual(['someSchema'])
})
