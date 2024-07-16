import { copycat } from '@snaplet/copycat'
import { sortBy, intersection, clone } from 'lodash'
import { EOL } from 'os'
import {
  DataModel,
  DataModelObjectField,
  DataModelScalarField,
  DataModelUniqueConstraint,
  isParentField,
} from './dataModel/dataModel.js'
import {
  ModelRecord,
  UserModels,
  ScalarField,
  GenerateCallback,
  Store,
  GenerateCallbackContext,
} from './index.js'
import { serializeValue } from './plan/serialize.js'

export function getInitialConstraints(dataModel: DataModel) {
  return Object.fromEntries(
    Object.entries(dataModel.models)
      .filter(([_, model]) => model.uniqueConstraints.length > 0)
      .map(([modelName, model]) => [
        modelName,
        Object.fromEntries(
          model.uniqueConstraints.map((constraint) => [
            constraint.name,
            new Set<string>(),
          ])
        ),
      ])
  )
}

export type Constraints = ReturnType<typeof getInitialConstraints>

/**
 * Shared context between checkConstraints and cartesianProduct
 */
type Context = {
  modelSeed: string
  inputsData: ModelRecord
  userModels: UserModels
  model: string
  connectStore?: Store['_store']
  modelData: Record<string, any>
  generateFnCtx: (fieldName: string, counter: number) => GenerateCallbackContext
}

export async function checkConstraints(
  props: {
    uniqueConstraints: Array<DataModelUniqueConstraint>
    parentFields: Array<DataModelObjectField>
    scalarFields: Array<DataModelScalarField>
    constraintsStores: Constraints
  } & Context
) {
  /**
   * We keep track of the fields that were already processed by previous constraints
   * because we can't retry them, they're closed for modifications
   */
  const processedFields: Array<string> = []

  /**
   * We exclude constraints containing fields that have a default value
   * We can't know the value of this field before inserting the data so we can't build a hash for the constraint
   */
  const filteredConstraints = props.uniqueConstraints.filter((c) => {
    return !c.columns.some((column) => {
      const field = props.scalarFields.find((f) => f.name === column)!
      return (
        !field.isId &&
        field.hasDefaultValue &&
        field.sequence === false &&
        props.inputsData[field.name] === undefined
      )
    })
  })

  /**
   * We sort the constraints by the number of columns they impact from the smallest to the largest
   * So smallest constraints are prioritized and their fields are closed for modifications for the next constraints
   */
  const sortedConstraints = sortBy(filteredConstraints, (c) => c.columns.length)
  for (const constraint of sortedConstraints) {
    // We skip the constraint if it contains null values
    // todo: handle "nulls not distinct" in the future when we support it
    if (constraint.columns.some((c) => props.modelData[c] === null)) {
      continue
    }

    const hash = getHash(constraint.columns.map((c) => props.modelData[c]))
    const constraintStore =
      props.constraintsStores[props.model][constraint.name]

    // constraint is violated, we try to fix it
    if (constraintStore.has(hash)) {
      // We keep track of the parent fields relations columns so if they're part of the primary key
      // we can distinguish them from the scalar fields
      const parentsFieldsColumns: string[] = []
      // We can only retry parent relation fields with a fallback connect function
      const parentFieldsToRetry = props.parentFields.filter((p) => {
        if (
          intersection(p.relationFromFields, constraint.columns).length > 0 &&
          intersection(p.relationFromFields, processedFields).length === 0 &&
          props.inputsData[p.name] === undefined &&
          // @ts-expect-error check if the connect function is tagged as fallback
          props.userModels[p.type].connect?.['fallback']
        ) {
          parentsFieldsColumns.push(...p.relationFromFields)
          return true
        }
        return false
      })
      const parentFieldsColumnsSet = new Set(parentsFieldsColumns)
      // We can only retry scalar fields with generateFn function
      const scalarFieldsToRetry = props.scalarFields.filter((f) => {
        const scalarField = props.inputsData[f.name] as ScalarField
        const generateFn =
          scalarField === undefined
            ? props.userModels[props.model].data?.[f.name]
            : scalarField

        return (
          parentFieldsColumnsSet.has(f.name) === false &&
          constraint.columns.includes(f.name) &&
          !processedFields.includes(f.name) &&
          typeof generateFn === 'function'
        )
      })

      processedFields.push(...constraint.columns)

      const getConstraintData = () =>
        constraint.columns.reduce(
          (acc, c) => {
            acc[c] = props.modelData[c]
            return acc
          },
          {} as Record<string, any>
        )
      let constraintData = getConstraintData()
      const connectStores = parentFieldsToRetry
        .map((f) => f.type)
        .reduce(
          (acc, type) => {
            acc[type] = props.connectStore![type]
            return acc
          },
          {} as Record<string, Array<any>>
        )
      // we want to attempt every combination of connections first
      let conflictFixed = await cartesianProduct({
        connectStores,
        fields: parentFieldsToRetry,
        level: 0,
        constraintData,
        constraint,
        constraintStore,
        ...props,
      })

      // if we couldn't fix the constraint with parent fields, we try with scalar fields if there is something to try
      if (!conflictFixed && scalarFieldsToRetry.length > 0) {
        // we reset the constraint data
        constraintData = getConstraintData()
        // we now try every combination of connections and scalar fields
        conflictFixed = await cartesianProduct({
          connectStores,
          fields: [...parentFieldsToRetry, ...scalarFieldsToRetry],
          level: 0,
          constraintData,
          constraint,
          constraintStore,
          ...props,
        })
      }

      if (!conflictFixed) {
        const values = constraint.columns.map((c) => props.modelData[c])
        throw new Error(
          [
            `Unique constraint "${constraint.name}" violated for model "${props.model}" on fields (${constraint.columns.join(',')}) with values (${values.join(',')})`,
            `Seed: ${props.modelSeed}`,
            `Model data: ${JSON.stringify(props.modelData, null, 2)}`,
          ].join(EOL)
        )
      }

      // at this point the constraint is fixed, yay!
      for (const column of constraint.columns) {
        props.modelData[column] = constraintData[column]
      }
      const hash = getHash(constraint.columns.map((c) => constraintData[c]))
      constraintStore.add(hash)
    } else {
      constraintStore.add(hash)
    }
  }
}

function getHash(values: Array<any>) {
  return values.join(':')
}

/**
 * This function attempts to fix a constraint violation by trying every combination of values between the `fields`
 * It mutates the `constraintData` object with the values that fixed the constraint
 */
async function cartesianProduct(
  props: {
    connectStores: Record<string, Array<any>>
    fields: Array<DataModelObjectField | DataModelScalarField>
    level: number
    constraintData: Record<string, any>
    constraintStore: Set<string>
    constraint: DataModelUniqueConstraint
  } & Context
): Promise<boolean> {
  if (props.level === props.fields.length) {
    return false
  }

  const field = props.fields[props.level]

  // props.fields could be empty if all fields were already processed
  if (field === undefined) {
    return false
  }

  const SCALAR_MAX_ATTEMPTS = 50
  let iterations = SCALAR_MAX_ATTEMPTS

  if (isParentField(field)) {
    iterations = props.connectStore![field.type].length
  }

  // each level (field) works with its own copy of the connectStores
  const connectStores = clone(props.connectStores)

  for (let i = 0; i < iterations; i++) {
    if (isParentField(field)) {
      // process parent field
      const connectStore = connectStores[field.type]

      if (connectStore.length === 0) {
        return false
      }
      const candidate = copycat.oneOf(
        `${props.modelSeed}/${field.name}`,
        connectStore
      ) as Record<string, any>

      for (const [i] of field.relationFromFields.entries()) {
        props.constraintData[field.relationFromFields[i]] =
          candidate[field.relationToFields[i]]
      }

      const hash = getHash(
        props.constraint.columns.map((c) => props.constraintData[c])
      )

      if (!props.constraintStore.has(hash)) {
        return true
      }

      // remove the candidate from the connect stores
      connectStores[field.type] = connectStore.filter(
        (p) => !field.relationToFields.every((f) => p[f] === candidate[f])
      )
    } else {
      // process scalar field
      const scalarField = props.inputsData[field.name] as ScalarField
      const generateFn = (
        scalarField === undefined
          ? props.userModels[props.model].data?.[field.name]
          : scalarField
      ) as GenerateCallback

      props.constraintData[field.name] = serializeValue(
        await generateFn(props.generateFnCtx(field.name, i))
      )

      const hash = getHash(
        props.constraint.columns.map((c) => props.constraintData[c])
      )

      if (!props.constraintStore.has(hash)) {
        return true
      }
    }

    const constraintFixed = await cartesianProduct({
      ...props,
      level: props.level + 1,
    })

    if (constraintFixed) {
      return true
    }
  }

  return false
}
