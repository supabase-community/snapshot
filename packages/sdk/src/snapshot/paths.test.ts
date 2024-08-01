import { faker } from '@snaplet/copycat'

import { getSnapshotFilePaths, generateSnapshotBasePath } from './paths.js'

test('getSnapshotFilePaths', () => {
  expect(getSnapshotFilePaths('/tmp/x')).toMatchInlineSnapshot(`
    {
      "base": "/tmp/x",
      "config": "/tmp/x/snaplet.config.ts",
      "restoreLog": "/tmp/x/restore.log",
      "schemas": "/tmp/x/schemas.sql",
      "structure": "/tmp/x/structure.json",
      "summary": "/tmp/x/summary.json",
      "tables": "/tmp/x/tables",
    }
  `)
})

test.skip('it generates a valid snapshot filename', async () => {
  const date = new Date('2022-08-15T20:09Z')
  faker.seed(1983)
  const name = faker.hacker.noun() + '-' + faker.hacker.verb()

  const x1 = generateSnapshotBasePath({ date, name })
  expect(
    x1.endsWith('.snaplet/snapshots/1660594140000-microchip-hack')
  ).toBeTruthy()

  const x2 = generateSnapshotBasePath({ date, name })
  expect(x2.endsWith('1660594140000-microchip-hack')).toBeTruthy()
})
