import sourceMap from 'source-map-js'
import { SnapletErrorBase } from '~/errors.js'

export function createErrorCodeFrame(args: {
  col: number
  line: number
  originalSource: string
  message?: string
}) {
  const { codeFrameColumns } = require('@babel/code-frame')
  const frame = codeFrameColumns(
    args.originalSource,
    {
      start: {
        line: args.line,
        column: args.col,
      },
    },
    {
      highlightCode: true,
      message: args.message,
      linesAbove: 1,
      linesBelow: 1,
    }
  )
  return frame as string
}
// This is used to parse the config execuction error stack trace and try to extract the original
// code frame of the culprit line
export function tryExtractErrorFrame(
  filepath: string,
  compiledSource: string,
  originalSource: string,
  e: Error
) {
  try {
    // Extract the inline source map from the transpiled code
    const sourceMapMatch = compiledSource.match(
      /\/\/# sourceMappingURL=(.*);base64,(.*)/
    )
    // if there actually were source maps in the compiled source
    if (sourceMapMatch && e.stack) {
      // Try to find the line in the stack trace that contains the config file error
      const stackLines = e.stack?.split('\n')
      const configErrorLine = stackLines.findIndex(
        (line) => line.includes(filepath) && line.match(/:(\d+):(\d+)/)
      )
      // if we found the config file error line
      if (configErrorLine > -1) {
        // extract the base64 encoded source map and parse it as json
        const sourceMapBase64 = sourceMapMatch[2]
        const sourceMapString = Buffer.from(
          sourceMapBase64,
          'base64'
        ).toString()
        const sourceMapJson = JSON.parse(sourceMapString)
        // create a source map consumer to find the line and column of the error in original source
        const smc = new sourceMap.SourceMapConsumer(sourceMapJson)
        // extract the line and column from the error stack trace
        const errorLine = stackLines[configErrorLine]
        const match = errorLine.match(/:(\d+):(\d+)/)
        // if we found the line and column
        if (match) {
          const line = Number(match[1])
          const column = Number(match[2])
          const originalPosition = smc.originalPositionFor({
            line: line,
            column: column,
          })
          return createErrorCodeFrame({
            originalSource,
            line: originalPosition.line,
            col: originalPosition.column,
            message: (e as Error).message,
          })
        }
      }
    }
  } catch (e) {
    return null
  }
  return null
}

// This class is used for config execution errors such as syntax errors
export class SnapletExecuteConfigError
  extends Error
  implements SnapletErrorBase<'CONFIG_ERROR'>
{
  readonly _tag = 'SnapletExecuteConfigError'
  codeframe?: string
  code = 'CONFIG_ERROR' as const
  data = {}
  constructor(filepath: string, codeframe?: string, originalError?: Error) {
    super()
    this.name = 'SnapletExecuteConfigError'
    this.message = [
      `Failed to execute config file: ${filepath}`,
      originalError?.message,
    ]
      .filter(Boolean)
      .join(':\n')
    this.codeframe = codeframe
    const stack = `${codeframe ?? originalError?.stack ?? this.stack}`
    this.stack = stack
  }
}

export class SnapletCompileConfigError
  extends Error
  implements SnapletErrorBase<'CONFIG_ERROR'>
{
  readonly _tag = 'SnapletCompileConfigError'
  codeframe?: string
  code = 'CONFIG_ERROR' as const
  data = {}
  constructor(filepath: string, codeframe?: string, originalError?: Error) {
    super()
    this.name = 'SnapletCompileConfigError'
    this.message = `Failed to compile config file: ${filepath}`
    this.codeframe = codeframe
    const stack = `${codeframe ?? originalError?.stack ?? this.stack}`
    this.stack = stack
  }
}
