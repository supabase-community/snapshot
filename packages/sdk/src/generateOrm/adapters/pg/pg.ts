import type { UserModels } from '../../plan/types.js'
import type { DataModel } from '../../dataModel/dataModel.js'
import { SeedClientBase, SeedClientBaseOptions } from '../../client.js'
import os from 'os'
import { DatabaseClient } from '~/db/client.js'
import { truncateTables } from '~/db/tools.js'
import { introspectDatabaseV3 } from '~/exports/api.js'
import { introspectionToDataModel } from '../../dataModel/dataModel.js'
import { updateDataModelSequences } from '../../dataModel/updateDataModelSequences.js'
import { withClientDefault } from './withClientDefault.js'
import { Configuration } from '~/config/config.js'
import { setupSeedClient } from '~/generateOrm/setupSeedClient.js'

export type SeedClientOptions = SeedClientBaseOptions & {
  dryRun?: boolean
  client?: DatabaseClient
}

export type WithClient = (
  fn: (client: DatabaseClient) => unknown
) => Promise<unknown>

export function getSeedClient(
  dataModel: DataModel,
  userModels: UserModels,
  config?: Configuration
) {
  class SeedClient extends SeedClientBase {
    readonly options: SeedClientOptions
    readonly dryRun: boolean
    readonly withClient: WithClient

    constructor(withClient: WithClient, options?: SeedClientOptions) {
      super({
        dataModel,
        userModels,
        runStatements: async (statements: string[]) => {
          if (!this.dryRun) {
            await withClient((client) => client.query(statements.join(';')))
          } else {
            console.log(statements.join(`;${os.EOL}`) + ';')
          }
        },
        options,
      })

      this.dryRun = options?.dryRun ?? false
      this.options = options ?? {}
      this.withClient = withClient
    }

    async $resetDatabase() {
      if (!this.dryRun) {
        // We extract the list of tables to truncate from the data model.
        // Since the dataModel generation is driven by the snaplet.config.ts select field
        // this will ensure that we only truncate tables that are selected and available to the
        // dataModel / seed SeedClient
        const tablesToTruncate = Object.values(this.dataModel.models)
          .filter((model) => Boolean(model.schemaName))
          .map((model) => ({
            schema: model.schemaName!,
            table: model.tableName,
          }))

        await this.withClient((client) =>
          truncateTables(client, tablesToTruncate)
        )
      }
    }

    async $syncDatabase(): Promise<void> {
      await this.withClient(async (client) => {
        const nextDataModel = await fetchDataModel(client)
        this.dataModel = updateDataModelSequences(this.dataModel, nextDataModel)
      })
    }

    async $transaction(cb: (seed: SeedClient) => Promise<void>) {
      await cb(await createSeedClient(this.options))
    }
  }

  const createSeedClient = async (options?: SeedClientOptions) => {
    let withClient: WithClient = withClientDefault

    if (options?.client) {
      const { client } = options
      withClient = async (fn) => await fn(client)
    }

    return await setupSeedClient(
      (options) => new SeedClient(withClient, options),
      config,
      options
    )
  }

  return createSeedClient
}

const fetchDataModel = async (client: DatabaseClient) => {
  const introspection = await introspectDatabaseV3(client)
  return introspectionToDataModel(introspection)
}
