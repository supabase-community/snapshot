import { isInstanceOf } from './lang.js'

describe('lang', () => {
  describe('isInstanceOf', () => {
    test('true when native instanceof is true', () => {
      class Foo {}
      class Bar {}
      expect(isInstanceOf(new Foo(), Foo)).toBe(true)
      expect(isInstanceOf(new Error(), Error)).toBe(true)
      expect(isInstanceOf(new Foo(), Bar)).toBe(false)
      expect(isInstanceOf(new Error(), Bar)).toBe(false)
    })

    test('true when constructor name matches', () => {
      expect(isInstanceOf(new (class Foo {})(), class Foo {})).toBe(true)
      expect(isInstanceOf(new Error(), class Error {})).toBe(true)
      expect(isInstanceOf(new (class Foo {})(), class Bar {})).toBe(false)
      expect(isInstanceOf(new Error(), class Bar {})).toBe(false)
    })
  })
})
