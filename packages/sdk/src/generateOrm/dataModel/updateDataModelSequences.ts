import { mapValues } from 'lodash'
import {
  DataModel,
  DataModelField,
  DataModelModel,
  DataModelScalarField,
} from './dataModel.js'

const isScalarField = (field: DataModelField): field is DataModelScalarField =>
  field.kind === 'scalar'

const createModelEntry = (model: DataModelModel): [string, DataModelModel] => [
  model.id,
  model,
]

// context(justinvdm, 24 Jan 2024): We use column name as key instead of model name so that we don't need to
// read snaplet config to apply model aliases to data model
const createScalarFieldEntry = (
  field: DataModelScalarField
): [string, DataModelScalarField] => [field.id, field]

export const updateDataModelSequences = (
  currentDataModel: DataModel,
  nextDataModel: DataModel
): DataModel => {
  const nextModelMap = new Map<string, DataModelModel>(
    Object.values(nextDataModel.models).map(createModelEntry)
  )

  return {
    ...currentDataModel,
    models: mapValues(currentDataModel.models, (model) => {
      const nextModel = nextModelMap.get(model.id)

      if (!nextModel) {
        return model
      }

      const nextFieldMap = new Map<string, DataModelScalarField>(
        nextModel.fields.filter(isScalarField).map(createScalarFieldEntry)
      )

      return {
        ...model,
        fields: model.fields.map((field) => {
          if (field.kind !== 'scalar') {
            return field
          }

          const nextField = nextFieldMap.get(field.id)

          if (!nextField) {
            return field
          }

          return {
            ...field,
            sequence: nextField.sequence,
          }
        }),
      }
    }),
  }
}
