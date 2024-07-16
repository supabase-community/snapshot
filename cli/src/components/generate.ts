import {
  generateV2ConfigTypes,
  generateRSAKeys,
  getTransform,
  TableShapePredictions,
  DataModel,
  IntrospectedStructure,
  GenerateTransformOptions,
  generateConfigTypes,
} from '@snaplet/sdk/cli'
import c from 'ansi-colors'

import { writeProjectFile, generateEncryptionConfig } from './writeConfig.js'

export const actGenerateRSA = async (
  dryRun: boolean,
  relatativePrivateKeyPath: string,
  relativeConfigPath: string
) => {
  if (dryRun) {
    const pair = await generateRSAKeys()
    console.log(pair.publicKey)
  } else {
    await generateEncryptionConfig()
    console.log(`Generated private key: ${c.bold(relatativePrivateKeyPath)}`)
    console.log(
      `Added ${c.bold('publicKey')} to project config: ${c.bold(
        relativeConfigPath
      )}`
    )
  }
}

// TODO: Confirm overwrite
export const actGenerateTypeDefs = async (
  structure: IntrospectedStructure,
  filePath: string,
  relativeFilePath: string,
  dryRun: boolean
) => {
  const source = generateV2ConfigTypes(structure)
  if (dryRun) {
    console.log(source)
  } else {
    await writeProjectFile(filePath, source)
    console.log(
      `Generated snaplet.config.ts type definitions: ${c.bold(
        relativeFilePath
      )} (see: ${c.gray(
        'https://docs.snaplet.dev/reference/configuration#type-safe-configuration-based-on-your-database-structure'
      )})`
    )
  }
}

// TODO: Confirm overwrite
export const actGenerateDataClientTypeDefs = async (props: {
  dataModel: DataModel
  rawDataModel: DataModel
  filePath: string
  relativeFilePath: string
  dryRun: boolean
}) => {
  const { dataModel, rawDataModel, filePath, relativeFilePath, dryRun } = props

  const source = await generateConfigTypes({
    dataModel,
    rawDataModel,
  })

  if (dryRun) {
    console.log(source)
  } else {
    await writeProjectFile(filePath, source)
    console.log(
      `Generated snaplet client type definitions for seed: ${c.bold(
        relativeFilePath
      )} (see: ${c.gray(
        'https://docs.snaplet.dev/core-concepts/seed#introducing-the-snaplet-data-client'
      )})`
    )
  }
}

export const actGenerateTransform = async (
  structure: Pick<IntrospectedStructure, 'tables'>,
  filePath: string,
  dryRun: boolean,
  tableShapePredictions?: TableShapePredictions[],
  generateSections?: GenerateTransformOptions['generateSections']
) => {
  const { generateTransform } = await getTransform()
  const source = await generateTransform(structure.tables, {
    tableShapePredictions,
    generateSections,
  })
  if (dryRun) {
    console.log(source)
  } else {
    await writeProjectFile(filePath, source)
    console.log(`Generated config: ${c.bold(filePath)}`)
  }
}
