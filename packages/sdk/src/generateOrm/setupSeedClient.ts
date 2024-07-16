import { readFingerprint } from './readFingerprint.js'
import { SeedClientBase, SeedClientBaseOptions } from './client.js'
import { cloneDeep, merge } from 'lodash'
import { Configuration } from '~/config/config.js'
import { Fingerprint } from './dataModel/fingerprint.js'

export const setupSeedClient = async <
  Options extends SeedClientBaseOptions,
  SeedClient extends SeedClientBase,
>(
  setupFn: (options?: Options) => SeedClient | Promise<SeedClient>,
  config?: Configuration,
  inputOptions?: Options
): Promise<SeedClient> => {
  const options = { ...inputOptions } as Options
  const fingerprint = await computeFingerprint(config, options)
  options.fingerprint = fingerprint

  const seed = await setupFn(options)

  await seed.$syncDatabase()
  seed.$reset()

  return seed
}

const computeFingerprint = async (
  config?: Configuration,
  options?: SeedClientBaseOptions
): Promise<Fingerprint> => {
  const fingerprintJson = cloneDeep(readFingerprint())
  const configFingerprint = cloneDeep(
    (await config?.getSeed())?.fingerprint ?? {}
  )
  const optionsFingerprint = cloneDeep(options?.fingerprint)

  const fingerprint = merge(
    {},
    fingerprintJson,
    configFingerprint,
    optionsFingerprint
  )

  return fingerprint
}
