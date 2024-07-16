import { mapValues } from 'lodash'

import { COLUMN_CONSTRAINTS } from '../db/introspect/queries/fetchTablesAndColumns.js'
import { ErrorList } from '../errors.js'
import { fakeColumnStructure } from '../testing.js'
import { fakeDbStructure } from '../testing.js'
import { fakeTableStructure } from '../testing.js'
import {
  TRANSFORM_MODES,
  createTransformer,
  importGenerateTransform,
} from './transform.js'
import { TransformError } from '../transformError.js'
import {
  SnapletConfigV2,
  Transform,
  TransformConfig,
} from '~/config/snapletConfig/v2/getConfig/parseConfig.js'

beforeAll(async () => {
  await importGenerateTransform()
})

describe('createTransformer', () => {
  test('context', async () => {
    const structure = fakeDbStructure({
      schemas: ['s1'],
      tables: [
        fakeTableStructure({
          schema: 's1',
          name: 't1',
          columns: [
            fakeColumnStructure({
              name: 'c1',
            }),
          ],
        }),
      ],
    })
    const transformer = await createTransformer(
      { structure },
      { s1: { t1: { c1: true } } }
    )

    expect(transformer.transform).toEqual({
      s1: {
        t1: {
          c1: true,
        },
      },
    })
  })

  test('option overrides', async () => {
    const transformConfig: TransformConfig = {}

    const transform = await createTransformer(
      { structure: fakeDbStructure() },
      transformConfig,
      {
        $mode: 'strict',
      }
    )

    expect(transform.options.$mode).toEqual('strict')
  })
})

describe('transformRow', () => {
  test('table transform functions', async () => {
    const transformConfig: TransformConfig = {
      public: {
        customer: ({ row }: { row: any }) => ({
          name: `the illustrious ${row.name}`,
        }),
      },
    }

    const structure = fakeDbStructure()
    const transform = await createTransformer({ structure }, transformConfig)

    const row = {
      id: '1',
      name: 'mr hungry cat',
      email: 'hungry@real-email.com',
    }

    const x = transform.transformRow({
      schema: 'public',
      table: 'customer',
      row: {
        parsed: row,
        raw: row,
        line: 23,
      },
    })
    expect(x).toEqual({
      email: 'hungry@real-email.com',
      id: '1',
      name: 'the illustrious mr hungry cat',
    })
  })

  test('column transform functions', async () => {
    const transformConfig: Transform = {
      public: {
        customer: {
          name: ({ row, value }) => `${row.name} is as ${value} does`,
        },
      },
    }

    const structure = fakeDbStructure()
    const config = await createTransformer({ structure }, transformConfig)

    const row = {
      id: '1',
      name: 'mr hungry cat',
      email: 'hungry@real-email.com',
    }

    const ctx = {
      schema: 'public',
      table: 'customer',
      row: {
        parsed: row,
        raw: row,
        line: 23,
      },
    }

    const x = config.transformRow(ctx)
    expect(x).toEqual({
      email: 'hungry@real-email.com',
      id: '1',
      name: 'mr hungry cat is as mr hungry cat does',
    })
  })

  test('per-column errors', async () => {
    const transformConfig: Transform = {
      public: {
        customer: {
          name: () => {
            throw new Error('badName')
          },
          email: () => {
            throw new Error('badEmail')
          },
        },
      },
    }

    const structure = fakeDbStructure()
    const config = await createTransformer({ structure }, transformConfig)

    const row = {
      id: '1',
      name: 'mr hungry cat',
      email: 'hungry@real-email.com',
    }

    const context = {
      schema: 'public',
      table: 'customer',
      row: {
        parsed: row,
        raw: row,
        line: 256,
      },
    }

    expect(() => config.transformRow(context)).toThrow(
      new ErrorList([
        new TransformError(
          {
            ...context,
            column: 'name',
          },
          new Error('badName')
        ),
        new TransformError(
          {
            ...context,
            column: 'email',
          },
          new Error('badEmail')
        ),
      ])
    )
  })

  describe('transform modes', () => {
    test('via config option', async () => {
      //@ts-expect-error: Since our types is an intersection of a record and an object
      // we can't use the $mode or $parseJson keys alongside with some schemas/tables transforms
      // definitions withour raising a type error. However it allows us to be much more intuitive
      // at reading time since we can do:
      //    const {$mode, $parseJson, ...schemasTransforms} = transformConfig
      // and end up with a strictly typed value for all of thems
      const transformConfig: SnapletConfigV2['transform'] = {
        $mode: 'strict',
        public: {
          customer: {
            email: 'hungry@fake-email.com',
          },
        },
      }

      const row = {
        id: '1',
        name: 'mr hungry cat',
        email: 'hungry@real-email.com',
      }

      const structure = fakeDbStructure()
      const config = await createTransformer({ structure }, transformConfig)

      const ctx = {
        schema: 'public',
        table: 'customer',
        row: {
          parsed: row,
          raw: row,
          line: 23,
        },
      }

      expect(() => config.transformRow(ctx)).toThrow(/strict transform mode/)
    })

    test('skips keys', async () => {
      const dbStructure = fakeDbStructure({
        tables: [
          fakeTableStructure({
            name: 'customer',
            schema: 'public',
            columns: [
              fakeColumnStructure({
                name: 'primary',
                type: 'int4',
                constraints: [COLUMN_CONSTRAINTS.PRIMARY_KEY],
              }),
              fakeColumnStructure({
                name: 'foreign',
                type: 'int4',
                constraints: [COLUMN_CONSTRAINTS.FOREIGN_KEY],
              }),
            ],
          }),
        ],
      })

      for (const $mode of Object.values(TRANSFORM_MODES)) {
        const transformConfig: TransformConfig = {
          public: {
            customer: {},
          },
        }

        const row = {
          primary: 2,
          foreign: 3,
        }

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode,
          }
        )

        const result = config.transformRow({
          schema: 'public',
          table: 'customer',
          row: {
            parsed: row,
            raw: mapValues(row, (value) => JSON.stringify(value)),
            line: 23,
          },
        })

        expect(result.primary).toEqual(2)
        expect(result.foreign).toEqual(3)
      }
    })

    describe('unsafe mode', () => {
      test('non-existent or undefined config value', async () => {
        const transform1: TransformConfig = {
          public: {
            customer: {
              email: 'hungry@fake-email.com',
            },
          },
        }

        const transform2: TransformConfig = {
          public: {
            customer: {
              // @ts-expect-error
              name: undefined,
              email: 'hungry@fake-email.com',
            },
          },
        }

        for (const transformConfig of [transform1, transform2]) {
          const row = {
            id: '1',
            name: 'mr hungry cat',
            email: 'hungry@real-email.com',
          }

          const config = await createTransformer(
            { structure: fakeDbStructure() },
            transformConfig,
            { $mode: 'unsafe' }
          )

          const x = config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: row,
              line: 23,
            },
          })

          expect(x.name).toEqual('mr hungry cat')
        }
      })

      test('null config value', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {
              name: null,
              email: 'hungry@fake-email.com',
            },
          },
        }

        const row = {
          id: '1',
          name: 'mr hungry cat',
          email: 'hungry@real-email.com',
        }

        const config = await createTransformer(
          { structure: fakeDbStructure() },
          transformConfig,
          {
            $mode: 'unsafe',
          }
        )

        const x = config.transformRow({
          schema: 'public',
          table: 'customer',
          row: {
            parsed: row,
            raw: row,
            line: 23,
          },
        })

        expect(x.name).toEqual(null)
      })
    })

    describe('strict mode', () => {
      test('non-existent or undefined config value', async () => {
        const transform1: TransformConfig = {
          public: {
            customer: {
              email: 'hungry@fake-email.com',
            },
          },
        }

        const transform2: TransformConfig = {
          public: {
            customer: {
              // @ts-expect-error
              name: undefined,
              email: 'hungry@fake-email.com',
            },
          },
        }

        for (const transformConfig of [transform1, transform2]) {
          const row = {
            name: 'mr hungry cat',
            email: 'hungry@real-email.com',
          }

          const config = await createTransformer(
            { structure: fakeDbStructure() },
            transformConfig,
            {
              $mode: 'strict',
            }
          )

          expect(() =>
            config.transformRow({
              schema: 'public',
              table: 'customer',
              row: {
                parsed: row,
                raw: row,
                line: 23,
              },
            })
          ).toThrow(/strict transform mode/)
        }
      })

      test('null config value', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {
              name: null,
              email: 'hungry@fake-email.com',
            },
          },
        }

        const row = {
          name: 'mr hungry cat',
          email: 'hungry@real-email.com',
        }

        const config = await createTransformer(
          { structure: fakeDbStructure() },
          transformConfig,
          {
            $mode: 'strict',
          }
        )

        expect(
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: row,
              line: 23,
            },
          }).name
        ).toEqual(null)
      })
    })

    describe('auto mode', () => {
      test('no column structure info', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {
              email: 'hungry@fake-email.com',
            },
          },
        }

        const row = {
          id: '1',
          name: 'mr hungry cat',
          email: 'hungry@real-email.com',
        }

        const config = await createTransformer(
          { structure: fakeDbStructure() },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        expect(() =>
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: row,
              line: 23,
            },
          })
        ).toThrow(/info about the column/)
      })

      test('non-string value + no known js type + non-nullable', async () => {
        const transformConfig: TransformConfig = {
          database: {
            public: {
              customer: {},
            },
          },
        }

        const row = {
          v: 23,
        }

        const dbStructure = fakeDbStructure({
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: [
                fakeColumnStructure({
                  name: 'v',
                  type: 'dfsdfsdf',
                  nullable: false,
                }),
              ],
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        expect(() =>
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: { v: '23' },
              line: 23,
            },
          })
        ).toThrow(/not yet support/)
      })

      test('enums', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {},
          },
        }

        const row = {
          v: 'Baz',
        }

        const dbStructure = fakeDbStructure({
          enums: [
            {
              id: 'public.Foo',
              schema: 'public',
              name: 'Foo',
              values: ['Bar', 'Baz', 'Quux'],
            },
          ],
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: [
                fakeColumnStructure({
                  name: 'v',
                  type: 'Foo',
                  typeCategory: 'E',
                  nullable: false,
                }),
              ],
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        const { v: result } = config.transformRow({
          schema: 'public',
          table: 'customer',
          row: {
            parsed: row,
            raw: { v: 'Foo' },
            line: 23,
          },
        })

        expect(result).toMatchInlineSnapshot('"Quux"')
      })

      test('unknown enum', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {},
          },
        }

        const row = {
          v: 'Baz',
        }

        const dbStructure = fakeDbStructure({
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: [
                fakeColumnStructure({
                  name: 'v',
                  type: 'Foo',
                  typeCategory: 'E',
                  nullable: false,
                }),
              ],
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        expect(() =>
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: { v: 'Foo' },
              line: 23,
            },
          })
        ).toThrow(/enum/)
      })

      test('non-string value + no known js type + nullable', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {},
          },
        }

        const row = {
          v: 23,
        }

        const dbStructure = fakeDbStructure({
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: [
                fakeColumnStructure({
                  name: 'v',
                  type: 'dfsdfsdf',
                  nullable: true,
                }),
              ],
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        expect(
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: { v: '23' },
              line: 23,
            },
          }).v
        ).toBe(null)
      })

      test('non-string value + known js type', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {},
          },
        }

        const row = {
          name: 23,
        }

        const dbStructure = fakeDbStructure({
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: [
                fakeColumnStructure({
                  name: 'name',
                  type: 'int4',
                }),
              ],
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        expect(
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: { name: '23' },
              line: 23,
            },
          }).name
        ).toMatchInlineSnapshot('36')
      })

      test('array values', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {},
          },
        }

        const row = {
          name: [23],
        }

        const dbStructure = fakeDbStructure({
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: [
                fakeColumnStructure({
                  name: 'name',
                  type: '_int4',
                }),
              ],
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        expect(
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: { name: '23' },
              line: 23,
            },
          }).name
        ).toEqual([36])
      })

      test('null values', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {},
          },
        }

        const row = {
          name: null,
        }

        const dbStructure = fakeDbStructure({
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: [
                fakeColumnStructure({
                  name: 'name',
                  nullable: true,
                }),
              ],
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        expect(
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: { name: 'NULL' },
              line: 23,
            },
          }).name
        ).toBe(null)
      })

      test('unknown shapes', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {},
          },
        }

        const row = {
          Skarsgård: 'Stellar Stellan',
        }

        const dbStructure = fakeDbStructure({
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: [
                fakeColumnStructure({
                  name: 'Skarsgård',
                  type: 'text',
                }),
              ],
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        expect(
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: row,
              line: 23,
            },
          }).Skarsgård
        ).toMatchInlineSnapshot('"Hqqajtv Gxskqay"')
      })

      test('large string values', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {},
          },
        }

        const row = {
          thing: Array(1000).fill('!').join(''),
        }

        const dbStructure = fakeDbStructure({
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: [
                fakeColumnStructure({
                  name: 'thing',
                  type: 'text',
                }),
              ],
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        expect(
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: row,
              line: 23,
            },
          }).thing.length
        ).toBe(1000)
      })

      test('known shapes', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {},
          },
        }

        const row = {
          email: 'stellarstellan@skars.gard',
        }

        const dbStructure = fakeDbStructure({
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: [
                fakeColumnStructure({
                  name: 'email',
                  type: 'text',
                }),
              ],
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        expect(
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: row,
              line: 23,
            },
          }).email
        ).toMatchInlineSnapshot('"uqsrjunjvxggaj@rbfuf.trat"')
      })

      test('date types', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {},
          },
        }

        const row = {
          timestamp: '2022-11-10 08:51:42.830Z',
          timestamptz: '2004-10-19 10:23:54+03:00',
          date: '2022-11-10',
          time: '08:51:42.830Z',
          interval: '01:02:03.456',
          timetz: '04:05:06.789-08:00',
        }

        const dbStructure = fakeDbStructure({
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: Object.keys(row).map((name) =>
                fakeColumnStructure({
                  name,
                  type: name,
                })
              ),
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        expect(
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: row,
              line: 23,
            },
          })
        ).toEqual({
          date: '2052-08-14',
          interval: '07:05:06.272',
          time: '04:03:18.613Z',
          timestamp: '2052-08-14T04:03:18.613Z',
          timestamptz: '0291-09-09T02:36:04.004Z',
          timetz: '10:06:09.156Z',
        })
      })

      test('date types - non-date values', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {},
          },
        }

        const row = {
          timestamp: 'infinity',
          timestamptz: 'infinity',
          date: 'infinity',
          time: 'infinity',
          interval: 'infinity',
          timetz: 'infinity',
        }

        const dbStructure = fakeDbStructure({
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: Object.keys(row).map((name) =>
                fakeColumnStructure({
                  name,
                  type: name,
                })
              ),
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        expect(
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: row,
              line: 23,
            },
          })
        ).toEqual({
          date: '5992-05-06',
          interval: '12:04:14.685',
          time: '12:04:14.685Z',
          timestamp: '5992-05-06T12:04:14.685Z',
          timestamptz: '5992-05-06T12:04:14.685Z',
          timetz: '12:04:14.685Z',
        })
      })

      test('undefined in config', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {
              // @ts-expect-error
              Skarsgård: undefined,
            },
          },
        }

        const row = {
          Skarsgård: 'Stellar Stellan',
        }

        const dbStructure = fakeDbStructure({
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: [
                fakeColumnStructure({
                  name: 'Skarsgård',
                  type: 'text',
                }),
              ],
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
          }
        )

        expect(
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: row,
              line: 23,
            },
          }).Skarsgård
        ).toMatchInlineSnapshot('"Hqqajtv Gxskqay"')
      })

      test('raw json', async () => {
        const transformConfig: TransformConfig = {
          public: {
            customer: {},
          },
        }

        const row = {
          v: '{"foo":23}',
        }

        const dbStructure = fakeDbStructure({
          tables: [
            fakeTableStructure({
              name: 'customer',
              schema: 'public',
              columns: [
                fakeColumnStructure({
                  name: 'v',
                  type: 'json',
                  nullable: false,
                }),
              ],
            }),
          ],
        })

        const config = await createTransformer(
          { structure: dbStructure },
          transformConfig,
          {
            $mode: 'auto',
            $parseJson: false,
          }
        )

        expect(
          config.transformRow({
            schema: 'public',
            table: 'customer',
            row: {
              parsed: row,
              raw: row,
              line: 23,
            },
          }).v
        ).toMatchInlineSnapshot('"{\\"foo\\":36}"')
      })
    })
  })
})
