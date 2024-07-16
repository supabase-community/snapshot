import { fmt } from './format.js'

test('`fmt` transforms markdown to ansi colors', function () {
  expect(
    fmt('this *bold* and this *bold* are different')
  ).toMatchInlineSnapshot(`"this *bold* and this *bold* are different"`)

  expect(fmt('# heading')).toMatchInlineSnapshot(`"[1mheading[22m"`)

  expect(
    fmt('this __italic__ and this __italic__ are different')
  ).toMatchInlineSnapshot(
    `"this [3mitalic[23m and this [3mitalic[23m are different"`
  )
})
