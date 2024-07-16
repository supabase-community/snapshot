import { IntrospectedStructure } from '../../db/introspect/introspectDatabase.js'
import {
  calculateIncludedSchemas,
  calculateIncludedTables,
} from './v2/calculateIncludedTables.js'

test('calculate the schemas to be dumped', async () => {
  const structure = {
    schemas: ['public', 'auth', 'functions'],
  } as IntrospectedStructure

  const schemaConfig = {
    functions: false,
    extensions: {
      extensions: {
        pg_crypto: false,
      },
    },
  }
  const schemas = calculateIncludedSchemas(structure['schemas'], schemaConfig)
  expect(schemas).toMatchInlineSnapshot(`
    [
      "public",
      "auth",
    ]
  `)
})

test('calculate the tables to be copied', async () => {
  const structure = {
    schemas: ['public', 'auth', 'functions'],
    tables: [
      {
        name: 'User',
        schema: 'public',
      },
      {
        name: 'AccessToken',
        schema: 'public',
      },
      {
        name: 'Test',
        schema: 'functions',
      },
    ],
  } as IntrospectedStructure

  const schemaConfig = {
    functions: false,
    public: {
      AccessToken: false,
    },
  }

  const tablesToCopy = calculateIncludedTables(
    structure['tables'],
    schemaConfig
  )

  expect(tablesToCopy.map(({ name, schema }) => ({ name, schema })))
    .toMatchInlineSnapshot(`
      [
        {
          "name": "User",
          "schema": "public",
        },
      ]
    `)
})
