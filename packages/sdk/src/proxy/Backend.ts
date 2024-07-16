import { BufferReader } from './BufferReader.js'
import { SmartBuffer } from './SmartBuffer.js'
import { Protocol } from './protocol.js'

// 1 byte message type, 4 byte frame length
const HEADER_LENGTH = 5

const ErrorFieldTypes = {
  M: 'message',
  S: 'severity',
  V: 'severity',
  C: 'code',
  D: 'detail',
  H: 'hint',
  P: 'position',
  p: 'internalPosition',
  q: 'internalQuery',
  W: 'where',
  s: 'schema',
  t: 'table',
  c: 'column',
  d: 'dataType',
  n: 'constraint',
  F: 'file',
  L: 'line',
  R: 'routine',
}

declare type ParseCallback = (
  code: Protocol.BackendMessageCode,
  data?: any
) => void

export class Backend {
  private _buf?: Buffer

  private _io = new SmartBuffer()

  getAuthenticationOk(): Buffer {
    return this._io
      .start()
      .writeInt8(Protocol.BackendMessageCode.Authentication)
      .writeUInt32BE(8) // Length of message contents in bytes, including self.
      .writeUInt32BE(0)
      .setLengthAndFlush(1)
  }

  getReadyForQuery(): Buffer {
    return this._io
      .start()
      .writeInt8(Protocol.BackendMessageCode.ReadyForQuery)
      .writeUInt32BE(5) // Length of message contents in bytes, including self.
      .writeInt8(Protocol.TransactionStatus.Idle)
      .setLengthAndFlush(1)
  }

  reset() {
    this._buf = undefined
  }

  parse(data: Buffer, callback: ParseCallback) {
    if (this._buf) {
      data = Buffer.concat([this._buf, data])
      this._buf = undefined
    }

    const io = new BufferReader(data)
    let offsetBookmark
    while (io.length - io.offset >= HEADER_LENGTH) {
      offsetBookmark = io.offset
      const code = io.readUInt8() as Protocol.BackendMessageCode
      const len = io.readUInt32BE()
      // Check if frame data not received yet
      if (io.length - io.offset < len - 4) {
        io.offset = offsetBookmark
        this._buf = io.readBuffer()
        return
      }
      // @ts-expect-error any
      const parser = MessageParsers[code]
      const v = parser && parser(io, code, len)
      callback(code, v)

      // Set offset to next message
      io.offset = offsetBookmark + len + 1
    }
    if (io.offset < io.length) this._buf = io.readBuffer(io.length - io.offset)
  }
}

const MessageParsers = {
  [Protocol.BackendMessageCode.Authentication]: parseAuthentication,
  [Protocol.BackendMessageCode.BackendKeyData]: parseBackendKeyData,
  [Protocol.BackendMessageCode.CommandComplete]: parseCommandComplete,
  [Protocol.BackendMessageCode.CopyData]: parseCopyData,
  [Protocol.BackendMessageCode.CopyInResponse]: parseCopyResponse,
  [Protocol.BackendMessageCode.CopyOutResponse]: parseCopyResponse,
  [Protocol.BackendMessageCode.CopyBothResponse]: parseCopyResponse,
  [Protocol.BackendMessageCode.DataRow]: parseDataRow,
  [Protocol.BackendMessageCode.ErrorResponse]: parseErrorResponse,
  [Protocol.BackendMessageCode.NoticeResponse]: parseErrorResponse,
  [Protocol.BackendMessageCode.NotificationResponse]: parseNotificationResponse,
  [Protocol.BackendMessageCode.FunctionCallResponse]: parseFunctionCallResponse,
  [Protocol.BackendMessageCode.NegotiateProtocolVersion]:
    parseNegotiateProtocolVersion,
  [Protocol.BackendMessageCode.ParameterDescription]: parseParameterDescription,
  [Protocol.BackendMessageCode.ParameterStatus]: parseParameterStatus,
  [Protocol.BackendMessageCode.ReadyForQuery]: parseReadyForQuery,
  [Protocol.BackendMessageCode.RowDescription]: parseRowDescription,
}

function parseAuthentication(
  io: BufferReader,
  code: Protocol.BackendMessageCode,
  len: number
): any {
  const kind = io.readUInt32BE()
  switch (kind) {
    case 0:
      return // AuthenticationOk
    case 2:
      return {
        kind: 'KerberosV5',
      } as Protocol.AuthenticationKerberosV5Message
    case 3:
      return {
        kind: 'CleartextPassword',
      } as Protocol.AuthenticationCleartextPasswordMessage
    case 5:
      return {
        kind: 'MD5Password',
        salt: io.readBuffer(len - 8),
      } as Protocol.AuthenticationMD5PasswordMessage
    case 6:
      return {
        kind: 'SCMCredential',
      } as Protocol.AuthenticationSCMCredentialMessage
    case 7:
      return {
        kind: 'GSS',
      } as Protocol.AuthenticationGSSMessage
    case 9:
      return {
        kind: 'SSPI',
      } as Protocol.AuthenticationSSPIMessage
    case 8:
      return {
        kind: 'GSSContinue',
        data: io.readBuffer(len - 8),
      } as Protocol.AuthenticationGSSContinueMessage
    case 10: {
      const out = {
        kind: 'SASL',
        mechanisms: [],
      } as Protocol.AuthenticationSASLMessage
      let mechanism
      while ((mechanism = io.readCString())) {
        out.mechanisms.push(mechanism)
      }
      return out
    }
    case 11:
      return {
        kind: 'SASLContinue',
        data: io.readLString(len - 8, 'utf8'),
      } as Protocol.AuthenticationSASLContinueMessage
    case 12:
      return {
        kind: 'SASLFinal',
        data: io.readLString(len - 8, 'utf8'),
      } as Protocol.AuthenticationSASLFinalMessage
    default:
      throw new Error(`Unknown authentication kind (${kind})`)
  }
}

function parseBackendKeyData(io: BufferReader): Protocol.BackendKeyDataMessage {
  return {
    processID: io.readUInt32BE(),
    secretKey: io.readUInt32BE(),
  } as Protocol.BackendKeyDataMessage
}

function parseCommandComplete(
  io: BufferReader
): Protocol.CommandCompleteMessage {
  return {
    command: io.readCString('utf8'),
  } as Protocol.CommandCompleteMessage
}

function parseCopyData(
  io: BufferReader,
  code: Protocol.BackendMessageCode,
  len: number
): Protocol.CopyDataMessage {
  return {
    data: io.readBuffer(len - 4),
  } as Protocol.CopyDataMessage
}

function parseCopyResponse(io: BufferReader): Protocol.CopyResponseMessage {
  const out = {
    overallFormat:
      io.readUInt8() === 0
        ? Protocol.DataFormat.text
        : Protocol.DataFormat.binary,
    columnCount: io.readUInt16BE(),
  } as Protocol.CopyResponseMessage

  if (out.columnCount) {
    out.columnFormats = []
    for (let i = 0; i < out.columnCount; i++) {
      out.columnFormats.push(
        io.readUInt16BE() === 0
          ? Protocol.DataFormat.text
          : Protocol.DataFormat.binary
      )
    }
  }
  return out
}

function parseDataRow(io: BufferReader): Protocol.DataRowMessage {
  const out = {
    columnCount: io.readUInt16BE(),
  } as Protocol.DataRowMessage

  if (out.columnCount) {
    out.columns = []
    for (let i = 0; i < out.columnCount; i++) {
      // The length of the column value, in bytes (this count does not include itself).
      // Can be zero. As a special case, -1 indicates a NULL column value.
      // No value bytes follow in the NULL case.
      const l = io.readInt32BE()
      if (l < 0) out.columns.push(null)
      else out.columns.push(io.readBuffer(l))
    }
  }
  return out
}

function parseErrorResponse(io: BufferReader): Protocol.ErrorResponseMessage {
  const out = {} as Protocol.ErrorResponseMessage

  let fieldType
  while ((fieldType = io.readLString(1)) !== '\0') {
    const value = io.readCString('utf8')
    // @ts-expect-error null as key
    const key = ErrorFieldTypes[fieldType]
    // @ts-expect-error any
    if (key) out[key] = value
  }
  return out
}

function parseNotificationResponse(
  io: BufferReader
): Protocol.NotificationResponseMessage {
  return {
    processId: io.readUInt32BE(),
    channel: io.readCString(),
    payload: io.readCString(),
  }
}

function parseFunctionCallResponse(
  io: BufferReader,
  code: Protocol.BackendMessageCode,
  len: number
): Protocol.FunctionCallResponseMessage {
  return {
    result: io.readBuffer(len - 4),
  } as Protocol.FunctionCallResponseMessage
}

function parseNegotiateProtocolVersion(
  io: BufferReader
): Protocol.NegotiateProtocolVersionMessage {
  return {
    supportedVersionMinor: io.readUInt32BE(),
    numberOfNotSupportedVersions: io.readUInt32BE(),
    option: io.readCString('utf8'),
  } as Protocol.NegotiateProtocolVersionMessage
}

function parseParameterDescription(
  io: BufferReader
): Protocol.ParameterDescriptionMessage {
  const out = {
    parameterCount: io.readUInt32BE(),
    parameterIds: [],
  } as Protocol.ParameterDescriptionMessage

  for (let i = 0; i < out.parameterCount; i++) {
    out.parameterIds.push(io.readUInt32BE())
  }

  return out
}

function parseParameterStatus(
  io: BufferReader
): Protocol.ParameterStatusMessage {
  return {
    name: io.readCString('utf8'),
    value: io.readCString('utf8'),
  } as Protocol.ParameterStatusMessage
}

function parseReadyForQuery(io: BufferReader): Protocol.ReadyForQueryMessage {
  return {
    status: io.readLString(1),
  } as Protocol.ReadyForQueryMessage
}

function parseRowDescription(io: BufferReader): Protocol.RowDescriptionMessage {
  const fieldCount = io.readUInt16BE()
  const out: Protocol.RowDescriptionMessage = {
    fields: [],
  }

  for (let i = 0; i < fieldCount; i++) {
    const field: Protocol.RowDescription = {
      fieldName: io.readCString('utf8'),
      tableId: io.readInt32BE(),
      columnId: io.readInt16BE(),
      dataTypeId: io.readInt32BE(),
      fixedSize: io.readInt16BE(),
      modifier: io.readInt32BE(),
      format:
        io.readInt16BE() === 0
          ? Protocol.DataFormat.text
          : Protocol.DataFormat.binary,
    }
    out.fields.push(field)
  }

  return out
}
