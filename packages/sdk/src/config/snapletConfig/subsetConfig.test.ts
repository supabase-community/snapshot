import { parseSubsetConfig } from './subsetConfig.js'

describe('subset config parsing - version 2', () => {
  it('version 2: happy case', () => {
    const exit = vi
      .spyOn(process, 'exit')
      // @ts-expect-error
      .mockImplementation((code) => code)

    const res = parseSubsetConfig({
      enabled: true,
      version: '3',
      targets: [
        {
          table: 'User',
          percent: 100,
        },
        {
          table: 'User',
          rowLimit: 99,
        },
      ],
      keepDisconnectedTables: false,
    })
    expect(exit).not.toHaveBeenCalled()
    expect(res).toBeDefined()
    exit.mockRestore()
  })

  it('target with rowLimit & percentage fails', () => {
    expect(() =>
      parseSubsetConfig({
        enabled: true,
        version: '3',
        targets: [
          {
            table: 'User',
            percent: 100,
          },

          {
            table: 'User',
            rowLimit: 99,
            percent: 100,
          },
        ],

        keepDisconnectedTables: false,
      })
    ).toThrowErrorMatchingInlineSnapshot(`
      "Could not parse subset config: [
        {
          \\"code\\": \\"custom\\",
          \\"message\\": \\"Either \`rowLimit\` or \`percentage\` required. Both supplied.\\",
          \\"path\\": [
            \\"targets\\",
            1
          ]
        }
      ]"
    `)
  })
  it('version 1: happy case', () => {
    const exit = vi
      .spyOn(process, 'exit')
      // @ts-expect-error
      .mockImplementation((code) => code)

    const res = parseSubsetConfig({
      enabled: true,
      version: '1',
      targets: [
        {
          table: 'User',
          percent: 100,
          where: 'id = 1',
        },
        {
          table: 'User',
          rowLimit: 99,
        },
      ],
      keepDisconnectedTables: false,
    })
    expect(exit).not.toHaveBeenCalled()
    expect(res).toBeDefined()
    exit.mockRestore()
  })

  it('version 1:  Can not only have a where clause in target config', () => {
    expect(() =>
      parseSubsetConfig({
        enabled: true,
        targets: [
          {
            table: 'User',
            percent: 100,
          },

          {
            table: 'User',
            where: 'id = 1',
          },
        ],

        keepDisconnectedTables: false,
      })
    ).toThrowErrorMatchingInlineSnapshot(`
      "Could not parse subset config: [
        {
          \\"code\\": \\"custom\\",
          \\"message\\": \\"Invalid subset configuration - Every target requires either a rowLimit or percent.\\",
          \\"path\\": []
        }
      ]"
    `)
  })

  it('version 2: Can only have a where clause in target config', () => {
    const exit = vi
      .spyOn(process, 'exit')
      // @ts-expect-error
      .mockImplementation((code) => code)

    const res = parseSubsetConfig({
      enabled: true,
      version: '3',
      targets: [
        {
          table: 'User',
          percent: 100,
        },
        {
          table: 'User',
          where: 'id = 1',
        },
      ],
      keepDisconnectedTables: false,
    })
    expect(exit).not.toHaveBeenCalled()
    expect(res).toBeDefined()
    exit.mockRestore()
  })
})
