type GetRelationshipOptionParams<T extends boolean | number | undefined> = {
  cascadingOptions: T | Record<string, T | Record<string, T>>
  defaultValue: T
  relations: Array<{
    sourceTableId: string
    relationId: string
    destinationTableId: string
  }>
  relation: {
    sourceTableId: string
    relationId: string
    destinationTableId: string
  }
}

// This function is there to drill down into the configuration to extract the lower level option
// for each subsetting reference, taking into account cascading $default options
export function getRelationshipOption<T extends boolean | number | undefined>(
  params: GetRelationshipOptionParams<T>
): T {
  const { cascadingOptions, defaultValue, relation } = params
  const { destinationTableId: tableId, relationId, sourceTableId } = relation

  if (
    cascadingOptions === undefined ||
    typeof cascadingOptions === 'number' ||
    typeof cascadingOptions === 'boolean'
  ) {
    return cascadingOptions
  }

  const tableOptions =
    cascadingOptions[tableId] !== undefined
      ? cascadingOptions[tableId]
      : cascadingOptions['$default'] !== undefined
        ? cascadingOptions['$default']
        : {}

  if (typeof tableOptions === 'number' || typeof tableOptions === 'boolean') {
    return tableOptions
  }

  const relationOptions =
    tableOptions?.[relationId] !== undefined
      ? tableOptions?.[relationId]
      : tableOptions?.[sourceTableId] !== undefined
        ? tableOptions?.[sourceTableId]
        : tableOptions?.['$default'] !== undefined
          ? tableOptions?.['$default']
          : undefined

  return relationOptions !== undefined ? relationOptions : defaultValue
}
