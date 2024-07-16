import DatabaseConstructor, { Database } from 'better-sqlite3'
import fs from 'fs-extra'
import { SubsettingTable } from '../../lib/types.js'
import { snakeCase } from 'lodash'
import { SubsettingStorage } from '../types.js'
import { escapeIdentifier, escapeLiteral } from '@snaplet/sdk/cli'

// SQLite has a limit of 999 variables per query so our insert must be chunked accordingly
// TODO: Use a custom recompiled version of sqlite with a higher limit (9999 would be much better)
const SQLITE_MAX_VARIABLE_NUMBER = 999
// The segment size is what will be loaded in memory at once
// so each one need to be small enough to fit entierly into memory
const MAX_SEGMENT_SIZE = 100000

// We will use a generator pattern to chunk the array as it reduce the memory footprint
// instead of having lodash _.chunk basically duplicating the whole array into memory as smaller chunks
// our algorithm will only keep the current chunk + original in memory
function* chunkGenerator<T>(array: T[], chunkSize: number): Generator<T[]> {
  for (let i = 0; i < array.length; i += chunkSize) {
    yield array.slice(i, i + chunkSize)
  }
}

function* getLimitOffsetGenerator(
  n: number,
  chunkSize: number
): Generator<{ limit: number; offset: number }> {
  for (let i = 0; i < n; i += chunkSize) {
    yield {
      offset: i,
      limit: Math.min(chunkSize, n - i),
    }
  }
}

class SqliteStorageV3 {
  db: Database
  path: string
  mode: 'read' | 'create'
  tablesQueryParams: Map<
    string,
    {
      // All the string idenfiers must be escaped
      idxName: string
      snakeCasedTableId: string
      snakeCasedPrimaryKeysSelector: string
      // Table which will be used for insertions / intersection
      tempTableId: string
      // The formated string for the insert query that we will duplicate for each row added (eg: (?, ?, ?))
      keysInsertPlaceholder: string
      // The columns that will be set to NULL when the subsetting is done because we don't follow those relations
      columnsToNullate: Set<string>
    }
  > = new Map()

  constructor(path: string, options: { mode: 'read' | 'create' }) {
    this.path = path
    this.db = new DatabaseConstructor(path)
    this.db.pragma('journal_mode = WAL')
    this.mode = options.mode
    if (options.mode === 'read') {
      this.initRead()
    }
  }

  // Will create the approriate tables, indexes and columns according
  // to the subset configuration passed into the init() function
  createTables(tables: Map<string, SubsettingTable>) {
    if (this.mode === 'read') {
      return
    }
    this.db.exec('BEGIN TRANSACTION')
    // This table will contain all the metadatas we need for quick retrieval
    // and mapping between sqlite and our introspected data
    this.db.exec(`CREATE TABLE metadatas
    (
      original_table_id TEXT PRIMARY KEY,
      snake_cased_table_id TEXT NOT NULL,
      snake_cased_primary_keys_selector TEXT NOT NULL,
      idx_name TEXT NOT NULL,
      temp_table_id TEXT NOT NULL,
      keys_insert_placeholder TEXT NOT NULL,
      columns_to_nullate JSON NOT NULL DEFAULT '[]'
    )`)
    // Will contain the data for each of our segments
    // the ctids will be an array of ctid json strigified (`"['(1,2)','(2,3)']"`)
    this.db.exec(`CREATE TABLE segments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ctids TEXT NOT NULL
    )`)
    const insertMetadatasValues = []
    for (const [_, table] of tables) {
      // We skip disconnected tables as they won't be used in the subset
      if (table.isDisconnected) {
        continue
      }
      // SQLite doesn't support casing for identifier because fck the SQL standard
      // so we have to convert everything in snake case
      // see: https://sqlite.org/forum/info/13ff27472c4322d8490df0d1c7988bf0e2d335daa89e748f96982121368e5a48
      const snakeCasedTableId = snakeCase(table.id)
      const snakeCasedEscapedTableId = escapeIdentifier(snakeCase(table.id))
      // Since we will change our keys values, we need to add an index to make sure we can keep the order
      // when retrieving the values later
      const primaryKeysColumns = table.primaryKeys.keys.map((key, idx) =>
        escapeIdentifier(`${idx}_${snakeCase(key.name)}`)
      )
      const tempTableId = escapeIdentifier(`temp_${snakeCasedTableId}`)
      // We don't set our ctid as PRIMARY KEY here because sqlite doesn't support dropping a column
      // which make the process of cleaning up the data harder.
      // Instead we create a custom index that we'll be able to just drop later, then we'll update
      // all the ctid columns values to NULL making the space they take in the strorage close to 0
      // but avoiding the need to copy all the content of the table into another one just to drop this column
      const idxName = escapeIdentifier(`idx_${snakeCasedTableId}_ctid`)
      const snakeCasedPrimaryKeysCreateClause = primaryKeysColumns
        .map((k) => `${k} TEXT`)
        .join(', ')
      this.db.exec(
        `CREATE TABLE ${snakeCasedEscapedTableId} (ctid TEXT, ${snakeCasedPrimaryKeysCreateClause})`
      )
      this.db.exec(
        `CREATE UNIQUE INDEX ${idxName} ON ${snakeCasedEscapedTableId} (ctid)`
      )
      // We create a temporary table that will be used to store the rows at insertion time so we can easily
      // bulk insert and then intersect with our current table
      this.db.exec(
        `CREATE TEMPORARY TABLE ${tempTableId} (ctid TEXT PRIMARY KEY, ${snakeCasedPrimaryKeysCreateClause})`
      )
      const queryParams = {
        snakeCasedTableId: snakeCasedEscapedTableId,
        idxName,
        snakeCasedPrimaryKeysSelector: primaryKeysColumns.join(','),
        tempTableId: tempTableId,
        // The first ? is for the ctid, the other ones are for the primary keys
        keysInsertPlaceholder: `(? ${', ?'.repeat(
          table.primaryKeys.keys.length
        )})`,
        columnsToNullate: table.columnsToNullate,
      }
      this.tablesQueryParams.set(table.id, queryParams)
      insertMetadatasValues.push(
        `(
          ${escapeLiteral(table.id)},
          ${escapeLiteral(queryParams.snakeCasedTableId)},
          ${escapeLiteral(queryParams.snakeCasedPrimaryKeysSelector)},
          ${escapeLiteral(queryParams.idxName)},
          ${escapeLiteral(queryParams.tempTableId)},
          ${escapeLiteral(queryParams.keysInsertPlaceholder)},
          ${escapeLiteral(
            JSON.stringify(Array.from(queryParams.columnsToNullate))
          )}
        )`
      )
    }
    // If all tables are disconnected (when we don't subset) we don't need to create the metadatas table
    if (insertMetadatasValues.length > 0) {
      // Create and feed our metadatas table
      this.db.exec(
        `
          INSERT INTO metadatas
          (
            original_table_id, snake_cased_table_id,
            snake_cased_primary_keys_selector, idx_name,
            temp_table_id, keys_insert_placeholder, columns_to_nullate
          )
          VALUES ${insertMetadatasValues.join(', ')}`
      )
    }
    this.db.exec('COMMIT TRANSACTION')
  }
  // Here we cleanup all the data we will not need anymore after the subsetting is done
  // to keep the database as small as possible
  tablesCleanup() {
    if (this.mode === 'read') {
      return
    }
    for (const [_, infos] of this.tablesQueryParams) {
      // We drop the temporary table
      this.db.prepare(`DROP TABLE ${infos.tempTableId}`).run()
      this.db.prepare(`DROP INDEX ${infos.idxName}`).run()
      this.db.prepare(`UPDATE ${infos.snakeCasedTableId} SET ctid = NULL`).run()
    }
    this.db.prepare(`DROP TABLE segments`).run()
  }

  // Restore all the internal data structures needed for the storage
  // from the metadata table
  initRead() {
    const metadatas = this.db
      .prepare(
        `SELECT
          original_table_id,
          snake_cased_table_id,
          snake_cased_primary_keys_selector,
          idx_name,
          temp_table_id,
          keys_insert_placeholder,
          columns_to_nullate
        FROM metadatas`
      )
      .all() as {
      original_table_id: string
      snake_cased_table_id: string
      snake_cased_primary_keys_selector: string
      idx_name: string
      temp_table_id: string
      keys_insert_placeholder: string
      columns_to_nullate: Set<string>
    }[]
    for (const metadata of metadatas) {
      this.tablesQueryParams.set(metadata.original_table_id, {
        snakeCasedTableId: metadata.snake_cased_table_id,
        idxName: metadata.idx_name,
        snakeCasedPrimaryKeysSelector:
          metadata.snake_cased_primary_keys_selector,
        tempTableId: metadata.temp_table_id,
        keysInsertPlaceholder: metadata.keys_insert_placeholder,
        columnsToNullate: new Set(metadata.columns_to_nullate),
      })
    }
  }

  getSegment(segmentId: number) {
    const result = this.db
      .prepare('SELECT ctids FROM segments WHERE id = ?')
      .pluck()
      .get(segmentId) as string | undefined
    if (!result) {
      throw new Error(`Segment ${segmentId} not found`)
    }
    return JSON.parse(result) as Array<string>
  }
  deleteSegment(segmentId: number) {
    const result = this.db
      .prepare('SELECT 1 FROM segments WHERE id = ?')
      .pluck()
      .get(segmentId) as string | undefined
    if (!result) {
      throw new Error(`Segment ${segmentId} not found`)
    }
    this.db.prepare('DELETE FROM segments WHERE id = ?').run(segmentId)
  }
  // Commit temporary table to the storage, add new ctids to the "segment" table by chunk, return an array of primary key values for each segment
  commitTemp(tableId: string) {
    const tablesQueryParams = this.tablesQueryParams.get(tableId)
    if (!tablesQueryParams) {
      throw new Error(`Table ${tableId} not found`)
    }
    const newSegmentIds: Array<number> = []
    // This is the number of newIds we'll need to insert in the storage and chunk into segments
    const newIds = this.countNewIds(tableId)
    // This was the number of total "foundIds" from all the previous inserts into temp table
    const foundIds = this.countFoundIds(tableId)
    if (newIds === 0) {
      // We clean the temporary table, using a delete is more efficient than droping
      // the table in sqlite (cf: https://www.sqlite.org/lang_delete.html)
      this.db.prepare(`DELETE FROM ${tablesQueryParams.tempTableId}`).run()
      return { newIds, foundIds, segmentIds: [] }
    } else {
      const limitOffsetGenerator = getLimitOffsetGenerator(
        newIds,
        MAX_SEGMENT_SIZE
      )
      this.db.exec('BEGIN TRANSACTION')
      // Insert the newIds into the "segments" table by chunk and return the segment id
      const insertStmt = this.db.prepare(
        'INSERT INTO segments (ctids) VALUES (?)'
      )
      // We only need to keep the "newIds" in the temporary table we can ditch the rest
      // for quicker processing
      const deleteNonNewIdsFromTempTableStmt = this.db.prepare(`
        DELETE FROM ${tablesQueryParams.tempTableId}
        WHERE ctid IN (
          SELECT t1.ctid
          FROM ${tablesQueryParams.tempTableId} as t1
          LEFT JOIN ${tablesQueryParams.snakeCasedTableId} as t2 ON t1.ctid = t2.ctid
          WHERE t2.ctid IS NOT NULL
        )
      `)
      deleteNonNewIdsFromTempTableStmt.run()
      // From now on, the only things left in the temporary table are the newIds
      for (const limitOffset of limitOffsetGenerator) {
        const ctidSelectQuery = `
          SELECT t1.ctid as ctid
          FROM ${tablesQueryParams.tempTableId} as t1
          LIMIT ${limitOffset.limit} OFFSET ${limitOffset.offset};
        `
        // Insert the chunk of new ids from the temporary table into the "definitive" table
        const ctidsInsertQuery = `
          INSERT OR IGNORE INTO ${tablesQueryParams.snakeCasedTableId} SELECT t1.*
          FROM ${tablesQueryParams.tempTableId} as t1
          LIMIT ${limitOffset.limit} OFFSET ${limitOffset.offset};
        `
        // Used to remove the
        const newCtidsChunk = this.db
          .prepare(ctidSelectQuery)
          .pluck()
          .raw(true)
          .all() as Array<string[]>
        // Insert the chunk into the "segments" table.
        const newSegmentId = insertStmt.run(
          JSON.stringify(newCtidsChunk.flat())
        )
        newSegmentIds.push(newSegmentId.lastInsertRowid as number)
        // Insert the chunk into the "definitive" table.
        this.db.prepare(ctidsInsertQuery).run()
      }
      // We clean the temporary table
      this.db.prepare(`DELETE FROM ${tablesQueryParams.tempTableId}`).run()
      this.db.exec('COMMIT TRANSACTION')
    }
    return { newIds, foundIds, segmentIds: newSegmentIds }
  }

  // Insert the ids to the temporary table so we can then intersect with the storage
  insertTemp(tableId: string, rows: Array<Array<string | null>>) {
    const tablesQueryParams = this.tablesQueryParams.get(tableId)
    if (!tablesQueryParams) {
      throw new Error(`Table ${tableId} not found`)
    }
    const columnsPerRow = rows[0].length
    // Number of rows we can insert at once depends of sqlite max variable number and the number of columns per row
    const rowsPerInsert = Math.floor(SQLITE_MAX_VARIABLE_NUMBER / columnsPerRow)
    this.db.exec('BEGIN TRANSACTION')
    for (const chunk of chunkGenerator(rows, rowsPerInsert)) {
      const valuesPlaceholder = chunk
        .map(() => tablesQueryParams.keysInsertPlaceholder)
        .join(',')

      const flattenedChunk = chunk.flat()

      // Insert all the rows into the temporary table
      this.db
        .prepare(
          `INSERT OR IGNORE INTO ${tablesQueryParams.tempTableId} VALUES ${valuesPlaceholder}`
        )
        .run(...flattenedChunk)
    }
    this.db.exec('COMMIT TRANSACTION')
  }
  // Count new ids in the storage for the given table by intersecting with the current temporary table
  countNewIds(tableId: string): number {
    const tablesQueryParams = this.tablesQueryParams.get(tableId)
    if (!tablesQueryParams) {
      throw new Error(`Table ${tableId} not found`)
    }
    // We use the temporary table to easily perform an intersection between the rows to insert and the rows already in the table
    const query = `
      SELECT COUNT(*) as count
      FROM ${tablesQueryParams.tempTableId} as t1
      LEFT JOIN ${tablesQueryParams.snakeCasedTableId} as t2 ON t1.ctid = t2.ctid
      WHERE t2.ctid IS NULL;
    `
    // We get all the "new ctids" in the table, if there is none, we can skip the insert
    const newCtidsCount = this.db.prepare(query).pluck().get() as number
    return newCtidsCount
  }
  // Count the number of ids in the temporary table for the given table
  countFoundIds(tableId: string): number {
    const tablesQueryParams = this.tablesQueryParams.get(tableId)
    if (!tablesQueryParams) {
      throw new Error(`Table ${tableId} not found`)
    }
    // We use the temporary table to easily perform an intersection between the rows to insert and the rows already in the table
    const query = `
      SELECT COUNT(*) as count
      FROM ${tablesQueryParams.tempTableId} as t1
    `
    // We get all the "new ctids" in the table, if there is none, we can skip the insert
    const ctidsCount = this.db.prepare(query).pluck().get() as number
    return ctidsCount
  }
  // rows will always be an array of arrays of strings formatted like so:
  // [ctid, pk1, pk2, ...]
  // The order of the pk in the array must be the same as into the table "primaryKeys.keys" order
  addRows(tableId: string, rows: Array<Array<string | null>>): Array<string> {
    const tablesQueryParams = this.tablesQueryParams.get(tableId)
    if (!tablesQueryParams) {
      throw new Error(`Table ${tableId} not found`)
    }
    this.insertTemp(tableId, rows)
    const commitResult = this.commitTemp(tableId)
    const newIds = []
    for (const segmentId of commitResult.segmentIds) {
      newIds.push(this.getSegment(segmentId))
    }
    return newIds.flat()
  }

  has(tableId: string): boolean {
    const tableQueryParams = this.tablesQueryParams.get(tableId)
    if (!tableQueryParams) {
      return false
    }
    return true
  }

  getAllIds(): Map<string, Array<string[]>> {
    const result = new Map<string, Array<string[]>>()
    for (const [tableId, params] of this.tablesQueryParams) {
      const rows = this.db
        .prepare(
          `SELECT ${params.snakeCasedPrimaryKeysSelector} FROM ${params.snakeCasedTableId}`
        )
        .raw(true)
        .all() as Array<string[]>
      result.set(tableId, rows)
    }
    return result
  }

  countIds(tableId: string): number {
    const tableQueryParams = this.tablesQueryParams.get(tableId)
    if (!tableQueryParams) {
      return 0
    }
    const result = this.db
      .prepare(
        `SELECT COUNT(1) as count FROM ${tableQueryParams.snakeCasedTableId}`
      )
      .raw(true)
      .get() as [number]
    return result[0]
  }

  getColumnsToNullate(tableId: string): Set<string> {
    const result = new Set<string>()
    const tableQueryParams = this.tablesQueryParams.get(tableId)
    if (!tableQueryParams) {
      return result
    }
    for (const column of tableQueryParams.columnsToNullate) {
      result.add(column)
    }
    return result
  }

  getIds(
    tableId: string,
    limitOffset?: { limit: number; offset: number }
  ): Array<string[]> {
    const tableQueryParams = this.tablesQueryParams.get(tableId)
    if (!tableQueryParams) {
      return []
    }
    const rows = this.db
      .prepare(
        `
        SELECT ${tableQueryParams.snakeCasedPrimaryKeysSelector}
        FROM ${tableQueryParams.snakeCasedTableId}
        ${
          limitOffset
            ? `LIMIT ${limitOffset.limit} OFFSET ${limitOffset.offset}`
            : ''
        }
      `
      )
      .raw(true)
      .all() as Array<string[]>
    return rows
  }

  close = () => {
    this.db.close()
  }

  clear = () => {
    try {
      fs.unlinkSync(this.path)
    } catch (_) {
      // ignore
    }
  }
}

// Create subsetting storage in write mode from a path
function createSubsettingStorageV3(path: string): SubsettingStorage {
  const sqliteStorage = new SqliteStorageV3(path, { mode: 'create' })
  return {
    add: (tableId, ids) => {
      return new Set(sqliteStorage.addRows(tableId, ids))
    },
    has(tableId) {
      return sqliteStorage.has(tableId)
    },
    countIds(tableId) {
      return sqliteStorage.countIds(tableId)
    },
    getIds(tableId, limitOffset) {
      return sqliteStorage.getIds(tableId, limitOffset)
    },
    subsetInit(tables) {
      sqliteStorage.createTables(tables)
    },
    subsetCleanup() {
      sqliteStorage.tablesCleanup()
    },
    close() {
      sqliteStorage.close()
    },
    getSegment(segmentId: number) {
      return sqliteStorage.getSegment(segmentId)
    },
    deleteSegment(segmentId: number) {
      sqliteStorage.deleteSegment(segmentId)
    },
    commitTemp(tableId: string) {
      return sqliteStorage.commitTemp(tableId)
    },
    insertTemp(tableId, rows) {
      sqliteStorage.insertTemp(tableId, rows)
    },
    getColumnsToNullate(tableId: string) {
      return sqliteStorage.getColumnsToNullate(tableId)
    },
  }
}

// Read the subsettingStorage in read mode from a path
function readSubsettingStorageV3(path: string): SubsettingStorage {
  const sqliteStorage = new SqliteStorageV3(path, { mode: 'read' })
  return {
    add: (tableId, ids) => {
      return new Set(sqliteStorage.addRows(tableId, ids))
    },
    has(tableId) {
      return sqliteStorage.has(tableId)
    },
    countIds(tableId) {
      return sqliteStorage.countIds(tableId)
    },
    getIds(tableId, limitOffset) {
      return sqliteStorage.getIds(tableId, limitOffset)
    },
    subsetInit() {},
    subsetCleanup() {},
    getSegment() {
      return []
    },
    deleteSegment() {},
    commitTemp() {
      return { foundIds: 0, newIds: 0, segmentIds: [] }
    },
    insertTemp() {},
    close() {
      sqliteStorage.close()
    },
    getColumnsToNullate(tableId: string) {
      return sqliteStorage.getColumnsToNullate(tableId)
    },
  }
}

export { createSubsettingStorageV3, readSubsettingStorageV3 }
