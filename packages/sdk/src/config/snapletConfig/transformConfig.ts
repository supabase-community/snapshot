import { Json } from '../../types.js'
import type { Transform } from './v2/getConfig/parseConfig.js'

type RowTransformFn<Row> = (params: {
  row: Row
  rowIndex: number
}) => Partial<Row> | Promise<Partial<Row>>

type ColumnTransformFn<Row> = (params: { row: Row; value: Json }) => Json

export type RowTransformObject<Row> = Partial<
  Record<keyof Row, ColumnTransform<Row>>
>

export type RowTransform<Row> = RowTransformObject<Row> | RowTransformFn<Row>

export type ColumnTransform<Row> = Json | ColumnTransformFn<Row>

export type { Transform }

export type TransformConfigContext = {
  structure: Record<string, any>
}

export type TransformConfigFn = (
  context: TransformConfigContext
) => Transform | Promise<Transform>
