import fs from 'fs'
import os from 'os'
import path from 'path'

import {
  parseSystemConfig,
  getSystemConfig,
  saveSystemConfig,
} from './systemConfig.js'

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

describe('system config', () => {
  test('parses config correctly', () => {
    const x = parseSystemConfig({
      accessToken: 'hunter2',
    })
    expect(x.accessToken).toEqual('hunter2')
    expect(x.silenceUpgradeNotifications).toBe(false)
  })

  test('allows returning defaults for non-existent configs', () => {
    expect(getSystemConfig('/file/not/exists')).toMatchInlineSnapshot(`
      {
        "accessToken": undefined,
        "silenceUpgradeNotifications": false,
        "timeFormat": "RELATIVE",
      }
    `)
    const x = path.join(FIXTURES_BASE_PATH, 'system/valid/.snaplet/config.json')
    expect(getSystemConfig(x)).not.toBe(null)
  })

  test('envars get preferences', () => {
    process.env.SNAPLET_ACCESS_TOKEN = 'hunter3'
    process.env.SNAPLET_SILENCE_UPGRADE_NOTIFICATIONS = 'true'

    const x = parseSystemConfig({
      accessToken: 'hunter2',
    })

    expect(x.accessToken).toEqual('hunter3')
    expect(x.silenceUpgradeNotifications).toBe(true)
  })

  test('config file is optional', () => {
    process.env.SNAPLET_ACCESS_TOKEN = 'hunter2'
    process.env.SNAPLET_SILENCE_UPGRADE_NOTIFICATIONS = 'true'

    const x = getSystemConfig('/dev/null/config.json')

    expect(x.accessToken).toEqual('hunter2')
    expect(x.silenceUpgradeNotifications).toBe(true)
  })

  test('creates the system config base directory', () => {
    const snapletSystemConfigPath = path.join(
      os.tmpdir(),
      '.snaplet/config.json'
    )
    saveSystemConfig({ accessToken: 'hunter2' }, snapletSystemConfigPath)
    expect(fs.existsSync(snapletSystemConfigPath)).toBe(true)
  })
})
