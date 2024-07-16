import c from 'ansi-colors'
import dotenv from 'dotenv-defaults'
import execa from 'execa'
import path from 'path'
import { inspect } from 'util'

import { testDebug } from './debug.js'
import { ensureDir } from 'fs-extra'
import { getPathsV2 } from '@snaplet/sdk/cli'
import { getTestAccessToken } from './getTestAccessToken.js'
import { VIDEOLET_PROJECT_ID } from './index.js'

const debugCliRun = testDebug.extend('runSnapletCli')
const debugCliOutput = debugCliRun.extend('output')
// for the output we want to totally disable all prefix including namespace
debugCliOutput.namespace = ''

const CLI_LOCAL_BASE_DIR = path.resolve(__dirname, '../../../cli')
dotenv.config({
  defaults: path.resolve(CLI_LOCAL_BASE_DIR, '../.env.defaults'),
})

const SHELL = '/bin/bash'
type ProjectPaths = NonNullable<ReturnType<typeof getPathsV2>['project']>

export async function runSnapletCLI(
  args: string[],
  envOverrides: Partial<NodeJS.ProcessEnv> = {},
  paths?: Pick<ProjectPaths, 'base'>,
  options: any = {}
) {
  const config = path.resolve(CLI_LOCAL_BASE_DIR, './vite.config.mts')
  const entrypointTS = path.resolve(CLI_LOCAL_BASE_DIR, './src/index.ts')
  const entrypointJS = path.resolve(CLI_LOCAL_BASE_DIR, './dist/index.js')
  let SNAPLET_CLI = process.env.CI
    ? // In CI we use the transpiled JS version of the CLI to save some precious seconds of start time
      // from vite-node over each command
      `node ${entrypointJS}`
    : `vite-node -c ${config} ${entrypointTS} --`
  if (options.binary) {
    SNAPLET_CLI = '/tmp/snaplet/bin/cli'
  }

  const { SNAPLET_OS_HOMEDIR, SNAPLET_PROJECT_ID, SNAPLET_ACCESS_TOKEN } =
    process.env
  const SNAPLET_CWD = process.env.SNAPLET_CWD ?? paths?.base
  // We must ensure the CWD exists if provided before running the CLI
  if (SNAPLET_CWD) {
    await ensureDir(SNAPLET_CWD)
  }
  const accessToken =
    SNAPLET_ACCESS_TOKEN ??
    (await getTestAccessToken(SNAPLET_PROJECT_ID ?? VIDEOLET_PROJECT_ID))

  const env = {
    SNAPLET_DISABLE_TELEMETRY: '1',
    NODE_ENV: 'development',
    SNAPLET_HOSTNAME: 'http://localhost:8910',
    SNAPLET_API_HOSTNAME: 'http://localhost:8911',
    SNAPLET_OS_HOMEDIR,
    SNAPLET_CWD,
    SNAPLET_PROJECT_ID,
    SNAPLET_ACCESS_TOKEN: accessToken,
    ...envOverrides,
  }

  debugCliRun(
    [
      '',
      '==================================',
      `${c.bold('Running snaplet cli:')} ${SNAPLET_CLI}`,
      `${c.bold('args:')} ${args.join(' ')}`,
      `${c.bold('test:')} ${expect.getState().currentTestName}`,
      Object.keys(envOverrides).length
        ? `${c.bold('env overrides:')} ${inspect(envOverrides)}`
        : null,
      '==================================',
      '',
    ]
      .filter((v) => v != null)
      .join('\n')
  )

  const result = execa(SNAPLET_CLI!, args, {
    shell: SHELL,
    stderr: 'pipe',
    stdout: 'pipe',
    env: { ...env, DEBUG_COLORS: '1' },
    ...options,
  })
  result.stdout?.on('data', (chunk) => debugCliOutput(chunk.toString().trim()))
  result.stderr?.on('data', (chunk) => debugCliOutput(chunk.toString().trim()))

  return result
}
