import dotenv from 'dotenv-defaults'
import path from 'path'
import tsconfigPaths from 'vite-tsconfig-paths'
import { defineConfig } from 'vitest/config'

dotenv.config({
  defaults: path.resolve(__dirname, '../../.env.defaults'),
})

export default defineConfig({
  plugins: [tsconfigPaths({ ignoreConfigErrors: true })],
  resolve: {
    conditions: ['snaplet_development']
  },
  test: {
    globals: true,
    globalSetup: ['./src/testing/globalSetup.ts'],
  },
})
