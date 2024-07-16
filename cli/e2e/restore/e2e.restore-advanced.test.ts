import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
  VIDEOLET_PROJECT_ID,
  getTestAccessToken,
} from '../../src/testing/index.js'
import fsExtra from 'fs-extra'

vi.setConfig({
  testTimeout: 60_000,
})

describe(
  'Snaplet CLI',
  () => {
    describe('snapshot restore', () => {
      describe('--no-data', () => {
        test('should have the same result as --schema-only', async () => {
          const sourceConnectionString = await createTestDb()
          const destinationConnectionString = await createTestDb()
          const paths = await createTestProjectDirV2()
          await execQueryNext(
            `CREATE TABLE "inscreenshot" (
      count int
      )`,
            sourceConnectionString.toString()
          )
          await execQueryNext(
            `INSERT INTO "inscreenshot" VALUES (
      42
      )`,
            sourceConnectionString.toString()
          )
          const snapshotDir = createTestCapturePath().name

          await runSnapletCLI(
            ['snapshot', 'capture', snapshotDir],
            {
              SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
            },
            paths
          )
          await runSnapletCLI(
            ['snapshot restore', '--no-data', snapshotDir],
            {
              SNAPLET_TARGET_DATABASE_URL:
                destinationConnectionString.toString(),
            },
            paths
          ).catch((error) => error)

          const inscreenshotResult = await execQueryNext(
            'SELECT * FROM inscreenshot;',
            destinationConnectionString
          )
          // The table in the screenshot should now be empty
          expect(inscreenshotResult.rows).toEqual([])
        })
      })
      describe(
        '--no-reset',
        () => {
          test('should not drop existing table not in snapshot from database', async () => {
            const sourceConnectionString = await createTestDb()
            const destinationConnectionString = await createTestDb()
            const paths = await createTestProjectDirV2()
            // Create an fill inscreenshot table into source
            await execQueryNext(
              `CREATE TABLE "inscreenshot" (
             count int
          )`,
              sourceConnectionString.toString()
            )
            await execQueryNext(
              `INSERT INTO "inscreenshot" VALUES (
            42
          )`,
              sourceConnectionString.toString()
            )
            const snapshotDir = createTestCapturePath().name
            const configContent = `
          import { copycat } from "@snaplet/copycat";
          import { defineConfig } from "snaplet";

          export default defineConfig({})`
            await fsExtra.writeFile(paths.snapletConfig, configContent)

            await runSnapletCLI(
              ['snapshot', 'capture', snapshotDir],
              {
                SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
              },
              paths
            )
            // We create a table in the destination not in the snapshot should remain in place when restoring with --no-reset
            await execQueryNext(
              `CREATE TABLE "outsidescreenshot" (
             count int
          )`,
              destinationConnectionString.toString()
            )
            await execQueryNext(
              `INSERT INTO "outsidescreenshot" VALUES (
            42
          )`,
              destinationConnectionString.toString()
            )
            await runSnapletCLI(
              ['snapshot restore', '--no-reset', snapshotDir],
              {
                SNAPLET_TARGET_DATABASE_URL:
                  destinationConnectionString.toString(),
              },
              paths
            ).catch((error) => error)

            const outsideScreenshotResult = await execQueryNext(
              'SELECT * FROM outsidescreenshot;',
              destinationConnectionString
            )
            const inscreenshotResult = await execQueryNext(
              'SELECT * FROM inscreenshot;',
              destinationConnectionString
            )
            expect(outsideScreenshotResult.rows).toEqual([{ count: 42 }])
            expect(inscreenshotResult.rows).toEqual([{ count: 42 }])
          })
          test('Drop contraint in correct order issue. Using --no-reset --no-schema', async () => {
            const sourceConnectionString = await createTestDb()
            const destinationConnectionString = await createTestDb()
            const paths = await createTestProjectDirV2()

            for (let i = 0; i < 2; i++) {
              const connection =
                i === 0 ? sourceConnectionString : destinationConnectionString
              await execQueryNext(
                `CREATE TABLE public."Collection" (
                  id serial,
                  name text NOT NULL,
                  CONSTRAINT Collection_pkey PRIMARY KEY (id)
                ) tablespace pg_default;`,
                connection.toString()
              )

              await execQueryNext(
                `create table
                public."CollectionLink" (
                  name text not null,
                  "collectionId" integer not null,
                  "settingId" integer not null,
                  "trackLinkSettingId" integer not null,
                  "isWatermarked" boolean not null default false,
                  uid serial,
                  constraint CollectionLink_collectionId_fkey foreign key ("collectionId") references "Collection" (id) on update cascade on delete cascade
                ) tablespace pg_default;
              `,
                connection.toString()
              )

              await execQueryNext(
                `create unique index "CollectionLink_uid_key" on public."CollectionLink" using btree (uid) tablespace pg_default;`,
                connection.toString()
              )

              await execQueryNext(
                `create table
                public."Link" (
                  id serial,
                  name text not null,
                  "createdAt" timestamp without time zone not null default current_timestamp,
                  "workspaceId" integer not null,
                  "collectionLinkUid" integer null,
                  "landingPageUid" integer null,
                  "trackLinkUid" integer null,
                  constraint Link_pkey primary key (id),
                  constraint Link_collectionLinkUid_fkey foreign key ("collectionLinkUid") references "CollectionLink" (uid)
                ) tablespace pg_default;`,
                connection.toString()
              )

              // Insert some data
              await execQueryNext(
                `INSERT INTO "Collection" (name) VALUES ('Collection 1')`,
                connection.toString()
              )

              await execQueryNext(
                `INSERT INTO public."CollectionLink" (name, "collectionId", "settingId", "trackLinkSettingId", "isWatermarked") VALUES ('CollectionLink Name', 1, 1, 1, false);`,
                connection.toString()
              )

              await execQueryNext(
                `INSERT INTO public."Link" ("name", "workspaceId", "collectionLinkUid", "landingPageUid", "trackLinkUid") VALUES ('Link 1', 1, 1, 1, 1)`,
                connection.toString()
              )
            }
            const snapshotDir = createTestCapturePath().name
            const configContent = `
            import { copycat } from "@snaplet/copycat";
            import { defineConfig } from "snaplet";

            export default defineConfig({})`
            await fsExtra.writeFile(paths.snapletConfig, configContent)

            await runSnapletCLI(
              ['snapshot', 'capture', snapshotDir],
              {
                SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
              },
              paths
            )

            const restoreOutput = await runSnapletCLI(
              ['snapshot restore', '--no-reset --no-schema', snapshotDir],
              {
                SNAPLET_TARGET_DATABASE_URL:
                  destinationConnectionString.toString(),
              },
              paths
            ).catch((error) => error)

            expect(restoreOutput.stdout).not.toContain(
              '[Drop constraints] Warning:'
            )
          })
          test('should not drop existing table with --no-data and should not import the data', async () => {
            const sourceConnectionString = await createTestDb()
            const destinationConnectionString = await createTestDb()
            const paths = await createTestProjectDirV2()
            await execQueryNext(
              `CREATE TABLE "inscreenshot" (
             count int
          )`,
              sourceConnectionString.toString()
            )
            await execQueryNext(
              `INSERT INTO "inscreenshot" VALUES (
            42
          )`,
              sourceConnectionString.toString()
            )
            const snapshotDir = createTestCapturePath().name
            const configContent = `
          import { copycat } from "@snaplet/copycat";
          import { defineConfig } from "snaplet";

          export default defineConfig({})`
            await fsExtra.writeFile(paths.snapletConfig, configContent)

            await runSnapletCLI(
              ['snapshot', 'capture', snapshotDir],
              {
                SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
              },
              paths
            )
            // We create a table in the destination not in the snapshot, she should remain in place when restoring
            await execQueryNext(
              `CREATE TABLE "outsidescreenshot" (
             count int
          )`,
              destinationConnectionString.toString()
            )
            await execQueryNext(
              `INSERT INTO "outsidescreenshot" VALUES (
            42
          )`,
              destinationConnectionString.toString()
            )
            await runSnapletCLI(
              ['snapshot restore', '--no-reset', '--no-data', snapshotDir],
              {
                SNAPLET_TARGET_DATABASE_URL:
                  destinationConnectionString.toString(),
              },
              paths
            ).catch((error) => error)

            const outsideScreenshotResult = await execQueryNext(
              'SELECT * FROM outsidescreenshot;',
              destinationConnectionString
            )
            const inscreenshotResult = await execQueryNext(
              'SELECT * FROM inscreenshot;',
              destinationConnectionString
            )
            // Our existing table out of the schema should remain unchanged
            expect(outsideScreenshotResult.rows).toEqual([{ count: 42 }])
            // The table in the screenshot should now be empty
            expect(inscreenshotResult.rows).toEqual([])
          })
          test('should work with a compressed snapshot', async () => {
            const sourceConnectionString = await createTestDb()
            const destinationConnectionString = await createTestDb()
            const paths = await createTestProjectDirV2()
            const accessToken = await getTestAccessToken(VIDEOLET_PROJECT_ID)
            // Create an fill inscreenshot table into source
            await execQueryNext(
              `CREATE TABLE "inscreenshot" (
             count int
          )`,
              sourceConnectionString.toString()
            )
            await execQueryNext(
              `INSERT INTO "inscreenshot" VALUES (
            42
          )`,
              sourceConnectionString.toString()
            )
            const snapshotDir = createTestCapturePath().name
            const configContent = `
          import { copycat } from "@snaplet/copycat";
          import { defineConfig } from "snaplet";

          export default defineConfig({})`
            await fsExtra.writeFile(paths.snapletConfig, configContent)

            await runSnapletCLI(
              ['snapshot', 'capture', snapshotDir],
              {
                SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
                SNAPLET_PROJECT_ID: VIDEOLET_PROJECT_ID,
              },
              paths
            )
            // Ensure the snapshot will be compressed in the cloud
            await runSnapletCLI(
              ['snapshot', 'share', snapshotDir, '--no-encrypt'],
              {
                SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
                SNAPLET_PROJECT_ID: VIDEOLET_PROJECT_ID,
                SNAPLET_ACCESS_TOKEN: accessToken,
              },
              paths
            )
            // Ensure we'll re-download the compressed snapshot from the cloud
            await fsExtra.remove(snapshotDir)
            // We create a table in the destination not in the snapshot should remain in place when restoring with --no-reset
            await execQueryNext(
              `CREATE TABLE "outsidescreenshot" (
          count int
          )`,
              destinationConnectionString.toString()
            )
            await execQueryNext(
              `INSERT INTO "outsidescreenshot" VALUES (
          42
          )`,
              destinationConnectionString.toString()
            )
            await runSnapletCLI(
              ['snapshot restore', '--no-reset', '--latest'],
              {
                SNAPLET_TARGET_DATABASE_URL:
                  destinationConnectionString.toString(),
                SNAPLET_PROJECT_ID: VIDEOLET_PROJECT_ID,
                SNAPLET_ACCESS_TOKEN: accessToken,
              },
              paths
            ).catch((error) => error)

            const outsideScreenshotResult = await execQueryNext(
              'SELECT * FROM outsidescreenshot;',
              destinationConnectionString
            )
            const inscreenshotResult = await execQueryNext(
              'SELECT * FROM inscreenshot;',
              destinationConnectionString
            )
            expect(outsideScreenshotResult.rows).toEqual([{ count: 42 }])
            expect(inscreenshotResult.rows).toEqual([{ count: 42 }])
          })
        },
        // This test is flawky because we hit the api with --latest allow it to retry 3 times
        { retry: 3 }
      )
      describe('schema relations', () => {
        test('should work with basic one-to-many relations', async () => {
          const sourceConnectionString = await createTestDb()
          const destinationConnectionString = await createTestDb()
          const paths = await createTestProjectDirV2()
          const snapshotDir = createTestCapturePath().name
          const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({})`
          await fsExtra.writeFile(paths.snapletConfig, configContent)
          // That's a classical OneToMany relationship pattern.
          // 1. We have users
          // 2. We have teams
          // 3. A team can have several users
          // 4. An user can be in a single team or no team at all
          await execQueryNext(
            `CREATE TABLE "team"
      (
                  id INT GENERATED ALWAYS AS IDENTITY,
      name text NOT NULL,
      PRIMARY KEY (id)
      );`,
            sourceConnectionString.toString()
          )
          await execQueryNext(
            `CREATE TABLE "user"
      (
                id INT GENERATED ALWAYS AS IDENTITY,
      name text NOT NULL,
      team_id INT DEFAULT NULL,
      PRIMARY KEY (id),
      CONSTRAINT fk_team FOREIGN KEY (team_id) REFERENCES "team"(id)
      );`,
            sourceConnectionString.toString()
          )

          // Retrieve the actual constraints on the source database
          const constraintsSource = await execQueryNext(
            `
            SELECT
      tc.table_schema,
      tc.constraint_name,
      tc.table_name,
      kcu.column_name,
      ccu.table_schema AS foreign_table_schema,
      ccu.table_name AS foreign_table_name,
      ccu.column_name AS foreign_column_name
      FROM
      information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
      JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
      WHERE tc.table_schema = 'public'
      `,
            sourceConnectionString.toString()
          )

          await runSnapletCLI(
            ['snapshot', 'capture', snapshotDir],
            {
              SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
            },
            paths
          )
          await runSnapletCLI(
            ['snapshot restore', snapshotDir],
            {
              SNAPLET_TARGET_DATABASE_URL:
                destinationConnectionString.toString(),
            },
            paths
          ).catch((error) => error)

          // Retrieve the actual constraints in place on the restored database
          const constraintsRestored = await execQueryNext(
            `
              SELECT
                  tc.table_schema,
                  tc.constraint_name,
                  tc.table_name,
                  kcu.column_name,
                  ccu.table_schema AS foreign_table_schema,
                  ccu.table_name AS foreign_table_name,
                  ccu.column_name AS foreign_column_name
              FROM
                  information_schema.table_constraints AS tc
                  JOIN information_schema.key_column_usage AS kcu
                    ON tc.constraint_name = kcu.constraint_name
                    AND tc.table_schema = kcu.table_schema
                  JOIN information_schema.constraint_column_usage AS ccu
                    ON ccu.constraint_name = tc.constraint_name
                    AND ccu.table_schema = tc.table_schema
              WHERE tc.table_schema = 'public'
          `,
            destinationConnectionString.toString()
          )
          // The two extracted tables structures.json should be the same into the database
          expect(constraintsSource.rows).toEqual(
            expect.arrayContaining(constraintsRestored.rows)
          )
        })
        test('should work with basic many-to-many linking table', async () => {
          const sourceConnectionString = await createTestDb()
          const destinationConnectionString = await createTestDb()
          const paths = await createTestProjectDirV2()
          const snapshotDir = createTestCapturePath().name
          const configContent = `
          import { copycat } from "@snaplet/copycat";
          import { defineConfig } from "snaplet";

          export default defineConfig({})`
          await fsExtra.writeFile(paths.snapletConfig, configContent)
          // That's a classical ManyToMany relationship pattern.
          // 1. We have members
          // 2. We have teams
          // 3. Teams are composed of zero, one, or more users
          // 4. Users can be into multiples teams at the same time
          // 5. So we have our two tables, and a linking table which bind teams and users togethers.

          await execQueryNext(
            `CREATE TABLE "user"
              (
                id INT GENERATED ALWAYS AS IDENTITY,
                name text NOT NULL,
                PRIMARY KEY (id)
              );`,
            sourceConnectionString.toString()
          )
          await execQueryNext(
            `CREATE TABLE "team"
              (
                  id INT GENERATED ALWAYS AS IDENTITY,
                  name text NOT NULL,
                  PRIMARY KEY (id)
              );`,
            sourceConnectionString.toString()
          )
          await execQueryNext(
            `CREATE TABLE "team_to_user"
              (
                  id INT GENERATED ALWAYS AS IDENTITY,
                  user_id integer NOT NULL,
                  team_id integer NOT NULL,
                  PRIMARY KEY (id),
                  CONSTRAINT fk_team FOREIGN KEY (team_id) REFERENCES "team"(id),
                  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES "user"(id)
              );`,
            sourceConnectionString.toString()
          )

          // Retrieve the actual constraints on the source database
          const constraintsSource = await execQueryNext(
            `
            SELECT
                tc.table_schema,
                tc.constraint_name,
                tc.table_name,
                kcu.column_name,
                ccu.table_schema AS foreign_table_schema,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name
            FROM
                information_schema.table_constraints AS tc
                JOIN information_schema.key_column_usage AS kcu
                  ON tc.constraint_name = kcu.constraint_name
                  AND tc.table_schema = kcu.table_schema
                JOIN information_schema.constraint_column_usage AS ccu
                  ON ccu.constraint_name = tc.constraint_name
                  AND ccu.table_schema = tc.table_schema
            WHERE tc.table_schema = 'public'
          `,
            sourceConnectionString.toString()
          )

          await runSnapletCLI(
            ['snapshot', 'capture', snapshotDir],
            {
              SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
            },
            paths
          )
          await runSnapletCLI(
            ['snapshot restore', snapshotDir],
            {
              SNAPLET_TARGET_DATABASE_URL:
                destinationConnectionString.toString(),
            },
            paths
          ).catch((error) => error)

          // Retrieve the actual constraints in place on the restored database
          const constraintsRestored = await execQueryNext(
            `
              SELECT
                  tc.table_schema,
                  tc.constraint_name,
                  tc.table_name,
                  kcu.column_name,
                  ccu.table_schema AS foreign_table_schema,
                  ccu.table_name AS foreign_table_name,
                  ccu.column_name AS foreign_column_name
              FROM
                  information_schema.table_constraints AS tc
                  JOIN information_schema.key_column_usage AS kcu
                    ON tc.constraint_name = kcu.constraint_name
                    AND tc.table_schema = kcu.table_schema
                  JOIN information_schema.constraint_column_usage AS ccu
                    ON ccu.constraint_name = tc.constraint_name
                    AND ccu.table_schema = tc.table_schema
              WHERE tc.table_schema = 'public'
          `,
            destinationConnectionString.toString()
          )
          // The two extracted tables structures.json should be the same into the database
          expect(constraintsSource.rows).toEqual(
            expect.arrayContaining(constraintsRestored.rows)
          )
        })
      })
    })
  },
  { timeout: 10 * 60 * 1000 }
)
