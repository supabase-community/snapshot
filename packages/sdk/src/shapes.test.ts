import { findShape } from './shapes.js'

describe('findShape', () => {
  test('finds the closest shape', () => {
    expect(findShape('first_name', 'string')).toMatchInlineSnapshot(`
      {
        "closest": "first name",
        "distance": 1,
        "shape": "FIRST_NAME",
      }
    `)
  })

  test('returns null for matches that could not be found', () => {
    expect(findShape('walzaroundtheroom', 'string')).toBe(null)
  })

  test('false positive matches', () => {
    expect(findShape('logs', 'string')?.shape).toEqual('LOGS')
    expect(findShape('status', 'string')?.shape).toEqual('STATUS')
  })
})
