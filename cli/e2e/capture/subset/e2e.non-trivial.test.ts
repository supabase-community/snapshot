import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
  checkConstraints,
} from '../../../src/testing/index.js'
import fs from 'fs'
import fsExtra from 'fs-extra'
import path from 'path'

import { splitSchema } from '../../../src/commands/snapshot/actions/restore/lib/pgSchemaTools.js'

vi.setConfig({
  testTimeout: 10 * 60 * 1000,
})

const FIXTURES_DIR = path.resolve(__dirname, '../../../__fixtures__')

async function loadDbDumpFixture(
  // The dump must be a .sql file located into __fixtures__
  dumpName: string,
  connectionString: string
) {
  const fileContent = fs
    .readFileSync(path.join(FIXTURES_DIR, dumpName))
    .toString('utf-8')
  const queries = splitSchema(fileContent)
  for (const stmt of queries) {
    try {
      await execQueryNext(stmt, connectionString)
    } catch (e) {
      console.log(stmt)
      console.log(e)
      throw e
    }
  }
}

test('capturing and restoring a non-trivial database subsetting folders', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture(
    'non-trivial-database.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: true,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.folders',
          percent: 10,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)

  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
})
test('capturing and restoring a non-trivial database folders entrypoint', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture(
    'non-trivial-database.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      maxCyclesLoop: 10,
      keepDisconnectedTables: true,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.folders',
          where: "folders.id = 'd1533f47-afc9-4f98-aa74-c954fbec6000'",
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)

  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  const restoredProjectToUsers = await execQueryNext(
    'SELECT * FROM projects_to_users',
    targetConnectionString
  )
  const restoredFileVersions = await execQueryNext(
    'SELECT * FROM file_versions',
    targetConnectionString
  )
  const restoredTasks = await execQueryNext(
    'SELECT * FROM tasks',
    targetConnectionString
  )
  const restoredFiles = await execQueryNext(
    'SELECT * FROM files',
    targetConnectionString
  )
  const restoredFolders = await execQueryNext(
    'SELECT * FROM folders',
    targetConnectionString
  )
  const restoredUsers = await execQueryNext(
    'SELECT * FROM users',
    targetConnectionString
  )

  expect(restoredProjectToUsers.rowCount).toBe(37)
  expect(restoredFolders.rowCount).toBe(36)
  expect(restoredFileVersions.rowCount).toBe(41)
  expect(restoredFiles.rowCount).toBe(39)
  expect(restoredTasks.rowCount).toBe(22)
  expect(restoredUsers.rowCount).toBe(16)
})
test('capturing and restoring a non-trivial database projects entrypoint', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture(
    'non-trivial-database.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      maxCyclesLoop: 10,
      keepDisconnectedTables: true,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.projects',
          where: "projects.name = 'Tour Eiffel'",
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )

  const restoredProjectToUsers = await execQueryNext(
    'SELECT * FROM projects_to_users',
    targetConnectionString
  )
  const restoredFileVersions = await execQueryNext(
    'SELECT * FROM file_versions',
    targetConnectionString
  )
  const restoredFiles = await execQueryNext(
    'SELECT * FROM files',
    targetConnectionString
  )
  const restoredFolders = await execQueryNext(
    'SELECT * FROM folders',
    targetConnectionString
  )
  const restoredUsers = await execQueryNext(
    'SELECT * FROM users',
    targetConnectionString
  )

  expect(restoredProjectToUsers.rowCount).toBe(37)
  expect(restoredFileVersions.rowCount).toBe(41)
  expect(restoredFiles.rowCount).toBe(39)
  expect(restoredFolders.rowCount).toBe(39)
  expect(restoredUsers.rowCount).toBe(16)
})
test('capturing and restoring a non-trivial database user isolated entrypoint', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture(
    'non-trivial-database.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.users',
          where: "users.email = 'isolated@test.com'",
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  const restoredProjectToUsers = await execQueryNext(
    'SELECT * FROM projects_to_users',
    targetConnectionString
  )
  const restoredFileVersions = await execQueryNext(
    'SELECT * FROM file_versions',
    targetConnectionString
  )
  const restoredFiles = await execQueryNext(
    'SELECT * FROM files',
    targetConnectionString
  )
  const restoredFolders = await execQueryNext(
    'SELECT * FROM folders',
    targetConnectionString
  )
  const restoredUsers = await execQueryNext(
    'SELECT * FROM users',
    targetConnectionString
  )

  expect(restoredProjectToUsers.rowCount).toBe(0)
  expect(restoredFileVersions.rowCount).toBe(0)
  expect(restoredFiles.rowCount).toBe(0)
  expect(restoredFolders.rowCount).toBe(0)
  expect(restoredUsers.rowCount).toBe(1)
})
test('capturing and restoring a non-trivial database user entrypoint', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture(
    'non-trivial-database.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      maxCyclesLoop: 10,
      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.users',
          where: "users.email = 'withoutorg@test.com'",
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  const restoredProjectToUsers = await execQueryNext(
    'SELECT * FROM projects_to_users',
    targetConnectionString
  )
  const restoredFileVersions = await execQueryNext(
    'SELECT * FROM file_versions',
    targetConnectionString
  )
  const restoredFiles = await execQueryNext(
    'SELECT * FROM files',
    targetConnectionString
  )
  const restoredFolders = await execQueryNext(
    'SELECT * FROM folders',
    targetConnectionString
  )
  const restoredUsers = await execQueryNext(
    'SELECT * FROM users',
    targetConnectionString
  )

  expect(restoredProjectToUsers.rowCount).toBe(48)
  expect(restoredFileVersions.rowCount).toBe(42)
  expect(restoredFiles.rowCount).toBe(40)
  expect(restoredFolders.rowCount).toBe(47)
  expect(restoredUsers.rowCount).toBe(19)
})
test('capturing and restoring a non-trivial database user entrypoint with taskSortAlgorithm: children', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture(
    'non-trivial-database.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      maxCyclesLoop: 0,
      keepDisconnectedTables: false,
      followNullableRelations: true,
      taskSortAlgorithm: 'children',
      targets: [
        {
          table: 'public.users',
          where: "users.email = 'withoutorg@test.com'",
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  const restoredProjectToUsers = await execQueryNext(
    'SELECT * FROM projects_to_users',
    targetConnectionString
  )
  const restoredFileVersions = await execQueryNext(
    'SELECT * FROM file_versions',
    targetConnectionString
  )
  const restoredFiles = await execQueryNext(
    'SELECT * FROM files',
    targetConnectionString
  )
  const restoredFolders = await execQueryNext(
    'SELECT * FROM folders',
    targetConnectionString
  )
  const restoredUsers = await execQueryNext(
    'SELECT * FROM users',
    targetConnectionString
  )
  expect([
    restoredProjectToUsers.rowCount,
    restoredFileVersions.rowCount,
    restoredFiles.rowCount,
    restoredFolders.rowCount,
    restoredUsers.rowCount,
  ]).toEqual([1, 8, 6, 6, 14])
})
test('capturing and restoring a non-trivial database user entrypoint with taskSortAlgorithm: idsCount', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture(
    'non-trivial-database.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      maxCyclesLoop: 0,
      keepDisconnectedTables: false,
      followNullableRelations: true,
      taskSortAlgorithm: 'idsCount',
      targets: [
        {
          table: 'public.users',
          where: "users.email = 'withoutorg@test.com'",
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  const restoredProjectToUsers = await execQueryNext(
    'SELECT * FROM projects_to_users',
    targetConnectionString
  )
  const restoredFileVersions = await execQueryNext(
    'SELECT * FROM file_versions',
    targetConnectionString
  )
  const restoredFiles = await execQueryNext(
    'SELECT * FROM files',
    targetConnectionString
  )
  const restoredFolders = await execQueryNext(
    'SELECT * FROM folders',
    targetConnectionString
  )
  const restoredUsers = await execQueryNext(
    'SELECT * FROM users',
    targetConnectionString
  )
  expect([
    restoredProjectToUsers.rowCount,
    restoredFileVersions.rowCount,
    restoredFiles.rowCount,
    restoredFolders.rowCount,
    restoredUsers.rowCount,
  ]).toEqual([1, 8, 6, 8, 9])
})
test('capturing and restoring a non-trivial database nr 2', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  await loadDbDumpFixture(
    'non-trivial-database-2.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: true,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.Order',
          rowLimit: 10,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  const results = await execQueryNext(
    `SELECT * FROM "Order";`,
    targetConnectionString
  )
  expect(results.rowCount).toBe(10)
  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
})
test('capturing and restoring using targeted followNullableRelations', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture(
    'dbWithNonUniformsRelations.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      targets: [
          { table: 'public.table_2', percent: 100}
      ],
      followNullableRelations: {
        'public.table_2': {
          'table_1_table_2_id_fkey': false,
        },
      },
    }
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)

  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  const restoredTable1 = await execQueryNext(
    'SELECT * FROM table_1',
    targetConnectionString
  )
  expect(restoredTable1.rowCount).toBe(0)
  // verify that table_3, which is also linked to table_2 through a nullable foreign key, has been populated as expected.
  const restoredTable3 = await execQueryNext(
    'SELECT * FROM table_3',
    targetConnectionString
  )
  expect(restoredTable3.rowCount).toBe(3)
})
test('capturing and restoring using targeted maxChildrenPerNode', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture(
    'dbWithNonUniformsRelations.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      targets: [
          { table: 'public.table_2', percent: 100}
      ],
      maxChildrenPerNode: {
        'public.table_2': {
          'table_1_table_2_id_fkey': 100,
        },
      },
    }
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)

  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )

  const sourceTable1 = await execQueryNext(
    'SELECT * FROM table_1',
    sourceConnectionString
  )
  const restoredTable1 = await execQueryNext(
    'SELECT * FROM table_1',
    targetConnectionString
  )
  expect(restoredTable1.rowCount).toBe(100)
  // Should result in less rows being taken after subsetting
  expect(sourceTable1.rowCount).toBeGreaterThan(restoredTable1.rowCount)
})
