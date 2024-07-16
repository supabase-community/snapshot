import { execQueryNext, escapeLiteral } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
} from '../../src/testing/index.js'
import fs from 'fs-extra'

vi.setConfig({
  testTimeout: 60_000,
})

describe('partial restore: --tables', () => {
  test('Only restore specified table', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({
        transform: {
          public: {
          }
        },
      })`

    await fs.writeFile(paths.snapletConfig, configContent)
    await execQueryNext(
      `CREATE TABLE "include_me" (
         name text
      )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "include_me" VALUES (
        'This is the included table'
      )`,
      sourceConnectionString.toString()
    )

    await execQueryNext(
      `CREATE TABLE "exclude_me" (
         name text
      )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "exclude_me" VALUES (
        'This is the excluded table'
      )`,
      sourceConnectionString.toString()
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
      ['snapshot restore', ssPath.name, '--tables=public.include_me'],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const excludeMeCount = await execQueryNext(
      `Select count(*) from exclude_me`,
      destinationConnectionString
    )
    expect(excludeMeCount.rows).toEqual([{ count: '0' }])
    const includeMeCount = await execQueryNext(
      `Select count(*) from include_me`,
      destinationConnectionString
    )
    expect(includeMeCount.rows).toEqual([{ count: '1' }])
  })

  test('Restore empty table', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({
        transform: {
          public: {
          }
        },
      })`

    await fs.writeFile(paths.snapletConfig, configContent)
    await execQueryNext(
      `CREATE TABLE "include_me" (
         name text
      )`,
      sourceConnectionString.toString()
    )
    // We insert nothing into this table

    await execQueryNext(
      `CREATE TABLE "exclude_me" (
         name text
      )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "exclude_me" VALUES (
        'This is the excluded table'
      )`,
      sourceConnectionString.toString()
    )
    const ssPath = createTestCapturePath()

    await runSnapletCLI(
      ['snapshot', 'capture', ssPath.name],
      {
        SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
      },
      paths
    )

    //Create and insert into destination include_me table
    await execQueryNext(
      `CREATE TABLE "include_me" (
         name text
      )`,
      destinationConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "include_me" VALUES (
        'This is the included table'
      )`,
      destinationConnectionString.toString()
    )

    await runSnapletCLI(
      ['snapshot restore', ssPath.name, '--tables=public.include_me'],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const excludeMeCount = await execQueryNext(
      `Select count(*) from exclude_me`,
      destinationConnectionString
    )
    expect(excludeMeCount.rows).toEqual([{ count: '0' }])
    const includeMeCount = await execQueryNext(
      `Select count(*) from include_me`,
      destinationConnectionString
    )
    expect(includeMeCount.rows).toEqual([{ count: '0' }])
  })

  test('Restore table without its parent table', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({
        transform: {
          public: {
          }
        },
      })`

    await fs.writeFile(paths.snapletConfig, configContent)
    await execQueryNext(
      `CREATE TABLE "parent" (
         id serial primary key,
         name text
      )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "parent" (id, name) VALUES (
        1,
        'This is the parent table'
      )`,
      sourceConnectionString.toString()
    )

    await execQueryNext(
      `CREATE TABLE "child" (
         name text,
         parent_id INTEGER NOT NULL,
         CONSTRAINT fk_parent FOREIGN KEY (parent_id) REFERENCES parent(id)
        )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "child" VALUES (
        'This is the child table',
        1
      )`,
      sourceConnectionString.toString()
    )
    const ssPath = createTestCapturePath()

    await runSnapletCLI(
      ['snapshot', 'capture', ssPath.name],
      {
        SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
      },
      paths
    )

    const res = await runSnapletCLI(
      ['snapshot restore', ssPath.name, '--tables=child'],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )
    // Lets check that we get a warining in the response
    expect(res.stdout).toContain(
      '[Create constraints] Warning: insert or update on table "child" violates foreign key constraint "fk_parent" (public.child)'
    )
    const excludeMeCount = await execQueryNext(
      `Select count(*) from parent`,
      destinationConnectionString
    )
    expect(excludeMeCount.rows).toEqual([{ count: '0' }])
    const includeMeCount = await execQueryNext(
      `Select * from child`,
      destinationConnectionString
    )
    // Our restore is breaking thie foreign key constraint becasue parent with id one has not been restored
    expect(includeMeCount.rows).toEqual([
      {
        name: 'This is the child table',
        parent_id: 1,
      },
    ])
  })

  test('Multiple schemas', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
        import { copycat } from "@snaplet/copycat";
        import { defineConfig } from "snaplet";

        export default defineConfig({
          transform: {
            public: {
            }
          },
        })`

    await fs.writeFile(paths.snapletConfig, configContent)
    await execQueryNext(
      `CREATE TABLE "include_me" (
           name text
        )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "include_me" VALUES (
          'This is the included table'
        )`,
      sourceConnectionString.toString()
    )

    await execQueryNext(
      `CREATE SCHEMA "another_schema"`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `CREATE TABLE "another_schema"."include_me_too" (
           name text
        )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "another_schema"."include_me_too" VALUES (
          'This is another included table'
        )`,
      sourceConnectionString.toString()
    )

    await execQueryNext(
      `CREATE TABLE "exclude_me" (
           name text
        )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "exclude_me" VALUES (
          'This is the excluded table'
        )`,
      sourceConnectionString.toString()
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
      [
        'snapshot restore',
        ssPath.name,
        '--tables=public.include_me,another_schema.include_me_too',
      ],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const excludeMeCount = await execQueryNext(
      `Select count(*) from exclude_me`,
      destinationConnectionString
    )
    expect(excludeMeCount.rows).toEqual([{ count: '0' }])
    const includeMeCount = await execQueryNext(
      `Select count(*) from include_me`,
      destinationConnectionString
    )
    expect(includeMeCount.rows).toEqual([{ count: '1' }])

    const includeMeTooCount = await execQueryNext(
      `Select count(*) from another_schema.include_me_too`,
      destinationConnectionString
    )
    expect(includeMeTooCount.rows).toEqual([{ count: '1' }])
  })

  test('with no-schema and no-reset', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
          import { copycat } from "@snaplet/copycat";
          import { defineConfig } from "snaplet";

          export default defineConfig({
            transform: {
              public: {
              }
            },
          })`

    await fs.writeFile(paths.snapletConfig, configContent)
    await execQueryNext(
      `CREATE TABLE "include_me" (
             name text
          )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "include_me" VALUES (
            'This is the included table'
          )`,
      sourceConnectionString.toString()
    )

    await execQueryNext(
      `CREATE TABLE "exclude_me" (
             name text
          )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "exclude_me" VALUES (
            'This is the excluded table'
          )`,
      sourceConnectionString.toString()
    )

    //In destination db we only create the table that we want to restore
    await execQueryNext(
      `CREATE TABLE "include_me" (
              name text
            )`,
      destinationConnectionString.toString()
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
      [
        'snapshot restore',
        ssPath.name,
        '--tables=public.include_me',
        '--no-schema',
        '--no-reset',
      ],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const includeMeCount = await execQueryNext(
      `Select count(*) from include_me`,
      destinationConnectionString
    )
    expect(includeMeCount.rows).toEqual([{ count: '1' }])
    const excludeMeExists = await execQueryNext(
      `SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'exclude_me')`,
      destinationConnectionString
    )
    expect(excludeMeExists.rows).toEqual([{ exists: false }])
  })

  test('with no-schema and no-reset on a snapshot with fk in tables', async () => {
    const sourceConnectionString = await createTestDb()
    const targetConnectionString = await createTestDb()
    const paths = await createTestProjectDirV2()

    // Setup source
    await execQueryNext(
      `CREATE TABLE public."team"
        (
            id INT GENERATED ALWAYS AS IDENTITY,
            name text NOT NULL,
            PRIMARY KEY (id)
        );`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `CREATE TABLE public."user"
                (
                  id INT GENERATED ALWAYS AS IDENTITY,
                  name text NOT NULL,
                  team_id INT DEFAULT NULL,
                  PRIMARY KEY (id),
                  CONSTRAINT fk_team FOREIGN KEY (team_id) REFERENCES "team"(id)
                );`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `
            INSERT INTO public."team" (name) VALUES ('team1');
            INSERT INTO public."user" (name, team_id) VALUES ('user1', 1);
            INSERT INTO public."user" (name, team_id) VALUES ('user2', 1);
            INSERT INTO public."user" (name, team_id) VALUES ('user3', 1);
            INSERT INTO public."user" (name, team_id) VALUES ('user4', 1);
            INSERT INTO public."user" (name, team_id) VALUES ('user5', 1);
            INSERT INTO public."user" (name, team_id) VALUES ('user6', NULL);
            INSERT INTO public."user" (name, team_id) VALUES ('user7', NULL);
            INSERT INTO public."user" (name, team_id) VALUES ('user8', NULL);
        `,
      sourceConnectionString.toString()
    )
    // Setup target with some data already in it
    await execQueryNext(
      `CREATE TABLE public."team"
        (
            id INT GENERATED ALWAYS AS IDENTITY,
            name text NOT NULL,
            PRIMARY KEY (id)
        );`,
      targetConnectionString.toString()
    )
    await execQueryNext(
      `CREATE TABLE public."user"
                (
                  id INT GENERATED ALWAYS AS IDENTITY,
                  name text NOT NULL,
                  team_id INT DEFAULT NULL,
                  PRIMARY KEY (id),
                  CONSTRAINT fk_team FOREIGN KEY (team_id) REFERENCES "team"(id)
                );`,
      targetConnectionString.toString()
    )
    await execQueryNext(
      `
            INSERT INTO public."user" (name, team_id) VALUES ('user42', NULL);
            INSERT INTO public."user" (name, team_id) VALUES ('user43', NULL);
            INSERT INTO public."user" (name, team_id) VALUES ('user44', NULL);
        `,
      targetConnectionString.toString()
    )

    const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({
        select: {
          public: {
            user: false,
          },
        },
      })`
    await fs.writeFile(paths.snapletConfig, configContent)

    const ssPath = createTestCapturePath()
    await runSnapletCLI(
      ['snapshot', 'capture', ssPath.name],
      {
        SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
      },
      paths
    )
    await runSnapletCLI(
      ['snapshot restore', ssPath.name, '--no-schema', '--no-reset'],
      {
        SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
      },
      paths
    )
    const usersResult = await execQueryNext(
      `SELECT * FROM public."user"`,
      targetConnectionString
    )
    const teamsResult = await execQueryNext(
      `SELECT * FROM public."team"`,
      targetConnectionString
    )
    // Should have kept the "users" data in the target db
    expect(usersResult.rows).toEqual(
      expect.arrayContaining([
        { id: 1, name: 'user42', team_id: null },
        { id: 2, name: 'user43', team_id: null },
        { id: 3, name: 'user44', team_id: null },
      ])
    )
    // Should have also imported the "teams" data from the source db
    expect(teamsResult.rows).toEqual(
      expect.arrayContaining([{ id: 1, name: 'team1' }])
    )
  })

  test('with no-schema and no-reset and schema drift between target and source', async () => {
    // This behaviour is mainly used for user restoring against a supabase instance
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
      import { copycat } from "@snaplet/copycat";
      import { defineConfig } from "snaplet";

      export default defineConfig({
        transform: {
          public: {
          }
        },
      })`

    await fs.writeFile(paths.snapletConfig, configContent)
    const structure = `
      CREATE TABLE "include_me" (
        name text,
        other text
      );
      CREATE TABLE "exclude_me" (
        name text
      );
    `
    const data = `
    INSERT INTO "include_me" VALUES (
      ${escapeLiteral(
        'This is the included table, with some \n specials \n characters in " \' it'
      )},
      'othercolumn'
    );
    INSERT INTO "exclude_me" VALUES (
      'This is the excluded table'
    );`
    await execQueryNext(structure, sourceConnectionString.toString())
    await execQueryNext(data, sourceConnectionString.toString())
    // We set the structure of the target database but drop the "order" column
    await execQueryNext(
      `
    ${structure}
    ALTER TABLE "include_me" DROP COLUMN other;
    `,
      destinationConnectionString.toString()
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
      ['snapshot restore', ssPath.name, '--no-schema', '--no-reset'],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const includeMe = await execQueryNext(
      `SELECT * from include_me`,
      destinationConnectionString
    )
    expect(includeMe.rows).toEqual([
      {
        name: 'This is the included table, with some \n specials \n characters in " \' it',
      },
    ])
    expect(includeMe.rowCount).toEqual(1)
  })
})

describe('partial restore: --exclude-tables', () => {
  test('Only restore include_me table', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
          import { copycat } from "@snaplet/copycat";
          import { defineConfig } from "snaplet";

          export default defineConfig({
            transform: {
              public: {
              }
            },
          })`

    await fs.writeFile(paths.snapletConfig, configContent)
    await execQueryNext(
      `CREATE TABLE "include_me" (
             name text
          )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "include_me" VALUES (
            'This is the included table'
          )`,
      sourceConnectionString.toString()
    )

    await execQueryNext(
      `CREATE TABLE "exclude_me" (
             name text
          )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "exclude_me" VALUES (
            'This is the excluded table'
          )`,
      sourceConnectionString.toString()
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
      ['snapshot restore', ssPath.name, '--exclude-tables=public.exclude_me'],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const excludeMeCount = await execQueryNext(
      `Select count(*) from exclude_me`,
      destinationConnectionString
    )
    expect(excludeMeCount.rows).toEqual([{ count: '0' }])
    const includeMeCount = await execQueryNext(
      `Select count(*) from include_me`,
      destinationConnectionString
    )
    expect(includeMeCount.rows).toEqual([{ count: '1' }])
  })

  test('Multiple schemas', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
        import { copycat } from "@snaplet/copycat";
        import { defineConfig } from "snaplet";

        export default defineConfig({
          transform: {
            public: {
            }
          },
        })`

    await fs.writeFile(paths.snapletConfig, configContent)
    await execQueryNext(
      `CREATE TABLE "include_me" (
           name text
        )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "include_me" VALUES (
          'This is the included table'
        )`,
      sourceConnectionString.toString()
    )

    await execQueryNext(
      `CREATE SCHEMA "another_schema"`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `CREATE TABLE "another_schema"."exclude_me_too" (
           name text
        )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "another_schema"."exclude_me_too" VALUES (
          'This is another excluded table'
        )`,
      sourceConnectionString.toString()
    )

    await execQueryNext(
      `CREATE TABLE "exclude_me" (
           name text
        )`,
      sourceConnectionString.toString()
    )
    await execQueryNext(
      `INSERT INTO "exclude_me" VALUES (
          'This is the excluded table'
        )`,
      sourceConnectionString.toString()
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
      [
        'snapshot restore',
        ssPath.name,
        '--exclude-tables=public.exclude_me,another_schema.exclude_me_too',
      ],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const excludeMeCount = await execQueryNext(
      `Select count(*) from exclude_me`,
      destinationConnectionString
    )
    expect(excludeMeCount.rows).toEqual([{ count: '0' }])
    const includeMeCount = await execQueryNext(
      `Select count(*) from include_me`,
      destinationConnectionString
    )
    expect(includeMeCount.rows).toEqual([{ count: '1' }])

    const excludeMeTooCount = await execQueryNext(
      `Select count(*) from another_schema.exclude_me_too`,
      destinationConnectionString
    )
    expect(excludeMeTooCount.rows).toEqual([{ count: '0' }])
  })
})
