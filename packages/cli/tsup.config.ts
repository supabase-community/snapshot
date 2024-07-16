import { Options, defineConfig } from 'tsup'
import { replace } from 'esbuild-plugin-replace'

const base: Options = {
  outDir: 'dist',
  bundle: true,
  platform: 'node',
  clean: true,
  dts: true,
  sourcemap: true,
  env: {
    NODE_ENV: process.env.NODE_ENV ?? 'development',
  },
  esbuildPlugins: [
    // context(justinvdm, 21 June 2023): Ideally we could use esbuild's alias feature,
    // but this won't work for commonjs outputs
    replace({
      'pg-protocol/': 'pg-protocol/dist/',
    }),
  ],
  outExtension({ format }) {
    return {
      js: {
        cjs: '.cjs',
        esm: '.mjs',
      }[format],
    }
  },
}

export default defineConfig([
  {
    ...base,
    // NOTE(justinvdm, 20 June 2023): The esm output will be broken for any cli and sdk re-exports
    // until we have esm outputs for those packages.
    format: ['cjs', 'esm'],
    entry: ['./src/index.ts'],
  },
  {
    ...base,
    format: ['cjs'],
    entry: ['./src/cli.ts'],
  },
])
