import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  runSnapletCLI,
  checkConstraints,
  createTestProjectDirV2,
} from '../../../src/testing/index.js'
import fsExtra from 'fs-extra'

vi.setConfig({
  testTimeout: 10 * 60 * 1000,
})

const seedStructureOne = `
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
          INSERT INTO "book" ("title", "author_id") VALUES ('Book-' || i, 5);
        END LOOP;
      END $$;

      -- Insert data into address table
      DO $$
      DECLARE
        i INTEGER := 0;
      BEGIN
        FOR i IN 1..100 LOOP
          INSERT INTO "address" ("description", "author_id") VALUES ('Address-' || i, 10);
        END LOOP;
      END $$;
    `
test('subsetting config in snaplet.config.ts', async () => {
  const sourceConnectionString = (
    await createTestDb(seedStructureOne)
  ).toString()
  const paths = await createTestProjectDirV2()
  const snapletConfigContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    transform: {
      public: {
        Address({ row }) {
          return {
            description: copycat.scramble(row.description)
          }
        },
      },
    },
    subset: {
      version: '3',
      targets: [
        {
          table: "public.book",
          percent: 10
        }
      ],
      keepDisconnectedTables: true
    }
  })`
  await fsExtra.writeFile(paths.snapletConfig, snapletConfigContent)
  const captureLocation = createTestCapturePath()
  await execQueryNext(`VACUUM`, sourceConnectionString)

  await runSnapletCLI(
    ['ss', 'capture', captureLocation.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  const targetConnectionString = (await createTestDb()).toString()
  await runSnapletCLI(
    ['ss', 'restore', captureLocation.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )

  const authorCount = (
    await execQueryNext(`SELECT 1 FROM "author"`, targetConnectionString)
  ).rowCount
  expect(authorCount).toBe(1)

  const extraCount = (
    await execQueryNext(`SELECT 1 FROM "extra"`, targetConnectionString)
  ).rowCount
  // All rows in extra should be dumped as keepDisconnected is true
  expect(extraCount).toBe(100)
})
test('capture with reduce on seeded database', async () => {
  const sourceConnectionString = (
    await createTestDb(seedStructureOne)
  ).toString()
  const paths = await createTestProjectDirV2()

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
          percent: 10,
          orderBy: 'id desc',
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const captureLocation = createTestCapturePath()

  await execQueryNext(`VACUUM`, sourceConnectionString)

  await runSnapletCLI(
    ['ss', 'capture', captureLocation.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  const targetConnectionString = (await createTestDb()).toString()
  await runSnapletCLI(
    ['ss', 'restore', captureLocation.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )

  const result = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "author"`,
    targetConnectionString
  )
  expect(result.rows[0].count).toBe('10')

  // const firstAuthorRes = await execQueryNext<{ id: number }>(
  //   `SELECT id FROM "author" limit 1`,
  //   targetConnectionString
  // )
  // expect(firstAuthorRes.rows[0].id).toBe(91)

  const extraResult = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "extra"`,
    targetConnectionString
  )
  expect(extraResult.rows[0].count).toBe('0')
})
test('seed/reduce on table with circular reference', async () => {
  const seedStructure = `
  ${seedStructureOne}
  ALTER TABLE "book" ADD COLUMN "similar_book_id" INTEGER;
  ALTER TABLE "book" ADD CONSTRAINT "book_similar_book_id_fkey" FOREIGN KEY ("similar_book_id") REFERENCES "book" ("id") ON DELETE CASCADE;
  UPDATE "book" SET "similar_book_id" = 4;

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
  const sourceConnectionString = (await createTestDb(seedStructure)).toString()
  const paths = await createTestProjectDirV2()
  await execQueryNext(`VACUUM`, sourceConnectionString)

  const bookResult = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "book"`,
    sourceConnectionString
  )
  expect(bookResult.rows[0].count).toBe('100')

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
          table: 'public.address',
          percent: 10,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const captureLocation = createTestCapturePath()

  await runSnapletCLI(['ss', 'capture', captureLocation.name], {
    SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
  })

  const targetConnectionString = (await createTestDb()).toString()
  await runSnapletCLI(
    ['ss', 'restore', captureLocation.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )

  const result = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "address"`,
    targetConnectionString
  )

  expect(result.rows[0].count).toBe('12')
})
test('capture with reduce on seeded database using percent', async () => {
  const sourceConnectionString = (
    await createTestDb(seedStructureOne)
  ).toString()
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
          percent: 10,
          orderBy: 'id desc',
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const captureLocation = createTestCapturePath()
  await runSnapletCLI(['ss', 'capture', captureLocation.name], {
    SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString,
  })

  await runSnapletCLI(
    ['ss', 'restore', captureLocation.name],
    {
      SNAPLET_TARGET_DATABASE_URL: sourceConnectionString,
    },
    paths
  )
  const result = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "author"`,
    sourceConnectionString
  )
  expect(result.rows[0].count).toBe('10')
  const firstAuthorRes = await execQueryNext<{ id: number }>(
    `SELECT id FROM "author" limit 1`,
    sourceConnectionString
  )
  expect(firstAuthorRes.rows[0].id).toBe(90)

  const extraResult = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "extra"`,
    sourceConnectionString
  )

  expect(extraResult.rows[0].count).toBe('0')
})
