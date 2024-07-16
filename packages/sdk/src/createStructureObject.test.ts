import { createStructureObject } from './createStructureObject.js'
import { IntrospectedStructure } from './db/introspect/introspectDatabase.js'

test('generate the structure object', () => {
  const structure = {
    schemas: ['public'],
    tables: [
      {
        schema: 'public',
        name: 'User',
        columns: [
          {
            name: 'id',
            type: 'integer',
          },
          {
            name: 'status',
            type: 'Status',
          },
        ],
      },
    ],
    enums: [
      {
        schema: 'public',
        name: 'Status',
        values: ['YES', 'NO'],
      },
    ],
  } as IntrospectedStructure

  const g = createStructureObject(structure)

  expect(g).toMatchObject({
    $schemas: ['public'],
    public: {
      $tables: ['User'],
      User: {
        $columns: ['id', 'status'],
        id: {
          default: undefined,
          nullable: undefined,
          type: 'integer',
        },
        status: {
          default: undefined,
          nullable: undefined,
          type: 'Status',
        },
      },
    },
  })
})
