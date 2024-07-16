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
    `

test('capture with subsetting on seeded database - row_limit more than seeded rows', async () => {
  const seededDb = `
  ${structure}
  -- Insert data into author table
  DO $$
  DECLARE
    i INTEGER := 0;
  BEGIN
    FOR i IN 1..20 LOOP
      INSERT INTO "author" ("name", "email", "password") VALUES ('Author-' || i, 'email-' || i || '@example.com', 'password-' || i);
    END LOOP;
  END $$;

  -- Insert data into extra table
  DO $$
  DECLARE
    i INTEGER := 0;
  BEGIN
    FOR i IN 1..20 LOOP
      INSERT INTO "extra" ("name") VALUES ('Extra-' || i);
    END LOOP;
  END $$;

  -- Insert data into book table
  DO $$
  DECLARE
    i INTEGER := 0;
  BEGIN
    FOR i IN 1..20 LOOP
      INSERT INTO "book" ("title", "author_id") VALUES ('Book-' || i, 2);
    END LOOP;
  END $$;

  -- Insert data into address table
  DO $$
  DECLARE
    i INTEGER := 0;
  BEGIN
    FOR i IN 1..20 LOOP
      INSERT INTO "address" ("description", "author_id") VALUES ('Address-' || i, 2);
    END LOOP;
  END $$;
  `
  const sourceConnectionString = (await createTestDb(seededDb)).toString()
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
      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.author',
          rowLimit: 100,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)

  const res = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "author"`,
    sourceConnectionString
  )

  expect(res.rows[0].count).toBe('20')

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
  const extraResult = await execQueryNext(
    `SELECT 1 from "extra"`,
    targetConnectionString
  )
  expect(result.rows[0].count).toBe('20')
  expect(extraResult.rowCount).toBe(0)
})

test('capture with subsetting on seeded database - keepDisconnectedTrue', async () => {
  const seededDb = `
  ${structure}
  -- Insert data into author table
  DO $$
  DECLARE
    i INTEGER := 0;
  BEGIN
    FOR i IN 1..20 LOOP
      INSERT INTO "author" ("name", "email", "password") VALUES ('Author-' || i, 'email-' || i || '@example.com', 'password-' || i);
    END LOOP;
  END $$;

  -- Insert data into extra table
  DO $$
  DECLARE
    i INTEGER := 0;
  BEGIN
    FOR i IN 1..20 LOOP
      INSERT INTO "extra" ("name") VALUES ('Extra-' || i);
    END LOOP;
  END $$;

  -- Insert data into book table
  DO $$
  DECLARE
    i INTEGER := 0;
  BEGIN
    FOR i IN 1..20 LOOP
      INSERT INTO "book" ("title", "author_id") VALUES ('Book-' || i, 2);
    END LOOP;
  END $$;

  -- Insert data into address table
  DO $$
  DECLARE
    i INTEGER := 0;
  BEGIN
    FOR i IN 1..20 LOOP
      INSERT INTO "address" ("description", "author_id") VALUES ('Address-' || i, 2);
    END LOOP;
  END $$;
  `
  const sourceConnectionString = (await createTestDb(seededDb)).toString()
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
          rowLimit: 100,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)

  const res = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "author"`,
    sourceConnectionString
  )

  expect(res.rows[0].count).toBe('20')

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
  const extraResult = await execQueryNext(
    `SELECT 1 from "extra"`,
    targetConnectionString
  )

  expect(result.rows[0].count).toBe('20')
  // With keepDisconnected true should have dumped the entire extra table
  expect(extraResult.rowCount).toBe(20)
})
