import { createTestDb } from '../../testing.js'
import { execQueryNext, withDbClient } from '../client.js'
import { fetchAuthorizedSequences } from './queries/fetchAuthorizedSequences.js'
import { fixSequences } from './fixSequences.js'

test('should fix sequences for multiple tables', async () => {
  const structure = `
    CREATE TABLE public."Table1" (id serial PRIMARY KEY, name text);
    CREATE TABLE public."Table2" (id serial PRIMARY KEY, name text);

    INSERT INTO public."Table1" (id, name) VALUES (5, 'A');
    INSERT INTO public."Table2" (id, name) VALUES (3, 'B');
  `
  const connString = await createTestDb(structure)
  const sequences = await withDbClient(fetchAuthorizedSequences, {
    connString: connString.toString(),
  })
  await fixSequences(connString, sequences)

  const checkSequence1 = `
    SELECT nextval(pg_get_serial_sequence('public."Table1"', 'id'))
  `
  const checkSequence2 = `
    SELECT nextval(pg_get_serial_sequence('public."Table2"', 'id'))
  `

  const [nextVal1, nextVal2] = await Promise.all([
    await execQueryNext(checkSequence1, connString),
    await execQueryNext(checkSequence2, connString),
  ])

  expect(nextVal1.rows?.[0].nextval).toBe('6')
  expect(nextVal2.rows?.[0].nextval).toBe('4')
})

test('fix sequences', async () => {
  const structure = `
    CREATE TABLE public."SequenceTest" (id serial PRIMARY KEY, name text);
  `
  const connString = await createTestDb(structure)

  await execQueryNext(
    `SELECT setval('public."SequenceTest_id_seq"', 100, false);`,
    connString
  )
  const x = await execQueryNext(
    `SELECT nextval('public."SequenceTest_id_seq"');`,
    connString
  )
  expect(x.rows?.[0]?.nextval).toEqual('100')

  const sequences = await withDbClient(fetchAuthorizedSequences, {
    connString: connString.toString(),
  })
  await fixSequences(connString, sequences)

  const y = await execQueryNext(
    `SELECT nextval('public."SequenceTest_id_seq"');`,
    connString
  )
  expect(y.rows?.[0]?.nextval).toEqual('1')
})

test('should handle empty input array', async () => {
  const connString = await createTestDb('')
  await expect(fixSequences(connString, [])).resolves.not.toThrow()
})
