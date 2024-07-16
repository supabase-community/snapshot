import fsExtra from 'fs-extra'
import path from 'path'
import tmp from 'tmp-promise'

import { loadModule } from './loadModule.js'

describe('loadModule', () => {
  test('resolves relative modules', async () => {
    const dir = await tmp.dir()
    const pathA = path.join(dir.path, 'a.ts')

    await fsExtra.writeFile(
      pathA,
      `
    import { b } from './b.ts'
    export default b
    `
    )

    await fsExtra.writeFile(
      path.join(dir.path, 'b.ts'),
      `
      export const b: number = 23
    `
    )

    expect(loadModule(pathA)).toEqual({ default: 23 })
  })

  test('resolves ts without extension', async () => {
    const dir = await tmp.dir()
    const pathA = path.join(dir.path, 'a.ts')

    await fsExtra.writeFile(
      pathA,
      `
    import { b } from './b'
    export default b
    `
    )

    await fsExtra.writeFile(
      path.join(dir.path, 'b.ts'),
      `
      export const b: number = 23
    `
    )

    expect(loadModule(pathA)).toEqual({ default: 23 })
  })

  test('resolves relative node modules', async () => {
    const dir = await tmp.dir()
    const depDir = path.join(dir.path, 'node_modules', 'dep')

    const pathA = path.join(dir.path, 'a.ts')

    await fsExtra.mkdirp(depDir)

    await fsExtra.writeFile(
      pathA,
      `
    import { foo } from 'dep'
    export default foo
    `
    )

    await fsExtra.writeFile(
      path.join(depDir, 'index.js'),
      `
      exports.foo = 23
    `
    )

    expect(loadModule(pathA)).toEqual({ default: 23 })
  })

  test('resolves builtin modules', async () => {
    const dir = await tmp.dir()

    const pathA = path.join(dir.path, 'a.ts')

    await fsExtra.writeFile(
      pathA,
      `
    import path from 'path'
    import process from 'node:process'

    export default path.join(process.cwd(), 'a', 'b')
    `
    )

    expect(loadModule(pathA)).toEqual({
      default: path.join(process.cwd(), 'a', 'b'),
    })
  })

  test('supports injecting into the cache', async () => {
    const dir = await tmp.dir()

    const pathA = path.join(dir.path, 'a.ts')

    await fsExtra.writeFile(
      pathA,
      `
    import { foo } from 'dep'
    export default foo
    `
    )

    expect(
      loadModule(pathA, {
        cache: {
          dep: { foo: 23 },
        },
      })
    ).toEqual({ default: 23 })
  })

  test('supports custom require', async () => {
    const dir = await tmp.dir()

    const pathA = path.join(dir.path, 'a.ts')

    await fsExtra.writeFile(
      pathA,
      `
    import { foo } from 'dep'
    export default foo
    `
    )

    expect(
      loadModule(pathA, {
        require(name) {
          if (name === 'dep') {
            return { foo: 23 }
          }

          return null
        },
      })
    ).toEqual({ default: 23 })
  })

  test('works with cycles: esm named exports', async () => {
    const dir = await tmp.dir()

    const pathA = path.join(dir.path, 'a.js')
    const pathB = path.join(dir.path, 'b.js')
    const pathC = path.join(dir.path, 'c.js')

    await fsExtra.writeFile(
      pathA,
      `
      import { b } from './b'
      export default b()
    `
    )

    await fsExtra.writeFile(
      pathB,
      `
      import { c } from './c'

      export const b = (v) => v ?? c()
    `
    )

    await fsExtra.writeFile(
      pathC,
      `
      import { b } from './b'
      export const c = () => b(23)
    `
    )

    expect(loadModule(pathA)).toEqual({ default: 23 })
  })

  test('works with cycles: esm default exports', async () => {
    const dir = await tmp.dir()

    const pathA = path.join(dir.path, 'a.js')
    const pathB = path.join(dir.path, 'b.js')
    const pathC = path.join(dir.path, 'c.js')

    await fsExtra.writeFile(
      pathA,
      `
      import b from './b'
      export default b()
    `
    )

    await fsExtra.writeFile(
      pathB,
      `
      import c from './c'
      export default (v) => v ?? c()
    `
    )

    await fsExtra.writeFile(
      pathC,
      `
      import b from './b'
      export default () => b(23)
    `
    )

    expect(loadModule(pathA)).toEqual({ default: 23 })
  })

  test('works with cycles: commonjs named export', async () => {
    const dir = await tmp.dir()

    const pathA = path.join(dir.path, 'a.js')
    const pathB = path.join(dir.path, 'b.js')
    const pathC = path.join(dir.path, 'c.js')

    await fsExtra.writeFile(
      pathA,
      `
      import b from './b'
      export default b.b()
    `
    )

    await fsExtra.writeFile(
      pathB,
      `
      const c = require('./c')
      exports.b = (v) => v ?? c.c()
    `
    )

    await fsExtra.writeFile(
      pathC,
      `
      const b = require('./b')
      exports.c = () => b.b(23)
    `
    )

    expect(loadModule(pathA)).toEqual({ default: 23 })
  })
})
