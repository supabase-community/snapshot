import fsExtra from 'fs-extra'
import path from 'path'
import tmp from 'tmp-promise'

import { getConfig } from './getConfig.js'
import {
  selectConfigSchema,
  subsetConfigV2Schema,
  parseConfig,
  transformConfigTableSchema,
} from './parseConfig.js'

async function createConfigFile(extension: 'js' | 'ts', configContent: string) {
  const configPath = path.join(
    (await tmp.dir()).path,
    `snaplet.config.${extension}`
  )
  await fsExtra.writeFile(configPath, configContent)
  return configPath
}
const createTSConfigFile = (content: string) => createConfigFile('ts', content)

describe('parseConfig V3', () => {
  describe('select', () => {
    test('exclude a schema from the select', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          select: {
            public: {
              users: false,
            }
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      expect(selectConfigSchema.parse(config.select)).toEqual({
        public: { users: false },
      })
    })
    test('exclude a schema and set a $default from the select', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          select: {
            $default: "structure",
            public: {
              users: false,
            }
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      expect(selectConfigSchema.parse(config.select)).toEqual({
        $default: 'structure',
        public: { users: false },
      })
    })
    test('exclude a schema and set a $default from the select', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          select: {
            $default: false,
            public: {
              users: false,
            }
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      expect(selectConfigSchema.parse(config.select)).toEqual({
        $default: false,
        public: { users: false },
      })
    })
    test('exclude a schema and exclude all extensions from the select', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          select: {
            public: {
              users: false,
              $extensions: false,
            }
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      expect(selectConfigSchema.parse(config.select)).toEqual({
        public: { users: false, $extensions: false },
      })
    })
    test('exclude a schema and exclude a extensions from the select', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          select: {
            public: {
              users: false,
              $extensions: {
                citext: false,
              },
            }
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      expect(selectConfigSchema.parse(config.select)).toEqual({
        public: { users: false, $extensions: { citext: false } },
      })
    })
  })
  describe('subset', () => {
    test('use only where in targets', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          subset: {
            enabled: true,
            targets: [
              {
                table: 'public.users',
                where: "users.id = 'randomuuid'",
              },
            ],
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      expect(subsetConfigV2Schema.parse(config.subset)).toEqual({
        enabled: true,
        followNullableRelations: true,
        maxCyclesLoop: 1,
        targets: [
          {
            table: 'public.users',
            where: "users.id = 'randomuuid'",
          },
        ],
      })
    })
    test('use only where and percent in targets', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          subset: {
            enabled: true,
            targets: [
              {
                table: 'public.users',
                where: "users.id = 'randomuuid'",
                percent: 10,
              },
            ],
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      expect(subsetConfigV2Schema.parse(config.subset)).toEqual({
        enabled: true,
        followNullableRelations: true,
        maxCyclesLoop: 1,
        targets: [
          {
            table: 'public.users',
            where: "users.id = 'randomuuid'",
            percent: 10,
          },
        ],
      })
    })
    test('use only where and rowLimit in targets', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          subset: {
            enabled: true,
            targets: [
              {
                table: 'public.users',
                where: "users.id = 'randomuuid'",
                rowLimit: 10,
              },
            ],
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      expect(subsetConfigV2Schema.parse(config.subset)).toEqual({
        enabled: true,
        followNullableRelations: true,
        maxCyclesLoop: 1,
        targets: [
          {
            table: 'public.users',
            where: "users.id = 'randomuuid'",
            rowLimit: 10,
          },
        ],
      })
    })
    test('use only rowLimit in targets', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          subset: {
            enabled: true,
            targets: [
              {
                table: 'public.users',
                rowLimit: 10,
              },
            ],
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      expect(subsetConfigV2Schema.parse(config.subset)).toEqual({
        enabled: true,
        followNullableRelations: true,
        maxCyclesLoop: 1,
        targets: [
          {
            table: 'public.users',
            rowLimit: 10,
          },
        ],
      })
    })
    test('use only percent in targets', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          subset: {
            enabled: true,
            targets: [
              {
                table: 'public.users',
                percent: 10,
              },
            ],
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      expect(subsetConfigV2Schema.parse(config.subset)).toEqual({
        enabled: true,
        followNullableRelations: true,
        maxCyclesLoop: 1,
        targets: [
          {
            table: 'public.users',
            percent: 10,
          },
        ],
      })
    })
    test('fail with where and rowLimit and percent in targets', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          subset: {
            enabled: true,
            targets: [
              {
                table: 'public.users',
                where: "users.id = 'randomuuid'",
                rowLimit: 10,
                percent: 10,
              },
            ],
          },
        });
      `)
      // Assert
      await expect(getConfig(configPath)).rejects.toThrowError(
        /Failed to parse config file/
      )
    })
    test('fail with rowLimit and percent in targets', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          subset: {
            enabled: true,
            targets: [
              {
                table: 'public.users',
                rowLimit: 10,
                percent: 10,
              },
            ],
          },
        });
      `)
      // Assert
      await expect(getConfig(configPath)).rejects.toThrowError(
        /Failed to parse config file/
      )
    })
    test('use scalars for maxCyclesLoop,maxChildrenPerNode,followNullableRelations', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          subset: {
            enabled: true,
            targets: [
              {
                table: 'public.users',
                where: "users.id = 'randomuuid'",
                rowLimit: 10,
              },
            ],
            followNullableRelations: false,
            maxCyclesLoop: 42,
            maxChildrenPerNode: 42,
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      expect(subsetConfigV2Schema.parse(config.subset)).toEqual({
        enabled: true,
        followNullableRelations: false,
        maxCyclesLoop: 42,
        maxChildrenPerNode: 42,
        targets: [
          {
            table: 'public.users',
            where: "users.id = 'randomuuid'",
            rowLimit: 10,
          },
        ],
      })
    })
    test('use $default and relationship definition for maxCyclesLoop,maxChildrenPerNode,followNullableRelations', async () => {
      // Arrange
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          subset: {
            enabled: true,
            targets: [
              {
                table: 'public.users',
                where: "users.id = 'randomuuid'",
                rowLimit: 10,
              },
            ],
            followNullableRelations: {
              $default: false,
              'public.Table1': {
                $default: true,
                some_pk: false,
              },
            },
            maxCyclesLoop: {
              $default: 41,
              'public.Table1': {
                $default: 42,
                some_pk: 43,
              },
            },
            maxChildrenPerNode: {
              $default: 44,
              'public.Table1': {
                $default: 45,
                some_pk: 46,
              },
            },
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      expect(subsetConfigV2Schema.parse(config.subset)).toEqual({
        enabled: true,
        followNullableRelations: {
          $default: false,
          'public.Table1': {
            $default: true,
            some_pk: false,
          },
        },
        maxCyclesLoop: {
          $default: 41,
          'public.Table1': {
            $default: 42,
            some_pk: 43,
          },
        },
        maxChildrenPerNode: {
          $default: 44,
          'public.Table1': {
            $default: 45,
            some_pk: 46,
          },
        },
        targets: [
          {
            table: 'public.users',
            where: "users.id = 'randomuuid'",
            rowLimit: 10,
          },
        ],
      })
    })
  })
  describe('transform', () => {
    test('parse the options along with the transforms', async () => {
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          transform: {
            $parseJson: true,
            $mode: 'unsafe',
            public: {
              tableA({row}) {
                return row
              },
            },
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      const parsed = parseConfig(config).transform!
      const { $mode, $parseJson, ...transform } = parsed
      const publicTransform = transform['public']
      const tableATransform = publicTransform['tableA']
      expect(typeof tableATransform === 'function').toBe(true)
      expect($parseJson).toBe(true)
      expect($mode).toBe('unsafe')
    })
    test('parse default options with empty transform', async () => {
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          transform: {
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      const parsed = parseConfig(config).transform!
      const { $mode, $parseJson, ...transform } = parsed
      expect(transform).toEqual({})
      expect($parseJson).toBe(true)
      expect($mode).toBe('unsafe')
    })
    test('parse default options along with transforms', async () => {
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          transform: {
            public: {
              tableA({row}) {
                return row
              },
            },
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      const parsed = parseConfig(config).transform!
      const { $mode, $parseJson, ...transform } = parsed
      const publicTransform = transform['public']
      const tableATransform = publicTransform['tableA']
      expect(typeof tableATransform === 'function').toBe(true)
      expect($parseJson).toBe(true)
      expect($mode).toBe('unsafe')
    })
    test('parse all kinds of transforms', async () => {
      const configPath = await createTSConfigFile(`
        import { defineConfig } from 'snaplet';
        export default defineConfig({
          transform: {
            public: {
              // Table function
              tableA({row}) {
                return row
              },
              // Table object
              tableB: {
                colBA: 'ba',
              },
              // Table object with function
              tableC: {
                colCA: 'ca',
                colCB: ({row}) => row.colCB,
              },
              // Table function return object with function
              tableD({row}) {
                return {
                  colDA: 'da',
                  colDB: ({row}) => row.colDB,
                }
              },
            },
          },
        });
      `)
      // Act
      const config = await getConfig(configPath)
      // Assert
      const parsed = parseConfig(config).transform!
      const { $mode, $parseJson, ...transform } = parsed
      const publicTransform = transform['public']
      const tableATransform = publicTransform['tableA']
      const tableBTransform = publicTransform['tableB']
      const tableCTransform = publicTransform['tableC']
      const tableDTransform = publicTransform['tableD']
      expect($parseJson).toBe(true)
      expect($mode).toBe('unsafe')
      expect(typeof tableATransform === 'function').toBe(true)
      expect(typeof tableBTransform === 'object').toBe(true)
      expect(typeof tableCTransform === 'object').toBe(true)
      if (typeof tableCTransform !== 'object') {
        throw new Error()
      }
      expect(tableCTransform['colCA']).toBe('ca')
      expect(typeof tableCTransform['colCB'] === 'function').toBe(true)
      expect(typeof tableDTransform === 'function').toBe(true)
      if (typeof tableDTransform !== 'function') {
        throw new Error()
      }
      const dResult = await tableDTransform({
        row: { colDB: 'db' },
        rowIndex: 0,
      })
      expect(dResult.colDA).toEqual('da')
      expect(typeof dResult.colDB === 'function').toBe(true)
      if (typeof dResult.colDB !== 'function') {
        throw new Error()
      }
      expect(dResult.colDB({ row: { colDB: 'db' }, value: 'db' })).toEqual('db')
    })
    test('parse table transforms', async () => {
      const parsed = transformConfigTableSchema.parse({
        tableA({ row }: any) {
          return row
        },
        // Table object
        tableB: {
          colBA: 'ba',
        },
        // Table object with function
        tableC: {
          colCA: 'ca',
          colCB: ({ row }: any) => row.colCB,
        },
        tableD({ row: _row }: any) {
          return {
            colDA: 'da',
            colDB: ({ row }: any) => row.colDB,
          }
        },
      })
      const tableATransform = parsed['tableA']
      const tableBTransform = parsed['tableB']
      const tableCTransform = parsed['tableC']
      const tableDTransform = parsed['tableD']
      expect(typeof tableATransform === 'function').toBe(true)
      expect(typeof tableBTransform === 'object').toBe(true)
      expect(typeof tableCTransform === 'object').toBe(true)
      if (typeof tableCTransform !== 'object') {
        throw new Error()
      }
      expect(tableCTransform['colCA']).toBe('ca')
      expect(typeof tableCTransform['colCB'] === 'function').toBe(true)
      expect(typeof tableDTransform === 'function').toBe(true)
      if (typeof tableDTransform !== 'function') {
        throw new Error()
      }
      const dResult = await tableDTransform({
        row: { colDB: 'db' },
        rowIndex: 0,
      })
      expect(dResult.colDA).toEqual('da')
      expect(typeof dResult.colDB === 'function').toBe(true)
      if (typeof dResult.colDB !== 'function') {
        throw new Error()
      }
      expect(dResult.colDB({ row: { colDB: 'db' }, value: 'db' })).toEqual('db')
    })
  })
})
