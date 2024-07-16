import { copycat, faker } from '@snaplet/copycat'
import vm from 'vm'

import { Shape } from '~/shapes.js'
import { createTestDb, fakeColumnStructure } from '~/testing/index.js'
import { JsTypeName } from '~/pgTypes.js'

import { execQueryNext, withDbClient } from '~/db/client.js'
import { introspectDatabaseV3 } from '~/db/introspect/introspectDatabase.js'
import {
  DataModel,
  introspectionToDataModel,
} from '~/generateOrm/dataModel/dataModel.js'
import { TemplateContext, TemplateFn } from './types.js'

interface TestGenerateColumnOptions {
  schemaName?: string
  tableName?: string
  columnName?: string
  columnValue?: string
}

interface TestGenerateColumnResult {
  kind: 'empty' | 'success' | 'failure'
  value: unknown
}

export const evaluateGenerateColumn = (
  generateFn: TemplateFn,
  jsType: JsTypeName,
  shape: Shape,
  options: TestGenerateColumnOptions = {}
): TestGenerateColumnResult => {
  const {
    schemaName = 'schema1',
    tableName = 'table1',
    columnName = 'column1',
    columnValue = 'columnValue',
  } = options

  const column = fakeColumnStructure({
    name: columnName,
    schema: schemaName,
    table: tableName,
    type: 'text',
    nullable: true,
    generated: 'NEVER' as const,
    default: '',
    maxLength: 50,
    constraints: [],
  })

  const api: TemplateContext = {
    field: {
      ...column,
      maxLength: column.maxLength === null ? undefined : column.maxLength,
    },
    shape,
    jsType,
    input: 'input',
  }

  const code = generateFn(api)

  if (code === null) {
    return {
      kind: 'empty' as const,
      value: null,
    }
  }

  let kind: TestGenerateColumnResult['kind'] = 'success' as const
  let value
  faker.seed(23)

  try {
    value = vm.runInNewContext(code, {
      copycat,
      faker,
      input: columnValue,
      Date,
    })
  } catch (error) {
    kind = 'failure'
    value = error
  }

  return {
    kind,
    value,
  }
}

export const createDataModelFromSql = async (
  sql: string
): Promise<DataModel> => {
  const connString = (await createTestDb()).toString()
  await execQueryNext(sql, connString)
  const introspection = await withDbClient(introspectDatabaseV3, { connString })
  return introspectionToDataModel(introspection)
}
