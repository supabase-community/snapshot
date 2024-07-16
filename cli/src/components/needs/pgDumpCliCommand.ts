import execa from 'execa'

import { exitWithError } from '~/lib/exit.js'

import { logError } from './logError.js'

export const pgDumpCliCommand = async () => {
  try {
    await execa('pg_dump', ['--version'])
  } catch (error) {
    logError([
      'The **pg_dump** binary could not be located and is required. Please install **pg_dump** on your system.',
    ])
    await exitWithError('CLI_BIN_REQUIRE_PGDUMP')
  }
}
