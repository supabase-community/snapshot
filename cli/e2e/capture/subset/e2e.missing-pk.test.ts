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

test('should work with a table with no primary key as entrypoint', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Create a table with multiple data types and the custom type
  await execQueryNext(
    `CREATE TABLE no_pk_table
    (
        value text,
        bool_col BOOLEAN
    );
  `,
    sourceConnectionString
  )

  // Insert three rows into the table
  await execQueryNext(
    `INSERT INTO no_pk_table (value, bool_col)
           VALUES ('abcde', true);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO no_pk_table (value, bool_col)
           VALUES ('fghijkl', false);`,
    sourceConnectionString
  )

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.no_pk_table',
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
    'SELECT * FROM no_pk_table',
    destinationConnectionString
  )
  expect(result.rowCount).toBe(2)
})
test('should work with table without primary keys as relation', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  await execQueryNext(
    `
          CREATE TABLE entrypoint (
            id SERIAL PRIMARY KEY,
            value text
          );
          CREATE TABLE no_pk_table
            (
                entrypoint_id integer REFERENCES entrypoint(id),
                value text,
                bool_col BOOLEAN
            );
          `,
    sourceConnectionString
  )

  await execQueryNext(
    `
          INSERT INTO entrypoint (value) VALUES ('abcde');
          INSERT INTO no_pk_table (entrypoint_id, value, bool_col)
           VALUES (1, 'abcde', true);
          INSERT INTO no_pk_table (entrypoint_id, value, bool_col)
           VALUES (1, 'efghi', false);
          INSERT INTO no_pk_table (entrypoint_id, value, bool_col)
           VALUES (NULL, 'hijkl', false);`,
    sourceConnectionString
  )

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.entrypoint',
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
    'SELECT * FROM no_pk_table',
    destinationConnectionString
  )
  expect(result.rowCount).toBe(2)
})
test('should work with a table with no primary key but a non nullable unique column as relation', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  await execQueryNext(
    `
          CREATE TABLE entrypoint (
            id SERIAL PRIMARY KEY,
            value text
          );
          CREATE TABLE no_pk_table
            (
                entrypoint_id integer REFERENCES entrypoint(id),
                value text UNIQUE NOT NULL,
                bool_col BOOLEAN
            );
          `,
    sourceConnectionString
  )

  await execQueryNext(
    `
          INSERT INTO entrypoint (value) VALUES ('abcde');
          INSERT INTO no_pk_table (entrypoint_id, value, bool_col)
           VALUES (1, 'abcde', true);
          INSERT INTO no_pk_table (entrypoint_id, value, bool_col)
           VALUES (1, 'efghi', false);
          INSERT INTO no_pk_table (entrypoint_id, value, bool_col)
           VALUES (NULL, 'hijkl', false);`,
    sourceConnectionString
  )

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.entrypoint',
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
    'SELECT * FROM no_pk_table',
    destinationConnectionString
  )
  expect(result.rowCount).toBe(2)
})
test('should work with a table with no primary key but a non nullable unique column as entrypoint', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Create a table with multiple data types and the custom type
  await execQueryNext(
    `CREATE TABLE no_pk_table
    (
        value text UNIQUE NOT NULL,
        bool_col BOOLEAN
    );
  `,
    sourceConnectionString
  )

  // Insert three rows into the table
  await execQueryNext(
    `INSERT INTO no_pk_table (value, bool_col)
           VALUES ('abcde', true);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO no_pk_table (value, bool_col)
           VALUES ('fghijkl', false);`,
    sourceConnectionString
  )

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.no_pk_table',
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
    'SELECT * FROM no_pk_table',
    destinationConnectionString
  )
  expect(result.rowCount).toBe(2)
})
test('should work with a table with no primary key but a unique index column as entrypoint', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Create a table with multiple data types and the custom type
  await execQueryNext(
    `CREATE TABLE no_pk_table
    (
        value text,
        bool_col BOOLEAN
    );
    CREATE UNIQUE INDEX idx_no_pk_table_value ON no_pk_table(value);
  `,
    sourceConnectionString
  )

  // Insert three rows into the table
  await execQueryNext(
    `INSERT INTO no_pk_table (value, bool_col)
           VALUES ('abcde', true);`,
    sourceConnectionString
  )
  await execQueryNext(
    `INSERT INTO no_pk_table (value, bool_col)
           VALUES ('fghijkl', false);`,
    sourceConnectionString
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.no_pk_table',
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
    'SELECT * FROM no_pk_table',
    destinationConnectionString
  )
  expect(result.rowCount).toBe(2)
})
test('should work with a table with no primary key but a unique index column as relation', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Create a table with multiple data types and the custom type
  await execQueryNext(
    `
    CREATE TABLE entrypoint (
      id SERIAL PRIMARY KEY,
      value text
    );
    CREATE TABLE no_pk_table
      (
          entrypoint_id integer REFERENCES entrypoint(id),
          value text,
          bool_col BOOLEAN
      );
      CREATE UNIQUE INDEX idx_no_pk_table_value ON no_pk_table(value);
    `,
    sourceConnectionString
  )

  // Insert three rows into the table no_pk
  await execQueryNext(
    `
          INSERT INTO entrypoint (value) VALUES ('abcde');
          INSERT INTO no_pk_table (entrypoint_id, value, bool_col)
           VALUES (1, 'abcde', true);
          INSERT INTO no_pk_table (entrypoint_id, value, bool_col)
           VALUES (1, 'efghi', false);
          INSERT INTO no_pk_table (entrypoint_id, value, bool_col)
           VALUES (NULL, 'hijkl', false);`,
    sourceConnectionString
  )

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.entrypoint',
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
    'SELECT * FROM no_pk_table',
    destinationConnectionString
  )
  expect(result.rowCount).toBe(2)
})
test('should work with a table with no primary key and null values in some columns', async () => {
  const sourceConnectionString = await createTestDb()
  const destinationConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Create a table with multiple data types and the custom type
  await execQueryNext(
    `
      CREATE TABLE entrypoint (
        id text,
        value text
      );
      CREATE UNIQUE INDEX idx_entrypoint
        ON public.entrypoint USING btree
        (id COLLATE pg_catalog."default" ASC NULLS LAST)
      TABLESPACE pg_default;
      CREATE TABLE no_pk_table (
        entrypoint_id text,
        CONSTRAINT nopktable_entrypointid_fkey FOREIGN KEY (entrypoint_id)
            REFERENCES public.entrypoint (id) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION
      );
    `,
    sourceConnectionString
  )

  // Insert three rows into the table no_pk
  await execQueryNext(
    `
      INSERT INTO entrypoint (id, value) VALUES ('a', 'a');
      INSERT INTO entrypoint (id, value) VALUES ('b', 'b');
      INSERT INTO entrypoint (id, value) VALUES ('c', 'c');
      INSERT INTO entrypoint (id, value) VALUES ('d', 'd');
      INSERT INTO entrypoint (id, value) VALUES ('e', 'e');
      INSERT INTO entrypoint (id, value) VALUES (NULL, NULL);
      INSERT INTO entrypoint (id, value) VALUES ('f', NULL);
      INSERT INTO entrypoint (id, value) VALUES (NULL, 'g');
      INSERT INTO no_pk_table (entrypoint_id) VALUES (NULL);
      INSERT INTO no_pk_table (entrypoint_id) VALUES ('f');
      INSERT INTO no_pk_table (entrypoint_id) VALUES ('a');
    `,
    sourceConnectionString
  )

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      eager: true,
      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.no_pk_table',
          where: "no_pk_table.entrypoint_id IN ('f', 'a') OR no_pk_table.entrypoint_id IS NULL",
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
  const resultNoPk = await execQueryNext(
    'SELECT * FROM no_pk_table',
    destinationConnectionString
  )
  const resultEntrypoint = await execQueryNext(
    'SELECT * FROM entrypoint',
    destinationConnectionString
  )
  expect(resultNoPk.rowCount).toBe(3)
  expect(resultEntrypoint.rowCount).toBe(4)
  expect(resultNoPk.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({ entrypoint_id: null }),
      expect.objectContaining({ entrypoint_id: 'f' }),
      expect.objectContaining({ entrypoint_id: 'a' }),
    ])
  )
  expect(resultEntrypoint.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({ id: null, value: null }),
      expect.objectContaining({ id: null, value: 'g' }),
      expect.objectContaining({ id: 'f' }),
      expect.objectContaining({ id: 'a' }),
    ])
  )
})
