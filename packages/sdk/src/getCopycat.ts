import pMemoize from 'p-memoize-cjs'

type CopycatLib = Awaited<typeof import('@snaplet/copycat')>
type Copycat = CopycatLib['copycat']

type HashKey = [number, number, number, number]

const DEFAULT_COPYCAT_HASH_KEY: HashKey = [
  1363698228, 607151991, 1148352113, 2032805430,
]

let hashKey: HashKey

export const getCopycat = pMemoize(_getCopycat)

async function _getCopycat(): Promise<CopycatLib> {
  const copycat = await import('@snaplet/copycat')
  await initCopycatHashKey()
  return copycat
}

function ensureHashKey(copycat: Copycat, secret: string): HashKey {
  if (secret.length >= 16) {
    return copycat.generateHashKey(secret.slice(0, 16))
  }

  const base = copycat.int(secret)
  return copycat.times(4, base, copycat.int) as HashKey
}

async function initCopycatHashKey() {
  if (hashKey) {
    return
  }

  const { copycat } = await import('@snaplet/copycat')
  hashKey = DEFAULT_COPYCAT_HASH_KEY

  if (process.env.COPYCAT_HASH_KEY) {
    hashKey = JSON.parse(process.env.COPYCAT_HASH_KEY)
  } else {
    copycat.setHashKey(DEFAULT_COPYCAT_HASH_KEY)
    const secret = process.env.COPYCAT_SECRET ?? null

    if (secret) {
      hashKey = ensureHashKey(copycat, secret)
    }
  }

  copycat.setHashKey(hashKey)
}
