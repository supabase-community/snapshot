import type { TransformOptions as BabelTransformOptions } from '@babel/core'
import vm from 'vm'
import path from 'path'
import fsExtra from 'fs-extra'
import { silent as resolveFrom } from 'resolve-from'
import { pathToFileURL } from 'url'
import { isPlainObject } from 'lodash'
import { ParseError } from '@babel/parser'
import {
  SnapletCompileConfigError,
  SnapletExecuteConfigError,
  createErrorCodeFrame,
  tryExtractErrorFrame,
} from './errors.js'

export interface LoadModuleOptions {
  source?: string
  global?: Record<string, unknown>
  cache?: Record<string, unknown>
  shouldCompile?: boolean | ((name: string) => boolean)
  require?: (name: string) => object | null
}

const defaultRequire = () => null

const defaultShouldCompile = (filepath: string) =>
  !filepath.includes('node_modules')

function compileModule(filepath: string, source: string) {
  const { transformSync } = require('@babel/core')

  const babelTransformOptions: BabelTransformOptions & {
    targets: Record<string, string>
  } = {
    babelrc: false,
    configFile: false,
    filename: filepath,
    targets: {
      node: 'current',
    },
    sourceMaps: 'inline',
    plugins: [
      ...(path.extname(filepath) === '.ts'
        ? [require('@babel/plugin-transform-typescript')]
        : []),
      [require('@babel/plugin-transform-modules-commonjs'), { lazy: true }],
    ],
  }
  try {
    const result = transformSync(source, babelTransformOptions)

    if (!result?.code) {
      throw new SnapletCompileConfigError(filepath)
    }

    return result.code
  } catch (e) {
    const err = e as Error
    if (
      err &&
      (err as unknown as ParseError).code === 'BABEL_PARSE_ERROR' &&
      (err as { loc?: { line: number; column: number } }).loc
    ) {
      const babelParseError = err as unknown as ParseError & {
        loc?: { line: number; column: number }
      }
      const frame = createErrorCodeFrame({
        line: babelParseError.loc?.line ?? 0,
        col: babelParseError.loc?.column ?? 0,
        originalSource: source,
        message: babelParseError.reasonCode,
      })
      if (frame) {
        throw new SnapletCompileConfigError(filepath, frame, err)
      }
    }
    throw new SnapletCompileConfigError(filepath, undefined, err)
  }
}

export function loadModule<ModuleResult>(
  filepath: string,
  rawOptions: LoadModuleOptions = {}
) {
  const options = {
    global,
    cache: {},
    shouldCompile: defaultShouldCompile,
    require: defaultRequire,
    ...rawOptions,
  }

  if (typeof options.shouldCompile !== 'function') {
    const { shouldCompile } = options
    options.shouldCompile = () => shouldCompile
  }

  const { source: inputSource = fsExtra.readFileSync(filepath).toString() } =
    options

  if (filepath.endsWith('.json')) {
    return JSON.parse(inputSource)
  }

  const source = options.shouldCompile(filepath)
    ? compileModule(filepath, inputSource)
    : inputSource

  const context = Object.create(options.global)

  const requireModule = (name: string) => {
    // context(justinvdm, 18 September 2023): if the unresolved path is in the
    // cache, it was most likely an injected dependency (e.g. `'@snaplet/copycat'`),
    // so we take the name as is
    if (Object.hasOwn(options.cache, name)) {
      return options.cache[name]
    }

    const customRequireResult = options.require(name)

    if (customRequireResult != null) {
      return (options.cache[name] = customRequireResult)
    }

    const fromDir = path.dirname(filepath)
    const modulePath =
      resolveFrom(fromDir, name) ?? resolveFrom(fromDir, `${name}.ts`)

    if (modulePath === undefined) {
      throw new Error(
        `Module "${name}" not found relative to importing module "${filepath}"`
      )
    }

    if (Object.hasOwn(options.cache, modulePath)) {
      return options.cache[modulePath]
    }

    const isBuiltinModule = !path.isAbsolute(modulePath)

    const cachedModule: Record<string, unknown> = { __esModule: true }

    // context(justinvdm, 26 September 2023): Put something in the cache already
    // in case a cyclic import happens - we'll populate this same object later on
    // when we load the module
    options.cache[modulePath] = cachedModule

    let moduleResult

    if (isBuiltinModule) {
      moduleResult = require(modulePath)
    } else {
      moduleResult = loadModule(modulePath, {
        ...options,
        source: undefined,
        global: context,
      })
    }

    if (isPlainObject(moduleResult)) {
      Object.assign(cachedModule, moduleResult)

      if (moduleResult.__esModule) {
        cachedModule.__esModule = true
      } else {
        delete cachedModule.__esModule
      }

      moduleResult = cachedModule
    } else {
      options.cache[modulePath] = moduleResult
    }

    return moduleResult
  }

  const moduleExports = {}

  Object.assign(context, {
    __dirname: path.dirname(filepath),
    __filename: path.basename(filepath),
    import: {
      meta: {
        url: pathToFileURL(filepath).href,
      },
    },
    module: { exports: moduleExports },
    exports: moduleExports,
    require: requireModule,
  })

  try {
    vm.runInNewContext(source, context, {
      filename: filepath,
      displayErrors: true,
    })
  } catch (e) {
    const err = e as Error
    const frame = tryExtractErrorFrame(filepath, source, inputSource, err)
    if (frame) {
      throw new SnapletExecuteConfigError(filepath, frame, err)
    }
    throw new SnapletExecuteConfigError(filepath, undefined, err)
  }
  return context.module.exports as ModuleResult
}
