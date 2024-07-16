import path from 'path'
import { detectMigrationTool } from './detectMigrationTool.js'

test('detect migration tool in non-monorepo project', async () => {
  const tool = await detectMigrationTool(
    path.join(__dirname, 'fixtures', 'non-monorepo-project')
  )

  expect(tool).toMatchObject({
    envVariable: 'DATABASE_URL',
    path: expect.stringContaining(
      'packages/sdk/src/generate/fixtures/non-monorepo-project'
    ),
    provider: 'prisma',
  })
})

test('detect migration tool in monorepo project', async () => {
  const tool = await detectMigrationTool(
    path.join(__dirname, 'fixtures', 'monorepo-project')
  )

  expect(tool).toMatchObject({
    envVariable: 'DB_URL',
    path: expect.stringContaining(
      'packages/sdk/src/generate/fixtures/monorepo-project'
    ),
    provider: 'drizzle',
  })
})
