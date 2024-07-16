import { Hosts } from './hosts.js'

test('host can return `undefined` for `getLatestSnapshot`', async () => {
  const local = {
    getLatestSnapshot: async () => {
      return undefined
    },
  }

  const cloud = {
    getLatestSnapshot: async () => {
      return {
        summary: {
          date: new Date(),
          name: 'test',
        },
      }
    },
  }
  // @ts-expect-error
  const h = new Hosts({ hosts: [local, cloud] })
  const x = await h.getLatestSnapshot()
  expect(x?.summary?.name).toEqual('test')
})

test('snapshots with same id are merged', async () => {
  const local = {
    getAllSnapshots: async () => {
      return [
        {
          summary: {
            snapshotId: '1',
            date: new Date(),
            name: 'test',
          },
        },
      ]
    },
  }

  const cloud = {
    getAllSnapshots: async () => {
      return [
        {
          summary: {
            snapshotId: '1',
            date: new Date(),
            name: 'test',
          },
        },
      ]
    },
  }
  // @ts-expect-error
  const h = new Hosts({ hosts: [local, cloud] })
  const x = await h.getAllSnapshots()
  expect(x.length).toEqual(1)
})

test('snapshots without snapshot ids are not merged', async () => {
  const local = {
    getAllSnapshots: async () => {
      return [
        {
          summary: {
            date: new Date(),
            name: 'test 1',
          },
        },
        {
          summary: {
            date: new Date(),
            name: 'test 2',
          },
        },
        {
          summary: {
            snapshotId: '3',
            date: new Date(),
            name: 'test 3',
          },
        },
      ]
    },
  }

  const cloud = {
    getAllSnapshots: async () => {
      return [
        {
          summary: {
            snapshotId: '3',
            date: new Date(),
            name: 'test 3',
          },
        },
      ]
    },
  }
  // @ts-expect-error
  const h = new Hosts({ hosts: [local, cloud] })
  const x = await h.getAllSnapshots()
  expect(x.length).toEqual(3)
})
