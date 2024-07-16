import {
  ConnectionString,
  calculateIncludedExtensions,
  calculateIncludedSchemas,
  calculateIncludedTablesStructure,
  fetchForbiddenSchemas,
  fetchForbiddenTablesIds,
  schemaIsModified,
  withDbClient,
  xdebug,
} from '@snaplet/sdk/cli'
import type {
  Configuration,
  DatabaseClient,
  IntrospectedStructure,
} from '@snaplet/sdk/cli'
import execa from 'execa'
import { getPgDumpProgress } from './pgDumpProgress.js'
import { OnChangeHandler } from './subsetV3/steps/emitterToOnUpdate.js'

const xd = xdebug.extend('capture').extend('pg_dump')

type SchemasConfig = Awaited<ReturnType<Configuration['getSchemas']>>

export function computePgDumpOptions(
  forbiddenSchemasNames: string[],
  forbiddenTableIds: string[],
  structure: {
    tables: Array<{ name: string; schema: string }>
    schemas: string[]
    extensions: Array<{ name: string; schema: string }>
  },
  schemasConfig: SchemasConfig
) {
  // We get the schemas and tables that we have access to but the user has chosen to exclude
  const tablesToCopy = calculateIncludedTablesStructure(
    structure['tables'],
    schemasConfig
  )
  const tablesToCopyMap = new Map(
    tablesToCopy.map((t) => [t.id ?? `${t.schema}.${t.name}`, t])
  )
  const excludedTables = structure['tables'].filter(
    (t) => !tablesToCopyMap.has(`${t.schema}.${t.name}`)
  )
  const schemasToCopy = calculateIncludedSchemas(
    structure['schemas'],
    schemasConfig
  )
  const schemasToExclude = structure['schemas'].filter(
    (s) => !schemasToCopy.includes(s)
  )
  const extensions = calculateIncludedExtensions(
    structure['extensions'],
    schemasConfig
  )
  const excludedSchemas = Array(
    ...new Set([...forbiddenSchemasNames, ...schemasToExclude])
  )
  const excludedTablesIds = Array(
    ...new Set([
      ...forbiddenTableIds,
      ...excludedTables.map((t) => `${t.schema}.${t.name}`),
    ])
  )
  const includedExtensionsNames = Array(
    ...new Set(extensions.map((e) => `${e.name}`))
  )
  return {
    excludedSchemas,
    excludedTablesIds,
    includedExtensionsNames,
  }
}
async function getPgDumpOptions(
  client: DatabaseClient,
  structure: {
    tables: Array<{ name: string; schema: string }>
    schemas: string[]
    extensions: Array<{ name: string; schema: string }>
  },
  schemasConfig: SchemasConfig
) {
  // We get the schemas and tables that we have no access to
  const forbiddenSchemas = await fetchForbiddenSchemas(client)
  const forbiddenTablesIds = await fetchForbiddenTablesIds(client)
  return computePgDumpOptions(
    forbiddenSchemas,
    forbiddenTablesIds,
    structure,
    schemasConfig
  )
}

export function getPgDumpFlagsAndPatches(
  structure: IntrospectedStructure,
  schemasConfig: SchemasConfig,
  options: Awaited<ReturnType<typeof getPgDumpOptions>>
) {
  let extraFlags = ['--no-privileges', '--no-owner', '--verbose']

  const patches = {
    removeExtensions: [] as string[],
  }

  xd('schemas configuration %o', schemasConfig)
  // If the schema is modified or we detect forbidden schemas and tables, we have to set explicit flags to exclude schemas and extensions
  if (
    schemaIsModified(schemasConfig) ||
    options.excludedSchemas.length > 0 ||
    options.excludedTablesIds.length > 0
  ) {
    xd('some schemas are modified')

    let includedExtensionsFlags = options.includedExtensionsNames.map(
      (e) => `--extension=${e}`
    )
    if (parseInt(structure.server.version) < 14) {
      includedExtensionsFlags = []
      patches.removeExtensions = structure.extensions
        .filter((e) => {
          const schemaIsExcluded = options.excludedSchemas.includes(e.schema)
          const extensionIsExcluded =
            options.includedExtensionsNames.includes(`${e.name}`) === false
          return schemaIsExcluded || extensionIsExcluded
        })
        .map((e) => `${e.name}`)
    }

    extraFlags = [
      ...extraFlags,
      ...options.excludedSchemas.map((schema) => `--exclude-schema=${schema}`),
      ...options.excludedTablesIds.map((table) => `--exclude-table=${table}`),
      ...includedExtensionsFlags,
    ]
  }

  return {
    flags: ['--schema-only', '--no-password', ...extraFlags],
    patches,
  }
}

export function removeExtensionsFromDump(
  dump: string,
  excludedExtensions: string[]
) {
  return dump
    .split('\n')
    .map((line) => {
      if (line.startsWith('CREATE EXTENSION')) {
        const matchResult =
          /CREATE EXTENSION IF NOT EXISTS (?<extensionName>.+) WITH SCHEMA/.exec(
            line
          )
        if (
          matchResult?.groups?.extensionName &&
          excludedExtensions.includes(matchResult.groups.extensionName)
        ) {
          return `-- ${line}`
        }
      }
      return line
    })
    .join('\n')
}

export const pgDump = async (
  rawConnectionString: string,
  structure: IntrospectedStructure,
  schemasConfig: SchemasConfig,
  onChange?: OnChangeHandler
) => {
  const connectionString = new ConnectionString(rawConnectionString)
  const safeConnectionString = connectionString
    .toString()
    .replace('pg://', 'postgresql://')

  const dumpOptions = await withDbClient(
    (client) => getPgDumpOptions(client, structure, schemasConfig),
    { connString: rawConnectionString }
  )
  const { flags, patches } = getPgDumpFlagsAndPatches(
    structure,
    schemasConfig,
    dumpOptions
  )

  xd(
    'Running: "pg_dump %s"',
    [...flags, connectionString.toScrubbedString()].join(' ')
  )

  const subprocess = execa('pg_dump', [...flags, safeConnectionString], {
    all: true,
  })

  subprocess.stderr?.on('data', (chunk) => {
    const t = chunk.toString().trim()
    if (onChange && t.startsWith('pg_dump:')) {
      const progress = getPgDumpProgress(t)
      if (progress) {
        void onChange('progress', progress)
      }
    }
  })

  try {
    let { stdout } = await subprocess
    if (patches.removeExtensions.length > 0) {
      stdout = removeExtensionsFromDump(stdout, patches.removeExtensions)
    }
    return stdout
  } catch (e: any) {
    if (e.stderr) {
      const errorScrubbed = scrubError(e, connectionString.password)
      throw new Error(
        `pg_dump failed with error: ${errorScrubbed}\n\n${scrub(
          e.stderr,
          connectionString.password
        )}`
      )
    }
    throw e
  }
}

const replaceAll = (
  target: string | null | undefined,
  match: string,
  replacement: string
): string => {
  let nextTarget = target || ''
  let prevTarget

  do {
    prevTarget = nextTarget
    nextTarget = nextTarget.replace(match, replacement)
  } while (nextTarget !== prevTarget)

  return nextTarget
}

export const scrub = (message: string, secret: string) => {
  // context(justinvdm, 19 May 2022): If the secret is just whitespace or an empty string, then our choices are:
  // * (a) use <scrubbed> for every whitespace occurence or after each character respectively
  //   * => the secret can be inferred as being whitespace or empty + we now have unreadable output
  // * (b) leave the message as is => the secret is no longer a secret
  // * (c) scrub the entire message => unfortunately we do not know the output anymore, but the secret is "safe"
  //
  // None of the options are good, but (c) is the arguably the least bad, so we're going with it.
  // Chances are, whitespace or an empty string would be things attackers would try anyways, but we can at least
  // cover ourselves as best we can this way.
  return secret.trim() === ''
    ? message
    : replaceAll(message, secret, '<scrubbed>')
}

const scrubObject = (input: Record<string, unknown>, secret: string) => {
  const result: Record<string, unknown> = {}

  for (const key of Object.keys(input)) {
    const value = input[key]

    if (typeof value === 'string') {
      result[key] = scrub(value, secret)
    } else {
      result[key] = value
    }
  }

  return result
}

export const scrubError = (error: Error, secret: string) => {
  const nextError = new Error()
  Object.assign(
    nextError,
    scrubObject(error as unknown as Record<string, unknown>, secret)
  )
  nextError.message = scrub(error.message, secret)
  nextError.stack = scrub(error.stack || '', secret)
  return nextError
}
