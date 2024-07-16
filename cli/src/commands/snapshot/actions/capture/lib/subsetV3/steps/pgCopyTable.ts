import {
  DatabaseClient,
  TransformConfig,
  getTransformParsers,
  getTransformSerializers,
  serializeRow,
  parseRow,
  PgTypeName,
  withDbClient,
} from '@snaplet/sdk/cli'
import { parse as csvParse, Options as ParseOptions } from 'csv-parse'
import { stringify, Options as StringifyOptions } from 'csv-stringify'
import fs from 'fs'
import { pipeline } from 'node:stream/promises'

import {
  SubsetOptions,
  querySubsetStream,
  queryTableStream,
} from './queryTableStream.js'
import { Table } from '../lib/types.js'
import { columnsToPrimaryKeys } from '../lib/queryBuilders.js'
import { SnapshotCaptureEventEmitter } from './events.js'
import { Duplex, Writable } from 'stream'
import { finished } from 'stream/promises'
import {
  PgSnapshotConnection,
  setTransactionSnapshotId,
} from '../lib/pgSnapshot.js'
import { xdebugCapture } from '../../debugCapture.js'

export const csvParseOptions: ParseOptions = {
  columns: true,
  cast: (value, { quoting }) => (value === '' && !quoting ? null : value),
}

export const csvStringifyOptions: StringifyOptions = {
  header: true,
  quoted_match: /\r|^$/,
  record_delimiter: 'unix',
}

async function setupClientForCopyTransaction(client: DatabaseClient) {
  // https://pgpedia.info/s/statement_timeout.html
  await client.query(`
    SET statement_timeout = 0;
    SET lock_timeout = 0;
    SET idle_in_transaction_session_timeout = 0;
    SET client_encoding = 'UTF8';
    SET standard_conforming_strings = on;
    SELECT pg_catalog.set_config('search_path', '', false);
    SET check_function_bodies = false;
    SET xmloption = content;
    SET client_min_messages = warning;
  `)
}

const cloneStream = (stream: Writable) => {
  const clone = Duplex.from(async function* clonedStream(source) {
    for await (const chunk of source) {
      yield chunk
    }
  })

  clone.pipe(stream, { end: false })

  return clone
}

const MAX_COPY_CHUNK_SIZE = 1000000

function computeTableChunkSize(selectedKeysLength: number): number {
  // We divide the maximum number of parameters by the number of primary keys
  // to avoid flooding the query with too many parameters.
  if (selectedKeysLength === 0) return MAX_COPY_CHUNK_SIZE
  const chunkSize = Math.floor(MAX_COPY_CHUNK_SIZE / selectedKeysLength)
  return chunkSize > 0 ? chunkSize : 1
}
export interface PgCopyTableOptions {
  /* Table definition */
  table: Pick<Table, 'id' | 'schema' | 'name' | 'columns' | 'primaryKeys'>
  /* Column modifications for this table */
  transform: TransformConfig
  writer: fs.WriteStream
  subsetOptions: SubsetOptions
  dumpAllTable: boolean
}

const createColumnTypeLookup = (
  table: PgCopyTableOptions['table']
): Record<string, PgTypeName> => {
  return Object.fromEntries(
    table.columns.map((column) => [column.name, column.type as PgTypeName])
  )
}

export async function pgCopyTable(
  connection: PgSnapshotConnection,
  emitter: SnapshotCaptureEventEmitter,
  { table, transform, writer, subsetOptions, dumpAllTable }: PgCopyTableOptions
): Promise<{
  ms: number
  rows: number
}> {
  return await withDbClient(
    async (client) => {
      const { transactionEnd } = await setTransactionSnapshotId(
        client,
        connection.pgSnapshotId
      )
      await setupClientForCopyTransaction(client)
      const applicableColumns = table.columns
        .filter((c) => c.generated !== 'ALWAYS')
        .map((c) => c.name)
      const columnTypes = createColumnTypeLookup(table)
      const parsers = getTransformParsers(transform)
      const serializers = getTransformSerializers(transform)
      let rowsTransformed = 0
      // TODO: split the rows counter into "transformed" and "retrieved" rows
      // so if an error occurs, we can still report the number of rows retrieved
      async function* applyTransformations(
        source: AsyncIterable<Record<string, string | null>>
      ) {
        for await (const row of source) {
          rowsTransformed += 1
          const parsedRow = parseRow({
            row,
            columnTypes,
            parsers,
          })
          const ctx = {
            schema: table.schema,
            table: table.name,
            columns: applicableColumns,
            row: {
              line: rowsTransformed,
              raw: row,
              parsed: parsedRow,
            },
          }
          const transformedRow = transform.transformRow(ctx)
          yield serializeRow({
            row: transformedRow,
            columnTypes,
            serializers,
          })
        }
      }

      const startingTime = performance.now()
      let updateInterval: NodeJS.Timer | undefined
      const startUpdates = () =>
        // TODO: this should maybe be moved higher up in the calling chain
        // we might want to always emit progress at each row processed then
        // give the caller who handle the event the responsibility to decide how often to emit
        // or debounce the event
        (updateInterval = setInterval(() => {
          emitter.emit('copyTableProgress', {
            currentCopiedRows: rowsTransformed,
            schema: table.schema,
            tableName: table.name,
          })
        }, 500))
      try {
        startUpdates()
        // TODO: time total time spent in each step of the pipeline
        // like total time spent into `querySubsetStream`, total time spent in applyTransformations, etc
        // If the table doesn't have primary keys, we use all the columns as primary keys
        const primaryKeys =
          table.primaryKeys ?? columnsToPrimaryKeys(table.columns)
        const tableChunkSize = computeTableChunkSize(primaryKeys.keys.length)
        xdebugCapture(`tableChunkSize: ${tableChunkSize}`)
        const chunkGenerator = getChunkGenerator(
          subsetOptions.rowsToCopy,
          tableChunkSize
        )
        let firstChunk = true
        const tableWithColumnsToSelect = {
          ...table,
          columns: table.columns.filter(
            (c) => subsetOptions.columnsToNullate.has(c.name) === false
          ),
        }
        if (dumpAllTable) {
          await pipeline(
            queryTableStream(client, table),
            csvParse(csvParseOptions),
            applyTransformations,
            stringify(csvStringifyOptions),
            writer
          )
        } else {
          for (const limitOffset of chunkGenerator) {
            await pipeline(
              querySubsetStream(
                client,
                { ...tableWithColumnsToSelect, primaryKeys },
                subsetOptions,
                limitOffset
              ),
              csvParse(csvParseOptions),
              applyTransformations,
              stringify({
                ...csvStringifyOptions,
                // We want to dump the headers only for the first chunk, otherwise we'll get duplicate headers
                header: firstChunk,
              }),
              cloneStream(writer)
            )
            firstChunk = false
          }
        }
        const endTime = performance.now()
        return {
          // This will be sent to our database and it expect an integer
          ms: Math.round(endTime - startingTime),
          rows: rowsTransformed,
        }
      } finally {
        if (updateInterval) {
          clearInterval(updateInterval)
        }
        writer.end()
        await finished(writer)
        await transactionEnd()
      }
    },
    { connString: connection.connString }
  )
}

function* getChunkGenerator(
  n: number,
  chunkSize: number = MAX_COPY_CHUNK_SIZE
): Generator<{ limit: number; offset: number }> {
  for (let i = 0; i < n; i += chunkSize) {
    yield {
      offset: i,
      limit: Math.min(chunkSize, n - i),
    }
  }
}
