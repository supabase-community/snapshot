import type {
  DataModel,
  DataModelModel,
  DataModelField,
  DataModelScalarField,
} from '../../generateOrm/dataModel/dataModel.js'
import { getTransform } from '../generateTransform.js'
import type {
  PredictedShape,
  TableShapePredictions,
} from '../../db/structure.js'
import type { IntrospectedStructure } from '../../db/introspect/introspectDatabase.js'
import type { UserModels } from '../../generateOrm/plan/types.js'
import { PG_GEOMETRY_TYPES, PG_TO_JS_TYPES, PgTypeName } from '../../pgTypes.js'
import { Shape, findShape } from '../../shapes.js'
import { SHAPE_PREDICTION_CONFIDENCE_THRESHOLD } from '../../pii.js'
import { stringify } from 'javascript-stringify'
import { Fingerprint, isJsonField } from '~/generateOrm/index.js'
import { generateJsonField } from './generateJsonField.js'
import { addOptionsToModelDefaultCode } from './addOptionsToModelDefaultCode.js'
import { ShapeGenerate } from '~/shapesGenerate.js'
import { SEED_PG_TEMPLATES } from '~/templates/sets/seed/pg.js'

const determineShape = (
  col: { type: string; name: string },
  predictedShape: PredictedShape | null
) => {
  let shape: Shape | ShapeGenerate | null

  // Return deterministic shapes based on type
  if (col.type === 'uuid') {
    return 'UUID'
  }
  if (['macaddr', 'macaddr8'].includes(col.type)) {
    return 'MAC_ADDRESS'
  }
  if (['inet', 'cidr'].includes(col.type)) {
    return 'IP_ADDRESS'
  }
  if (PG_GEOMETRY_TYPES.has(col.type)) {
    return null
  }

  if (
    predictedShape &&
    predictedShape.shape &&
    predictedShape.confidence &&
    predictedShape.confidence > SHAPE_PREDICTION_CONFIDENCE_THRESHOLD
  ) {
    shape = predictedShape?.shape

    if (shape) {
      return shape
    }
  }

  const jsType = PG_TO_JS_TYPES[col.type as PgTypeName]

  if (!jsType) {
    return null
  }

  return findShape(col.name, jsType)?.shape ?? null
}

const findEnumType = (dataModel: DataModel, field: DataModelField) =>
  Object.entries(dataModel.enums).find(
    ([enumName]) => enumName === field.type
  )?.[1]

const generateDefaultForField = async (props: {
  field: DataModelField
  column: IntrospectedStructure['tables'][number]['columns'][number]
  dataModel: DataModel
  predictedShape: PredictedShape | null
  fieldShapeExamples: string[]
  fingerprint: Fingerprint[string][string] | null
}) => {
  const { field, column, dataModel, predictedShape, fingerprint } = props

  const matchEnum = findEnumType(dataModel, field)

  if (matchEnum) {
    return `({ seed }) => copycat.oneOf(seed, ${JSON.stringify(
      matchEnum.values.map((v) => v.name)
    )})`
  }

  if (fingerprint && isJsonField(fingerprint)) {
    const result = generateJsonField(fingerprint)
    return `({ seed }) => { return ${result}; }`
  }
  const shape = determineShape(column, predictedShape)
  if (shape && props.fieldShapeExamples.length > 0) {
    if (column.maxLength) {
      return `({ seed }) => copycat.oneOfString(seed, getExamples('${shape}'), { limit: ${JSON.stringify(column.maxLength)} })`
    } else {
      return `({ seed }) => copycat.oneOfString(seed, getExamples('${shape}'))`
    }
  }

  const { generateColumnTransformCode } = await getTransform()
  let code = generateColumnTransformCode(
    'seed',
    column,
    shape,
    SEED_PG_TEMPLATES
  )
  code = await addOptionsToModelDefaultCode(code ?? 'null')
  return `({ seed, options }) => { return ${code} }`
}

const generateDefaultsForModel = async (props: {
  model: DataModelModel
  table: IntrospectedStructure['tables'][number]
  dataModel: DataModel
  shapePredictions: TableShapePredictions | null
  shapeExamples: { shape: string; examples: string[] }[]
  fingerprint: Fingerprint[string] | null
}) => {
  const { fingerprint, model, table, dataModel, shapePredictions } = props

  const fields: { data: UserModels[string]['data'] } = {
    data: {},
  }

  const scalarFields = model.fields.filter(
    (f) => f.kind === 'scalar'
  ) as DataModelScalarField[]

  for (const field of scalarFields) {
    const fieldShapePrediction =
      shapePredictions?.predictions.find(
        (prediction) => prediction.column === field.columnName
      ) ?? null

    const fieldShapeExample =
      props.shapeExamples.find(
        (e) =>
          fieldShapePrediction?.confidence &&
          fieldShapePrediction.confidence >
            SHAPE_PREDICTION_CONFIDENCE_THRESHOLD &&
          e.shape === fieldShapePrediction.shape
      )?.examples ?? []

    const column = table.columns.find(
      (column) => column.name === field.columnName
    )!

    const fieldFingerprint = fingerprint?.[field.name] ?? null

    // If the field is both a sequence and id, its default value must be null
    // so we can overide it with the sequence generator in the plan
    if (field.isId && field.sequence) {
      fields.data![field.name] = null
    } else {
      fields.data![field.name] = await generateDefaultForField({
        field,
        column,
        dataModel,
        predictedShape: fieldShapePrediction,
        fieldShapeExamples: fieldShapeExample,
        fingerprint: fieldFingerprint,
      })
    }
  }
  return fields
}

export const generateDefaultsForModels = async (props: {
  dataModel: DataModel
  introspection: IntrospectedStructure
  shapePredictions: TableShapePredictions[]
  shapeExamples: { shape: string; examples: string[] }[]
  fingerprint: Fingerprint
}) => {
  const { fingerprint, dataModel, introspection, shapePredictions } = props
  const models: UserModels = {}

  for (const [modelName, model] of Object.entries(dataModel.models)) {
    const modelShapePredictions =
      shapePredictions.find(
        (predictions) =>
          model.tableName === predictions.tableName &&
          model.schemaName === predictions.schemaName
      ) ?? null

    const table = introspection.tables.find(
      (t) => t.schema === model.schemaName && t.name === model.tableName
    )!

    const modelFingerprint = fingerprint[modelName] ?? null

    models[modelName] = await generateDefaultsForModel({
      model,
      table,
      dataModel,
      shapePredictions: modelShapePredictions,
      shapeExamples: props.shapeExamples,
      fingerprint: modelFingerprint,
    })
  }

  return models
}

export const generateModelDefaults = async (props: {
  dataModel: DataModel
  introspection: IntrospectedStructure
  shapePredictions: TableShapePredictions[]
  shapeExamples: { shape: string; examples: string[] }[]
  fingerprint: Fingerprint
  isCopycatNext?: boolean
}): Promise<string> => {
  const {
    fingerprint,
    dataModel,
    introspection,
    shapePredictions,
    shapeExamples,
    isCopycatNext,
  } = props

  const defaults = await generateDefaultsForModels({
    dataModel,
    introspection,
    shapePredictions,
    shapeExamples,
    fingerprint,
  })

  const stringifiedDefaults =
    stringify(
      defaults,
      (value, _indent, recur) => {
        if (value === null) {
          return 'null'
        }

        if (typeof value === 'string') {
          return value
        }

        return recur(value)
      },
      '  '
    ) ?? ''
  return `
Object.defineProperty(exports, "__esModule", { value: true })

const { copycat } = require('${
    isCopycatNext ? '@snaplet/copycat/next' : '@snaplet/copycat'
  }')
const shapeExamples = require('./shapeExamples.json')

const getExamples = (shape) => shapeExamples.find((e) => e.shape === shape)?.examples ?? []

exports.modelDefaults = ${stringifiedDefaults}
`
}
