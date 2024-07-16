import { Shape } from '../../shapes.js'
import * as generateOrm from '../../generateOrm/index.js'
import type { TableShapePredictions } from '../../db/structure.js'
import { generateModelDefaults } from './generateModelDefaults.js'
import {
  fakeColumnStructure,
  fakeDbStructure,
  fakeTableStructure,
} from '../../testing/fakes.js'
import { allExamples as shapeExamples } from '../fixtures/shapeExamples.js'
import { ShapeGenerate } from '~/shapesGenerate.js'

const fakeFieldShape = (
  field: generateOrm.DataModelField
): Shape | ShapeGenerate | undefined => {
  if (field.name.toLowerCase().includes('email')) {
    return 'EMAIL'
  }

  if (field.name.toLowerCase().includes('name')) {
    return 'FULL_NAME'
  }
  if (field.name.toLowerCase().includes('favourite_colour')) {
    return 'INTERNET_COLOR'
  }
}

const fakeShapePredictions = (
  dataModel: generateOrm.DataModel
): TableShapePredictions[] => {
  const predictions: TableShapePredictions[] = []
  const models = Object.values(dataModel.models)
  for (const model of models) {
    predictions.push({
      // TODO: make prediction work without schema
      schemaName: model.schemaName!,
      tableName: model.tableName,
      predictions: model.fields
        .filter((f) => f.kind === 'scalar')
        .map((f) => ({
          input: `${model.schemaName} ${model.tableName} ${f.name} ${f.type}`,
          column: f.name,
          shape: fakeFieldShape(f),
          confidence: 0.7,
          context: undefined,
          confidenceContext: 0.5,
        })),
    })
  }

  return predictions
}

describe('generateModelDefaults', () => {
  test('it should generate fake data for each column', async () => {
    const dataModel: generateOrm.DataModel = {
      enums: {},
      models: {
        test_customer: {
          uniqueConstraints: [],
          id: 'public.test_customer',
          tableName: 'test_customer',
          schemaName: 'public',
          fields: [
            {
              isId: true,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.name',
              name: 'name',
              columnName: 'name',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.email',
              name: 'email',
              columnName: 'email',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.confirmed_at',
              name: 'confirmed_at',
              columnName: 'confirmed_at',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.favourite_colour',
              name: 'favourite_colour',
              columnName: 'favourite_colour',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
      },
    }

    const structure = fakeDbStructure({
      tables: [
        fakeTableStructure({
          columns: [
            {
              name: 'id',
              type: 'text',
            },
            {
              name: 'name',
              type: 'text',
            },
            {
              name: 'email',
              type: 'text',
            },
            {
              name: 'confirmed_at',
              type: 'text',
            },
            {
              name: 'favourite_colour',
              type: 'text',
            },
          ].map(fakeColumnStructure),
        }),
      ],
    })

    const predictions = fakeShapePredictions(dataModel)

    expect(
      await generateModelDefaults({
        dataModel,
        introspection: structure,
        shapePredictions: predictions,
        shapeExamples,
        fingerprint: {},
      })
    ).toMatchInlineSnapshot(
      `
      "
      Object.defineProperty(exports, \\"__esModule\\", { value: true })

      const { copycat } = require('@snaplet/copycat')
      const shapeExamples = require('./shapeExamples.json')

      const getExamples = (shape) => shapeExamples.find((e) => e.shape === shape)?.examples ?? []

      exports.modelDefaults = {
        test_customer: {
          data: {
            id: ({ seed, options }) => { return copycat.uuid(seed, options); },
            name: ({ seed, options }) => { return copycat.fullName(seed, options); },
            email: ({ seed, options }) => { return copycat.email(seed, options); },
            confirmed_at: ({ seed, options }) => { return copycat.sentence(seed, options); },
            favourite_colour: ({ seed }) => copycat.oneOfString(seed, getExamples('INTERNET_COLOR'))
          }
        }
      }
      "
    `
    )
  })

  test('it allows using @snaplet/copycat/next', async () => {
    const dataModel: generateOrm.DataModel = {
      enums: {},
      models: {},
    }

    const structure = fakeDbStructure({
      tables: [],
    })

    const predictions = fakeShapePredictions(dataModel)

    const result1 = await generateModelDefaults({
      dataModel,
      introspection: structure,
      shapePredictions: predictions,
      shapeExamples,
      fingerprint: {},
    })

    const result2 = await generateModelDefaults({
      dataModel,
      introspection: structure,
      shapePredictions: predictions,
      shapeExamples,
      fingerprint: {},
      isCopycatNext: true,
    })

    expect(result1).toContain("'@snaplet/copycat'")
    expect(result1).not.toContain("'@snaplet/copycat/next'")

    expect(result2).not.toContain("'@snaplet/copycat'")
    expect(result2).to.toContain("'@snaplet/copycat/next'")
  })
})
