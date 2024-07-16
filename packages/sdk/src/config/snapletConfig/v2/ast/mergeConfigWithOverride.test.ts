import { mergeConfigWithOverride } from './mergeConfigWithOverride.js'
import { SnapletConfig, parseConfig } from '../getConfig/parseConfig.js'

describe('mergeConfigWithOverride', () => {
  test('should create subset', async () => {
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
    const result = await mergeConfigWithOverride(
      source,
      parseConfig({
        subset: { targets: [{ table: 'public.User', rowLimit: 10 }] },
      })
    )
    // ignore whitespaces
    expect(result.replace(/\s/g, '')).toEqual(
      `import { copycat } from '@snaplet/copycat';
    import { defineConfig } from 'snaplet';
    export default defineConfig({
      transform: {
        public: {
          User({
            row
          }) {
            return {
              email: copycat.email(row.email)
            };
          }
        }
      },
      subset: {
        enabled: true,
        targets: [{
          table: "public.User",
          rowLimit: 10
        }],
        followNullableRelations: true,
        maxCyclesLoop: 1
      }
    });`.replace(/\s/g, '')
    )
  })
  test('should merge subset and replace enabled value', async () => {
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
        subset: {
          enabled: false,
        },
      })
    `.trim()
    const result = await mergeConfigWithOverride(
      source,
      parseConfig({
        subset: { targets: [{ table: 'public.User', rowLimit: 10 }] },
      })
    )
    // ignore whitespaces
    expect(result.replace(/\s/g, '')).toEqual(
      `import { copycat } from '@snaplet/copycat';
    import { defineConfig } from 'snaplet';
    export default defineConfig({
      transform: {
        public: {
          User({
            row
          }) {
            return {
              email: copycat.email(row.email)
            };
          }
        }
      },
      subset: {
        enabled: true,
        targets: [{
          table: "public.User",
          rowLimit: 10
        }],
        followNullableRelations: true,
        maxCyclesLoop: 1
      }
    });`.replace(/\s/g, '')
    )
  })
  test('should deeply merge subset transform select', async () => {
    const source = `
      import { copycat } from '@snaplet/copycat'
      import { defineConfig } from 'snaplet'

      export default defineConfig({
        select: {
          $default: "structure",
          public: {
            _prisma_migrations: false,
          },
        },
        transform: {
          public: {
            User: ({ row }) => {
              return {
                email: copycat.email(row.email),
              }
            },
          },
        },
        subset: {
          enabled: false,
        },
      })
    `.trim()
    const result = await mergeConfigWithOverride(
      source,
      parseConfig({
        select: {
          public: {
            $default: true,
          },
        },
        transform: {
          public: {
            // @ts-expect-error
            Snapshot: ({ row }) => {
              return {
                id: row.id,
              }
            },
          },
        },
        subset: { targets: [{ table: 'public.User', rowLimit: 10 }] },
      }),
      true
    )
    // ignore whitespaces
    expect(result.replace(/\s/g, '')).toEqual(
      `import { copycat } from '@snaplet/copycat';
      import { defineConfig } from 'snaplet';
      export default defineConfig({
        select: {
          $default: "structure",
          public: {
            _prisma_migrations: false,
            $default: true
          }
        },
        transform: {
          public: {
            User: ({
              row
            }) => {
              return {
                email: copycat.email(row.email)
              };
            },
            Snapshot: ({
              row
            }) => {
              return {
                id: row.id
              };
            }
          },
          $mode: "unsafe",
          $parseJson: true
        },
        subset: {
          enabled: true,
          targets: [{
            table: "public.User",
            rowLimit: 10
          }],
          followNullableRelations: true,
          maxCyclesLoop: 1
        }
      });`.replace(/\s/g, '')
    )
  })
  test('should shallow merge subset transform select', async () => {
    const source = `
      import { copycat } from '@snaplet/copycat'
      import { defineConfig } from 'snaplet'

      export default defineConfig({
        select: {
          $default: "structure",
          public: {
            _prisma_migrations: false,
          },
        },
        transform: {
          public: {
            User: ({ row }) => {
              return {
                email: copycat.email(row.email),
              }
            },
          },
        },
        subset: {
          enabled: false,
        },
      })
    `.trim()
    const result = await mergeConfigWithOverride(
      source,
      parseConfig({
        select: {
          public: {
            $default: true,
          },
        },
        transform: {
          public: {
            // @ts-expect-error
            Snapshot: ({ row }) => {
              return {
                id: row.id,
              }
            },
          },
        },
        subset: { targets: [{ table: 'public.User', rowLimit: 10 }] },
      })
    )
    // ignore whitespaces
    expect(result.replace(/\s/g, '')).toEqual(
      `import { copycat } from '@snaplet/copycat';
      import { defineConfig } from 'snaplet';
      export default defineConfig({
        select: {
          public: {
            $default: true
          }
        },
        transform: {
          $mode: "unsafe",
          $parseJson: true,
          public: {
            Snapshot: ({
              row
            }) => {
              return {
                id: row.id
              };
            }
          }
        },
        subset: {
          enabled: true,
          targets: [{
            table: "public.User",
            rowLimit: 10
          }],
          followNullableRelations: true,
          maxCyclesLoop: 1
        }
      });`.replace(/\s/g, '')
    )
  })
  test('should only create the subset.targets property', async () => {
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
    const result = await mergeConfigWithOverride(source, {
      subset: { targets: [{ table: 'public.User', rowLimit: 10 }] },
    } as unknown as Partial<SnapletConfig>)
    // ignore whitespaces
    expect(result.replace(/\s/g, '')).toEqual(
      `import { copycat } from '@snaplet/copycat';
    import { defineConfig } from 'snaplet';
    export default defineConfig({
      transform: {
        public: {
          User({
            row
          }) {
            return {
              email: copycat.email(row.email)
            };
          }
        }
      },
      subset: {
        targets: [{
          table: "public.User",
          rowLimit: 10
        }]
      }
    });`.replace(/\s/g, '')
    )
  })
  test('should override existing subset property', async () => {
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
        subset: {
          enabled: false,
        }
      })
    `.trim()
    const result = await mergeConfigWithOverride(source, {
      subset: { targets: [{ table: 'public.User', rowLimit: 10 }] },
    } as unknown as Partial<SnapletConfig>)
    // ignore whitespaces
    expect(result.replace(/\s/g, '')).toEqual(
      `import { copycat } from '@snaplet/copycat';
    import { defineConfig } from 'snaplet';
    export default defineConfig({
      transform: {
        public: {
          User({
            row
          }) {
            return {
              email: copycat.email(row.email)
            };
          }
        }
      },
      subset: {
        targets: [{
          table: "public.User",
          rowLimit: 10
        }]
      }
    });`.replace(/\s/g, '')
    )
  })
  test('should merge existing subset property and override targets', async () => {
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
        subset: {
          enabled: false,
        }
      })
    `.trim()
    const result = await mergeConfigWithOverride(
      source,
      {
        subset: { targets: [{ table: 'public.User', rowLimit: 10 }] },
      } as unknown as Partial<SnapletConfig>,
      true
    )
    // ignore whitespaces
    expect(result.replace(/\s/g, '')).toEqual(
      `import { copycat } from '@snaplet/copycat';
    import { defineConfig } from 'snaplet';
    export default defineConfig({
      transform: {
        public: {
          User({
            row
          }) {
            return {
              email: copycat.email(row.email)
            };
          }
        }
      },
      subset: {
        enabled: false,
        targets: [{
          table: "public.User",
          rowLimit: 10
        }]
      }
    });`.replace(/\s/g, '')
    )
  })
})
