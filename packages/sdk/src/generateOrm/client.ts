import { DataModel } from './dataModel/dataModel.js'
import type { Fingerprint } from './dataModel/fingerprint.js'
import { Plan, PlanOptions } from './plan/plan.js'
import { ClientState, PlanInputs, UserModels } from './plan/types.js'
import { Store } from './store.js'
import { mergeUserModels } from './utils/mergeUserModels.js'
import { generateUserModelsSequences } from './utils/generateUserModelsSequences.js'
import { getInitialConstraints } from './constraints.js'
import { Configuration } from '~/config/config.js'

export type SeedClientBaseOptions = {
  config?: Configuration
  models?: UserModels
  fingerprint?: Fingerprint
}

export class SeedClientBase {
  state: ClientState
  dataModel: DataModel
  readonly runStatements: (statements: string[]) => Promise<void>
  readonly initialUserModels: UserModels
  readonly userModels: UserModels
  readonly fingerprint: Fingerprint

  constructor(props: {
    dataModel: DataModel
    userModels: UserModels
    runStatements: (statements: string[]) => Promise<void>
    options?: SeedClientBaseOptions
  }) {
    this.runStatements = props.runStatements
    this.dataModel = props.dataModel
    this.initialUserModels = mergeUserModels(
      props.userModels,
      props.options?.models ?? {}
    )

    this.fingerprint = props.options?.fingerprint ?? {}

    this.userModels = mergeUserModels(
      props.userModels,
      props.options?.models ?? {}
    )
    this.state = SeedClientBase.getInitialState({
      dataModel: props.dataModel,
      userModels: this.userModels,
      initialUserModels: this.initialUserModels,
    })

    Object.keys(props.dataModel.models).forEach((model) => {
      // @ts-expect-error dynamic method creation
      this[model] = (inputs: PlanInputs['inputs'], options?: PlanOptions) => {
        return new Plan({
          ctx: this.state,
          runStatements: props.runStatements,
          dataModel: props.dataModel,
          userModels: mergeUserModels(this.userModels, options?.models ?? {}),
          fingerprint: this.fingerprint,
          plan: {
            model,
            inputs,
          },
          options,
        })
      }
    })
  }

  static getInitialState(props: {
    dataModel: DataModel
    userModels: UserModels
    initialUserModels?: UserModels
  }) {
    const initialUserModels = props.initialUserModels ?? props.userModels
    const constraints = getInitialConstraints(props.dataModel)
    return {
      constraints,
      store: new Store(props.dataModel),
      seeds: {},
      sequences: generateUserModelsSequences(
        initialUserModels,
        props.userModels,
        props.dataModel
      ),
    }
  }

  get $store() {
    return this.state.store._store
  }

  $reset() {
    this.state = SeedClientBase.getInitialState({
      dataModel: this.dataModel,
      userModels: this.userModels,
      initialUserModels: this.initialUserModels,
    })
  }

  async $resetDatabase() {}

  async $syncDatabase() {}

  async $transaction(_cb: (snaplet: SeedClientBase) => Promise<void>) {}
}
