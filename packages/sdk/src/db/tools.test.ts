import { sortBy } from 'lodash'

import { createTestRole, createTestDb } from '../testing/index.js'
import { execQueryNext, withDbClient } from './client.js'
import { resetDb, dbExistsNext, clearDb } from './tools.js'

describe('dbExistsNext', () => {
  test('determines whether db exists', async () => {
    const connectionString = await createTestDb()
    expect(await dbExistsNext(connectionString.setDatabase('postgres'))).toBe(
      true
    )
    expect(await dbExistsNext(connectionString.setDatabase('okereke'))).toBe(
      false
    )
  })
})

describe('resetDb', () => {
  test('clears everything in the DB', async () => {
    const connString = await createTestDb()
    await execQueryNext(`CREATE SCHEMA "skiba"`, connString)
    await execQueryNext(
      `CREATE TABLE "public"."foo" ("a" integer, "b" integer)`,
      connString
    )
    await execQueryNext(
      `CREATE TABLE "skiba"."bar" ("c" integer, "d" integer)`,
      connString
    )

    await expect(
      execQueryNext(`SELECT * FROM "public"."foo"`, connString)
    ).resolves.toEqual(expect.anything())
    await expect(
      execQueryNext(`SELECT * FROM "skiba"."bar"`, connString)
    ).resolves.toEqual(expect.anything())
    await resetDb(connString)
    await expect(
      execQueryNext(`SELECT * FROM "public"."foo"`, connString)
    ).rejects.toThrow()
    await expect(
      execQueryNext(`SELECT * FROM "skiba"."bar"`, connString)
    ).rejects.toThrow()
  })

  test('tries clear schemas where user is not the owner', async () => {
    const connectionString = await createTestDb()
    const ownerString = await createTestRole(connectionString)
    const otherString = await createTestRole(connectionString)

    await execQueryNext('DROP SCHEMA public CASCADE', connectionString)

    await execQueryNext(
      `GRANT CREATE ON DATABASE "${connectionString.database}" TO "${otherString.username}"`,
      connectionString
    )

    await execQueryNext(
      `CREATE SCHEMA "perm" AUTHORIZATION "${otherString.username}"`,
      connectionString
    )

    await execQueryNext(
      `CREATE SCHEMA "someperm" AUTHORIZATION "${ownerString.username}"`,
      connectionString
    )

    await execQueryNext(
      `CREATE SCHEMA "noperm" AUTHORIZATION "${ownerString.username}"`,
      connectionString
    )

    await execQueryNext(
      `CREATE TABLE "perm"."test" ("value" text)`,
      connectionString
    )

    await execQueryNext(
      `CREATE TABLE "someperm"."test" ("value" text)`,
      connectionString
    )

    await execQueryNext(
      `CREATE TABLE "noperm"."test" ("value" text)`,
      connectionString
    )

    await execQueryNext(
      `INSERT INTO "perm"."test" VALUES ('perm')`,
      connectionString
    )

    await execQueryNext(
      `INSERT INTO "someperm"."test" VALUES ('some-perm')`,
      connectionString
    )

    await execQueryNext(
      `INSERT INTO "noperm"."test" VALUES ('no-perm')`,
      connectionString
    )

    await execQueryNext(
      `GRANT USAGE ON SCHEMA "noperm" TO "${otherString.username}"`,
      connectionString
    )

    await execQueryNext(
      `GRANT USAGE ON SCHEMA "someperm" TO "${otherString.username}"`,
      connectionString
    )

    await execQueryNext(
      `GRANT ALL PRIVILEGES ON SCHEMA "perm" TO "${otherString.username}"`,
      connectionString
    )

    await execQueryNext(
      `GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA "someperm" TO "${otherString.username}"`,
      connectionString
    )

    const errors = await resetDb(otherString)

    expect(sortBy(errors, 'message')).toEqual(
      expect.arrayContaining([
        expect.stringContaining('"someperm"'),
        expect.stringContaining('"noperm"'),
        expect.stringContaining('"noperm"."test"'),
      ])
    )

    await expect(
      execQueryNext(`SELECT * FROM "someperm"."test"`, connectionString)
    ).resolves.toEqual(expect.anything())
    await expect(
      execQueryNext(`SELECT * FROM "noperm"."test"`, connectionString)
    ).resolves.toEqual(expect.anything())
    expect(
      (await execQueryNext('SELECT * from "someperm"."test"', connectionString))
        .rows
    ).toEqual([])

    expect(
      (await execQueryNext('SELECT * from "noperm"."test"', connectionString))
        .rows
    ).toEqual([
      {
        value: 'no-perm',
      },
    ])
  })
})

describe('clearDb', () => {
  test('clears all schemas', async () => {
    const connectionString = await createTestDb()

    await execQueryNext(`CREATE SCHEMA "other"`, connectionString)

    await execQueryNext(
      `CREATE TABLE "public"."a" ("value" text)`,
      connectionString
    )
    await execQueryNext(
      `CREATE TABLE "other"."b" ("value" text)`,
      connectionString
    )

    await execQueryNext(
      `INSERT INTO "public"."a" VALUES ('a')`,
      connectionString
    )

    await execQueryNext(
      `INSERT INTO "other"."b" VALUES ('b')`,
      connectionString
    )

    expect(
      (await execQueryNext('SELECT * from "public"."a"', connectionString)).rows
    ).toEqual([{ value: 'a' }])

    expect(
      (await execQueryNext('SELECT * from "other"."b"', connectionString)).rows
    ).toEqual([{ value: 'b' }])

    await withDbClient((client) => clearDb(client), {
      connString: connectionString.toString(),
    })

    expect(
      (await execQueryNext('SELECT * from "public"."a"', connectionString)).rows
    ).toEqual([])

    expect(
      (await execQueryNext('SELECT * from "other"."b"', connectionString)).rows
    ).toEqual([])
  })
})
