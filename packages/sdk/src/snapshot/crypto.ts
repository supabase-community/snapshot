import crypto from 'crypto'
import fs, { readFile } from 'fs-extra'
import os from 'os'
import { promisify } from 'util'
import zlib from 'zlib'

import { saveProjectConfig, getProjectConfig } from '../config/index.js'
import { getPaths } from '../paths.js'
import { compress } from './compress.js'

type EncryptVersion = '1' | '2'
export interface PublicEncryptionPayload {
  version: EncryptVersion
  ivHex: string
  encryptedSessionKeyHex: string
}

export interface EncryptionPayload {
  iv: Buffer | Uint8Array
  unencryptedSessionKey: Buffer | Uint8Array
  public: PublicEncryptionPayload
}

const DEFAULT_ENCRYPT_VERSION = '2'

// TODO_BEFORE_REVIEW: use the latest version of encryption
export const generateEncryptionPayload = (
  publicKey: string,
  version?: EncryptVersion
): EncryptionPayload => {
  const generateFns = {
    1: generateEncryptionPayloadV1,
    2: generateEncryptionPayloadV2,
  } as const

  version ??=
    (process.env.SNAPLET_ENCRYPT_VERSION as '1' | '2') ??
    DEFAULT_ENCRYPT_VERSION

  const generateFn = generateFns[version]
  return generateFn(publicKey)
}

export const hydrateEncryptionPayload = (
  privateKey: string,
  publicEncryptionPayload: PublicEncryptionPayload
): EncryptionPayload => {
  const hydrateFns = {
    1: hydrateEncryptionPayloadV1,
    2: hydrateEncryptionPayloadV2,
  } as const

  const version = String(publicEncryptionPayload.version) as '1' | '2'
  const hydrateFn = hydrateFns[version]
  return hydrateFn(privateKey, publicEncryptionPayload)
}

const generateEncryptionPayloadV2 = (publicKey: string) => {
  const iv = crypto.randomBytes(16)

  const { key: unencryptedSessionKey, encryptedKey: encryptedSessionKeyHex } =
    generateSessionKey(publicKey)

  return {
    unencryptedSessionKey,
    iv,
    public: {
      version: '2' as const,
      ivHex: iv.toString('hex'),
      encryptedSessionKeyHex,
    },
  }
}

const hydrateEncryptionPayloadV2 = (
  privateKey: string,
  publicEncryptionPayload: PublicEncryptionPayload
): EncryptionPayload => {
  const unencryptedSessionKey = decryptSessionKey(
    privateKey,
    publicEncryptionPayload.encryptedSessionKeyHex
  )

  const iv = Buffer.from(publicEncryptionPayload.ivHex, 'hex')

  return {
    unencryptedSessionKey,
    iv,
    public: publicEncryptionPayload,
  }
}

const generateEncryptionPayloadV1 = (publicKey: string): EncryptionPayload => {
  const unencryptedIv = crypto.randomBytes(16)
  const encryptedIv = crypto.publicEncrypt(publicKey, unencryptedIv)

  const override = process.env.SNAPLET_ENCRYPT_SESSION_KEY_OVERRIDE_V1

  const unencryptedSessionKey = override
    ? Buffer.from(override)
    : crypto.randomBytes(32)

  const encryptedSessionKey = crypto.publicEncrypt(
    publicKey,
    unencryptedSessionKey
  )

  return {
    iv: unencryptedIv,
    unencryptedSessionKey,
    public: {
      version: '1' as EncryptVersion,
      ivHex: encryptedIv.toString('hex'),
      encryptedSessionKeyHex: encryptedSessionKey.toString('hex'),
    },
  }
}

const hydrateEncryptionPayloadV1 = (
  privateKey: string,
  publicEncryptionPayload: PublicEncryptionPayload
) => {
  const unencryptedSessionKey = decryptSessionKey(
    privateKey,
    publicEncryptionPayload.encryptedSessionKeyHex
  )
  const iv = decryptSessionKey(privateKey, publicEncryptionPayload.ivHex)

  return {
    unencryptedSessionKey,
    iv,
    public: publicEncryptionPayload,
  }
}

export const generateSessionKey = (publicKey: string, size = 32) => {
  try {
    const key = crypto.randomBytes(size)
    const encryptedKey = crypto.publicEncrypt(publicKey, key)
    return {
      key,
      encryptedKey: encryptedKey.toString('hex'),
    }
  } catch (err: any) {
    throw new Error(
      `Failed to generate session key using public key: ${err.message}`
    )
  }
}

export const decryptSessionKey = (
  privateKey: string,
  encryptedSessionKey: string
) => {
  try {
    const sessionKey = Buffer.from(encryptedSessionKey, 'hex')
    const decryptedkey = crypto.privateDecrypt(privateKey, sessionKey)

    return new Uint8Array(decryptedkey)
  } catch (err: any) {
    throw new Error(
      `Failed to decrypt session key using private key: ${err.message}`
    )
  }
}

const compressAndEncrypt = async (
  src: string,
  dst: string,
  encryptionPayload: EncryptionPayload
): Promise<{
  oldSize: number
  newSize: number
  ms: number
}> => {
  return new Promise((resolve, reject) => {
    const startTime = Date.now()

    const encryptionStream = crypto.createCipheriv(
      'aes-256-ctr',
      encryptionPayload.unencryptedSessionKey,
      encryptionPayload.iv
    )

    const brotli = zlib.createBrotliCompress({
      params: {
        [zlib.constants.BROTLI_PARAM_QUALITY]: 1,
      },
    })

    const stream = fs
      .createReadStream(src)
      .pipe(brotli)
      .pipe(encryptionStream)
      .pipe(fs.createWriteStream(dst))

    stream.on('error', reject)

    stream.on('finish', () => {
      const oldSize = fs.statSync(src).size
      const newSize = fs.statSync(dst).size

      resolve({
        oldSize,
        newSize,
        ms: Date.now() - startTime,
      })
    })
  })
}

export const decompressAndDecrypt = (
  src: string,
  dst: string,
  encryptionPayload: EncryptionPayload
): Promise<{
  oldSize: number
  newSize: number
  ms: number
}> => {
  return new Promise((resolve, reject) => {
    const startTime = Date.now()

    const decryptionStream = crypto.createDecipheriv(
      'aes-256-ctr',
      encryptionPayload.unencryptedSessionKey,
      encryptionPayload.iv
    )

    const brotli = zlib.createBrotliDecompress({
      params: { [zlib.constants.BROTLI_PARAM_QUALITY]: 1 },
    })

    const stream = fs
      .createReadStream(src)
      .pipe(decryptionStream)
      .pipe(brotli)
      .pipe(fs.createWriteStream(dst))

    stream.on('error', reject)

    stream.on('finish', () => {
      const oldSize = fs.statSync(src).size
      const newSize = fs.statSync(dst).size

      resolve({ oldSize, newSize, ms: Date.now() - startTime })
    })
  })
}

export const encryptAndCompressSnapshotFile = async (
  filePath: string,
  encryptionPayload: EncryptionPayload | undefined
) => {
  const compressedFilePath = `${filePath}.br`

  const result = encryptionPayload
    ? await compressAndEncrypt(filePath, compressedFilePath, encryptionPayload)
    : await compress(filePath, compressedFilePath)

  return {
    ...result,
    compressedFilePath,
  }
}

export const writeEncryptionConfig = async ({
  publicKey,
  privateKey,
}: {
  publicKey?: string
  privateKey?: string
}) => {
  const { project } = getPaths()

  if (project.privateKey) {
    if (privateKey) {
      const content = [
        'NOTE: This private key is used to decrypt snapshots.',
        'Do not share this with entities that should not be able to decrypt your snapshots.',
        '',
        privateKey,
      ].join(os.EOL)
      await fs.writeFile(project.privateKey, content)
    }

    const oldConfig = getProjectConfig()
    saveProjectConfig({
      ...oldConfig,
      publicKey,
    })
  }

  return project.privateKey
}

export const readPrivateKey = async () => {
  try {
    const { project } = getPaths()

    if (project.privateKey) {
      const privateKey = await readFile(project.privateKey, {
        encoding: 'utf8',
      })

      return privateKey
    }

    return null
  } catch (err) {
    return null
  }
}

const generateKeyPairAsync = promisify(crypto.generateKeyPair)

export const generateRSAKeys = () => {
  return generateKeyPairAsync('rsa', {
    modulusLength: 3072,
    publicKeyEncoding: { type: 'pkcs1', format: 'pem' },
    privateKeyEncoding: { type: 'pkcs1', format: 'pem' },
  })
}

export const generatePublicKey = (privateKey: string) => {
  const publicKeyObject = crypto.createPublicKey({
    key: privateKey,
    format: 'pem',
  })

  return publicKeyObject.export({ format: 'pem', type: 'pkcs1' })
}
