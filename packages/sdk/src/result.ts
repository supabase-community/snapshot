import { ResultError, ResultSuccess } from './types.js'

export function ok<T>(value: T): ResultSuccess<T> {
  return { ok: true, value }
}

export function err<E>(error: E): ResultError<E> {
  return { ok: false, error }
}
