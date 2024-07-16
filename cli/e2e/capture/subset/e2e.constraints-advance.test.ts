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

test('capturing and restoring with two differents paths growing the same tables', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()
  const sqlQueryTableCreate = [
    `CREATE TABLE "author" ("id" SERIAL PRIMARY KEY);`,
    `CREATE TABLE "groups" ("id" SERIAL PRIMARY KEY);`,
    `CREATE TABLE "groups_to_author" (
          "id" SERIAL PRIMARY KEY,
          group_id SERIAL NOT NULL,
          author_id SERIAL NOT NULL,
          CONSTRAINT "group_to_author_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "groups" ON DELETE CASCADE,
          CONSTRAINT "group_to_author_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "author" ON DELETE CASCADE
        );`,
    `CREATE TABLE "books_assignations" ("id" SERIAL PRIMARY KEY);`,
    `CREATE TABLE "books_assignations_groups" (
          "id" SERIAL PRIMARY KEY,
          assignation_id SERIAL NOT NULL,
          group_id SERIAL NOT NULL,
          CONSTRAINT "books_assignations_to_groups_id_fkey" FOREIGN KEY ("assignation_id") REFERENCES "books_assignations" ON DELETE CASCADE,
          CONSTRAINT "books_assignations_to_groups_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "groups" ON DELETE CASCADE
        );`,
    `CREATE TABLE "books" (
          "id" SERIAL PRIMARY KEY,
          "author_id" SERIAL NOT NULL,
          "assignation_id" INTEGER DEFAULT NULL,
          CONSTRAINT "books_assignations_id_fkey" FOREIGN KEY ("assignation_id") REFERENCES "books_assignations" ON DELETE CASCADE,
          CONSTRAINT "books_authors_id_fkey" FOREIGN KEY ("author_id") REFERENCES "author" ON DELETE CASCADE
        );`,
  ]
  // Basically we create a topology like so:
  // From designated book (62), we can reach a author in 2 ways:
  // book -> author_id
  // book -> assignations -> assignation_groups -> groups -> author
  // But we can also access author via groups
  // groups -> groups_to_author
  const sqlQueryInsertData = [
    `INSERT INTO author VALUES (1), (2), (3), (4);`,
    `INSERT INTO groups VALUES (10), (11), (12), (13);`,
    `INSERT INTO books_assignations (id) VALUES (20), (21), (22);`,
    // TODO: If you comment the next line, the test will pass, since it "cut" one of the two path link into the data
    `INSERT INTO books_assignations_groups (id, assignation_id, group_id) VALUES (40, 20, 11);`,
    `INSERT INTO groups_to_author (id, group_id, author_id) VALUES (50, 10, 1), (51, 10, 3), (52, 11, 2);`,
    `INSERT INTO books (id, author_id, assignation_id) VALUES (60, 1, NULL), (61, 1, NULL), (62, 1, 20), (63, 2, NULL);`,
  ]
  const prepareQueries = [...sqlQueryTableCreate, ...sqlQueryInsertData]

  for (const prepareStmt of prepareQueries) {
    await execQueryNext(prepareStmt, sourceConnectionString)
  }

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
          table: 'public.books',
          where: 'id = 62',
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
  const restoredBooks = await execQueryNext(
    `SELECT * FROM books`,
    targetConnectionString
  )
  const restoredAuthors = await execQueryNext(
    `SELECT * FROM author`,
    targetConnectionString
  )
  const restoredGroups = await execQueryNext(
    `SELECT * FROM groups`,
    targetConnectionString
  )
  const restoredBookAssignations = await execQueryNext(
    `SELECT * FROM books_assignations`,
    targetConnectionString
  )
  const restoredBookAssignationsGroups = await execQueryNext(
    `SELECT * FROM books_assignations_groups`,
    targetConnectionString
  )
  const restoredGroupToAuthor = await execQueryNext(
    `SELECT * FROM groups_to_author`,
    targetConnectionString
  )
  expect(restoredBooks.rowCount).toBe(2)
  expect(restoredAuthors.rowCount).toBe(2)
  expect(restoredGroups.rowCount).toBe(2)
  expect(restoredGroupToAuthor.rowCount).toBe(2)
  expect(restoredBookAssignations.rowCount).toBe(1)
  expect(restoredBookAssignationsGroups.rowCount).toBe(1)
  // The expected data gathered and walk should be:
  // Book 62 as an entrypoint
  // -> author: 1, book_assignations_id: 20
  // --> author: 1, groups_to_author: 50
  // ---> groups_to_author: 50, 1 single member (author: 1)
  // --> book_assignations_id: 20
  // ---> book_assignations_groups: 40, groups: 11
  // ----> groups: 11, group_to_author: 52
  // -----> group_to_author: 52, author: 2
  // ------> author: 2 , books: 63
  // -------> books: 63, no book assignations, no new author
  expect(restoredBooks.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 62,
        author_id: 1,
        assignation_id: 20,
      }),
      expect.objectContaining({
        id: 63,
        author_id: 2,
        assignation_id: null,
      }),
    ])
  )
  expect(restoredAuthors.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 1,
      }),
      expect.objectContaining({
        id: 2,
      }),
    ])
  )
  expect(restoredGroups.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 10,
      }),
      expect.objectContaining({
        id: 11,
      }),
    ])
  )
  expect(restoredGroupToAuthor.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 50,
        group_id: 10,
        author_id: 1,
      }),
      expect.objectContaining({
        id: 52,
        group_id: 11,
        author_id: 2,
      }),
    ])
  )
  expect(restoredBookAssignations.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 20,
      }),
    ])
  )
  expect(restoredBookAssignationsGroups.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 40,
        assignation_id: 20,
        group_id: 11,
      }),
    ])
  )
})
test('capturing and restoring with two differents paths growing the same tables on different schemas', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()
  const sqlQueryTableCreate = [
    `CREATE SCHEMA other;`,
    `CREATE TABLE "author" ("id" SERIAL PRIMARY KEY);`,
    `CREATE TABLE "groups" ("id" SERIAL PRIMARY KEY);`,
    `CREATE TABLE "groups_to_author" (
          "id" SERIAL PRIMARY KEY,
          group_id SERIAL NOT NULL,
          author_id SERIAL NOT NULL,
          CONSTRAINT "group_to_author_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "groups" ON DELETE CASCADE,
          CONSTRAINT "group_to_author_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "author" ON DELETE CASCADE
        );`,
    `CREATE TABLE other."books_assignations" ("id" SERIAL PRIMARY KEY);`,
    `CREATE TABLE "books_assignations_groups" (
          "id" SERIAL PRIMARY KEY,
          assignation_id SERIAL NOT NULL,
          group_id SERIAL NOT NULL,
          CONSTRAINT "books_assignations_to_groups_id_fkey" FOREIGN KEY ("assignation_id") REFERENCES other."books_assignations" ON DELETE CASCADE,
          CONSTRAINT "books_assignations_to_groups_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "groups" ON DELETE CASCADE
        );`,
    `CREATE TABLE "books" (
          "id" SERIAL PRIMARY KEY,
          "author_id" SERIAL NOT NULL,
          "assignation_id" INTEGER DEFAULT NULL,
          CONSTRAINT "books_assignations_id_fkey" FOREIGN KEY ("assignation_id") REFERENCES other."books_assignations" ON DELETE CASCADE,
          CONSTRAINT "books_authors_id_fkey" FOREIGN KEY ("author_id") REFERENCES "author" ON DELETE CASCADE
        );`,
  ]
  // Basically we create a topology like so:
  // From designated book (62), we can reach a author in 2 ways:
  // book -> author_id
  // book -> assignations -> assignation_groups -> groups -> author
  // But we can also access author via groups
  // groups -> groups_to_author
  const sqlQueryInsertData = [
    `INSERT INTO author VALUES (1), (2), (3), (4);`,
    `INSERT INTO groups VALUES (10), (11), (12), (13);`,
    `INSERT INTO other.books_assignations (id) VALUES (20), (21), (22);`,
    // TODO: If you comment the next line, the test will pass, since it "cut" one of the two path link into the data
    `INSERT INTO books_assignations_groups (id, assignation_id, group_id) VALUES (40, 20, 11);`,
    `INSERT INTO groups_to_author (id, group_id, author_id) VALUES (50, 10, 1), (51, 10, 3), (52, 11, 2);`,
    `INSERT INTO books (id, author_id, assignation_id) VALUES (60, 1, NULL), (61, 1, NULL), (62, 1, 20), (63, 2, NULL);`,
  ]
  const prepareQueries = [...sqlQueryTableCreate, ...sqlQueryInsertData]

  for (const prepareStmt of prepareQueries) {
    await execQueryNext(prepareStmt, sourceConnectionString)
  }

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
          table: 'public.books',
          where: 'id = 62',
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
  const restoredBooks = await execQueryNext(
    `SELECT * FROM books`,
    targetConnectionString
  )
  const restoredAuthors = await execQueryNext(
    `SELECT * FROM author`,
    targetConnectionString
  )
  const restoredGroups = await execQueryNext(
    `SELECT * FROM groups`,
    targetConnectionString
  )
  const restoredBookAssignations = await execQueryNext(
    `SELECT * FROM other.books_assignations`,
    targetConnectionString
  )
  const restoredBookAssignationsGroups = await execQueryNext(
    `SELECT * FROM books_assignations_groups`,
    targetConnectionString
  )
  const restoredGroupToAuthor = await execQueryNext(
    `SELECT * FROM groups_to_author`,
    targetConnectionString
  )
  expect(restoredBooks.rowCount).toBe(2)
  expect(restoredAuthors.rowCount).toBe(2)
  expect(restoredGroups.rowCount).toBe(2)
  expect(restoredGroupToAuthor.rowCount).toBe(2)
  expect(restoredBookAssignations.rowCount).toBe(1)
  expect(restoredBookAssignationsGroups.rowCount).toBe(1)
  // The expected data gathered and walk should be:
  // Book 62 as an entrypoint
  // -> author: 1, book_assignations_id: 20
  // --> author: 1, groups_to_author: 50
  // ---> groups_to_author: 50, 1 single member (author: 1)
  // --> book_assignations_id: 20
  // ---> book_assignations_groups: 40, groups: 11
  // ----> groups: 11, group_to_author: 52
  // -----> group_to_author: 52, author: 2
  // ------> author: 2 , books: 63
  // -------> books: 63, no book assignations, no new author
  expect(restoredBooks.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 62,
        author_id: 1,
        assignation_id: 20,
      }),
      expect.objectContaining({
        id: 63,
        author_id: 2,
        assignation_id: null,
      }),
    ])
  )
  expect(restoredAuthors.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 1,
      }),
      expect.objectContaining({
        id: 2,
      }),
    ])
  )
  expect(restoredGroups.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 10,
      }),
      expect.objectContaining({
        id: 11,
      }),
    ])
  )
  expect(restoredGroupToAuthor.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 50,
        group_id: 10,
        author_id: 1,
      }),
      expect.objectContaining({
        id: 52,
        group_id: 11,
        author_id: 2,
      }),
    ])
  )
  expect(restoredBookAssignations.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 20,
      }),
    ])
  )
  expect(restoredBookAssignationsGroups.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 40,
        assignation_id: 20,
        group_id: 11,
      }),
    ])
  )
})
test('capturing and restoring with two differents paths growing the same tables books_assignations_groups entrypoint lazy', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()
  const sqlQueryTableCreate = [
    `CREATE TABLE "author" ("id" SERIAL PRIMARY KEY);`,
    `CREATE TABLE "groups" ("id" SERIAL PRIMARY KEY);`,
    `CREATE TABLE "groups_to_author" (
          "id" SERIAL PRIMARY KEY,
          group_id SERIAL NOT NULL,
          author_id SERIAL NOT NULL,
          CONSTRAINT "group_to_author_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "groups" ON DELETE CASCADE,
          CONSTRAINT "group_to_author_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "author" ON DELETE CASCADE
        );`,
    `CREATE TABLE "books_assignations" ("id" SERIAL PRIMARY KEY);`,
    `CREATE TABLE "books_assignations_groups" (
          "id" SERIAL PRIMARY KEY,
          assignation_id SERIAL NOT NULL,
          group_id SERIAL NOT NULL,
          CONSTRAINT "books_assignations_to_groups_id_fkey" FOREIGN KEY ("assignation_id") REFERENCES "books_assignations" ON DELETE CASCADE,
          CONSTRAINT "books_assignations_to_groups_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "groups" ON DELETE CASCADE
        );`,
    `CREATE TABLE "books" (
          "id" SERIAL PRIMARY KEY,
          "author_id" SERIAL NOT NULL,
          "assignation_id" INTEGER DEFAULT NULL,
          CONSTRAINT "books_assignations_id_fkey" FOREIGN KEY ("assignation_id") REFERENCES "books_assignations" ON DELETE CASCADE,
          CONSTRAINT "books_authors_id_fkey" FOREIGN KEY ("author_id") REFERENCES "author" ON DELETE CASCADE
        );`,
  ]
  // Basically we create a topology like so:
  // From designated book (62), we can reach a author in 2 ways:
  // book -> author_id
  // book -> assignations -> assignation_groups -> groups -> author
  // But we can also access author via groups
  // groups -> groups_to_author
  const sqlQueryInsertData = [
    `INSERT INTO author VALUES (1), (2), (3), (4);`,
    `INSERT INTO groups VALUES (10), (11), (12), (13);`,
    `INSERT INTO books_assignations (id) VALUES (20), (21), (22);`,
    // TODO: If you comment the next line, the test will pass, since it "cut" one of the two path link into the data
    `INSERT INTO books_assignations_groups (id, assignation_id, group_id) VALUES (40, 20, 11);`,
    `INSERT INTO groups_to_author (id, group_id, author_id) VALUES (50, 10, 1), (51, 10, 3), (52, 11, 2);`,
    `INSERT INTO books (id, author_id, assignation_id) VALUES (60, 1, NULL), (61, 1, NULL), (62, 1, 20), (63, 2, NULL);`,
  ]
  const prepareQueries = [...sqlQueryTableCreate, ...sqlQueryInsertData]

  for (const prepareStmt of prepareQueries) {
    await execQueryNext(prepareStmt, sourceConnectionString)
  }

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
          table: 'public.books_assignations_groups',
          where: 'id = 40',
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
  const restoredBooks = await execQueryNext(
    `SELECT * FROM books`,
    targetConnectionString
  )
  const restoredAuthors = await execQueryNext(
    `SELECT * FROM author`,
    targetConnectionString
  )
  const restoredGroups = await execQueryNext(
    `SELECT * FROM groups`,
    targetConnectionString
  )
  const restoredBookAssignations = await execQueryNext(
    `SELECT * FROM books_assignations`,
    targetConnectionString
  )
  const restoredBookAssignationsGroups = await execQueryNext(
    `SELECT * FROM books_assignations_groups`,
    targetConnectionString
  )
  const restoredGroupToAuthor = await execQueryNext(
    `SELECT * FROM groups_to_author`,
    targetConnectionString
  )
  expect(restoredBooks.rowCount).toBe(2)
  expect(restoredAuthors.rowCount).toBe(2)
  expect(restoredGroups.rowCount).toBe(2)
  expect(restoredGroupToAuthor.rowCount).toBe(2)
  expect(restoredBookAssignations.rowCount).toBe(1)
  expect(restoredBookAssignationsGroups.rowCount).toBe(1)
  // The expected data gathered and walk should be:
  // books_assignations_groups 40 as an entrypoint
  // -> book_assignations_groups: 40, groups: 11
  // --> groups: 11, group_to_author: 52
  // ---> group_to_author: 52, author: 2
  // ----> author: 2 , books: 63
  // -----> books: 63, no book assignations, no new author
  // --> book_assignations_id: 20, group_to_author: 50
  // ---> groups_to_author: 50, author: 1, group: 11
  // ----> group: 11 (no other groups_to_author)
  // ----> author: 1, books: 62
  // ----> books: 62, book_assignations_id (20, not new), author_id: (1 not new)
  expect(restoredBooks.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 62,
        author_id: 1,
        assignation_id: 20,
      }),
      expect.objectContaining({
        id: 63,
        author_id: 2,
        assignation_id: null,
      }),
    ])
  )
  expect(restoredAuthors.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 1,
      }),
      expect.objectContaining({
        id: 2,
      }),
    ])
  )
  expect(restoredGroups.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 10,
      }),
      expect.objectContaining({
        id: 11,
      }),
    ])
  )
  expect(restoredGroupToAuthor.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 50,
        group_id: 10,
        author_id: 1,
      }),
      expect.objectContaining({
        id: 52,
        group_id: 11,
        author_id: 2,
      }),
    ])
  )
  expect(restoredBookAssignations.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 20,
      }),
    ])
  )
  expect(restoredBookAssignationsGroups.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 40,
        assignation_id: 20,
        group_id: 11,
      }),
    ])
  )
})
test('capturing and restoring with two differents paths growing the same tables books_assignations_groups entrypoint eager', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()
  const sqlQueryTableCreate = [
    `CREATE TABLE "author" ("id" SERIAL PRIMARY KEY);`,
    `CREATE TABLE "groups" ("id" SERIAL PRIMARY KEY);`,
    `CREATE TABLE "groups_to_author" (
          "id" SERIAL PRIMARY KEY,
          group_id SERIAL NOT NULL,
          author_id SERIAL NOT NULL,
          CONSTRAINT "group_to_author_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "groups" ON DELETE CASCADE,
          CONSTRAINT "group_to_author_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "author" ON DELETE CASCADE
        );`,
    `CREATE TABLE "books_assignations" ("id" SERIAL PRIMARY KEY);`,
    `CREATE TABLE "books_assignations_groups" (
          "id" SERIAL PRIMARY KEY,
          assignation_id SERIAL NOT NULL,
          group_id SERIAL NOT NULL,
          CONSTRAINT "books_assignations_to_groups_id_fkey" FOREIGN KEY ("assignation_id") REFERENCES "books_assignations" ON DELETE CASCADE,
          CONSTRAINT "books_assignations_to_groups_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "groups" ON DELETE CASCADE
        );`,
    `CREATE TABLE "books" (
          "id" SERIAL PRIMARY KEY,
          "author_id" SERIAL NOT NULL,
          "assignation_id" INTEGER DEFAULT NULL,
          CONSTRAINT "books_assignations_id_fkey" FOREIGN KEY ("assignation_id") REFERENCES "books_assignations" ON DELETE CASCADE,
          CONSTRAINT "books_authors_id_fkey" FOREIGN KEY ("author_id") REFERENCES "author" ON DELETE CASCADE
        );`,
  ]
  // Basically we create a topology like so:
  // From designated book (62), we can reach a author in 2 ways:
  // book -> author_id
  // book -> assignations -> assignation_groups -> groups -> author
  // But we can also access author via groups
  // groups -> groups_to_author
  const sqlQueryInsertData = [
    `INSERT INTO author VALUES (1), (2), (3), (4);`,
    `INSERT INTO groups VALUES (10), (11), (12), (13);`,
    `INSERT INTO books_assignations (id) VALUES (20), (21), (22);`,
    // TODO: If you comment the next line, the test will pass, since it "cut" one of the two path link into the data
    `INSERT INTO books_assignations_groups (id, assignation_id, group_id) VALUES (40, 20, 11);`,
    `INSERT INTO groups_to_author (id, group_id, author_id) VALUES (50, 10, 1), (51, 10, 3), (52, 11, 2);`,
    `INSERT INTO books (id, author_id, assignation_id) VALUES (60, 1, NULL), (61, 1, NULL), (62, 1, 20), (63, 2, NULL);`,
  ]
  const prepareQueries = [...sqlQueryTableCreate, ...sqlQueryInsertData]

  for (const prepareStmt of prepareQueries) {
    await execQueryNext(prepareStmt, sourceConnectionString)
  }

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      maxCyclesLoop: 10,
      eager: true,
      keepDisconnectedTables: true,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.books_assignations_groups',
          where: 'id = 40',
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
  const restoredBooks = await execQueryNext(
    `SELECT * FROM books`,
    targetConnectionString
  )
  const restoredAuthors = await execQueryNext(
    `SELECT * FROM author`,
    targetConnectionString
  )
  const restoredGroups = await execQueryNext(
    `SELECT * FROM groups`,
    targetConnectionString
  )
  const restoredBookAssignations = await execQueryNext(
    `SELECT * FROM books_assignations`,
    targetConnectionString
  )
  const restoredBookAssignationsGroups = await execQueryNext(
    `SELECT * FROM books_assignations_groups`,
    targetConnectionString
  )
  const restoredGroupToAuthor = await execQueryNext(
    `SELECT * FROM groups_to_author`,
    targetConnectionString
  )
  expect(restoredBooks.rowCount).toBe(4)
  expect(restoredAuthors.rowCount).toBe(3)
  expect(restoredGroups.rowCount).toBe(2)
  expect(restoredGroupToAuthor.rowCount).toBe(3)
  expect(restoredBookAssignations.rowCount).toBe(1)
  expect(restoredBookAssignationsGroups.rowCount).toBe(1)

  expect(restoredBooks.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 60,
        author_id: 1,
        assignation_id: null,
      }),
      expect.objectContaining({
        id: 61,
        author_id: 1,
        assignation_id: null,
      }),
      expect.objectContaining({
        id: 62,
        author_id: 1,
        assignation_id: 20,
      }),
      expect.objectContaining({
        id: 63,
        author_id: 2,
        assignation_id: null,
      }),
    ])
  )
  expect(restoredAuthors.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 1,
      }),
      expect.objectContaining({
        id: 2,
      }),
      expect.objectContaining({
        id: 3,
      }),
    ])
  )
  expect(restoredGroups.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 10,
      }),
      expect.objectContaining({
        id: 11,
      }),
    ])
  )
  expect(restoredGroupToAuthor.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 50,
        group_id: 10,
        author_id: 1,
      }),
      expect.objectContaining({
        id: 51,
        group_id: 10,
        author_id: 3,
      }),
      expect.objectContaining({
        id: 52,
        group_id: 11,
        author_id: 2,
      }),
    ])
  )
  expect(restoredBookAssignations.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 20,
      }),
    ])
  )
  expect(restoredBookAssignationsGroups.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 40,
        assignation_id: 20,
        group_id: 11,
      }),
    ])
  )
})
test('capturing and restoring database with table with composite PK', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await execQueryNext(
    `CREATE TABLE "db"
          (
              id INT NOT NULL,
              name text NOT NULL,
              PRIMARY KEY (id)
          );`,
    sourceConnectionString
  )
  await execQueryNext(
    `
        CREATE TABLE "user"
        (
            id INT NOT NULL,
            primary_db_id INT DEFAULT NULL,
            secondary_db_id INT DEFAULT NULL,
            PRIMARY KEY (id),
            CONSTRAINT fk_primary_db FOREIGN KEY (primary_db_id) REFERENCES "db"(id),
            CONSTRAINT fk_secondary_db FOREIGN KEY (secondary_db_id) REFERENCES "db"(id)
        );`,
    sourceConnectionString
  )
  await execQueryNext(
    `
        CREATE TABLE "db_to_user" (
            "a" INT NOT NULL,
            "b" INT NOT NULL,
            CONSTRAINT "fk_db_to_user_a" FOREIGN KEY ("a")
                REFERENCES public."user" (id) MATCH SIMPLE
                ON UPDATE CASCADE
                ON DELETE CASCADE,
            CONSTRAINT "fk_db_to_user_b" FOREIGN KEY ("b")
                REFERENCES public."db" (id) MATCH SIMPLE
                ON UPDATE CASCADE
                ON DELETE CASCADE,
            PRIMARY KEY ("a", "b")
          )
      `,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `INSERT INTO "db" (id, name) VALUES (1, 'a');`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "db" (id, name) VALUES (2, 'b');`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "user" (id, primary_db_id, secondary_db_id) VALUES (1, 1, 2);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO db_to_user VALUES (1, 1);`,
    sourceConnectionString
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      eager: true,
      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.db_to_user',
          percent: 100,
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
test('capturing and restoring database with table with composite PK should not fail', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await execQueryNext(
    `CREATE TABLE "db"
          (
              id INT NOT NULL,
              name text NOT NULL,
              PRIMARY KEY (id)
          );`,
    sourceConnectionString
  )
  await execQueryNext(
    `
        CREATE TABLE "user"
        (
            id INT NOT NULL,
            primary_db_id INT DEFAULT NULL,
            secondary_db_id INT DEFAULT NULL,
            PRIMARY KEY (id),
            CONSTRAINT fk_primary_db FOREIGN KEY (primary_db_id) REFERENCES "db"(id),
            CONSTRAINT fk_secondary_db FOREIGN KEY (secondary_db_id) REFERENCES "db"(id)
        );`,
    sourceConnectionString
  )
  await execQueryNext(
    `
        CREATE TABLE "db_to_user" (
            "a" INT NOT NULL,
            "b" INT NOT NULL,
            CONSTRAINT "fk_db_to_user_a" FOREIGN KEY ("a")
                REFERENCES public."user" (id) MATCH SIMPLE
                ON UPDATE CASCADE
                ON DELETE CASCADE,
            CONSTRAINT "fk_db_to_user_b" FOREIGN KEY ("b")
                REFERENCES public."db" (id) MATCH SIMPLE
                ON UPDATE CASCADE
                ON DELETE CASCADE,
            PRIMARY KEY ("a", "b")
          )
      `,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `INSERT INTO "db" (id, name) VALUES (1, 'a');`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "db" (id, name) VALUES (2, 'b');`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "user" (id, primary_db_id, secondary_db_id) VALUES (1, 1, 2);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO db_to_user VALUES (1, 1);`,
    sourceConnectionString
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      eager: true,
      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.db',
          percent: 100,
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
  const resultDb = await execQueryNext(
    `SELECT * FROM db`,
    targetConnectionString
  )
  expect(resultDb.rowCount).toBe(2)
})
test('capturing and restoring with two parents FK pointing to the same table', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()
  const sqlQueryTableCreate = `
      CREATE TABLE "author" (
        "id" SERIAL PRIMARY KEY
      )
    `
  await execQueryNext(sqlQueryTableCreate, sourceConnectionString)
  const sqlQueryBookCreate = `
      CREATE TABLE "book" (
        "id" SERIAL PRIMARY KEY,
        "author_id" INTEGER NOT NULL,
        CONSTRAINT "book_author_id_fkey" FOREIGN KEY ("author_id")
          REFERENCES "author" ("id")
          ON DELETE CASCADE
      )`
  await execQueryNext(sqlQueryBookCreate, sourceConnectionString)
  // Create publisher table
  const createPublisherTableQuery = `CREATE TABLE "publisher" ("id" SERIAL PRIMARY KEY)`
  await execQueryNext(createPublisherTableQuery, sourceConnectionString)
  // Add publisher_id to author table
  const addColPubQuery = `ALTER TABLE "author" ADD COLUMN "publisher_id" INTEGER NOT NULL`
  await execQueryNext(addColPubQuery, sourceConnectionString)
  const addForeignKeyPubQuery = `ALTER TABLE "author" ADD CONSTRAINT "author_publisher_fkey" FOREIGN KEY ("publisher_id") REFERENCES "publisher" ("id") ON DELETE SET NULL`
  await execQueryNext(addForeignKeyPubQuery, sourceConnectionString)
  // We already have one fk from book to the author table
  // Create another fk to author table
  const addColQuery = `ALTER TABLE "book" ADD COLUMN "author_id_2" INTEGER NOT NULL`
  await execQueryNext(addColQuery, sourceConnectionString)
  const addForeignKeyQuery = `ALTER TABLE "book" ADD CONSTRAINT "book_author_2_fkey" FOREIGN KEY ("author_id_2") REFERENCES "author" ("id") ON DELETE SET NULL`
  await execQueryNext(addForeignKeyQuery, sourceConnectionString)

  // Insert into Publisher 2 rows
  const insertPublisherQuery = `INSERT INTO "publisher" (id) VALUES (1), (2)`
  await execQueryNext(insertPublisherQuery, sourceConnectionString)

  // Insert Author
  const insertAuthorQuery = `INSERT INTO "author" (id, publisher_id) VALUES (10,1)`
  await execQueryNext(insertAuthorQuery, sourceConnectionString)
  const insertAuthorQuery2 = `INSERT INTO "author" (id, publisher_id) VALUES (11,2)`
  await execQueryNext(insertAuthorQuery2, sourceConnectionString)
  // Insert Book
  const insertBookQuery = `INSERT INTO "book" (id, author_id, author_id_2) VALUES (20, 10, 11)`
  await execQueryNext(insertBookQuery, sourceConnectionString)

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: true,
      targets: [
        {
          table: 'public.author',
          percent: 10,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(['snapshot', 'capture', ssPath.name], {
    SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
  })

  await runSnapletCLI(['snapshot restore', ssPath.name], {
    SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
  })
  await checkConstraints(
    sourceConnectionString.toString(),
    destinationConnectionString.toString()
  )
})
test('keepDisconnected should be graph based and not dump empty result tables', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()
  const sqlQueryTableCreate = `
      CREATE TABLE "author" (
        "id" SERIAL PRIMARY KEY
      )
    `
  await execQueryNext(sqlQueryTableCreate, sourceConnectionString)
  const sqlQueryBookCreate = `
      CREATE TABLE "book" (
        "id" SERIAL PRIMARY KEY,
        "author_id" INTEGER NOT NULL,
        CONSTRAINT "book_author_id_fkey" FOREIGN KEY ("author_id")
          REFERENCES "author" ("id")
          ON DELETE CASCADE
      )`
  await execQueryNext(sqlQueryBookCreate, sourceConnectionString)
  // Create publisher table
  const createPublisherTableQuery = `CREATE TABLE "publisher" ("id" SERIAL PRIMARY KEY)`
  await execQueryNext(createPublisherTableQuery, sourceConnectionString)
  // Create a completly disconnected table
  const createExtraDisconnected = `CREATE TABLE "extra_disconnected" ("id" SERIAL PRIMARY KEY)`
  await execQueryNext(createExtraDisconnected, sourceConnectionString)
  const insertExtraDisconnected = `INSERT INTO "extra_disconnected" (id) VALUES (1)`
  await execQueryNext(insertExtraDisconnected, sourceConnectionString)
  // Add publisher_id to author table
  const addColPubQuery = `ALTER TABLE "author" ADD COLUMN "publisher_id" INTEGER NOT NULL`
  await execQueryNext(addColPubQuery, sourceConnectionString)
  const addForeignKeyPubQuery = `ALTER TABLE "author" ADD CONSTRAINT "author_publisher_fkey" FOREIGN KEY ("publisher_id") REFERENCES "publisher" ("id") ON DELETE SET NULL`
  await execQueryNext(addForeignKeyPubQuery, sourceConnectionString)
  // We already have one fk from book to the author table
  // Create another fk to author table
  const addColQuery = `ALTER TABLE "book" ADD COLUMN "author_id_2" INTEGER NOT NULL`
  await execQueryNext(addColQuery, sourceConnectionString)
  const addForeignKeyQuery = `ALTER TABLE "book" ADD CONSTRAINT "book_author_2_fkey" FOREIGN KEY ("author_id_2") REFERENCES "author" ("id") ON DELETE SET NULL`
  await execQueryNext(addForeignKeyQuery, sourceConnectionString)

  // Insert into Publisher 2 rows
  const insertPublisherQuery = `INSERT INTO "publisher" (id) VALUES (1), (2)`
  await execQueryNext(insertPublisherQuery, sourceConnectionString)

  // Insert Author
  const insertAuthorQuery = `INSERT INTO "author" (id, publisher_id) VALUES (10,1)`
  await execQueryNext(insertAuthorQuery, sourceConnectionString)
  const insertAuthorQuery2 = `INSERT INTO "author" (id, publisher_id) VALUES (11,2)`
  await execQueryNext(insertAuthorQuery2, sourceConnectionString)
  // Insert Book
  const insertBookQuery = `INSERT INTO "book" (id, author_id, author_id_2) VALUES (20, 10, 11)`
  await execQueryNext(insertBookQuery, sourceConnectionString)
  await execQueryNext(`VACUUM`, sourceConnectionString)

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: true,
      targets: [
        {
          table: 'public.author',
          where: '"author"."id" = 12312',
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(['snapshot', 'capture', ssPath.name], {
    SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
  })

  await runSnapletCLI(['snapshot restore', ssPath.name], {
    SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
  })
  await checkConstraints(
    sourceConnectionString.toString(),
    destinationConnectionString.toString()
  )
  const authorCount = await execQueryNext(
    `SELECT COUNT(*) FROM "author"`,
    destinationConnectionString
  )
  const bookCount = await execQueryNext(
    `SELECT COUNT(*) FROM "book"`,
    destinationConnectionString
  )
  const publisherCount = await execQueryNext(
    `SELECT COUNT(*) FROM "publisher"`,
    destinationConnectionString
  )
  const extraDisconnectedCount = await execQueryNext(
    `SELECT COUNT(*) FROM "extra_disconnected"`,
    destinationConnectionString
  )
  expect(authorCount.rows[0].count).toEqual('0')
  expect(bookCount.rows[0].count).toEqual('0')
  expect(publisherCount.rows[0].count).toEqual('0')
  expect(extraDisconnectedCount.rows[0].count).toEqual('1')
})
test('gran children making parent grow dont follow nullable', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await execQueryNext(
    `CREATE TABLE "connexion"
          (
              id INT NOT NULL,
              db_connexion_one_id INT NOT NULL,
              db_connexion_two_id INT NOT NULL,
              PRIMARY KEY (id)
          );`,
    sourceConnectionString
  )
  await execQueryNext(
    `CREATE TABLE "db"
          (
              id INT NOT NULL,
              PRIMARY KEY (id),
              connexion_id INT DEFAULT NULL,
              CONSTRAINT fk_connexion_id FOREIGN KEY (connexion_id) REFERENCES "connexion"(id)
          );`,
    sourceConnectionString
  )
  await execQueryNext(
    `ALTER TABLE "connexion" ADD CONSTRAINT "db_connexion_one_id_fkey" FOREIGN KEY ("db_connexion_one_id") REFERENCES "db" ("id") ON DELETE SET NULL`,
    sourceConnectionString
  )
  await execQueryNext(
    `ALTER TABLE "connexion" ADD CONSTRAINT "db_connexion_two_id_fkey" FOREIGN KEY ("db_connexion_two_id") REFERENCES "db" ("id") ON DELETE SET NULL`,
    sourceConnectionString
  )
  await execQueryNext(
    `
        CREATE TABLE "user"
        (
            id INT NOT NULL,
            primary_db_id INT DEFAULT NULL,
            secondary_db_id INT DEFAULT NULL,
            PRIMARY KEY (id),
            CONSTRAINT fk_primary_db FOREIGN KEY (primary_db_id) REFERENCES "db"(id),
            CONSTRAINT fk_secondary_db FOREIGN KEY (secondary_db_id) REFERENCES "db"(id)
        );`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `INSERT INTO "db" (id) VALUES (1);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "db" (id) VALUES (2);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "db" (id) VALUES (3);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "db" (id) VALUES (4);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "connexion" (id, db_connexion_one_id, db_connexion_two_id) VALUES (1, 3, 4);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "db" (id, connexion_id) VALUES (5, 1);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "user" (id, primary_db_id, secondary_db_id) VALUES (1, 1, 5);`,
    sourceConnectionString
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      keepDisconnectedTables: false,
      targets: [
        {
          table: 'public.user',
          percent: 100,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(['snapshot', 'capture', ssPath.name], {
    SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
  })

  await runSnapletCLI(['snapshot restore', ssPath.name], {
    SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
  })
  await checkConstraints(
    sourceConnectionString.toString(),
    destinationConnectionString.toString()
  )
})
test('gran children making parent grow', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await execQueryNext(
    `CREATE TABLE "connexion"
          (
              id INT NOT NULL,
              db_connexion_one_id INT NOT NULL,
              db_connexion_two_id INT NOT NULL,
              PRIMARY KEY (id)
          );`,
    sourceConnectionString
  )
  await execQueryNext(
    `CREATE TABLE "db"
          (
              id INT NOT NULL,
              PRIMARY KEY (id),
              connexion_id INT DEFAULT NULL,
              CONSTRAINT fk_connexion_id FOREIGN KEY (connexion_id) REFERENCES "connexion"(id)
          );`,
    sourceConnectionString
  )
  await execQueryNext(
    `ALTER TABLE "connexion" ADD CONSTRAINT "db_connexion_one_id_fkey" FOREIGN KEY ("db_connexion_one_id") REFERENCES "db" ("id") ON DELETE SET NULL`,
    sourceConnectionString
  )
  await execQueryNext(
    `ALTER TABLE "connexion" ADD CONSTRAINT "db_connexion_two_id_fkey" FOREIGN KEY ("db_connexion_two_id") REFERENCES "db" ("id") ON DELETE SET NULL`,
    sourceConnectionString
  )
  await execQueryNext(
    `
        CREATE TABLE "user"
        (
            id INT NOT NULL,
            primary_db_id INT DEFAULT NULL,
            secondary_db_id INT DEFAULT NULL,
            PRIMARY KEY (id),
            CONSTRAINT fk_primary_db FOREIGN KEY (primary_db_id) REFERENCES "db"(id),
            CONSTRAINT fk_secondary_db FOREIGN KEY (secondary_db_id) REFERENCES "db"(id)
        );`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `INSERT INTO "db" (id) VALUES (1);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "db" (id) VALUES (2);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "db" (id) VALUES (3);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "db" (id) VALUES (4);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "connexion" (id, db_connexion_one_id, db_connexion_two_id) VALUES (1, 3, 4);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "db" (id, connexion_id) VALUES (5, 1);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "user" (id, primary_db_id, secondary_db_id) VALUES (1, 1, 5);`,
    sourceConnectionString
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      followNullableRelations: true,
      keepDisconnectedTables: false,
      targets: [
        {
          table: 'public.user',
          percent: 100,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(['snapshot', 'capture', ssPath.name], {
    SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
  })

  await runSnapletCLI(['snapshot restore', ssPath.name], {
    SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
  })
  await checkConstraints(
    sourceConnectionString.toString(),
    destinationConnectionString.toString()
  )
})
describe('capturing and restoring dense cyclic graph', () => {
  const dbStructure = `
  CREATE TABLE "Users" (
    "id" SERIAL PRIMARY KEY,
    "name" VARCHAR(255),
    "friend_id" INTEGER,
    CONSTRAINT "users_friend_id_fkey" FOREIGN KEY ("friend_id") REFERENCES "Users" ON DELETE CASCADE
  );
  CREATE TABLE "Posts" (
      "id" SERIAL PRIMARY KEY,
      "content" TEXT,
      "user_id" INTEGER NOT NULL,
      CONSTRAINT "posts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "Users" ON DELETE CASCADE
  );
  CREATE TABLE "Likes" (
      "user_id" INTEGER NOT NULL,
      "post_id" INTEGER NOT NULL,
      CONSTRAINT "likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "Users" ON DELETE CASCADE,
      CONSTRAINT "likes_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "Posts" ON DELETE CASCADE
  );
  INSERT INTO "Users" ("id", "name", "friend_id") VALUES (1, 'Alice', NULL), (2, 'Bob', 1), (3, 'Charlie', 2), (4, 'Dave', 3), (5, 'Eve', 4), (6, 'Frank', 5);
  UPDATE "Users" SET "friend_id" = 6 WHERE "id" = 1; -- This creates a cyclic relationship of friends.
  INSERT INTO "Posts" ("id", "content", "user_id") VALUES (10, 'Hello world!', 1), (11, 'Having a great day!', 2), (12, 'Enjoying the weather.', 3), (13, 'Reading a good book.', 4), (14, 'Working out.', 5), (15, 'Cooking dinner.', 6);
  INSERT INTO "Likes" ("user_id", "post_id") VALUES (1, 11), (1, 12), (1, 13), (1, 14), (1, 15), (2, 10), (3, 10), (4, 10), (5, 10), (6, 10);
  INSERT INTO "Users" ("id", "name", "friend_id") VALUES (7, 'George', 6), (8, 'Hannah', 7), (9, 'Ian', 8), (10, 'Jenny', 9), (11, 'Kevin', 10), (12, 'Lily', 11);
  UPDATE "Users" SET "friend_id" = 12 WHERE "id" = 7; -- This extends the cyclic relationship of friends.
  -- Adding more posts
  INSERT INTO "Posts" ("id", "content", "user_id") VALUES
  (16, 'Going for a walk.', 7),
  (17, 'Listening to music.', 8),
  (18, 'Baking cookies.', 9),
  (19, 'Playing video games.', 10),
  (20, 'Doing homework.', 11),
  (21, 'Watching a movie.', 12);
  -- Adding more likes
  INSERT INTO "Likes" ("user_id", "post_id") VALUES
  (7, 16), (7, 17), (7, 18), (7, 19), (7, 20),
  (8, 15), (8, 16), (8, 17), (8, 18), (8, 19),
  (9, 14), (9, 15), (9, 16), (9, 17), (9, 18),
  (10, 13), (10, 14), (10, 15), (10, 16), (10, 17),
  (11, 12), (11, 13), (11, 14), (11, 15), (11, 16),
  (12, 11), (12, 12), (12, 13), (12, 14), (12, 15);
  `
  test('capturing and restoring dense cyclic graph', async () => {
    const targetConnectionString = await createTestDb()
    const paths = await createTestProjectDirV2()
    const sourceConnectionString = await createTestDb(dbStructure)
    const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      maxCyclesLoop: 10,
      targets: [
        {
          table: 'public.Users',
          rowLimit: 1,
        },
      ],
      keepDisconnectedTables: false,
      eager: false,
      followNullableRelations: true,
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
    const usersResults = await execQueryNext(
      `SELECT 1 FROM public."Users"`,
      targetConnectionString.toString()
    )
    const likesResults = await execQueryNext(
      `SELECT 1 FROM public."Likes"`,
      targetConnectionString.toString()
    )
    const postsResults = await execQueryNext(
      `SELECT 1 FROM public."Posts"`,
      targetConnectionString.toString()
    )
    expect(likesResults.rowCount).toBe(35)
    expect(postsResults.rowCount).toBe(12)
    expect(usersResults.rowCount).toBe(12)
  })
  test('capturing and restoring dense cyclic graph maxCyclesLoop: 1', async () => {
    const targetConnectionString = await createTestDb()
    const paths = await createTestProjectDirV2()
    const sourceConnectionString = await createTestDb(dbStructure)
    const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      targets: [
        {
          table: 'public.Users',
          rowLimit: 1
        }
      ],
      keepDisconnectedTables: false,
      eager: false,
      followNullableRelations: true,
      maxCyclesLoop: 1
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
    const usersResults = await execQueryNext(
      `SELECT 1 FROM public."Users"`,
      targetConnectionString.toString()
    )
    const likesResults = await execQueryNext(
      `SELECT 1 FROM public."Likes"`,
      targetConnectionString.toString()
    )
    const postsResults = await execQueryNext(
      `SELECT 1 FROM public."Posts"`,
      targetConnectionString.toString()
    )
    expect(likesResults.rowCount).toBe(1)
    expect(postsResults.rowCount).toBe(2)
    expect(usersResults.rowCount).toBe(6)
  })
  test('capturing and restoring dense cyclic graph maxCyclesLoop: 1 and maxChildrenPerNode: 1', async () => {
    const targetConnectionString = await createTestDb()
    const paths = await createTestProjectDirV2()
    const sourceConnectionString = await createTestDb(dbStructure)
    const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      targets: [
        {
          table: 'public.Users',
          rowLimit: 1
        }
      ],
      keepDisconnectedTables: false,
      eager: false,
      followNullableRelations: true,
      maxChildrenPerNode: 1,
      maxCyclesLoop: 1
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
    const usersResults = await execQueryNext(
      `SELECT 1 FROM public."Users"`,
      targetConnectionString.toString()
    )
    const likesResults = await execQueryNext(
      `SELECT 1 FROM public."Likes"`,
      targetConnectionString.toString()
    )
    const postsResults = await execQueryNext(
      `SELECT 1 FROM public."Posts"`,
      targetConnectionString.toString()
    )
    expect(likesResults.rowCount).toBe(1)
    expect(postsResults.rowCount).toBe(2)
    expect(usersResults.rowCount).toBe(6)
  })
})
