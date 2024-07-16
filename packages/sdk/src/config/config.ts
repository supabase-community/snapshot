import pMemoize, { pMemoizeClear } from 'p-memoize-cjs'

import { merge } from 'lodash'
import {
  ProjectConfig,
  getProjectConfig,
  saveProjectConfig,
} from './projectConfig/projectConfig.js'
import {
  getSystemConfig,
  saveSystemConfig,
  SystemConfig,
  updateSystemConfig,
} from './systemConfig/systemConfig.js'
import {
  SnapletConfig as SnapletConfigV2,
  subsetConfigV2Schema,
} from './snapletConfig/v2/getConfig/parseConfig.js'
import { getSource } from './snapletConfig/v2/getConfig/getSource.js'
import { getConfigFromSource } from './snapletConfig/v2/getConfig/getConfig.js'
import { DatabaseStoredSnapshotConfig } from '~/db/structure.js'
import { importGenerateTransform as importGenerateTransformV2 } from '~/v2/transform.js'
import {
  createTransformConfig,
  importGenerateTransform as importGenerateTransformV1,
} from '~/transform.js'
import { extractTransformationsStructure } from '~/transform/utils.js'
import { IntrospectedStructure } from '../db/introspect/introspectDatabase.js'
import { err, ok } from '~/result.js'
import { SnapletError, isError } from '~/errors.js'
import { SnapletParseConfigError } from './snapletConfig/v2/getConfig/errors.js'
import {
  SnapletCompileConfigError,
  SnapletExecuteConfigError,
} from './errors.js'

export type SnapletProjectConfig = SnapletConfigV2

interface ProjectSnapshotConfigLoader {
  snapletConfig: SnapletProjectConfig | null
  /*
   ** In charge of loading the project config for the snapshot
   ** Will return the SnapletProjectConfig accordingly
   */
  init(): Promise<SnapletProjectConfig>
  getSubsetConfig(): Promise<SnapletProjectConfig['subset']>
  getTransformConfig(): Promise<SnapletProjectConfig['transform']>
  getConfigSourceCode(): Promise<string>
  getSelectConfig(): Promise<SnapletProjectConfig['select']>
  getIntrospectConfig(): Promise<SnapletProjectConfig['introspect']>
}
class ProjectSnapshotConfigLoaderV2 implements ProjectSnapshotConfigLoader {
  snapletConfig: SnapletProjectConfig | null = null
  configOverride: Partial<SnapletProjectConfig> | null = null
  constructor(
    private readonly snapletConfigSource?: string,
    configOverride?: Partial<SnapletProjectConfig>
  ) {
    this.snapletConfig = null
    this.init = pMemoize(this.init)
    this.getSubsetConfig = pMemoize(this.getSubsetConfig)
    this.snapletConfigSource = snapletConfigSource
    this.configOverride = configOverride ?? null
  }
  async init() {
    // If we already loaded the config no need to do it again
    if (this.snapletConfig) {
      return this.snapletConfig
    }
    // This will try to load and parse the config from a transfom.ts file
    const snapletConfigV2Source = this.snapletConfigSource
      ? {
          source: this.snapletConfigSource,
          filename: '',
          filepath: '',
        }
      : getSource()
    await importGenerateTransformV2()
    // This is mantory otherwise the "fallback" tranformations are not defined
    // TODO: refactor the transforms avoid both this importGenerateTransform
    await importGenerateTransformV1()
    const configV2 = await getConfigFromSource(snapletConfigV2Source)
    this.snapletConfig = merge(configV2, this.configOverride ?? {})
    return this.snapletConfig
  }
  async getSubsetConfig() {
    const snapletConfig = await this.init()
    return snapletConfig.subset
  }
  async getTransformConfig() {
    const snapletConfig = await this.init()
    return snapletConfig.transform
  }
  async getSelectConfig() {
    const snapletConfig = await this.init()
    return snapletConfig.select
  }
  async getIntrospectConfig() {
    const snapletConfig = await this.init()
    return snapletConfig.introspect
  }
  async getConfigSourceCode() {
    return getSource()?.source ?? ''
  }
}

export class Configuration {
  configLoader: ProjectSnapshotConfigLoader | null
  constructor() {
    this.configLoader = null
    this.getSeed = pMemoize(this.getSeed)
    this.getProject = pMemoize(this.getProject)
    this.getSchemas = pMemoize(this.getSchemas)
    this.getSubset = pMemoize(this.getSubset)
    this.getSystem = pMemoize(this.getSystem)
    this.getTransform = pMemoize(this.getTransform)
    this.getSnapletSource = pMemoize(this.getSnapletSource)
    this.init = pMemoize(this.init)
  }

  async init(
    snapletConfigSource?: string,
    configOverride?: Partial<SnapletProjectConfig>
  ) {
    try {
      if (this.configLoader) {
        return ok(await this.configLoader.init())
      }
      this.configLoader = new ProjectSnapshotConfigLoaderV2(
        snapletConfigSource,
        configOverride
      )
      return ok(await this.configLoader.init())
    } catch (error) {
      if (isError(error)) {
        if (error.name === 'SnapletExecuteConfigError') {
          return err(error as SnapletExecuteConfigError)
        }
        if (error.name === 'SnapletCompileConfigError') {
          return err(error as SnapletCompileConfigError)
        }
        if (error.name === 'SnapletParseConfigError') {
          return err(error as SnapletParseConfigError)
        }
      }
      return err(new SnapletError('UNHANDLED_ERROR', { error }))
    }
  }

  getSnapletSource = async (transformFilename?: string) => {
    await this.init(transformFilename)
    return await this.configLoader?.getConfigSourceCode()
  }

  getSystem = async (
    config: string | undefined = undefined,
    shouldOverrideWithEnv = true
  ) => {
    return getSystemConfig(config, shouldOverrideWithEnv)
  }
  saveSystem = async (
    systemConfig: SystemConfig,
    systemConfigPath?: string
  ) => {
    saveSystemConfig(systemConfig, systemConfigPath)
    pMemoizeClear(this.getSystem)
  }
  updateSystem = async (
    systemConfig: Partial<SystemConfig>,
    systemConfigPath?: string
  ): Promise<SystemConfig> => {
    const nextConfig = updateSystemConfig(systemConfig, systemConfigPath)
    pMemoizeClear(this.getSystem)
    return nextConfig
  }

  clearSystem = () => {
    pMemoizeClear(this.getSystem)
  }

  getProject = async () => {
    return getProjectConfig()
  }
  saveProject = async (projectConfig: ProjectConfig) => {
    saveProjectConfig(projectConfig)
    pMemoizeClear(this.getProject)
  }
  clearProject = () => {
    pMemoizeClear(this.getProject)
  }

  getTransform = async () => {
    const transformConfig = await this.configLoader!.getTransformConfig()
    return transformConfig
  }

  getRuntimeTransform = async (structure: IntrospectedStructure) => {
    const transformConfig = await this.configLoader!.getTransformConfig()
    if (transformConfig) {
      const [options, transformations] =
        extractTransformationsStructure(transformConfig)
      return createTransformConfig(transformations, structure, options)
    }
    return createTransformConfig({}, structure)
  }

  getSubset = async (override?: DatabaseStoredSnapshotConfig['override']) => {
    const snapletConfig = await this.init()
    if (snapletConfig.ok === false) {
      throw snapletConfig.error
    }
    const mergedConfig = {
      ...snapletConfig.value.subset,
      ...override?.subset,
    }
    if (Object.keys(mergedConfig).length > 0) {
      return subsetConfigV2Schema.parse(mergedConfig)
    }
    return undefined
  }

  getIntrospect = async () => {
    const snapletConfig = await this.init()
    if (snapletConfig.ok === false) {
      throw snapletConfig.error
    }
    return snapletConfig.value.introspect
  }

  getSchemas = async () => {
    const snapletConfig = await this.init()
    if (snapletConfig.ok === false) {
      throw snapletConfig.error
    }
    return snapletConfig.value.select
  }

  getSeed = async () => {
    const snapletConfig = await this.init()
    if (snapletConfig.ok === false) {
      throw snapletConfig.error
    }
    return snapletConfig.value.seed
  }
}
