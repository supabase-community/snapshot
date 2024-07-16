import {
  quicktype,
  InputData,
  jsonInputForTargetLanguage,
  JSONSchemaInput,
  FetchingJSONSchemaStore,
} from 'quicktype-core'
import { DataModel, DataModelModel, groupFields } from './dataModel.js'
import { execQueryNext, withDbClient } from '~/db/client.js'
import { escapeIdentifier } from '~/db/introspect/queries/utils.js'
import { camelize } from 'inflection'
import { PG_DATE_TYPES, PG_NUMBER_TYPES } from '~/pgTypes.js'

type FingerprintJsonField = { schema: Record<string, unknown> }
type FingerprintOptionsField = { options: Record<string, unknown> }
type FingerprintRelationshipField = {
  count: number | { min: number; max: number }
}
type FingerprintField =
  | FingerprintJsonField
  | FingerprintOptionsField
  | FingerprintRelationshipField
export type Fingerprint = Record<string, Record<string, FingerprintField>>

export function isRelationshipField(
  field: FingerprintField
): field is FingerprintRelationshipField {
  return 'count' in field
}

export function isJsonField(
  field: FingerprintField
): field is FingerprintJsonField {
  return 'schema' in field
}

export function isOptionsField(
  field: FingerprintField
): field is FingerprintOptionsField {
  return 'options' in field
}

export async function jsonToJsonSchema(name: string, samples: string[]) {
  const jsonInput = jsonInputForTargetLanguage('json-schema')

  await jsonInput.addSource({
    name,
    samples,
  })

  const inputData = new InputData()
  inputData.addInput(jsonInput)

  const jsonSchema = await quicktype({
    inputData,
    lang: 'json-schema',
    indentation: '  ',
    inferEnums: false,
  })

  return JSON.parse(jsonSchema.lines.join('\n'))
}

export async function jsonSchemaToTypescriptType(
  namespace: string,
  schema: string
) {
  const schemaInput = new JSONSchemaInput(new FetchingJSONSchemaStore())

  await schemaInput.addSource({ name: 'default', schema })

  const inputData = new InputData()
  inputData.addInput(schemaInput)

  const typescriptType = await quicktype({
    inputData,
    lang: 'typescript',
    indentation: '  ',
    rendererOptions: {
      'just-types': true,
    },
  })

  const types = typescriptType.lines.join('\n')

  const standardNamespace = camelize(namespace)

  return {
    name: `${standardNamespace}JsonField.Default`,
    types: `declare namespace ${standardNamespace}JsonField {
  ${types}}`,
  }
}

export async function generateDefaultFingerprint(
  sourceDatabaseUrl: string,
  dataModel: DataModel
) {
  const SAMPLE_SIZE = 50

  const modelNames = Object.keys(dataModel.models)

  const fingerprint: Fingerprint = {}

  for (const modelName of modelNames) {
    const model = dataModel.models[modelName]

    fingerprint[modelName] = {}

    const fields = groupFields(model.fields)
    const relationFields = getRelationFields(model)

    for (const field of fields.scalars) {
      if (field.isId || relationFields.has(field.name)) {
        continue
      }

      const column = escapeIdentifier(field.columnName)

      const table = [model.schemaName, model.tableName]
        .filter(Boolean)
        .map((id) => escapeIdentifier(id!))
        .join('.')

      if (['json', 'jsonb'].includes(field.type)) {
        const samples = await withDbClient(
          (client) =>
            client.query({
              text: `
              SELECT ${column}::text
              FROM ${table}
              WHERE ${column} IS NOT NULL
              ORDER BY random()
              LIMIT ${SAMPLE_SIZE}`,
              rowMode: 'array',
            }),
          { connString: sourceDatabaseUrl }
        )
        if (samples.rows.length > 0) {
          const jsonSchema = await jsonToJsonSchema(
            field.name,
            samples.rows.map(([json]) => json)
          )
          fingerprint[modelName][field.name] = { schema: jsonSchema }
        }
      } else if (PG_NUMBER_TYPES.has(field.type)) {
        const results = await execQueryNext(
          `
          SELECT MIN(${column}) min, MAX(${column}) max
          FROM ${table}
          WHERE ${column} IS NOT NULL
          ORDER BY random()
          LIMIT ${SAMPLE_SIZE}`,
          sourceDatabaseUrl
        )
        if (results.rows.length > 0) {
          const [{ min, max }] = results.rows
          const options: Record<string, unknown> = {}

          if (min != null) {
            options.min = +min
          }

          if (max != null) {
            options.max = +max
          }

          fingerprint[modelName][field.name] = {
            options,
          }
        }
      } else if (PG_DATE_TYPES.has(field.type)) {
        const results = await execQueryNext(
          `
          SELECT MIN(DATE_PART('year', ${column}::date)) "minYear", MAX(DATE_PART('year', ${column}::date)) "maxYear"
          FROM ${table}
          WHERE ${column} IS NOT NULL
          ORDER BY random()
          LIMIT ${SAMPLE_SIZE}`,
          sourceDatabaseUrl
        )
        if (results.rows.length > 0) {
          const [{ minYear, maxYear }] = results.rows
          const options: Record<string, unknown> = {}

          if (minYear != null) {
            options.minYear = +minYear
          }

          if (maxYear != null) {
            options.maxYear = +maxYear
          }

          fingerprint[modelName][field.name] = {
            options,
          }
        }
      }
    }

    // for (const field of fields.parents) {
    //   // get statistics about the relationship, account for nullable parent, so the count can be { min: 0, max: 1 }
    // }

    // for (const field of fields.children) {
    //   // get statistics about the relationship, for example count = { min: 3, max: 10 }
    // }
  }

  return fingerprint
}

const getRelationFields = (model: DataModelModel): Set<string> => {
  const relationFields = new Set<string>()

  for (const field of model.fields) {
    if (field.kind === 'object') {
      for (const fieldName of field.relationFromFields) {
        relationFields.add(fieldName)
      }
    }
  }

  return relationFields
}
