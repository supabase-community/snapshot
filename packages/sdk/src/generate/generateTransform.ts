import type { TemplateBuilderOptions } from '@babel/template'
import type * as t from '@babel/types'
import { memoize } from 'lodash'
import { randomBytes } from 'crypto'

import { TransformFallbackMode } from '~/transform.js'
import type {
  IntrospectedStructure,
  IntrospectedTableColumn,
} from '../db/introspect/introspectDatabase.js'
import type {
  SubsetConfigV2,
  SelectConfig,
} from '../config/snapletConfig/v2/getConfig/parseConfig.js'
import { TableShapePredictions } from '../db/structure.js'
import { determinePredictedShape, isPii } from '../pii.js'
import { findShape, Shape } from '../shapes.js'
import { JsTypeName, PgTypeName, PG_TO_JS_TYPES } from '../pgTypes.js'
import { generateTypedefInclusion } from '~/config/snapletConfig/v2/generateTypes/generateTypes.js'
import { importAstBabelDeps } from '~/config/snapletConfig/v2/ast/babelDepsLoader.js'
import { getPgTypeArrayDimensions } from '../pgTypes.js'
import { extractPrimitivePgType } from '../pgTypes.js'
import { ShapeGenerate } from '~/shapesGenerate.js'
import { TRANSFORM_CONFIG_EXAMPLE_TEMPLATES } from '~/templates/sets/transformConfigExamples.js'
import {
  TemplateContext,
  TemplateInputNode,
  TemplateResult,
  Templates,
} from '~/templates/types.js'

export interface DbSchemaStructure {
  name: string
  tables: IntrospectedStructure['tables']
}

export interface DbTableStructure {
  name: string
  columns: IntrospectedTableColumn[]
}
interface GenerateTransformContext {
  includeEmpty: boolean
  includePiiOnly: boolean
  templates: CompiledGenerateTransformTemplates
  transformMode?: TransformFallbackMode
  tableShapePredictions?: TableShapePredictions[]
}

export interface GenerateTransformOptions {
  includeEmpty?: boolean
  includePiiOnly?: boolean
  templates?: GenerateTransformTemplates
  transformMode?: TransformFallbackMode
  tableShapePredictions?: TableShapePredictions[]
  copycatSecretKey?: string | null
  generateSections?: Array<'select' | 'transform' | 'subset'>
}

export interface GenerateTransformTemplates {
  file?: string
  input?: string
  config?: string
  tableTransform?: string
}
interface CompiledGenerateTransformTemplates {
  input: (params: { column: string | t.Node }) => t.Expression
  tableTransform: (params: { body: t.Node }) => t.Expression
}

export type GenerateTransformModule = Awaited<ReturnType<typeof _getTransform>>

async function _getTransform() {
  // Because of the way we compile for pkg, we need those checks on default, babel v8 will fix that
  // Issue: https://github.com/babel/babel/issues/15269
  const deps = await importAstBabelDeps(['generate', 'template', 'types'])
  const { generate, template, types: t } = deps

  const baseTemplateOptions: TemplateBuilderOptions = {
    preserveComments: true,
    plugins: ['typescript'],
  }

  const applyColumnTransformTemplate = (
    api: TemplateContext,
    templates: Templates
  ): TemplateResult => {
    const shapeTemplates = templates[extractPrimitivePgType(api.field.type)]

    if (!shapeTemplates) {
      return null
    }

    if (typeof shapeTemplates === 'function') {
      const templateResult = shapeTemplates(api)
      if (templateResult !== null) {
        return encloseValueInArray(api.field.type, templateResult)
      }
      return templateResult
    }

    let fn

    if (api.shape == null) {
      fn = shapeTemplates.__DEFAULT ?? null
    } else {
      fn = shapeTemplates?.[api.shape] ?? shapeTemplates.__DEFAULT ?? null
    }
    const templateResult = fn?.(api) ?? null
    if (templateResult !== null) {
      return encloseValueInArray(api.field.type, templateResult)
    }
    return templateResult
  }

  const createTemplateContext = (
    input: TemplateInputNode,
    field: { type: string; name: string },
    shape: Shape | ShapeGenerate | null,
    jsType: JsTypeName
  ): TemplateContext => {
    return {
      field,
      shape,
      jsType,
      input: typeof input !== 'string' ? generate(input).code : input,
    }
  }

  const generateColumnTransformCode = (
    input: TemplateInputNode,
    column: { type: string; name: string },
    shape: Shape | ShapeGenerate | null,
    templates: Templates<PgTypeName> = TRANSFORM_CONFIG_EXAMPLE_TEMPLATES
  ) => {
    const jsType = PG_TO_JS_TYPES[extractPrimitivePgType(column.type)]

    if (!jsType) {
      return null
    }

    const api = createTemplateContext(input, column, shape, jsType)
    const columnTemplateResult = applyColumnTransformTemplate(api, templates)

    return columnTemplateResult
  }

  const DEFAULT_TEMPLATES = {
    input: `row.%%column%%`,

    tableTransform: `function ({ row }) { return %%body%% }`,
  }

  const objectLiteral = (
    entries: [string, t.Expression | t.PatternLike | null][]
  ) =>
    t.objectExpression(
      entries
        .filter(([, node]) => node !== null)
        .map(([key, node]) =>
          node?.type === 'FunctionExpression'
            ? t.objectMethod(
                'method',
                t.stringLiteral(key),
                node.params,
                node.body as t.BlockStatement,
                false,
                node.generator,
                node.async
              )
            : t.objectProperty(t.identifier(key), node as t.Expression)
        )
    )

  const computeColumnAst = (
    column: IntrospectedTableColumn,
    context: GenerateTransformContext
  ) => {
    const jsType = PG_TO_JS_TYPES[column.type as PgTypeName]

    if (!jsType) {
      return null
    }

    const predictedShape = determinePredictedShape(
      column,
      context.tableShapePredictions
    )
    const shape =
      predictedShape?.shape ?? findShape(column.name, jsType)?.shape ?? null
    const shapeContext = predictedShape?.context ?? 'GENERAL'

    if (shape && (!context.includePiiOnly || isPii(shape, shapeContext))) {
      const code = generateColumnTransformCode(
        context.templates.input({ column: column.name }),
        column,
        shape
      )

      return code !== null
        ? template.expression.ast(code, baseTemplateOptions)
        : null
    }

    return null
  }

  const computeTableAst = (
    table: DbTableStructure,
    context: GenerateTransformContext
  ) => {
    const body = objectLiteral(
      table.columns
        // If a column is generated ALWAYS, it's a computed column it won't have any data in the snapshot
        .filter((c) => c.generated !== 'ALWAYS')
        .map((column) => [column.name, computeColumnAst(column, context)])
    )

    return body.properties.length || context.includeEmpty
      ? context.templates.tableTransform({ body })
      : null
  }

  const computeSchemaAst = (
    schema: DbSchemaStructure,
    context: GenerateTransformContext
  ) => {
    const result = objectLiteral(
      schema.tables.map((table) => [
        table.name,
        computeTableAst(table, context),
      ])
    )

    return result.properties.length || context.includeEmpty ? result : null
  }

  const computeNestedSchemaStructure = (
    tables: IntrospectedStructure['tables']
  ): DbSchemaStructure[] => {
    const schemas: { [name: string]: DbSchemaStructure } = {}

    for (const table of tables) {
      const schema = (schemas[table.schema] = schemas[table.schema] || {
        name: table.schema,
        tables: [],
      })

      schema.tables.push(table)
    }

    return Object.values(schemas)
  }

  const generateImportStatements = (imports: Record<string, string[]>) => {
    const statements = []

    for (const [module, names] of Object.entries(imports)) {
      statements.push(
        t.importDeclaration(
          names.map((name) =>
            t.importSpecifier(t.identifier(name), t.identifier(name))
          ),
          t.stringLiteral(module)
        )
      )
    }
    return statements
  }

  const createAstNodeForValue = (
    value: unknown
  ):
    | t.BooleanLiteral
    | t.StringLiteral
    | t.NumericLiteral
    | t.ArrayExpression
    | t.ObjectExpression => {
    if (typeof value === 'string') {
      return t.stringLiteral(value)
    } else if (typeof value === 'number') {
      return t.numericLiteral(value)
    } else if (typeof value === 'boolean') {
      return t.booleanLiteral(value)
    } else if (Array.isArray(value)) {
      return t.arrayExpression(value.map(createAstNodeForValue))
    } else if (typeof value === 'object' && value !== null) {
      return t.objectExpression(
        Object.entries(value).map(([key, val]: [string, unknown]) =>
          t.objectProperty(t.identifier(key), createAstNodeForValue(val))
        )
      )
    } else {
      throw new Error(
        `Cannot create AST node for value of type ${typeof value}`
      )
    }
  }

  const generateSubsetStatements = (subsetConfig?: SubsetConfigV2) => {
    const statements = []
    if (subsetConfig) {
      statements.push(
        t.objectProperty(
          t.identifier('subset'),
          t.objectExpression(
            Object.entries(subsetConfig).map(([key, value]) => {
              return t.objectProperty(
                t.identifier(key),
                createAstNodeForValue(value)
              )
            })
          )
        )
      )
    }
    return statements
  }

  const generateSelectStatements = (selectConfig: SelectConfig) => {
    return t.objectExpression(
      Object.entries(selectConfig).map(([key, value]) => {
        return t.objectProperty(
          t.identifier(key),
          // Level one of the structure is $default or schema name
          typeof value === 'boolean' || typeof value === 'string'
            ? value === 'structure'
              ? t.stringLiteral(value)
              : t.booleanLiteral(value)
            : // Level two of the structure { schemaName: { $default, tableName: string, $extensions: {} | boolean } }
              t.objectExpression(
                Object.entries(value).map(([key, value]) => {
                  return t.objectProperty(
                    t.identifier(key),
                    typeof value === 'boolean' || typeof value === 'string'
                      ? value === 'structure'
                        ? t.stringLiteral(value)
                        : t.booleanLiteral(value)
                      : // Level three of the structure { $extensions: boolean | { extensionName: boolean } }
                        t.objectExpression(
                          Object.entries(value).map(([key, value]) => {
                            return t.objectProperty(
                              t.identifier(key),
                              typeof value === 'boolean'
                                ? t.booleanLiteral(value)
                                : // Level four of the structure { extensionName: boolean }
                                  t.objectExpression(
                                    Object.entries(value).map(
                                      ([key, value]) => {
                                        return t.objectProperty(
                                          t.identifier(key),
                                          t.booleanLiteral(value)
                                        )
                                      }
                                    )
                                  )
                            )
                          })
                        )
                  )
                })
              )
        )
      })
    )
  }

  const generateTransformsBody = (
    schemas: DbSchemaStructure[],
    context: GenerateTransformContext
  ) => {
    const transformBody = t.objectExpression([])
    if (context.transformMode) {
      transformBody.properties.push(
        t.objectProperty(
          t.identifier('$mode'),
          t.stringLiteral(context.transformMode)
        )
      )
    }
    for (const schema of schemas) {
      const ast = computeSchemaAst(schema, context)
      if (ast) {
        transformBody.properties.push(
          t.objectProperty(t.identifier(schema.name), ast)
        )
      }
    }
    return transformBody
  }

  const _compileTemplates = (
    rawTemplates: Partial<GenerateTransformTemplates>
  ) => {
    const templates = {
      ...DEFAULT_TEMPLATES,
      ...rawTemplates,
    }

    return {
      input: template.expression(templates.input, baseTemplateOptions),
      tableTransform: template.expression(
        templates.tableTransform,
        baseTemplateOptions
      ),
    }
  }

  const compileTemplates = memoize(_compileTemplates, JSON.stringify)

  const generateDefineConfigStatements = (
    schemas: DbSchemaStructure[],
    tables: IntrospectedStructure['tables'],
    options: GenerateTransformOptions = {},
    subsetConfig?: SubsetConfigV2,
    selectConfig?: SelectConfig
  ) => {
    const { generateSections = ['transform', 'select', 'subset'] } = options

    const includeSelect = generateSections.includes('select')
    const includeSubset = generateSections.includes('subset')
    const includeTransform = generateSections.includes('transform')

    const transformsBody = generateTransformsBody(schemas, {
      includeEmpty: false,
      includePiiOnly: true,
      ...options,
      templates: compileTemplates({
        ...DEFAULT_TEMPLATES,
        ...options?.templates,
      }),
    })

    return t.exportDefaultDeclaration(
      t.callExpression(t.identifier('defineConfig'), [
        t.objectExpression([
          ...(selectConfig && includeSelect
            ? [
                t.objectProperty(
                  t.identifier('select'),
                  generateSelectStatements(selectConfig)
                ),
              ]
            : []),
          ...(includeTransform
            ? [t.objectProperty(t.identifier('transform'), transformsBody)]
            : []),
          ...(includeSubset ? generateSubsetStatements(subsetConfig) : []),
        ]),
      ])
    )
  }

  const generateTransformFromNestedStructure = async (
    schemas: DbSchemaStructure[],
    tables: IntrospectedStructure['tables'],
    options: GenerateTransformOptions = {},
    subsetConfig?: SubsetConfigV2,
    selectConfig?: SelectConfig
  ) => {
    const statements = [
      ...generateImportStatements({
        '@snaplet/copycat': ['copycat', 'faker'],
        snaplet: ['defineConfig'],
      }),
      ...(options.copycatSecretKey !== null
        ? [generateCopycatSetHashKey(options.copycatSecretKey)]
        : []),
      generateDefineConfigStatements(
        schemas,
        tables,
        options,
        subsetConfig,
        selectConfig
      ),
    ]
    let sourceText = ''

    for (const statement of statements) {
      sourceText += generate(statement).code
    }
    return sourceText
  }

  const generateCopycatSetHashKey = (
    copycatSecretKey = randomBytes(12).toString('base64')
  ): t.Node =>
    template.statement.ast(
      `copycat.setHashKey('${copycatSecretKey}');`,
      baseTemplateOptions
    )

  const generateTransform = async (
    tables: IntrospectedStructure['tables'],
    options: GenerateTransformOptions = {},
    subsetConfig?: SubsetConfigV2,
    selectConfig?: SelectConfig
  ) => {
    const schemas = computeNestedSchemaStructure(tables)
    const configCode = await generateTransformFromNestedStructure(
      schemas,
      tables,
      options,
      subsetConfig,
      selectConfig
    )
    const code = `
  ${generateTypedefInclusion()}
  // This config was generated by Snaplet make sure to check it over before using it.
  ${configCode}
  `
    const { format } = await import('prettier')
    const formattedCode = format(code, { parser: 'babel' })
    return formattedCode
  }

  return {
    createTemplateContext,
    generateColumnTransformCode,
    applyColumnTransformTemplate,
    generateTransform,
    DEFAULT_TEMPLATES,
  }
}

function encloseValueInArray(pgType: string, value: string) {
  const dimensions = getPgTypeArrayDimensions(pgType)

  if (dimensions === 0) {
    return value
  }

  return [...Array(dimensions)].reduce((acc) => `[${acc}]`, value)
}

export const getTransform = memoize(_getTransform)
