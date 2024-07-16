import fs from 'fs-extra'
import path from 'path'
import tmp, { DirectoryResult } from 'tmp-promise'

import { createTestDb } from '../../testing/index.js'
import { importGenerateTransform } from '../../transform.js'
import {
  createSnapletConfig,
  getSnapletConfig,
  SNAPLET_CONFIG_DEFAULTS,
} from './snapletConfig.js'

beforeAll(async () => {
  await importGenerateTransform()
})

describe('getSnapletConfig', () => {
  let dir: DirectoryResult
  let projectPath: string

  beforeEach(async () => {
    const connectionString = await createTestDb()
    dir = await tmp.dir()
    process.env.SNAPLET_CWD = dir.path
    projectPath = path.join(dir.path, '.snaplet')
    await fs.mkdir(projectPath)
    const config = {
      sourceDatabaseUrl: connectionString.toString(),
    }
    await fs.writeFile(
      path.join(projectPath, 'config.json'),
      JSON.stringify(config)
    )
  })

  test('reading the config as ts', async () => {
    const data = {
      public: {},
    }

    const filepath = path.join(projectPath, 'transform.ts')
    const source = `export const transform = (): Record<string, unknown> => (${JSON.stringify(
      data
    )})`

    await fs.writeFile(filepath, source)

    const config = await getSnapletConfig()

    expect(config.source).toEqual(source)
  })

  test('reading empty ts file', async () => {
    const filepath = path.join(projectPath, 'transform.ts')
    await fs.writeFile(filepath, '')
    const config = await getSnapletConfig()

    expect(config.source).toEqual(SNAPLET_CONFIG_DEFAULTS)
  })

  test('non-existent files', async () => {
    const config = await getSnapletConfig()
    expect(config.source).toEqual(SNAPLET_CONFIG_DEFAULTS)
  })
})

describe('createSnapletConfig', () => {
  test('named exports', async () => {
    const config = await createSnapletConfig(
      `/fake/file/path`,
      `export const transform = () => ({ __isTransform: true })
       export const subset = { enabled: false, targets: [{ table: "public.team", rowLimit: 100 }] }`
    )

    expect(config.transform()).toMatchObject({ __isTransform: true })
    expect(config.subset).toMatchObject({
      enabled: false,
      targets: [{ table: 'public.team', rowLimit: 100 }],
    })
  })

  test('named export "config" for transforms for backwards compatibility', async () => {
    const config = await createSnapletConfig(
      `/fake/file/path`,
      `export const config = () => ({ __isTransform: true })
       export const subset = { enabled: false, targets: [{ table: "public.team", rowLimit: 100 }] }`
    )

    expect(config.transform()).toMatchObject({ __isTransform: true })
    expect(config.subset).toMatchObject({
      enabled: false,
      targets: [{ table: 'public.team', rowLimit: 100 }],
    })
  })

  test('export default taken as transform config for backwards compatibility', async () => {
    const config = await createSnapletConfig(
      `/fake/file/path`,
      `const transform = () => ({ __isTransform: true })
      export const subset = { enabled: false, targets: [{ table: "public.team", rowLimit: 100 }] }
      export default transform`
    )

    expect(config.transform()).toMatchObject({ __isTransform: true })
    expect(config.subset).toMatchObject({
      enabled: false,
      targets: [{ table: 'public.team', rowLimit: 100 }],
    })
  })

  test('module.exports taken as transform config for backwards compatibility', async () => {
    const config = await createSnapletConfig(
      `/fake/file/path`,
      `module.exports = () => ({ __isTransform: true })`
    )

    expect(config.transform()).toMatchObject({ __isTransform: true })
  })
})
