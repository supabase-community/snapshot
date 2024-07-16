import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
  checkConstraints,
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
test('seed and reduce on table with 2 fk to the same other table', async () => {
  const sourceConnectionString = (await createTestDb(structure)).toString()
  const paths = await createTestProjectDirV2()
  // We already have one fk from book to the author table
  // Create another fk to author table
  await execQueryNext(
    `
          ALTER TABLE "book" ADD COLUMN "author_id_2" INTEGER NOT NULL;
          ALTER TABLE "book" ADD CONSTRAINT "book_author_2_fkey" FOREIGN KEY ("author_id_2") REFERENCES "author" ("id") ON DELETE SET NULL;
          INSERT INTO "author" (id,name,email,password,created_at, updated_at) VALUES (1,'John Doe','doe@email.com','password','2021-01-01 00:00:00','2021-01-01 00:00:00');
          INSERT INTO "author" (id,name,email,password,created_at, updated_at) VALUES (2,'Chris Penny','chris@email.com','password','2021-01-01 00:00:00','2021-01-01 00:00:00');
          INSERT INTO "book" (title, author_id, author_id_2) VALUES ('book 1', 1, 2);
          INSERT INTO "address" (description, author_id) VALUES ('address 1', 1);
          `,
    sourceConnectionString
  )
  await execQueryNext('VACUUM', sourceConnectionString)

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
          where: 'id = 2',
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
    `SELECT count(*) FROM "author"`,
    targetConnectionString
  )
  expect(result.rows[0].count).toBe('2')
})
test('seed and reduce on table with 2 fk to the same other table - other table have parent', async () => {
  const sourceConnectionString = (await createTestDb(structure)).toString()
  const paths = await createTestProjectDirV2()
  await execQueryNext(
    `
          -- Add publisher_id to author table
          CREATE TABLE "publisher" (
            "id" SERIAL PRIMARY KEY,
            "name" VARCHAR(255) NOT NULL
          );
          ALTER TABLE "author" ADD COLUMN "publisher_id" INTEGER NOT NULL;
          ALTER TABLE "author" ADD CONSTRAINT "author_publisher_fkey" FOREIGN KEY ("publisher_id") REFERENCES "publisher" ("id") ON DELETE SET NULL;
          ALTER TABLE "book" ADD COLUMN "author_id_2" INTEGER NOT NULL;
          -- We already have one fk from book to the author table
          -- Create another fk to author table
          ALTER TABLE "book" ADD CONSTRAINT "book_author_2_fkey" FOREIGN KEY ("author_id_2") REFERENCES "author" ("id") ON DELETE SET NULL;
          INSERT INTO "publisher" (name) VALUES ('publisher 1'), ('publisher 2');
          INSERT INTO "author" (id,name,email,password,created_at, updated_at, publisher_id) VALUES (1,'John Doe','doe@email.com','password','2021-01-01 00:00:00','2021-01-01 00:00:00',1);
          INSERT INTO "author" (id,name,email,password,created_at, updated_at, publisher_id) VALUES (2,'Chris Penny','chris@email.com','password','2021-01-01 00:00:00','2021-01-01 00:00:00',2);
          INSERT INTO "book" (title, author_id, author_id_2) VALUES ('book 1', 1, 2);
          INSERT INTO "address" (description, author_id) VALUES ('address 1', 1);
        `,
    sourceConnectionString
  )
  await execQueryNext('VACUUM', sourceConnectionString)

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
          percent: 50,
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
    `SELECT count(*) FROM "author"`,
    targetConnectionString
  )
  expect(result.rows[0].count).toBe('2')

  const resultPublisher = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "publisher"`,
    targetConnectionString
  )
  expect(resultPublisher.rows[0].count).toBe('2')
})

test('Skipping nullable relation on only one table', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()
  await execQueryNext(
    `CREATE TABLE table_1 (
        id INT PRIMARY KEY,
        data VARCHAR(100)
    );

    CREATE TABLE table_2 (
        id INT PRIMARY KEY,
        table_1_id INT NOT NULL,
        other_data VARCHAR(100),
        FOREIGN KEY (table_1_id) REFERENCES table_1(id)
    );

    CREATE TABLE table_3 (
        id INT PRIMARY KEY,
        table_1_id INT,
        additional_data VARCHAR(100),
        FOREIGN KEY (table_1_id) REFERENCES table_1(id)
    );`,
    sourceConnectionString.toString()
  )
  await execQueryNext(
    `
    INSERT INTO table_1 (id, data) VALUES (1, 'Data 1');
    INSERT INTO table_1 (id, data) VALUES (2, 'Data 2');
    INSERT INTO table_1 (id, data) VALUES (3, 'Data 3');

    INSERT INTO table_2 (id, table_1_id, other_data) VALUES (1, 1, 'Other Data 1');
    INSERT INTO table_2 (id, table_1_id, other_data) VALUES (2, 2, 'Other Data 2');

    INSERT INTO table_3 (id, table_1_id, additional_data) VALUES (1, 1, 'Additional Data 1');
    INSERT INTO table_3 (id, table_1_id, additional_data) VALUES (2, NULL, 'Additional Data 2');
  `,
    sourceConnectionString.toString()
  )

  const configContent = `
  import { defineConfig } from "snaplet";
  export default defineConfig({
    subset: {
      enabled: true,
      targets: [
        { table: 'public.table_1', where: \`"table_1"."id" = 1\` }
      ],
      followNullableRelations: {
        $default: true,
        "public.table_1": {
          table_2_table_1_id_fkey: false,
        }
      }
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
  const table1Results = await execQueryNext(
    `SELECT 1 FROM public.table_1`,
    targetConnectionString.toString()
  )
  const table2Results = await execQueryNext(
    `SELECT 1 FROM public.table_2`,
    targetConnectionString.toString()
  )
  const table3Results = await execQueryNext(
    `SELECT 1 FROM public.table_3`,
    targetConnectionString.toString()
  )
  expect(table1Results.rowCount).toEqual(1)
  expect(table3Results.rowCount).toEqual(1)
  // It should have skipped the relations between table_1 and table_2 and therefore table_2 should be empty
  expect(table2Results.rowCount).toEqual(0)
})

test('targetTraversalMode: "sequential": Multiple targets with same table', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()
  await execQueryNext(
    `CREATE TABLE table_1 (
        id INT PRIMARY KEY,
        data VARCHAR(100)
    );

    CREATE TABLE table_2 (
        id INT PRIMARY KEY,
        table_1_id INT NOT NULL,
        other_data VARCHAR(100),
        FOREIGN KEY (table_1_id) REFERENCES table_1(id)
    );

    CREATE TABLE table_3 (
        id INT PRIMARY KEY,
        table_2_id INT NOT NULL,
        additional_data VARCHAR(100),
        FOREIGN KEY (table_2_id) REFERENCES table_2(id)
    );`,
    sourceConnectionString.toString()
  )
  await execQueryNext(
    `
    INSERT INTO table_1 (id, data) VALUES (1, 'Data 1');
    INSERT INTO table_1 (id, data) VALUES (2, 'Data 2');
    INSERT INTO table_1 (id, data) VALUES (3, 'Data 3');

    INSERT INTO table_2 (id, table_1_id, other_data) VALUES (1, 1, 'Other Data 1');
    INSERT INTO table_2 (id, table_1_id, other_data) VALUES (2, 2, 'Other Data 2');
    INSERT INTO table_2 (id, table_1_id, other_data) VALUES (3, 3, 'Other Data 3');

    INSERT INTO table_3 (id, table_2_id, additional_data) VALUES (1, 1, 'Additional Data 1');
    INSERT INTO table_3 (id, table_2_id, additional_data) VALUES (2, 2, 'Additional Data 2');
    INSERT INTO table_3 (id, table_2_id, additional_data) VALUES (3, 3, 'Additional Data 2');
  `,
    sourceConnectionString.toString()
  )

  const configContent = `
  import { defineConfig } from "snaplet";
  export default defineConfig({
    subset: {
      enabled: true,
      targetTraversalMode: 'sequential',
      targets: [
        {
          table: 'public.table_1',
          where: \`"table_1"."id" = 1\`
        },
        {
          table: 'public.table_1',
          where: \`"table_1"."id" = 2\`
        }
      ]
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
  const table1Results = await execQueryNext(
    `SELECT 1 FROM public.table_1`,
    targetConnectionString.toString()
  )
  const table2Results = await execQueryNext(
    `SELECT 1 FROM public.table_2`,
    targetConnectionString.toString()
  )
  const table3Results = await execQueryNext(
    `SELECT 1 FROM public.table_3`,
    targetConnectionString.toString()
  )
  expect(table1Results.rowCount).toEqual(2)
  expect(table2Results.rowCount).toEqual(2)
  expect(table3Results.rowCount).toEqual(2)
})
