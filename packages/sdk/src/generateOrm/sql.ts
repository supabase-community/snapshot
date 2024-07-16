import { isNestedArrayPgType } from '~/pgTypes.js'
import type { Json } from '~/types.js'
import { serializeArrayColumn } from '~/csv.js'

export const serializeToSQL = (type: string, value: Json): Json => {
  if (isNestedArrayPgType(type)) {
    return serializeArrayColumn(value, type)
  }

  if (['json', 'jsonb'].includes(type)) {
    return JSON.stringify(value)
  }

  return value
}
