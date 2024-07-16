import { PlanInputs, UserModels } from '~/generateOrm/plan/types.js'
import { SeedClientOptions, getSeedClient } from './pg.js'
import {
  DataModel,
  introspectionToDataModel,
} from '~/generateOrm/dataModel/dataModel.js'
import { Plan, PlanOptions } from '~/generateOrm/plan/plan.js'
import { createTestDb } from '~/testing.js'
import {
  ConnectionString,
  execQueryNext,
  introspectDatabaseV3,
  withDbClient,
} from '~/exports/api.js'
import { SeedClientBase } from '~/generateOrm/client.js'

describe('pg adapter', () => {
  type SnapletClientMethods = SeedClientBase &
    Record<
      string,
      (inputs: PlanInputs['inputs'], options?: PlanOptions) => Promise<Plan>
    >

  let connectionString: ConnectionString
  let dataModel: DataModel
  let userModels: UserModels
  const originalDbUrl = process.env.SNAPLET_TARGET_DATABASE_URL

  const createSeedClient = async (
    options?: SeedClientOptions
  ): Promise<SnapletClientMethods> => {
    const createSeedClient = getSeedClient(dataModel, userModels)
    const client = await createSeedClient(options)
    return client as unknown as SnapletClientMethods
  }

  const resetTestScenario = async (scenario: {
    schema: string
    userModels: UserModels
  }) => {
    connectionString = await createTestDb()
    await execQueryNext(scenario.schema, connectionString)

    process.env.SNAPLET_TARGET_DATABASE_URL = connectionString.toString()

    dataModel = introspectionToDataModel(
      await withDbClient(introspectDatabaseV3, {
        connString: connectionString.toString(),
      })
    )

    userModels = scenario.userModels
  }

  beforeEach(async () => {
    await resetTestScenario({
      schema: `
        CREATE TABLE "User" (
          "id" text not null
        );

        ALTER TABLE "User" ADD CONSTRAINT "User_pkey" PRIMARY KEY ("id");
      `,
      userModels: {
        User: {
          data: {
            id: ({ seed }) => seed,
          },
        },
      },
    })
  })

  afterEach(() => {
    process.env.SNAPLET_TARGET_DATABASE_URL = originalDbUrl
  })

  test('dryRun option', async () => {
    const logSpy = vi.spyOn(console, 'log')

    const client = await createSeedClient({
      dryRun: true,
    })

    await client.User((x) => x(2))

    expect(logSpy.mock.calls).toEqual([
      [
        `INSERT INTO public."User" (id) VALUES ('0/User/0/id'), ('0/User/1/id');`,
      ],
    ])
  })

  test('$resetDatabase()', async () => {
    const client = await createSeedClient()

    await execQueryNext('insert into "User" values (23)', connectionString)

    await client.$resetDatabase()

    expect(
      (await execQueryNext('select * from "User"', connectionString)).rowCount
    ).toEqual(0)
  })

  test('$resetDatabase() is a no-op for dry run', async () => {
    const client = await createSeedClient({
      dryRun: true,
    })

    await execQueryNext('insert into "User" values (23)', connectionString)

    await client.$resetDatabase()

    expect(
      (await execQueryNext('select * from "User"', connectionString)).rows
    ).toEqual([{ id: '23' }])
  })

  test('default client', async () => {
    const client = await createSeedClient()

    expect(
      (await execQueryNext('select * from "User"', connectionString)).rowCount
    ).toEqual(0)

    await client.User((x) => x(2))

    expect(
      (await execQueryNext('select * from "User"', connectionString)).rowCount
    ).toEqual(2)
  })

  test('$syncDatabase updates sequences', async () => {
    await resetTestScenario({
      schema: `
        CREATE TABLE "User" (
          "id" SERIAL PRIMARY KEY
        );
      `,
      userModels: {
        User: {
          data: {
            id: null,
          },
        },
      },
    })

    const client = await createSeedClient({
      dryRun: false,
    })

    await execQueryNext(
      'insert into "User" values (DEFAULT), (DEFAULT), (DEFAULT)',
      connectionString
    )

    const { rows: rowsBefore } = await execQueryNext(
      'select * from "User"',
      connectionString
    )
    expect(rowsBefore).toEqual([{ id: 1 }, { id: 2 }, { id: 3 }])

    await client.$syncDatabase()
    client.$reset()
    await client.User((x) => x(2))

    const { rows: rowsAfter } = await execQueryNext(
      'select * from "User"',
      connectionString
    )

    expect(rowsAfter).toEqual([
      { id: 1 },
      { id: 2 },
      { id: 3 },
      { id: 4 },
      { id: 5 },
    ])
  })
})
