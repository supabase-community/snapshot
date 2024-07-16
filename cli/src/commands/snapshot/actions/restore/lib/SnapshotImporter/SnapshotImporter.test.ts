import { ConnectionString } from '@snaplet/sdk/cli'
import path from 'path'

import { createTestDb } from '~/testing/index.js'

import SnapshotImporter from './SnapshotImporter.js'
import { getSnapshotColumns } from './importTablesData.js'

const FIXTURES_PATH = path.resolve(
  __dirname,
  '../../../../../../../__fixtures__'
)

describe('Snapshot Importer', () => {
  let CONNECTION_STRING: ConnectionString

  beforeEach(async () => {
    CONNECTION_STRING = await createTestDb()
  })

  test('import schema with syntax errors', async () => {
    const importer = new SnapshotImporter({
      connString: CONNECTION_STRING.toString(),
      //@ts-expect-error
      summary: {},
      cache: {
        //@ts-expect-error
        paths: {
          schemas: path.join(
            FIXTURES_PATH,
            'badSchema/schema-with-syntax-error.sql'
          ),
          tables: '',
        },
      },
    })
    const errors: any[] = []
    importer.on('importSchema:statementError', (payload) => {
      errors.push(payload.error)
    })
    await importer.importSchema()
    expect(errors.length).toBe(1)
    expect(errors[0].message).toMatchInlineSnapshot(
      `"syntax error at or near \\"XXX\\""`
    )
  })

  test('import schema with missing dependency', async () => {
    const importer = new SnapshotImporter({
      connString: CONNECTION_STRING.toString(),
      //@ts-expect-error
      summary: {},
      cache: {
        //@ts-expect-error
        paths: {
          schemas: path.join(
            FIXTURES_PATH,
            'badSchema/schema-with-missing-dependency.sql'
          ),
          tables: '',
        },
      },
    })
    const errors: any[] = []
    importer.on('importSchema:statementError', (payload) => {
      errors.push(payload.error)
    })
    await importer.importSchema()
    expect(errors.length).toBe(1)
    expect(errors[0].message).toMatchInlineSnapshot(
      `"type \\"isbn\\" does not exist"`
    )
  })
})

test('get csv header', async () => {
  const f = path.join(FIXTURES_PATH, 'public-example-table.csv')
  const columns = await getSnapshotColumns(f)
  expect(columns).toMatchInlineSnapshot(`
    [
      "country",
      "country_id",
      "last_update",
    ]
  `)
})
