#!/usr/bin/env node
/* eslint-env node */

const fs = require('fs')
const https = require('https')
const os = require('os')
const path = require('path')
const packageJSON = require('../package.json')

main()

async function main() {
  const platformMap = new Map([
    ['darwin', 'macos'],
    ['linux', 'linux'],
    ['win32', 'win'],
  ])

  const platform = platformMap.get(os.platform())

  if (!platform) {
    console.error(`Your current platform is not supported.`)
    process.exit(1)
  }

  const url = `https://snaplet-public.s3-accelerate.amazonaws.com/cli/beta/snaplet-${platform}-${packageJSON.version}`

  const target = path.join(__dirname, '..', 'bin', 'snaplet')

  try {
    fs.mkdirSync(path.dirname(target))
  } catch (e) {
    if (e.code !== 'EEXIST') {
      throw e
    }
  }

  const file = fs.createWriteStream(target)

  await new Promise((res, rej) => {
    console.log(`Downloading Snaplet binary to ${target}...`)

    https.get(url, (response) => {
      const totalBytes = response.headers['content-length']
      response.pipe(file)

      let lastPercentage = 0

      file.on('drain', () => {
        const percentage = Math.floor((file.bytesWritten / totalBytes) * 100)
        if (percentage > lastPercentage) {
          process.stdout.write(`\rDownload at ${percentage}%`)
          lastPercentage = percentage
        }
      })

      file.on('finish', () => {
        process.stdout.write(`\rDownload complete.\n`)
        file.close()
        res()
      })
      file.on('error', rej)
    })
  })

  fs.chmodSync(target, '755')

  if (platform === 'win') {
    fs.renameSync(target, `${target}.exe`)
  }
}
