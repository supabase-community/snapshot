import { createTestDb, createTestRole } from '../../../testing.js'
import { withDbClient } from '../../client.js'
import { fetchAuthorizedExtensions } from './fetchAuthorizedExtensions.js'

test('should fetch basic extensions', async () => {
  const structure = `
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
  `
  const connString = await createTestDb(structure)
  const extensions = await withDbClient(fetchAuthorizedExtensions, {
    connString: connString.toString(),
  })
  expect(extensions).toEqual([
    {
      name: 'uuid-ossp',
      version: expect.stringMatching(/\d+\.\d+/),
      schema: 'public',
    },
  ])
})

test('should not fetch extensions on schemas the user does not have access to', async () => {
  const structure = `
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
    CREATE SCHEMA private;
    CREATE EXTENSION IF NOT EXISTS "hstore" WITH SCHEMA private;
  `
  const connString = await createTestDb(structure)
  const testRoleConnString = await createTestRole(connString)
  const extensions = await withDbClient(fetchAuthorizedExtensions, {
    connString: testRoleConnString.toString(),
  })
  expect(extensions).toEqual([
    {
      name: 'uuid-ossp',
      version: expect.stringMatching(/\d+\.\d+/),
      schema: 'public',
    },
  ])
})

test('should fetch multiple extensions', async () => {
  const structure = `
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
    CREATE EXTENSION IF NOT EXISTS "hstore" WITH SCHEMA public;
  `
  const connString = await createTestDb(structure)
  const extensions = await withDbClient(fetchAuthorizedExtensions, {
    connString: connString.toString(),
  })
  expect(extensions).toEqual(
    expect.arrayContaining([
      {
        name: 'uuid-ossp',
        version: expect.stringMatching(/\d+\.\d+/),
        schema: 'public',
      },
      {
        name: 'hstore',
        version: expect.stringMatching(/\d+\.\d+/),
        schema: 'public',
      },
    ])
  )
})

test('should fetch extensions from multiple schemas', async () => {
  const structure = `
    CREATE SCHEMA schema1;
    CREATE SCHEMA schema2;
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA schema1;
    CREATE EXTENSION IF NOT EXISTS "hstore" WITH SCHEMA schema2;
  `
  const connString = await createTestDb(structure)
  const extensions = await withDbClient(fetchAuthorizedExtensions, {
    connString: connString.toString(),
  })
  expect(extensions).toEqual(
    expect.arrayContaining([
      {
        name: 'uuid-ossp',
        version: expect.stringMatching(/\d+\.\d+/),
        schema: 'schema1',
      },
      {
        name: 'hstore',
        version: expect.stringMatching(/\d+\.\d+/),
        schema: 'schema2',
      },
    ])
  )
})

test('should handle empty result when no accessible extensions', async () => {
  const structure = ``
  const connString = await createTestDb(structure)
  const extensions = await withDbClient(fetchAuthorizedExtensions, {
    connString: connString.toString(),
  })
  expect(extensions).toEqual([])
})
