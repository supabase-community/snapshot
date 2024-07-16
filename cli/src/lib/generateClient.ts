import {
  IntrospectedStructure,
  TableShapePredictions,
  filterSelectedTables,
  generateDefaultFingerprint,
  getSelectedTables,
  introspectionToDataModel,
} from '@snaplet/sdk/cli'
import { display } from '~/lib/display.js'
import { config } from '~/lib/config.js'
import { fetchShapePredictions } from '~/commands/generate/lib/fetchShapePredictions.js'
import { getAliasedDataModel } from './getAliasedDataModel.js'
import { fetchShapeExamples } from '~/commands/generate/lib/fetchShapeExamples.js'

export async function createGenerateClientContext(
  sourceDatabaseUrl: string,
  structure: IntrospectedStructure,
  outputDir?: string | undefined
) {
  const initResult = await config.init()

  if (initResult.ok) {
    const selectedTables = await getSelectedTables({
      config,
      introspection: structure,
    })
    structure = filterSelectedTables({
      introspection: structure,
      selectedTables,
    })
  }

  let dataModel = introspectionToDataModel(structure)

  if (initResult.ok) {
    const seedConfig = await config.getSeed()
    dataModel = await getAliasedDataModel(dataModel, seedConfig?.alias)
  }

  const fingerprint = await generateDefaultFingerprint(
    sourceDatabaseUrl,
    dataModel
  )

  let shapePredictions: TableShapePredictions[] = []
  let shapeExamples: { shape: string; examples: string[] }[] = []

  const isLoggedIn = Boolean((await config.getSystem()).accessToken)

  if (!isLoggedIn) {
    display(`
For the best AI-enhanced data generation experience, create a free Snaplet account and login with: **snaplet auth login**.

Snaplet uses details about your database to improve our generation results.`)
  }

  if (isLoggedIn) {
    shapePredictions = await fetchShapePredictions(dataModel)
    shapeExamples = await fetchShapeExamples(shapePredictions)
  }

  return {
    dataModel,
    outputDir,
    introspection: structure,
    shapePredictions,
    shapeExamples,
    fingerprint,
  }
}
