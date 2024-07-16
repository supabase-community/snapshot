import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
} from '../../src/testing/index.js'
import fs from 'fs-extra'
import path from 'path'
import { parse as csvParse } from 'csv-parse/sync'

vi.setConfig({
  testTimeout: 60_000,
})

describe('Config V3 tests', () => {
  test('capturing and restoring with `parseJson: false`', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      transform: {
        $parseJson: false,
        public: {
          User: ({ row }) => ({})
        }
      },
    })`

    await fs.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `CREATE TABLE "User" ("value" Json)`,
      sourceConnectionString
    )

    await execQueryNext(
      `INSERT INTO "User" VALUES ('null')`,
      sourceConnectionString
    )

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
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const result = await execQueryNext(
      `select * from "User" where json_typeof(value) = 'null'`,
      destinationConnectionString
    )

    expect(result.rows).toEqual([
      {
        value: null,
      },
    ])
  })
  test('capturing and restoring with `parseJson: true`', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      transform: {
        $mode: 'auto',
        $parseJson: true,
        public: {
          User: ({ row }) => ({})
        }
      },
    })`

    await fs.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `CREATE TABLE "User" ("value" Json)`,
      sourceConnectionString
    )

    await execQueryNext(
      `INSERT INTO "User" VALUES ('{ "name": "Koos Cumberbatch" }')`,
      sourceConnectionString
    )

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
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const result = await execQueryNext(
      `select * from "User"`,
      destinationConnectionString
    )

    expect(result.rows).toEqual([
      {
        value: {
          name: expect.not.stringMatching('Koos Cumberbatch'),
        },
      },
    ])
  })
  // TODO: This won't work with config v3 because it doesn't support the `transform: (structure) => {}` syntax
  // look for an alternative way to do the same without this
  test('dynamic transform using structure', async () => {})
  test('transform.ts', async () => {
    const connectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      transform: {
        public: {
          User: ({ row }) => ({
            email: 'the-kiffest-' + row.email
          })
        }
      },
    })`

    await fs.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `CREATE TABLE "User" ("name" TEXT, "email" TEXT)`,
      connectionString
    )

    await execQueryNext(
      `INSERT INTO "User" VALUES ('Koos Cumberbatch', 'koosie@cumberbatch.com')`,
      connectionString
    )

    await execQueryNext(
      `INSERT INTO "User" VALUES ('Weakerthan Jake', 'weakerthan@jake.com')`,
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
      await fs.readFile(path.join(ssPath.name, 'tables', 'public.User.csv')),
      { columns: true }
    )

    expect(data).toEqual([
      {
        name: 'Koos Cumberbatch',
        email: 'the-kiffest-koosie@cumberbatch.com',
      },
      {
        name: 'Weakerthan Jake',
        email: 'the-kiffest-weakerthan@jake.com',
      },
    ])
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

    const paths = await createTestProjectDirV2()

    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      select: {
        public: {
          user: "structure",
        },
      },
      subset: {
        enabled: true,

        followNullableRelations: true,
        targets: [
          {
            table: 'public.organization',
            percent: 100,
            where: '"organization"."id" = 1',
          },
        ],
        keepDisconnectedTables: false,
      }
    })`

    await fs.writeFile(paths.snapletConfig, configContent)
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
  test('should rethrow execution parsing error', async () => {
    const connectionString = await createTestDb()
    const paths = await createTestProjectDirV2()
    const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      throw new Error('test error')

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
    await fs.writeFile(paths.snapletConfig, configContent)

    const ssPath = createTestCapturePath()
    await expect(
      runSnapletCLI(['snapshot capture', ssPath.name], {
        SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
      })
    ).rejects.toEqual(
      expect.objectContaining({
        stdout: expect.stringContaining(`Failed to execute config file`),
        failed: true,
        exitCode: 118,
      })
    )
  })
  describe('advanced database structure', () => {
    const structure = `
      CREATE SCHEMA private;

      -- Creating extensions in the public schema
      CREATE EXTENSION IF NOT EXISTS pg_stat_statements SCHEMA public;
      CREATE EXTENSION IF NOT EXISTS hstore SCHEMA public;

      -- Creating tables in the public schema and inserting data
      CREATE TABLE public."User" ("id" SERIAL PRIMARY KEY, "name" TEXT, "email" TEXT);
      CREATE TABLE public."Team" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      CREATE TABLE public."Other" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      INSERT INTO public."User" VALUES (1, 'Koos Cumberbatch', 'koosie@cumberbatch.com');
      INSERT INTO public."User" VALUES (2, 'Weakerthan Jake', 'weakerthan@jake.com');
      INSERT INTO public."Team" VALUES (1, 'Team A');
      INSERT INTO public."Team" VALUES (2, 'Team B');
      INSERT INTO public."Other" VALUES (1, 'Other A');
      INSERT INTO public."Other" VALUES (2, 'Other B');

      -- Creating extension in the private schema
      CREATE EXTENSION IF NOT EXISTS citext SCHEMA private;
      CREATE EXTENSION IF NOT EXISTS fuzzystrmatch SCHEMA private;

      -- Creating tables in the private schema and inserting data
      CREATE TABLE private."Employee" ("id" SERIAL PRIMARY KEY, "name" TEXT, "email" TEXT);
      CREATE TABLE private."Department" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      INSERT INTO private."Employee" VALUES (1, 'John Doe', 'john.doe@example.com');
      INSERT INTO private."Employee" VALUES (2, 'Jane Doe', 'jane.doe@example.com');
      INSERT INTO private."Department" VALUES (1, 'Human Resources');
      INSERT INTO private."Department" VALUES (2, 'Engineering');
    `
    test('exclude one schema from a database', async () => {
      const connectionString = await createTestDb(structure)
      const targetDatabase = await createTestDb()

      const paths = await createTestProjectDirV2()

      const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({
        select: {
          private: false,
        },
        transform: {
          public: {
            User: ({ row }) => ({
              email: 'the-kiffest-' + row.email
            })
          }
        },
      })`
      await fs.writeFile(paths.snapletConfig, configContent)
      const ssPath = createTestCapturePath()
      await runSnapletCLI(['snapshot capture', ssPath.name], {
        SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
      })
      await runSnapletCLI(['snapshot restore', ssPath.name], {
        SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
      })
      const users = await execQueryNext(
        `SELECT name, email FROM public."User"`,
        targetDatabase
      )
      expect(users.rows).toEqual(
        expect.arrayContaining([
          {
            name: 'Koos Cumberbatch',
            email: 'the-kiffest-koosie@cumberbatch.com',
          },
          {
            name: 'Weakerthan Jake',
            email: 'the-kiffest-weakerthan@jake.com',
          },
        ])
      )
      // The private schema has properly been excluded
      const privateSchemaExists = await execQueryNext(
        `SELECT EXISTS(SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'private')`,
        targetDatabase
      )
      expect(privateSchemaExists.rows[0].exists).toBe(false)
    })
    test('exclude one extension from a database', async () => {
      const connectionString = await createTestDb(structure)
      const targetDatabase = await createTestDb()
      const paths = await createTestProjectDirV2()
      const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({
        select: {
          private: {
            $extensions: {
              citext: false,
            },
          },
        },
        transform: {
          public: {
            User: ({ row }) => ({
              email: 'the-kiffest-' + row.email
            })
          }
        },
      })`
      await fs.writeFile(paths.snapletConfig, configContent)
      const ssPath = createTestCapturePath()
      await runSnapletCLI(['snapshot capture', ssPath.name], {
        SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
      })
      await runSnapletCLI(['snapshot restore', ssPath.name], {
        SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
      })
      // Check that the public schema is restored with its data
      const publicUsers = await execQueryNext(
        `SELECT name, email FROM public."User"`,
        targetDatabase
      )
      expect(publicUsers.rows).toEqual(
        expect.arrayContaining([
          {
            name: 'Koos Cumberbatch',
            email: 'the-kiffest-koosie@cumberbatch.com',
          },
          {
            name: 'Weakerthan Jake',
            email: 'the-kiffest-weakerthan@jake.com',
          },
        ])
      )

      // Check that the private schema is restored with its data
      const privateEmployees = await execQueryNext(
        `SELECT name, email FROM private."Employee"`,
        targetDatabase
      )
      expect(privateEmployees.rows).toEqual(
        expect.arrayContaining([
          {
            name: 'John Doe',
            email: 'john.doe@example.com',
          },
          {
            name: 'Jane Doe',
            email: 'jane.doe@example.com',
          },
        ])
      )

      // Check that the citext extension is not restored on the private schema
      const citextExtensionExists = await execQueryNext(
        `SELECT EXISTS(SELECT * FROM pg_extension WHERE extname = 'citext')`,
        targetDatabase
      )
      expect(citextExtensionExists.rows[0].exists).toBe(false)
    })
    test('exclude one schema one extension and data from one table from a database', async () => {
      const connectionString = await createTestDb(structure)
      const targetDatabase = await createTestDb()

      const paths = await createTestProjectDirV2()
      const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({
        select: {
          private: false,
          public: {
            Team: "structure",
            Other: false,
            $extensions: {
              hstore: false,
            },
          }
        },
        transform: {
          public: {
            User: ({ row }) => ({
              email: 'the-kiffest-' + row.email
            })
          }
        },
      })`
      await fs.writeFile(paths.snapletConfig, configContent)
      const ssPath = createTestCapturePath()
      await runSnapletCLI(['snapshot capture', ssPath.name], {
        SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
      })
      await runSnapletCLI(['snapshot restore', ssPath.name], {
        SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
      })
      // Check that the public schema is restored with its data
      const publicUsers = await execQueryNext(
        `SELECT name, email FROM public."User"`,
        targetDatabase
      )
      expect(publicUsers.rows).toEqual(
        expect.arrayContaining([
          {
            name: 'Koos Cumberbatch',
            email: 'the-kiffest-koosie@cumberbatch.com',
          },
          {
            name: 'Weakerthan Jake',
            email: 'the-kiffest-weakerthan@jake.com',
          },
        ])
      )

      // Check that the hstore extension is not restored on the private schema
      const hstoreExtensionExists = await execQueryNext(
        `SELECT EXISTS(SELECT * FROM pg_extension WHERE extname = 'hstore')`,
        targetDatabase
      )
      expect(hstoreExtensionExists.rows[0].exists).toBe(false)
      // The private schema has properly been excluded
      const privateSchemaExists = await execQueryNext(
        `SELECT EXISTS(SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'private')`,
        targetDatabase
      )
      expect(privateSchemaExists.rows[0].exists).toBe(false)
      // Check that the public schema Team table is restored without data
      const publicTeams = await execQueryNext(
        `SELECT * FROM public."Team"`,
        targetDatabase
      )
      expect(publicTeams.rowCount).toEqual(0)
      // Check that the public schema Other table is not restored
      const publicOtherTableExists = await execQueryNext(
        `SELECT * FROM public."Other"`,
        targetDatabase
      )
      expect(publicOtherTableExists.rowCount).toBe(0)
    })
    test('exclude all tables data from a schema', async () => {
      const connectionString = await createTestDb(structure)
      const targetDatabase = await createTestDb()

      const paths = await createTestProjectDirV2()
      const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({
        select: {
          private: false,
          public: {
            $default: "structure",
            $extensions: {
              hstore: false,
            }
          }
        },
        transform: {
          public: {
            User: ({ row }) => ({
              email: 'the-kiffest-' + row.email
            })
          }
        },
      })`
      await fs.writeFile(paths.snapletConfig, configContent)

      const ssPath = createTestCapturePath()
      await runSnapletCLI(['snapshot capture', ssPath.name], {
        SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
      })
      await runSnapletCLI(['snapshot restore', ssPath.name], {
        SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
      })
      // Check that the public schema is restored with its data
      const publicUsers = await execQueryNext(
        `SELECT name, email FROM public."User"`,
        targetDatabase
      )
      expect(publicUsers.rowCount).toEqual(0)
      // Check that the hstore extension is not restored on the private schema
      const hstoreExtensionExists = await execQueryNext(
        `SELECT EXISTS(SELECT * FROM pg_extension WHERE extname = 'hstore')`,
        targetDatabase
      )
      expect(hstoreExtensionExists.rows[0].exists).toBe(false)
      // The private schema has properly been excluded
      const privateSchemaExists = await execQueryNext(
        `SELECT EXISTS(SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'private')`,
        targetDatabase
      )
      expect(privateSchemaExists.rows[0].exists).toBe(false)
      // Check that the public schema Team table is restored without data
      const publicTeams = await execQueryNext(
        `SELECT * FROM public."Team"`,
        targetDatabase
      )
      expect(publicTeams.rowCount).toEqual(0)
      // Check that the public schema Other table is not restored
      const publicOtherTableExists = await execQueryNext(
        `SELECT * FROM public."Other"`,
        targetDatabase
      )
      expect(publicOtherTableExists.rowCount).toBe(0)
    })
    test('exclude all tables data from a schema except one', async () => {
      const connectionString = await createTestDb(structure)
      const targetDatabase = await createTestDb()

      const paths = await createTestProjectDirV2()
      const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({
        select: {
          private: false,
          public: {
            $default: "structure",
            Other: true,
            $extensions: {
              hstore: false,
            }
          }
        },
        transform: {
          public: {
            Other: ({row}) => row,
          }
        },
      })`
      await fs.writeFile(paths.snapletConfig, configContent)
      const ssPath = createTestCapturePath()
      await runSnapletCLI(['snapshot capture', ssPath.name], {
        SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
      })
      await runSnapletCLI(['snapshot restore', ssPath.name], {
        SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
      })
      // Check that the public schema is restored with its data
      const publicUsers = await execQueryNext(
        `SELECT name, email FROM public."User"`,
        targetDatabase
      )
      expect(publicUsers.rowCount).toEqual(0)
      // Check that the hstore extension is not restored on the private schema
      const hstoreExtensionExists = await execQueryNext(
        `SELECT EXISTS(SELECT * FROM pg_extension WHERE extname = 'hstore')`,
        targetDatabase
      )
      expect(hstoreExtensionExists.rows[0].exists).toBe(false)
      // The private schema has properly been excluded
      const privateSchemaExists = await execQueryNext(
        `SELECT EXISTS(SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'private')`,
        targetDatabase
      )
      expect(privateSchemaExists.rows[0].exists).toBe(false)
      // Check that the public schema Team table is restored without data
      const publicTeams = await execQueryNext(
        `SELECT * FROM public."Team"`,
        targetDatabase
      )
      expect(publicTeams.rowCount).toEqual(0)
      // Check that the public schema Other table is not restored
      const publicOtherTableExists = await execQueryNext(
        `SELECT * FROM public."Other"`,
        targetDatabase
      )
      expect(publicOtherTableExists.rowCount).toBe(2)
    })
    test('should change non declared columns in auto mode', async () => {
      const connectionString = await createTestDb(structure)
      const targetDatabase = await createTestDb()

      const paths = await createTestProjectDirV2()
      const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({
        transform: {
          $mode: 'auto',
          public: {
            User: ({row}) => ({ name: row.name }),
          }
        },
      })`
      await fs.writeFile(paths.snapletConfig, configContent)
      const ssPath = createTestCapturePath()
      await runSnapletCLI(['snapshot capture', ssPath.name], {
        SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
      })
      await runSnapletCLI(['snapshot restore', ssPath.name], {
        SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
      })
      // Check that the public schema is restored with its data transformed
      const users = await execQueryNext(
        `SELECT name, email FROM public."User"`,
        targetDatabase
      )
      expect(users.rows).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            name: 'Koos Cumberbatch',
            email: expect.not.stringMatching('koosie@cumberbatch.com'),
          }),
          expect.objectContaining({
            name: 'Weakerthan Jake',
            email: expect.not.stringMatching('koosie@cumberbatch.com'),
          }),
        ])
      )
    })
    test('should not change non declared columns in unsafe mode', async () => {
      const connectionString = await createTestDb(structure)
      const targetDatabase = await createTestDb()

      const paths = await createTestProjectDirV2()
      const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({
        transform: {
          $mode: 'unsafe',
          public: {
            User: ({row}) => ({ name: row.name + ' test' }),
          }
        },
      })`
      await fs.writeFile(paths.snapletConfig, configContent)
      const ssPath = createTestCapturePath()
      await runSnapletCLI(['snapshot capture', ssPath.name], {
        SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
      })
      await runSnapletCLI(['snapshot restore', ssPath.name], {
        SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
      })
      // Check that the public schema is restored with its data transformed
      const users = await execQueryNext(
        `SELECT name, email FROM public."User"`,
        targetDatabase
      )
      expect(users.rows).toEqual(
        expect.arrayContaining([
          {
            name: 'Koos Cumberbatch test',
            email: 'koosie@cumberbatch.com',
          },
          {
            name: 'Weakerthan Jake test',
            email: 'weakerthan@jake.com',
          },
        ])
      )
    })
    test('should raise an error in strict mode', async () => {
      const connectionString = await createTestDb(structure)

      const paths = await createTestProjectDirV2()
      const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({
        transform: {
          $mode: 'strict',
          public: {
            User: ({row}) => ({ name: row.name + ' test' }),
          }
        },
      })`
      await fs.writeFile(paths.snapletConfig, configContent)
      const ssPath = createTestCapturePath()
      const result = await runSnapletCLI(
        ['snapshot capture', ssPath.name],
        {
          SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
        },
        undefined,
        { reject: false }
      )
      expect(result.stderr).toContain(
        'The following schemas, tables or columns are missing from your transform config'
      )
    })
  })
  test('should exclude all schemas and one table from the capture leveraging $default', async () => {
    const structure = `
      CREATE SCHEMA private;
      CREATE SCHEMA auth;

      -- Creating tables in the public schema and inserting data
      CREATE TABLE public._prisma_migrations (id SERIAL PRIMARY KEY, name TEXT, revision INTEGER, datamodel TEXT, status TEXT, applied_at TIMESTAMP);
      CREATE TABLE public."Pokemon" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      CREATE TABLE public."Other" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      -- Creating user table in auth schema (similar to supabase)
      CREATE TABLE auth.user ("id" SERIAL PRIMARY KEY, "name" TEXT, "email" TEXT);
      -- Creating table into private schema
      CREATE TABLE private."Employee" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      -- Insert data into public schema
      INSERT INTO public."Pokemon" VALUES (1, 'Pikachu');
      INSERT INTO public."Pokemon" VALUES (2, 'Charmander');
      INSERT INTO public."Other" VALUES (1, 'Other A');
      INSERT INTO public._prisma_migrations VALUES (1, 'init', 1, 'datamodel', 'MigrationSuccess', NOW());
      INSERT INTO public._prisma_migrations VALUES (2, 'init2', 2, 'datamodel', 'MigrationSuccess', NOW());
      -- Insert data into auth schema
      INSERT INTO auth.user VALUES (1, 'Koos Cumberbatch', 'test@gmail.com');
      INSERT INTO auth.user VALUES (2, 'Weakerthan Jake', 'test2@gmail.com');
      -- Insert data into private schema
      INSERT INTO private."Employee" VALUES (1, 'John Doe');
    `
    const connectionString = await createTestDb(structure)
    const targetDatabase = await createTestDb()
    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat, faker } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";
    export default defineConfig({
      select: {
        $default: false,
        public: {
          $default: true,
          _prisma_migrations: false,
        },
      },
      transform: {
        $mode: "unsafe"
      },
    });
    `
    await fs.writeFile(paths.snapletConfig, configContent)
    const ssPath = createTestCapturePath()
    await runSnapletCLI(['snapshot capture', ssPath.name], {
      SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
    })
    await runSnapletCLI(['snapshot restore', ssPath.name], {
      SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
    })
    // Check that the public schema is restored with its data
    const publicPokemon = await execQueryNext(
      `SELECT * FROM public."Pokemon"`,
      targetDatabase
    )
    const publicOther = await execQueryNext(
      `SELECT * FROM public."Other"`,
      targetDatabase
    )
    await expect(
      execQueryNext(`SELECT * FROM public._prisma_migrations`, targetDatabase)
    ).rejects.toEqual(expect.objectContaining({ code: '42P01' }))
    await expect(
      execQueryNext(`SELECT * FROM auth.user`, targetDatabase)
      // should fail because the schema should not exist
    ).rejects.toEqual(expect.objectContaining({ code: '42P01' }))
    await expect(
      execQueryNext(`SELECT * FROM private."Employee"`, targetDatabase)
      // should fail because the schema should not exist
    ).rejects.toEqual(expect.objectContaining({ code: '42P01' }))
    expect(publicPokemon.rowCount).toEqual(2)
    expect(publicOther.rowCount).toEqual(1)
  })
  test('should exclude all schemas and one table from the capture', async () => {
    const structure = `
      CREATE SCHEMA private;
      CREATE SCHEMA auth;

      -- Creating tables in the public schema and inserting data
      CREATE TABLE public._prisma_migrations (id SERIAL PRIMARY KEY, name TEXT, revision INTEGER, datamodel TEXT, status TEXT, applied_at TIMESTAMP);
      CREATE TABLE public."Pokemon" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      CREATE TABLE public."Other" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      -- Creating user table in auth schema (similar to supabase)
      CREATE TABLE auth.user ("id" SERIAL PRIMARY KEY, "name" TEXT, "email" TEXT);
      -- Creating table into private schema
      CREATE TABLE private."Employee" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      -- Insert data into public schema
      INSERT INTO public."Pokemon" VALUES (1, 'Pikachu');
      INSERT INTO public."Pokemon" VALUES (2, 'Charmander');
      INSERT INTO public."Other" VALUES (1, 'Other A');
      INSERT INTO public._prisma_migrations VALUES (1, 'init', 1, 'datamodel', 'MigrationSuccess', NOW());
      INSERT INTO public._prisma_migrations VALUES (2, 'init2', 2, 'datamodel', 'MigrationSuccess', NOW());
      -- Insert data into auth schema
      INSERT INTO auth.user VALUES (1, 'Koos Cumberbatch', 'test@gmail.com');
      INSERT INTO auth.user VALUES (2, 'Weakerthan Jake', 'test2@gmail.com');
      -- Insert data into private schema
      INSERT INTO private."Employee" VALUES (1, 'John Doe');
    `
    const connectionString = await createTestDb(structure)
    const targetDatabase = await createTestDb()
    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat, faker } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";
    export default defineConfig({
      select: {
        private: false,
        auth: false,
        public: {
          _prisma_migrations: false,
        },
      },
      transform: {
        $mode: "unsafe"
      },
    });
    `
    await fs.writeFile(paths.snapletConfig, configContent)
    const ssPath = createTestCapturePath()
    await runSnapletCLI(['snapshot capture', ssPath.name], {
      SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
    })
    await runSnapletCLI(['snapshot restore', ssPath.name], {
      SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
    })
    // Check that the public schema is restored with its data
    const publicPokemon = await execQueryNext(
      `SELECT * FROM public."Pokemon"`,
      targetDatabase
    )
    const publicOther = await execQueryNext(
      `SELECT * FROM public."Other"`,
      targetDatabase
    )
    await expect(
      execQueryNext(`SELECT * FROM public._prisma_migrations`, targetDatabase)
    ).rejects.toEqual(expect.objectContaining({ code: '42P01' }))
    await expect(
      execQueryNext(`SELECT * FROM auth.user`, targetDatabase)
      // should fail because the schema should not exist
    ).rejects.toEqual(expect.objectContaining({ code: '42P01' }))
    await expect(
      execQueryNext(`SELECT * FROM private."Employee"`, targetDatabase)
      // should fail because the schema should not exist
    ).rejects.toEqual(expect.objectContaining({ code: '42P01' }))
    expect(publicPokemon.rowCount).toEqual(2)
    expect(publicOther.rowCount).toEqual(1)
  })
  test('should skip data of all tables leveraging $default', async () => {
    const structure = `
      CREATE SCHEMA private;
      CREATE SCHEMA auth;

      -- Creating tables in the public schema and inserting data
      CREATE TABLE public._prisma_migrations (id SERIAL PRIMARY KEY, name TEXT, revision INTEGER, datamodel TEXT, status TEXT, applied_at TIMESTAMP);
      CREATE TABLE public."Pokemon" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      CREATE TABLE public."Other" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      -- Creating user table in auth schema (similar to supabase)
      CREATE TABLE auth.user ("id" SERIAL PRIMARY KEY, "name" TEXT, "email" TEXT);
      -- Creating table into private schema
      CREATE TABLE private."Employee" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      -- Insert data into public schema
      INSERT INTO public."Pokemon" VALUES (1, 'Pikachu');
      INSERT INTO public."Pokemon" VALUES (2, 'Charmander');
      INSERT INTO public."Other" VALUES (1, 'Other A');
      INSERT INTO public._prisma_migrations VALUES (1, 'init', 1, 'datamodel', 'MigrationSuccess', NOW());
      INSERT INTO public._prisma_migrations VALUES (2, 'init2', 2, 'datamodel', 'MigrationSuccess', NOW());
      -- Insert data into auth schema
      INSERT INTO auth.user VALUES (1, 'Koos Cumberbatch', 'test@gmail.com');
      INSERT INTO auth.user VALUES (2, 'Weakerthan Jake', 'test2@gmail.com');
      -- Insert data into private schema
      INSERT INTO private."Employee" VALUES (1, 'John Doe');
    `
    const connectionString = await createTestDb(structure)
    const targetDatabase = await createTestDb()
    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat, faker } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";
    export default defineConfig({
      select: {
        $default: "structure",
      },
      transform: {
        $mode: "unsafe"
      },
    });
    `
    await fs.writeFile(paths.snapletConfig, configContent)
    const ssPath = createTestCapturePath()
    await runSnapletCLI(['snapshot capture', ssPath.name], {
      SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
    })
    await runSnapletCLI(['snapshot restore', ssPath.name], {
      SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
    })
    // Check that the public schema is restored with its data
    const publicPokemon = await execQueryNext(
      `SELECT * FROM public."Pokemon"`,
      targetDatabase
    )
    const publicOther = await execQueryNext(
      `SELECT * FROM public."Other"`,
      targetDatabase
    )
    const publicMigrations = await execQueryNext(
      `SELECT * FROM public._prisma_migrations`,
      targetDatabase
    )
    const authuUser = await execQueryNext(
      `SELECT * FROM auth.user`,
      targetDatabase
    )
    const privateEmployees = await execQueryNext(
      `SELECT * FROM private."Employee"`,
      targetDatabase
    )
    expect(publicPokemon.rowCount).toEqual(0)
    expect(publicOther.rowCount).toEqual(0)
    expect(publicMigrations.rowCount).toEqual(0)
    expect(authuUser.rowCount).toEqual(0)
    expect(privateEmployees.rowCount).toEqual(0)
  })
  test('should skip data on tables leveraging $default', async () => {
    const structure = `
      CREATE SCHEMA private;
      CREATE SCHEMA auth;

      -- Creating tables in the public schema and inserting data
      CREATE TABLE public._prisma_migrations (id SERIAL PRIMARY KEY, name TEXT, revision INTEGER, datamodel TEXT, status TEXT, applied_at TIMESTAMP);
      CREATE TABLE public."Pokemon" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      CREATE TABLE public."Other" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      -- Creating user table in auth schema (similar to supabase)
      CREATE TABLE auth.user ("id" SERIAL PRIMARY KEY, "name" TEXT, "email" TEXT);
      -- Creating table into private schema
      CREATE TABLE private."Employee" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      -- Insert data into public schema
      INSERT INTO public."Pokemon" VALUES (1, 'Pikachu');
      INSERT INTO public."Pokemon" VALUES (2, 'Charmander');
      INSERT INTO public."Other" VALUES (1, 'Other A');
      INSERT INTO public._prisma_migrations VALUES (1, 'init', 1, 'datamodel', 'MigrationSuccess', NOW());
      INSERT INTO public._prisma_migrations VALUES (2, 'init2', 2, 'datamodel', 'MigrationSuccess', NOW());
      -- Insert data into auth schema
      INSERT INTO auth.user VALUES (1, 'Koos Cumberbatch', 'test@gmail.com');
      INSERT INTO auth.user VALUES (2, 'Weakerthan Jake', 'test2@gmail.com');
      -- Insert data into private schema
      INSERT INTO private."Employee" VALUES (1, 'John Doe');
    `
    const connectionString = await createTestDb(structure)
    const targetDatabase = await createTestDb()
    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat, faker } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";
    export default defineConfig({
      select: {
        $default: "structure",
        public: {
          $default: "structure",
        },
      },
      transform: {
        $mode: "unsafe"
      },
    });
    `
    await fs.writeFile(paths.snapletConfig, configContent)
    const ssPath = createTestCapturePath()
    await runSnapletCLI(['snapshot capture', ssPath.name], {
      SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
    })
    await runSnapletCLI(['snapshot restore', ssPath.name], {
      SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
    })
    // Check that the public schema is restored with its data
    const publicPokemon = await execQueryNext(
      `SELECT * FROM public."Pokemon"`,
      targetDatabase
    )
    const publicOther = await execQueryNext(
      `SELECT * FROM public."Other"`,
      targetDatabase
    )
    const publicMigrations = await execQueryNext(
      `SELECT * FROM public._prisma_migrations`,
      targetDatabase
    )
    const authuUser = await execQueryNext(
      `SELECT * FROM auth.user`,
      targetDatabase
    )
    const privateEmployees = await execQueryNext(
      `SELECT * FROM private."Employee"`,
      targetDatabase
    )
    expect(publicPokemon.rowCount).toEqual(0)
    expect(publicOther.rowCount).toEqual(0)
    expect(publicMigrations.rowCount).toEqual(0)
    expect(authuUser.rowCount).toEqual(0)
    expect(privateEmployees.rowCount).toEqual(0)
  })
  test('should skip data on tables leveraging $default and overriding them', async () => {
    const structure = `
      CREATE SCHEMA private;
      CREATE SCHEMA auth;

      -- Creating tables in the public schema and inserting data
      CREATE TABLE public._prisma_migrations (id SERIAL PRIMARY KEY, name TEXT, revision INTEGER, datamodel TEXT, status TEXT, applied_at TIMESTAMP);
      CREATE TABLE public."Pokemon" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      CREATE TABLE public."Other" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      -- Creating user table in auth schema (similar to supabase)
      CREATE TABLE auth.user ("id" SERIAL PRIMARY KEY, "name" TEXT, "email" TEXT);
      -- Creating table into private schema
      CREATE TABLE private."Employee" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      -- Insert data into public schema
      INSERT INTO public."Pokemon" VALUES (1, 'Pikachu');
      INSERT INTO public."Pokemon" VALUES (2, 'Charmander');
      INSERT INTO public."Other" VALUES (1, 'Other A');
      INSERT INTO public._prisma_migrations VALUES (1, 'init', 1, 'datamodel', 'MigrationSuccess', NOW());
      INSERT INTO public._prisma_migrations VALUES (2, 'init2', 2, 'datamodel', 'MigrationSuccess', NOW());
      -- Insert data into auth schema
      INSERT INTO auth.user VALUES (1, 'Koos Cumberbatch', 'test@gmail.com');
      INSERT INTO auth.user VALUES (2, 'Weakerthan Jake', 'test2@gmail.com');
      -- Insert data into private schema
      INSERT INTO private."Employee" VALUES (1, 'John Doe');
    `
    const connectionString = await createTestDb(structure)
    const targetDatabase = await createTestDb()
    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat, faker } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";
    export default defineConfig({
      select: {
        $default: "structure",
        public: {
          $default: true,
          _prisma_migrations: "structure",
          Pokemon: "structure",
          Other: "structure",
        },
      },
      transform: {
        $mode: "unsafe"
      },
    });
    `
    await fs.writeFile(paths.snapletConfig, configContent)
    const ssPath = createTestCapturePath()
    await runSnapletCLI(['snapshot capture', ssPath.name], {
      SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
    })
    await runSnapletCLI(['snapshot restore', ssPath.name], {
      SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
    })
    // Check that the public schema is restored with its data
    const publicPokemon = await execQueryNext(
      `SELECT * FROM public."Pokemon"`,
      targetDatabase
    )
    const publicOther = await execQueryNext(
      `SELECT * FROM public."Other"`,
      targetDatabase
    )
    const publicMigrations = await execQueryNext(
      `SELECT * FROM public._prisma_migrations`,
      targetDatabase
    )
    const authuUser = await execQueryNext(
      `SELECT * FROM auth.user`,
      targetDatabase
    )
    const privateEmployees = await execQueryNext(
      `SELECT * FROM private."Employee"`,
      targetDatabase
    )
    expect(publicPokemon.rowCount).toEqual(0)
    expect(publicOther.rowCount).toEqual(0)
    expect(publicMigrations.rowCount).toEqual(0)
    expect(authuUser.rowCount).toEqual(0)
    expect(privateEmployees.rowCount).toEqual(0)
  })
  test('should skip data on tables leveraging $default and overriding them except one undefined', async () => {
    const structure = `
      CREATE SCHEMA private;
      CREATE SCHEMA auth;

      -- Creating tables in the public schema and inserting data
      CREATE TABLE public._prisma_migrations (id SERIAL PRIMARY KEY, name TEXT, revision INTEGER, datamodel TEXT, status TEXT, applied_at TIMESTAMP);
      CREATE TABLE public."Pokemon" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      CREATE TABLE public."Other" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      -- Creating user table in auth schema (similar to supabase)
      CREATE TABLE auth.user ("id" SERIAL PRIMARY KEY, "name" TEXT, "email" TEXT);
      -- Creating table into private schema
      CREATE TABLE private."Employee" ("id" SERIAL PRIMARY KEY, "name" TEXT);
      -- Insert data into public schema
      INSERT INTO public."Pokemon" VALUES (1, 'Pikachu');
      INSERT INTO public."Pokemon" VALUES (2, 'Charmander');
      INSERT INTO public."Other" VALUES (1, 'Other A');
      INSERT INTO public._prisma_migrations VALUES (1, 'init', 1, 'datamodel', 'MigrationSuccess', NOW());
      INSERT INTO public._prisma_migrations VALUES (2, 'init2', 2, 'datamodel', 'MigrationSuccess', NOW());
      -- Insert data into auth schema
      INSERT INTO auth.user VALUES (1, 'Koos Cumberbatch', 'test@gmail.com');
      INSERT INTO auth.user VALUES (2, 'Weakerthan Jake', 'test2@gmail.com');
      -- Insert data into private schema
      INSERT INTO private."Employee" VALUES (1, 'John Doe');
    `
    const connectionString = await createTestDb(structure)
    const targetDatabase = await createTestDb()
    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat, faker } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";
    export default defineConfig({
      select: {
        $default: "structure",
        public: {
          $default: true,
          _prisma_migrations: "structure",
          Pokemon: "structure",
        },
      },
      transform: {
        $mode: "unsafe"
      },
    });
    `
    await fs.writeFile(paths.snapletConfig, configContent)
    const ssPath = createTestCapturePath()
    await runSnapletCLI(['snapshot capture', ssPath.name], {
      SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
    })
    await runSnapletCLI(['snapshot restore', ssPath.name], {
      SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
    })
    // Check that the public schema is restored with its data
    const publicPokemon = await execQueryNext(
      `SELECT * FROM public."Pokemon"`,
      targetDatabase
    )
    const publicOther = await execQueryNext(
      `SELECT * FROM public."Other"`,
      targetDatabase
    )
    const publicMigrations = await execQueryNext(
      `SELECT * FROM public._prisma_migrations`,
      targetDatabase
    )
    const authuUser = await execQueryNext(
      `SELECT * FROM auth.user`,
      targetDatabase
    )
    const privateEmployees = await execQueryNext(
      `SELECT * FROM private."Employee"`,
      targetDatabase
    )
    expect(publicPokemon.rowCount).toEqual(0)
    expect(publicOther.rowCount).toEqual(1)
    expect(publicMigrations.rowCount).toEqual(0)
    expect(authuUser.rowCount).toEqual(0)
    expect(privateEmployees.rowCount).toEqual(0)
  })
  test('should include tables with explicit true', async () => {
    const structure = `
      -- Creating tables in the public schema and inserting data
      CREATE TABLE public.truly_empty_table (id SERIAL PRIMARY KEY, name TEXT);
      CREATE TABLE public._prisma_migrations (id SERIAL PRIMARY KEY, name TEXT, revision INTEGER, datamodel TEXT, status TEXT, applied_at TIMESTAMP);
      CREATE TABLE public.waste_water_providers (
        id text NOT NULL,
        "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
        "updatedAt" timestamp(3) without time zone NOT NULL,
        name text NOT NULL,
        logo text NOT NULL
      );
      CREATE TABLE public.marketing_campaigns (
        id text NOT NULL,
        "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
        slug text NOT NULL,
        "organizationId" text
      );
      CREATE TABLE public.average_fuel_prices (
          id text NOT NULL,
          "monthEnd" timestamp(3) without time zone NOT NULL,
          "pencePerLiterAmount" integer NOT NULL,
          "pencePerLiterPrecision" integer NOT NULL
      );
      ALTER TABLE ONLY public.average_fuel_prices
          ADD CONSTRAINT average_fuel_prices_pkey PRIMARY KEY (id);
      ALTER TABLE ONLY public.marketing_campaigns
      ADD CONSTRAINT marketing_campaigns_pkey PRIMARY KEY (id);
      CREATE UNIQUE INDEX marketing_campaigns_slug_key ON public.marketing_campaigns USING btree (slug);
      ALTER TABLE ONLY public.waste_water_providers
      ADD CONSTRAINT waste_water_providers_pkey PRIMARY KEY (id);
      CREATE UNIQUE INDEX waste_water_providers_name_key ON public.waste_water_providers USING btree (name);
      INSERT INTO public.marketing_campaigns VALUES ('1', NOW(), 'slug 1', 'organization 1');
      INSERT INTO public.marketing_campaigns VALUES ('2', NOW(), 'slug 2', 'organization 2');
      INSERT INTO public._prisma_migrations VALUES (1, 'init', 1, 'datamodel', 'MigrationSuccess', NOW());
      INSERT INTO public._prisma_migrations VALUES (2, 'init2', 2, 'datamodel', 'MigrationSuccess', NOW());
      INSERT INTO public.average_fuel_prices VALUES ('1', NOW(), 1, 1);
      INSERT INTO public.average_fuel_prices VALUES ('2', NOW(), 2, 2);
    `
    const connectionString = await createTestDb(structure)
    // -- Vacuum the database while waste_water_providers is still empty
    await execQueryNext(`VACUUM`, connectionString)
    await execQueryNext(
      `CREATE TABLE public.empty_table_after_vacuum (id SERIAL PRIMARY KEY, name TEXT);`,
      connectionString
    )
    // Insert data into waste_water_providers
    await execQueryNext(
      `
    INSERT INTO public.waste_water_providers VALUES ('1', NOW(), NOW(), 'provider 1', 'logo 1');
    INSERT INTO public.waste_water_providers VALUES ('2', NOW(), NOW(), 'provider 2', 'logo 2');
    `,
      connectionString
    )
    const targetDatabase = await createTestDb()
    const paths = await createTestProjectDirV2()
    const configContent = `
    const { copycat, faker } = require("@snaplet/copycat");

    /**
     * @type { import("./transformations").Transformations }
     */
    import { defineConfig } from "snaplet";
    export default defineConfig({
      select: {
        public: {
          _prisma_migrations: "structure",
          waste_water_providers: true,
        },
      },
      transform: {
        public: {
          marketing_campaigns: (data) => ({
            ...data,
            organizationId: null,
          }),
        },
      },
      subset: {
        enabled: false,

        targets: [
          {table: 'public.waste_water_providers', percent: 100},
        ]
      }
    });
    `
    await fs.writeFile(paths.snapletConfig, configContent)
    const ssPath = createTestCapturePath()
    await runSnapletCLI(['snapshot capture', ssPath.name], {
      SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
    })
    await runSnapletCLI(['snapshot restore', ssPath.name], {
      SNAPLET_TARGET_DATABASE_URL: targetDatabase.toString(),
    })
    // Check that the public schema is restored with its data
    const publicWasteProviders = await execQueryNext(
      `SELECT * FROM public."waste_water_providers"`,
      targetDatabase
    )
    const publicPrismaMigrations = await execQueryNext(
      `SELECT * FROM public._prisma_migrations`,
      targetDatabase
    )
    const publicMarketingCampains = await execQueryNext(
      `SELECT * FROM public.marketing_campaigns`,
      targetDatabase
    )
    const publicAverageFuelPrices = await execQueryNext(
      `SELECT * FROM public.average_fuel_prices`,
      targetDatabase
    )
    expect(publicWasteProviders.rowCount).toEqual(2)
    expect(publicMarketingCampains.rowCount).toEqual(2)
    expect(publicAverageFuelPrices.rowCount).toEqual(2)
    expect(publicPrismaMigrations.rowCount).toEqual(0)
  })
})
