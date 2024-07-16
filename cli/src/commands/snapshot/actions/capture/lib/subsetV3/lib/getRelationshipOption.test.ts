import { getRelationshipOption } from './getRelationshipOption.js'

describe('getRelationshipOption', () => {
  it('should return the direct value when cascadingOptions is a primitive', () => {
    expect(
      getRelationshipOption({
        cascadingOptions: 10,
        defaultValue: undefined,
        relations: [
          {
            destinationTableId: 'table1',
            relationId: 'relation1',
            sourceTableId: 'table2',
          },
        ],
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation1',
          sourceTableId: 'table2',
        },
      })
    ).toBe(10)

    expect(
      getRelationshipOption({
        cascadingOptions: true,
        defaultValue: undefined,
        relations: [
          {
            destinationTableId: 'table1',
            relationId: 'relation1',
            sourceTableId: 'table2',
          },
        ],
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation1',
          sourceTableId: 'table2',
        },
      })
    ).toBe(true)

    expect(
      getRelationshipOption({
        cascadingOptions: undefined,
        defaultValue: undefined,
        relations: [
          {
            destinationTableId: 'table1',
            relationId: 'relation1',
            sourceTableId: 'table2',
          },
        ],
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation1',
          sourceTableId: 'table2',
        },
      })
    ).toBe(undefined)
  })

  it('should return the correct value considering $default and specific keys', () => {
    const options = {
      $default: 10,
      table1: {
        $default: 20,
        relation1: 30,
      },
    }
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations: [
          {
            destinationTableId: 'table1',
            relationId: 'relation1',
            sourceTableId: 'table2',
          },
        ],
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation1',
          sourceTableId: 'table2',
        },
      })
    ).toBe(30)

    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations: [
          {
            destinationTableId: 'table1',
            relationId: 'relation2',
            sourceTableId: 'table2',
          },
        ],
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation2',
          sourceTableId: 'table2',
        },
      })
    ).toBe(20)

    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations: [
          {
            destinationTableId: 'table2',
            relationId: 'relation2',
            sourceTableId: 'table3',
          },
        ],
        relation: {
          destinationTableId: 'table2',
          relationId: 'relation2',
          sourceTableId: 'table3',
        },
      })
    ).toBe(10)
  })

  it('should return the correct value considering $default and specific keys with false boolean', () => {
    const options = {
      $default: true,
      table1: {
        $default: true,
        relation1: false,
      },
    }
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: true,
        relations: [
          {
            destinationTableId: 'table1',
            relationId: 'relation1',
            sourceTableId: 'table2',
          },
        ],
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation1',
          sourceTableId: 'table2',
        },
      })
    ).toBe(false)

    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: true,
        relations: [
          {
            destinationTableId: 'table1',
            relationId: 'relation2',
            sourceTableId: 'table2',
          },
        ],
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation2',
          sourceTableId: 'table2',
        },
      })
    ).toBe(true)

    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: true,
        relations: [
          {
            destinationTableId: 'table2',
            relationId: 'relation2',
            sourceTableId: 'table3',
          },
        ],
        relation: {
          destinationTableId: 'table2',
          relationId: 'relation2',
          sourceTableId: 'table3',
        },
      })
    ).toBe(true)

    expect(
      getRelationshipOption({
        cascadingOptions: { $default: false },
        defaultValue: true,
        relations: [
          {
            destinationTableId: 'table2',
            relationId: 'relation2',
            sourceTableId: 'table3',
          },
        ],
        relation: {
          destinationTableId: 'table2',
          relationId: 'relation2',
          sourceTableId: 'table3',
        },
      })
    ).toBe(false)
  })

  it('should return the correct value considering $default and specific keys 0 number', () => {
    const options = {
      $default: 10,
      table1: {
        $default: 20,
        relation1: 0,
      },
    }
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations: [
          {
            destinationTableId: 'table1',
            relationId: 'relation1',
            sourceTableId: 'table2',
          },
        ],
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation1',
          sourceTableId: 'table2',
        },
      })
    ).toBe(0)

    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations: [
          {
            destinationTableId: 'table1',
            relationId: 'relation2',
            sourceTableId: 'table2',
          },
        ],
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation2',
          sourceTableId: 'table2',
        },
      })
    ).toBe(20)

    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations: [
          {
            destinationTableId: 'table2',
            relationId: 'relation2',
            sourceTableId: 'table3',
          },
        ],
        relation: {
          destinationTableId: 'table2',
          relationId: 'relation2',
          sourceTableId: 'table3',
        },
      })
    ).toBe(10)

    expect(
      getRelationshipOption({
        cascadingOptions: { $default: 0 },
        defaultValue: 10,
        relations: [
          {
            destinationTableId: 'table2',
            relationId: 'relation2',
            sourceTableId: 'table3',
          },
        ],
        relation: {
          destinationTableId: 'table2',
          relationId: 'relation2',
          sourceTableId: 'table3',
        },
      })
    ).toBe(0)
  })

  it('should return the default value when no matching keys or $default are found', () => {
    const options = {
      table1: {
        relation1: 30,
      },
    }
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations: [
          {
            destinationTableId: 'table2',
            relationId: 'relation2',
            sourceTableId: 'table3',
          },
        ],
        relation: {
          destinationTableId: 'table2',
          relationId: 'relation2',
          sourceTableId: 'table3',
        },
      })
    ).toBe(5)
  })

  it('should return set default for all relations pointing to destination table', () => {
    const options = {
      // For table1
      table1: {
        // We set a default for all relations pointing to table2
        table2: 30,
      },
    }
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations: [
          {
            destinationTableId: 'table1',
            relationId: 'relation1',
            sourceTableId: 'table2',
          },
          {
            destinationTableId: 'table1',
            relationId: 'relation2',
            sourceTableId: 'table2',
          },
          {
            destinationTableId: 'table1',
            relationId: 'relation3',
            sourceTableId: 'table2',
          },
        ],
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation1',
          sourceTableId: 'table2',
        },
      })
    ).toBe(30)
  })
  it('should return set default for all relations pointing to destination table, with relation defined value taking over', () => {
    const options = {
      // For table1
      table1: {
        // We set a default for all relations pointing to table2
        table2: 30,
        // We set a specific value for relation1
        relation1: 20,
      },
    }
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations: [
          {
            destinationTableId: 'table1',
            relationId: 'relation1',
            sourceTableId: 'table2',
          },
          {
            destinationTableId: 'table1',
            relationId: 'relation2',
            sourceTableId: 'table2',
          },
          {
            destinationTableId: 'table1',
            relationId: 'relation3',
            sourceTableId: 'table2',
          },
        ],
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation1',
          sourceTableId: 'table2',
        },
      })
    ).toBe(20)
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations: [
          {
            destinationTableId: 'table1',
            relationId: 'relation1',
            sourceTableId: 'table2',
          },
          {
            destinationTableId: 'table1',
            relationId: 'relation2',
            sourceTableId: 'table2',
          },
          {
            destinationTableId: 'table1',
            relationId: 'relation3',
            sourceTableId: 'table2',
          },
        ],
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation2',
          sourceTableId: 'table2',
        },
      })
    ).toBe(30)
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations: [
          {
            destinationTableId: 'table1',
            relationId: 'relation1',
            sourceTableId: 'table2',
          },
          {
            destinationTableId: 'table1',
            relationId: 'relation2',
            sourceTableId: 'table2',
          },
          {
            destinationTableId: 'table1',
            relationId: 'relation3',
            sourceTableId: 'table2',
          },
          // This one is not pointing to table2 so it should be filled by defaultValue
          {
            destinationTableId: 'table1',
            relationId: 'relation4',
            sourceTableId: 'table3',
          },
        ],
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation2',
          sourceTableId: 'table3',
        },
      })
    ).toBe(5)
  })
  it('should work for default table destination set', () => {
    const options = {
      $default: {
        // We set a default for all relations pointing to table2
        table2: 30,
      },
      // For table1
      table1: {
        // We set a specific value for relation1
        relation1: 20,
        // We set a default for all relations pointing to table2 from table1
        table2: 10,
      },
    }
    const relations = [
      // This one is pointing to table2 from table1
      {
        destinationTableId: 'table1',
        relationId: 'relation1',
        sourceTableId: 'table2',
      },
      {
        destinationTableId: 'table1',
        relationId: 'relation2',
        sourceTableId: 'table2',
      },
      // This one is not pointing to table3 from table1
      {
        destinationTableId: 'table1',
        relationId: 'relation4',
        sourceTableId: 'table3',
      },
      // This one is pointing to table2 from table5
      {
        destinationTableId: 'table5',
        relationId: 'relation5',
        sourceTableId: 'table2',
      },
    ]
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations,
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation1',
          sourceTableId: 'table2',
        },
      })
      //  Should be 20 because the relation value is defined
    ).toBe(20)
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations,
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation2',
          sourceTableId: 'table2',
        },
      })
      //  Should be 10 because the table value is defined for table1 -> table2
    ).toBe(10)
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations,
        relation: {
          destinationTableId: 'table5',
          relationId: 'relation5',
          sourceTableId: 'table2',
        },
      })
      // Should be 30 because the default value is defined for all relations pointing to table2
    ).toBe(30)
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations,
        relation: {
          destinationTableId: 'table5',
          relationId: 'relation4',
          sourceTableId: 'table4',
        },
      })
      // Should be 5 because no default value
    ).toBe(5)
  })
  it('should work for default table destination set with global default', () => {
    const options = {
      $default: {
        $default: Number.MAX_SAFE_INTEGER,
        // We set a default for all relations pointing to table2
        table2: 30,
      },
      // For table1
      table1: {
        // We set a specific value for relation1
        relation1: 20,
        // We set a default for all relations pointing to table2 from table1
        table2: 10,
      },
    }
    const relations = [
      // This one is pointing to table2 from table1
      {
        destinationTableId: 'table1',
        relationId: 'relation1',
        sourceTableId: 'table2',
      },
      {
        destinationTableId: 'table1',
        relationId: 'relation2',
        sourceTableId: 'table2',
      },
      // This one is not pointing to table3 from table1
      {
        destinationTableId: 'table1',
        relationId: 'relation4',
        sourceTableId: 'table3',
      },
      // This one is pointing to table2 from table5
      {
        destinationTableId: 'table5',
        relationId: 'relation5',
        sourceTableId: 'table2',
      },
    ]
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations,
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation1',
          sourceTableId: 'table2',
        },
      })
      //  Should be 20 because the relation value is defined
    ).toBe(20)
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations,
        relation: {
          destinationTableId: 'table1',
          relationId: 'relation2',
          sourceTableId: 'table2',
        },
      })
      //  Should be 10 because the table value is defined for table1 -> table2
    ).toBe(10)
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations,
        relation: {
          destinationTableId: 'table5',
          relationId: 'relation5',
          sourceTableId: 'table2',
        },
      })
      // Should be 30 because the default value is defined for all relations pointing to table2
    ).toBe(30)
    expect(
      getRelationshipOption({
        cascadingOptions: options,
        defaultValue: 5,
        relations,
        relation: {
          destinationTableId: 'table5',
          relationId: 'relation4',
          sourceTableId: 'table4',
        },
      })
      // Should be the global default value
    ).toBe(Number.MAX_SAFE_INTEGER)
  })
})
