import { createTestDb } from '~/testing.js'
import {
  generateDefaultFingerprint,
  jsonSchemaToTypescriptType,
  jsonToJsonSchema,
} from './fingerprint.js'
import { execQueryNext, withDbClient } from '~/db/client.js'
import { introspectionToDataModel } from './dataModel.js'
import { introspectDatabaseV3 } from '~/exports/api.js'

describe('fingerprint', () => {
  test('jsonSchemaToTypescriptType', async () => {
    // arrange
    const jsonSchema = JSON.stringify({
      additionalProperties: false,
      type: 'object',
      properties: {
        id: {
          type: 'number',
        },
        name: {
          type: 'string',
        },
      },
      required: ['id'],
      title: 'Test',
    })
    // act
    const typescriptType = await jsonSchemaToTypescriptType('test', jsonSchema)
    // assert
    expect(typescriptType.types).toMatchInlineSnapshot(`
      "declare namespace TestJsonField {
        export interface Default {
        id:    number;
        name?: string;
      }
      }"
    `)
  })

  test('jsonSchemaToTypescriptType complicated type', async () => {
    // arrange
    const jsonSchema = JSON.stringify({
      $schema: 'http://json-schema.org/draft-06/schema#',
      $ref: '#/definitions/DBInfo',
      definitions: {
        DBInfo: {
          type: 'object',
          additionalProperties: false,
          properties: {
            enums: {
              type: 'array',
              items: {
                $ref: '#/definitions/Enum',
              },
            },
            server: {
              $ref: '#/definitions/Server',
            },
            tables: {
              type: 'array',
              items: {
                $ref: '#/definitions/DBInfoTable',
              },
            },
            schemas: {
              type: 'array',
              items: {
                type: 'string',
              },
            },
            extensions: {
              type: 'array',
              items: {
                $ref: '#/definitions/Extension',
              },
            },
            indexes: {
              type: 'array',
              items: {
                $ref: '#/definitions/Index',
              },
            },
            data: {
              $ref: '#/definitions/Data',
            },
            version: {
              type: 'string',
              format: 'integer',
            },
          },
          required: [],
          title: 'DBInfo',
        },
        Data: {
          type: 'object',
          additionalProperties: false,
          properties: {
            enums: {
              type: 'array',
              items: {
                $ref: '#/definitions/Enum',
              },
            },
            server: {
              $ref: '#/definitions/Server',
            },
            tables: {
              type: 'array',
              items: {
                $ref: '#/definitions/DataTable',
              },
            },
            indexes: {
              type: 'array',
              items: {
                $ref: '#/definitions/Index',
              },
            },
            schemas: {
              type: 'array',
              items: {
                type: 'string',
              },
            },
            extensions: {
              type: 'array',
              items: {
                $ref: '#/definitions/Extension',
              },
            },
          },
          required: [
            'enums',
            'extensions',
            'indexes',
            'schemas',
            'server',
            'tables',
          ],
          title: 'Data',
        },
        Enum: {
          type: 'object',
          additionalProperties: false,
          properties: {
            id: {
              type: 'string',
            },
            name: {
              type: 'string',
            },
            schema: {
              type: 'string',
            },
            values: {
              type: 'array',
              items: {
                type: 'string',
              },
            },
          },
          required: ['name', 'schema', 'values'],
          title: 'Enum',
        },
        Extension: {
          type: 'object',
          additionalProperties: false,
          properties: {
            name: {
              type: 'string',
            },
            schema: {
              type: 'string',
            },
            version: {
              type: 'string',
            },
          },
          required: ['name', 'schema', 'version'],
          title: 'Extension',
        },
        Index: {
          type: 'object',
          additionalProperties: false,
          properties: {
            type: {
              type: 'string',
            },
            index: {
              type: 'string',
            },
            table: {
              type: 'string',
            },
            schema: {
              type: 'string',
            },
            definition: {
              type: 'string',
            },
            indexColumns: {
              type: 'array',
              items: {
                type: 'string',
              },
            },
          },
          required: [
            'definition',
            'index',
            'indexColumns',
            'schema',
            'table',
            'type',
          ],
          title: 'Index',
        },
        Server: {
          type: 'object',
          additionalProperties: false,
          properties: {
            version: {
              type: 'string',
            },
          },
          required: ['version'],
          title: 'Server',
        },
        DataTable: {
          type: 'object',
          additionalProperties: false,
          properties: {
            id: {
              type: 'string',
            },
            name: {
              type: 'string',
            },
            rows: {
              anyOf: [
                {
                  type: 'integer',
                },
                {
                  type: 'null',
                },
              ],
            },
            bytes: {
              type: 'integer',
            },
            schema: {
              type: 'string',
            },
            columns: {
              type: 'array',
              items: {
                $ref: '#/definitions/Column',
              },
            },
            parents: {
              type: 'array',
              items: {
                $ref: '#/definitions/PurpleChild',
              },
            },
            children: {
              type: 'array',
              items: {
                $ref: '#/definitions/PurpleChild',
              },
            },
            partitioned: {
              type: 'boolean',
            },
            primaryKeys: {
              anyOf: [
                {
                  $ref: '#/definitions/PrimaryKeys',
                },
                {
                  type: 'null',
                },
              ],
            },
          },
          required: [
            'bytes',
            'children',
            'columns',
            'id',
            'name',
            'parents',
            'partitioned',
            'primaryKeys',
            'rows',
            'schema',
          ],
          title: 'DataTable',
        },
        PurpleChild: {
          type: 'object',
          additionalProperties: false,
          properties: {
            id: {
              type: 'string',
            },
            keys: {
              type: 'array',
              items: {
                $ref: '#/definitions/ChildKey',
              },
            },
            fkTable: {
              type: 'string',
            },
            targetTable: {
              type: 'string',
            },
          },
          required: ['fkTable', 'id', 'keys', 'targetTable'],
          title: 'PurpleChild',
        },
        ChildKey: {
          type: 'object',
          additionalProperties: false,
          properties: {
            fkType: {
              type: 'string',
            },
            fkColumn: {
              type: 'string',
            },
            nullable: {
              type: 'boolean',
            },
            targetType: {
              type: 'string',
            },
            targetColumn: {
              type: 'string',
            },
          },
          required: [
            'fkColumn',
            'fkType',
            'nullable',
            'targetColumn',
            'targetType',
          ],
          title: 'ChildKey',
        },
        Column: {
          type: 'object',
          additionalProperties: false,
          properties: {
            id: {
              type: 'string',
            },
            name: {
              type: 'string',
            },
            type: {
              type: 'string',
            },
            table: {
              type: 'string',
            },
            schema: {
              type: 'string',
            },
            typeId: {
              type: 'string',
            },
            default: {
              anyOf: [
                {
                  type: 'null',
                },
                {
                  type: 'string',
                },
              ],
            },
            identity: {
              type: 'null',
            },
            nullable: {
              type: 'boolean',
            },
            generated: {
              type: 'string',
            },
            maxLength: {
              anyOf: [
                {
                  type: 'integer',
                },
                {
                  type: 'null',
                },
              ],
            },
            constraints: {
              type: 'array',
              items: {
                type: 'string',
              },
            },
            typeCategory: {
              type: 'string',
            },
          },
          required: ['name', 'type'],
          title: 'Column',
        },
        PrimaryKeys: {
          type: 'object',
          additionalProperties: false,
          properties: {
            keys: {
              type: 'array',
              items: {
                $ref: '#/definitions/PrimaryKeysKey',
              },
            },
            dirty: {
              type: 'boolean',
            },
            table: {
              type: 'string',
            },
            schema: {
              type: 'string',
            },
            tableId: {
              type: 'string',
            },
          },
          required: ['dirty', 'keys', 'schema', 'table', 'tableId'],
          title: 'PrimaryKeys',
        },
        PrimaryKeysKey: {
          type: 'object',
          additionalProperties: false,
          properties: {
            name: {
              type: 'string',
            },
            type: {
              type: 'string',
            },
          },
          required: ['name', 'type'],
          title: 'PrimaryKeysKey',
        },
        DBInfoTable: {
          type: 'object',
          additionalProperties: false,
          properties: {
            name: {
              type: 'string',
            },
            rows: {
              anyOf: [
                {
                  type: 'integer',
                },
                {
                  type: 'null',
                },
              ],
            },
            bytes: {
              type: 'string',
              format: 'integer',
            },
            schema: {
              type: 'string',
            },
            columns: {
              type: 'array',
              items: {
                $ref: '#/definitions/Column',
              },
            },
            id: {
              type: 'string',
            },
            parents: {
              type: 'array',
              items: {
                $ref: '#/definitions/FluffyChild',
              },
            },
            children: {
              type: 'array',
              items: {
                $ref: '#/definitions/FluffyChild',
              },
            },
            primaryKey: {
              type: 'string',
            },
          },
          required: ['bytes', 'columns', 'name', 'rows'],
          title: 'DBInfoTable',
        },
        FluffyChild: {
          type: 'object',
          additionalProperties: false,
          properties: {
            fkTable: {
              type: 'string',
            },
            fkColumn: {
              type: 'string',
            },
            nullable: {
              type: 'boolean',
            },
            targetTable: {
              type: 'string',
            },
            targetColumn: {
              type: 'string',
            },
          },
          required: [
            'fkColumn',
            'fkTable',
            'nullable',
            'targetColumn',
            'targetTable',
          ],
          title: 'FluffyChild',
        },
      },
    })
    // act
    const typescriptType = await jsonSchemaToTypescriptType(
      'projects_dbInfo',
      jsonSchema
    )
    // assert
    expect(typescriptType.types).toMatchInlineSnapshot(`
      "declare namespace ProjectsDbinfoJsonField {
        export interface Default {
        data?:       Data;
        enums?:      Enum[];
        extensions?: Extension[];
        indexes?:    Index[];
        schemas?:    string[];
        server?:     Server;
        tables?:     DBInfoTable[];
        version?:    string;
      }

      export interface Data {
        enums:      Enum[];
        extensions: Extension[];
        indexes:    Index[];
        schemas:    string[];
        server:     Server;
        tables:     DataTable[];
      }

      export interface Enum {
        id?:    string;
        name:   string;
        schema: string;
        values: string[];
      }

      export interface Extension {
        name:    string;
        schema:  string;
        version: string;
      }

      export interface Index {
        definition:   string;
        index:        string;
        indexColumns: string[];
        schema:       string;
        table:        string;
        type:         string;
      }

      export interface Server {
        version: string;
      }

      export interface DataTable {
        bytes:       number;
        children:    PurpleChild[];
        columns:     Column[];
        id:          string;
        name:        string;
        parents:     PurpleChild[];
        partitioned: boolean;
        primaryKeys: PrimaryKeys | null;
        rows:        number | null;
        schema:      string;
      }

      export interface PurpleChild {
        fkTable:     string;
        id:          string;
        keys:        ChildKey[];
        targetTable: string;
      }

      export interface ChildKey {
        fkColumn:     string;
        fkType:       string;
        nullable:     boolean;
        targetColumn: string;
        targetType:   string;
      }

      export interface Column {
        constraints?:  string[];
        default?:      null | string;
        generated?:    string;
        id?:           string;
        identity?:     null;
        maxLength?:    number | null;
        name:          string;
        nullable?:     boolean;
        schema?:       string;
        table?:        string;
        type:          string;
        typeCategory?: string;
        typeId?:       string;
      }

      export interface PrimaryKeys {
        dirty:   boolean;
        keys:    PrimaryKeysKey[];
        schema:  string;
        table:   string;
        tableId: string;
      }

      export interface PrimaryKeysKey {
        name: string;
        type: string;
      }

      export interface DBInfoTable {
        bytes:       string;
        children?:   FluffyChild[];
        columns:     Column[];
        id?:         string;
        name:        string;
        parents?:    FluffyChild[];
        primaryKey?: string;
        rows:        number | null;
        schema?:     string;
      }

      export interface FluffyChild {
        fkColumn:     string;
        fkTable:      string;
        nullable:     boolean;
        targetColumn: string;
        targetTable:  string;
      }
      }"
    `)
  })

  test('jsonToJsonSchema', async () => {
    // arrange
    const jsonSample1 = JSON.stringify({
      id: 1,
      name: 'test',
    })
    const jsonSample2 = JSON.stringify({
      id: 2,
    })
    // act
    const jsonSchema = await jsonToJsonSchema('test', [
      jsonSample1,
      jsonSample2,
    ])
    // assert
    expect(jsonSchema).toMatchObject({
      $ref: '#/definitions/Test',
      $schema: 'http://json-schema.org/draft-06/schema#',
      definitions: {
        Test: {
          additionalProperties: false,
          properties: {
            id: {
              type: 'integer',
            },
            name: {
              type: 'string',
            },
          },
          required: ['id'],
          title: 'Test',
          type: 'object',
        },
      },
    })
  })

  describe('generateDefaultFingerprint', () => {
    test('number types', async () => {
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

      const fingerprint = await generateDefaultFingerprint(
        testDb.toString(),
        dataModel
      )

      expect(fingerprint.t.value).toEqual({
        options: {
          min: 2,
          max: 23,
        },
      })
    })

    test('date types', async () => {
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

      const fingerprint = await generateDefaultFingerprint(
        testDb.toString(),
        dataModel
      )

      expect(fingerprint.t.value).toEqual({
        options: {
          minYear: 2002,
          maxYear: 2023,
        },
      })
    })

    test('id and relation fields are excluded', async () => {
      const testDb = await createTestDb()

      await execQueryNext(
        `
        CREATE TABLE "A" (
          "id" serial not null primary key
        );
        CREATE TABLE "B" (
          "id" serial not null primary key,
          "aId" int not null references "A"("id")
        );

        INSERT INTO "A" VALUES (1);
        INSERT INTO "B" VALUES (2, 1);
      `,
        testDb
      )

      const dataModel = introspectionToDataModel(
        await withDbClient(introspectDatabaseV3, {
          connString: testDb.toString(),
        })
      )

      const fingerprint = await generateDefaultFingerprint(
        testDb.toString(),
        dataModel
      )

      expect(fingerprint.A).toEqual({})
      expect(fingerprint.B).toEqual({})
    })
  })
})
