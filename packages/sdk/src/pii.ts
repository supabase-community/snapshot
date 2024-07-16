import { Shape, ShapeContext } from './shapes.js'

import { TableShapePredictions } from './db/structure.js'
import { piiImpact } from './pii/piiImpact.js'
import type { IntrospectedTableColumn } from './db/introspect/introspectDatabase.js'
import { GenerateShapes, ShapeGenerate } from './shapesGenerate.js'

export const SHAPE_PREDICTION_CONFIDENCE_THRESHOLD = 0.65
export const CONTEXT_PREDICTION_CONFIDENCE_THRESHOLD = 0.5
const PII_SHAPE_SET = new Set<Shape | ShapeGenerate>([
  'FULL_NAME',
  'FIRST_NAME',
  'LAST_NAME',
  'DATE_OF_BIRTH',
  'GENDER',
  'STREET_ADDRESS',
  'FULL_ADDRESS',
  'CITY',
  'COUNTRY',
  'STATE',
  'ZIP_CODE',
  'COUNTRY_CODE',
  'LATITUDE',
  'LONGITUDE',
  'TIMEZONE',
  'PHONE',
  'EMAIL',
  'PASSWORD',
  'USERNAME',
  'TOKEN',
  'USER_AGENT',
  'IP_ADDRESS',
  'MAC_ADDRESS',
  'AGE',
  'BANK_ACCOUNT_NUMBER_FULL',
  'BANK_ACCOUNT_NUMBER_LAST4',
  'BANK_ROUTING_FULL',
  'BANK_ROUTING_LAST4',
  'CHECKSUM',
  'CREDIT_DEBIT_NUMBER',
  'CREDIT_DEBIT_EXPIRY',
  'CREDIT_DEBIT_CVV',
  'CURRENCY',
  'DRIVER_ID',
  'HASH',
  'LICENSE_PLATE',
  'META_DATA',
  'NATIONAL_IDENTIFICATION_NUMBER',
  'PIN',
  'SSN_FULL',
  'SSN_LAST4',
  'SWIFT_CODE',
  'LOCATION',
  'TAX_CODE',
  'TAX_AMOUNT',
])

export const isPii = (
  shape: Shape | ShapeGenerate,
  context?: ShapeContext
): boolean => {
  if (!context || context === 'GENERAL') {
    return PII_SHAPE_SET.has(shape!)
  } else {
    let impact = 'LOW'
    if (shape && !(shape in GenerateShapes)) {
      // context(cdw): We make sure that the shape is of type Shape before casting
      impact = piiImpact(context, shape as Shape)
    }
    return impact === 'HIGH' || impact === 'MODERATE'
  }
}

export const determinePredictedShape = (
  column: Pick<IntrospectedTableColumn, 'name' | 'schema' | 'table'>,
  tableShapePredictions?: TableShapePredictions[]
) => {
  if (!tableShapePredictions) {
    return null
  }
  const tableShapePrediction = tableShapePredictions.find(
    (prediction) =>
      prediction.schemaName === column.schema &&
      prediction.tableName === column.table
  )
  const predictedShape = tableShapePrediction?.predictions.find(
    (prediction) => prediction.column === column.name
  )
  return predictedShape?.confidence &&
    predictedShape.confidence > SHAPE_PREDICTION_CONFIDENCE_THRESHOLD
    ? predictedShape
    : null
}
