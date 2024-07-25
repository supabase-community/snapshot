import { config } from '~/lib/config.js'
import { exitWithError } from '~/lib/exit.js'
import { S3Settings } from '~/lib/s3.js'
import { activity } from '~/lib/spinner.js'
import { logError } from './logError.js'

export const s3Settings = async () => {
  const act = activity('S3 settings', 'fetching...')
  const project = await config.getProject()

  const partialSettings: Partial<S3Settings> = {
    accessKeyId: project.s3AccessKeyId,
    bucket: project.s3Bucket,
    region: project.s3Region,
    secretAccessKey: project.s3SecretAccessKey,
    endpoint: project.s3Endpoint
  }

  const { region, endpoint, ...required } = partialSettings
  const undefinedEntries = Object.entries(required).filter(([k, v]) => !v)

  if (undefinedEntries.length === 0) {
    act.done()
    return partialSettings as S3Settings
  } else {
    act.fail('Failed')
    logError([
      `Snaplet requires parameters to pass into S3`,
      `Missing keys: ${undefinedEntries.map(([k, v]) => k).join(', ')}`,
    ])

    return exitWithError('CONFIG_INVALID_SCHEMA')
  }
}
