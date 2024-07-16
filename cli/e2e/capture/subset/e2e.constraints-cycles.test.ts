import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  checkConstraints,
  runSnapletCLI,
} from '../../../src/testing/index.js'
import fsExtra from 'fs-extra'

vi.setConfig({
  testTimeout: 10 * 60 * 1000,
})

test('capturing and restoring tables with auto-referencing cycle 1', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await execQueryNext(
    `CREATE TABLE "user"
        (
            id INT NOT NULL,
            creator_id INT DEFAULT NULL,
            PRIMARY KEY (id)
        );`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `ALTER TABLE "user" ADD CONSTRAINT "user_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "user" ("id") ON DELETE SET NULL`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `INSERT INTO "user" (id) VALUES (1);`,
    sourceConnectionString
  )
  // Auto reference user 1 as creator
  await execQueryNext(
    `UPDATE public."user" SET creator_id=1 WHERE id = 1;`,
    sourceConnectionString
  )

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.user',
          where: '"user"."id" = 2',
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
test('capturing and restoring tables with auto-referencing cycle 2', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await execQueryNext(
    `CREATE TABLE "user"
        (
            id INT NOT NULL,
            team_id INT DEFAULT NULL,
            PRIMARY KEY (id)
        );`,
    sourceConnectionString
  )
  await execQueryNext(
    `CREATE TABLE "team"
        (
            id INT NOT NULL,
            creator_id INT DEFAULT NULL,
            PRIMARY KEY (id)
        );`,
    sourceConnectionString
  )
  await execQueryNext(
    `ALTER TABLE "team" ADD CONSTRAINT "team_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "user" ("id") ON DELETE SET NULL`,
    sourceConnectionString
  )
  await execQueryNext(
    `ALTER TABLE "user" ADD CONSTRAINT "user_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "team" ("id") ON DELETE SET NULL`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `INSERT INTO "user" (id) VALUES (1);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "team" (id, creator_id) VALUES (1, 1);`,
    sourceConnectionString
  )
  // Auto reference user 1 as creator
  await execQueryNext(
    `UPDATE public."user" SET team_id=1 WHERE id = 1;`,
    sourceConnectionString
  )

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.user',
          where: '"user"."id" = 2',
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
test('capturing and restoring table with cycle of 1', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await execQueryNext(
    `CREATE TABLE "user"
        (
            id INT NOT NULL,
            creator_id INT DEFAULT NULL,
            PRIMARY KEY (id)
        );`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `ALTER TABLE "user" ADD CONSTRAINT "user_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "user" ("id") ON DELETE SET NULL`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `INSERT INTO "user" (id) VALUES (1);`,
    sourceConnectionString
  )
  for (let i = 1; i < 100; i += 1) {
    await execQueryNext(
      `INSERT INTO "user" (id, creator_id) VALUES (${i + 1}, ${i});`,
      sourceConnectionString
    )
  }
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.user',
          where: '"user"."id" = 2',
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
test('capturing and restoring table with cycle of 1 with parents', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await execQueryNext(
    `CREATE TABLE "user"
        (
            id INT NOT NULL,
            referee_id INT DEFAULT NULL,
            PRIMARY KEY (id)
        );`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `ALTER TABLE "user" ADD CONSTRAINT "user_referee_id_fkey" FOREIGN KEY ("referee_id") REFERENCES "user" ("id") ON DELETE SET NULL`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `INSERT INTO "user" (id) VALUES (1);`,
    sourceConnectionString
  )
  for (let i = 1; i < 100; i += 1) {
    await execQueryNext(
      `INSERT INTO "user" (id) VALUES (${i + 1});`,
      sourceConnectionString
    )
    await execQueryNext(
      `UPDATE "user" SET referee_id = ${i + 1} WHERE id = ${i};`,
      sourceConnectionString
    )
  }
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.user',
          where: '"user"."id" = 1',
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

  const results = await execQueryNext(
    `SELECT * FROM "user";`,
    targetConnectionString
  )
  expect(results.rowCount).toBe(100)

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
})
test('capturing and restoring table with cycle of 1 with childs', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await execQueryNext(
    `CREATE TABLE "user"
        (
            id INT NOT NULL,
            referee_id INT DEFAULT NULL,
            PRIMARY KEY (id)
        );`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `ALTER TABLE "user" ADD CONSTRAINT "user_referee_id_fkey" FOREIGN KEY ("referee_id") REFERENCES "user" ("id") ON DELETE SET NULL`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `INSERT INTO "user" (id) VALUES (1);`,
    sourceConnectionString
  )
  for (let i = 1; i < 100; i += 1) {
    await execQueryNext(
      `INSERT INTO "user" (id) VALUES (${i + 1});`,
      sourceConnectionString
    )
    await execQueryNext(
      `UPDATE "user" SET referee_id = ${i + 1} WHERE id = ${i};`,
      sourceConnectionString
    )
  }
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      followNullableRelations: true,
      maxCyclesLoop: 100,
      targets: [
        {
          table: 'public.user',
          where: '"user"."id" = 100',
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

  const results = await execQueryNext(
    `SELECT * FROM "user";`,
    targetConnectionString
  )
  expect(results.rowCount).toBe(100)

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
})
test('followNullableRelations should be true if undefined and keepDisconnectedTable false', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await execQueryNext(
    `CREATE TABLE "user"
        (
            id INT NOT NULL,
            referee_id INT DEFAULT NULL,
            PRIMARY KEY (id)
        );`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `ALTER TABLE "user" ADD CONSTRAINT "user_referee_id_fkey" FOREIGN KEY ("referee_id") REFERENCES "user" ("id") ON DELETE SET NULL`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `INSERT INTO "user" (id) VALUES (1);`,
    sourceConnectionString
  )
  for (let i = 1; i < 100; i += 1) {
    await execQueryNext(
      `INSERT INTO "user" (id) VALUES (${i + 1});`,
      sourceConnectionString
    )
    await execQueryNext(
      `UPDATE "user" SET referee_id = ${i + 1} WHERE id = ${i};`,
      sourceConnectionString
    )
  }
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      maxCyclesLoop: 100,
      targets: [
        {
          table: 'public.user',
          where: '"user"."id" = 100',
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

  const results = await execQueryNext(
    `SELECT * FROM "user";`,
    targetConnectionString
  )
  expect(results.rowCount).toBe(100)

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
})
test('capturing and restoring table with cycle of 1 until chain of dependency break', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await execQueryNext(
    `CREATE TABLE "user"
        (
            id INT NOT NULL,
            referee_id INT DEFAULT NULL,
            PRIMARY KEY (id)
        );`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `ALTER TABLE "user" ADD CONSTRAINT "user_referee_id_fkey" FOREIGN KEY ("referee_id") REFERENCES "user" ("id") ON DELETE SET NULL`,
    sourceConnectionString
  )
  // Insert a row with both fk values pointing to the same table but different rows
  await execQueryNext(
    `INSERT INTO "user" (id) VALUES (1);`,
    sourceConnectionString
  )
  for (let i = 1; i < 100; i += 1) {
    await execQueryNext(
      `INSERT INTO "user" (id) VALUES (${i + 1});`,
      sourceConnectionString
    )
    if (i != 50) {
      await execQueryNext(
        `UPDATE "user" SET referee_id = ${i + 1} WHERE id = ${i};`,
        sourceConnectionString
      )
    }
  }
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      followNullableRelations: true,
      maxCyclesLoop: 100,
      targets: [
        {
          table: 'public.user',
          where: '"user"."id" = 100',
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

  const results = await execQueryNext(
    `SELECT * FROM "user";`,
    targetConnectionString
  )
  expect(results.rowCount).toBe(50)

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
})
