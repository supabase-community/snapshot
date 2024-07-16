import { parse } from 'csv-parse/sync'
import { stringify } from 'csv-stringify/sync'
import { csvParseOptions, csvStringifyOptions } from './pgCopyTable.js'

describe('pgCopyTable', () => {
  test('csv-parse and csv-serialize options are working as expected against PostgreSQL csv', () => {
    // arrange
    const csv = `id,content
1,John
2,
3,""
`
    // act
    const parsed = parse(csv, csvParseOptions)
    const serialized = stringify(parsed, csvStringifyOptions)
    // assert
    expect(parsed).toEqual([
      {
        content: 'John',
        id: '1',
      },
      {
        content: null,
        id: '2',
      },
      {
        content: '',
        id: '3',
      },
    ])
    expect(serialized).toEqual(csv)
  })
})
