import { StructureInfos } from '../transform.js'
import {
  TransformFallbackMode,
  applyFallback,
  importGenerateTransform,
} from '../fallbacks.js'
import { FillRowsColumnStatus, FillRowsInput, FillRowsResult } from './types.js'
import { Json } from '~/types.js'
import { JsonNull } from '~/pgTypes.js'

export interface FillRowsOptions {
  schemaName: string
  tableName: string
  data: FillRowsInput
  structure: StructureInfos
  mode: TransformFallbackMode
}

export const fillRows = async (
  options: FillRowsOptions
): Promise<FillRowsResult> => {
  await importGenerateTransform()

  const { schemaName, tableName, structure, mode, data } = options
  const result: FillRowsResult = []

  for (const inputRowData of data) {
    const filled: Record<string, Json | JsonNull> = {}
    const statuses: Record<string, FillRowsColumnStatus> = {}

    for (const columnName of Object.keys(inputRowData.raw)) {
      let columnResult
      let status: FillRowsColumnStatus

      const replacement = inputRowData.replacement[columnName]

      if (typeof replacement !== 'undefined') {
        columnResult = replacement

        status = 'replaced'
      } else if (mode === 'strict') {
        status = 'invalid'
        columnResult = null
      } else {
        status = mode === 'unsafe' ? 'original' : 'filled'

        columnResult = applyFallback({
          schemaName,
          tableName,
          columnName,
          structure,
          mode,
          row: {
            line: inputRowData.line,
            parsed: inputRowData.parsed,
            raw: inputRowData.raw,
          },
        })
      }

      filled[columnName] = columnResult
      statuses[columnName] = status
    }

    result.push({
      ...inputRowData,
      filled,
      statuses,
    })
  }

  return result
}
