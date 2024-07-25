import { S3Client } from '@aws-sdk/client-s3'
import {
  checkIfObjectExists,
  downloadFileFromBucket,
  initClient,
  S3Settings,
  uploadFileToBucket,
} from '~/lib/s3.js'

import DatabaseConstructor, { type Database } from 'better-sqlite3'

import fsExtra from 'fs-extra'
import path from 'path'

const DATABASE_NAME = 'db.sqlite'

/**
 * we store a list of snapshots in a sqlite db (a ledger), as S3 is missing
 * support for filtering by tags.
 */
class SnapshotListStorage {
  client: S3Client
  bucketName: string
  db: Database | undefined
  dbPath: string

  constructor(settings: S3Settings, dbPath: string) {
    this.client = initClient(settings)
    this.bucketName = settings.bucket
    this.dbPath = path.join(dbPath, DATABASE_NAME)
  }

  /**
   * create a new database instance we
   * can use to make queries against.
   */
  async init() {
    // TODO_BEFORE_REVIEW: look at saving the file at temp location
    // is it is being used as a placeholder at the moment.
    const isFound = await this.downloadDatabaseFile()

    if (isFound) {
      this.db = new DatabaseConstructor(this.dbPath)
    } else {
      this.db = await this.createNewDatabase()
    }
    this.db.pragma('journal_mode = WAL')
  }

  async createNewDatabase() {
    const newDb = new DatabaseConstructor(this.dbPath)

    newDb.exec(`CREATE TABLE snapshots (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      tags JSON NOT NULL DEFAULT '[]',
      created_at DATETIME DEFAULT current_timestamp
    )`)

    await this.saveDatabaseFile()

    return newDb
  }

  /**
   *
   */
  async saveDatabaseFile() {
    const dbFile = await fsExtra.createReadStream(this.dbPath)

    return uploadFileToBucket(dbFile, {
      bucket: this.bucketName,
      client: this.client,
      key: DATABASE_NAME,
    })
  }

  /**
   * download `db.sqlite` file from S3 bucket
   * and write to the `.snapshots` file.
   *
   * @returns {boolean}: returns false if not found
   */
  async downloadDatabaseFile() {
    const isFound = await checkIfObjectExists(
      this.bucketName,
      DATABASE_NAME,
      this.client
    )

    if (isFound) {
      const snapshotDb = await downloadFileFromBucket(
        this.bucketName,
        DATABASE_NAME,
        { client: this.client }
      )

      if (snapshotDb) {
        await fsExtra.writeFile(this.dbPath, snapshotDb)
        return true
      }
    }

    return false
  }

  getDatabase() {
    if (this.db) {
      return this.db
    } else {
      throw new Error('Database instance not found, run `init`')
    }
  }

  async destoryDatabaseFile() {
    return fsExtra.unlink(this.dbPath)
  }
}

export type SnapshotListStorage = Awaited<
  ReturnType<typeof snapshotListStorage>
>

export const snapshotListStorage = async (
  settings: S3Settings,
  /** base `.snaplet` folder */
  basePath: string
) => {
  const storage = new SnapshotListStorage(settings, basePath)
  await storage.init()

  const db = storage.getDatabase()

  return {
    getSnapshotsMany: (rules?: { startsWith?: string }) => {
      return db
        .prepare(
          [
            'SELECT * FROM snapshots',
            rules?.startsWith ? 'WHERE ? LIKE name || %' : null,
          ].join(' ')
        )
        .all(rules?.startsWith)
        .map((r: any) => ({
          id: r.id,
          name: r.name,
          tags: r.tags,
          createdAt: r.createdAt,
        }))
    },
    getLatestSnapshot: () => {
      return db
        .prepare('SELECT * FROM snapshots ORDER BY created_at LIMIT 1')
        .all()
        .map((r: any) => ({
          id: r.id,
          name: r.name,
          tags: r.tags,
          createdAt: r.created_at,
        }))
    },
    insertSnapshot: (data: {
      id: string
      name: string
      createdAt: string
      tags?: string[]
    }) => {
      return db.exec(`INSERT INTO snapshots (
        id, name, created_at, tags
      ) VALUES (
        ${[
          `'${data.id}'`,
          `'${data.name}'`,
          `'${data.createdAt}'`,
          data.tags ? `[${data.tags.toString()}]` : '[]',
        ].join(',')}
      )`)
    },
    /**
     * save current database instance to S3
     * bucket, will automatically delete the
     */
    commit: async (
      opts: {
        /** delete the file stored  */
        destroy: boolean
      } = { destroy: true }
    ) => {
      await storage.saveDatabaseFile()
      if (opts.destroy) {
        await storage.destoryDatabaseFile()
      }
    },
  }
}
