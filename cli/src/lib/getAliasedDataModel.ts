import {
  type AliasModelNameConflict,
  SnapletError,
  getAliasedDataModel as baseGetAliasedDataModel,
} from '@snaplet/sdk/cli'
import { display } from './display.js'
import { exitWithError } from './exit.js'

const renderModelNameConflicts = (conflicts: AliasModelNameConflict[]) =>
  conflicts
    .map(
      (conflict) => `* Alias "${conflict.aliasName}" maps to: ${[
        ...conflict.models.values(),
      ]
        .map((model) =>
          [model.schemaName, model.tableName].filter(Boolean).join('.')
        )
        .join(', ')}
`
    )
    .join('\n')

export const getAliasedDataModel = async (
  ...args: Parameters<typeof baseGetAliasedDataModel>
): Promise<ReturnType<typeof baseGetAliasedDataModel>> => {
  try {
    return baseGetAliasedDataModel(...args)
  } catch (error) {
    if (SnapletError.instanceof(error, 'SEED_ALIAS_MODEL_NAME_CONFLICTS')) {
      const conflicts = error.data?.conflicts ?? []
      display(`
Your database has some table names that would end up being aliased to the same names. To resolve this,
add alias \`overrides\` for these tables in your \`snaplet.config.ts\` file.

More on this in the docs: https://docs.snaplet.dev/core-concepts/seed#override

The following table names conflict:
${renderModelNameConflicts(conflicts)}`)
      await exitWithError(error.code)
      return args[0]
    } else {
      throw error
    }
  }
}
