export class BufferReader {
  buffer: Buffer
  offset = 0

  constructor(buffer: Buffer) {
    this.buffer = buffer
  }

  get length(): number {
    return this.buffer.length
  }

  readUInt8(): number {
    this._checkReadable(1)
    const v = this.buffer.readUInt8(this.offset)
    this.offset++
    return v
  }

  readUInt16BE(): number {
    this._checkReadable(2)
    const v = this.buffer.readUInt16BE(this.offset)
    this.offset += 2
    return v
  }

  readInt16BE(): number {
    this._checkReadable(2)
    const v = this.buffer.readInt16BE(this.offset)
    this.offset += 2
    return v
  }

  readUInt32BE(): number {
    this._checkReadable(4)
    const v = this.buffer.readUInt32BE(this.offset)
    this.offset += 4
    return v
  }

  readInt32BE(): number {
    this._checkReadable(4)
    const v = this.buffer.readInt32BE(this.offset)
    this.offset += 4
    return v
  }

  readCString(encoding?: BufferEncoding): string {
    const idx = this.buffer.indexOf(0, this.offset)
    const v = this.buffer.toString(encoding, this.offset, idx)
    this.offset = idx + 1
    return v
  }

  readLString(len: number, encoding?: BufferEncoding): string | null {
    if (len < 0) return null
    this._checkReadable(len)
    const v = this.buffer.toString(encoding, this.offset, this.offset + len)
    this.offset += len
    return v
  }

  readBuffer(len?: number): Buffer {
    if (len) this._checkReadable(len)
    const end = len !== undefined ? this.offset + len : this.length
    const buf = this.buffer.slice(this.offset, end)
    this.offset = end
    return buf
  }

  moveBy(n: number): this {
    return this.moveTo(this.offset + n)
  }

  moveTo(pos: number): this {
    if (pos >= this.length) throw new Error('Eof in buffer detected')
    this.offset = pos
    return this
  }

  private _checkReadable(size: number): void {
    if (this.offset + size - 1 >= this.length)
      throw new Error('Eof in buffer detected')
  }
}
