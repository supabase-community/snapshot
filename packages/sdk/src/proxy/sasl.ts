/* eslint-disable no-inner-declarations */
/* eslint-disable no-bitwise */
import crypto, { BinaryLike } from 'crypto'

// eslint-disable-next-line @typescript-eslint/no-namespace
export namespace SASL {
  const CLIENT_KEY = 'Client Key'
  const SERVER_KEY = 'Server Key'
  const GS2_HEADER = 'n,,'

  export interface Session {
    username: string
    mechanism: string
    nonce: string
    clientFirstMessage: string
    clientFinalMessage: string
    serverSignature: string
  }

  export function createSession(username: string, mechanism: string): Session {
    const nonce = crypto.randomBytes(18).toString('base64')
    const clientFirstMessage = `${GS2_HEADER}${firstMessageBare(
      username,
      nonce
    )}`
    return {
      username,
      mechanism,
      nonce,
      clientFirstMessage,
    } as Session
  }

  export function continueSession(
    session: Session,
    password: string,
    data: string
  ) {
    const s = data.toString()
    const items = s.split(',')
    let nonce = ''
    let salt = ''
    let iteration = 0
    for (const i of items) {
      switch (i[0]) {
        case 'r':
          nonce = i.substring(2)
          break
        case 's':
          salt = i.substring(2)
          break
        case 'i':
          iteration = parseInt(i.substring(2), 10)
          break
      }
    }
    if (!nonce)
      throw new Error('SASL: SCRAM-SERVER-FIRST-MESSAGE: nonce missing')
    if (!salt) throw new Error('SASL: SCRAM-SERVER-FIRST-MESSAGE: salt missing')
    if (!iteration)
      throw new Error('SASL: SCRAM-SERVER-FIRST-MESSAGE: iteration missing')

    if (!nonce.startsWith(session.nonce))
      throw new Error('SASL: Server nonce does not start with client nonce')

    const serverFirstMessage = `r=${nonce},s=${salt},i=${iteration}`
    const clientFinalMessageWithoutProof = `c=${encode64(
      GS2_HEADER
    )},r=${nonce}`
    const authMessage = `${firstMessageBare(
      session.username,
      session.nonce
    )},${serverFirstMessage},${clientFinalMessageWithoutProof}`

    const saltPass = hi(password, salt, iteration)
    const clientKey = hmac(saltPass, CLIENT_KEY)
    const storedKey = hash(clientKey)
    const clientSignature = hmac(storedKey, authMessage)
    const clientProofBytes = xor(clientKey, clientSignature)
    const clientProof = clientProofBytes.toString('base64')

    const serverKey = hmac(saltPass, SERVER_KEY)
    const serverSignatureBytes = hmac(serverKey, authMessage)
    session.serverSignature = serverSignatureBytes.toString('base64')
    session.clientFinalMessage =
      clientFinalMessageWithoutProof + ',p=' + clientProof
  }

  export function finalizeSession(session: Session, data: string) {
    let serverSignature = ''

    const arr = data.split(',')
    for (const s of arr) {
      if (s[0] === 'v') serverSignature = s.substr(2)
    }

    if (serverSignature !== session.serverSignature)
      throw new Error('SASL: Server signature does not match')
  }

  function firstMessageBare(username: string, nonce: string): string {
    return `n=${username},r=${nonce}`
  }

  /**
   * Hi() is, essentially, PBKDF2 [RFC2898] with HMAC() as the
   * pseudorandom function (PRF) and with dkLen == output length of
   * HMAC() == output length of H()
   */
  function hi(text: string, salt: string, iterations: number): Buffer {
    return crypto.pbkdf2Sync(
      text,
      Buffer.from(salt, 'base64'),
      iterations,
      32,
      'sha256'
    )
  }

  const encode64 = (str: string) => Buffer.from(str).toString('base64')

  function hmac(key: Buffer, msg: BinaryLike): Buffer {
    return crypto.createHmac('sha256', key).update(msg).digest()
  }

  function hash(data: Buffer): Buffer {
    return crypto.createHash('sha256').update(data).digest()
  }

  function xor(a: any, b: any): Buffer {
    a = Buffer.isBuffer(a) ? a : Buffer.from(a)
    b = Buffer.isBuffer(b) ? b : Buffer.from(b)
    if (a.length !== b.length)
      throw new Error('Buffers must be of the same length')
    const l = a.length
    const out = Buffer.allocUnsafe(l)
    for (let i = 0; i < l; i++) {
      out[i] = a[i] ^ b[i]
    }
    return out
  }
}
