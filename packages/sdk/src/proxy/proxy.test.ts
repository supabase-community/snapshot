import { createTestDb } from '~/testing.js'
import { createProxy } from './proxy.js'
import { AddressInfo } from 'net'
import { execQueryNext } from '~/db/client.js'

describe('createProxy', () => {
  let kills: (() => Promise<void>)[] = []

  afterEach(async () => {
    for (const kill of kills) {
      await kill()
    }

    kills = []
  })

  test('it proxies local connections', async () => {
    const targetString = await createTestDb()

    const { server, kill } = createProxy(targetString)
    kills.push(kill)

    await new Promise((resolve) => server.listen(resolve))
    const port = (server.address() as AddressInfo).port

    // context(justinvdm, 3 October 2023): `snaplet` is an
    // alias to the underlying target db name
    const sourceString = targetString.setPort(port).setDatabase('snaplet')

    await execQueryNext(
      `CREATE TABLE "Tmp" (
         value int
      )`,
      targetString.toString()
    )

    await execQueryNext(
      `INSERT INTO "Tmp" VALUES (
        23
      )`,
      targetString.toString()
    )

    const result = await execQueryNext('select * from "Tmp"', sourceString)

    expect(result.rows).toEqual([{ value: 23 }])
  })

  test('it uses the given db name', async () => {
    const targetString = await createTestDb()
    const db1TargetString = await createTestDb()
    const db2TargetString = await createTestDb()

    await execQueryNext(
      `CREATE TABLE "Tmp" (value text)`,
      db1TargetString.toString()
    )
    await execQueryNext(
      `CREATE TABLE "Tmp" (value text)`,
      db2TargetString.toString()
    )

    await execQueryNext(
      `INSERT INTO "Tmp" VALUES ('db1')`,
      db1TargetString.toString()
    )
    await execQueryNext(
      `INSERT INTO "Tmp" VALUES ('db2')`,
      db2TargetString.toString()
    )

    const { server, kill } = createProxy(targetString)
    kills.push(kill)

    await new Promise((resolve) => server.listen(resolve))
    const port = (server.address() as AddressInfo).port

    const db1String = targetString
      .setPort(port)
      .setDatabase(db1TargetString.database)

    const db2String = targetString
      .setPort(port)
      .setDatabase(db2TargetString.database)

    const { rows: db1Rows } = await execQueryNext(
      `SELECT * from "Tmp"`,
      db1String.toString()
    )
    const { rows: db2Rows } = await execQueryNext(
      `SELECT * from "Tmp"`,
      db2String.toString()
    )

    expect(db1Rows).toEqual([{ value: 'db1' }])
    expect(db2Rows).toEqual([{ value: 'db2' }])
  })
})
