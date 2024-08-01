import fs from 'fs'
import os from 'os'
import path from 'path'

import {
  parseProjectConfig,
  getProjectConfigAsync,
  saveProjectConfig,
} from './projectConfig.js'

const FIXTURES_BASE_PATH = path.resolve(
  __dirname,
  '../../../__fixtures__/configs'
)

beforeEach(() => {
  delete process.env.SNAPLET_CWD
  delete process.env.SNAPLET_PROJECT_ID
  delete process.env.SNAPLET_DATABASE_URL
  delete process.env.SNAPLET_SOURCE_DATABASE_URL
  delete process.env.SNAPLET_TARGET_DATABASE_URL
  delete process.env.SNAPLET_ACCESS_TOKEN
  delete process.env.SNAPLET_SILENCE_UPGRADE_NOTIFICATIONS
})

describe('project config', () => {
  test('parses a config correctly', () => {
    const x = parseProjectConfig({
      targetDatabaseUrl: 'pg://postgres:postgres@localhost:5432/postgres',
    })
    expect(x.targetDatabaseUrl).toEqual(
      'pg://postgres:postgres@localhost:5432/postgres'
    )
  })

  test('envars get preferences', () => {
    process.env.SNAPLET_PROJECT_ID = '2'
    process.env.SNAPLET_TARGET_DATABASE_URL = 'pg://localhost:5432/one'
    const x = parseProjectConfig({
      targetDatabaseUrl: 'pg://localhost:5432/three',
    })
    expect(x.targetDatabaseUrl).toEqual('pg://localhost:5432/one')
  })

  test('config file is optional', async () => {
    process.env.SNAPLET_PROJECT_ID = '1'
    process.env.SNAPLET_TARGET_DATABASE_URL = 'pg://localhost:5432/two'
    const x = await getProjectConfigAsync('/dev/null/config.json')
    expect(x.targetDatabaseUrl).toEqual('pg://localhost:5432/two')
  })

  test('handles parsing errors gracefully', async () => {
    try {
      await getProjectConfigAsync('/dev/null/config.json')
    } catch (e: any) {
      expect(e?.message.startsWith('Could not parse')).toBeTruthy()
    }
  })

  test('creates the project config `.snaplet` directory', () => {
    const snapletProjectConfigPath = path.join(
      os.tmpdir(),
      '.snaplet/config.json'
    )
    saveProjectConfig({ targetDatabaseUrl: 'pg://localhost:5432/db' }, snapletProjectConfigPath)
    expect(fs.existsSync(snapletProjectConfigPath)).toBe(true)
  })

  test('parses a valid configuration', async () => {
    const x = path.join(
      FIXTURES_BASE_PATH,
      'project/valid/.snaplet/config.json'
    )
    const y = await getProjectConfigAsync(x)

    expect(y.targetDatabaseUrl).toEqual('pg://localhost:5432/two')
  })

  test('Allow overrides for non-existent configs', async () => {
    expect(await getProjectConfigAsync('/file/not/found')).toEqual({
      projectId: undefined,
      snapshotId: undefined,
      dataSourceDbUrl: undefined,
      dataTargetDbUrl: undefined,
    })

    const x = path.join(
      FIXTURES_BASE_PATH,
      'project/valid/.snaplet/config.json'
    )

    expect((await getProjectConfigAsync(x)).targetDatabaseUrl).toEqual('pg://localhost:5432/two')
  })
})
