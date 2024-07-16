import { identity } from 'lodash'

import {
  ColumnTransform,
  RowTransform,
  RowTransformObject,
  Transform,
} from '../config/index.js'
import { createStructureObject } from '../createStructureObject.js'
import { Parsers, Serializers } from '../csv.js'
import { ErrorList, isError } from '../errors.js'
import { TransformError } from '../transformError.js'
import { Json, RowShape, TransformContext } from '../types.js'
import {
  DEFAULT_TRANSFORM_MODE,
  TransformFallbackMode,
  applyFallback,
} from './fallbacks.js'
import { IntrospectedStructure } from '../db/introspect/introspectDatabase.js'
import { SnapletError } from '../errors.js'
import { extractTransformationsStructure } from '../transform/utils.js'

export interface FullTransformOptions {
  mode: TransformFallbackMode
  parseJson: boolean
}

export type TransformOptions = Partial<FullTransformOptions>

type CreateStructureObjectParams = Parameters<typeof createStructureObject>[0]
type CreateStructureObjectParamsTable =
  CreateStructureObjectParams['tables'][number]

// We also need some more informations for our columns than the ones we use
// in createStructureObject so we augment the type here
export type ColumnInfos = CreateStructureObjectParamsTable['columns'][number] &
  Pick<
    IntrospectedStructure['tables'][number]['columns'][number],
    | 'constraints'
    | 'schema'
    | 'table'
    | 'generated'
    | 'maxLength'
    | 'typeCategory'
  >

type TableInfos = Omit<CreateStructureObjectParamsTable, 'columns'> & {
  columns: Array<ColumnInfos>
}

// By derivating and reducing the types to the minimal exact informations we need
// it allows us to switch between IntrospectedStructure and IntrospectedStructure without
// any code changes.
export type StructureInfos = Pick<IntrospectedStructure, 'enums'> &
  Omit<CreateStructureObjectParams, 'tables'> & {
    tables: Array<TableInfos>
  }

export interface TransformRowContext {
  options: FullTransformOptions
  structure: StructureInfos
  transform: Transform
}

export class TransformConfig {
  options: FullTransformOptions
  structure: StructureInfos
  transform: Transform

  constructor(
    transform: TransformConfig['transform'],
    structure: TransformConfig['structure'],
    options: TransformConfig['options']
  ) {
    this.transform = transform
    this.structure = structure
    this.options = options
  }

  transformRow<Row extends RowShape>(ctx: TransformContext<Row>): Row {
    try {
      return applyRowTransform<Row>(ctx, this)
    } catch (e) {
      if (
        isError(e) &&
        !(e instanceof TransformError) &&
        !(e instanceof ErrorList)
      ) {
        throw new TransformError(ctx, e)
      } else {
        throw e
      }
    }
  }
}

const TRANSFORM_OPTIONS_DEFAULTS = {
  mode: DEFAULT_TRANSFORM_MODE,
  parseJson: true,
}

type TransformationsOptions = ReturnType<
  typeof extractTransformationsStructure
>[0]
type TransformationsFunctions = ReturnType<
  typeof extractTransformationsStructure
>[1]

export const createTransformConfig = async (
  transformations: TransformationsFunctions,
  structure: TransformConfig['structure'],
  optionsOverrides?: TransformationsOptions
): Promise<TransformConfig> => {
  const transform = transformations

  const options: TransformConfig['options'] = {
    mode: optionsOverrides?.$mode ?? TRANSFORM_OPTIONS_DEFAULTS.mode,
    parseJson:
      optionsOverrides?.$parseJson ?? TRANSFORM_OPTIONS_DEFAULTS.parseJson,
  }

  return new TransformConfig(transform, structure, options)
}

const applyColumnTransform = <Row extends RowShape>(
  row: Row,
  initialValue: Json,
  columnTransform: ColumnTransform<Row>
): Json => {
  if (initialValue === null) {
    return initialValue
  } else if (typeof columnTransform === 'function') {
    return columnTransform({ row, value: initialValue })
  } else {
    return columnTransform
  }
}

const applyRowTransformObject = <Row extends RowShape>(
  ctx: TransformContext<Row>,
  transform: RowTransformObject<Row>,
  config: TransformConfig
): Row => {
  const results: Partial<Row> = {}

  const columnNames = Object.keys(ctx.row.parsed) as (keyof Row)[]
  const errors: Error[] = []

  for (const columnName of columnNames) {
    try {
      if (typeof transform?.[columnName] !== 'undefined') {
        results[columnName] = applyColumnTransform(
          ctx.row.parsed,
          ctx.row.parsed[columnName],
          transform[columnName] as ColumnTransform<Row>
        ) as Row[keyof Row]
      } else {
        results[columnName] = applyFallback({
          row: ctx.row,
          schemaName: ctx.schema,
          tableName: ctx.table,
          columnName: columnName as string,
          mode: config.options.mode,
          structure: config.structure,
          parseJson: config.options.parseJson,
        }) as Row[keyof Row]
      }
    } catch (e) {
      let error: Error

      if (isError(e)) {
        error = new TransformError(
          {
            ...ctx,
            column: columnName.toString(),
          },
          e
        )
      } else {
        error = e as Error
      }

      errors.push(error)
    }
  }

  if (errors.length) {
    throw new ErrorList(errors)
  }

  return results as Row
}

const ensureRowTransform = <Row extends RowShape>(
  ctx: TransformContext<Row>,
  config: TransformConfig
): Partial<RowTransform<Row>> => {
  const schemaTransforms = config.transform?.[ctx.schema]

  if (!schemaTransforms) {
    if (config.options.mode === 'strict') {
      throw new SnapletError('CONFIG_STRICT_TRANSFORM_MISSING_SCHEMA', {
        schema: ctx.schema,
      })
    }
  }

  const rowTransforms = schemaTransforms?.[ctx.table]

  if (!rowTransforms) {
    if (config.options.mode === 'strict') {
      throw new SnapletError('CONFIG_STRICT_TRANSFORM_MISSING_TABLE', {
        schema: ctx.schema,
        table: ctx.table,
      })
    }
  }
  return rowTransforms
}

const applyRowTransform = <Row extends RowShape>(
  ctx: TransformContext<Row>,
  config: TransformConfig
): Row => {
  const transform = ensureRowTransform(ctx, config)

  const nextTransform =
    typeof transform === 'function'
      ? transform({
          row: ctx.row.parsed,
          rowIndex: ctx.row.line,
        })
      : transform

  return applyRowTransformObject(ctx, nextTransform, config)
}

export const getTransformParsers = (config: TransformConfig): Parsers => {
  const parsers: Parsers = {}

  if (!config.options.parseJson) {
    parsers.Json = identity
  }

  return parsers
}

export const getTransformSerializers = (
  config: TransformConfig
): Serializers => {
  const serializers: Serializers = {}

  if (!config.options.parseJson) {
    serializers.Json = identity
  }

  return serializers
}
