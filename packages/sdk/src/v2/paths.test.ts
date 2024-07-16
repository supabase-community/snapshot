import tmp from 'tmp-promise'
import { ensureProjectPaths } from './paths.js'
import path from 'path'
import fs, { move, pathExists } from 'fs-extra'
import { tmpdir } from 'os'

// context(justinvdm, 3 Jan 2024): Some other test seems to create `.snaplet` in the tmpdir root
const avoidTmpSnapletDir = () => {
  let movedTo: string | null = null
  const tmpSnapletDir = path.join(tmpdir(), '.snaplet')

  beforeEach(async () => {
    if (await pathExists(tmpSnapletDir)) {
      movedTo = await tmp.tmpName()
      await move(tmpSnapletDir, movedTo)
    }
  })

  afterEach(async () => {
    if (movedTo) {
      await move(movedTo, tmpSnapletDir)
      movedTo = null
    }
  })
}

describe('paths', () => {
  let rootDir: string
  const originalCwd = process.env.SNAPLET_CWD

  avoidTmpSnapletDir()

  beforeEach(async () => {
    rootDir = (await tmp.dir()).path
    process.env.SNAPLET_CWD = rootDir
  })

  afterEach(() => {
    process.env.SNAPLET_CWD = originalCwd
  })

  describe('ensureProjectPaths', () => {
    test('returns project paths if base path already exists', async () => {
      const subDir = path.join(rootDir, 'foo')
      const expectedPath = path.join(rootDir, '.snaplet')
      await fs.mkdir(subDir)
      await fs.mkdir(expectedPath)
      process.env.SNAPLET_CWD = subDir

      expect((await ensureProjectPaths()).base).toEqual(expectedPath)
    })

    test('creates dir if it does not yet exists', async () => {
      const expectedPath = path.join(rootDir, '.snaplet')
      expect(await fs.pathExists(expectedPath)).toBe(false)

      expect((await ensureProjectPaths()).base).toEqual(expectedPath)
      expect(await fs.pathExists(expectedPath)).toBe(true)
    })
  })
})
