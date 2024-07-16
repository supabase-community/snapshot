import { locateColumnConfig } from './locateColumnConfig.js'

describe('locateColumConfig', () => {
  test('returned literal with key in', async () => {
    const source = `
      import { copycat } from '@snaplet/copycat'
      import { defineConfig } from 'snaplet'

      export default defineConfig({
        transform: {
          public: {
            User({ row }) {
              return {
                email: copycat.email(row.email),
              }
            },
          },
        },
      })
    `.trim()

    expect(await locateColumnConfig(source, 'public', 'User', 'email'))
      .toMatchInlineSnapshot(`
        {
          "column": SourceLocation {
            "end": Position {
              "column": 47,
              "index": 264,
              "line": 9,
            },
            "filename": undefined,
            "identifierName": undefined,
            "start": Position {
              "column": 16,
              "index": 233,
              "line": 9,
            },
          },
          "schema": SourceLocation {
            "end": Position {
              "column": 11,
              "index": 308,
              "line": 12,
            },
            "filename": undefined,
            "identifierName": undefined,
            "start": Position {
              "column": 18,
              "index": 164,
              "line": 6,
            },
          },
          "table": SourceLocation {
            "end": Position {
              "column": 13,
              "index": 295,
              "line": 11,
            },
            "filename": undefined,
            "identifierName": undefined,
            "start": Position {
              "column": 12,
              "index": 178,
              "line": 7,
            },
          },
        }
      `)
  })

  test('no column given', async () => {
    const source = `
      import { copycat } from '@snaplet/copycat'
      import { defineConfig } from 'snaplet'

      export default defineConfig({
        transform: {
          public: {
            User({ row }) {
              return {}
            },
          },
        },
      })
    `.trim()

    expect(await locateColumnConfig(source, 'public', 'User', 'email'))
      .toMatchInlineSnapshot(`
      {
        "column": null,
        "schema": SourceLocation {
          "end": Position {
            "column": 11,
            "index": 244,
            "line": 10,
          },
          "filename": undefined,
          "identifierName": undefined,
          "start": Position {
            "column": 18,
            "index": 164,
            "line": 6,
          },
        },
        "table": SourceLocation {
          "end": Position {
            "column": 13,
            "index": 231,
            "line": 9,
          },
          "filename": undefined,
          "identifierName": undefined,
          "start": Position {
            "column": 12,
            "index": 178,
            "line": 7,
          },
        },
      }
    `)
  })

  test('no table given', async () => {
    const source = `
      import { copycat } from '@snaplet/copycat'
      import { defineConfig } from 'snaplet'

      export default defineConfig({
        transform: {
          public: {
          },
        },
      })
    `.trim()

    expect(await locateColumnConfig(source, 'public', 'User', 'email'))
      .toMatchInlineSnapshot(`
      {
        "column": null,
        "schema": SourceLocation {
          "end": Position {
            "column": 11,
            "index": 177,
            "line": 7,
          },
          "filename": undefined,
          "identifierName": undefined,
          "start": Position {
            "column": 18,
            "index": 164,
            "line": 6,
          },
        },
        "table": null,
      }
    `)
  })

  test('no schema given', async () => {
    const source = `
      import { copycat } from '@snaplet/copycat'
      import { defineConfig } from 'snaplet'

      export default defineConfig({
        transform: {
        },
      })
    `.trim()

    expect(await locateColumnConfig(source, 'public', 'User', 'email'))
      .toMatchInlineSnapshot(`
      {
        "column": null,
        "schema": null,
        "table": null,
      }
    `)
  })
})
