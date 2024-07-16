import { execQueryNext, fixedEncodeURIComponent } from '@snaplet/sdk/cli'
import {
  createTestRole,
  getTestAccessToken,
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
  VIDEOLET_PROJECT_ID,
} from '../src/testing/index.js'
import fs from 'fs'
import fsExtra from 'fs-extra'
import { range } from 'lodash'
import { Client } from 'pg'

const escapeLiteral = Client.prototype.escapeLiteral

vi.setConfig({
  testTimeout: 120_000,
})

describe('Snaplet CLI', () => {
  test('snaplet auth setup', async () => {
    const paths = await createTestProjectDirV2()
    const accessToken = await getTestAccessToken(VIDEOLET_PROJECT_ID)
    await runSnapletCLI(['auth login', accessToken], {}, paths)

    const systemConfigContent = JSON.parse(
      fs.readFileSync(paths.system.config).toString()
    )
    expect(systemConfigContent).toEqual(
      expect.objectContaining({
        accessToken: accessToken,
      })
    )
  })

  test('should exit sucessfully with production build', async () => {
    const result = await runSnapletCLI(
      ['invalidcommand', VIDEOLET_PROJECT_ID],
      { NODE_ENV: 'production' }
    )
    expect(result.stderr).toContain('snaplet <command> <subcommand>')
  })

  test('should exit sucessfully on error with production build', async () => {
    await expect(
      runSnapletCLI(['snapshot capture --from-cloud'], {
        NODE_ENV: 'production',
      })
    ).rejects.toEqual(expect.objectContaining({ exitCode: 190 }))
  })

  test('capturing and restoring of auto-generated fields', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()
    const paths = await createTestProjectDirV2()

    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({})`
    await fsExtra.writeFile(paths.snapletConfig, configContent)
    await execQueryNext(
      `CREATE TABLE IF NOT EXISTS public.town
          (
              id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
              name character varying(150) COLLATE pg_catalog."default"
          )`,
      sourceConnectionString
    )

    await execQueryNext(
      `insert into public.town(name) values('Worcester');
           insert into public.town(name) values('Darling');
           insert into public.town(name) values('Saron');
           insert into public.town(name) values('Gouda');
           insert into public.town(name) values('Hermanus');
           insert into public.town(name) values('Hermon');
           insert into public.town(name) values('Malmesbury');
           insert into public.town(name) values('Tifton');`,
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
      "SELECT * FROM public.town WHERE name = 'Saron';",
      destinationConnectionString
    )

    expect(result.rows).toEqual([
      {
        id: '3',
        name: 'Saron',
      },
    ])
  })

  test('connection strings usage in `capture`: chars left unencoded when allowed by RFC 3986', async () => {
    const password = String.fromCharCode(...range(32, 129))
    const sourceConnectionString = await createTestDb()
    const testRoleConnectionString = await createTestRole(
      sourceConnectionString
    )
    const paths = await createTestProjectDirV2()
    await execQueryNext(
      `ALTER ROLE "${
        testRoleConnectionString.username
      }" PASSWORD ${escapeLiteral(password)}`,
      sourceConnectionString
    )

    const testRoleWithPassword = testRoleConnectionString.setPassword(
      encodeURIComponent(password)
    )

    const ssPath = createTestCapturePath()

    await expect(
      runSnapletCLI(
        ['snapshot', 'capture', ssPath.name],
        {
          SNAPLET_SOURCE_DATABASE_URL: testRoleWithPassword.toString(),
        },
        paths
      )
    ).resolves.toEqual(
      expect.objectContaining({
        exitCode: 0,
        stdout: expect.stringContaining('Capture complete'),
      })
    )
  })

  test('connection strings usage in `capture`: all chars encoded', async () => {
    const password = String.fromCharCode(...range(32, 129))
    const sourceConnectionString = await createTestDb()
    const testRoleConnectionString = await createTestRole(
      sourceConnectionString
    )
    const paths = await createTestProjectDirV2()
    await execQueryNext(
      `ALTER ROLE "${
        testRoleConnectionString.username
      }" PASSWORD ${escapeLiteral(password)}`,
      sourceConnectionString
    )

    const testRoleWithPassword = testRoleConnectionString.setPassword(
      fixedEncodeURIComponent(password)
    )

    const ssPath = createTestCapturePath()

    await expect(
      runSnapletCLI(
        ['snapshot', 'capture', ssPath.name],
        {
          SNAPLET_SOURCE_DATABASE_URL: testRoleWithPassword.toString(),
        },
        paths
      )
    ).resolves.toEqual(
      expect.objectContaining({
        exitCode: 0,
        stdout: expect.stringContaining('Capture complete'),
      })
    )
  })

  test('--transform-mode=strict: per-column transform errors', async () => {
    const connectionString = await createTestDb()

    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      transform: {
        public: {
          Foo: () => ({
          })
        },
        bar: {
          Baz: () => ({
            d: "garply",
          }),
          Quux: () => ({
            f: () => {
              throw new Error("You don't choose the soy sauce, the soy sauce chooses you")
            }
          })
        },
        xxyyxx: {}
      },
    })`
    await fsExtra.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `CREATE TABLE "Foo" ("a" TEXT, "b" TEXT)`,
      connectionString
    )

    await execQueryNext('CREATE SCHEMA "bar"', connectionString)
    await execQueryNext('CREATE SCHEMA "waldo"', connectionString)
    await execQueryNext('CREATE SCHEMA "xxyyxx"', connectionString)

    await execQueryNext(
      `CREATE TABLE "bar"."Baz" ("c" TEXT, "d" TEXT)`,
      connectionString
    )

    await execQueryNext(
      `CREATE TABLE "bar"."Quux" ("e" TEXT, "f" TEXT)`,
      connectionString
    )

    await execQueryNext(
      'CREATE TABLE "waldo"."Laser" ("blazer" TEXT)',
      connectionString
    )

    await execQueryNext(
      'CREATE TABLE "xxyyxx"."Winrar" ("Rar" TEXT)',
      connectionString
    )

    await execQueryNext(`INSERT INTO "Foo" VALUES ('a', 'b')`, connectionString)

    await execQueryNext(
      `INSERT INTO "bar"."Baz" VALUES ('c', 'd')`,
      connectionString
    )
    await execQueryNext(
      `INSERT INTO "bar"."Quux" VALUES ('e', 'f')`,
      connectionString
    )
    await execQueryNext(
      `INSERT INTO "waldo"."Laser" VALUES ('g')`,
      connectionString
    )

    await execQueryNext(
      `INSERT INTO "xxyyxx"."Winrar" VALUES ('h')`,
      connectionString
    )

    const result = await runSnapletCLI(
      ['snapshot capture --transform-mode=strict'],
      {
        SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
        SNAPLET_TARGET_DATABASE_URL: connectionString.toString(),
      },
      paths
    ).catch((e) => e)

    // Check for a specific exit code
    expect(result.exitCode).toBe(114)

    // Check for substring in stderr
    expect(result.stderr).toMatch(
      /You don't choose the soy sauce, the soy sauce chooses you/
    )
    expect(result.stderr).toMatch(/\["bar"."Quux"\]/)
    expect(result.stderr).toMatch(/e,f/)
  })
})
