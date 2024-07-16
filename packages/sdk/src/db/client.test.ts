import { createTestDb } from '../testing/index.js'
import {
  withDbClient,
  getDbClient,
  createAdminDatabase,
  execQueryNext,
} from './client.js'

const stubEnvVars = () => {
  const original = process.env

  beforeEach(() => {
    process.env = Object.create(original)
  })

  afterEach(() => {
    process.env = original
  })
}

test('throws with bad db credentials', async () => {
  try {
    await createAdminDatabase(
      'postgresql://bad_username:bad_password@bad_hostname/bad_database'
    )
  } catch (e) {
    expect((e as Error).name).toEqual('DB_CONNECTION_AUTH')
  }
})

test('is able to get a connection', async () => {
  const connString = await createTestDb()
  const res = await execQueryNext('SELECT 1', connString)
  expect(res.rowCount).toEqual(1)
})

describe('withDbClient', () => {
  test("releasing the client after the function's result has resolved", async () => {
    const connString = await createTestDb()
    const client = await getDbClient(connString.toString())
    const endSpy = vi.spyOn(client, 'release')

    const result = await withDbClient(
      (client) => client.query('SELECT 1 FROM pg_database LIMIT 1'),
      {
        client,
      }
    )

    expect(Object.values(result.rows[0])).toEqual([1])
    expect(endSpy).toHaveBeenCalled()
  })

  test('releasing the client on error', async () => {
    const connString = await createTestDb()
    const client = await getDbClient(connString.toString())
    const endSpy = vi.spyOn(client, 'release')

    await expect(
      withDbClient(
        () => {
          throw new Error(':o')
        },
        {
          client,
        }
      )
    ).rejects.toEqual(new Error(':o'))

    expect(endSpy).toHaveBeenCalled()
  })
})

describe('execQueryNext', () => {
  stubEnvVars()

  test('executes the query', async () => {
    const connString = await createTestDb()
    const result = await execQueryNext(
      'SELECT 1 FROM pg_database LIMIT 1',
      connString
    )
    expect(Object.values(result.rows[0])).toEqual([1])
  })

  test('test stringParserEnabled', async () => {
    const testDbConnString = await createTestDb()
    process.env.SNAPLET_TARGET_DATABASE_URL = testDbConnString
      .setDatabase(testDbConnString.database)
      .toString()

    await execQueryNext(
      `CREATE TABLE test_table (id SERIAL PRIMARY KEY, date_col DATE)`,
      testDbConnString
    )
    await execQueryNext(
      `INSERT INTO test_table (date_col) VALUES ('2021-01-01')`,
      testDbConnString
    )
    const selectSql = `SELECT date_col FROM test_table LIMIT 1`

    const {
      rows: [{ date_col: result }],
    } = await execQueryNext(selectSql, testDbConnString)
    expect(typeof result).toEqual('object')

    const {
      rows: [{ date_col: result2 }],
    } = await execQueryNext(selectSql, testDbConnString, undefined, true)
    expect(typeof result2).toEqual('string')

    const {
      rows: [{ date_col: result3 }],
    } = await execQueryNext(selectSql, testDbConnString)
    expect(typeof result3).toEqual('object')
  })

  test('test rawMode enabled and disabled with concurrent queries', async () => {
    const structure = `
      CREATE TABLE test_table (id SERIAL PRIMARY KEY, date_col DATE);
      INSERT INTO test_table (date_col) VALUES ('2021-01-01');
    `
    const testDbConnString = await createTestDb(structure)
    process.env.SNAPLET_TARGET_DATABASE_URL = testDbConnString
      .setDatabase(testDbConnString.database)
      .toString()
    const selecQuery = `SELECT date_col FROM test_table LIMIT 1`
    const objectParsedPromises = Array.from({ length: 10 }).map(() =>
      execQueryNext(selecQuery, testDbConnString)
    )
    const rawModePromises = Array.from({ length: 10 }).map(() =>
      execQueryNext(selecQuery, testDbConnString, undefined, true)
    )
    const [objectParsedResults, rawModeResults] = await Promise.all([
      Promise.all(objectParsedPromises),
      Promise.all(rawModePromises),
    ])
    expect(
      objectParsedResults.every(
        ({ rows: [{ date_col }] }) => typeof date_col === 'object'
      )
    ).toEqual(true)
    expect(
      rawModeResults.every(
        ({ rows: [{ date_col }] }) => typeof date_col === 'string'
      )
    ).toEqual(true)
  })
})
