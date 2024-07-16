import { createTestDb, createTestRole } from '../../../testing.js'
import { withDbClient } from '../../client.js'
import { fetchAuthorizedEnums } from './fetchAuthorizedEnums.js'

test('should fetch basic enums', async () => {
  const structure = `
    CREATE TYPE public."enum_example" AS ENUM ('A', 'B', 'C');
  `
  const connString = await createTestDb(structure)
  const enums = await withDbClient(fetchAuthorizedEnums, {
    connString: connString.toString(),
  })
  expect(enums).toEqual([
    {
      id: 'public.enum_example',
      schema: 'public',
      name: 'enum_example',
      values: expect.arrayContaining(['A', 'B', 'C']),
    },
  ])
})

test('should not fetch enums on schemas the user does not have access to', async () => {
  const structure = `
    CREATE TYPE public."enum_example" AS ENUM ('A', 'B', 'C');
    CREATE SCHEMA private;
    CREATE TYPE private."enum_example_private" AS ENUM ('D', 'E', 'F');
  `
  const connString = await createTestDb(structure)
  const testRoleConnString = await createTestRole(connString)
  const enums = await withDbClient(fetchAuthorizedEnums, {
    connString: testRoleConnString.toString(),
  })
  expect(enums).toEqual([
    {
      id: 'public.enum_example',
      schema: 'public',
      name: 'enum_example',
      values: expect.arrayContaining(['A', 'B', 'C']),
    },
  ])
})

test('should fetch multiple enums', async () => {
  const structure = `
    CREATE TYPE public."enum_example1" AS ENUM ('A', 'B', 'C');
    CREATE TYPE public."enum_example2" AS ENUM ('D', 'E', 'F');
  `
  const connString = await createTestDb(structure)
  const enums = await withDbClient(fetchAuthorizedEnums, {
    connString: connString.toString(),
  })
  expect(enums).toEqual(
    expect.arrayContaining([
      {
        id: 'public.enum_example1',
        schema: 'public',
        name: 'enum_example1',
        values: expect.arrayContaining(['A', 'B', 'C']),
      },
      {
        id: 'public.enum_example2',
        schema: 'public',
        name: 'enum_example2',
        values: expect.arrayContaining(['D', 'E', 'F']),
      },
    ])
  )
})

test('should handle empty result when no accessible enums', async () => {
  const structure = ``
  const connString = await createTestDb(structure)
  const enums = await withDbClient(fetchAuthorizedEnums, {
    connString: connString.toString(),
  })
  expect(enums).toEqual([])
})
