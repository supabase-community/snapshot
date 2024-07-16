import type { UserModels } from '../plan/types.js'
import type { DataModel } from '../dataModel/dataModel.js'
import { SeedClientBase, SeedClientBaseOptions } from '../client.js'
import { setupSeedClient } from '../setupSeedClient.js'
import { Configuration } from '~/config/config.js'

export function getSeedClient(
  dataModel: DataModel,
  userModels: UserModels,
  config?: Configuration
) {
  class SeedClient extends SeedClientBase {
    constructor(
      public statementsStore: string[],
      public options?: SeedClientBaseOptions
    ) {
      super({
        dataModel,
        userModels,
        runStatements: async (statements: string[]) => {
          statementsStore.push(...statements)
        },
        options,
      })
    }

    async $transaction(cb: (seed: SeedClient) => Promise<void>) {
      await cb(await createSeedClient(this.statementsStore, this.options))
    }
  }

  const createSeedClient = async (
    statementsStore: string[],
    options?: SeedClientBaseOptions
  ) =>
    setupSeedClient(
      (options) => new SeedClient(statementsStore, options),
      config,
      options
    )

  return createSeedClient
}
