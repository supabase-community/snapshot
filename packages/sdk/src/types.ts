// Global types helpers
export type NonEmptyArray<T> = [T, ...T[]]
export type DistributivePick<T, K extends keyof T> = T extends unknown
  ? Pick<T, K>
  : never
export type AsyncFunctionSuccessType<
  T extends (...args: any) => Promise<unknown>,
> = Awaited<ReturnType<T>>
export type JsonPrimitive = null | number | string | boolean
export type Nested<V> =
  | V
  | { [s: string]: V | Nested<V> }
  | Array<V | Nested<V>>
export type Json = Nested<JsonPrimitive>
export type RowShape = Record<string, Json>
export type TransformContext<Row extends RowShape = RowShape> = {
  schema: string
  table: string
  columns?: string[]
  row: {
    line: number
    raw: Record<string, string | null>
    parsed: Row
  }
  column?: string
}
export type ResultSuccess<T> = { ok: true; value: T }
export type ResultError<E> = { ok: false; error: E }
export type Result<T, E = Error> = ResultSuccess<T> | ResultError<E>
