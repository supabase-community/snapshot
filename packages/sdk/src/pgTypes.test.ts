import { fakeDbStructure } from './testing/index.js'
import { createColumnTypeLookup, getPgTypeArrayDimensions } from './pgTypes.js'

describe('createColumnTypeLookup', () => {
  it('same table name, different column', () => {
    const structure = fakeDbStructure()
    const correctTable = structure.tables[0]

    const decoyTable = {
      ...correctTable,
      schema: 'decoySchema',
      columns: correctTable.columns.map((column) => ({
        ...column,
        type: 'tztrange',
      })),
    }

    expect(correctTable.columns[0]).not.toEqual(decoyTable.columns[0])

    expect(
      createColumnTypeLookup(structure, correctTable.schema, correctTable.name)
    ).toMatchInlineSnapshot(`
      {
        "confirmed_at": "text",
        "email": "text",
        "id": "text",
        "name": "text",
      }
    `)
  })
})

describe('getPgTypeArrayDimensions', () => {
  it('returns 0 for non-array types', () => {
    expect(getPgTypeArrayDimensions('text')).toEqual(0)
  })

  it('returns the number of [] for array types', () => {
    expect(getPgTypeArrayDimensions('text[][][]')).toEqual(3)
  })
})
