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

test('capturing and restoring a videolet', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('videolet.sql', sourceConnectionString.toString())

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      targets: [
        {
          table: 'public.customer',
          rowLimit: 100
        }
      ],
      keepDisconnectedTables: false,
      eager: false,
      followNullableRelations: true,
      maxCyclesLoop: 10,
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
  const ordersResults = await execQueryNext(
    `SELECT 1 FROM public.customer`,
    targetConnectionString.toString()
  )
  // Because the database have a very cyclic and dense structure, we should overfetch a lot
  expect(ordersResults.rowCount).toEqual(600)
})

test('capturing and restoring a videolet with maxChildrenPerNode', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('videolet.sql', sourceConnectionString.toString())

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      targets: [
        {
          table: 'public.customer',
          rowLimit: 100
        }
      ],
      keepDisconnectedTables: false,
      eager: false,
      followNullableRelations: true,
      maxChildrenPerNode: 1,
      maxCyclesLoop: 10,
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
  const ordersResults = await execQueryNext(
    `SELECT 1 FROM public.customer`,
    targetConnectionString.toString()
  )
  // With maxChildrenPerNode we should overfetch much less
  expect(ordersResults.rowCount).toEqual(101)
})

test('only capture and restore a videolet using v3', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('videolet.sql', sourceConnectionString.toString())

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: false,

      targets: [
        {
          // Should not even check the targets because enabled is false
          table: 'dummytable',
          rowLimit: 1
        }
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
  const customerResults = await execQueryNext(
    `SELECT 1 FROM public.customer`,
    targetConnectionString.toString()
  )
  const filmActorResults = await execQueryNext(
    `SELECT 1 FROM public.film_actor`,
    targetConnectionString.toString()
  )
  // Because the database have a very cyclic and dense structure, we should overfetch a lot
  expect(customerResults.rowCount).toEqual(600)
  expect(filmActorResults.rowCount).toEqual(5462)
})

test('capturing and restoring a videolet with maxChildrenPerNode on specific tables', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('videolet.sql', sourceConnectionString.toString())

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      targets: [
        {
          table: 'public.customer',
          rowLimit: 10
        }
      ],
      keepDisconnectedTables: false,
      eager: false,
      maxChildrenPerNode: {
        'public.store': 1,
        'public.customer': 1,
      },
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
  const customerResults = await execQueryNext(
    `SELECT 1 FROM public.customer`,
    targetConnectionString.toString()
  )
  const filmResults = await execQueryNext(
    `SELECT 1 FROM public.film`,
    targetConnectionString.toString()
  )
  // With maxChildrenPerNode we should overfetch much less
  expect(filmResults.rowCount).toEqual(2)
  expect(customerResults.rowCount).toEqual(10)
})

test('capturing and restoring a videolet with maxChildrenPerNode on specific relations', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('videolet.sql', sourceConnectionString.toString())

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      targets: [
        {
          table: 'public.customer',
          rowLimit: 10
        }
      ],
      keepDisconnectedTables: false,
      eager: false,
      maxChildrenPerNode: {
        'public.store': {
          inventory_store_id_fkey: 1,
        },
        'public.customer': {
          rental_customer_id_fkey: 1,
        },
      },
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
  const customerResults = await execQueryNext(
    `SELECT 1 FROM public.customer`,
    targetConnectionString.toString()
  )
  const filmResults = await execQueryNext(
    `SELECT 1 FROM public.film`,
    targetConnectionString.toString()
  )
  // With maxChildrenPerNode we should overfetch much less
  expect(filmResults.rowCount).toEqual(2)
  expect(customerResults.rowCount).toEqual(10)
})

test('capturing and restoring a videolet with maxChildrenPerNode table shortcut', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('videolet.sql', sourceConnectionString.toString())

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      targets: [
        {
          table: 'public.customer',
          rowLimit: 10
        }
      ],
      keepDisconnectedTables: false,
      eager: false,
      maxChildrenPerNode: {
        'public.store': {
          'public.inventory': 1,
        },
        'public.customer': {
          'public.rental': 1,
        },
      },
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
  const customerResults = await execQueryNext(
    `SELECT 1 FROM public.customer`,
    targetConnectionString.toString()
  )
  const filmResults = await execQueryNext(
    `SELECT 1 FROM public.film`,
    targetConnectionString.toString()
  )
  // With maxChildrenPerNode we should overfetch much less
  expect(filmResults.rowCount).toEqual(2)
  expect(customerResults.rowCount).toEqual(10)
})

test('capturing and restoring a videolet with maxChildrenPerNode table $default', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('videolet.sql', sourceConnectionString.toString())

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      targets: [
        {
          table: 'public.customer',
          rowLimit: 10
        }
      ],
      keepDisconnectedTables: false,
      eager: false,
      maxChildrenPerNode: {
        '$default': {
          '$default': Number.MAX_SAFE_INTEGER,
          'public.inventory': 1,
          'public.rental': 1,
        }
      },
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
  const customerResults = await execQueryNext(
    `SELECT 1 FROM public.customer`,
    targetConnectionString.toString()
  )
  const filmResults = await execQueryNext(
    `SELECT 1 FROM public.film`,
    targetConnectionString.toString()
  )
  // With maxChildrenPerNode we should overfetch much less
  expect(filmResults.rowCount).toEqual(2)
  expect(customerResults.rowCount).toEqual(10)
})

test('capturing and restoring a videolet with maxChildrenPerNode table $default.$default', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('videolet.sql', sourceConnectionString.toString())

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      targets: [
        {
          table: 'public.customer',
          rowLimit: 10
        }
      ],
      keepDisconnectedTables: false,
      eager: false,
      maxChildrenPerNode: {
        '$default': {
          '$default': 1,
        }
      },
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
  const customerResults = await execQueryNext(
    `SELECT 1 FROM public.customer`,
    targetConnectionString.toString()
  )
  const filmResults = await execQueryNext(
    `SELECT 1 FROM public.film`,
    targetConnectionString.toString()
  )
  // With maxChildrenPerNode we should overfetch much less
  expect(filmResults.rowCount).toEqual(2)
  expect(customerResults.rowCount).toEqual(10)
})
