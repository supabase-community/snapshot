import { addOptionsToModelDefaultCode } from './addOptionsToModelDefaultCode.js'

describe('addOptionsToModelDefaultCode', () => {
  test('adding `options` argument', async () => {
    expect(await addOptionsToModelDefaultCode('copycat.email(seed)')).toEqual(
      'copycat.email(seed, options);'
    )
  })

  test('spreading in `options` into existing object expression', async () => {
    expect(
      await addOptionsToModelDefaultCode('copycat.email(seed, { limit: 10 })')
    ).toEqual(`\
copycat.email(seed, {
  limit: 10,
  ...options
});`)
  })

  test('ignores irrelevant code', async () => {
    expect(await addOptionsToModelDefaultCode('null')).toEqual('null;')
    expect(await addOptionsToModelDefaultCode('faker.wassup()')).toEqual(
      'faker.wassup();'
    )
  })

  test('works with object expressions', async () => {
    expect(
      await addOptionsToModelDefaultCode(
        '{ [copycat.email(seed)]: copycat.email(seed) }'
      )
    ).toEqual(`\
({
  [copycat.email(seed, options)]: copycat.email(seed, options)
});`)
  })
})
