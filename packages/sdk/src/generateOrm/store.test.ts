import { Store } from './store.js'
import { DataModel } from './dataModel/dataModel.js'
import { getAliasedDataModel } from './dataModel/aliases.js'

describe('store', () => {
  describe('toSQL', () => {
    test('generates sql statements', () => {
      const dataModel: DataModel = {
        enums: {},
        models: {
          test_customer: {
            uniqueConstraints: [],
            id: 'public.test_customer',
            tableName: 'test_customer',
            schemaName: 'public',
            fields: [
              {
                isId: true,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.test_customer.id',
                name: 'id',
                columnName: 'id',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.test_customer.name',
                name: 'name',
                columnName: 'name',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.test_customer.email',
                name: 'email',
                columnName: 'email',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
            ],
          },
        },
      }

      const store = new Store(dataModel)

      store.add('test_customer', {
        id: '2',
        name: 'Cadavre Exquis',
        email: 'cadavre@ex.quis',
      })

      store.add('test_customer', {
        id: '3',
        name: 'Winrar Skarsgård',
        email: 'win@rar.gard',
      })

      expect([...store.toSQL()]).toEqual([
        "INSERT INTO public.test_customer (id,name,email) VALUES ('2', 'Cadavre Exquis', 'cadavre@ex.quis'), ('3', 'Winrar Skarsgård', 'win@rar.gard')",
      ])
    })

    test('generates sql statements with two tables named the same in different schemas', () => {
      // arrange
      const dataModel: DataModel = {
        enums: {},
        models: {
          public_User: {
            uniqueConstraints: [],
            id: 'public.User',
            tableName: 'User',
            schemaName: 'public',
            fields: [
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.User.id',
                name: 'id',
                columnName: 'id',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.User.name',
                name: 'name',
                columnName: 'name',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
            ],
          },
          auth_User: {
            uniqueConstraints: [],
            id: 'public.User',
            tableName: 'User',
            schemaName: 'auth',
            fields: [
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.User.id',
                name: 'id',
                columnName: 'id',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.User.password',
                name: 'password',
                columnName: 'password',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
            ],
          },
        },
      }

      const store = new Store(dataModel)

      store.add('public_User', {
        id: '2',
        name: 'John Doe',
      })

      store.add('auth_User', {
        id: '3',
        password: '$3cr37',
      })

      expect([...store.toSQL()]).toEqual([
        "INSERT INTO auth.\"User\" (id,password) VALUES ('3', '$3cr37')",
        "INSERT INTO public.\"User\" (id,name) VALUES ('2', 'John Doe')",
      ])
    })

    test('generates sql statements with aliases', () => {
      // arrange
      let dataModel: DataModel = {
        enums: {},
        models: {
          public_User: {
            uniqueConstraints: [],
            id: 'public.User',
            tableName: 'User',
            schemaName: 'public',
            fields: [
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.User.id',
                name: 'id',
                columnName: 'id',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.User.firstName',
                name: 'firstName',
                columnName: 'first_name',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
            ],
          },
          auth_User: {
            uniqueConstraints: [],
            id: 'public.User',
            tableName: 'User',
            schemaName: 'auth',
            fields: [
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.User.id',
                name: 'id',
                columnName: 'id',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.User.password',
                name: 'password',
                columnName: 'password',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
            ],
          },
        },
      }

      dataModel = getAliasedDataModel(dataModel, { inflection: true })

      const store = new Store(dataModel)

      store.add('publicUsers', {
        id: '2',
        firstName: 'John Doe',
      })

      store.add('authUsers', {
        id: '3',
        password: '$3cr37',
      })

      expect([...store.toSQL()]).toEqual([
        "INSERT INTO auth.\"User\" (id,password) VALUES ('3', '$3cr37')",
        "INSERT INTO public.\"User\" (id,first_name) VALUES ('2', 'John Doe')",
      ])
    })

    test('generates sql statements with generated values', () => {
      const dataModel: DataModel = {
        enums: {},
        models: {
          test_customer: {
            uniqueConstraints: [],
            id: 'public.test_customer',
            tableName: 'test_customer',
            schemaName: 'public',
            fields: [
              {
                isId: true,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.test_customer.id',
                name: 'id',
                columnName: 'id',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.test_customer.name',
                name: 'name',
                columnName: 'name',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.test_customer.confirmed_at',
                name: 'confirmed_at',
                columnName: 'confirmed_at',
                type: 'text',
                isGenerated: true,
                sequence: false,
                hasDefaultValue: false,
              },
            ],
          },
        },
      }

      const store = new Store(dataModel)

      store.add('test_customer', {
        id: '2',
        name: 'Cadavre Exquis',
      })

      store.add('test_customer', {
        id: '3',
        name: 'Winrar Skarsgård',
      })

      expect([...store.toSQL()]).toEqual([
        "INSERT INTO public.test_customer (id,name) VALUES ('2', 'Cadavre Exquis'), ('3', 'Winrar Skarsgård')",
      ])
    })

    test('generates sql statements with id + generated values', () => {
      const dataModel: DataModel = {
        enums: {},
        models: {
          test_customer: {
            uniqueConstraints: [],
            id: 'public.test_customer',
            tableName: 'test_customer',
            schemaName: 'public',
            fields: [
              {
                isId: true,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.test_customer.id',
                name: 'id',
                columnName: 'id',
                type: 'int8',
                isGenerated: true,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.test_customer.name',
                name: 'name',
                columnName: 'name',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
            ],
          },
        },
      }

      const store = new Store(dataModel)

      store.add('test_customer', {
        id: 100,
        name: 'Cadavre Exquis',
      })

      store.add('test_customer', {
        id: 200,
        name: 'Winrar Skarsgård',
      })

      expect([...store.toSQL()]).toEqual([
        "INSERT INTO public.test_customer (id,name) OVERRIDING SYSTEM VALUE VALUES (100, 'Cadavre Exquis'), (200, 'Winrar Skarsgård')",
      ])
    })

    test('generates sql statements with default value', () => {
      const dataModel: DataModel = {
        enums: {},
        models: {
          test_customer: {
            uniqueConstraints: [],
            id: 'public.test_customer',
            tableName: 'test_customer',
            schemaName: 'public',
            fields: [
              {
                isId: true,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.test_customer.id',
                name: 'id',
                columnName: 'id',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.test_customer.name',
                name: 'name',
                columnName: 'name',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.test_customer.confirmed_at',
                name: 'confirmed_at',
                columnName: 'confirmed_at',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: true,
              },
            ],
          },
        },
      }

      const store = new Store(dataModel)

      store.add('test_customer', {
        id: '2',
        name: 'Cadavre Exquis',
      })

      store.add('test_customer', {
        id: '3',
        name: 'Winrar Skarsgård',
      })

      expect([...store.toSQL()]).toMatchInlineSnapshot(`
        [
          "INSERT INTO public.test_customer (id,name,confirmed_at) VALUES ('2', 'Cadavre Exquis', DEFAULT), ('3', 'Winrar Skarsgård', DEFAULT)",
        ]
      `)
    })

    test('generates sql statements with nullable value', () => {
      const dataModel: DataModel = {
        enums: {},
        models: {
          test_customer: {
            uniqueConstraints: [],
            id: 'public.test_customer',
            tableName: 'test_customer',
            schemaName: 'public',
            fields: [
              {
                isId: true,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.test_customer.id',
                name: 'id',
                columnName: 'id',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.test_customer.name',
                name: 'name',
                columnName: 'name',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: false,
                kind: 'scalar',
                id: 'public.test_customer.confirmed_at',
                name: 'confirmed_at',
                columnName: 'confirmed_at',
                type: 'text',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
            ],
          },
        },
      }

      const store = new Store(dataModel)

      store.add('test_customer', {
        id: '2',
        name: 'Cadavre Exquis',
      })

      store.add('test_customer', {
        id: '3',
        name: 'Winrar Skarsgård',
      })

      expect([...store.toSQL()]).toEqual([
        "INSERT INTO public.test_customer (id,name,confirmed_at) VALUES ('2', 'Cadavre Exquis', NULL), ('3', 'Winrar Skarsgård', NULL)",
      ])
    })

    test('serialize json/jsonb arrays correctly', () => {
      const dataModel: DataModel = {
        enums: {},
        models: {
          analytic: {
            uniqueConstraints: [],
            id: 'public.analytic',
            tableName: 'analytic',
            schemaName: 'public',
            fields: [
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.analytic.metadata',
                name: 'metadata',
                columnName: 'metadata',
                type: 'jsonb',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
            ],
          },
        },
      }

      const store = new Store(dataModel)

      store.add('analytic', {
        metadata: ['http://somewhere', 'http://elsewhere'],
      })

      store.add('analytic', {
        metadata: { it: 'works' },
      })

      expect([...store.toSQL()]).toEqual([
        'INSERT INTO public.analytic (metadata) VALUES (\'["http://somewhere","http://elsewhere"]\'), (\'{"it":"works"}\')',
      ])
    })
    test('serialize json/jsonb arrays and ARRAY types correctly', () => {
      const dataModel: DataModel = {
        enums: {},
        models: {
          analytic: {
            uniqueConstraints: [],
            id: 'public.analytic',
            tableName: 'analytic',
            schemaName: 'public',
            fields: [
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.analytic.metadata',
                name: 'metadata',
                columnName: 'metadata',
                type: 'jsonb',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
              {
                isId: false,
                isList: false,
                isRequired: true,
                kind: 'scalar',
                id: 'public.analytic.pgarray',
                name: 'pgarray',
                columnName: 'pgarray',
                type: 'text[]',
                isGenerated: false,
                sequence: false,
                hasDefaultValue: false,
              },
            ],
          },
        },
      }

      const store = new Store(dataModel)

      store.add('analytic', {
        metadata: ['http://somewhere', 'http://elsewhere'],
        pgarray: ['One', 'Two'],
      })

      store.add('analytic', {
        metadata: { it: 'works' },
        pgarray: ['Three', 'Vivalalgerie'],
      })

      expect([...store.toSQL()]).toEqual([
        'INSERT INTO public.analytic (metadata,pgarray) VALUES (\'["http://somewhere","http://elsewhere"]\', \'{"One","Two"}\'), (\'{"it":"works"}\', \'{"Three","Vivalalgerie"}\')',
      ])
    })
  })
})
