import { Configuration, IntrospectedStructure } from '@snaplet/sdk/cli'

import {
  pgDump,
  scrub,
  scrubError,
  getPgDumpFlagsAndPatches,
  removeExtensionsFromDump,
  computePgDumpOptions,
} from './pgDump.js'

const DEFAULT_STRUCTURE: IntrospectedStructure = {
  schemas: ['public', 'pgboss'],
  tables: [],
  extensions: [
    {
      name: 'plpgsql',
      version: '1.0',
      schema: 'pg_catalog',
    },
    {
      name: 'queue',
      version: '1.0',
      schema: 'pgboss',
    },
  ],
  enums: [],
  indexes: [],
  server: {
    version: '14.4',
  },
}
const DEFAULT_FLAGS = [
  '--schema-only',
  '--no-password',
  '--no-privileges',
  '--no-owner',
  '--verbose',
]
const DUMP = `
--
-- PostgreSQL database dump
--

-- Dumped from database version 14.4
-- Dumped by pg_dump version 14.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: queue; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS queue WITH SCHEMA pgboss;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
`

test("getPgDumpFlagsAndPatches doesn't add flags if schemaConfigs is empty", async () => {
  const config = new Configuration()
  await config.init(
    `import {defineConfig} from 'snaplet'; export default defineConfig({})`
  )

  const schemasConfig = await config.getSchemas()
  const { flags } = getPgDumpFlagsAndPatches(
    DEFAULT_STRUCTURE,
    schemasConfig,
    computePgDumpOptions([], [], DEFAULT_STRUCTURE, schemasConfig)
  )

  expect(flags).toEqual(DEFAULT_FLAGS)
})

test('getPgDumpFlagsAndPatches add exclude-schema flags', async () => {
  const config = new Configuration()
  await config.init(
    `import {defineConfig} from 'snaplet'; export default defineConfig({select: { public: false, pgboss: false } })`
  )

  const schemasConfig = await config.getSchemas()
  const { flags } = getPgDumpFlagsAndPatches(
    DEFAULT_STRUCTURE,
    schemasConfig,
    computePgDumpOptions([], [], DEFAULT_STRUCTURE, schemasConfig)
  )

  expect(flags).toEqual([
    ...DEFAULT_FLAGS,
    '--exclude-schema=public',
    '--exclude-schema=pgboss',
    '--extension=plpgsql',
  ])
})

test('getPgDumpFlagsAndPatches include all extensions explicitly when excluding schemas', async () => {
  const config = new Configuration()
  await config.init(
    `import {defineConfig} from 'snaplet'; export default defineConfig({select: { public: false} })`
  )

  const schemasConfig = await config.getSchemas()
  const { flags } = getPgDumpFlagsAndPatches(
    DEFAULT_STRUCTURE,
    schemasConfig,
    computePgDumpOptions([], [], DEFAULT_STRUCTURE, schemasConfig)
  )
  expect(flags).toEqual([
    ...DEFAULT_FLAGS,
    '--exclude-schema=public',
    '--extension=plpgsql',
    '--extension=queue',
  ])
})

test('getPgDumpFlagsAndPatches dont include --extension flag on pg version lower than 14', async () => {
  const config = new Configuration()
  await config.init(
    `import {defineConfig} from 'snaplet'; export default defineConfig({select: { public: false} })`
  )

  const schemasConfig = await config.getSchemas()
  const { flags, patches } = getPgDumpFlagsAndPatches(
    {
      ...DEFAULT_STRUCTURE,
      server: {
        version: '12.2',
      },
    },
    schemasConfig,
    computePgDumpOptions([], [], DEFAULT_STRUCTURE, schemasConfig)
  )

  expect(flags).toEqual([...DEFAULT_FLAGS, '--exclude-schema=public'])
  expect(patches.removeExtensions).toEqual([])
})

test('getPgDumpFlagsAndPatches patch dump on pg version lower than 14 when extensions are excluded', async () => {
  const config = new Configuration()
  await config.init(
    `import {defineConfig} from 'snaplet'; export default defineConfig({select: { pgboss: false } })`
  )

  const schemasConfig = await config.getSchemas()
  const { flags, patches } = getPgDumpFlagsAndPatches(
    {
      ...DEFAULT_STRUCTURE,
      server: {
        version: '12.2',
      },
    },
    schemasConfig,
    computePgDumpOptions([], [], DEFAULT_STRUCTURE, schemasConfig)
  )

  expect(flags).toEqual([...DEFAULT_FLAGS, '--exclude-schema=pgboss'])
  expect(patches.removeExtensions).toEqual(['queue'])
})

test('removeExtensionsFromDump patch dump on pg version lower than 14 when extensions are excluded', async () => {
  const stdout = removeExtensionsFromDump(DUMP, ['queue'])

  expect(stdout).toMatchInlineSnapshot(`
    "
    --
    -- PostgreSQL database dump
    --

    -- Dumped from database version 14.4
    -- Dumped by pg_dump version 14.4

    SET statement_timeout = 0;
    SET lock_timeout = 0;
    SET idle_in_transaction_session_timeout = 0;
    SET client_encoding = 'UTF8';
    SET standard_conforming_strings = on;
    SELECT pg_catalog.set_config('search_path', '', false);
    SET check_function_bodies = false;
    SET xmloption = content;
    SET client_min_messages = warning;
    SET row_security = off;

    --
    -- Name: queue; Type: EXTENSION; Schema: -; Owner: -
    --

    -- CREATE EXTENSION IF NOT EXISTS queue WITH SCHEMA pgboss;

    --
    -- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
    --

    CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
    "
  `)
})

test('pgDump throws', async () => {
  const res = pgDump(
    'postgresql://@127.0.0.1/_bad_connection_string',
    DEFAULT_STRUCTURE,
    {}
  )
  await expect(res).rejects.toThrow()
})

test('scrub replaces multiple occurances', () => {
  expect(scrub('the password is password', 'password')).toEqual(
    'the <scrubbed> is <scrubbed>'
  )
})

test('scrub caters for empty values', () => {
  expect(scrub('the password is ', '')).toEqual('the password is ')
  expect(scrub('the  password is  ', ' ')).toEqual('the  password is  ')
})

test('scrub works with special characters', () => {
  expect(scrub('the password is *A', '*A')).toEqual(
    'the password is <scrubbed>'
  )
})

test('scrubbing errors scrubs error props', () => {
  const someError = new Error('foo secret bar') as any
  someError.somewhere = 'between the secret silence'

  const scrubbedError = new Error('foo <scrubbed> bar') as any
  const result = scrubError(someError, 'secret') as any
  expect(result.message).toEqual('foo <scrubbed> bar')
  expect(result.stack).toContain('<scrubbed>')
  expect(result.somewhere).toEqual('between the <scrubbed> silence')
  expect(scrubError(someError, 'secret')).toEqual(scrubbedError)
})
