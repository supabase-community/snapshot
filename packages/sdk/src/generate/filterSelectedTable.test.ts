import { execQueryNext, withDbClient } from '../db/client.js'
import { createTestDb } from '~/testing/index.js'
import { filterSelectedTables } from './filterSelectedTables.js'
import { introspectDatabaseV3 } from '../db/introspect/introspectDatabase.js'

describe('filterSelectedTables', () => {
  test('excludes all references of unselected tables', async () => {
    const connectionString = await createTestDb()
    await execQueryNext(
      `
      CREATE TABLE "Foo" (
        "id" int,
        "barId" int
      );

      CREATE TABLE "Bar" (
        "id" int,
        "bazId" int
      );

      CREATE TABLE "Baz" (id int);

      ALTER TABLE "Foo" ADD CONSTRAINT "Foo_pkey" PRIMARY KEY ("id");

      ALTER TABLE "Bar" ADD CONSTRAINT "Bar_pkey" PRIMARY KEY ("id");

      ALTER TABLE "Baz" ADD CONSTRAINT "Baz_pkey" PRIMARY KEY ("id");

      ALTER TABLE "Foo" ADD CONSTRAINT "Foo_barId_fkey" FOREIGN KEY ("barId") REFERENCES "Bar"("id");

      ALTER TABLE "Bar" ADD CONSTRAINT "Bar_bazId_fkey" FOREIGN KEY ("bazId") REFERENCES "Baz"("id");`,
      connectionString
    )

    const introspection = await withDbClient(introspectDatabaseV3, {
      connString: connectionString.toString(),
    })

    const result = filterSelectedTables({
      introspection,
      selectedTables: [
        {
          id: 'public.Foo',
          name: 'Foo',
          schema: 'public',
        },
        {
          id: 'public.Baz',
          name: 'Baz',
          schema: 'public',
        },
      ],
    })

    const serializedResult = JSON.stringify(result, null, 2)
    expect(serializedResult).toContain('Foo')
    expect(serializedResult).toContain('Baz')
    expect(serializedResult).not.toContain('Bar')
  })
})
