#!/usr/bin/env node
const fs = require('fs/promises')
const path = require('path')
const execa = require('execa')

const main = async () => {
  const pkg = require('../package.json')
  const currentVersion = pkg.devDependencies.snaplet
  const nextVersion = require('../cli/package.json').version
  pkg.devDependencies.snaplet = nextVersion

  console.log(`Upgrading snaplet from ${currentVersion} to ${nextVersion}...`)

  await fs.writeFile(
    require.resolve('../package.json'),
    JSON.stringify(pkg, null, 2)
  )

  await execa('yarn', ['install'], {
    stdio: 'inherit',
    cwd: path.join(__dirname, '..'),
    env: {
      YARN_ENABLE_IMMUTABLE_INSTALLS: false,
    },
  })
}

main()
