import { needs } from '~/components/needs/index.js'
import boxen from '~/vendor/boxen.js'
import c from 'ansi-colors'
import wordwrap from 'word-wrap'

import { CommandOptions } from './devCommand.types.js'
import { findPreviewDatabaseUrl } from './lib/findPreviewDatabaseUrl.js'
import { getPreviewDatabaseNameFromGitBranch } from './lib/getPreviewDatabaseNameFromGitBranch.js'
import { ConnectionString, onGitBranchChange } from '@snaplet/sdk/cli'
import { createProxy } from '@snaplet/sdk/cli'
import { getProxyUrl } from './lib/getProxyUrl.js'
import { Server } from 'net'
import { createPreviewDatabase } from '../previewDatabase/actions/create/lib/createPreviewDatabase.js'
import { captureEvent } from '~/lib/telemetry.js'
import { once } from 'lodash'

const captureDevListenOnce = once((options) =>
  captureEvent('$command:dev:listen', { options })
)

export async function handler(options: CommandOptions) {
  await captureEvent('$command:dev:start', { options })
  const projectId = await needs.projectId()

  let server: Server | undefined

  for await (const gitBranch of onGitBranchChange()) {
    // Clear the console
    process.stdout.write('\x1Bc')

    console.log(c.blue('█▄▄ █▀█ ▄▀█ █▄░█ █▀▀ █░█   █▀█ █▀█ █▀█ ▀▄▀ █▄█'))
    console.log(
      c.blue('█▄█ █▀▄ █▀█ █░▀█ █▄▄ █▀█   █▀▀ █▀▄ █▄█ █░█ ░█░'),
      c.magenta(' beta [powered by Neon.tech]')
    )
    console.log()
    console.log(c.cyanBright('What is this?'))
    console.log(
      wordwrap(
        c.magenta(
          'It creates a preview database branch for each local git branch, so you always code against an up-to-date snapshot of production accurate data.'
        ),
        { width: 80 }
      )
    )
    console.log(c.cyanBright('How does it work?'))
    console.log(
      wordwrap(
        c.magenta(
          `It provides a local database URL that proxies all traffic to a remote preview database. When you checkout a git-branch, we create a preview-database branch based off the latest snapshot tagged "main."`
        ),
        { width: 80 }
      )
    )
    console.log()
    console.log()

    const previewDatabaseName = getPreviewDatabaseNameFromGitBranch(gitBranch)

    console.log('Name [from git]:', previewDatabaseName)

    // TODO: We need to supply the snapshot as well.
    let previewDatabaseUrl = await findPreviewDatabaseUrl({
      projectId,
      previewDatabaseName,
    })

    if (!previewDatabaseUrl) {
      const snapshot = await needs.snapshot({
        latest: true,
        hosts: ['cloud'],
        tags: ['main'],
      })

      console.log('Snapshot:', snapshot.summary.name)

      const previewBranch = await createPreviewDatabase({
        name: previewDatabaseName,
        projectId,
        snapshot,
      })
      previewDatabaseUrl = previewBranch.connectionUrl
    }
    if (!previewDatabaseUrl) {
      throw new Error('Could not find or create preview database')
    }

    console.log('Remote URL:', previewDatabaseUrl)

    const parsedPreviewDatabaseUrl = new ConnectionString(previewDatabaseUrl)

    if (server) {
      await new Promise<void>((resolve, reject) => {
        server!.close((err) => {
          if (err) {
            reject(err)
          } else {
            resolve()
          }
        })
      })
    }

    server = createProxy(parsedPreviewDatabaseUrl).server
    server.listen(options.port, async () => {
      const proxyUrl = getProxyUrl({
        previewDatabaseUrl: parsedPreviewDatabaseUrl,
        port: options.port,
      })

      console.log()
      console.log(
        boxen(c.yellowBright(proxyUrl.toString()), {
          padding: 2,
          title: 'Use this Database URL',
          titleAlignment: 'center',
        })
      )

      await captureDevListenOnce(options)
    })
  }
}
