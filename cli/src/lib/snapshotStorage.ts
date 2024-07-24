import fs from 'fs-extra'
import fg from 'fast-glob'
import got from 'got-cjs'
import util from 'util'
import stream from 'stream'
import createProgressStream from 'progress-stream'
import path from 'path'
import pMap from 'p-map'
import { getSnapshotFilePaths } from '@snaplet/sdk/cli'
import md5File from 'md5-file'

import { xdebugShare } from '~/commands/snapshot/actions/share/debugShare.js'
import { generateSnapshotFileKey, initClient, S3Settings, StorageFile, uploadFileToBucket } from '~/lib/s3.js'

const pipeline = util.promisify(stream.pipeline)

export const downloadSnapshot = async (options: {
  snapshotId: string
  paths: ReturnType<typeof getSnapshotFilePaths>
  onProgress: (percentage: string) => Promise<void>
}) => {
  const { snapshotId, paths, onProgress } = options

  const storage = await trpc.snapshot.storage.all.query({
    snapshotId,
  })

  if (!storage) {
    throw new Error('Snapshot does not contain any files')
  }
  const { files, totalBytes } = storage
  let transferred = 0
  let lastPercentage = '0'

  await pMap(
    Object.values(files).map((file) => {
      const destination = path.join(paths.base, file.filename)

      // context(peterp, 12 July 2023): If the file already exists
      // compare the md5 hash of the local file to that of the uploaded file
      let shouldDownload = true
      if (
        fs.existsSync(destination) &&
        md5File.sync(destination) === file.md5
      ) {
        shouldDownload = false
      }
      return { file, destination, shouldDownload }
    }),
    async ({ file, destination, shouldDownload }) => {
      if (shouldDownload === false) {
        return
      }
      await download({
        file,
        snapshotId,
        destination,
        onProgress: async (e) => {
          transferred += e.delta
          const percentage = ((transferred / totalBytes) * 100).toFixed(2)
          // context(peterp, 12 July 2023): We submit duplicate events for the same percentage
          if (lastPercentage !== percentage) {
            await onProgress(percentage)
            lastPercentage = percentage
          }
        },
      })
    },
    { concurrency: 5 }
  )

  return transferred
}

/**
 * Download a single snapshot file based on the filename.
 * This is used to download `schemas.sql`
 *
 * @todo: query the API and get the relevant information.
 */
export const downloadSnapshotFile = async (options: {
  snapshotId: string
  filename: string
  destination: string
}) => {
  const { filename, snapshotId, destination } = options

  return await download({
    destination,
    snapshotId,
    file: {
      filename,
      bytes: 0,
      md5: '',
      bucketKey: '',
    },
    onProgress: async () => {},
  })
}

const download = async (options: {
  file: StorageFile
  snapshotId: string
  destination: string
  onProgress: (e: createProgressStream.Progress) => Promise<void>
}) => {
  const { file, snapshotId, destination, onProgress } = options

  // create directories that don't exist
  if (!fs.existsSync(path.dirname(destination))) {
    fs.mkdirpSync(path.dirname(destination))
  }

  const downloadURL = await trpc.snapshot.storage.downloadURL.query({
    snapshotId,
    filename: file.filename,
  })

  const progress = createProgressStream({ length: file.bytes, time: 500 })
  progress.on('progress', onProgress)
  await pipeline(
    got.stream(downloadURL),
    progress,
    fs.createWriteStream(destination)
  )

  return destination
}

export async function uploadSnapshot(
  snapshotId: string,
  paths: ReturnType<typeof getSnapshotFilePaths>,
  options: {
    settings: S3Settings
    onProgress: (percentage: string) => Promise<void>
  }
) {
  xdebugShare('Starting snapshot upload')
  const { settings, onProgress } = options

  // find all the snapshot files
  const uploadFiles = await fg('**/*.*', { cwd: paths.base, absolute: true })
  xdebugShare('Files to upload: ')
  xdebugShare(uploadFiles)

  //
  const totalBytes = getTotalSize(uploadFiles)
  xdebugShare(`Total bytes to upload: ${totalBytes}`)

  /** percentage of files uploaded */
  let currentTotalProgress = '0'

  for (const filepath of uploadFiles) {
    const filename = path.relative(paths.base, filepath)
    xdebugShare(`Uploading file:  ${filename}`)

    await uploadFile(settings, {
      snapshotId,
      filename,
      filepath,
      async onProgress(p) {
        xdebugShare(`Uploading file ${filename} progress`)
        try {
          const newProgress = p.toFixed(2)

          // prevent duplicate events
          if (currentTotalProgress !== newProgress) {
            await onProgress(newProgress)
            currentTotalProgress = newProgress
          }
        } catch (e) {
          xdebugShare(`Uploading file ${filename} progress error`)
          xdebugShare(e)
        }
        xdebugShare(`Uploading progress finished`)
      },
    })

    xdebugShare(`Uploaded file:  ${filename}`)
  }
}

const uploadFile = async (
  settings: S3Settings,
  options: {
    filepath: string
    filename: string
    snapshotId: string
    onProgress: (progres: number) => void
  }
) => {
  const { filepath, filename, snapshotId, onProgress } = options

  const md5 = md5File.sync(filepath)
  const bytes = fs.statSync(filepath).size
  // If bytes are above 5GB, warn the user that the upload might fail
  // Multiply by 1024 to go from: bytes -> kilobytes -> megabytes -> gigabytes
  if (bytes > 5 * 1024 * 1024 * 1024) {
    console.log(`
    WARNING: File ${filename} is larger than 5GB, the upload might fail.
    Consider using only a subset of the data to create a snapshot.
    More information: https://docs.snaplet.dev/core-concepts/capture#subset-data
    `)
  }

  xdebugShare(`upload file ${filepath} with ${bytes} bytes`)
  xdebugShare(
    `upload file ${filepath} on bucket ${settings.bucket} with ${md5} md5`
  )

  //
  xdebugShare(`upload file ${filepath} completed`)

  const fileToUpload = fs.createReadStream(filepath)
  const snapshotKey = generateSnapshotFileKey({ filename, snapshotId })
  await uploadFileToBucket(
    fileToUpload,
    {
      bucket: settings.bucket,
      key: snapshotKey,
      client: initClient(settings)
    },
    {
      onProgress,
    }
  )

  xdebugShare(`upload file ${filepath} completed`)
  return { bytes, filename, bucketKey: settings.bucket, md5 }
}

const getTotalSize = (files: string[]) => {
  let totalBytes = 0
  for (const p of files) {
    const { size: bytes } = fs.statSync(p)
    totalBytes += bytes
  }
  return totalBytes
}
