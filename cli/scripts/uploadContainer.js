#!/usr/bin/env node

/* eslint-env node */
const execa = require('execa')
const path = require('path')
const axios = require('axios')

const { version: newVersion } = require('../package.json')

const EXECA_OPTIONS = {
  cwd: path.resolve(__dirname, '../'),
  shell: true,
  stdio: 'inherit',
}

async function downloadAssetFromRelease() {
  console.log(`Downloading asset from release v${newVersion}...`)

  const { data: releases } = await axios.get(
    `https://api.github.com/repos/snaplet/snaplet/releases`,
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

  const asset = release.assets.find((a) =>
    a.name.startsWith('snaplet-snapshot-worker')
  )
  await execa(
    `curl -L -H "Accept: application/octet-stream" -H "Authorization: token ${process.env.GITHUB_TOKEN}" -o ${asset.name} ${asset.url}`,
    EXECA_OPTIONS
  )

  console.log(`Asset downloaded from release v${newVersion}`)

  return asset.name
}

async function uploadImageToRegistry(imagePath) {
  const snapletEcrUrl =
    '144041620613.dkr.ecr.eu-central-1.amazonaws.com/snaplet'

  // Restore the Docker image
  await execa(`docker load < ${imagePath}`, EXECA_OPTIONS)

  // Tag CLI Docker image
  // Tag as :latest
  await execa(
    `docker tag snaplet-snapshot-worker ${snapletEcrUrl}/cli`,
    EXECA_OPTIONS
  )

  // Tag as :<version>
  await execa(
    `docker tag snaplet-snapshot-worker ${snapletEcrUrl}/cli:${newVersion}`,
    EXECA_OPTIONS
  )

  // Login to Container Registery
  await execa(
    `aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin ${snapletEcrUrl}`,
    EXECA_OPTIONS
  )

  // Push images to Container Registery
  await execa(`docker push ${snapletEcrUrl}/cli`, EXECA_OPTIONS)
}

async function uploadContainer() {
  const assetPath = await downloadAssetFromRelease()
  await uploadImageToRegistry(assetPath)
}

uploadContainer().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e.message)
  process.exit(1)
})
