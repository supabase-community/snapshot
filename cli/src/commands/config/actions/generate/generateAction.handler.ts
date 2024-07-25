import {
  IntrospectedStructure,
  introspectionToDataModel,
  introspectDatabaseV3,
  withDbClient,
  getSelectedTables,
  filterSelectedTables,
} from '@snaplet/sdk/cli'
import path from 'path'

import {
  actGenerateTransform,
  actGenerateTypeDefs,
  actGenerateRSA,
  actGenerateDataClientTypeDefs,
} from '~/components/generate.js'
import { needs } from '~/components/needs/index.js'
import { initConfigOrExit } from '~/lib/initConfigOrExit.js'
import { activity } from '~/lib/spinner.js'

import { CommandOptions } from './generateAction.types.js'
import { xdebugConfigGenerate } from '../../debugConfig.js'
import { ConnectionString } from '@snaplet/sdk/cli'
import { getSentry } from '~/lib/sentry.js'
import { getAliasedDataModel } from '~/lib/getAliasedDataModel.js'

function getRelativePath(abs: string, base: string) {
  return abs.slice((base! + path.sep).length)
}

export async function generateConfigTypesDefinitions(props: {
  structure: IntrospectedStructure
  paths: Awaited<ReturnType<typeof needs.projectPathsV2>>
  dryRun: boolean
  connString?: string
  shouldGenerateForSeed?: boolean
}) {
  const { structure, paths, dryRun, shouldGenerateForSeed = true } = props

  if (shouldGenerateForSeed) {
    try {
      xdebugConfigGenerate('Generating typedefs - Getting introspection...')
      const { config } = await initConfigOrExit()
      const selectedTables = await getSelectedTables({
        config,
        introspection: structure,
      })
      const rawDataModel = introspectionToDataModel(
        filterSelectedTables({
          introspection: structure,
          selectedTables,
        })
      )
      const seedConfig = await config.getSeed()
      const dataModel = await getAliasedDataModel(
        rawDataModel,
        seedConfig?.alias
      )
      xdebugConfigGenerate(
        `Generating typedefs - Data model result: ${JSON.stringify(
          dataModel,
          null,
          2
        )}`
      )
      const clientTypeDefsPath = path.join(
        path.dirname(paths.transformTypeDef),
        'snaplet-client.d.ts'
      )

      await actGenerateDataClientTypeDefs({
        dataModel,
        rawDataModel,
        filePath: clientTypeDefsPath,
        relativeFilePath: getRelativePath(clientTypeDefsPath, paths.base),
        dryRun,
      })
    } catch (e) {
      const Sentry = await getSentry()
      Sentry.captureException(e, {
        tags: {
          type: 'generateConfigTypesDefinitions client',
        },
      })
      console.log('Error generating client typedefs: ', e)
      console.log(
        'We have been notified of the error. This might be caused by an issue with your database schema and will impact the type definition of the generate in the snaplet.config.ts file.'
      )
    }
  }
  try {
    await actGenerateTypeDefs(
      structure,
      paths.transformTypeDef,
      getRelativePath(paths.transformTypeDef, paths.base),
      dryRun
    )
  } catch (e) {
    const Sentry = await getSentry()
    Sentry.captureException(e, {
      tags: {
        type: 'generateConfigTypesDefinitions config',
      },
    })
    console.log('Error generating typedefs: ', e)
    console.log(
      'We have been notified of the error. This might be caused by an issue with your database schema and will impact the type definition of configuration the snaplet.config.ts file.'
    )
  }
}

export async function handler({
  dryRun,
  type,
  connectionString: rawConnectionString,
}: CommandOptions) {
  let connString: ConnectionString

  if (rawConnectionString) {
    connString = new ConnectionString(rawConnectionString)
    await needs.databaseConnection(connString)
  } else {
    connString = await needs.sourceDatabaseUrl()
  }

  xdebugConfigGenerate(
    `Generating config - Connection string: ${connString.toScrubbedString()}`
  )
  await needs.databaseConnection(connString)
  const paths = await needs.projectPathsV2({ create: true })
  const act = activity('Database structure', 'Instrospecting...')
  const structure = await withDbClient(introspectDatabaseV3, {
    connString: connString.toString(),
  })
  xdebugConfigGenerate(
    `Generating config - Introspection result:
    ${JSON.stringify(structure, null, 2)}`
  )
  act.done()

  if (type.includes('typedefs')) {
    await generateConfigTypesDefinitions({
      connString: connString.toString(),
      structure,
      paths,
      dryRun,
    })
  }

  if (type.includes('transform')) {
    act.info('Generate transform config...')
    const structure = await withDbClient(introspectDatabaseV3, {
      connString: connString.toString(),
    })
    await actGenerateTransform(
      structure,
      paths.snapletConfig,
      dryRun
    )
    act.done()
  }

  if (type.includes('keys')) {
    xdebugConfigGenerate('Generating RSA keys...')
    await actGenerateRSA(
      dryRun,
      paths.privateKey,
      getRelativePath(paths.privateKey, paths.base)
    )
  }
}
