import { Protocol } from './protocol.js'

export class DatabaseError extends Error {
  severity?: string
  code?: string
  detail?: string
  hint?: string
  position?: number
  internalPosition?: string
  internalQuery?: string
  where?: string
  schema?: string
  table?: string
  column?: string
  dataType?: string
  constraint?: string
  lineNr?: number
  colNr?: number
  line?: string

  constructor(msg: Protocol.ErrorResponseMessage) {
    super(msg.message)
    Object.assign(this, {
      ...msg,
      line: undefined,
      file: undefined,
      routine: undefined,
    })
    if (msg.position) this.position = parseInt(msg.position, 10) || undefined
  }
}
