import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  runSnapletCLI,
  checkConstraints,
  createTestProjectDirV2,
} from '../../../src/testing/index.js'
import fsExtra from 'fs-extra'

vi.setConfig({
  testTimeout: 10 * 60 * 1000,
})

test('virtualkeys subset basic one to many relationship lazy subset', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // That's a classical OneToMany relationship pattern.
  // 1. We have users
  // 2. We have teams
  // 3. A team can have several users
  // 4. An user can be in a single team or no team at all
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
                PRIMARY KEY (id)
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
          where: '"user"."id" IN (5, 8)',
        },
      ],
    },
    introspect: {
      virtualForeignKeys: [
        {
          fkTable: 'public.user',
          targetTable: 'public.team',
          keys: [
            {
              fkColumn: 'team_id',
              targetColumn: 'id',
            },
          ],
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
  const usersResult = await execQueryNext(
    `SELECT * FROM public.user`,
    targetConnectionString
  )
  const teamResult = await execQueryNext(
    `SELECT * FROM public.team`,
    targetConnectionString
  )
  expect(usersResult.rowCount).toBe(2)
  expect(usersResult.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 5,
      }),
      expect.objectContaining({
        id: 8,
      }),
    ])
  )
  expect(teamResult.rowCount).toBe(1)
  expect(teamResult.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 1,
      }),
    ])
  )
})

test('virtualkeys subset basic many to many relationship lazy subset', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

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
                  PRIMARY KEY (id)
              );`,
    sourceConnectionString.toString()
  )
  await execQueryNext(
    `
          INSERT INTO public."team" (name) VALUES ('team1');
          INSERT INTO public."team" (name) VALUES ('team2');
          INSERT INTO public."team" (name) VALUES ('team3');
          INSERT INTO public."team" (name) VALUES ('team4');
          INSERT INTO public."user" (name) VALUES ('user1');
          INSERT INTO public."user" (name) VALUES ('user2');
          INSERT INTO public."user" (name) VALUES ('user3');
          INSERT INTO public."user" (name) VALUES ('user4');
          INSERT INTO public."user" (name) VALUES ('user5');
          INSERT INTO public."user" (name) VALUES ('user6');
          INSERT INTO public."user" (name) VALUES ('user7');
          INSERT INTO public."user" (name) VALUES ('user8');
          INSERT INTO public."team_to_user" (user_id, team_id) VALUES (1, 1);
          INSERT INTO public."team_to_user" (user_id, team_id) VALUES (1, 2);
          INSERT INTO public."team_to_user" (user_id, team_id) VALUES (2, 1);
          INSERT INTO public."team_to_user" (user_id, team_id) VALUES (2, 2);
          INSERT INTO public."team_to_user" (user_id, team_id) VALUES (3, 1);
      `,
    sourceConnectionString.toString()
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
          where: '"user"."id" IN (1)',
        },
      ],
    },
    introspect: {
      virtualForeignKeys: [
        {
          fkTable: 'public.team_to_user',
          targetTable: 'public.team',
          keys: [
            {
              fkColumn: 'team_id',
              targetColumn: 'id',
            },
          ],
        },
        {
          fkTable: 'public.team_to_user',
          targetTable: 'public.user',
          keys: [
            {
              fkColumn: 'user_id',
              targetColumn: 'id',
            },
          ],
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
  const usersResult = await execQueryNext(
    `SELECT * FROM public.user`,
    targetConnectionString
  )
  const teamResult = await execQueryNext(
    `SELECT * FROM public.team`,
    targetConnectionString
  )
  expect(usersResult.rowCount).toBe(1)
  expect(usersResult.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 1,
      }),
    ])
  )
  expect(teamResult.rowCount).toBe(2)
  expect(teamResult.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 1,
      }),
      expect.objectContaining({
        id: 2,
      }),
    ])
  )
})

test('virtualkeys subset capturing and restoring database with composite FK and composite FK', async () => {
  const structure = `
    CREATE TABLE "Authors" (
        "AuthorID" SERIAL PRIMARY KEY,
        "FirstName" VARCHAR(255) NOT NULL,
        "LastName" VARCHAR(255) NOT NULL
    );

    CREATE TABLE "Books" (
        "BookID" SERIAL PRIMARY KEY,
        "Title" VARCHAR(255) NOT NULL,
        "AuthorID" INT NOT NULL,
        UNIQUE ("BookID", "AuthorID")
    );

    CREATE TABLE "BookEditions" (
        "EditionID" SERIAL PRIMARY KEY,
        "BookID" INT NOT NULL,
        "AuthorID" INT NOT NULL,
        "EditionName" VARCHAR(255) NOT NULL,
        "PublicationYear" INT NOT NULL
    );

    CREATE TABLE "BookSales" (
        "EditionID" INT NOT NULL,
        "SaleDate" DATE NOT NULL,
        "QuantitySold" INT NOT NULL,
        PRIMARY KEY ("EditionID", "SaleDate")
    );
  `
  const sourceConnectionString = await createTestDb(structure)
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()
  const insertDataScript = `
  INSERT INTO "Authors" ("FirstName", "LastName")
  VALUES ('George', 'Orwell'),
        ('Aldous', 'Huxley'),
        ('Ray', 'Bradbury');

  INSERT INTO "Books" ("Title", "AuthorID")
  VALUES ('1984', 1),
        ('Brave New World', 2),
        ('Fahrenheit 451', 3);

  INSERT INTO "BookEditions" ("BookID", "AuthorID", "EditionName", "PublicationYear")
  VALUES (1, 1, 'First Edition', 1949),
        (2, 2, 'First Edition', 1932),
        (3, 3, 'First Edition', 1953),
        (1, 1, 'Second Edition', 1934);

  INSERT INTO "BookSales" ("EditionID", "SaleDate", "QuantitySold")
  VALUES (1, '2023-04-01', 10),
        (2, '2023-04-01', 12),
        (2, '2023-04-02', 12),
        (1, '2023-04-02', 12),
        (3, '2023-04-03', 15);
  `
  await execQueryNext(insertDataScript, sourceConnectionString)

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      keepDisconnectedTables: true,
      targets: [
        {
          table: 'public.Books',
          where: \`"Books"."Title" = '1984'\`,
        },
      ],
    },
    introspect: {
      virtualForeignKeys: [
        {
          fkTable: 'public.Books',
          targetTable: 'public.Authors',
          keys: [
            {
              fkColumn: 'AuthorID',
              targetColumn: 'AuthorID',
            },
          ],
        },
        {
          fkTable: 'public.BookSales',
          targetTable: 'public.BookEditions',
          keys: [
            {
              fkColumn: 'EditionID',
              targetColumn: 'EditionID',
            },
          ],
        },
        {
          fkTable: 'public.BookEditions',
          targetTable: 'public.Books',
          keys: [
            {
              fkColumn: 'BookID',
              targetColumn: 'BookID',
            },
            {
              fkColumn: 'AuthorID',
              targetColumn: 'AuthorID',
            },
          ],
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
  const bookEditions = await execQueryNext(
    `SELECT * FROM "BookEditions"`,
    targetConnectionString
  )
  const bookSales = await execQueryNext(
    `SELECT * FROM "BookSales"`,
    targetConnectionString
  )
  expect(bookEditions.rowCount).toEqual(2)
  expect(bookEditions.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        BookID: 1,
        AuthorID: 1,
        EditionName: 'First Edition',
        PublicationYear: 1949,
      }),
      expect.objectContaining({
        BookID: 1,
        AuthorID: 1,
        EditionName: 'Second Edition',
        PublicationYear: 1934,
      }),
    ])
  )
  expect(bookSales.rowCount).toEqual(2)
  expect(bookSales.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        EditionID: 1,
        QuantitySold: 10,
      }),
      expect.objectContaining({
        EditionID: 1,
        QuantitySold: 12,
      }),
    ])
  )
})

test('virtualkeys subset basic one to many relationship lazy subset cross schema', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // That's a classical OneToMany relationship pattern.
  // 1. We have users
  // 2. We have teams
  // 3. A team can have several users
  // 4. An user can be in a single team or no team at all
  await execQueryNext(
    `CREATE SCHEMA team_schema;`,
    sourceConnectionString.toString()
  )
  await execQueryNext(
    `CREATE TABLE team_schema."team"
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
                PRIMARY KEY (id)
              );`,
    sourceConnectionString.toString()
  )
  await execQueryNext(
    `
          INSERT INTO team_schema."team" (name) VALUES ('team1');
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
          where: '"user"."id" IN (5, 8)',
        },
      ],
    },
    introspect: {
      virtualForeignKeys: [
        {
          fkTable: 'public.user',
          targetTable: 'team_schema.team',
          keys: [
            {
              fkColumn: 'team_id',
              targetColumn: 'id',
            },
          ],
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
  const usersResult = await execQueryNext(
    `SELECT * FROM public.user`,
    targetConnectionString
  )
  const teamResult = await execQueryNext(
    `SELECT * FROM team_schema.team`,
    targetConnectionString
  )
  expect(usersResult.rowCount).toBe(2)
  expect(usersResult.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 5,
      }),
      expect.objectContaining({
        id: 8,
      }),
    ])
  )
  expect(teamResult.rowCount).toBe(1)
  expect(teamResult.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 1,
      }),
    ])
  )
})
