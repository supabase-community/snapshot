import {
  IntrospectedStructure,
  getSnapshotFilePaths,
  introspectedStructureSchema,
} from '@snaplet/sdk/cli'
import fs from 'fs-extra'

export async function writeSnapshotStructure(
  paths: ReturnType<typeof getSnapshotFilePaths>,
  structure: IntrospectedStructure
) {
  await fs.writeJSON(paths.structure, structure, { spaces: 2 })
}

export async function readSnapshotStructure(
  paths: ReturnType<typeof getSnapshotFilePaths>
) {
  const structure = await fs.readJSON(paths.structure, { encoding: 'utf-8' })
  return introspectedStructureSchema.parse(structure)
}

export const readSnapshotConfig = async (filePath: string) => {
  try {
    if (!(await fs.pathExists(filePath))) {
      return undefined
    }
    const x = await fs.readFile(filePath, { encoding: 'utf-8' })
    return x
  } catch (e: any) {
    console.log(`Could not read ${filePath}: ${e.message}`)
  }
}
