import { execQueryNext, withDbClient } from '~/db/client.js'
import {
  ConnectionString,
  introspectDatabaseV3,
  introspectionToDataModel,
} from '~/exports/api.js'
import { createTestDb } from '~/testing.js'
import {
  GenerateExampleSeedScriptContext,
  generateExampleSeedScriptContent,
} from './generateExampleSeedScript.js'

const computeContext = async (
  connectionString: ConnectionString
): Promise<GenerateExampleSeedScriptContext> => {
  const introspection = await withDbClient(introspectDatabaseV3, {
    connString: connectionString.toString(),
  })
  const dataModel = introspectionToDataModel(introspection)

  return {
    introspection,
    dataModel,
  }
}

describe('generateExampleSeedScriptContent', () => {
  test('non-empty db', async () => {
    const connectionString = await createTestDb()

    await execQueryNext(
      `
      CREATE TABLE "User" (
        "id" text not null
      );

      ALTER TABLE "User" ADD CONSTRAINT "User_pkey" PRIMARY KEY ("id");
    `,
      connectionString
    )

    const result = generateExampleSeedScriptContent(
      await computeContext(connectionString)
    )

    expect(result).toContain("import { createSeedClient } from '@snaplet/seed'")
    expect(result).toContain('const seed = await createSeedClient')
    expect(result).toContain('seed.User(x => x(3))')
  })

  test('empty db', async () => {
    const connectionString = await createTestDb()

    const result = generateExampleSeedScriptContent(
      await computeContext(connectionString)
    )

    expect(result).toContain("import { createSeedClient } from '@snaplet/seed'")
    expect(result).toContain('const seed = await createSeedClient(')
  })
})
