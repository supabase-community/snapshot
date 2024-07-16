import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
  getTestAccessToken,
  VIDEOLET_PROJECT_ID,
} from '../src/testing/index.js'
import { parse as csvParse } from 'csv-parse/sync'
import fsExtra from 'fs-extra'
import path from 'path'

vi.setConfig({
  testTimeout: 10 * 60 * 1000,
})

const SHOULD_SMOKE_TEST = process.env.CI || process.env.SNAPLET_CLI_PATH

describe.skipIf(!SHOULD_SMOKE_TEST)('Binary cli smoke tests', () => {
  test('smoke test snaplet cli binary', async () => {
    const structure = `
  CREATE TABLE "Order" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL
  );
  CREATE TABLE "Platform" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL
  );
  CREATE TABLE "Product" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255) NOT NULL,
    "platformId" INTEGER NOT NULL,
    CONSTRAINT "Product_platform_fk" FOREIGN KEY ("platformId") REFERENCES public."Platform"(id) ON UPDATE CASCADE ON DELETE RESTRICT
  );
  CREATE TABLE "OrderItem" (
    "id" SERIAL PRIMARY KEY,
    "orderId" INTEGER NOT NULL,
    "productId" INTEGER NOT NULL,
    CONSTRAINT "OrderItem_orderId_fkey" FOREIGN KEY ("orderId")
      REFERENCES public."Order"(id)
      ON UPDATE CASCADE
      ON DELETE RESTRICT,
    CONSTRAINT "OrderItem_productId_fkey" FOREIGN KEY ("productId")
      REFERENCES public."Product"(id)
      ON UPDATE CASCADE
      ON DELETE RESTRICT
  );
  -- Insert data into Platform table
    DO $$
    DECLARE
      i INTEGER := 0;
    BEGIN
      FOR i IN 1..100 LOOP
        INSERT INTO "Platform" ("name") VALUES ('Platform-' || i);
      END LOOP;
    END $$;

    -- Insert data into Order table
    DO $$
    DECLARE
      i INTEGER := 0;
    BEGIN
      FOR i IN 1..100 LOOP
        INSERT INTO "Order" ("name") VALUES ('Order-' || i);
      END LOOP;
    END $$;

    -- Insert data into Product table
    DO $$
    DECLARE
      i INTEGER := 0;
    BEGIN
      FOR i IN 1..100 LOOP
        INSERT INTO "Product" ("name", "platformId") VALUES ('Product-' || i, 5);
      END LOOP;
    END $$;

    -- Insert data into OrderItem table
    DO $$
    DECLARE
      i INTEGER := 0;
    BEGIN
      FOR i IN 1..100 LOOP
        INSERT INTO "OrderItem" ("orderId", "productId") VALUES (5, 5);
      END LOOP;
    END $$;
  `
    const sourceConnectionString = (await createTestDb(structure)).toString()
    const targetConnectionString = (await createTestDb()).toString()
    const paths = await createTestProjectDirV2()
    await execQueryNext<{ count: number }>(`VACUUM`, sourceConnectionString)

    const productResultPostSeed = await execQueryNext<{ count: number }>(
      `SELECT count(*) FROM "Product"`,
      sourceConnectionString
    )
    expect(productResultPostSeed.rows[0].count).toBe('100')

    const orderResultPostSeed = await execQueryNext<{ count: number }>(
      `SELECT count(*) FROM "Order"`,
      sourceConnectionString
    )
    expect(orderResultPostSeed.rows[0].count).toBe('100')
    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      transform: {
        $mode: "unsafe",
        public: {
          Order: ({ row }) => {
            name: copycat.scramble(row.name)
          }
        }
      },
      subset: {
        enabled: true,
        followNullableRelations: true,
        keepDisconnectedTables: true,
        targets: [
          {
            table: 'public.Order',
            rowLimit: 10,
          },
        ],
      },
    })`
    await fsExtra.writeFile(paths.snapletConfig, configContent)

    const captureLocation = createTestCapturePath()
    await runSnapletCLI(
      ['ss', 'capture', captureLocation.name],
      {
        SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
      },
      paths,
      { binary: true }
    )

    await runSnapletCLI(
      ['ss', 'restore', captureLocation.name],
      {
        SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
      },
      paths,
      { binary: true }
    )
    await runSnapletCLI(
      ['ss', 'share', '--no-encrypt', captureLocation.name],
      {
        SNAPLET_PROJECT_ID: VIDEOLET_PROJECT_ID,
        SNAPLET_TARGET_DATABASE_URL: sourceConnectionString,
        SNAPLET_ACCESS_TOKEN: await getTestAccessToken(VIDEOLET_PROJECT_ID),
      },
      paths,
      { binary: true }
    )
    const result = await execQueryNext<{ count: number }>(
      `SELECT count(*) FROM "Order"`,
      targetConnectionString
    )
    expect(result.rows[0].count).toBe('10')

    const productResult = await execQueryNext<{ count: string }>(
      `SELECT count(*) FROM "Product"`,
      targetConnectionString
    )

    expect(parseInt(productResult.rows[0].count)).toBeGreaterThanOrEqual(1) //It has the subset bernoulli so wont be exactly 10
  })

  test(
    'transform with require()s of bundled dependencies',
    async () => {
      const paths = await createTestProjectDirV2()
      const connectionString = await createTestDb(`
        CREATE TABLE "User" ("email" TEXT);
        INSERT INTO "User" VALUES ('hiphopopotamus@rhymenoceros.com');
      `)
      const configContent = `
      const { copycat } = require('@snaplet/copycat')
      const { defineConfig } = require('snaplet')

      module.exports = defineConfig({
        transform: {
          public: {
            User: ({ row }) => ({
              email: copycat.email(row.email)
            })
          }
        },
      });`
      await fsExtra.writeFile(paths.snapletConfig, configContent)
      const ssPath = createTestCapturePath()
      await runSnapletCLI(
        ['snapshot capture', ssPath.name],
        {
          SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
        },
        paths,
        { binary: true }
      )
      const csvSnapshotContent = await fsExtra.readFile(
        path.join(ssPath.name, 'tables', 'public.User.csv')
      )
      const csvParsed = csvParse(csvSnapshotContent, { columns: true })
      expect(csvParsed[0].email).toMatchInlineSnapshot(
        `"Laury_Haley34416@rejuvenate-slate.com"`
      )
      const ssPathSafe = createTestCapturePath()
      await runSnapletCLI(
        ['snapshot capture', ssPathSafe.name],
        {
          SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
          SNAPLET_SAFE_MODE: '1',
        },
        paths,
        { binary: true }
      )
      const csvSnapshotSafeContent = await fsExtra.readFile(
        path.join(ssPath.name, 'tables', 'public.User.csv')
      )
      const csvSafeParse = csvParse(csvSnapshotSafeContent, { columns: true })

      expect(csvSafeParse[0].email).toMatchInlineSnapshot(
        `"Laury_Haley34416@rejuvenate-slate.com"`
      )
    },
    { timeout: 1 * 60 * 1000 }
  )
})
