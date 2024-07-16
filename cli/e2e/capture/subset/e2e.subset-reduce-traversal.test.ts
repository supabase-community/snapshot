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

test('user_account entries are populated in reduce traversal ', async () => {
  const paths = await createTestProjectDirV2()
  const structure = `
          CREATE TABLE organization (
            id SERIAL PRIMARY KEY,
            name text NOT NULL
          );
          CREATE TABLE user_account (
            id SERIAL PRIMARY KEY,
            name text NOT NULL,
            last_used_organization_id integer NOT NULL REFERENCES organization
          );
          CREATE TABLE "user" (
            id SERIAL PRIMARY KEY,
            name text NOT NULL,
            organization_id integer NOT NULL REFERENCES organization,
            user_account_id integer NOT NULL REFERENCES user_account
          );
        `

  const sourceConnectionString = (await createTestDb(structure)).toString()
  const targetConnectionString = (await createTestDb()).toString()
  const sqlInsert = `
    INSERT INTO "organization" VALUES (1, 'Linear'), (2, 'Snaplet');
    INSERT INTO "user_account" VALUES (1, 'user account 1', 2);
    INSERT INTO "user" VALUES(1, 'user 1', 1, 1);
  `
  await execQueryNext(sqlInsert, sourceConnectionString)
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    transform: {
    },
    subset: {
      enabled: true,
      version: '3',
      followNullableRelations: true,
      keepDisconnectedTables: false,
      targets: [
        {
          table: 'public.organization',
          percent: 50,
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
    paths
  )

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

  const userAccountResult = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "user_account"`,
    targetConnectionString
  )
  expect(userAccountResult.rows[0].count).toBe('1')

  const userResult = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "user"`,
    targetConnectionString
  )
  expect(userResult.rows[0].count).toBe('1')

  const orgResult = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "organization"`,
    targetConnectionString
  )
  // We requested 50% of organizations (1 of 2), but the relationships should also add the second organization
  expect(orgResult.rows[0].count).toBe('2')
})

test('exclude table that is a child of a included tables ', async () => {
  const structure = `
        CREATE TABLE "organization" (
          "id" SERIAL PRIMARY KEY,
          "name" VARCHAR(255) NOT NULL
        );
        CREATE TABLE "user_account" (
          "id" SERIAL PRIMARY KEY,
          "name" VARCHAR(255) NOT NULL
        );
        CREATE TABLE "user" (
          "id"  SERIAL PRIMARY KEY,
          "name" VARCHAR(255) NOT NULL,
          "organization_id" INTEGER NOT NULL,
          CONSTRAINT "user_organization_fkey" FOREIGN KEY ("organization_id") REFERENCES "organization" ("id") ON DELETE CASCADE,
          "user_account_id" INTEGER NOT NULL,
          CONSTRAINT "user_user_account_fkey" FOREIGN KEY ("user_account_id") REFERENCES "user_account" ("id") ON DELETE CASCADE
        );
      `
  const sourceConnectionString = (await createTestDb(structure)).toString()
  const targetConnectionString = (await createTestDb()).toString()
  const paths = await createTestProjectDirV2()
  const sqlInsert = `
      INSERT INTO "organization" VALUES
        (1, 'Linear'),
        (2, 'Snaplet');
      INSERT INTO "user_account" VALUES
      ( 10, 'user account 1'),
      ( 11, 'user account 2');
      INSERT INTO "user" VALUES
      ( 21, 'user 1', 1, 10),
      ( 22, 'user 2', 2, 11);`
  await execQueryNext(sqlInsert, sourceConnectionString)

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    select: {
      public: {
        user: "structure",
      },
    },
    transform: {
    },
    subset: {
      enabled: true,
      version: '3',
      followNullableRelations: true,
      keepDisconnectedTables: false,
      targets: [
        {
          table: 'public.organization',
          percent: 100,
          where: '"organization"."id" = 1',
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

  const userResult = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "user"`,
    targetConnectionString
  )
  expect(userResult.rows[0].count).toBe('0')

  const orgResult = await execQueryNext<{ count: number }>(
    `SELECT count(*) FROM "organization"`,
    targetConnectionString
  )
  expect(orgResult.rows[0].count).toBe('1')
})
