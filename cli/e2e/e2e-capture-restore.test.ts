import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
} from '../src/testing/index.js'
import fsExtra from 'fs-extra'
import path from 'path'

vi.setConfig({
  testTimeout: 60_000,
})

describe('Snaplet CLI', () => {
  test('capturing and restoring of booleans', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      transform: {
        public: {
          User: ({ row }) => ({
            isNotCool: !row.isCool,
          })
        }
      }
    })`
    await fsExtra.writeFile(paths.snapletConfig, configContent)
    await execQueryNext(
      `CREATE TABLE "User" ("isCool" BOOLEAN, "isNotCool" BOOLEAN)`,
      sourceConnectionString
    )

    await execQueryNext(
      `INSERT INTO "User" VALUES (true, true)`,
      sourceConnectionString
    )

    const ssPath = createTestCapturePath()

    await runSnapletCLI(
      ['snapshot', 'capture', ssPath.name],
      {
        SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
      },
      paths
    )

    await runSnapletCLI(
      ['snapshot restore', ssPath.name],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const result = await execQueryNext(
      'select * from "User"',
      destinationConnectionString
    )

    expect(result.rows).toEqual([
      {
        isCool: true,
        isNotCool: false,
      },
    ])
  })

  test('capturing and restoring with `parseJson: false`', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      transform: {
        $parseJson: false,
        public: {
          User: () => ({}),
        },
      },
    })`
    await fsExtra.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `CREATE TABLE "User" ("value" Json)`,
      sourceConnectionString
    )

    await execQueryNext(
      `INSERT INTO "User" VALUES ('null')`,
      sourceConnectionString
    )

    const ssPath = createTestCapturePath()

    await runSnapletCLI(
      ['snapshot', 'capture', ssPath.name],
      {
        SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
      },
      paths
    )

    await runSnapletCLI(
      ['snapshot restore', ssPath.name],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const result = await execQueryNext(
      `select * from "User" where json_typeof(value) = 'null'`,
      destinationConnectionString
    )

    expect(result.rows).toEqual([
      {
        value: null,
      },
    ])
  })

  test('capturing and restoring of country phone number fields', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()
    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
    })`
    await fsExtra.writeFile(paths.snapletConfig, configContent)
    await execQueryNext(
      `CREATE TABLE IF NOT EXISTS public.country
        (
            country_name text COLLATE pg_catalog."default" NOT NULL,
            country_code text COLLATE pg_catalog."default" NOT NULL,
            country_phone_code text COLLATE pg_catalog."default" NOT NULL,
            CONSTRAINT country_pkey PRIMARY KEY (country_name)
        )`,
      sourceConnectionString
    )

    await execQueryNext(
      `insert into public.country(country_name, country_code, country_phone_code) values('United States', 'US', '+1');
         insert into public.country(country_name, country_code, country_phone_code) values('South Africa', 'ZA', '+27');`,
      sourceConnectionString
    )

    const ssPath = createTestCapturePath()

    await runSnapletCLI(
      ['snapshot', 'capture', ssPath.name],
      {
        SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
      },
      paths
    )

    await runSnapletCLI(
      ['snapshot restore', ssPath.name],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const result = await execQueryNext(
      "SELECT * FROM public.country WHERE country_name = 'United States';",
      destinationConnectionString
    )

    expect(result.rows).toEqual([
      {
        country_name: 'United States',
        country_code: 'US',
        country_phone_code: '+1',
      },
    ])
  })

  test('capturing and restoring of nested values', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      transform: {
        public: {
          Tmp: ({ row }) => ({
            text: [...row.text, ...row.text],
            int: [...row.int, ...row.int],
            tstzrange: row.tstzrange,
            tstzranges: [...row.tstzranges, ...row.tstzranges],
            tstzranges_unmodified: row.tstzranges_unmodified,
            json: { ...row.json, self: row.json},
            jsonb: { ...row.jsonb, self: row.jsonb},
            jsonb_array: [...row.jsonb_array, ...row.jsonb_array],
          })
        }
      },
    })`
    await fsExtra.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `CREATE TABLE "Tmp" (
           text text[][][],
           int int[][][],
           tstzrange tstzrange,
           tstzranges tstzrange[],
           tstzranges_unmodified tstzrange[],
           json json,
           jsonb jsonb,
           jsonb_array jsonb[][]
        )`,
      sourceConnectionString
    )

    await execQueryNext(
      `INSERT INTO "Tmp" VALUES (
          '{{{"a"}}}',
          '{{{2}}}',
          '[2010-01-01 14:00, 2010-01-01 15:00)',
          '{"[2010-01-01 14:00, 2010-01-01 15:00)"}',
          '{"[2010-01-01 14:00, 2010-01-01 15:00)"}',
          '{ "foo": [{ "bar": { "baz": 21 }}] }',
          '{ "foo": [{ "bar": { "baz": 23 }}] }',
          '{{"[1,null,\\"foo\\"]"}}'
        )`,
      sourceConnectionString
    )

    const ssPath = createTestCapturePath()
    await runSnapletCLI(
      ['snapshot', 'capture', ssPath.name],
      {
        SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
      },
      paths
    )

    const {
      rows: [sourceData],
    } = await execQueryNext<Record<string, any>>(
      'select * from "Tmp"',
      sourceConnectionString
    )

    await runSnapletCLI(
      ['snapshot restore', ssPath.name],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const result = await execQueryNext(
      'select * from "Tmp"',
      destinationConnectionString
    )

    expect(result.rows).toEqual([
      {
        text: [[['a']], [['a']]],
        int: [[[2]], [[2]]],
        tstzrange: sourceData.tstzrange,
        // context(justinvdm, 29 June 2022): node-postgres does not appear to parse
        // tstzrange[] as an array, and returns the result in string form.
        tstzranges: `{${[sourceData.tstzrange, sourceData.tstzrange].map((x) =>
          JSON.stringify(x)
        )}}`,
        // context(justinvdm, 29 June 2022): Above we're testing that we are able to work with tstzrange[] as an array
        // in the transform config with `tstzranges`, below that the value does in
        // fact remain unchanged if we don't change anything in the transform config (`tstzranges_unmodified`)
        tstzranges_unmodified: sourceData.tstzranges_unmodified,
        json: {
          foo: [{ bar: { baz: 21 } }],
          self: {
            foo: [{ bar: { baz: 21 } }],
          },
        },
        jsonb: {
          foo: [{ bar: { baz: 23 } }],
          self: {
            foo: [{ bar: { baz: 23 } }],
          },
        },
        jsonb_array: [[[1, null, 'foo']], [[1, null, 'foo']]],
      },
    ])
  })

  test('capturing and restoring of money columns', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      transform: {
        public: {
          Tmp: ({ row }) => ({
            value: row.value
          })
        }
      },
    })`
    await fsExtra.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `CREATE TABLE "Tmp" (
           value money
        )`,
      sourceConnectionString
    )

    await execQueryNext(
      `INSERT INTO "Tmp" VALUES ('23')`,
      sourceConnectionString
    )

    const ssPath = createTestCapturePath()
    await runSnapletCLI(
      ['snapshot', 'capture', ssPath.name],
      {
        SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
      },
      paths
    )

    await execQueryNext<Record<string, any>>(
      'select * from "Tmp"',
      sourceConnectionString
    )

    await runSnapletCLI(
      ['snapshot restore', ssPath.name],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const result = await execQueryNext(
      'select value as "valueStr", value::money::numeric::float8 from "Tmp"',
      destinationConnectionString
    )

    expect(result.rows).toEqual([
      {
        value: 23,
        valueStr: '$23.00',
      },
    ])
  })

  test('capturing and restoring of a partitioned table', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      select: {
        $default: false,
        public: {
          cities: true
        }
      },
      transform: {
        public: {
          cities: ({ row }) => ({
            name: \`Beautiful \${row.name}\`
          })
        }
      },
      subset: {
        targets: [
          {
            table: 'public.cities',
            percent: 50,
          },
        ],
      },
    })`
    await fsExtra.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `
      CREATE TABLE cities (
        city_id uuid NOT NULL,
        name text NOT NULL,
        population bigint
      )
      PARTITION BY LIST (left(lower(name), 1));

      CREATE TABLE cities_ab PARTITION OF cities
      FOR VALUES IN ('a', 'b');

      CREATE TABLE cities_cd PARTITION OF cities
      FOR VALUES IN ('c', 'd');

      CREATE TABLE cities_ef PARTITION OF cities
      FOR VALUES IN ('e', 'f');

      CREATE TABLE cities_gh PARTITION OF cities
      FOR VALUES IN ('g', 'h');

      INSERT INTO cities (city_id, name, population) VALUES
      ('123e4567-e89b-12d3-a456-426655440000', 'Amsterdam', 821752),
      ('123e4567-e89b-12d3-a456-426655440001', 'Berlin', 3644826),
      ('123e4567-e89b-12d3-a456-426655440002', 'Chicago', 2693976),
      ('123e4567-e89b-12d3-a456-426655440003', 'Dublin', 554554),
      ('123e4567-e89b-12d3-a456-426655440004', 'Edinburgh', 540272),
      ('123e4567-e89b-12d3-a456-426655440005', 'Frankfurt', 753056),
      ('123e4567-e89b-12d3-a456-426655440006', 'Geneva', 201818),
      ('123e4567-e89b-12d3-a456-426655440007', 'Hamburg', 1841179);
      `,
      sourceConnectionString
    )

    const ssPath = createTestCapturePath()
    await runSnapletCLI(
      ['snapshot', 'capture', ssPath.name],
      {
        SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
      },
      paths
    )

    await runSnapletCLI(
      ['snapshot restore', ssPath.name],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const result = await execQueryNext(
      'select * from "cities"',
      destinationConnectionString
    )

    expect(result.rows).toEqual([
      {
        city_id: '123e4567-e89b-12d3-a456-426655440000',
        name: 'Beautiful Amsterdam',
        population: '821752',
      },
      {
        city_id: '123e4567-e89b-12d3-a456-426655440001',
        name: 'Beautiful Berlin',
        population: '3644826',
      },
      {
        city_id: '123e4567-e89b-12d3-a456-426655440002',
        name: 'Beautiful Chicago',
        population: '2693976',
      },
      {
        city_id: '123e4567-e89b-12d3-a456-426655440003',
        name: 'Beautiful Dublin',
        population: '554554',
      },
    ])
  })

  test('capturing and restoring of a partitioned table without subsetting', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      select: {
        $default: false,
        public: {
          cities: true
        }
      },
      transform: {
        public: {
          cities: ({ row }) => ({
            name: \`Beautiful \${row.name}\`
          })
        }
      },
    })`
    await fsExtra.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `
      CREATE TABLE cities (
        city_id uuid NOT NULL,
        name text NOT NULL,
        population bigint
      )
      PARTITION BY LIST (left(lower(name), 1));

      CREATE TABLE cities_ab PARTITION OF cities
      FOR VALUES IN ('a', 'b');

      CREATE TABLE cities_cd PARTITION OF cities
      FOR VALUES IN ('c', 'd');

      CREATE TABLE cities_ef PARTITION OF cities
      FOR VALUES IN ('e', 'f');

      CREATE TABLE cities_gh PARTITION OF cities
      FOR VALUES IN ('g', 'h');

      INSERT INTO cities (city_id, name, population) VALUES
      ('123e4567-e89b-12d3-a456-426655440000', 'Amsterdam', 821752),
      ('123e4567-e89b-12d3-a456-426655440001', 'Berlin', 3644826),
      ('123e4567-e89b-12d3-a456-426655440002', 'Chicago', 2693976),
      ('123e4567-e89b-12d3-a456-426655440003', 'Dublin', 554554),
      ('123e4567-e89b-12d3-a456-426655440004', 'Edinburgh', 540272),
      ('123e4567-e89b-12d3-a456-426655440005', 'Frankfurt', 753056),
      ('123e4567-e89b-12d3-a456-426655440006', 'Geneva', 201818),
      ('123e4567-e89b-12d3-a456-426655440007', 'Hamburg', 1841179);
      `,
      sourceConnectionString
    )

    const ssPath = createTestCapturePath()
    await runSnapletCLI(
      ['snapshot', 'capture', ssPath.name],
      {
        SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
      },
      paths
    )

    await runSnapletCLI(
      ['snapshot restore', ssPath.name],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    const result = await execQueryNext(
      'select * from "cities"',
      destinationConnectionString
    )

    expect(result.rows).toEqual([
      {
        city_id: '123e4567-e89b-12d3-a456-426655440000',
        name: 'Beautiful Amsterdam',
        population: '821752',
      },
      {
        city_id: '123e4567-e89b-12d3-a456-426655440001',
        name: 'Beautiful Berlin',
        population: '3644826',
      },
      {
        city_id: '123e4567-e89b-12d3-a456-426655440002',
        name: 'Beautiful Chicago',
        population: '2693976',
      },
      {
        city_id: '123e4567-e89b-12d3-a456-426655440003',
        name: 'Beautiful Dublin',
        population: '554554',
      },
      {
        city_id: '123e4567-e89b-12d3-a456-426655440004',
        name: 'Beautiful Edinburgh',
        population: '540272',
      },
      {
        city_id: '123e4567-e89b-12d3-a456-426655440005',
        name: 'Beautiful Frankfurt',
        population: '753056',
      },
      {
        city_id: '123e4567-e89b-12d3-a456-426655440006',
        name: 'Beautiful Geneva',
        population: '201818',
      },
      {
        city_id: '123e4567-e89b-12d3-a456-426655440007',
        name: 'Beautiful Hamburg',
        population: '1841179',
      },
    ])
  })
  test('capturing and restoring with NULL values with no transform', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    await execQueryNext(
      `
      CREATE TABLE cities (
        id SERIAL primary key,
        metadata jsonb
      );

      INSERT INTO cities (metadata) VALUES
      (NULL), -- sql NULL
      ('null'), -- jsonb null
      ('"null"'), -- jsonb string "null"
      ('[[null]]'), -- jsonb array containing a jsonb null [[null]]
      ('{"foo": "null"}'); -- jsonb object containing a jsonb string "null"
      `,
      sourceConnectionString
    )

    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      select: {
        $default: false,
        public: {
          cities: true
        }
      },
    })`
    await fsExtra.writeFile(paths.snapletConfig, configContent)

    const ssPath = createTestCapturePath()
    await runSnapletCLI(
      ['snapshot', 'capture', ssPath.name],
      {
        SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
      },
      paths
    )

    expect(
      await fsExtra.readFile(
        path.join(ssPath.name, 'tables/public.cities.csv'),
        'utf-8'
      )
    ).toEqual(`id,metadata
1,
2,null
3,"""null"""
4,[[null]]
5,"{""foo"":""null""}"
`)

    await runSnapletCLI(
      ['snapshot restore', ssPath.name],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    // we cast metadata to text to avoid pg client to parse the jsonb null to js null
    const result = await execQueryNext(
      'select id, metadata::text from "cities"',
      destinationConnectionString
    )

    expect(result.rows).toEqual([
      {
        id: 1,
        metadata: null,
      },
      {
        id: 2,
        metadata: 'null',
      },
      {
        id: 3,
        metadata: '"null"',
      },
      {
        id: 4,
        metadata: '[[null]]',
      },
      {
        id: 5,
        metadata: '{"foo": "null"}',
      },
    ])
  })

  test('capturing and restoring with NULL values with transform', async () => {
    const sourceConnectionString = await createTestDb()
    const destinationConnectionString = await createTestDb()

    await execQueryNext(
      `
      CREATE TABLE cities (
        id SERIAL primary key,
        metadata jsonb
      );

      INSERT INTO cities (metadata) VALUES
      ('{"foo": "null"}'); -- jsonb object containing a jsonb string "null"
      `,
      sourceConnectionString
    )

    const paths = await createTestProjectDirV2()
    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig, jsonNull } from "snaplet";

    export default defineConfig({
      select: {
        $default: false,
        public: {
          cities: true
        }
      },
      transform: {
        public: {
          cities: {
            // we use jsonNull to explicitly set the column to jsonb null instead of db NULL
            metadata: jsonNull
          },
        }
      },
    })`
    await fsExtra.writeFile(paths.snapletConfig, configContent)

    const ssPath = createTestCapturePath()
    await runSnapletCLI(
      ['snapshot', 'capture', ssPath.name],
      {
        SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
      },
      paths
    )

    expect(
      await fsExtra.readFile(
        path.join(ssPath.name, 'tables/public.cities.csv'),
        'utf-8'
      )
    ).toEqual(`id,metadata
1,null
`)

    await runSnapletCLI(
      ['snapshot restore', ssPath.name],
      {
        SNAPLET_TARGET_DATABASE_URL: destinationConnectionString.toString(),
      },
      paths
    )

    // we cast metadata to text to avoid pg client to parse the jsonb null to js null
    const result = await execQueryNext(
      'select id, metadata::text from "cities"',
      destinationConnectionString
    )

    expect(result.rows).toEqual([
      {
        id: 1,
        metadata: 'null',
      },
    ])
  })
})
