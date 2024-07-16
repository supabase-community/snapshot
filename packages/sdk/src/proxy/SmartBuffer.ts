import { BufferReader } from './BufferReader.js'

interface SmartBufferConfig {
  pageSize: number
  maxLength?: number
  houseKeepInterval?: number
}

export class SmartBuffer extends BufferReader {
  static DEFAULT_PAGE_SIZE = 4096

  private readonly _houseKeepInterval: number
  private _houseKeepTimer?: NodeJS.Timeout
  private _lastHouseKeep = 0
  private _stMaxPages = 1
  private _length = 0
  readonly pageSize: number
  readonly maxSize: number

  constructor(cfg?: SmartBufferConfig) {
    super(
      Buffer.allocUnsafe(
        (cfg?.pageSize ? parseInt(cfg.pageSize.toString(), 10) : 0) ||
          SmartBuffer.DEFAULT_PAGE_SIZE
      )
    )
    this._houseKeepInterval = cfg?.houseKeepInterval || 5000
    this.pageSize = this.buffer.length
    this.maxSize = cfg?.maxLength || 1024 * 1024 * 128 // 128 MB
    this._length = 0
  }

  get capacity(): number {
    return this.buffer.length
  }

  get length(): number {
    return this._length
  }

  start(): this {
    this.offset = 0
    this._length = 0
    if (this._houseKeepTimer) {
      clearTimeout(this._houseKeepTimer)
      this._houseKeepTimer = undefined
    }
    return this
  }

  flush(): Buffer {
    if (this._houseKeepTimer) clearTimeout(this._houseKeepTimer)

    const length = this.length
    this._length = 0
    const out = this.buffer.slice(0, length)

    const pages = length ? Math.ceil(length / this.pageSize) : 1
    this._stMaxPages = Math.max(this._stMaxPages, pages)
    if (this._lastHouseKeep < Date.now() + this._houseKeepInterval)
      this._houseKeep()

    this._houseKeepTimer = setTimeout(() => {
      this._houseKeepTimer = undefined
      this._houseKeep()
    }, this._houseKeepInterval).unref()

    return out
  }

  ensureCapacity(len: number): this {
    const endOffset = this.offset + len
    if (this.capacity < endOffset) {
      if (endOffset > this.maxSize) throw new Error('Buffer limit exceeded.')
      const newSize = Math.ceil(endOffset / this.pageSize) * this.pageSize
      const newBuffer = Buffer.allocUnsafe(newSize)
      this.buffer.copy(newBuffer)
      this.buffer = newBuffer
    }
    this._length = Math.max(this.length, endOffset)
    return this
  }

  fill(value = 0, len = 1): this {
    this.ensureCapacity(len)
    this.buffer.fill(value, this.offset, this.offset + len)
    this.offset += len
    return this
  }

  writeCString(str: string, encoding?: BufferEncoding): this {
    const len = str ? Buffer.byteLength(str, encoding) : 0
    this.ensureCapacity(len + 1)
    if (str) {
      this.buffer.write(str, this.offset, encoding)
      this.offset += len
    }
    this.writeUInt8(0)
    return this
  }

  writeLString(str?: string, encoding?: BufferEncoding): this {
    const len = str ? Buffer.byteLength(str, encoding) : 0
    this.ensureCapacity(len + 4)
    this.writeInt32BE(str == null ? -1 : len)
    if (str) {
      if (encoding) this.offset += this.buffer.write(str, this.offset, encoding)
      else this.offset += this.buffer.write(str, this.offset)
    }
    return this
  }

  writeString(str: string, encoding?: BufferEncoding): this {
    if (str) {
      const len = Buffer.byteLength(str, encoding)
      this.ensureCapacity(len)
      this.offset += this.buffer.write(str, this.offset, encoding)
    }
    return this
  }

  writeInt8(n: number): this {
    this.ensureCapacity(1)
    this.buffer.writeInt8(n, this.offset)
    this.offset++
    return this
  }

  writeUInt8(n: number): this {
    this.ensureCapacity(1)
    this.buffer.writeUInt8(n, this.offset)
    this.offset++
    return this
  }

  writeUInt16BE(n: number): this {
    this.ensureCapacity(2)
    this.buffer.writeUInt16BE(n, this.offset)
    this.offset += 2
    return this
  }

  writeUInt32BE(n: number): this {
    this.ensureCapacity(4)
    this.buffer.writeUInt32BE(n, this.offset)
    this.offset += 4
    return this
  }

  writeInt16BE(n: number): this {
    this.ensureCapacity(2)
    this.buffer.writeInt16BE(n, this.offset)
    this.offset += 2
    return this
  }

  writeInt32BE(n: number): this {
    this.ensureCapacity(4)
    this.buffer.writeInt32BE(n, this.offset)
    this.offset += 4
    return this
  }

  writeFloatBE(n: number): this {
    this.ensureCapacity(4)
    this.buffer.writeFloatBE(n, this.offset)
    this.offset += 4
    return this
  }

  writeDoubleBE(n: number): this {
    this.ensureCapacity(8)
    this.buffer.writeDoubleBE(n, this.offset)
    this.offset += 8
    return this
  }

  writeBuffer(buffer: Buffer): this {
    this.ensureCapacity(buffer.length)
    buffer.copy(this.buffer, this.offset, 0, buffer.length)
    this.offset += buffer.length
    return this
  }

  private _houseKeep(): void {
    const needSize = this._stMaxPages * this.pageSize
    if (this.buffer.length > needSize)
      this.buffer = Buffer.allocUnsafe(needSize)
    this._stMaxPages = this.length ? Math.ceil(this.length / this.pageSize) : 1
  }

  setLengthAndFlush(lengthOffset: number): Buffer {
    this.buffer.writeUInt32BE(this.length - lengthOffset, lengthOffset)
    return this.flush()
  }
}
