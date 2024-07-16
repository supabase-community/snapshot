import { type IntrospectedStructure } from '../../../db/introspect/introspectDatabase.js'

import { SelectConfig } from './getConfig/parseConfig.js'

export function calculateIncludedSchemas(
  schemas: IntrospectedStructure['schemas'],
  selectConfig?: SelectConfig
) {
  if (!selectConfig) {
    return schemas
  }

  return schemas.filter((schemaName) => {
    const defaultValue = selectConfig.$default ?? true
    const schemaValue = selectConfig[schemaName] ?? defaultValue
    return Boolean(schemaValue)
  })
}

type Table = Pick<
  IntrospectedStructure['tables'][number],
  'schema' | 'name'
> & { id?: string }
// tables which structure and data should be included (for the schema.sql dump)
export function calculateIncludedTablesStructure(
  tables: Array<Table>,
  selectConfig?: SelectConfig
) {
  if (!selectConfig) {
    return tables
  }

  return tables.filter((table) => {
    const rootDefaultValue = selectConfig.$default ?? true
    const schemaValue = selectConfig[table.schema] ?? rootDefaultValue
    if (schemaValue === true || schemaValue === 'structure') {
      return true
    } else if (schemaValue === false) {
      return false
    } else {
      const schemaDefaultValue = schemaValue.$default ?? rootDefaultValue
      const tableValue = schemaValue[table.name] ?? schemaDefaultValue
      return Boolean(tableValue)
    }
  })
}

// tables which data are dumped
export function calculateIncludedTables(
  tables: Array<Table>,
  selectConfig?: SelectConfig,
  includeStructure = false
) {
  if (!selectConfig) {
    return tables
  }

  return tables.filter((table) => {
    const rootDefaultValue = selectConfig.$default ?? true
    const schemaValue = selectConfig[table.schema] ?? rootDefaultValue
    if (schemaValue === true) {
      return true
    } else if (schemaValue === false || schemaValue === 'structure') {
      if (schemaValue === 'structure' && includeStructure) {
        return true
      }
      return false
    } else {
      const schemaDefaultValue = schemaValue.$default ?? rootDefaultValue
      const tableValue = schemaValue[table.name] ?? schemaDefaultValue
      if (tableValue === 'structure' && includeStructure) {
        return true
      }
      return tableValue === true ? true : false
    }
  })
}

type Extension = Pick<
  IntrospectedStructure['extensions'][number],
  'schema' | 'name'
>
export function calculateIncludedExtensions(
  extensions: Array<Extension>,
  selectConfig?: SelectConfig
) {
  if (!selectConfig) {
    return extensions
  }

  return extensions.filter((extension) => {
    const rootDefaultValue = selectConfig.$default ?? true
    const schemaValue = selectConfig[extension.schema] ?? rootDefaultValue
    if (schemaValue === true || schemaValue === 'structure') {
      return true
    } else if (schemaValue === false) {
      return false
    } else {
      const schemaDefaultValue = schemaValue.$default ?? rootDefaultValue
      const extensionsValue =
        schemaValue.$extensions ?? Boolean(schemaDefaultValue)
      if (extensionsValue === true) {
        return true
      } else if (extensionsValue === false) {
        return false
      } else {
        const extensionValue =
          extensionsValue[extension.name] ?? Boolean(schemaDefaultValue)
        return extensionValue
      }
    }
  })
}
