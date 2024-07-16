import path from 'path'

import { AbsPathSnapshotHost } from './absPathSnapshotHost.js'

const storagePath = path.resolve(
  __dirname,
  '../../../__fixtures__/.snaplet/snapshots'
)

describe('find snapshots', () => {
  test('gets snapshot by path', async () => {
    const l = new AbsPathSnapshotHost()
    const s = await l.filterSnapshots({
      startsWith: path.join(storagePath, '1659946195116-pixel-bypass'),
    })
    expect(s?.[0]?.summary?.name).toEqual('pixel-bypass')
  })
})
