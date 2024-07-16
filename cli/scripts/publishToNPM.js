#!/usr/bin/env node
/* eslint-env node */

const execa = require('execa')
const path = require('node:path')
const { mkdtemp } = require('node:fs/promises')
const { tmpdir } = require('node:os')
const { downloadAssetsFromRelease } = require('./downloadAssetsFromRelease.js')

async function publishToNPM() {
  const { version: newVersion } = require('../package.json')
  const dir = await mkdtemp(path.join(tmpdir(), 'npm-publish-'))

  // eslint-disable-next-line no-undef
  const packagesByName = new Set([`snaplet-npm-${newVersion}.tgz`])

  const assets = await downloadAssetsFromRelease({
    newVersion,
    outDir: dir,
    filter: (asset) => packagesByName.has(asset.name),
  })

  console.log('Publishing to NPM...')

  let hasErrored = false

  for (const asset of assets) {
    try {
      await execa(
        'npm',
        ['publish', '--access=public', path.join(dir, asset.name)],
        {
          stdio: 'inherit',
          cwd: dir,
        }
      )
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error(e)
      hasErrored = true
    }
  }

  if (hasErrored) {
    process.exitCode = 1
    return
  }
}

publishToNPM().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e.message)
  process.exit(1)
})
