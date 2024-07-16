import { ErrorList, SnapletError, TransformError } from '@snaplet/sdk/cli'
import { uniq } from 'lodash'

const flattenErrors = (errors: Error[]): Error[] => {
  const results = []

  for (const error of errors) {
    if (error.name === 'TransformError') {
      const transformError = error as TransformError

      if (transformError.error.name === 'ErrorList') {
        results.push(
          ...flattenErrors((transformError.error as ErrorList).errors).map(
            (error) =>
              error.name === 'TransformError'
                ? error
                : new TransformError(transformError.context, error)
          )
        )
      } else if (transformError.error.name === 'SnapletError') {
        results.push(transformError.error)
      } else {
        results.push(transformError)
      }
    } else if (error.name === 'ErrorList') {
      results.push(...flattenErrors((error as ErrorList).errors))
    } else {
      results.push(error)
    }
  }

  return results
}

export const displayErrors = (errors: Error[]) => {
  console.log(errors)
  const strictModeMissingSchemas: SnapletError<'CONFIG_STRICT_TRANSFORM_MISSING_SCHEMA'>[] =
    []
  const strictModeMissingTables: SnapletError<'CONFIG_STRICT_TRANSFORM_MISSING_TABLE'>[] =
    []
  const strictModeMissingColumns: SnapletError<'CONFIG_STRICT_TRANSFORM_MISSING_COLUMN'>[] =
    []

  const otherMessages: string[] = []

  for (const error of flattenErrors(errors)) {
    if (
      SnapletError.instanceof(error, 'CONFIG_STRICT_TRANSFORM_MISSING_SCHEMA')
    ) {
      strictModeMissingSchemas.push(error)
    } else if (
      SnapletError.instanceof(error, 'CONFIG_STRICT_TRANSFORM_MISSING_TABLE')
    ) {
      strictModeMissingTables.push(error)
    } else if (
      SnapletError.instanceof(error, 'CONFIG_STRICT_TRANSFORM_MISSING_COLUMN')
    ) {
      strictModeMissingColumns.push(error)
    } else {
      otherMessages.push(error.toString())
    }
  }

  const strictModeMessages: string[] = []

  if (
    strictModeMissingSchemas.length ||
    strictModeMissingTables.length ||
    strictModeMissingColumns.length
  ) {
    strictModeMessages.push(
      [
        'The following schemas, tables or columns are missing from your transform config.',
        'Since you are using strict transform mode, snaplet needs these to be given.',
        'You can read more about this at https://docs.snaplet.dev/core-concepts/capture#strict-mode:',
      ].join(' ')
    )
  }

  if (strictModeMissingSchemas.length) {
    strictModeMessages.push(
      `* Schemas: ${uniq(
        strictModeMissingSchemas.map((error) => `"${error.data?.schema}"`)
      ).join(', ')}`
    )
  }

  if (strictModeMissingTables.length) {
    strictModeMessages.push(
      `* Tables: ${strictModeMissingTables
        .map((error) => `"${error.data?.schema}"."${error.data?.table}"`)
        .join(', ')}`
    )
  }

  if (strictModeMissingColumns.length) {
    strictModeMessages.push(
      `* Columns: ${strictModeMissingColumns
        .map(
          (error) =>
            `"${error.data?.schema}"."${error.data?.table}"."${error.data?.column}"`
        )
        .join(', ')}`
    )
  }

  if (strictModeMessages.length) {
    const messages = [...strictModeMessages]

    if (otherMessages.length) {
      messages.push('\n', 'Other errors:', otherMessages.join('\n\n'))
    }

    return messages.join('\n')
  } else {
    return otherMessages.join('\n\n')
  }
}
