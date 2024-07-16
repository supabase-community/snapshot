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

test('capturing and restoring a northwind database 100 orders', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('northwind.sql', sourceConnectionString.toString())

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      eager: false,

      keepDisconnectedTables: false,
      followNullableRelations: false,
      targets: [
        {
          table: 'public.orders',
          rowLimit: 100,
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
  const ordersResults = await execQueryNext(
    `SELECT 1 FROM public.orders`,
    targetConnectionString.toString()
  )
  expect(ordersResults.rowCount).toEqual(100)
})

test('capturing and restoring a northwind database 10 customers', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('northwind.sql', sourceConnectionString.toString())

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      eager: false,

      keepDisconnectedTables: false,
      followNullableRelations: false,
      targets: [
        {
          table: 'public.customers',
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

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  const customersResults = await execQueryNext(
    `SELECT 1 FROM public.customers`,
    targetConnectionString.toString()
  )
  expect(customersResults.rowCount).toEqual(10)
})

test('capturing and restoring a northwind database 10 order_details', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('northwind.sql', sourceConnectionString.toString())
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      eager: false,

      keepDisconnectedTables: false,
      followNullableRelations: false,
      targets: [
        {
          table: 'public.order_details',
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

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  const orderDetailsResults = await execQueryNext(
    `SELECT 1 FROM public.order_details`,
    targetConnectionString.toString()
  )
  expect(orderDetailsResults.rowCount).toEqual(10)
})

test('capturing and restoring a northwind database 1 territory', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('northwind.sql', sourceConnectionString.toString())
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      eager: false,

      keepDisconnectedTables: false,
      followNullableRelations: false,
      targets: [
        {
          table: 'public.territories',
          rowLimit: 1,
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
  const territoriesResults = await execQueryNext(
    `SELECT 1 FROM public.territories`,
    targetConnectionString.toString()
  )
  expect(territoriesResults.rowCount).toEqual(1)
})

test('capturing and restoring a northwind database 1 employee skipping null', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('northwind.sql', sourceConnectionString.toString())
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      eager: false,

      keepDisconnectedTables: false,
      followNullableRelations: false,
      targets: [
        {
          table: 'public.employees',
          rowLimit: 1,
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
  const employeeResults = await execQueryNext<{ count: number }>(
    `SELECT 1 FROM public.employees`,
    targetConnectionString.toString()
  )
  expect(employeeResults.rowCount).toEqual(1)
})

test('capturing and restoring a northwind database 10 skiping some nullable in tables', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('northwind.sql', sourceConnectionString.toString())

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      eager: false,
      keepDisconnectedTables: false,
      followNullableRelations: {
        $default: true,
        'public.products': false,
        'public.region': false,
        'public.shippers': false,
        'public.suppliers': false,
        'public.territories': false,
      },
      targets: [
        {
          table: 'public.customers',
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

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  const customersResults = await execQueryNext(
    `SELECT 1 FROM public.customers`,
    targetConnectionString.toString()
  )
  expect(customersResults.rowCount).toEqual(10)
  const suppliersResults = await execQueryNext(
    `SELECT 1 FROM public.suppliers`,
    targetConnectionString.toString()
  )
  expect(suppliersResults.rowCount).toEqual(0)
})
