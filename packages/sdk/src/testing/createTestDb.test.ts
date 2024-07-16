import { dbExistsNext } from '../db/tools.js'
import { defineCreateTestDb } from './createTestDb.js'

describe('createTestDb', () => {
  test('creates a test db', async () => {
    const state = { dbNames: [] }
    const createTestDb = defineCreateTestDb(state)
    const connString = await createTestDb()
    expect(await dbExistsNext(connString)).toBe(true)
    await createTestDb.afterEach()
  })

  test('drops db after each test run', async () => {
    const state = { dbNames: [] }
    const createTestDb = defineCreateTestDb(state)

    const connString = await createTestDb()
    await createTestDb.afterEach()

    expect(await dbExistsNext(connString)).toBe(false)
  })
})
