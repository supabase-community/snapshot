import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
  checkConstraints,
} from '../../../../src/testing/index.js'
import fsExtra from 'fs-extra'

vi.setConfig({
  testTimeout: 10 * 60 * 1000,
})

test('catpuring table with auto generated always columns', async () => {
  const structure = `
        CREATE TABLE "author" (
          "id" SERIAL PRIMARY KEY
        );
        CREATE TABLE "book" (
          "id" SERIAL PRIMARY KEY,
          "author_id" INTEGER NOT NULL,
          "generated_column" INTEGER GENERATED ALWAYS AS (id * 2) STORED,
          CONSTRAINT "book_author_id_fkey" FOREIGN KEY ("author_id")
            REFERENCES "author" ("id")
            ON DELETE CASCADE
        );
        CREATE TABLE "publisher" ("id" SERIAL PRIMARY KEY);
        ALTER TABLE "author" ADD COLUMN "publisher_id" INTEGER NOT NULL;
        ALTER TABLE "author" ADD CONSTRAINT "author_publisher_fkey" FOREIGN KEY ("publisher_id") REFERENCES "publisher" ("id") ON DELETE SET NULL;
        ALTER TABLE "book" ADD COLUMN "author_id_2" INTEGER NOT NULL;
        ALTER TABLE "book" ADD CONSTRAINT "book_author_2_fkey" FOREIGN KEY ("author_id_2") REFERENCES "author" ("id") ON DELETE SET NULL;
      `
  const sourceConnectionString = (await createTestDb(structure)).toString()
  const targetConnectionString = (await createTestDb()).toString()
  const paths = await createTestProjectDirV2()
  // Insert into Publisher 2 rows
  const sqlInsertQuery = `
        INSERT INTO "publisher" (id) VALUES (1), (2);
        INSERT INTO "author" (id, publisher_id) VALUES (10,1);
        INSERT INTO "author" (id, publisher_id) VALUES (11,2);
        INSERT INTO "book" (id, author_id, author_id_2) VALUES (20, 10, 11);
      `
  await execQueryNext(sqlInsertQuery, sourceConnectionString)
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: false,

      keepDisconnectedTables: true,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.author',
          where: 'id = 10',
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
test('catpuring and subsetting table with auto generated always columns', async () => {
  const structure = `
        CREATE TABLE "author" (
          "id" SERIAL PRIMARY KEY
        );
        CREATE TABLE "book" (
          "id" SERIAL PRIMARY KEY,
          "author_id" INTEGER NOT NULL,
          "generated_column" INTEGER GENERATED ALWAYS AS (id * 2) STORED,
          CONSTRAINT "book_author_id_fkey" FOREIGN KEY ("author_id")
            REFERENCES "author" ("id")
            ON DELETE CASCADE
        );
        CREATE TABLE "publisher" ("id" SERIAL PRIMARY KEY);
        ALTER TABLE "author" ADD COLUMN "publisher_id" INTEGER NOT NULL;
        ALTER TABLE "author" ADD CONSTRAINT "author_publisher_fkey" FOREIGN KEY ("publisher_id") REFERENCES "publisher" ("id") ON DELETE SET NULL;
        ALTER TABLE "book" ADD COLUMN "author_id_2" INTEGER NOT NULL;
        ALTER TABLE "book" ADD CONSTRAINT "book_author_2_fkey" FOREIGN KEY ("author_id_2") REFERENCES "author" ("id") ON DELETE SET NULL;
      `
  const sourceConnectionString = (await createTestDb(structure)).toString()
  const targetConnectionString = (await createTestDb()).toString()
  const paths = await createTestProjectDirV2()
  // Insert into Publisher 2 rows
  const sqlInsertQuery = `
        INSERT INTO "publisher" (id) VALUES (1), (2);
        INSERT INTO "author" (id, publisher_id) VALUES (10,1);
        INSERT INTO "author" (id, publisher_id) VALUES (11,2);
        INSERT INTO "book" (id, author_id, author_id_2) VALUES (20, 10, 11);
      `
  await execQueryNext(sqlInsertQuery, sourceConnectionString)
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
          table: 'public.book',
          percent: 50
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
