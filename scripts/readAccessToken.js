const { readFile } = require('fs/promises')
const path = require('path')
const once = require('lodash/once')

exports.readAccessToken = once(async () => {
  const configContents = await readFile(
    path.join(process.env.HOME, '.config', 'snaplet', 'system.json')
  )

  return JSON.parse(configContents).accessToken
})
