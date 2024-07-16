import { TransformError } from './transformError.js'

describe('TransformError', () => {
  test('the error is formatted correctly', async () => {
    const error = new TransformError(
      {
        schema: 'public',
        table: 'User',
        columns: ['id', 'name', 'email'],
        row: {
          line: 3654,
          raw: {
            id: 'u1654519848516',
            name: 'John Doe',
            email: 'john.doe@gmail.com',
          },
          parsed: {
            id: 'u1654519848516',
            name: 'John Doe',
            email: 'john.doe@gmail.com',
          },
        },
        column: 'name',
      },
      'it broke here'
    )

    expect(error.toString()).toMatchInlineSnapshot(`
      "       ┌─[\\"public\\".\\"User\\"]
             │
           1 │  id,name,email
             ·
             ·
      [31m∙[39m 3655 │  u1654519848516,John Doe,john.doe@gmail.com
             ·  [31m               ────┬───[39m
             ·  [31m                   ╰────── it broke here[39m
             │
             └─"
    `)
  })
})
