import { execQueryNext } from '@snaplet/sdk/cli'
import { parse as csvParse } from 'csv-parse/sync'
import fsExtra from 'fs-extra'
import path from 'path'

import {
  getTestAccessToken,
  createTestDb,
  createTestCapturePath,
  runSnapletCLI,
  VIDEOLET_PROJECT_ID,
  createTestProjectDirV2,
} from '../../src/testing/index.js'

vi.setConfig({
  testTimeout: 60_000,
})

describe(
  'Snaplet CLI',
  () => {
    describe('snapshot capture', () => {
      test('snaplet config push with bad transform.ts', async () => {
        const envOverride = {
          SNAPLET_PROJECT_ID: VIDEOLET_PROJECT_ID, // VideoLet, Inc.
          SNAPLET_ACCESS_TOKEN: await getTestAccessToken(VIDEOLET_PROJECT_ID),
        }
        const paths = await createTestProjectDirV2()

        await fsExtra.writeFile(
          paths.snapletConfig,
          `export const meaningOfLife = 42`
        )

        await expect(
          runSnapletCLI(
            ['config', 'push'],
            {
              ...envOverride,
            },
            paths
          )
        ).rejects.toEqual(
          expect.objectContaining({
            stdout: expect.stringContaining(`Failed to parse config file`),
            failed: true,
            exitCode: 118,
          })
        )
      })
      // context(peterp, 06 July 2023): Skipped this test because it does not _really_
      // make sense to me. The user pushes an empty configuration, and then expects a
      // non-empty configuration to be returned?
      test.skip('snaplet config push with empty transform.ts', async () => {
        const envOverride = {
          SNAPLET_PROJECT_ID: VIDEOLET_PROJECT_ID, // VideoLet, Inc.
          SNAPLET_ACCESS_TOKEN: await getTestAccessToken(VIDEOLET_PROJECT_ID),
        }
        const paths = await createTestProjectDirV2()
        const cwd = path.resolve(paths.base, '../')

        const run = async () => {
          await fsExtra.writeFile(
            paths.snapletConfig,
            `

          `
          )

          await runSnapletCLI(['config', 'push'], {
            SNAPLET_CWD: cwd,
            ...envOverride,
          })

          await runSnapletCLI(['config', 'pull'], {
            SNAPLET_CWD: cwd,
            ...envOverride,
          })

          return await fsExtra.readFile(paths.snapletConfig, 'utf-8')
        }

        const transformFile = await run()

        expect(transformFile).toMatchInlineSnapshot(
          `"export const transform = () => ({})"`
        )
      })
      test('--environment=local with transform errors', async () => {
        const paths = await createTestProjectDirV2()

        const connectionString = (await createTestDb()).toString()

        await execQueryNext(
          `CREATE TABLE "User" ("name" TEXT, "email" TEXT)`,
          connectionString
        )

        await execQueryNext(
          `INSERT INTO "User" VALUES ('Skunkin Drublic', 'skunkin@drublic.com')`,
          connectionString
        )

        await execQueryNext('VACUUM', connectionString)

        // Pretend that the user has run "snaplet setup"
        await fsExtra.mkdirp(paths.base!)
        const ssPath = createTestCapturePath()
        await fsExtra.writeFile(
          paths.snapletConfig!,
          `module.exports = {
            transform: {
              public: {
                User: ({ row }) => {
                  throw new Error('o_O')
                }
              }
            }
          }`
        )

        await expect(
          runSnapletCLI(
            ['snapshot capture', ssPath.name],
            {
              SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
            },
            paths
          )
        ).rejects.toEqual(
          expect.objectContaining({
            stderr: expect.stringContaining('o_O'),
          })
        )
      })

      test('transform.ts', async () => {
        const connectionString = await createTestDb()

        const paths = await createTestProjectDirV2()

        await fsExtra.writeFile(
          paths.snapletConfig,
          `module.exports = {
            transform: {
              public: {
                User: ({ row }) => ({
                  email: 'the-kiffest-' + row.email
                })
              }
            }
          }`
        )

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
          await fsExtra.readFile(
            path.join(ssPath.name, 'tables', 'public.User.csv')
          ),
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
    })
  },
  { timeout: 10 * 60 * 1000 }
)
