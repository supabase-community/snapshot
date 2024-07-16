import { execQueryNext } from '@snaplet/sdk/cli'
import { parse as csvParse } from 'csv-parse/sync'
import fs from 'fs'
import fsExtra from 'fs-extra'
import path from 'path'

import {
  createTestRole,
  createTestDb,
  createTestCapturePath,
  runSnapletCLI,
  createTestProjectDirV2,
} from '../../src/testing/index.js'

vi.setConfig({
  testTimeout: 60_000,
})

describe('Snaplet CLI', () => {
  describe('snapshot capture', () => {
    test('should generate schema.sql on basic database', async () => {
      const sourceConnectionString = await createTestDb()

      const paths = await createTestProjectDirV2()
      const configContent = `
        import { defineConfig } from "snaplet";

        export default defineConfig({
        })`
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
      const snapshotDirSource = createTestCapturePath().name

      await runSnapletCLI(
        ['snapshot', 'capture', snapshotDirSource],
        {
          SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
          SNAPLET_SNAPSHOT_ID: 'source',
        },
        paths
      )
      const schemaSqlContent = fs.readFileSync(
        path.join(snapshotDirSource, 'schemas.sql'),
        'utf-8'
      )
      // since user is a keyword it should have been escaped
      expect(schemaSqlContent).toContain('CREATE TABLE public."user"')
      expect(schemaSqlContent).toContain('CREATE TABLE public.team')
    })

    test('should generate schema.sql with read-only permission granted on all tables', async () => {
      const connString = await createTestDb()
      const paths = await createTestProjectDirV2()
      const configContent = `
        import { defineConfig } from "snaplet";

        export default defineConfig({
        })`
      await fsExtra.writeFile(paths.snapletConfig, configContent)

      // Create two table with the default privilege so they are readable
      await execQueryNext(
        `CREATE TABLE "team"
            (
                id INT GENERATED ALWAYS AS IDENTITY,
                name text NOT NULL,
                PRIMARY KEY (id)
            );`,
        connString
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
        connString
      )

      const readOnlySourceConnectionString = await createTestRole(connString)
      // Grant read permissions on all current tables
      await execQueryNext(
        `GRANT SELECT ON ALL TABLES IN SCHEMA public TO "${readOnlySourceConnectionString.username}";`,
        connString
      )

      await createTestProjectDirV2()
      const snapshotDirSource = createTestCapturePath().name

      await runSnapletCLI(
        ['snapshot', 'capture', snapshotDirSource],
        {
          SNAPLET_SOURCE_DATABASE_URL:
            readOnlySourceConnectionString.toString(),
        },
        paths
      )
      const schemaSqlContent = fs.readFileSync(
        path.join(snapshotDirSource, 'schemas.sql'),
        'utf-8'
      )
      // since user is a keyword it should have been escaped
      expect(schemaSqlContent).toContain('CREATE TABLE public."user"')
      expect(schemaSqlContent).toContain('CREATE TABLE public.team')
    })

    test('should exclude forbidden tables', async () => {
      const connString = await createTestDb()
      const paths = await createTestProjectDirV2()
      const configContent = `
        import { defineConfig } from "snaplet";

        export default defineConfig({
        })`
      await fsExtra.writeFile(paths.snapletConfig, configContent)
      const readOnlySourceConnectionString = await createTestRole(connString)
      // Create two table with the default privilege so they are readable
      await execQueryNext(
        `CREATE TABLE "team"
            (
                id INT GENERATED ALWAYS AS IDENTITY,
                name text NOT NULL,
                PRIMARY KEY (id)
            );`,
        connString
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
        connString
      )
      // Grant read permissions on all current tables
      await execQueryNext(
        `GRANT SELECT ON ALL TABLES IN SCHEMA public TO "${readOnlySourceConnectionString.username}";`,
        connString
      )
      // Create a third hidden table on which we won't grant SELECT permissions
      await execQueryNext(
        `CREATE TABLE "hidden"
            (
                id INT GENERATED ALWAYS AS IDENTITY,
                name text NOT NULL,
                PRIMARY KEY (id)
            );`,
        connString
      )
      const snapshotDirSource = createTestCapturePath().name
      await expect(
        runSnapletCLI(['snapshot', 'capture', snapshotDirSource], {
          SNAPLET_SOURCE_DATABASE_URL:
            readOnlySourceConnectionString.toString(),
          DEBUG: 'snaplet:capture:pg_dump',
        })
      ).resolves.toEqual(
        expect.objectContaining({
          stderr: expect.stringContaining('--exclude-table=public.hidden'),
        })
      )
      expect(
        fs.readFileSync(path.join(snapshotDirSource, 'schemas.sql'), 'utf-8')
      ).not.toContain('CREATE TABLE public.hidden')
    })

    test('transform set custom hash key', async () => {
      const connectionString = await createTestDb()
      const paths = await createTestProjectDirV2()
      const configContent = `
        import { copycat } from "@snaplet/copycat";
        import { defineConfig } from "snaplet";

        const key = copycat.generateHashKey('9.8jzB86bjEyyw_M')
        copycat.setHashKey(key)

        export default defineConfig({
          transform: {
            $mode: 'auto',
            public: {
              User: ({ row }) => ({
                email: copycat.email(row.email)
              })
            }
          },
        })`
      await fsExtra.writeFile(paths.snapletConfig, configContent)

      await execQueryNext(
        `CREATE TABLE "User" ("email" TEXT)`,
        connectionString
      )

      await execQueryNext(
        `INSERT INTO "User" VALUES ('hiphopopotamus@rhymenoceros.com')`,
        connectionString
      )
      const ssPath = createTestCapturePath()
      await runSnapletCLI(
        ['snapshot capture', ssPath.name],
        {
          SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
        },
        paths
      )

      const data = csvParse(
        await fsExtra.readFile(
          path.join(ssPath.name, 'tables', 'public.User.csv')
        ),
        { columns: true }
      )

      expect(data[0].email).to.not.equal('hiphopopotamus@rhymenoceros.com')
      expect(data[0].email).to.not.equal(
        `Laury_Harber95248@irritating-bowler.name`
      )
    })
  })
})
