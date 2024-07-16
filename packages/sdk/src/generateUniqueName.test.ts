import { generateUniqueName } from './generateUniqueName.js'

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))

describe('generateUniqueName', () => {
  test('should not collide once over 1000 runs', async () => {
    const names = new Set<string>()
    for (let i = 0; i < 1000; i++) {
      const name = generateUniqueName('ss')
      expect(names.has(name)).toBe(false)
      names.add(name)
      // We need to wait for a bit to make sure the seed is different
      await sleep(2)
    }
  })
  // Tested locally, but slowdown too much the tests to be ran everytime
  test.skip('should not collide once over 10k runs', async () => {
    const names = new Set<string>()
    for (let i = 0; i < 10000; i++) {
      const name = generateUniqueName('ss')
      if (names.has(name)) {
        expect(i).toBe(5000)
      }
      expect(names.has(name)).toBe(false)
      names.add(name)
      // We need to wait for a bit to make sure the seed is different
      await sleep(2)
    }
  })
})
