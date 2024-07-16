import { execQueryNext } from '@snaplet/sdk/cli'

import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
} from '../../../src/testing/index.js'
import fsExtra from 'fs-extra'

vi.setConfig({
  testTimeout: 60_000,
})

test('ensuring data safety with multiple data types and a custom type', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Create a custom type
  await execQueryNext(
    `CREATE TYPE mood AS ENUM ('sad', 'ok', 'happy');`,
    sourceConnectionString
  )

  // Create a table with multiple data types and the custom type
  await execQueryNext(
    `CREATE TABLE complex_data
            (
                id SERIAL PRIMARY KEY,
                bool_col BOOLEAN,
                char_col CHAR(5),
                varchar_col VARCHAR(255),
                text_col TEXT,
                smallint_col SMALLINT,
                integer_col INTEGER,
                bigint_col BIGINT,
                real_col REAL,
                double_col DOUBLE PRECISION,
                numeric_col NUMERIC(10, 2),
                date_col DATE,
                time_col TIME,
                timestamp_col TIMESTAMP,
                timestamptz_col TIMESTAMPTZ,
                interval_col INTERVAL,
                uuid_col UUID,
                json_col JSON,
                jsonb_col JSONB,
                mood_col mood
            );`,
    sourceConnectionString
  )

  // Insert two rows into the table
  await execQueryNext(
    `INSERT INTO complex_data (bool_col, char_col, varchar_col, text_col, smallint_col, integer_col, bigint_col, real_col, double_col, numeric_col, date_col, time_col, timestamp_col, timestamptz_col, interval_col, uuid_col, json_col, jsonb_col, mood_col)
           VALUES (true, 'abcde', 'Hello, world!', 'This is a text column.', 42, 2147483647, 9223372036854700000, 3.14, 3.1415926535, 12345.67, '2023-04-14', '12:34:56', '2023-04-14 12:34:56', '2023-04-14 12:34:56+00', '1 day', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '{"key": "value"}', '{"key": "value"}', 'happy');`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO complex_data (bool_col, char_col, varchar_col, text_col, smallint_col, integer_col, bigint_col, real_col, double_col, numeric_col, date_col, time_col, timestamp_col, timestamptz_col, interval_col, uuid_col, json_col, jsonb_col, mood_col)
           VALUES (false, 'fghij', 'Another string', 'Another text column.', -42, -2147483647, -9223372036854700000, 42.00, 42.0000000000, 67890.12, '2023-04-13', '23:45:01', '2023-04-13 23:45:01', '2023-04-13 23:45:01+00', '2 days', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', '{"key": "another_value"}', '{"key": "another_value"}', 'sad');`,
    sourceConnectionString
  )

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      targets: [
        {
          table: 'public.complex_data',
          percent: 100,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(['snapshot', 'capture', ssPath.name], {
    SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
  })

  await runSnapletCLI(['snapshot restore', ssPath.name], {
    SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
  })
  const result = await execQueryNext(
    'SELECT * FROM complex_data',
    destinationConnectionString
  )
  expect(result.rowCount).toBe(2)
})
test('ensuring data safety with multiple data types as tables primary keys', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Create a custom type
  await execQueryNext(
    `CREATE TYPE mood AS ENUM ('sad', 'ok', 'happy');`,
    sourceConnectionString
  )
  const possiblesPrimaryKeysType = {
    BOOLEAN: {
      value: true,
    },
    'CHAR(5)': {
      value: 'abcde',
    },
    'VARCHAR(255)': {
      value: 'Hello, world!',
    },
    TEXT: {
      value: 'This is a text column.',
    },
    SMALLINT: {
      value: 42,
    },
    INTEGER: {
      value: 2147483647,
    },
    BIGINT: {
      value: 9223372036854700000,
    },
    REAL: {
      value: 3.14,
    },
    'DOUBLE PRECISION': {
      value: 3.1415926535,
    },
    'NUMERIC(10, 2)': {
      value: 12345.67,
    },
    DATE: {
      value: '2023-04-14',
    },
    TIME: {
      value: '12:34:56',
    },
    TIMESTAMP: {
      value: '2023-04-14 12:34:56',
    },
    TIMESTAMPTZ: {
      value: '2023-04-14 12:34:56+00',
    },
    INTERVAL: {
      value: '1 day',
    },
    UUID: {
      value: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    },
    JSONB: {
      value: '{"key": "value"}',
    },
    mood: {
      value: 'happy',
    },
  }
  const createTablesQueries = Object.keys(possiblesPrimaryKeysType).map(
    (type) => {
      return `CREATE TABLE "table_primary_key_${type}" (id ${type} PRIMARY KEY);`
    }
  )
  const insertDataQueries = Object.keys(possiblesPrimaryKeysType).map(
    (type) => {
      //@ts-expect-error
      return `INSERT INTO "table_primary_key_${type}" (id) VALUES ('${possiblesPrimaryKeysType[type].value}');`
    }
  )
  const subetTargets = Object.keys(possiblesPrimaryKeysType).map((type) => {
    return {
      table: `public.table_primary_key_${type}`,
      percent: 100,
    }
  })
  await execQueryNext(createTablesQueries.join('\n'), sourceConnectionString)
  await execQueryNext(insertDataQueries.join('\n'), sourceConnectionString)

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      targets: ${JSON.stringify(subetTargets)},
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(['snapshot', 'capture', ssPath.name], {
    SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
  })

  await runSnapletCLI(['snapshot restore', ssPath.name], {
    SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
  })
  const tableResults = await Promise.all(
    Object.keys(possiblesPrimaryKeysType).map((type) =>
      execQueryNext(
        `SELECT * FROM "table_primary_key_${type}"`,
        destinationConnectionString
      )
    )
  )
  const rowsCount = tableResults.map((result) => result.rowCount)
  expect(rowsCount.every((count) => count === 1)).toBe(true)
})
test('ensuring data safety with relations multiple data types as tables primary keys', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Create a custom type
  await execQueryNext(
    `CREATE TYPE mood AS ENUM ('sad', 'ok', 'happy');`,
    sourceConnectionString
  )
  const possiblesPrimaryKeysType = {
    BOOLEAN: {
      value: true,
    },
    'CHAR(5)': {
      value: 'abcde',
    },
    'VARCHAR(255)': {
      value: 'Hello, world!',
    },
    TEXT: {
      value: 'This is a text column.',
    },
    SMALLINT: {
      value: 42,
    },
    INTEGER: {
      value: 2147483647,
    },
    BIGINT: {
      value: 9223372036854700000,
    },
    REAL: {
      value: 3.14,
    },
    'DOUBLE PRECISION': {
      value: 3.1415926535,
    },
    'NUMERIC(10, 2)': {
      value: 12345.67,
    },
    DATE: {
      value: '2023-04-14',
    },
    TIME: {
      value: '12:34:56',
    },
    TIMESTAMP: {
      value: '2023-04-14 12:34:56',
    },
    TIMESTAMPTZ: {
      value: '2023-04-14 12:34:56+00',
    },
    INTERVAL: {
      value: '1 day',
    },
    UUID: {
      value: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    },
    JSONB: {
      value: '{"key": "value"}',
    },
    mood: {
      value: 'happy',
    },
  }
  const createTablesQueries = Object.keys(possiblesPrimaryKeysType).map(
    (type) => {
      return `CREATE TABLE "table_primary_key_${type}" (id ${type} PRIMARY KEY);`
    }
  )
  const insertDataQueries = Object.keys(possiblesPrimaryKeysType).map(
    (type) => {
      //@ts-expect-error
      return `INSERT INTO "table_primary_key_${type}" (id) VALUES ('${possiblesPrimaryKeysType[type].value}');`
    }
  )
  await execQueryNext(createTablesQueries.join('\n'), sourceConnectionString)
  await execQueryNext(insertDataQueries.join('\n'), sourceConnectionString)
  // Now we create a table which will have foreign keys to all the tables we just created
  await execQueryNext(
    `CREATE TABLE "table_with_foreign_keys" (
          id SERIAL PRIMARY KEY,
          ${Object.keys(possiblesPrimaryKeysType)
            .map(
              (type) =>
                `"fk_${type}" ${type} REFERENCES "table_primary_key_${type}"(id)`
            )
            .join(',\n')}
        );`,
    sourceConnectionString
  )
  // Insert some data into the table
  await execQueryNext(
    `INSERT INTO "table_with_foreign_keys" (${Object.keys(
      possiblesPrimaryKeysType
    )
      .map((type) => `"fk_${type}"`)
      .join(',')})
          VALUES (${Object.keys(possiblesPrimaryKeysType)
            //@ts-expect-error
            .map((type) => `'${possiblesPrimaryKeysType[type].value}'`)
            .join(',')});`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO "table_with_foreign_keys" (${Object.keys(
      possiblesPrimaryKeysType
    )
      .map((type) => `"fk_${type}"`)
      .join(',')})
          VALUES (${Object.keys(possiblesPrimaryKeysType)
            //@ts-expect-error
            .map((type) => `'${possiblesPrimaryKeysType[type].value}'`)
            .join(',')});`,
    sourceConnectionString
  )

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      targets: [
        {
          table: 'public.table_with_foreign_keys',
          percent: 100,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(['snapshot', 'capture', ssPath.name], {
    SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
  })

  await runSnapletCLI(['snapshot restore', ssPath.name], {
    SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
  })
  const result = await execQueryNext(
    `SELECT * FROM "table_with_foreign_keys"`,
    destinationConnectionString
  )
  expect(result.rowCount).toBe(2)
})
