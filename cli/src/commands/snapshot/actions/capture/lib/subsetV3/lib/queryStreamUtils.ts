import { DatabaseClient } from '@snaplet/sdk/cli'
import { QueryArrayConfig } from 'pg'
import QueryStream from 'pg-query-stream'
import { Transform, TransformOptions } from 'stream'

import { Writable } from 'stream'
import { pipeline } from 'stream/promises'

class ChunkAccumulator<T> extends Transform {
  buffer: T[]
  chunkSize: number
  constructor(
    options: (TransformOptions & { chunkSize?: number }) | undefined
  ) {
    super({ objectMode: true, ...options })
    this.buffer = []
    this.chunkSize = options?.chunkSize ?? 10000
  }

  // Accumulate data until we have enough to push out a chunk
  _transform(chunk: T, _: unknown, callback: () => void) {
    this.buffer.push(chunk)
    if (this.buffer.length >= this.chunkSize) {
      this.push(this.buffer)
      this.buffer = []
    }

    callback()
  }
  // Ensure that any remaining data is pushed out when the stream end
  _flush(callback: () => void) {
    if (this.buffer.length > 0) {
      this.push(this.buffer)
    }
    callback()
  }
}

async function streamQueryWithChunk<T>(
  client: DatabaseClient,
  query: QueryArrayConfig,
  chunkWriteCallback: (chunk: T[]) => void,
  chunkSize?: number
) {
  const queryStream = new QueryStream(query.text, query.values, {
    rowMode: query.rowMode,
    batchSize: chunkSize,
  })
  const resultStream = client.query(queryStream)
  const chunkStream = new ChunkAccumulator({ chunkSize })
  const writeStream = new Writable({
    objectMode: true,
    write: (chunk, _, callback) => {
      try {
        chunkWriteCallback(chunk)
        callback()
      } catch (err) {
        callback(err as Error)
      }
    },
  })
  return await pipeline(resultStream, chunkStream, writeStream)
}

export { streamQueryWithChunk }
