/* eslint-env node */
/* eslint-global Promise */
const execa = require('execa')
const path = require('path')
const fs = require('fs')
const axios = require('axios')

exports.downloadAssetsFromRelease = async function downloadAssetsFromRelease({
  newVersion,
  filter,
  outDir,
}) {
  console.log(`Downloading assets from release v${newVersion}...`)

  const cwd = path.resolve(__dirname, '../')

  try {
    fs.mkdirSync(path.join(cwd, 'bin'))
    // eslint-disable-next-line no-empty
  } catch (_) {}

  const { data: releases } = await axios.get(
    `https://api.github.com/repos/snaplet/snapshot/releases`,
    {
      headers: {
        Authorization: `token ${process.env.GITHUB_TOKEN}`,
      },
    }
  )

  const release = releases.find((r) => r.name === `v${newVersion}`)
  if (!release) {
    throw new Error(`Could not find release for version ${newVersion}`)
  }

  const assets = release.assets.filter(filter)

  await Promise.all(
    assets.map((asset) =>
      execa(
        `curl -L -H "Accept: application/octet-stream" -H "Authorization: token ${
          process.env.GITHUB_TOKEN
        }" -o ${path.join(outDir, asset.name)} ${asset.url}`,
        {
          shell: true,
          stdio: 'inherit',
        }
      )
    )
  )

  console.log(`Assets downloaded from release v${newVersion}`)
  return assets
}
