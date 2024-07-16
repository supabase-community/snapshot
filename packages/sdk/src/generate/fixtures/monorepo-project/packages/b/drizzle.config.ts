// @ts-expect-error - this is a fixture
import type { Config } from 'drizzle-kit'

export default {
  schema: './schema.ts',
  driver: 'pg',
  dbCredentials: {
    connectionString: process.env.DB_URL,
  },
} satisfies Config
