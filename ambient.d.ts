import type { TimeFormat } from '@snaplet/sdk/src/config/systemConfig/systemConfig.js'

// context(peterp, 25 May 2022): This file is only reference by SDK and CLI.
declare global {
  namespace NodeJS {
    interface ProcessEnv {
      NODE_ENV?: string

      SNAPLET_ACCESS_TOKEN?: string
      SNAPLET_PROJECT_ID?: string
      SNAPLET_SNAPSHOT_ID?: string
      SNAPLET_SOURCE_DATABASE_URL?: string
      SNAPLET_TARGET_DATABASE_URL?: string
      SNAPLET_EXEC_TASK_ID?: string

      /**
       * A connection string created from the `PG*` envars, and is used by
       * `snaplet setup` as the default credentials.
       **/
      PGENV_CONNECTION_URL?: string

      /**
       * The CWD is an alias of `process.cwd()` in the ordinary runtime,
       * but can be overwritten during tests.
       */
      SNAPLET_CWD?: string
      SNAPLET_CONFIG?: string

      /**
       * The user's home directory, via `os.homedir()`,
       * but can be overwritten during tests.
       */
      SNAPLET_OS_HOMEDIR?: string
      SNAPLET_HOSTNAME?: string
      SNAPLET_API_HOSTNAME?: string

      /**
       * Controls whether we display last update date and time as relative.
       */
      SNAPLET_TIME_FORMAT?: TimeFormat
    }
  }
}

export {}
