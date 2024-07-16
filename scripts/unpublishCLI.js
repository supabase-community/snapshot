#!/usr/bin/env node
/* eslint-env node */
// context(justinvdm, 19 June 2023): Script for preventing a release from being downloadable:
// * Changes the release channel to PRIVATE in our ReleaseVersion table so that it isn't downloadable using
//   `snaplet upgrade` or app.snaplet.dev/get-cli
// * Runs `npm unpublish` for the release

const axios = require('axios')
const execa = require('execa')
const prompts = require('prompts')
const { readAccessToken } = require('./readAccessToken.js')

const VERSION = parseVersion(process.argv[2] || '')

async function updateChannelToPrivate() {
  await axios.post(
    'https://api.snaplet.dev/admin/releaseVersion.updateChannelToPrivate',
    { version: VERSION },
    {
      responseType: 'json',
      headers: {
        authorization: `Bearer ${await readAccessToken()}`,
      },
    }
  )
}

async function unpublishFromNpm() {
  const spec = `snaplet@${VERSION}`

  await execa('npm', ['unpublish', spec, '--loglevel=verbose'], {
    stdio: 'inherit',
  })
}

const STEPS = {
  'Updating channel to private in ReleaseVersion table': updateChannelToPrivate,
  'Unpublish from npm': unpublishFromNpm,
}

const main = async () => {
  if (process.argv.find((v) => v === '-h' || v === '--help' || v === 'help')) {
    console.log(`
yarn unpublish-cli: Script for preventing a release from being downloadable:
* Changes the release channel to PRIVATE in our ReleaseVersion table so that it isn't downloadable using \`snaplet upgrade\` or app.snaplet.dev/get-cli
* Runs \`npm unpublish\` for the \`snaplet\` package on npm for the given version

If one of these unpublish steps fail, the script will still let the other step proceed.

**NOTE**: Once unpublished, the cli version will no longer be downloadable. This action is not reversible.

Usage: yarn unpublish-cli <version>

Example: yarn unpublish 1.2.3
`)
    return
  }

  console.log(
    `This will **UNPUBLISH** cli version ${VERSION}, it will no longer be downloadable. This action is not reversible.`
  )
  console.log('')

  const response = await prompts({
    type: 'confirm',
    name: 'value',
    message: 'Are you sure you want to do this?',
    initial: false,
  })

  if (!response.value) {
    console.log('Aborting unpublish.')
    return
  }

  if (!VERSION || VERSION === '0.0.0') {
    throw new Error('No version argument given to unpublishCli script')
  }

  const failedSteps = []

  console.log(`Unpublishing version ${VERSION}...`)

  for (const [stepDescription, stepFn] of Object.entries(STEPS)) {
    console.log(`${stepDescription}...`)

    try {
      await stepFn()
    } catch (e) {
      console.log(e)
      failedSteps.push(stepDescription)
    }
  }

  if (failedSteps.length) {
    if (failedSteps.length < Object.keys(STEPS).length) {
      console.log(
        'The following steps failed and will need to be run manually:'
      )

      console.log(failedSteps.map((step) => `* ${step}`).join('\n'))
    } else {
      console.log('All of the unpublish steps failed.')
    }

    process.exitCode = 1
  }
}

function parseVersion(version) {
  version = version.trim()
  return version.startsWith('v') ? version.slice(1) : version
}

main()
