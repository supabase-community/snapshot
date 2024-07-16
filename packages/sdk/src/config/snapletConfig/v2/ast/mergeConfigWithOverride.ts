import type * as t from '@babel/types'
import { SnapletConfig } from '../getConfig/parseConfig.js'
import { AstBabelDeps, importAstBabelDeps } from './babelDepsLoader.js'

function updateConfig(
  deps: Pick<AstBabelDeps, 'generate' | 'parser' | 'traverse' | 'types'>,
  source: string,
  override: Partial<SnapletConfig>,
  deep: boolean
): string {
  const { parser, generate, traverse, types: t } = deps
  // Parse the source code to an AST
  const ast = parser.parse(source, {
    sourceType: 'module',
    plugins: ['typescript'],
  })

  // Traverse the AST to find the call to `defineConfig`
  traverse(ast, {
    CallExpression(path) {
      if (
        t.isIdentifier(path.node.callee, { name: 'defineConfig' }) &&
        path.node.arguments.length > 0
      ) {
        const arg = path.node.arguments[0]

        if (t.isObjectExpression(arg)) {
          // Filter properties to get only ObjectProperty type
          const objectProperties = arg.properties.filter(
            (o): o is t.ObjectProperty => t.isObjectProperty(o)
          )
          // Merge the existing properties with the override
          arg.properties = mergeProperties(
            deps,
            objectProperties,
            override,
            deep
          )
        }
      }
    },
  })

  // Convert the modified AST back to code
  const { code } = generate(ast)
  return code
}

function valueToAst(
  deps: Pick<AstBabelDeps, 'types' | 'parser'>,
  value: any
): t.Expression {
  const { types: t, parser } = deps

  if (typeof value === 'string') {
    return t.stringLiteral(value)
  } else if (typeof value === 'number') {
    return t.numericLiteral(value)
  } else if (typeof value === 'boolean') {
    return t.booleanLiteral(value)
  } else if (Array.isArray(value)) {
    return t.arrayExpression(value.map((v) => valueToAst(deps, v)))
  } else if (typeof value === 'object') {
    const properties = Object.keys(value).map((key) =>
      t.objectProperty(t.identifier(key), valueToAst(deps, value[key]))
    )
    return t.objectExpression(properties)
  } else if (typeof value === 'function') {
    // Wrap the function string in an object literal and parse it
    const wrapperAst = parser.parseExpression(`({fn: ${value.toString()}})`)
    // Make sure we got an ObjectExpression node
    if (!t.isObjectExpression(wrapperAst)) {
      throw new Error('Expected an ObjectExpression node')
    }
    // Extract the function from the object
    // @ts-expect-error TS complain that value does not exist (but it does)
    const functionAst = wrapperAst.properties[0].value
    // Make sure we got a FunctionExpression or ArrowFunctionExpression node
    if (
      !t.isFunctionExpression(functionAst) &&
      !t.isArrowFunctionExpression(functionAst)
    ) {
      throw new Error(
        'Expected a FunctionExpression or ArrowFunctionExpression node'
      )
    }
    return functionAst
  } else {
    throw new Error(`Unsupported value type: ${typeof value}`)
  }
}

// This function will deeply merge all the properties of the override
// It's the equivalent of doing `newConfig = {...oldConfig, ...override, transform: {...oldConfig.transform, ...override.transform} ...}`
function deepMergeProperties(
  deps: Pick<AstBabelDeps, 'types' | 'parser'>,
  properties: t.ObjectProperty[],
  override: Partial<SnapletConfig>
): t.ObjectProperty[] {
  const updatedProperties: t.ObjectProperty[] = []
  const { types: t } = deps

  for (const prop of properties) {
    if (t.isObjectProperty(prop) && t.isIdentifier(prop.key)) {
      const key = prop.key.name

      if (Object.prototype.hasOwnProperty.call(override, key)) {
        if (
          t.isObjectExpression(prop.value) &&
          // we need to cast override as any because TS can't infer type across recursion
          typeof (override as any)[key] === 'object' &&
          !Array.isArray((override as any)[key])
        ) {
          const objectProperties = prop.value.properties.filter(
            (o): o is t.ObjectProperty => t.isObjectProperty(o)
          )

          if (key === 'transform') {
            const transformOverride = (override as any)[key] as any
            for (const transformKey in transformOverride) {
              const correspondingProperty = objectProperties.find(
                (p) =>
                  t.isObjectProperty(p) &&
                  t.isIdentifier(p.key) &&
                  p.key.name === transformKey
              )
              if (correspondingProperty) {
                if (t.isObjectExpression(correspondingProperty.value)) {
                  correspondingProperty.value.properties = deepMergeProperties(
                    deps,
                    correspondingProperty.value.properties.filter(
                      (o): o is t.ObjectProperty => t.isObjectProperty(o)
                    ),
                    transformOverride[transformKey]
                  )
                }
              } else {
                prop.value.properties.push(
                  t.objectProperty(
                    t.identifier(transformKey),
                    valueToAst(deps, transformOverride[transformKey])
                  )
                )
              }
            }
          } else {
            prop.value.properties = deepMergeProperties(
              deps,
              objectProperties,
              (override as any)[key]
            )
          }
        } else {
          prop.value = valueToAst(deps, (override as any)[key])
        }
      }

      updatedProperties.push(prop)
    }
  }

  for (const key in override) {
    if (Object.prototype.hasOwnProperty.call(override, key)) {
      if (
        !properties.find(
          (p) =>
            t.isObjectProperty(p) && t.isIdentifier(p.key) && p.key.name === key
        )
      ) {
        updatedProperties.push(
          t.objectProperty(
            t.identifier(key),
            valueToAst(deps, (override as any)[key])
          )
        )
      }
    }
  }

  return updatedProperties
}

// This function will merge the properties of the override in a shallow way
// It's the equivalent of doing `newConfig = {...oldConfig, ...override}`
function shallowMergeProperties(
  deps: Pick<AstBabelDeps, 'types' | 'parser'>,
  properties: t.ObjectProperty[],
  override: Partial<SnapletConfig>
): t.ObjectProperty[] {
  const { types: t } = deps
  const updatedProperties: t.ObjectProperty[] = []
  // First add all existing properties from the AST, possibly updated
  for (const prop of properties) {
    if (t.isObjectProperty(prop) && t.isIdentifier(prop.key)) {
      const key = prop.key.name

      // If the key exists in the override
      if (Object.prototype.hasOwnProperty.call(override, key)) {
        prop.value = valueToAst(deps, (override as any)[key])
      }

      updatedProperties.push(prop)
    }
  }
  // Then add all new properties from the override that didn't exist in the AST
  // Eg: A config with only a "transform" defined, using a filtered snapshot should add a "subset" property

  for (const key in override) {
    if (Object.prototype.hasOwnProperty.call(override, key)) {
      if (
        !properties.find(
          (p) =>
            t.isObjectProperty(p) && t.isIdentifier(p.key) && p.key.name === key
        )
      ) {
        // Add the new property
        updatedProperties.push(
          t.objectProperty(
            t.identifier(key),
            valueToAst(deps, (override as any)[key])
          )
        )
      }
    }
  }

  return updatedProperties
}

function mergeProperties(
  deps: Pick<AstBabelDeps, 'types' | 'parser'>,
  properties: t.ObjectProperty[],
  override: Partial<SnapletConfig>,
  deep: boolean
) {
  if (deep) {
    return deepMergeProperties(deps, properties, override)
  } else {
    return shallowMergeProperties(deps, properties, override)
  }
}

// Override the config source with the "override" created when using filtered snapshot
export const mergeConfigWithOverride = async (
  sourceConfig: string,
  overrideConfig?: Partial<SnapletConfig>,
  deep = false
): Promise<string> => {
  let result = sourceConfig
  if (overrideConfig) {
    const deps = await importAstBabelDeps([
      'parser',
      'generate',
      'traverse',
      'types',
    ])
    result = updateConfig(deps, sourceConfig, overrideConfig, deep)
  }
  return result
}
