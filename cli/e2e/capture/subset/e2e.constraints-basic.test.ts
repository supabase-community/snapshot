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

test('basic one to many empty database', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()
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
test('basic many to many relationship empty database', async () => {
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
                  PRIMARY KEY (id),
                  CONSTRAINT fk_team FOREIGN KEY (team_id) REFERENCES "team"(id),
                  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES "user"(id)
              );`,
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
test('basic one to many relationship eager subset', async () => {
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
          table: 'public.user',
          where: '"user"."id" IN (5, 8)',
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
  const usersResult = await execQueryNext(
    `SELECT * FROM public.user`,
    targetConnectionString
  )
  const teamResult = await execQueryNext(
    `SELECT * FROM public.team`,
    targetConnectionString
  )
  expect(usersResult.rowCount).toBe(6)
  expect(usersResult.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 5,
      }),
      expect.objectContaining({
        id: 8,
      }),
      expect.objectContaining({
        id: 2,
      }),
      expect.objectContaining({
        id: 3,
      }),
      expect.objectContaining({
        id: 4,
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
test('basic many to many relationship eager subset', async () => {
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
                  PRIMARY KEY (id),
                  CONSTRAINT fk_team FOREIGN KEY (team_id) REFERENCES "team"(id),
                  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES "user"(id)
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
      maxCyclesLoop: 10,
      eager: true,
      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.user',
          where: '"user"."id" IN (1)',
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
  const usersResult = await execQueryNext(
    `SELECT * FROM public.user`,
    targetConnectionString
  )
  const teamResult = await execQueryNext(
    `SELECT * FROM public.team`,
    targetConnectionString
  )
  expect(usersResult.rowCount).toBe(3)
  expect(usersResult.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 1,
      }),
      expect.objectContaining({
        id: 3,
      }),
      expect.objectContaining({
        id: 2,
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
test('basic one to many relationship lazy subset', async () => {
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
test('basic many to many relationship lazy subset', async () => {
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
                  PRIMARY KEY (id),
                  CONSTRAINT fk_team FOREIGN KEY (team_id) REFERENCES "team"(id),
                  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES "user"(id)
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
test('grand child making parent grow', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
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
      followNullableRelations: true,
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
test('capturing and restoring with two childs FK pointing to the same table', async () => {
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
test('capturing and restoring with multiples childs FK pointing to the same table', async () => {
  const sourceConnectionString = (await createTestDb()).toString()
  const targetConnectionString = (await createTestDb()).toString()
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
          a_db_id INT NULL,
          b_db_id INT DEFAULT NULL,
          c_db_id INT DEFAULT NULL,
          d_db_id INT DEFAULT NULL,
          e_db_id INT DEFAULT NULL,
          f_db_id INT DEFAULT NULL,
          PRIMARY KEY (id),
          CONSTRAINT fk_a_db FOREIGN KEY (a_db_id) REFERENCES "db"(id),
          CONSTRAINT fk_b_db FOREIGN KEY (b_db_id) REFERENCES "db"(id),
          CONSTRAINT fk_c_db FOREIGN KEY (c_db_id) REFERENCES "db"(id),
          CONSTRAINT fk_d_db FOREIGN KEY (d_db_id) REFERENCES "db"(id),
          CONSTRAINT fk_e_db FOREIGN KEY (e_db_id) REFERENCES "db"(id),
          CONSTRAINT fk_f_db FOREIGN KEY (f_db_id) REFERENCES "db"(id)
      );`,
    sourceConnectionString
  )
  const sqlInsertQuery = `
      INSERT INTO "db" (id, name) VALUES (1, 'a');
      INSERT INTO "db" (id, name) VALUES (2, 'b');
      INSERT INTO "db" (id, name) VALUES (3, 'b');
      INSERT INTO "db" (id, name) VALUES (4, 'b');
      INSERT INTO "db" (id, name) VALUES (5, 'b');
      INSERT INTO "user" (id, a_db_id, b_db_id, c_db_id, d_db_id, e_db_id, f_db_id) VALUES (1, 1, 2, 3, 4, 5, 1);
      `
  // Insert a rows with both fk values pointing to the same table but different rows
  await execQueryNext(sqlInsertQuery, sourceConnectionString)
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
  await checkConstraints(sourceConnectionString, targetConnectionString)
})
test('capturing and restoring with two parents FK pointing to the same table', async () => {
  const structure = `
        CREATE TABLE "author" (
          "id" SERIAL PRIMARY KEY
        );
        CREATE TABLE "book" (
          "id" SERIAL PRIMARY KEY,
          "author_id" INTEGER NOT NULL,
          CONSTRAINT "book_author_id_fkey" FOREIGN KEY ("author_id")
            REFERENCES "author" ("id")
            ON DELETE CASCADE
        );
        CREATE TABLE "publisher" ("id" SERIAL PRIMARY KEY);
        ALTER TABLE "author" ADD COLUMN "publisher_id" INTEGER NOT NULL;
        ALTER TABLE "author" ADD CONSTRAINT "author_publisher_fkey" FOREIGN KEY ("publisher_id") REFERENCES "publisher" ("id") ON DELETE SET NULL;
        ALTER TABLE "book" ADD COLUMN "author_id_2" INTEGER NOT NULL;
        ALTER TABLE "book" ADD CONSTRAINT "book_author_2_fkey" FOREIGN KEY ("author_id_2") REFERENCES "author" ("id") ON DELETE SET NULL;
      `
  const sourceConnectionString = (await createTestDb(structure)).toString()
  const targetConnectionString = (await createTestDb()).toString()
  const paths = await createTestProjectDirV2()
  // Insert into Publisher 2 rows
  const sqlInsertQuery = `
        INSERT INTO "publisher" (id) VALUES (1), (2);
        INSERT INTO "author" (id, publisher_id) VALUES (10,1);
        INSERT INTO "author" (id, publisher_id) VALUES (11,2);
        INSERT INTO "book" (id, author_id, author_id_2) VALUES (20, 10, 11);
      `
  await execQueryNext(sqlInsertQuery, sourceConnectionString)
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: true,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.author',
          where: 'id = 10',
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
test('capturing and restoring with two differents paths growing the same tables books_assignations_groups with follow_nullable_relations false', async () => {
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

      keepDisconnectedTables: true,
      followNullableRelations: {
        'public.books_assignations': false,
      },
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
  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  expect(restoredBooks.rowCount).toBe(1)
  expect(restoredAuthors.rowCount).toBe(1)
  expect(restoredGroups.rowCount).toBe(1)
  expect(restoredGroupToAuthor.rowCount).toBe(1)
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
        id: 63,
        author_id: 2,
        assignation_id: null,
      }),
    ])
  )
  expect(restoredAuthors.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 2,
      }),
    ])
  )
  expect(restoredGroups.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        id: 11,
      }),
    ])
  )
  expect(restoredGroupToAuthor.rows).toEqual(
    expect.arrayContaining([
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
      keepDisconnectedTables: true,
      followNullableRelations: true,
      eager: true,
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
