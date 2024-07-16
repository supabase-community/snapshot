import { isInstanceOf } from '~/lang.js'
import { Serializable } from './types.js'
import { Json } from '~/types.js'
import { mapValues } from 'lodash'

export const serializeValue = (value: Serializable): Json | undefined => {
  return isInstanceOf(value, Date) ? value.toISOString() : value
}

export const serializeModelValues = (model: {
  [field: string]: Serializable
}): {
  [field: string]: Json | undefined
} => mapValues(model, serializeValue)
