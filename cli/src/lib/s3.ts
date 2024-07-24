import {
  S3Client,
  HeadObjectCommand,
  ListObjectsV2Command,
  GetObjectCommand,
} from '@aws-sdk/client-s3'
import { Upload } from '@aws-sdk/lib-storage'
import { type Readable } from 'stream'

export type S3Settings = {
  region?: string
  endpoint?: string
  accessKeyId: string
  secretAccessKey: string
  bucket: string
}

export type StorageFile = string | Uint8Array | Buffer | Readable

type UploadToBucketOptions = {
  bucket: string
  key: string
  client: S3Client
}

/**
 * initialize an S3 client, if no config
 * is passed in, we will return the existing
 * instance or throw an error.
 * */
export const initClient = (settings: S3Settings) => {
  return new S3Client({
    region: settings.region,
    endpoint: settings.endpoint,
    credentials: {
      accessKeyId: settings.accessKeyId,
      secretAccessKey: settings.secretAccessKey,
    },
  })
}

export const uploadFileToBucket = async (
  body: StorageFile,
  options: UploadToBucketOptions,
  hooks?: {
    onProgress: (progress: number) => void
  }
) => {
  const { client, bucket, key } = options

  const parellelUpload = new Upload({
    client: client,
    params: {
      Bucket: bucket,
      Key: key,
      Body: body
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
    hooks?.onProgress(progress)
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
  client: S3Client
) => {
  try {
    await client.send(new HeadObjectCommand({ Bucket: bucket, Key: key }))
    return true
  } catch (err) {
    return false
  }
}

export const listBucketObjects = async (bucket: string, client: S3Client) => {
  const listCommand = new ListObjectsV2Command({
    Bucket: bucket,
  })

  return client.send(listCommand)
}

export const downloadFileFromBucket = async (
  bucket: string,
  key: string,
  options: { client: S3Client }
) => {
  const getCommand = new GetObjectCommand({ Bucket: bucket, Key: key })
  const output = await options.client.send(getCommand)

  const unit8Array = await output.Body?.transformToByteArray()
  return unit8Array ? Buffer.from(unit8Array) : undefined
}
