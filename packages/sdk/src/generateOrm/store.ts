import {
  DataModel,
  DataModelModel,
  DataModelScalarField,
} from './dataModel/dataModel.js'
import { ident, literal, format } from '@scaleleap/pg-format'
import { serializeToSQL } from './sql.js'
import { Json } from '~/types.js'
import TopologicalSort from 'topological-sort'
import {
  escapeIdentifier,
  escapeLiteral,
} from '~/db/introspect/queries/utils.js'
import { isError } from '~/errors.js'

type MissingPKForUpdateError = {
  modelName: string
  type: 'missingPKForUpdateError'
}
type ToSQLErrors = MissingPKForUpdateError

function logToSqlErrors(errors: ToSQLErrors[]) {
  if (errors.length === 0) {
    return
  }
  const missingPKForUpdateErrorsMap = new Map<string, number>()
  for (const error of errors) {
    // Set a unique map per model with the number of affected rows
    if (error.type === 'missingPKForUpdateError') {
      missingPKForUpdateErrorsMap.set(
        error.modelName,
        (missingPKForUpdateErrorsMap.get(error.modelName) ?? 1) + 1
      )
    }
  }
  for (const [modelName, affectedRows] of missingPKForUpdateErrorsMap) {
    console.log(
      `Warning: skipping UPDATE on model ${modelName} for ${affectedRows} rows as it has no id fields (no PRIMARY KEYS or UNIQUE NON NULL columns found)`
    )
  }
}

export class Store {
  public readonly dataModel: DataModel
  _store: Record<string, Array<any>>

  constructor(dataModel: DataModel) {
    this.dataModel = dataModel
    this._store = Object.fromEntries(
      Object.keys(dataModel.models).map((modelName) => [modelName, []])
    )
  }

  add(model: string, value: any) {
    this._store[model].push(value)
  }

  private isNullableParent(model: string, fieldName: string) {
    const field = this.dataModel.models[model].fields.find(
      (f) => f.name === fieldName
    )!
    return (
      !field.isRequired &&
      this.dataModel.models[model].fields.some(
        (f) => f.kind === 'object' && f.relationFromFields.includes(fieldName)
      )
    )
  }

  // TODO: memoize
  private getIdFieldNames(model: DataModelModel & { modelName: string }) {
    return this.dataModel.models[model.modelName].fields
      .filter((f) => f.kind === 'scalar' && f.isId)
      .map((f) => f.name)
  }

  toSQL(): string[] {
    const SQL_DEFAULT_SYMBOL = '$$DEFAULT$$'

    const sortedModels = [...topologicalSort(this.dataModel).values()].reverse()
    // we need to maintain an update map to store the ids of nullable parents
    // we will use this map to create the links between the parent and the child once all the models have been inserted
    const insertStatements: string[] = []
    const updateStatements: string[] = []
    const sequenceFixerStatements: string[] = []
    const errorsData: Array<ToSQLErrors> = []

    for (const entry of sortedModels) {
      const model: DataModelModel & { modelName: string } = entry.node
      const idFieldNames = this.getIdFieldNames(model)
      const rows = this._store[model.modelName]

      if (!rows?.length) {
        continue
      }

      // todo(justinvdm, 27 July 2023): Cache this
      const fieldMap = new Map(
        model.fields
          .filter((f) => f.kind === 'scalar' && !(f.isGenerated && !f.isId))
          .map((f) => [f.name, f as DataModelScalarField])
      )
      const fieldToColumnMap = new Map(
        Array.from(fieldMap.values()).map((f) => [f.name, f.columnName])
      )
      const sequenceFields = model.fields.filter((f) => f.sequence)
      // If we inserted new rows with sequences, we need to update the database sequence value to the max value of the inserted rows
      for (const sequenceField of sequenceFields) {
        const tableName = model.tableName
        const schemaName = model.schemaName
        const fieldColumn = fieldToColumnMap.get(sequenceField.name)
        if (
          fieldColumn &&
          sequenceField.sequence &&
          schemaName &&
          tableName &&
          sequenceField.sequence &&
          sequenceField.sequence.identifier
        ) {
          const sequenceIdentifier = sequenceField.sequence.identifier
          const sequenceFixerStatement = `SELECT setval(${escapeLiteral(
            sequenceIdentifier
          )}::regclass, (SELECT MAX(${escapeIdentifier(
            fieldColumn
          )}) FROM ${escapeIdentifier(schemaName)}.${escapeIdentifier(
            tableName
          )}))`
          sequenceFixerStatements.push(sequenceFixerStatement)
        }
      }
      const insertRowsValues: any[][] = []
      for (const row of rows) {
        const insertRowValues: any[] = []
        let updateRow:
          | { filter: Record<string, any>; values: Record<string, any> }
          | undefined

        for (const fieldName of fieldMap.keys()) {
          const field = fieldMap.get(fieldName)!

          const value = row[fieldName]

          if (value === undefined && field.hasDefaultValue) {
            // we use this weird syntax to replace the value in the final sql statements
            insertRowValues.push(SQL_DEFAULT_SYMBOL)
            continue
          }

          // We check if the column is part of a nullable parent relation
          const isNullableParent = this.isNullableParent(
            model.modelName,
            fieldName
          )
          // If it is, and the value is not null, we store the id of the parent in the update map
          if (isNullableParent && value !== null) {
            if (idFieldNames.length > 0) {
              if (!updateRow) {
                updateRow = {
                  filter: idFieldNames.reduce(
                    (acc, idFieldName) => ({
                      ...acc,
                      [idFieldName]: serializeToSQL(
                        fieldMap.get(idFieldName)!.type,
                        row[idFieldName]
                      ),
                    }),
                    {}
                  ),
                  values: {},
                }
              }
              updateRow.values[fieldName] = serializeToSQL(
                fieldMap.get(fieldName)!.type,
                value as Json
              )
            } else {
              errorsData.push({
                modelName: model.modelName,
                type: 'missingPKForUpdateError',
              })
            }
          }
          insertRowValues.push(
            serializeToSQL(
              fieldMap.get(fieldName)!.type,
              // if the field is a nullable parent, we defer the insert of its parent id for later to avoid fk constraint errors
              isNullableParent ? null : (value as Json)
            )
          )
        }
        if (updateRow) {
          const updateStatement = [
            `UPDATE ${ident(model.schemaName!)}.${ident(model.tableName)}`,
            `SET ${Object.entries(updateRow.values)
              .map(
                ([c, v]) => `${ident(fieldToColumnMap.get(c))} = ${literal(v)}`
              )
              .join(', ')}`,
            `WHERE ${Object.entries(updateRow.filter)
              .map(
                ([c, v]) => `${ident(fieldToColumnMap.get(c))} = ${literal(v)}`
              )
              .join(' AND ')}`,
          ].join(' ')
          updateStatements.push(updateStatement)
        }
        insertRowsValues.push(insertRowValues)
      }

      const isGeneratedId =
        model.fields.filter((f) => f.isGenerated && f.isId).length > 0

      const insertStatementTemplate = [
        'INSERT INTO %I.%I (%I)',
        isGeneratedId ? 'OVERRIDING SYSTEM VALUE' : undefined,
        'VALUES %L',
      ]
        .filter((s) => Boolean(s))
        .join(' ')

      const insertStatement = format(
        insertStatementTemplate,
        model.schemaName,
        model.tableName,
        Array.from(fieldToColumnMap.values()),
        insertRowsValues
      )
        // We patch the "DEFAULT" values as it's a reserved keyword and we don't want to escape it
        .replaceAll(`'${SQL_DEFAULT_SYMBOL}'`, 'DEFAULT')
      insertStatements.push(insertStatement)
    }
    logToSqlErrors(errorsData)
    return [
      ...insertStatements,
      ...updateStatements,
      ...sequenceFixerStatements,
    ]
  }
}

function topologicalSort(dataModel: DataModel) {
  const nodes = new Map()
  const models = Object.entries(dataModel.models).map(([modelName, model]) => ({
    ...model,
    modelName,
  }))
  for (const model of models) {
    nodes.set(model.modelName, model)
  }
  const sortOp = new TopologicalSort(nodes)
  for (const model of models) {
    const parents = model.fields.filter(
      (f) => f.kind === 'object' && f.relationFromFields.length > 0
    )
    for (const parent of parents) {
      if (parent.isRequired) {
        try {
          sortOp.addEdge(model.modelName, parent.type)
        } catch (e) {
          const isDoubleEdgeError =
            isError(e) &&
            e.message.includes('already has an adge to target node')
          if (!isDoubleEdgeError) {
            throw e
          }
        }
      }
    }
  }
  return sortOp.sort()
}
