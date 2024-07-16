import { ConnectionString } from '../db/connString/ConnectionString.js'
import { execQueryNext, withDbClient } from '../db/client.js'
import { getSelectedTables } from './getSelectedTables.js'
import { createTestDb } from '~/testing/createTestDb.js'
import { introspectDatabaseV3 } from '../db/introspect/introspectDatabase.js'
import { Configuration } from '~/config/config.js'

const createOptions = async ({
  select = {},
  connectionString,
}: {
  connectionString: ConnectionString
  // todo(justinvdm, 10 Aug 2023): Use better type once we have one for `select`
  select: object
}) => {
  const introspection = await withDbClient(introspectDatabaseV3, {
    connString: connectionString.toString(),
  })

  const source = `
    import { defineConfig } from 'snaplet'
    export default defineConfig({
      select: ${JSON.stringify(select)}
    })
    `

  const config = new Configuration()
  await config.init(source)

  return {
    connectionString,
    introspection,
    config,
  }
}

describe('getSelectedTables', () => {
  test('includes tables not specified in select config', async () => {
    const connectionString = await createTestDb()
    await execQueryNext(
      `CREATE TABLE "Tmp" (
         value int
      )`,
      connectionString
    )
    await execQueryNext(
      `INSERT INTO "Tmp" VALUES (
        23
      )`,
      connectionString
    )
    const options = await createOptions({
      connectionString,
      select: {},
    })

    expect(await getSelectedTables(options)).toEqual(
      expect.arrayContaining([
        {
          id: 'public.Tmp',
          schema: 'public',
          name: 'Tmp',
        },
      ])
    )
  })

  test('includes tables specified as `true` in select config', async () => {
    const connectionString = await createTestDb()
    await execQueryNext(
      `CREATE TABLE "Tmp" (
         value int
      )`,
      connectionString
    )
    await execQueryNext(
      `INSERT INTO "Tmp" VALUES (
        23
      )`,
      connectionString
    )
    const options = await createOptions({
      connectionString,
      select: {
        public: {
          Tmp: true,
        },
      },
    })

    expect(await getSelectedTables(options)).toEqual(
      expect.arrayContaining([
        {
          id: 'public.Tmp',
          schema: 'public',
          name: 'Tmp',
        },
      ])
    )
  })

  test('does not include tables specific as `false` in select config', async () => {
    const connectionString = await createTestDb()
    await execQueryNext(
      `CREATE TABLE "Tmp" (
         value int
      )`,
      connectionString
    )
    await execQueryNext(
      `INSERT INTO "Tmp" VALUES (
        23
      )`,
      connectionString
    )
    const options = await createOptions({
      connectionString,
      select: {
        public: {
          Tmp: false,
        },
      },
    })

    expect(await getSelectedTables(options)).not.toEqual(
      expect.arrayContaining([
        {
          id: 'public.Tmp',
          schema: 'public',
          name: 'Tmp',
        },
      ])
    )
  })

  test("does include tables specific as 'structure' in select config", async () => {
    const connectionString = await createTestDb()
    await execQueryNext(
      `CREATE TABLE "Tmp" (
         value int
      )`,
      connectionString
    )
    await execQueryNext(
      `INSERT INTO "Tmp" VALUES (
        23
      )`,
      connectionString
    )
    const options = await createOptions({
      connectionString,
      select: {
        public: {
          Tmp: 'structure',
        },
      },
    })

    expect(await getSelectedTables(options)).toEqual(
      expect.arrayContaining([
        {
          id: 'public.Tmp',
          schema: 'public',
          name: 'Tmp',
        },
      ])
    )
  })
})
