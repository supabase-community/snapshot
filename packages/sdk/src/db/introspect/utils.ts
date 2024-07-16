import {
  introspectedStructureSchema,
  IntrospectedStructure,
} from './introspectDatabase.js'

export type ProjectIntrospectedStructure = {
  version: '20231002'
  data: IntrospectedStructure
}

export function isIntrospectedStructure(
  structure: any
): structure is IntrospectedStructure {
  try {
    introspectedStructureSchema.parse(structure)
    return true
  } catch (e) {
    return false
  }
}

export function getIntrospectedStructure(
  dbStructure: ProjectIntrospectedStructure | null
) {
  if (dbStructure && dbStructure.version === '20231002') {
    return dbStructure.data
  }
  return null
}
