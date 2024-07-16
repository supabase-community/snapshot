import {
  ConnectionString,
  CONNECTION_STRING_PROTOCOLS,
  encodeConnectionString,
} from '@snaplet/sdk/cli'

import { exitWithError } from '~/lib/exit.js'

import { logError } from './logError.js'

export const validConnectionString = async (cs: string) => {
  let connString = new ConnectionString(cs)
  if (connString.validationErrors === null) {
    return connString
  }

  // attempt to auto-encode the connection string
  if (connString.validationErrors !== 'INVALID') {
    connString = new ConnectionString(
      encodeConnectionString(connString).toString()
    )

    if (connString.validationErrors === null) {
      return connString
    }
  }

  let reason
  if (connString.validationErrors === 'UNRECOGNIZED_PROTOCOL') {
    reason = `The protocol is not recognized. Use one of ${CONNECTION_STRING_PROTOCOLS.join(
      ', '
    )}`
  } else {
    reason = `Unable to parse connection string. Learn more: https://docs.snaplet.dev/guides/postgresql#connection-strings`
  }
  logError([
    `Could not validate connection string: "${connString.toScrubbedString()}"`,
    reason,
  ])
  return await exitWithError('CONNECTION_URL_INVALID')
}
