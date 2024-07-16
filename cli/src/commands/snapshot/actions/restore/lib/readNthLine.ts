import execa from 'execa'
import fs from 'fs'
import readline from 'readline'

const outOfRangeError = function (filepath: string, n: number) {
  return new RangeError(
    `Line with index ${n} does not exist in '${filepath}. Note that line indexing is zero-based'`
  )
}

function readNthLineFromStream(n: number, filepath: string) {
  return new Promise<string>(function (resolve, reject) {
    if (n < 0 || n % 1 !== 0)
      return reject(new RangeError(`Invalid line number`))

    let cursor = 0
    const input = fs.createReadStream(filepath)
    const rl = readline.createInterface({ input })

    rl.on('line', function (line) {
      if (cursor++ === n) {
        rl.close()
        input.close()
        resolve(line)
      }
    })

    rl.on('error', reject)

    input.on('end', function () {
      reject(outOfRangeError(filepath, n))
    })
  })
}

async function readNthLineFromSed(n: number, filepath: string) {
  const { stdout } = await execa('sed', ['-n', `${n}p`, filepath])
  return stdout
}

export async function readNthLine(n: number, filepath: string) {
  try {
    return await readNthLineFromSed(n, filepath)
  } catch (_) {
    return readNthLineFromStream(n, filepath)
  }
}
