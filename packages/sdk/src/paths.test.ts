import fsExtra from 'fs-extra'
import path from 'path'
import tmp from 'tmp-promise'

import { findProjectPath, getProjectConfigPath } from './paths.js'

describe('project paths', () => {
  const baseFixturePath = path.resolve(
    __dirname,
    '../__fixtures__/paths/project'
  )

  test('the `.snaplet` directory is resolved', () => {
    const x = findProjectPath(path.join(baseFixturePath, 'valid'))
    expect(x!.endsWith('.snaplet')).toBe(true)
  })

  test('throws when a `.snaplet` directory cannot be found', () => {
    try {
      findProjectPath('/bad/path')
    } catch (e: any) {
      expect(e?.message).toMatchInlineSnapshot(
        `"Could not find a '.snaplet' project directory."`
      )
    }
  })

  test('throw when an invalid `SNAPLET_CWD` is provided', () => {
    try {
      process.env.SNAPLET_CWD = '/bad/path'
      findProjectPath()
    } catch (e: any) {
      expect(e?.message).toMatchInlineSnapshot(
        `"The specified 'SNAPLET_CWD' directory '/bad/path' does not exist."`
      )
    } finally {
      delete process.env.SNAPLET_CWD
    }
  })

  test('`SNAPLET_CONFIG` overrides default config path', () => {
    process.env.SNAPLET_CONFIG = '/x/config.json'
    expect(getProjectConfigPath()).toEqual('/x/config.json')
  })

  test('project in home dir', async () => {
    const homeDir = (await tmp.dir()).path
    const systemDir = path.join(homeDir, '.snaplet')

    try {
      process.env.SNAPLET_OS_HOMEDIR = process.env.SNAPLET_CWD = homeDir

      await fsExtra.mkdir(systemDir)

      expect(findProjectPath()).toEqual(systemDir)
    } finally {
      delete process.env.SNAPLET_OS_HOMEDIR
      delete process.env.SNAPLET_CWD
    }
  })
})
