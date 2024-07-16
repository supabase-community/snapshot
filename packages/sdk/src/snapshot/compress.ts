import execa from 'execa'
import fs from 'fs'
import zlib from 'zlib'

export async function compress(
  src: string,
  dst: string,
  keepOriginal = true,
  quality = '1'
) {
  const startTime = Date.now()
  const res = await execa('brotli', [
    `--output=${dst}`,
    keepOriginal ? '--keep' : '--rm',
    '--quality=' + quality,
    '--verbose',
    '--force',
    src,
  ])
  if (res.failed) {
    throw new Error(res.stderr)
  }
  const oldSize = fs.statSync(src).size
  const newSize = fs.statSync(dst).size
  return {
    oldSize,
    newSize,
    ms: Date.now() - startTime,
  }
}

export async function decompressTable(src: string, dst: string) {
  return new Promise((resolve, reject) => {
    const brotli = zlib.createBrotliDecompress()
    const reader = fs.createReadStream(src).pipe(brotli)
    reader.on('error', reject)

    const writer = fs.createWriteStream(dst)
    writer.on('finish', resolve).on('error', reject)

    reader.pipe(writer)
  })
}
