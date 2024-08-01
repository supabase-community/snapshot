import { createTestDb } from '../testing/index.js'

import { endAllPools, execQueryNext, withDbClient } from '../db/client.js'
import { ConnectionString } from '../db/connString/index.js'
import { subsetStartTable } from './startTable.js'
import { introspectDatabaseV3 } from '../db/introspect/introspectDatabase.js'

describe('startTable', () => {

  test('detect start table on Custom Db', async () => {
    const connStr: ConnectionString = await createTestDb()
    const sqlOrgCreate = `
    CREATE TABLE media (
      id SERIAL PRIMARY KEY,
      name text NOT NULL
    )`
    await execQueryNext(sqlOrgCreate, connStr)
    const sqlUserAccountCreate = `
      CREATE TABLE storage (
        id SERIAL PRIMARY KEY,
        name text NOT NULL
      )`
    await execQueryNext(sqlUserAccountCreate, connStr)
    const sqlUserCreate = `
      CREATE TABLE "myUsers" (
        id SERIAL PRIMARY KEY,
        name text NOT NULL,
        media_id integer NOT NULL REFERENCES media,
        storage_id integer NOT NULL REFERENCES storage
      )`
    await execQueryNext(sqlUserCreate, connStr)
    const structure = await withDbClient(introspectDatabaseV3, {
      connString: connStr.toString(),
    })
    const startTable = subsetStartTable(structure)
    expect(startTable.id).toBe('public.myUsers')
    // TODO: (avallete) find out why putting this into an afterAll/afterEach
    // doesn't work, when putting it at the end of the test itself work
    await endAllPools()
  })
})
