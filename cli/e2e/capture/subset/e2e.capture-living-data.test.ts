import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
  checkConstraints,
} from '../../../src/testing/index.js'
import fsExtra from 'fs-extra'
import fs from 'fs'

import path from 'path'

import { splitSchema } from '../../../src/commands/snapshot/actions/restore/lib/pgSchemaTools.js'

vi.setConfig({
  testTimeout: 10 * 60 * 1000,
})

const FIXTURES_DIR = path.resolve(__dirname, '../../../__fixtures__')

async function loadDbDumpFixture(
  // The dump must be a .sql file located into __fixtures__
  dumpName: string,
  connectionString: string
) {
  const fileContent = fs
    .readFileSync(path.join(FIXTURES_DIR, dumpName))
    .toString('utf-8')
  const queries = splitSchema(fileContent)
  for (const stmt of queries) {
    try {
      await execQueryNext(stmt, connectionString)
    } catch (e) {
      console.log(stmt)
      console.log(e)
      throw e
    }
  }
}

test('ensure capture consistency on living data', async () => {
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
    `CREATE TABLE public."project"
    (
        id INT GENERATED ALWAYS AS IDENTITY,
        name text NOT NULL,
        PRIMARY KEY (id)
    );`,
    sourceConnectionString.toString()
  )
  await execQueryNext(
    `CREATE TABLE public."team_project"
    (
        team_id INT NOT NULL,
        project_id INT NOT NULL,
        PRIMARY KEY (team_id, project_id),
        CONSTRAINT fk_team FOREIGN KEY (team_id) REFERENCES "team"(id),
        CONSTRAINT fk_project FOREIGN KEY (project_id) REFERENCES "project"(id)
    );`,
    sourceConnectionString.toString()
  )
  await execQueryNext(
    `CREATE TABLE public."user"
      (
        id INT GENERATED ALWAYS AS IDENTITY,
        name text NOT NULL,
        team_id INT DEFAULT NULL,
        mentor_id INT DEFAULT NULL,
        PRIMARY KEY (id),
        CONSTRAINT fk_team FOREIGN KEY (team_id) REFERENCES "team"(id),
        CONSTRAINT fk_user FOREIGN KEY (mentor_id) REFERENCES "user"(id) ON DELETE SET NULL
      );`,
    sourceConnectionString.toString()
  )
  await execQueryNext(
    `INSERT INTO public."team" (name) VALUES ('team1');`,
    sourceConnectionString.toString()
  )
  await execQueryNext(
    `INSERT INTO public."project" (name) VALUES ('project1'), ('project2'), ('project3');`,
    sourceConnectionString.toString()
  )

  await execQueryNext(
    `INSERT INTO public."team_project" (team_id, project_id) VALUES (1, 1), (1, 2), (1, 3);`,
    sourceConnectionString.toString()
  )

  // Create a lot of connected users
  await execQueryNext(
    Array.from({ length: 100000 })
      .map(
        (_, i) =>
          `INSERT INTO public."user" (name, team_id, mentor_id) VALUES ('user${i}', 1, ${
            i > 2 ? i - 1 : 'NULL'
          })`
      )
      .join(';'),
    sourceConnectionString.toString()
  )

  function randomIntFromInterval(min: number, max: number) {
    // min and max included
    return Math.floor(Math.random() * (max - min + 1) + min)
  }
  const deletedUsers: number[] = []

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: false,
      version: '3',
      targets: [
        {
          table: 'public.user',
          percent: 100,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const deletedTeamProjects: { team_id: number; project_id: number }[] = []

  const removeRandomUser = async () => {
    try {
      const randomUser = randomIntFromInterval(1, 100000)
      if (deletedUsers.includes(randomUser)) {
        return
      }
      await execQueryNext(
        `DELETE FROM "user" WHERE id = ${randomUser}`,
        sourceConnectionString.toString()
      )
      deletedUsers.push(randomUser)
    } catch (e) {
      // noop since we a running a lot of parallel queries in an interval some errors can happen we dissmiss them
    }
  }
  const removeRandomTeamProject = async () => {
    try {
      const randomTeam = 1
      const randomProject = randomIntFromInterval(1, 3)
      if (
        deletedTeamProjects.some(
          (tp) => tp.team_id === randomTeam && tp.project_id === randomProject
        )
      ) {
        return
      }
      await execQueryNext(
        `DELETE FROM "team_project" WHERE team_id = ${randomTeam} AND project_id = ${randomProject}`,
        sourceConnectionString.toString()
      )
      deletedTeamProjects.push({
        team_id: randomTeam,
        project_id: randomProject,
      })
    } catch (e) {
      // noop since we a running a lot of parallel queries in an interval some errors can happen we dissmiss them
    }
  }
  const ssPath = createTestCapturePath()
  // Remove random data every 5ms to simulate a living database
  // This test might be a bit "flaky" in terms of "fail" case but it's the best way to ensure we are not breaking anything
  // I've tried this without the fix and it was failing 100% of the time over ~20+ runs
  // And also passing 100% of the time with the fix (which is expected)
  const interval = setInterval(async () => {
    // Make 10 changes at once
    const changes = []
    for (let i = 0; i < 10; i++) {
      changes.push(removeRandomUser())
      changes.push(removeRandomTeamProject())
    }
    await Promise.all(changes)
  }, 5)
  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )
  clearInterval(interval)
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
  const resultUser = await execQueryNext(
    `SELECT * FROM "user"`,
    targetConnectionString
  )
  expect(resultUser.rowCount).toBeGreaterThan(0)
})

test.skip('only capture and restore living data on videolet v3', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('videolet.sql', sourceConnectionString.toString())

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    transform: {
      public: {
        actor: ({row}) => {
          for (let i = 0; i < 10000000; i += 1){} // To slow down the capture process
          return row;
        },
        film: ({row}) => {
          for (let i = 0; i < 10000000; i += 1){} // To slow down the capture process
          return row;
        },
        film_actor: ({row}) => {
          for (let i = 0; i < 1000000; i += 1){} // To slow down the capture process
          return row;
        },
      },
    },
    subset: {
      enabled: false,

      targets: [
        {
          // Should not even check the targets because enabled is false
          table: 'dummytable',
          rowLimit: 1
        }
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  const deleteRandomActor = async () => {
    try {
      await execQueryNext(
        `
        DELETE FROM "actor" WHERE actor_id = (SELECT actor_id FROM "actor" ORDER BY random() LIMIT 1)
      `,
        sourceConnectionString.toString()
      )
    } catch (e) {
      // noop since we a running a lot of parallel queries in an interval some errors can happen we dismiss them
    }
  }
  const deleteRandomFilm = async () => {
    try {
      await execQueryNext(
        `
        DELETE FROM "film" WHERE film_id = (SELECT film_id FROM "film" ORDER BY random() LIMIT 1)
      `,
        sourceConnectionString.toString()
      )
    } catch (e) {
      // noop since we a running a lot of parallel queries in an interval some errors can happen we dismiss them
    }
  }

  // Remove an actor and a film every 100 ms
  const capture_process = runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )
  async function sleep(ms: number) {
    return new Promise((resolve) => {
      setTimeout(resolve, ms)
    })
  }
  await sleep(500)
  const intervalRemoveActor = setInterval(deleteRandomActor, 10)
  const intervalRemoveFilm = setInterval(deleteRandomFilm, 10)
  await capture_process
  clearInterval(intervalRemoveActor)
  clearInterval(intervalRemoveFilm)

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
  const filmActorResults = await execQueryNext(
    `SELECT 1 FROM public.film_actor`,
    targetConnectionString.toString()
  )
  // Because film_actor delete in cascade we a film or a actor is deleted we should have less rows
  expect(filmActorResults.rowCount).toBeLessThan(5462)
  expect(filmActorResults.rowCount).toBeGreaterThan(10)
})

test.skip('subset capture and restore living data on videolet v3', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture('videolet.sql', sourceConnectionString.toString())

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    transform: {
      public: {
        actor: ({row}) => {
          for (let i = 0; i < 10000000; i += 1){} // To slow down the capture process
          return row;
        },
        film: ({row}) => {
          for (let i = 0; i < 10000000; i += 1){} // To slow down the capture process
          return row;
        },
        film_actor: ({row}) => {
          for (let i = 0; i < 1000000; i += 1){} // To slow down the capture process
          return row;
        },
      },
    },
    subset: {
      enabled: true,

      targets: [
        {
          table: 'public.film',
          percent: 100,
        }
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  const deleteRandomActor = async () => {
    try {
      await execQueryNext(
        `
        DELETE FROM "actor" WHERE actor_id = (SELECT actor_id FROM "actor" ORDER BY random() LIMIT 1)
      `,
        sourceConnectionString.toString()
      )
    } catch (e) {
      // noop since we a running a lot of parallel queries in an interval some errors can happen we dismiss them
    }
  }
  const deleteRandomFilm = async () => {
    try {
      await execQueryNext(
        `
        DELETE FROM "film" WHERE film_id = (SELECT film_id FROM "film" ORDER BY random() LIMIT 1)
      `,
        sourceConnectionString.toString()
      )
    } catch (e) {
      // noop since we a running a lot of parallel queries in an interval some errors can happen we dismiss them
    }
  }

  // Remove an actor and a film every 100 ms
  const capture_process = runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )
  async function sleep(ms: number) {
    return new Promise((resolve) => {
      setTimeout(resolve, ms)
    })
  }
  await sleep(500)
  const intervalRemoveActor = setInterval(deleteRandomActor, 10)
  const intervalRemoveFilm = setInterval(deleteRandomFilm, 10)
  await capture_process
  clearInterval(intervalRemoveActor)
  clearInterval(intervalRemoveFilm)

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
  const filmActorResults = await execQueryNext(
    `SELECT 1 FROM public.film_actor`,
    targetConnectionString.toString()
  )
  // Because film_actor delete in cascade we a film or a actor is deleted we should have less rows
  expect(filmActorResults.rowCount).toBeLessThan(5462)
  expect(filmActorResults.rowCount).toBeGreaterThan(10)
})
