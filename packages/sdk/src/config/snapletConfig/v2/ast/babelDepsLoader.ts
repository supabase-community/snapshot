import type * as parser from '@babel/parser'
import type * as traverse from '@babel/traverse'
import type * as types from '@babel/types'
import type * as generate from '@babel/generator'
import type * as template from '@babel/template'
import type * as prettier from 'prettier'
import type * as core from '@babel/core'

// All the deps you need to just parse and analyse the ast
interface ParsingDeps {
  traverse: typeof traverse.default
  parser: typeof parser
  core: typeof core
}

// The extra deps you need to regenerate source code from the ast
interface GenerateDeps {
  types: typeof types
  generate: typeof generate.default
  template: typeof template.default
  prettier: typeof prettier
}

type AstBabelDeps = ParsingDeps & GenerateDeps

// This function allow you to dynamically import only the deps you need at runtime
// but still get a typed array depending of the arguments you pass to it.
export async function importAstBabelDeps<K extends keyof AstBabelDeps>(
  depsToImport: Array<K>
): Promise<Pick<AstBabelDeps, K>> {
  const result = {
    traverse: depsToImport.includes('traverse' as K)
      ? (await import('@babel/traverse')).default
      : undefined,
    parser: depsToImport.includes('parser' as K)
      ? await import('@babel/parser')
      : undefined,
    types: depsToImport.includes('types' as K)
      ? await import('@babel/types')
      : undefined,
    generate: depsToImport.includes('generate' as K)
      ? (await import('@babel/generator')).default
      : undefined,
    prettier: depsToImport.includes('prettier' as K)
      ? await import('prettier')
      : undefined,
    template: depsToImport.includes('template' as K)
      ? (await import('@babel/template')).default
      : undefined,
    core: depsToImport.includes('core' as K)
      ? await import('@babel/core')
      : undefined,
  }
  return result as Pick<AstBabelDeps, K>
}
export type { AstBabelDeps }
