import fg from 'fast-glob'
import fs from 'fs-extra'
import path from 'path'
import { fileURLToPath } from 'url'

export const safeReadJson = async <Data>(
  filepath: string
): Promise<Data | null> => {
  try {
    return await fs.readJSON(filepath)
  } catch (error) {
    if ((error as any)?.code === 'ENOENT') {
      return null
    } else {
      throw error
    }
  }
}

export const safeReadJsonSync = <Data>(filepath: string): Data | null => {
  try {
    return fs.readJSONSync(filepath)
  } catch (error) {
    if ((error as any)?.code === 'ENOENT') {
      return null
    } else {
      throw error
    }
  }
}

export const saveJson = async <Data>(
  filepath: string,
  data: Data
): Promise<void> => {
  await fs.mkdirp(path.dirname(filepath))
  await fs.writeJSON(filepath, data, { spaces: 2 })
}

/**
 *
 * @param directoryPath
 * @returns total size of all the files in the specified directory
 */
export const calculateDirectorySize = (directoryPath: string) =>
  fg
    .sync(`${directoryPath}/*`)
    .map((filepath: string) => {
      return fs.statSync(filepath).size
    })
    .reduce((runningTotal, current) => {
      return runningTotal + current
    }, 0)

const toPath = (urlOrPath: string | URL) =>
  urlOrPath instanceof URL ? fileURLToPath(urlOrPath) : urlOrPath

// context(justinvdm, 15 November 2023): Taken from https://github.com/sindresorhus/find-up-simple/blob/main/index.js
// Reasoning: I could not find a well maintained and used package that does this purpose, does it async, exposes commonjs
// for us to consume, and exposes typescript typedefs. The next best thing seemed to be copy-paste the code from a
// trusted package author - besides, its 20 lines of code.
export async function findUp(
  name: string,
  {
    cwd = process.cwd(),
    type = 'file',
    stopAt,
  }: {
    cwd?: string
    type?: 'file' | 'directory'
    stopAt?: string
  } = {}
) {
  let directory = path.resolve(toPath(cwd) ?? '')
  const { root } = path.parse(directory)
  stopAt = path.resolve(directory, toPath(stopAt ?? root))

  while (directory && directory !== stopAt && directory !== root) {
    const filePath = path.isAbsolute(name) ? name : path.join(directory, name)

    try {
      const stats = await fs.stat(filePath) // eslint-disable-line no-await-in-loop
      if (
        (type === 'file' && stats.isFile()) ||
        (type === 'directory' && stats.isDirectory())
      ) {
        return filePath
      }
    } catch {
      //
    }

    directory = path.dirname(directory)
  }
}
