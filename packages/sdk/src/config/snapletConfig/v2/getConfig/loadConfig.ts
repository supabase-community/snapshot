import { JsonNull } from '~/pgTypes.js'
import { getCopycat } from '../../../../getCopycat.js'
import { type SnapletConfig } from './parseConfig.js'
import { loadModule } from '~/config/loadModule.js'

const getFakerDeps = async () => {
  let deps = {}

  // context(justinvdm, 2 Aug 2023): If we import faker, we get obscure transient timeouts
  // in our e2e tests when using the pkg-based binary. As a workaround, we use a CI_TESTS flag
  // in our e2e tests on CI. Then, we conditionally import faker over here when CI_TESTS is falsy.
  // This way, esbuild removes the faker import when CI_TESTS=1 so that our pkg build does not contain
  // these imports in our cli e2e tests
  process.env.CI_TESTS ||
    (deps = {
      '@faker-js/faker': {
        faker: (await import('@faker-js/faker/locale/en')).faker,
        fakerDE: (await import('@faker-js/faker/locale/de')).faker,
      },
    })

  return deps
}

export async function loadConfig(filepath: string, source: string) {
  const deps: Record<string, unknown> = {
    '@snaplet/copycat': await getCopycat(),
    snaplet: {
      defineConfig: (config: any) => config,
      jsonNull: new JsonNull(),
    },
    ...(await getFakerDeps()),
  }

  const result = loadModule<{ default?: SnapletConfig }>(filepath, {
    source,
    cache: deps,
    require: (name) =>
      name === '@snaplet/copycat/next'
        ? require('@snaplet/copycat/next')
        : null,
  })
  return result?.default ?? result ?? {}
}
