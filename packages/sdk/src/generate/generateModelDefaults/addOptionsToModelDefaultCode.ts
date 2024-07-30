import { last } from 'lodash'
import { importAstBabelDeps } from '~/config/snapletConfig/v2/ast/babelDepsLoader.js'

export const addOptionsToModelDefaultCode = async (code: string) => {
  const babel = await importAstBabelDeps([
    'parser',
    'generate',
    'traverse',
    'types',
  ])

  const t = babel.types

  const ast = babel.parser.parse(`(${code})`)

  babel.traverse(ast, {
    CallExpression(path) {
      if (
        !(
          // @ts-ignore
          t.isMemberExpression(path.node?.callee) &&
          t.isIdentifier(path.node.callee.object) &&
          path.node.callee.object.name === 'copycat'
        )
      ) {
        return
      }

      const lastArg = last(path.node.arguments)

      // If there is an options object, spread in `options`
      // e.g. copycat.email(seed, { limit: 10 }) -> copycat.email(seed, { limit: 10, ...options })
      // @ts-ignore
      if (t.isObjectExpression(lastArg)) {
        lastArg.properties.push(t.spreadElement(t.identifier('options')))
      }
      // Otherwise just add `options` as an arg
      // e.g. copycat.email(seed) -> copycat.email(seed, options)
      else {
        path.node.arguments.push(t.identifier('options'))
      }
    },
  })

  return babel.generate(ast).code
}
