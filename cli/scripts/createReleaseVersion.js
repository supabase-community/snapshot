#!/usr/bin/env node

/* eslint-env node */
const axios = require('axios')
const { version: newVersion } = require('../package.json')

async function createReleaseVersion() {
  console.log(`Creating version ${newVersion}...`)

  const { data } = await axios.post(
    'https://api.snaplet.dev/admin/releaseVersion.create',
    { newVersion },
    {
      responseType: 'json',
      headers: {
        authorization: `Bearer ${process.env.ADMIN_ACCESS_TOKEN}`,
      },
    }
  )

  console.log(`Version ${newVersion} created`)
  console.log(data)
}

createReleaseVersion().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e.message)
  process.exit(1)
})
