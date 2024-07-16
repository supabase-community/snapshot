import { ConnectionString } from '@snaplet/sdk/cli'

export function getProxyUrl({
  previewDatabaseUrl,
  port,
}: {
  previewDatabaseUrl: ConnectionString
  port: number
}) {
  return previewDatabaseUrl
    .setHostname('localhost')
    .setPort(port)
    .setPassword('')
}
