import type * as types from '@babel/types'
import { importAstBabelDeps, AstBabelDeps } from './ast/babelDepsLoader.js'

export interface ColumnConfigLocations {
  schema: types.SourceLocation | null
  table: types.SourceLocation | null
  column: types.SourceLocation | null
}

const DEFAULT_COLUMN_CONFIG_LOCATION = {
  schema: null,
  table: null,
  column: null,
}

const findConfigNode = (
  deps: Pick<AstBabelDeps, 'traverse'>,
  ast: types.Node
): types.ObjectExpression | null => {
  let result = null

  deps.traverse(ast, {
    CallExpression(path) {
      const callee = path.node.callee
      const arg0 = path.node.arguments[0]

      if (
        callee.type === 'Identifier' &&
        callee.name === 'defineConfig' &&
        arg0 &&
        arg0.type === 'ObjectExpression'
      ) {
        result = arg0 ?? null
        path.stop()
      }
    },
  })

  return result
}

const findPropertyNode = (
  objectNode: types.ObjectExpression,
  propertyName: string
): types.ObjectProperty | types.ObjectMethod | null =>
  (objectNode.properties.find(
    (property) =>
      (property.type === 'ObjectMethod' ||
        property.type === 'ObjectProperty') &&
      property.key.type === 'Identifier' &&
      property.key.name === propertyName
  ) as types.ObjectProperty | types.ObjectMethod) ?? null

const findPropertyValueNode = (
  objectNode: types.ObjectExpression,
  propertyName: string
): types.Expression | types.PatternLike | null => {
  const property = findPropertyNode(objectNode, propertyName)
  return property?.type === 'ObjectProperty' ? property.value : null
}

// todo(justinvdm, 12 July 2023): Support things other than object methods as table nodes (e.g. arrow function expressions)
const findColumnNode = (
  deps: Pick<AstBabelDeps, 'traverse'>,
  tableNode: types.Node,
  columnName: string
): types.ObjectProperty | types.ObjectMethod | null => {
  let columnNode = null

  deps.traverse(tableNode, {
    noScope: true,
    // todo(justinvdm, 12 July 2023): Support things other than returned object literal for defined object properties
    ReturnStatement(path) {
      const arg = path.node.argument

      if (arg?.type === 'ObjectExpression') {
        // @ts-ignore
        columnNode = findPropertyNode(arg, columnName)
        path.stop()
      }
    },
  })

  return columnNode
}

const doLocateColumnConfig = (
  deps: Pick<AstBabelDeps, 'parser' | 'traverse'>,
  source: string,
  schemaName: string,
  tableName: string,
  columnName: string
): ColumnConfigLocations => {
  const { parser } = deps
  const ast = parser.parse(source, { sourceType: 'module' })

  const locations: ColumnConfigLocations = DEFAULT_COLUMN_CONFIG_LOCATION
  // @ts-ignore
  const configNode = findConfigNode(deps, ast)

  const transformConfigNode = configNode
    ? findPropertyValueNode(configNode, 'transform')
    : null

  const schemaNode =
    transformConfigNode?.type === 'ObjectExpression'
      ? findPropertyValueNode(transformConfigNode, schemaName)
      : null

  const tableNode =
    schemaNode?.type === 'ObjectExpression'
      ? findPropertyNode(schemaNode, tableName)
      : null

  const columnNode = tableNode
    ? findColumnNode(deps, tableNode, columnName)
    : null

  locations.schema = schemaNode?.loc ?? null
  locations.table = tableNode?.loc ?? null
  locations.column = columnNode?.loc ?? null

  return locations
}

export const locateColumnConfig = async (
  source: string,
  schemaName: string,
  tableName: string,
  columnName: string
) => {
  try {
    return doLocateColumnConfig(
      await importAstBabelDeps(['parser', 'traverse']),
      source,
      schemaName,
      tableName,
      columnName
    )
    // In case of error we still want to return the config
  } catch (e) {
    return DEFAULT_COLUMN_CONFIG_LOCATION
  }
}

export const transformColumnConfig = async (source: string) => {
  const { core } = await importAstBabelDeps(['core'])

  const result = await core.transformAsync(source, {
    plugins: [
      require('@babel/plugin-transform-typescript'),
      require('@babel/plugin-transform-modules-commonjs'),
    ],
  })

  return result?.code
}
