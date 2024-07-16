import { RestoreError } from './restoreError.js'

describe('RestoreError', () => {
  test('the error is formatted correctly', async () => {
    const error = new RestoreError(
      {
        filePath: `${process.cwd()}/.snaplet/snapshots/1660915182078-v546-lela-corners-protocol/tables/public.User.csv`,
        schema: 'public',
        table: 'User',
        columns: ['id', 'name', 'email'],
      },
      'it broke somewhere'
    )

    expect(error.toString()).toMatchInlineSnapshot(`
      "┌─[.snaplet/snapshots/1660915182078-v546-lela-corners-protocol/tables/public.User.csv]
      │
      ·  [31mit broke somewhere[39m
      │
      └─"
    `)
  })

  test('the error is formatted correctly when providing a row', async () => {
    const error = new RestoreError(
      {
        filePath: `${process.cwd()}/.snaplet/snapshots/1660915182078-v546-lela-corners-protocol/tables/public.User.csv`,
        schema: 'public',
        table: 'User',
        columns: ['id', 'name', 'email'],
        row: {
          line: 3654,
          value: 'u1654519848516,John Doe,john.doe@gmail.com',
        },
      },
      'it broke here'
    )

    expect(error.toString()).toMatchInlineSnapshot(`
      "       ┌─[.snaplet/snapshots/1660915182078-v546-lela-corners-protocol/tables/public.User.csv:3654]
             │
           1 │  id,name,email
             ·
             ·
      [31m∙[39m 3654 │  u1654519848516,John Doe,john.doe@gmail.com
             ·  [31m─────┬────────────────────────────────────[39m
             ·  [31m     ╰────── it broke here[39m
             │
             └─"
    `)
  })
})
