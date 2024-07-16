import { fakeDbStructure } from '~/testing.js'
import { fillRows } from './fillRows.js'

describe('fillRows', () => {
  it('uses user values if they have been given', async () => {
    const result = await fillRows({
      data: [
        {
          line: 0,
          raw: {
            foo: 'bar',
          },
          parsed: {
            foo: 'bar',
          },
          replacement: {
            foo: 'baz',
          },
        },
      ],
      mode: 'unsafe',
      schemaName: 'quux',
      tableName: 'corge',
      structure: fakeDbStructure(),
    })

    expect(result).toEqual([
      {
        line: 0,
        raw: {
          foo: 'bar',
        },
        parsed: {
          foo: 'bar',
        },
        replacement: {
          foo: 'baz',
        },
        filled: {
          foo: 'baz',
        },
        statuses: {
          foo: 'replaced',
        },
      },
    ])
  })

  it('uses fallback based on the mode if no user value has been given', async () => {
    const result = await fillRows({
      data: [
        {
          line: 0,
          raw: {
            foo: 'bar',
          },
          parsed: {
            foo: 'bar',
          },
          replacement: {},
        },
      ],
      mode: 'unsafe',
      schemaName: 'quux',
      tableName: 'corge',
      structure: fakeDbStructure(),
    })

    expect(result).toEqual([
      {
        line: 0,
        raw: {
          foo: 'bar',
        },
        parsed: {
          foo: 'bar',
        },
        replacement: {},
        filled: {
          foo: 'bar',
        },
        statuses: {
          foo: 'original',
        },
      },
    ])
  })

  it('auto fills', async () => {
    const result = await fillRows({
      data: [
        {
          line: 0,
          raw: {
            name: 'foo',
          },
          parsed: {
            name: 'foo',
          },
          replacement: {},
        },
      ],
      mode: 'auto',
      schemaName: 'public',
      tableName: 'test_customer',
      structure: fakeDbStructure(),
    })

    expect(result).toEqual([
      {
        line: 0,
        raw: {
          name: 'foo',
        },
        parsed: {
          name: 'foo',
        },
        replacement: {},
        filled: {
          name: expect.any(String),
        },
        statuses: {
          name: 'filled',
        },
      },
    ])
  })
})
