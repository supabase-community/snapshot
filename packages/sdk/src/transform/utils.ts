import type {
  ColumnTransformFunction,
  ColumnTransformScalar,
  TableTransformFunction,
  TableTransformScalar,
  TransformConfigOptions,
  TransformConfig,
} from '../config/snapletConfig/v2/getConfig/parseConfig.js'

export const isColumnFunctionTransform = (
  transform: unknown
): transform is ColumnTransformFunction => {
  return typeof transform === 'function'
}

export const isTableFunctionTransform = (
  transform: unknown
): transform is TableTransformFunction => {
  return typeof transform === 'function'
}

// Since our transform types are quite complex, those utils are here
// to help us to extract the informations we need from them with a
// correct and typed way with the minimal amount of casts.
export const extractTransformationsStructure = (config: TransformConfig) => {
  const { $mode, $parseJson, ...transform } = config ?? {}
  return [{ $mode, $parseJson } as TransformConfigOptions, transform] as const
}

export const partitionTableTransformation = (
  transforms: ReturnType<typeof extractTransformationsStructure>[1]
): {
  functions: Record<string, TableTransformFunction>
  scalars: Record<string, TableTransformScalar>
} => {
  const functions: Record<string, TableTransformFunction> = {}
  const scalars: Record<string, TableTransformScalar> = {}
  for (const [key, value] of Object.entries(transforms)) {
    if (isTableFunctionTransform(value)) {
      functions[key] = value
    } else {
      scalars[key] = value as TableTransformScalar
    }
  }
  return {
    functions,
    scalars,
  }
}

export const partionColumnTransformations = (
  columnTransforms: TableTransformScalar
): {
  functions: Record<string, ColumnTransformFunction>
  scalars: Record<string, ColumnTransformScalar>
} => {
  const functions: Record<string, ColumnTransformFunction> = {}
  const scalars: Record<string, ColumnTransformScalar> = {}
  for (const [key, value] of Object.entries(columnTransforms)) {
    if (isColumnFunctionTransform(value)) {
      functions[key] = value
    } else {
      scalars[key] = value as ColumnTransformScalar
    }
  }
  return {
    functions,
    scalars,
  }
}
