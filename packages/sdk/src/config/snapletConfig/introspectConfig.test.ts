import { parseIntrospectConfig } from './introspectConfig.js'

describe('introspect config parsing', () => {
  it('happy case', () => {
    const exit = vi
      .spyOn(process, 'exit')
      // @ts-expect-error
      .mockImplementation((code) => code)

    const res = parseIntrospectConfig({
      virtualForeignKeys: [
        {
          fkTable: 'Table1',
          targetTable: 'Table2',
          keys: [{ fkColumn: 'column1', targetColumn: 'column2' }],
        },
        // Test with composite virtual key
        {
          fkTable: 'Table1',
          targetTable: 'Table2',
          keys: [
            { fkColumn: 'column1', targetColumn: 'column2' },
            { fkColumn: 'column3', targetColumn: 'column4' },
          ],
        },
      ],
    })
    expect(exit).not.toHaveBeenCalled()
    expect(res).toBeDefined()
    exit.mockRestore()
  })
})
