import fs from 'fs-extra'
import path from 'path'
import { z, ZodError } from 'zod'

import { getCopycat } from '../../getCopycat.js'
import { findProjectPath, SNAPLET_CONFIG_FILENAME } from '../../paths.js'
import { importGenerateTransform } from '../../transform.js'
import { importGenerateTransform as importGenerateTransformV2 } from '~/v2/transform.js'
import { subsetConfigSchema } from './subsetConfig.js'
import { TransformConfigFn } from './transformConfig.js'
import { introspectConfigSchema } from './introspectConfig.js'
import { loadModule } from '../loadModule.js'

export const snapletConfigSchema = z.object({
  transform: z.function(),
  subset: subsetConfigSchema.optional(),
  introspect: introspectConfigSchema.optional(),
  override: z.record(z.any()).optional(),
})

export type SnapletConfig = z.infer<typeof snapletConfigSchema> & {
  transform: TransformConfigFn
}

export function parseSnapletConfig(config: Record<string, unknown>) {
  try {
    return snapletConfigSchema.parse(config)
  } catch (e) {
    if (e instanceof ZodError) {
      throw new Error(`Could not parse snaplet config: ${e.message}`)
    }
    throw e
  }
}

export const SNAPLET_CONFIG_DEFAULTS = `export const transform = () => ({})`

export const createSnapletConfig = async (
  filepath: string,
  source: string
): Promise<SnapletConfig> => {
  await importGenerateTransform()
  await importGenerateTransformV2()

  const copycat = await getCopycat()

  const deps: Record<string, unknown> = {
    '@snaplet/copycat': copycat,
    '@snaplet/copycat/locales/en': await import(
      '@snaplet/copycat/dist/locales/en'
    ),
    snaplet: { defineConfig: (config: any) => config },
  }

  let snapletConfig = loadModule<
    SnapletConfig & { default?: SnapletConfig; config?: SnapletConfig }
  >(filepath, {
    source,
    require: (name) =>
      name === '@snaplet/copycat/next'
        ? require('@snaplet/copycat/next')
        : null,
    cache: deps,
  })

  const { config: exportsConfig, default: exportsDefault } = snapletConfig

  const transform =
    snapletConfig.transform ?? exportsConfig ?? exportsDefault ?? snapletConfig

  snapletConfig = {
    ...snapletConfig,
    transform,
  }

  return parseSnapletConfig(snapletConfig) as SnapletConfig
}

export const getSnapletConfigFromSource = async (
  filepath: string,
  source: string
) => {
  if (source.trim() === '') {
    source = SNAPLET_CONFIG_DEFAULTS
  }

  return {
    source,
    config: await createSnapletConfig(filepath, source),
  }
}

export const getSnapletConfig = async (
  filename: string = SNAPLET_CONFIG_FILENAME
): Promise<{
  filepath: string
  source: string
  config: SnapletConfig
}> => {
  const projectPath = findProjectPath()

  if (!projectPath) {
    throw new Error('Could not find project path.')
  }

  const filepath = path.join(projectPath, filename)

  let source = ''
  if (await fs.pathExists(filepath)) {
    source = await fs.readFile(filepath, 'utf8')
  }

  return {
    filepath,
    ...(await getSnapletConfigFromSource(filepath, source)),
  }
}
