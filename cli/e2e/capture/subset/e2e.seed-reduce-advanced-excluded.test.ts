import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
} from '../../../src/testing/index.js'
import fsExtra from 'fs-extra'

vi.setConfig({
  testTimeout: 10 * 60 * 1000,
})

const structure = `
      CREATE TABLE "author" (
        "id" SERIAL PRIMARY KEY,
        "name" VARCHAR(255) NOT NULL,
        "email" VARCHAR(255) NOT NULL,
        "password" VARCHAR(255) NOT NULL,
        "created_at" TIMESTAMP NOT NULL DEFAULT NOW(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT NOW()
      );
      CREATE TABLE "book" (
        "id" SERIAL PRIMARY KEY,
        "title" VARCHAR(255) NOT NULL,
        "author_id" INTEGER NOT NULL,
        "created_at" TIMESTAMP NOT NULL DEFAULT NOW(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT NOW(),
        CONSTRAINT "book_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "author" ("id") ON DELETE CASCADE
      );
      CREATE TABLE "address" (
        "id" SERIAL PRIMARY KEY,
        "description" VARCHAR(255) NOT NULL,
        "author_id" INTEGER NOT NULL,
        CONSTRAINT "address_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "author" ("id") ON DELETE CASCADE
      );
      CREATE TABLE "extra" (
        "id" SERIAL PRIMARY KEY,
        "name" VARCHAR(255) NOT NULL
      );
      -- Insert data into author table
      DO $$
      DECLARE
        i INTEGER := 0;
      BEGIN
        FOR i IN 1..100 LOOP
          INSERT INTO "author" ("name", "email", "password") VALUES ('Author-' || i, 'email-' || i || '@example.com', 'password-' || i);
        END LOOP;
      END $$;

      -- Insert data into extra table
      DO $$
      DECLARE
        i INTEGER := 0;
      BEGIN
        FOR i IN 1..100 LOOP
          INSERT INTO "extra" ("name") VALUES ('Extra-' || i);
        END LOOP;
      END $$;

      -- Insert data into book table
      DO $$
      DECLARE
        i INTEGER := 0;
      BEGIN
        FOR i IN 1..100 LOOP
          INSERT INTO "book" ("title", "author_id") VALUES ('Book-' || i, 2);
        END LOOP;
      END $$;

      -- Insert data into address table
      DO $$
      DECLARE
        i INTEGER := 0;
      BEGIN
        FOR i IN 1..100 LOOP
          INSERT INTO "address" ("description", "author_id") VALUES ('Address-' || i, 2);
        END LOOP;
      END $$;
    `

test('capture with subsetting on seeded database - keep excluded (with percent)', async () => {
  const sourceConnectionString = (await createTestDb(structure)).toString()
  const targetConnectionString = (await createTestDb()).toString()
  const paths = await createTestProjectDirV2()
  await execQueryNext<{ count: number }>(`VACUUM`, sourceConnectionString)

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    transform: {
    },
    subset: {
      enabled: true,
      version: '3',
      keepDisconnectedTables: true,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.author',
          percent: 10,
        },
        {
          table: 'public.extra',
          percent: 5,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)

  const captureLocation = createTestCapturePath()
  await runSnapletCLI(
    ['ss', 'capture', captureLocation.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString,
    },
    paths
  )

  await runSnapletCLI(
    ['ss', 'restore', captureLocation.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString,
    },
    paths
  )
  const result = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "author"`,
    targetConnectionString
  )
  expect(result.rows[0].count).toBe('10')

  const extraResult = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "extra"`,
    targetConnectionString
  )

  expect(extraResult.rows[0].count).toBe('5')
})

test('capture with subsetting on seeded database - exclude table', async () => {
  const sourceConnectionString = (await createTestDb(structure)).toString()
  const targetConnectionString = (await createTestDb()).toString()
  const paths = await createTestProjectDirV2()
  await execQueryNext<{ count: number }>(`VACUUM`, sourceConnectionString)

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    select: {
      public: {
        address: "structure",
      },
    },
    subset: {
      enabled: true,
      version: '3',
      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.book',
          percent: 10,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const captureLocation = createTestCapturePath()
  await runSnapletCLI(
    ['ss', 'capture', captureLocation.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString,
    },
    paths
  )
  await runSnapletCLI(
    ['ss', 'restore', captureLocation.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString,
    },
    paths
  )
  const result = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "author"`,
    targetConnectionString
  )
  expect(result.rows[0].count).toBe('1')

  const addressResult = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "address"`,
    targetConnectionString
  )
  expect(addressResult.rows[0].count).toBe('0')
})
