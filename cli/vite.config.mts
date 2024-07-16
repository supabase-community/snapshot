import tsconfigPaths from 'vite-tsconfig-paths'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  plugins: [
    tsconfigPaths({
      ignoreConfigErrors: true,
    }),
  ],
  resolve: {
    conditions: ['snaplet_development'],
  },
  test: {
    reporters: ['basic'],
    globals: true,
    globalSetup: ['./src/testing/globalSetup.ts'],
  },
})
