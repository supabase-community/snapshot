import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
  checkConstraints,
} from '../../src/testing/index.js'
import fsExtra from 'fs-extra'
import path from 'path'

vi.setConfig({
  testTimeout: 60_000,
})

describe(
  'Snaplet CLI',
  () => {
    describe('snapshot restore', () => {
      test('recreate all foreign keys', async () => {
        const paths = await createTestProjectDirV2()

        const configContent = `
          module.exports = {
            select: {
              movie: 'structure',
            },
          }
        `
        await fsExtra.writeFile(paths.snapletConfig, configContent)

        const sourceConnectionString = (await createTestDb()).toString()
        const targetConnectionString = (await createTestDb()).toString()

        await execQueryNext(
          `
          create table actor (
            id integer primary key
          );
          create table movie (
            id integer primary key,
            actor_id integer references actor(id)
          );
          insert into actor values (1);
          insert into movie values (1, 1);
          `,
          sourceConnectionString
        )

        const ssPath = createTestCapturePath()

        await runSnapletCLI(
          ['snapshot', 'capture', ssPath.name],
          {
            SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString,
          },
          paths
        )

        await runSnapletCLI(
          ['snapshot restore', ssPath.name],
          {
            SNAPLET_TARGET_DATABASE_URL: targetConnectionString,
          },
          paths
        )

        await checkConstraints(sourceConnectionString, targetConnectionString)
      })

      test('snaplet snapshot restore: report failure with context', async () => {
        const sourceConnectionString = await createTestDb()
        const destinationConnectionString = await createTestDb()

        const paths = await createTestProjectDirV2()
        const configContent = `
          module.exports = {
          }
        `
        await fsExtra.writeFile(paths.snapletConfig, configContent)

        await execQueryNext(
          `CREATE TABLE "Tmp" (
             count int
          )`,
          sourceConnectionString.toString()
        )

        await execQueryNext(
          `INSERT INTO "Tmp" VALUES (
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

        // alter the csv data to trigger an error during restore
        const tableFile = path.join(snapshotDir, 'tables', 'public.Tmp.csv')
        const fileContent = await fsExtra.readFile(tableFile, 'utf8')
        await fsExtra.writeFile(tableFile, fileContent.replace('42', 'oops'))

        await expect(
          runSnapletCLI(
            ['snapshot restore', snapshotDir],
            {
              SNAPLET_TARGET_DATABASE_URL:
                destinationConnectionString.toString(),
            },
            paths
          )
        ).rejects.toEqual(
          expect.objectContaining({
            stdout: expect.stringContaining(
              'The table "public"."Tmp" restoration failed, this error might be an indication of an issue in your data'
            ),
          })
        )
      })
      describe('--no-schema', () => {
        test('should have the same result as --data-only', async () => {
          const sourceConnectionString = await createTestDb()
          const destinationConnectionString = await createTestDb()

          await createTestProjectDirV2()
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

          await runSnapletCLI(['snapshot', 'capture', snapshotDir], {
            SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
            SNAPLET_SNAPSHOT_ID: 'tmp',
          })
          // Recreate the tables into the database, add an extra table
          await execQueryNext(
            `CREATE TABLE "inscreenshot" (
             count int
          )`,
            destinationConnectionString.toString()
          )
          await execQueryNext(
            `CREATE TABLE "outscreenshot" (
             count int
          )`,
            destinationConnectionString.toString()
          )
          await execQueryNext(
            `INSERT INTO "outscreenshot" VALUES (
            42
          )`,
            destinationConnectionString.toString()
          )
          await runSnapletCLI(
            ['snapshot restore', '--no-schema', snapshotDir],
            {
              SNAPLET_TARGET_DATABASE_URL:
                destinationConnectionString.toString(),
            }
          ).catch((error) => error)

          const inscreenshotResult = await execQueryNext(
            'SELECT * FROM inscreenshot;',
            destinationConnectionString
          )
          const outcreenshotResult = await execQueryNext(
            'SELECT * FROM outscreenshot;',
            destinationConnectionString
          )
          // Data from the table in screenshot should have been imported
          expect(inscreenshotResult.rows).toEqual([{ count: 42 }])
          // The other table should have been left untouched
          expect(outcreenshotResult.rows).toEqual([{ count: 42 }])
        })
      })
      describe('--no-data', () => {
        test('should have the same result as --schema-only', async () => {
          const sourceConnectionString = await createTestDb()
          const destinationConnectionString = await createTestDb()

          await createTestProjectDirV2()
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

          await runSnapletCLI(['snapshot', 'capture', snapshotDir], {
            SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
            SNAPLET_SNAPSHOT_ID: 'tmp',
          })
          await runSnapletCLI(['snapshot restore', '--no-data', snapshotDir], {
            SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
          }).catch((error) => error)

          const inscreenshotResult = await execQueryNext(
            'SELECT * FROM inscreenshot;',
            destinationConnectionString
          )
          // The table in the screenshot should now be empty
          expect(inscreenshotResult.rows).toEqual([])
        })
      })
      describe('--no-reset', () => {
        test('should not drop existing table not in snapshot from database', async () => {
          const sourceConnectionString = await createTestDb()
          const destinationConnectionString = await createTestDb()

          const paths = await createTestProjectDirV2()
          const configContent = `
          import { copycat } from "@snaplet/copycat";
          import { defineConfig } from "snaplet";

          export default defineConfig({
          })`
          await fsExtra.writeFile(paths.snapletConfig, configContent)
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

          await runSnapletCLI(
            ['snapshot', 'capture', snapshotDir],
            {
              SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
              SNAPLET_SNAPSHOT_ID: 'tmp',
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
        test('should not drop existing table with --no-data and should not import the data', async () => {
          const sourceConnectionString = await createTestDb()
          const destinationConnectionString = await createTestDb()

          await createTestProjectDirV2()
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

          await runSnapletCLI(['snapshot', 'capture', snapshotDir], {
            SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
            SNAPLET_SNAPSHOT_ID: 'tmp',
          })
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
            }
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
      })
      describe('schema relations', () => {
        test('should work with basic one-to-many relations', async () => {
          const sourceConnectionString = await createTestDb()
          const destinationConnectionString = await createTestDb()

          await createTestProjectDirV2()

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
          const snapshotDirSource = createTestCapturePath().name

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

          await runSnapletCLI(['snapshot', 'capture', snapshotDirSource], {
            SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
            SNAPLET_SNAPSHOT_ID: 'source',
          })
          await runSnapletCLI(['snapshot restore', snapshotDirSource], {
            SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
          }).catch((error) => error)

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

          // That's a classical ManyToMany relationship pattern.
          // 1. We have members
          // 2. We have teams
          // 3. Teams are composed of zero, one, or more users
          // 4. Users can be into multiples teams at the same time
          // 5. So we have our two tables, and a linking table which bind teams and users togethers.
          await createTestProjectDirV2()

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
          const snapshotDirSource = createTestCapturePath().name

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

          await runSnapletCLI(['snapshot', 'capture', snapshotDirSource], {
            SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
            SNAPLET_SNAPSHOT_ID: 'source',
          })
          await runSnapletCLI(['snapshot restore', snapshotDirSource], {
            SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
          }).catch((error) => error)

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
  { timeout: 10 * 60 * 1000 } // 10 minutes
)
