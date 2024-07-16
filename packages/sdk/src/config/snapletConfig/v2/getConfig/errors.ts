import { uniqBy } from 'lodash'
import { z, ZodError } from 'zod'
import { fromZodError, ValidationError } from 'zod-validation-error'
import { SnapletErrorBase } from '~/errors.js'

// Since union can have very nested path we need to find the deepest path to bubble up the proper error message
function findDeepestPath(issue: z.ZodInvalidUnionIssue) {
  let deepestIssue = issue as z.ZodIssue
  const errors = [...issue.unionErrors]
  let error = errors.pop()
  while (error) {
    for (const issue of error.issues) {
      if (issue.path.length > deepestIssue.path.length) {
        deepestIssue = issue
      }
      if (issue.code === 'invalid_union') {
        errors.push(...issue.unionErrors)
      }
    }
    error = errors.pop()
  }
  return deepestIssue
}

// This is in charge of parsing the zod error for the select config since the type is a complex union
// we need to manually parse it with our config behaviour in mind to get a human readable error message
function customParseSelectConfigUnion(
  issue: z.ZodInvalidUnionIssue & {
    fatal?: boolean | undefined
    message: string
  }
) {
  // We get the deepath issue since in union we want to know the deepest path to bubble up the proper error message
  const deepestIssue = findDeepestPath(issue)
  const deepestPath = deepestIssue.path
  // If it's the $default special key it must be either a boolean or "structure" literal
  if (deepestPath.includes('$default')) {
    return {
      ...issue,
      unionErrors: [
        new ZodError([
          {
            code: 'custom',
            message: `Expected boolean | "structure"`,
            path: deepestPath,
          },
        ]),
      ],
    }
  }
  if (deepestPath.includes('$extensions')) {
    return {
      ...issue,
      unionErrors: [
        new ZodError([
          {
            code: 'custom',
            message:
              deepestPath[deepestPath.length - 1] === '$extensions'
                ? // if it's a definition for all $extensions
                  'Expected boolean | { "<extensionName>": boolean }'
                : // if it's only a definition for one extension
                  'Expected boolean',
            path: deepestPath,
          },
        ]),
      ],
    }
  }
  // Since we checked for $extension and $default before at this level this must be a table definition
  if (deepestPath.length === 3)
    return {
      ...issue,
      unionErrors: [
        new ZodError([
          {
            code: 'custom',
            message: 'Expected boolean | "structure"',
            path: deepestPath,
          },
        ]),
      ],
    }
  // At this level this must be a schema config definition
  if (deepestPath.length === 2) {
    return {
      ...issue,
      unionErrors: [
        new ZodError([
          {
            code: 'custom',
            message: 'Expected boolean | { "<tableName>": SelectTableConfig }',
            path: deepestPath,
          },
        ]),
      ],
    }
  }
  return issue
}

export class SnapletParseConfigError
  extends Error
  implements SnapletErrorBase<'CONFIG_ERROR'>
{
  readonly _tag = 'SnapletParseConfigError'
  code = 'CONFIG_ERROR' as const
  data = {}
  validationError?: ValidationError
  constructor(filepath?: string, originalError?: ZodError) {
    super()
    this.name = 'SnapletParseConfigError'
    this.message = `Failed to parse config file: ${filepath}`
    const stack = `${originalError?.stack ?? this.stack}`
    this.stack = stack
    if (originalError) {
      const filteredIssues = uniqBy(originalError.issues, (issue) =>
        JSON.stringify(issue.path)
      ).map((issue) => {
        if (issue.code === 'invalid_union') {
          if (issue.path[0] === 'select') {
            return customParseSelectConfigUnion(issue)
          }
        }
        return issue
      })
      originalError.issues = filteredIssues
      this.validationError = fromZodError(originalError, {
        issueSeparator: ' and\n',
        prefix: '',
        prefixSeparator: '',
        unionSeparator: ' or ',
      })
      this.stack = this.validationError.stack
      this.message = `${this.message}\n${this.validationError.message}`
    }
  }
}
