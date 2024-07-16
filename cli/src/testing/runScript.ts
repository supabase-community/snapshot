import c from 'ansi-colors'
import execa from 'execa'
import path from 'path'

import { testDebug } from './debug.js'
import { remove, writeFile } from 'fs-extra'
import { uniqueId } from 'lodash'

const ROOT_DIR = path.resolve(__dirname, '../../..')
const CLI_DIR = path.resolve(ROOT_DIR, 'cli')

const debugScriptRun = testDebug.extend('runSnapletCli')
const debugScriptOutput = debugScriptRun.extend('output')

interface RunScriptOptions {
  env?: Record<string, string>
}

export const runScript = async (
  script: string,
  { env = {} }: RunScriptOptions = {}
) => {
  debugScriptRun(
    [
      '',
      '==================================',
      `${c.bold('Running script:')}`,
      `${c.bold('test:')} ${expect.getState().currentTestName}`,
      `${c.bold('script:')} ${script}`,
      '==================================',
      '',
    ]
      .filter((v) => v != null)
      .join('\n')
  )

  const scriptPath = path.join(
    process.env.SNAPLET_CWD!,
    `${uniqueId('script')}.mts`
  )

  await writeFile(scriptPath, script)

  try {
    const viteConfigPath = path.resolve(CLI_DIR, './vite.config.mts')

    const result = execa(
      'vite-node',
      ['-c', viteConfigPath, '-r', CLI_DIR, scriptPath],
      {
        stderr: 'pipe',
        stdout: 'pipe',
        env: {
          DEBUG_COLORS: '1',
          NODE_PATH: path.resolve(ROOT_DIR, 'node_modules'),
          ...env,
        },
      }
    )
    result.stdout?.on('data', (chunk) =>
      debugScriptOutput(chunk.toString().trim())
    )
    result.stderr?.on('data', (chunk) =>
      debugScriptOutput(chunk.toString().trim())
    )

    return result
  } catch (e) {
    await remove(script)
    throw e
  }
}
