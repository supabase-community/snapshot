#!/usr/bin/env node
/* eslint-env node */
import { mkdtemp } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import fs from 'fs/promises'
import path from 'path'
import { build as tsupBuild } from 'tsup'
import execa from 'execa'

import { dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const cliPath = path.resolve(__dirname, '..', '..', '..', 'cli')
const sdkPath = path.resolve(__dirname, '..', '..', 'sdk')
const pkgRootPath = path.resolve(__dirname, '..')

const computeDeps = async (sdkPkg, cliPkg) => {
  const deps = {
    ...sdkPkg.dependencies,
    ...cliPkg.dependencies,
  }

  delete deps['@snaplet/cli']
  delete deps['@snaplet/sdk']
  delete deps['snaplet']

  return deps
}

const updatePkg = async () => {
  console.log(`Reading package.json's...`)
  const sdkPkg = JSON.parse(
    await fs.readFile(path.resolve(sdkPath, 'package.json'))
  )

  const cliPkg = JSON.parse(
    await fs.readFile(path.resolve(cliPath, 'package.json'))
  )

  const pkgPath = path.resolve(pkgRootPath, 'package.json')
  const pkg = JSON.parse(await fs.readFile(pkgPath))

  console.log(`Syncing version with cli version (${cliPkg.version})...`)
  pkg.version = cliPkg.version

  console.log('Syncing deps with sdk and cli...')
  pkg.dependencies = await computeDeps(sdkPkg, cliPkg)

  await fs.writeFile(pkgPath, JSON.stringify(pkg, null, 2))
}

const installDeps = async () => {
  console.log('Installing deps...')

  await execa('yarn', ['install'], {
    cwd: pkgRootPath,
    stdio: 'inherit',
    env: {
      YARN_ENABLE_IMMUTABLE_INSTALLS: false,
    },
  })
}

const build = async () => {
  console.log('Building...')
  await tsupBuild({})
}

const pack = async (packDestination = 'snaplet-npm.tgz') => {
  console.log('Packing release...')
  const dir = await mkdtemp(path.join(tmpdir(), 'snaplet-npm-pack-'))

  await execa('npm', ['pack', '--pack-destination', dir], {
    cwd: pkgRootPath,
    stdio: 'inherit',
  })

  await execa(
    'mv',
    [path.join(dir, '*'), path.resolve(pkgRootPath, packDestination)],
    {
      cwd: pkgRootPath,
      shell: true,
      stdio: 'inherit',
    }
  )
}

const prepareRelease = async (packDestination) => {
  console.log('Preparing release...')
  await updatePkg()
  await installDeps()
  await build()
  await pack(packDestination)
}

const tasks = {
  build,
  prepareRelease,
}

const main = async () => {
  await tasks[process.argv[2]](...process.argv.slice(3))
  console.log('Done!')
}

main()
