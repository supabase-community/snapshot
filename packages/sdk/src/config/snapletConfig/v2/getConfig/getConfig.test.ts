import fsExtra from 'fs-extra'
import path from 'path'
import tmp from 'tmp-promise'

import { getConfig } from './getConfig.js'

async function createConfigFile(extension: 'js' | 'ts', configContent: string) {
  const configPath = path.join(
    (await tmp.dir()).path,
    `snaplet.config.${extension}`
  )
  await fsExtra.writeFile(configPath, configContent)
  return configPath
}
const createTSConfigFile = (content: string) => createConfigFile('ts', content)
const createJSConfigFile = (content: string) => createConfigFile('js', content)

test('get the config in TypeScript', async () => {
  // Arrange
  const configPath = await createTSConfigFile(`
    import { defineConfig } from 'snaplet';
    type ThisIsAType = string;
    export default defineConfig({
      select: {
        public: {
          users: "structure",
        }
      },
      transform: {
        $mode: 'auto',
        public: {
          books: (ctx) => ({ title: 'A Long Story' }),
        },
      },
      subset: {
        targets: [{ table: 'public.books', percent: 10 }],
      },
    });
  `)
  // Act
  const config = await getConfig(configPath)
  expect(config.select).toEqual(
    expect.objectContaining({
      public: {
        users: 'structure',
      },
    })
  )
  expect(config.transform).toEqual(
    expect.objectContaining({
      $mode: 'auto',
      public: {
        books: expect.any(Function),
      },
    })
  )
  expect(config.subset).toEqual({
    enabled: true,
    followNullableRelations: true,
    maxCyclesLoop: 1,
    targets: [{ table: 'public.books', percent: 10 }],
  })
})

test('get the config in JavaScript (ESM)', async () => {
  // Arrange
  const configPath = await createJSConfigFile(`
    import { defineConfig } from 'snaplet';
    export default defineConfig({
      select: {
        public: {
          users: "structure",
        }
      },
      transform: {
        $mode: 'auto',
        public: {
          books: (ctx) => ({ title: 'A Long Story' }),
        },
      },
      subset: {
        targets: [{ table: 'public.books', percent: 10 }],
      },
    });
  `)
  // Act
  const config = await getConfig(configPath)
  // Assert
  expect(config.select).toEqual(
    expect.objectContaining({
      public: {
        users: 'structure',
      },
    })
  )
  expect(config.transform).toEqual(
    expect.objectContaining({
      $mode: 'auto',
      public: {
        books: expect.any(Function),
      },
    })
  )
  expect(config.subset).toEqual({
    enabled: true,
    followNullableRelations: true,
    maxCyclesLoop: 1,
    targets: [{ table: 'public.books', percent: 10 }],
  })
})

test('get the config in JavaScript (CJS)', async () => {
  // Arrange
  const configPath = await createJSConfigFile(`
    const { defineConfig } = require('snaplet');
    module.exports = defineConfig({
      select: {
        public: {
          users: "structure",
        }
      },
      transform: {
        $mode: 'auto',
        public: {
          books: (ctx) => ({ title: 'A Long Story' }),
        },
      },
      subset: {
        targets: [{ table: 'public.books', percent: 10 }],
      },
    });
  `)
  // Act
  const config = await getConfig(configPath)
  // Assert
  // Assert
  expect(config.select).toEqual(
    expect.objectContaining({
      public: {
        users: 'structure',
      },
    })
  )
  expect(config.transform).toEqual(
    expect.objectContaining({
      $mode: 'auto',
      public: {
        books: expect.any(Function),
      },
    })
  )
  expect(config.subset).toEqual({
    enabled: true,
    followNullableRelations: true,
    maxCyclesLoop: 1,
    targets: [{ table: 'public.books', percent: 10 }],
  })
})

test('raise an error if the config is invalid', async () => {
  // Arrange
  const configPath = await createTSConfigFile(`
    import { defineConfig } from 'snaplet';
    export default defineConfig({
     transform: {
        $mode: 'autoo',
     },
   });
 `)
  // Act
  let error: Error | undefined = undefined
  try {
    await getConfig(configPath)
  } catch (e) {
    if (e instanceof Error) {
      error = e
    }
  }
  // Assert
  expect(error?.message).toContain(`Failed to parse config file`)
})

test('transform functions work', async () => {
  // Arrange
  const configPath = await createTSConfigFile(`
    import { defineConfig } from 'snaplet';
    import { copycat } from '@snaplet/copycat';
    export default defineConfig({
      transform: {
        public: {
          books: (ctx) => ({ title: \`A Long Story \${ctx.rowIndex}\`, author: copycat.fullName(ctx.row.author) }),
        },
      },
    });
  `)
  // Act
  const config = await getConfig(configPath)
  // Assert
  expect(
    // @ts-expect-error - we know this is a function
    config.transform?.public?.books?.({
      row: { title: 'A Random Title', author: 'Victor Hugo' },
      rowIndex: 1,
    })
  ).toEqual({
    author: 'Wilton Conroy',
    title: 'A Long Story 1',
  })
})
