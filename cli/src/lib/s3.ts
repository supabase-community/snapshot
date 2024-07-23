import { S3Client, HeadObjectCommand } from '@aws-sdk/client-s3'
import { Upload } from '@aws-sdk/lib-storage'
import { type Readable } from 'stream'
import { config } from './config.js'

export type S3Settings = {
  region?: string
  endpoint?: string
  accessKeyId: string
  secretAccessKey: string
  bucket: string
}

export type StorageFile = string | Uint8Array | Buffer | Readable

type UploadToBucketOptions = {
  filename: string
  snapshotId: string
  settings?: S3Settings
  bytes: number
}

let cachedClient: S3Client

/**
 * initialize an S3 client, if no config
 * is passed in, we will return the existing
 * instance or throw an error.
 * */
export const initClient = (settings?: S3Settings) => {
  if (!config && !cachedClient) {
    throw new Error('No instance found, pass in config to create one.')
  }

  if (settings) {
    return new S3Client({
      region: settings.region,
      endpoint: settings.endpoint,
      credentials: {
        accessKeyId: settings.accessKeyId,
        secretAccessKey: settings.secretAccessKey,
      },
    })
  } else {
    return cachedClient
  }
}

export const uploadFileToBucket = async (
  body: StorageFile,
  options: UploadToBucketOptions,
  hooks: {
    onProgress: (progress: number) => void
  }
) => {
  const { filename, snapshotId, settings } = options

  const parellelUpload = new Upload({
    client: initClient(settings),
    params: {
      Bucket: settings?.bucket,
      Key: generateSnapshotFileKey({ filename, snapshotId }),
      Body: body,
    },
    tags: [
      // TODO_BEFORE_REVIEW: pass in the Snapshot tags
    ],
  })

  let progress = 0

  parellelUpload.on('httpUploadProgress', (ev) => {
    if (ev.loaded && ev.total) {
      progress = (ev.loaded / ev.total) * 100
    }
    hooks.onProgress(progress)
  })
  await parellelUpload.done()
}

/**
 * use snapshot file information to generate object key name
 */
export const generateSnapshotFileKey = (options: {
  filename: string
  snapshotId: string
}) => {
  return `${options.snapshotId}/${options.filename}`
}

/**
 * using a bucket and key, check if the object exists
 * if an error is thrown, it will return false.
 * */
export const checkIfObjectExists = async (
  bucket: string,
  key: string,
  settings?: S3Settings
) => {
  try {
    const client = await initClient(settings)
    await client.send(new HeadObjectCommand({ Bucket: bucket, Key: key }))

    return true
  } catch (err) {
    console.log(err)
    return false
  }
}
