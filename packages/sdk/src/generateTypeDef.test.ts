import type { IntrospectedStructure } from './db/introspect/introspectDatabase.js'
import {
  generateEnumTypes,
  generateTableTypes,
  generateSchemaTypes,
  generateDatabaseType,
  generateStructureTypes,
  generateTransformOptions,
} from './generateTypeDef.js'

describe('generating transform type definitions', () => {
  const DEFAULT_STRUCTURE = {
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
          {
            name: 'arrays',
            type: '_bool',
          },
          {
            name: 'createdAt',
            type: 'timestamp',
          },
        ],
      },
      {
        schema: 'public',
        name: 'Odd-table',
        columns: [
          {
            name: '21',
            type: 'varchar',
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

  test('enum types', () => {
    const g = generateEnumTypes(DEFAULT_STRUCTURE)
    expect(g).toMatchInlineSnapshot(`"type Enum_public_status = 'YES' | 'NO'"`)
  })

  test('table types', () => {
    const g = generateTableTypes(DEFAULT_STRUCTURE)
    expect(g).toMatchInlineSnapshot(`
      "interface Table_public_user {
        \\"id\\": number
        \\"status\\": Enum_public_status
        \\"arrays\\": boolean[]
        \\"createdAt\\": string
      }
      interface Table_public_odd_table {
        \\"21\\": string
      }"
    `)
  })

  test('schema types', () => {
    const g = generateSchemaTypes(DEFAULT_STRUCTURE)
    expect(g).toMatchInlineSnapshot(`
      "interface Schema_public {
        \\"User\\": false | ((ctx: { row: Table_public_user, rowIndex: number }) => Partial<Table_public_user>)
        \\"Odd-table\\": false | ((ctx: { row: Table_public_odd_table, rowIndex: number }) => Partial<Table_public_odd_table>)
      }"
    `)
  })

  test('transform type', () => {
    const g = generateDatabaseType(DEFAULT_STRUCTURE)
    expect(g).toMatchInlineSnapshot(`
      "export interface Database {
        \\"public\\": Partial<Schema_public>
      }"
    `)
  })

  test('structure type', () => {
    const structure = {
      ...DEFAULT_STRUCTURE,
      schemas: [...DEFAULT_STRUCTURE.schemas, 'other_schema'],
      tables: [
        ...DEFAULT_STRUCTURE.tables,
        {
          schema: 'other_schema',
          name: 'OtherTable',
          columns: [
            {
              name: 'id',
              type: 'uuid',
            },
            {
              name: 'name',
              type: 'text',
            },
          ],
        },
      ],
    } as IntrospectedStructure
    const g = generateStructureTypes(structure)
    expect(g).toMatchInlineSnapshot(`
      "export type Structure = {
        $schemas: [\\"public\\", \\"other_schema\\"],
        \\"public\\": {
        $tables: [\\"User\\", \\"Odd-table\\"],
        \\"User\\": {
        $columns: [\\"id\\", \\"status\\", \\"arrays\\", \\"createdAt\\"],
        \\"id\\": {
        default: undefined,
        nullable: undefined,
        type: \\"integer\\",
      },
      \\"status\\": {
        default: undefined,
        nullable: undefined,
        type: \\"Status\\",
      },
      \\"arrays\\": {
        default: undefined,
        nullable: undefined,
        type: \\"_bool\\",
      },
      \\"createdAt\\": {
        default: undefined,
        nullable: undefined,
        type: \\"timestamp\\",
      },
      },
      \\"Odd-table\\": {
        $columns: [\\"21\\"],
        \\"21\\": {
        default: undefined,
        nullable: undefined,
        type: \\"varchar\\",
      },
      },
      },
      \\"other_schema\\": {
        $tables: [\\"OtherTable\\"],
        \\"OtherTable\\": {
        $columns: [\\"id\\", \\"name\\"],
        \\"id\\": {
        default: undefined,
        nullable: undefined,
        type: \\"uuid\\",
      },
      \\"name\\": {
        default: undefined,
        nullable: undefined,
        type: \\"text\\",
      },
      },
      },
      }"
    `)
  })

  test('options', () => {
    expect(generateTransformOptions()).toMatchInlineSnapshot(`
      "export interface TransformOptions {
        mode?: 'auto' | 'strict' | 'unsafe'
        parseJson?: boolean
      }"
    `)
  })
})
