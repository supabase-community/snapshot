import { mapValues } from 'lodash'

import {
  parseColumn,
  parseRow,
  serializeArrayColumn,
  serializeColumn,
  serializeRow,
} from './csv.js'
import { JS_TO_PG_TYPES, JsonNull, PgTypeName } from './pgTypes.js'
import type { Json } from './types.js'

describe('{serialize,parse}Column', () => {
  test('serializing and parsing are inverses of each other', () => {
    const inputs = {
      text: ['foo', 'bar'],
      int: [0, 1, -1, 23],
      bool: [true, false],
      json: [{}, { bar: 'baz' }],
      'bool[][]': [[[true, false]]],
      'text[][]': [[['foo', 'bar']]],
      'int[][]': [[[2, 3]]],
      'json[][]': [[[{ foo: 2 }, { bar: 3 }]]],
    }

    Object.keys(inputs).forEach((pgType) => {
      const values = inputs[pgType as keyof typeof inputs] as Json[]

      for (const value of values) {
        expect(parseColumn(serializeColumn(value, pgType), pgType)).toEqual(
          value
        )
      }
    })
  })

  test('array types', () => {
    const expectToBeInverses = (
      parsed: Json,
      serialized: string,
      pgType: string
    ) => {
      expect(serializeColumn(parsed, pgType)).toEqual(serialized)
      expect(parseColumn(serialized, pgType)).toEqual(parsed)
    }

    expectToBeInverses([[['foo', 'bar']]], '{{{"foo","bar"}}}', 'text[][][]')
    expectToBeInverses([[[2, 3]]], '{{{2,3}}}', 'int[][][]')
    expectToBeInverses([[[true, false]]], '{{{t,f}}}', 'bool[][][]')
    expectToBeInverses(
      [[['[2010-01-01 14:30, 2010-01-01 15:30)']]],
      '{{{"[2010-01-01 14:30, 2010-01-01 15:30)"}}}',
      'tstzrange[][][]'
    )

    expectToBeInverses(
      [[[{ foo: [2] }, { bar: [3] }]]],
      `{{{${JSON.stringify(JSON.stringify({ foo: [2] }))},${JSON.stringify(
        JSON.stringify({ bar: [3] })
      )}}}}`,
      'json[][][]'
    )
  })

  test('custom parsing and serialising', () => {
    const parsed = parseColumn('21', 'text', { string: (v) => +v + 1 })

    const serialized = serializeColumn(parsed, 'text', {
      string: (v) => ((v as number) + 1).toString(),
    })

    expect(serialized).toEqual('23')
  })
})

describe('{serialize,parse}Row', () => {
  test('serializing and parsing are inverses of each other', () => {
    const row = {
      string: 'foo',
      number: 23,
      boolean: true,
      Json: { bar: 'baz ' },
    }

    const columnTypes = mapValues(
      row,
      (_, jsType) => JS_TO_PG_TYPES[jsType as keyof typeof JS_TO_PG_TYPES][0]
    )

    expect(
      parseRow({
        row: serializeRow({ row, columnTypes }),
        columnTypes,
      })
    ).toEqual(row)
  })

  test('serializing+parsing a row with insuffient column type information', () => {
    const row = {
      name: 'value',
    }

    expect(
      parseRow({ row, columnTypes: {} as Record<string, PgTypeName> })
    ).toEqual(row)
    expect(
      serializeRow({ row, columnTypes: {} as Record<string, PgTypeName> })
    ).toEqual(row)
  })

  test('parsing+serializing a row with null values', () => {
    const row = {
      id: '1',
      c_db_null: null,
      c_json_null: 'null',
      c_json_null_string: '"null"',
      c_json_null_array: '[null]',
      c_json_null_object: '{ "foo": null }',
    }

    const columnTypes = {
      id: 'int',
      c_db_null: 'jsonb',
      c_json_null: 'jsonb',
      c_json_null_string: 'jsonb',
      c_json_null_array: 'jsonb',
      c_json_null_object: 'jsonb',
    } as Record<string, PgTypeName>

    const parsedRow = parseRow({ row, columnTypes })

    // once parsed, we see that c_db_null and c_json_null are both null at runtime
    expect(parsedRow).toEqual({
      id: 1,
      c_db_null: null,
      c_json_null: null,
      c_json_null_string: 'null',
      c_json_null_array: [null],
      c_json_null_object: {
        foo: null,
      },
    })

    // when serializing, we can't distinguish between db null and json null
    expect(
      serializeRow({
        columnTypes,
        row: parsedRow,
      })
    ).toEqual({
      id: '1',
      c_db_null: null,
      c_json_null: null,
      c_json_null_string: '"null"',
      c_json_null_array: '[null]',
      c_json_null_object: '{"foo":null}',
    })

    // by using JsonNull, we can distinguish between db null and json null and serialize accordingly
    expect(
      serializeRow({
        columnTypes,
        row: {
          ...parsedRow,
          c_json_null: new JsonNull(),
        },
      })
    ).toEqual({
      id: '1',
      c_db_null: null,
      c_json_null: 'null',
      c_json_null_string: '"null"',
      c_json_null_array: '[null]',
      c_json_null_object: '{"foo":null}',
    })
  })

  test('serializeArrayColumn', () => {
    expect(
      serializeArrayColumn([[['foo', null, 'bar']]], 'text[][][]')
    ).toEqual('{{{"foo",NULL,"bar"}}}')
    expect(serializeArrayColumn([1, 2, null], 'int[]')).toEqual('{1,2,NULL}')
    expect(serializeArrayColumn([[[1, 2, null]]], 'jsonb[][]')).toEqual(
      '{{"[1,2,null]"}}'
    )
    expect(serializeArrayColumn([[{ foo: 'bar' }]], 'jsonb[][]')).toEqual(
      '{{"{\\"foo\\":\\"bar\\"}"}}'
    )
  })
})
