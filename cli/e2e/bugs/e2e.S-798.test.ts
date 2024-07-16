import { execQueryNext } from '@snaplet/sdk/cli'

import {
  createTestDb,
  createTestProjectDirV2,
  runSnapletCLI,
} from '../../src/testing/index.js'
import fsExtra from 'fs-extra'
import { range } from 'lodash'

test(
  '--transform-mode=strict on large db',
  async () => {
    const connectionString = await createTestDb()

    const paths = await createTestProjectDirV2()
    const configContent = ``
    await fsExtra.writeFile(paths.snapletConfig, configContent)
    // context(justinvdm, 13 April 2023): If our `COPY ... TO` streams are not
    // tearing down correctly, the capture will hang indefinitely. Interestingly though,
    // at a lower table counts (e.g. 6), the queries sometimes do not hang
    // (they take around 6 seconds to complete when they do),
    // then sometimes seem to hang indefinitely.
    for (const i of range(10)) {
      await execQueryNext(
        `CREATE TABLE "T${i}" (
        "a" TEXT,
        "b" TEXT,
        "c" TEXT,
        "d" TEXT,
        "e" TEXT,
        "f" TEXT
      )`,
        connectionString
      )

      for (const j of range(2000)) {
        await execQueryNext(
          `INSERT INTO "T${i}" VALUES ('${j}','${j}','${j}','${j}','${j}','${j}')`,
          connectionString
        )
      }
    }
    await expect(
      runSnapletCLI(['snapshot capture --transform-mode=strict'], {
        SNAPLET_SOURCE_DATABASE_URL: connectionString.toString(),
      })
    ).rejects.toEqual(
      expect.objectContaining({
        stderr: expect.stringContaining(`* Schemas: "public"`),
      })
    )
  },
  // If the test take more than 60 seconds, it's probably hanging when it shouldn't be.
  60 * 1000
)
