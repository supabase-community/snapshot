#!/usr/bin/env node

/* eslint-env node */
const execa = require('execa')
const path = require('path')
const fs = require('fs')

const { version: newVersion } = require('../package.json')
const { downloadAssetsFromRelease } = require('./downloadAssetsFromRelease.js')

async function uploadAssetsToS3() {
  console.log('Uploading assets to S3...')

  const cwd = path.resolve(__dirname, '../')

  const assets = fs.readdirSync(path.join(cwd, 'bin'))

  await Promise.all(
    assets.map((asset) =>
      execa(
        `aws s3 cp`,
        [
          `bin/${asset}`,
          `s3://snaplet-public/cli/beta/${asset}`,
          `--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers`,
        ],
        { shell: true, stdio: 'inherit' }
      )
    )
  )

  console.log('Assets uploaded to S3')
}

async function uploadCLI() {
  await downloadAssetsFromRelease({
    newVersion,
    outDir: path.join(__dirname, '..', 'bin'),
    filter: (asset) =>
      asset.name.startsWith('snaplet-') &&
      !asset.name.startsWith('snaplet-snapshot-worker') &&
      !asset.name.startsWith('snaplet-npm'),
  })
  await uploadAssetsToS3()
}

uploadCLI().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e.message)
  process.exit(1)
})
