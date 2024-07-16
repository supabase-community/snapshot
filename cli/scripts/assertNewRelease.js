#!/usr/bin/env node
/* eslint-env node */
const axios = require('axios')
const { version: newVersion } = require('../package.json')

const main = async () => {
  console.log(`Checking that Snaplet CLI ${newVersion} exists...`)
  if (await versionAlreadyExists()) {
    console.log(`... stopping release, version ${newVersion} already exists`)
    process.exitCode = 1
  } else {
    console.log(`... releasing, version ${newVersion} does not yet exist`)
  }
}

const versionAlreadyExists = async () => {
  const res = await axios.get(
    'https://api.snaplet.dev/admin/releaseVersion.findByVersion',
    {
      responseType: 'json',
      params: { input: { version: newVersion } },
      headers: {
        authorization: `Bearer ${process.env.ADMIN_ACCESS_TOKEN}`,
      },
    }
  )
  return res?.data?.result?.data?.version === newVersion
}

if (require.main === module) {
  main()
}
