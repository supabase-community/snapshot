import { formatDatabaseName } from '@snaplet/sdk/cli'

const PREFIX = 'pdb'

export function getPreviewDatabaseNameFromGitBranch(gitBranch: string) {
  return [PREFIX, formatDatabaseName(gitBranch)].join('-')
}
