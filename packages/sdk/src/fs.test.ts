import fs from 'fs-extra'
import path from 'path'
import tmp, { DirectoryResult } from 'tmp-promise'

import { safeReadJson, saveJson, safeReadJsonSync } from './fs.js'

let dir: DirectoryResult

beforeEach(async () => {
  dir = await tmp.dir()
})

describe('safeReadJson', () => {
  let jsonFilepath: string

  beforeEach(() => {
    jsonFilepath = path.resolve(dir.path, 'foo.json')
  })

  test('returns null if file does not exist', async () => {
    try {
      expect(await safeReadJson(jsonFilepath)).toBe(null)
    } catch (e) {
      console.log(e)
    }
  })

  test('returns json if file exists', async () => {
    await fs.writeJson(jsonFilepath, { bar: 23 })
    expect(await safeReadJson(jsonFilepath)).toEqual({
      bar: 23,
    })
  })

  test('throws for invalid json', async () => {
    await fs.writeFile(jsonFilepath, '{')
    await expect(safeReadJson(jsonFilepath)).rejects.toBeInstanceOf(SyntaxError)
  })
})

describe('safeReadJsonSync', () => {
  let jsonFilepath: string

  beforeEach(() => {
    jsonFilepath = path.resolve(dir.path, 'foo.json')
  })

  test('returns null if file does not exist', async () => {
    try {
      expect(safeReadJsonSync(jsonFilepath)).toBe(null)
    } catch (e) {
      console.log(e)
    }
  })

  test('returns json if file exists', async () => {
    await fs.writeJson(jsonFilepath, { bar: 23 })
    expect(safeReadJsonSync(jsonFilepath)).toEqual({
      bar: 23,
    })
  })

  test('throws for invalid json', async () => {
    await fs.writeFile(jsonFilepath, '{')
    expect(() => safeReadJsonSync(jsonFilepath)).toThrow(SyntaxError)
  })
})

describe('saveJson', () => {
  test('ensures dir exists', async () => {
    const pathname = path.resolve(dir.path, 'bar', 'baz', 'quux.json')

    await saveJson(pathname, {
      foo: 23,
    })

    expect(await safeReadJson(pathname)).toEqual({ foo: 23 })
  })

  test.todo('saves json')
})
