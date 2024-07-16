import path from 'path'

import { LocalSnapshotHost } from './localSnapshotHost.js'

const storagePath = path.resolve(
  __dirname,
  '../../../__fixtures__/.snaplet/snapshots'
)

test('correctly finds the latest snapshots', async () => {
  const l = new LocalSnapshotHost({ storagePath })
  const x = await l.getLatestSnapshot()
  expect(x.summary.name).toEqual('pixel-bypass')
})

test('gets all the snapshots', async () => {
  const l = new LocalSnapshotHost({ storagePath })
  const x = await l.getAllSnapshots()
  expect(x.length).toEqual(2)
})

describe('filter snapshots', () => {
  test('gets snapshot by unique name', async () => {
    const l = new LocalSnapshotHost({ storagePath })
    const s = await l.filterSnapshots({ startsWith: 'ella' })
    expect(s?.[0]?.summary?.name).toEqual('ella-mountains-system')
  })

  test('gets snapshot by tag', async () => {
    const l = new LocalSnapshotHost({ storagePath })
    const s = await l.filterSnapshots({ tags: ['cat'] })
    expect(s?.[0]?.summary?.name).toEqual('pixel-bypass')
  })

  test('gets snapshot by unique name and tag', async () => {
    const l = new LocalSnapshotHost({ storagePath })
    const s = await l.filterSnapshots({ startsWith: 'ella', tags: ['dog'] })
    expect(s?.[0]?.summary?.name).toEqual('ella-mountains-system')
  })
})
