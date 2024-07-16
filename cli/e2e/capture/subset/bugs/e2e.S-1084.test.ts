import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
} from '../../../../src/testing/index.js'
import fs from 'fs'
import fsExtra from 'fs-extra'
import path from 'path'

import { splitSchema } from '../../../../src/commands/snapshot/actions/restore/lib/pgSchemaTools.js'

const FIXTURES_DIR = path.resolve(__dirname, '../../../../__fixtures__')

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

test(
  'S-801 MRE user error test case reproduction',
  async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()
    await loadDbDumpFixture(
      'bugs/S-1084.sql',
      sourceConnectionString.toString()
    )

    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat } from '@snaplet/copycat'
    import { defineConfig } from 'snaplet'

    export default defineConfig({
      subset: {
        enabled: true,
         // the latest version
        targets: [
          {
            table: "public.team",
            percent: 20
          },
          {
            table: "public.migrations",
            percent: 20
          }
        ],
        keepDisconnectedTables: false
      },
    })`
    await fsExtra.writeFile(paths.snapletConfig, configContent)
    const ssPath = createTestCapturePath()

    await execQueryNext(
      [
        `INSERT INTO public.team (id, name, "stripeId", "trialEnd", "subscriptionId", "createdAt", "updatedAt", "currentPeriodStart", "currentPeriodEnd", "hasOnboarded", "subscriptionStatus", address, "subscriptionCreated", product, period, "productAddons", color, "logoPath", "hasStrategicLandBeta", "autoTopupTitleCredit", "firstTrialEnd", "customColours", "hubspotCustomerUrl", "salesDevelopmentRepresentative", "businessDevelopmentManager", "customerSuccessManager")
        VALUES
        ('fe393b34-4486-5409-93a7-eabf3acf845f', 'Team 1', 'stripe_id_1', '2022-01-01 00:00:00', 'sub_id_1', '2021-10-01 00:00:00', '2021-10-01 00:00:00', '2021-10-01 00:00:00', '2021-11-01 00:00:00', true, 'active', '{"street": "123 Main St", "city": "Anytown", "state": "CA", "zip": "12345"}', '2021-10-01 00:00:00', '{"name": "Product 1", "price": 9.99}', 'monthly', '[]', 'blue', '/path/to/logo1.png', false, 10, '2022-01-01 00:00:00', '{}', 'https://www.hubspot.com/customers/team1', 'John Doe', 'Jane Smith', 'Bob Johnson'),
        ('fe393b34-4486-5409-93a7-eabf3acf844f', 'Team 2', 'stripe_id_2', '2022-02-01 00:00:00', 'sub_id_2', '2021-10-02 00:00:00', '2021-10-02 00:00:00', '2021-10-02 00:00:00', '2021-11-02 00:00:00', true, 'active', '{"street": "456 Elm St", "city": "Othertown", "state": "NY", "zip": "67890"}', '2021-10-02 00:00:00', '{"name": "Product 2", "price": 19.99}', 'monthly', '[]', 'red', '/path/to/logo2.png', false, 20, '2022-02-01 00:00:00', '{}', 'https://www.hubspot.com/customers/team2', 'Alice Johnson', 'Bob Smith', 'Jane Doe'),
        ('fe393b34-4486-5409-93a7-eabf3acf843f', 'Team 3', 'stripe_id_3', '2022-03-01 00:00:00', 'sub_id_3', '2021-10-03 00:00:00', '2021-10-03 00:00:00', '2021-10-03 00:00:00', '2021-11-03 00:00:00', true, 'active', '{"street": "789 Oak St", "city": "Somewhere", "state": "TX", "zip": "54321"}', '2021-10-03 00:00:00', '{"name": "Product 3", "price": 29.99}', 'monthly', '[]', 'green', '/path/to/logo3.png', false, 30, '2022-03-01 00:00:00', '{}', 'https://www.hubspot.com/customers/team3', 'Bob Doe', 'Alice Smith', 'John Johnson')`,
        "INSERT INTO supabase_functions.migrations (version) VALUES ('1'), ('2'), ('3')",
        "INSERT INTO public.migrations (id, timestamp, name) VALUES (1, 1610035200000, '1'), (2, 1610035200000, '2'), (3, 1610035200000, '3')",
        "INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES (1, '1', '1', now()), (2, '2', '2', now()), (3, '3', '3', now())",
      ].join('\n;'),
      sourceConnectionString.toString()
    )
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
  },
  10 * 60 * 1000
)
