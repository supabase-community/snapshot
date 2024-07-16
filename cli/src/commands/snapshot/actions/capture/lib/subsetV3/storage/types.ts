import { SubsettingTable } from '../lib/types.js'

export type SubsettingStorage = {
  // Check if the table exist in the storage
  has: (tableId: string) => boolean
  // Add the ids to the storage return the ctids that are new
  add: (tableId: string, ids: Array<Array<string | null>>) => Set<string>
  // Retrieve the ctids from the designated segment in the storage
  getSegment: (segmentId: number) => Array<string>
  // Delete the designated segment from the storage
  deleteSegment: (segmentId: number) => void
  // Commit temporary table to the storage, add new ctids to the "segment" table by chunk, return an array of primary key values for each segment
  commitTemp: (tableId: string) => {
    newIds: number
    foundIds: number
    segmentIds: Array<number>
  }
  // Insert the ids to the temporary table so we can then intersect with the storages
  insertTemp: (tableId: string, rows: Array<Array<string | null>>) => void
  // Count the number of ids in the storage for the given table
  countIds: (tableId: string) => number
  // Get the ids from the storage for the given table
  getIds: (
    tableId: string,
    limitOffset?: { limit: number; offset: number }
  ) => Array<Array<string | null>>
  // Initialize the storage with the tables
  subsetInit: (tables: Map<string, SubsettingTable>) => void
  // Cleanup the storage after the subsetting
  subsetCleanup: () => void
  close: () => void
  getColumnsToNullate(tableId: string): Set<string>
}
