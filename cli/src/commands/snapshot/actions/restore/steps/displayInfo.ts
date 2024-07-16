import { CloudSnapshot, formatTime } from '@snaplet/sdk/cli'
import wordwrap from 'word-wrap'

import { fmt } from '~/lib/format.js'

import c from 'ansi-colors'

export const displaySnapshotSummary = (summary: CloudSnapshot) => {
  console.log()
  if (summary.summary.isSupabaseConnection) {
    console.log(' ', c.green('⚡ Restoring from a Supabase database'))
  }
  console.log()
  console.log(
    ' ',
    fmt(`
  **Name:** ${summary?.summary?.name}
  **Created:** ${formatTime(summary?.summary?.date)}
  **Size:** ${summary?.summary?.totalSize}
  **Host:** ${summary?.summary?.origin}
  **Tables:**
  `)
  )
  console.log(
    wordwrap(
      summary?.summary?.tables
        ?.map(({ schema, table }) => `${schema}.${table}`)
        .sort()
        .join(', ') ?? '',
      { indent: '    ' }
    )
  )
  console.log()
}
