import { Protocol } from './protocol.js'
import { SASL } from './sasl.js'
import { SmartBuffer } from './SmartBuffer.js'

// type Maybe<T> = T | undefined
// type OID = number

// eslint-disable-next-line @typescript-eslint/no-namespace
export namespace Frontend {
  export interface StartupMessageArgs {
    user: string
    database: string

    [index: string]: string
  }

  // export interface ParseMessageArgs {
  //   statement?: string
  //   sql: string
  //   paramTypes?: Maybe<OID>[]
  // }

  // export interface DescribeMessageArgs {
  //   type: 'P' | 'S'
  //   name?: string
  // }

  // export interface ExecuteMessageArgs {
  //   portal?: string
  //   fetchCount?: number
  // }

  // export interface CloseMessageArgs {
  //   type: 'P' | 'S'
  //   name?: string
  // }
}

export class Frontend {
  private _io = new SmartBuffer()

  getSSLRequestMessage(): Buffer {
    return this._io
      .start()
      .writeUInt32BE(8) // Length of message contents in bytes, including self.
      .writeUInt16BE(1234)
      .writeUInt16BE(5679)
      .flush()
  }

  getGSSAPIRequestMessage(): Buffer {
    return this._io
      .start()
      .writeUInt32BE(8) // Length of message contents in bytes, including self.
      .writeUInt16BE(1234)
      .writeUInt16BE(5680)
      .flush()
  }

  getParameterStatus(payload: { name: string; value: string }): Buffer {
    return (
      this._io
        .start()
        .writeInt8(Protocol.BackendMessageCode.ParameterStatus)
        // Length of message contents in bytes
        .writeInt32BE(payload.name.length + payload.value.length)
        .writeCString(payload.name, 'utf8')
        .writeCString(payload.value, 'utf8')
        .setLengthAndFlush(1)
    )
  }

  getStartupMessage(args: Frontend.StartupMessageArgs): Buffer {
    const io = this._io
      .start()
      .writeInt32BE(0) // Preserve length
      .writeInt16BE(Protocol.VERSION_MAJOR)
      .writeInt16BE(Protocol.VERSION_MINOR)
    for (const [k, v] of Object.entries(args)) {
      if (k !== 'client_encoding')
        io.writeCString(k, 'utf8').writeCString(v, 'utf8')
    }
    io.writeCString('client_encoding', 'utf8')
      .writeCString('UTF8', 'utf8')
      .writeUInt8(0)

    return io.setLengthAndFlush(0)
  }

  getSASLMessage(sasl: SASL.Session): Buffer {
    return this._io
      .start()
      .writeInt8(Protocol.FrontendMessageCode.PasswordMessage)
      .writeInt32BE(0) // Preserve header
      .writeCString(sasl.mechanism, 'utf8')
      .writeLString(sasl.clientFirstMessage)
      .setLengthAndFlush(1)
  }

  getSASLFinalMessage(session: SASL.Session): Buffer {
    return this._io
      .start()
      .writeInt8(Protocol.FrontendMessageCode.PasswordMessage)
      .writeInt32BE(0) // Preserve header
      .writeString(session.clientFinalMessage)
      .setLengthAndFlush(1)
  }
}

// context(justinvdm, 3 October 2023): StartMessage messages do not contain an identifier for the message type
// When the client is connected, we get two messages without a message type - an initial one that is
// always 8 bytes in length, then next the startup message.
export const isStartupMessage = (data: Buffer): boolean => {
  return data.readUInt8() === 0 && data.length > 8
}

export const parseStartupMessage = (
  data: Buffer
): {
  args: Frontend.StartupMessageArgs
} => {
  const argsData = data.subarray(
    4 + // message length (Int32BE)
      2 + // protocol major versin (Int16BE)
      2 // protocol minor version (Int16BE)
  )

  const args =
    extractParametersFromBuffer<Frontend.StartupMessageArgs>(argsData)

  return { args }
}

function extractParametersFromBuffer<Parameters extends Record<string, string>>(
  buffer: Buffer
): Parameters {
  const parameters: Record<string, string> = {}

  let offset = 0

  while (offset < buffer.length) {
    const name = buffer.toString('utf8', offset, buffer.indexOf(0, offset))
    offset += name.length + 1 // Move past the null terminator
    const value = buffer.toString('utf8', offset, buffer.indexOf(0, offset))
    offset += value.length + 1 // Move past the null terminator
    parameters[name] = value
  }

  return parameters as Parameters
}
