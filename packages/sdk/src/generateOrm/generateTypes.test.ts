import { createTestDb } from '~/testing/createTestDb.js'
import { DataModel, introspectionToDataModel } from './dataModel/dataModel.js'
import { generateConfigTypes, generateTypes } from './generateTypes.js'
import { introspectDatabaseV3 } from '~/db/introspect/introspectDatabase.js'
import { execQueryNext, withDbClient } from '~/db/client.js'

describe('generateTypes', () => {
  test('generates types with two tables named the same in different schemas', async () => {
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
    // act
    const types = await generateTypes({ dataModel })
    // assert
    expect(types).toContain('public_User:')
    expect(types).toContain('auth_User:')
  })

  test('generates array types', async () => {
    // arrange
    const dataModel: DataModel = {
      enums: {
        public_B: {
          schemaName: 'public',
          values: [
            {
              name: 'B1.1',
            },
            {
              name: 'B1.2',
            },
          ],
        },
        auth_B: {
          schemaName: 'public',
          values: [
            {
              name: 'B2.1',
            },
            {
              name: 'B2.2',
            },
          ],
        },
      },
      models: {
        public_Foo: {
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
              name: 'id',
              id: 'public.User.id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: true,
              isRequired: true,
              kind: 'scalar',
              id: 'public.User.a',
              name: 'a',
              columnName: 'a',
              type: 'text[][]',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: true,
              isRequired: true,
              kind: 'scalar',
              id: 'public.User.b1',
              name: 'b1',
              columnName: 'b1',
              type: 'public_B[][]',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: true,
              isRequired: true,
              kind: 'scalar',
              id: 'public.User.b2',
              name: 'b2',
              columnName: 'b2',
              type: 'auth_B[][]',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: true,
              isRequired: false,
              kind: 'scalar',
              id: 'public.User.c',
              name: 'c',
              columnName: 'c',
              type: 'text[][]',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
      },
    }
    // act
    const types = await generateTypes({ dataModel })

    // assert

    expect(types).toContain('id: string;')
    expect(types).toContain('a: string[][];')
    expect(types).toContain('b1: public_BEnum[][];')
    expect(types).toContain('b2: auth_BEnum[][];')
    expect(types).toContain('c: string[][] | null;')
  })

  test('generates types with generated and default values', async () => {
    // arrange
    const dataModel: DataModel = {
      enums: {},
      models: {
        User: {
          fields: [
            {
              hasDefaultValue: false,
              isGenerated: false,
              sequence: false,
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.User.email',
              name: 'email',
              columnName: 'email',
              type: 'text',
            },
            {
              hasDefaultValue: false,
              isGenerated: false,
              sequence: false,
              isId: true,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.User.id',
              name: 'id',
              columnName: 'id',
              type: 'uuid',
            },
            // created_at is required and has a default value
            {
              hasDefaultValue: true,
              isGenerated: false,
              sequence: false,
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.User.created_at',
              name: 'created_at',
              columnName: 'created_at',
              type: 'timestamptz',
            },
            // updated_at is required and is generated
            {
              hasDefaultValue: false,
              isGenerated: true,
              sequence: false,
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.User.updated_at',
              name: 'updated_at',
              columnName: 'updated_at',
              type: 'timestamptz',
            },
          ],
          schemaName: 'public',
          uniqueConstraints: [],
          id: 'public.User',
          tableName: 'User',
        },
      },
    }
    // act
    const types = await generateTypes({ dataModel })
    // assert
    // both created_at and updated_at should be optional as they can be generated from the database
    expect(types).toContain('email: string;')
    expect(types).toContain('id: string;')
    expect(types).toContain('created_at?: ( Date | string );')
    expect(types).toContain('updated_at?: ( Date | string );')
    // updated_at is removed from the inputs as it's always generated by the database
    expect(types).toContain(`type UserInputs = Inputs<
  Omit<UserScalars, "updated_at">,
  UserParentsInputs,
  UserChildrenInputs
>;`)
  })

  test('generates types with non conflicting model names', async () => {
    // arrange
    const dataModel: DataModel = {
      enums: {},
      models: {
        Store: {
          fields: [
            {
              hasDefaultValue: false,
              isGenerated: false,
              sequence: false,
              isId: true,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.Store.id',
              name: 'id',
              columnName: 'id',
              type: 'uuid',
            },
          ],
          schemaName: 'public',
          uniqueConstraints: [],
          id: 'public.Store',
          tableName: 'Store',
        },
      },
    }
    // act
    const types = await generateTypes({ dataModel })
    const count = (types.match(/type Store =/g) || []).length
    // assert
    expect(count).toEqual(1)
  })
})

describe('generateConfigTypes', () => {
  test('generates fingerprint for numbers', async () => {
    const testDb = await createTestDb()

    await execQueryNext(
      `
        CREATE TABLE "t" (
          "value" integer not null
        );

        INSERT INTO "t" VALUES (2), (23), (3);
      `,
      testDb
    )

    const dataModel = introspectionToDataModel(
      await withDbClient(introspectDatabaseV3, {
        connString: testDb.toString(),
      })
    )

    const result = await generateConfigTypes({
      dataModel,
    })

    expect(result).toContain(`\
interface FingerprintNumberField {
  options?: {
    min?: number;
    max?: number;
  }
}`)

    expect(result).toContain(`\
export interface Fingerprint {
  t?: {
    value?: FingerprintNumberField;
  }}`)
  })

  test('generates fingerprint for dates', async () => {
    const testDb = await createTestDb()

    await execQueryNext(
      `
        CREATE TABLE "t" (
          "value" timestamp not null
        );

        INSERT INTO "t" VALUES ('2002-08-14T04:03:18.613Z'), ('2023-08-14T04:03:18.613Z'), ('2003-08-14T04:03:18.613Z');
      `,
      testDb
    )

    const dataModel = introspectionToDataModel(
      await withDbClient(introspectDatabaseV3, {
        connString: testDb.toString(),
      })
    )

    const result = await generateConfigTypes({
      dataModel,
    })

    expect(result).toContain(`\
interface FingerprintDateField {
  options?: {
    minYear?: number;
    maxYear?: number;
  }
}`)

    expect(result).toContain(`\
export interface Fingerprint {
  t?: {
    value?: FingerprintDateField;
  }}`)
  })
})
