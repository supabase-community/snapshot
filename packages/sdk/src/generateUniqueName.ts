import { copycat } from '@snaplet/copycat'
import { predicates, objects } from 'friendly-words'
import { v4 as uuid } from 'uuid'

type Prefix = 'pr' | 'ss' | 'pdb'

export function generateUniqueName(prefix: Prefix) {
  const key = uuid()

  return [
    prefix,
    copycat.oneOf(key, predicates),
    copycat.oneOf(key, objects),
    copycat.int(key, { min: 100000, max: 999999 }),
  ].join('-')
}
