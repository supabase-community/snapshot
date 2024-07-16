import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestProjectDirV2,
  runSnapletCLI,
} from '../../src/testing/index.js'
import fs from 'fs-extra'

vi.setConfig({
  testTimeout: 60_0000,
})

describe('Config errors tests', () => {
  test('syntax error with undeclared variable', async () => {
    const sourceConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    m;
    export default defineConfig({
      select: {
        schema1: false
      }
    })`

    await fs.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `
      -- Creating schema1 and schema2
      create schema schema1;
      create schema schema2;

      -- Creating table1 in schema1 with a primary key
      create table schema1.table1 (
          id int primary key,
          name varchar(255)
      );
      -- Creating table2 in schema2 with a foreign key referencing table1 in schema1
      create table schema2.table2 (
          id int primary key,
          "table1_id" int,
          description varchar(255),
          foreign key ("table1_id") references schema1.table1(id)
      );
      `,
      sourceConnectionString
    )
    await execQueryNext(
      `-- Inserting data into table1 in schema1
      insert into schema1.table1 (id, name)
      values
      (1, 'John Doe'),
      (2, 'Jane Smith'),
      (3, 'Mike Johnson');

      -- Inserting data into table2 in schema2
      insert into schema2.table2 (id, "table1_id", description)
      values
      (1, 1, 'Description for record 1'),
      (2, 2, 'Description for record 2'),
      (3, 3, 'Description for record 3');
      `,
      sourceConnectionString
    )

    await expect(
      runSnapletCLI(
        [
          'config',
          'generate',
          `--connection-string=${sourceConnectionString.toString()}`,
        ],
        {},
        paths
      )
    ).rejects.toThrow(`Failed to execute config file: ${paths.snapletConfig}:
m is not defined
  4 |
> 5 |     m;
    |     ^ m is not defined
  6 |     export default defineConfig({`)
  })
  test('syntax error call to a non function', async () => {
    const sourceConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    const titi = 42;
    titi();
    export default defineConfig({
      select: {
        schema1: false
      },
      transform: {
        schema2: {
          table2: (row) => ({
            ...row,
            fifi,
          }),
        }
      }
    })`

    await fs.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `
      -- Creating schema1 and schema2
      create schema schema1;
      create schema schema2;

      -- Creating table1 in schema1 with a primary key
      create table schema1.table1 (
          id int primary key,
          name varchar(255)
      );
      -- Creating table2 in schema2 with a foreign key referencing table1 in schema1
      create table schema2.table2 (
          id int primary key,
          "table1_id" int,
          description varchar(255),
          foreign key ("table1_id") references schema1.table1(id)
      );
      `,
      sourceConnectionString
    )
    await execQueryNext(
      `-- Inserting data into table1 in schema1
      insert into schema1.table1 (id, name)
      values
      (1, 'John Doe'),
      (2, 'Jane Smith'),
      (3, 'Mike Johnson');

      -- Inserting data into table2 in schema2
      insert into schema2.table2 (id, "table1_id", description)
      values
      (1, 1, 'Description for record 1'),
      (2, 2, 'Description for record 2'),
      (3, 3, 'Description for record 3');
      `,
      sourceConnectionString
    )

    await expect(
      runSnapletCLI(
        [
          'config',
          'generate',
          `--connection-string=${sourceConnectionString.toString()}`,
        ],
        {},
        paths
      )
    ).rejects.toThrow(`Failed to execute config file: ${paths.snapletConfig}:
titi is not a function
  5 |     const titi = 42;
> 6 |     titi();
    |    ^ titi is not a function
  7 |     export default defineConfig({`)
  })
  test('syntax error invalid transform declaration', async () => {
    const sourceConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      select: {
        schema1: false
      },
      transform: {
        schema2: {
          table2: (row) => {
            ...row,
            fifi,
          },
        }
      }
    })`

    await fs.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `
      -- Creating schema1 and schema2
      create schema schema1;
      create schema schema2;

      -- Creating table1 in schema1 with a primary key
      create table schema1.table1 (
          id int primary key,
          name varchar(255)
      );
      -- Creating table2 in schema2 with a foreign key referencing table1 in schema1
      create table schema2.table2 (
          id int primary key,
          "table1_id" int,
          description varchar(255),
          foreign key ("table1_id") references schema1.table1(id)
      );
      `,
      sourceConnectionString
    )
    await execQueryNext(
      `-- Inserting data into table1 in schema1
      insert into schema1.table1 (id, name)
      values
      (1, 'John Doe'),
      (2, 'Jane Smith'),
      (3, 'Mike Johnson');

      -- Inserting data into table2 in schema2
      insert into schema2.table2 (id, "table1_id", description)
      values
      (1, 1, 'Description for record 1'),
      (2, 2, 'Description for record 2'),
      (3, 3, 'Description for record 3');
      `,
      sourceConnectionString
    )

    await expect(
      runSnapletCLI(
        [
          'config',
          'generate',
          `--connection-string=${sourceConnectionString.toString()}`,
        ],
        {},
        paths
      )
    ).rejects.toThrow(`Failed to compile config file: ${paths.snapletConfig}
  11 |           table2: (row) => {
> 12 |             ...row,
     |            ^ UnexpectedToken
  13 |             fifi,`)
  })
  // TODO: change this behaviour so we can prevent errors within a transform declaration
  test('cannot prevent error within a transform declaration', async () => {
    const sourceConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      select: {
        schema1: false
      },
      transform: {
        schema2: {
          table2: (row) => {
            nonExistentFunction();
            return {
              ...row,
            }
          },
        }
      }
    })`

    await fs.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `
      -- Creating schema1 and schema2
      create schema schema1;
      create schema schema2;

      -- Creating table1 in schema1 with a primary key
      create table schema1.table1 (
          id int primary key,
          name varchar(255)
      );
      -- Creating table2 in schema2 with a foreign key referencing table1 in schema1
      create table schema2.table2 (
          id int primary key,
          "table1_id" int,
          description varchar(255),
          foreign key ("table1_id") references schema1.table1(id)
      );
      `,
      sourceConnectionString
    )
    await execQueryNext(
      `-- Inserting data into table1 in schema1
      insert into schema1.table1 (id, name)
      values
      (1, 'John Doe'),
      (2, 'Jane Smith'),
      (3, 'Mike Johnson');

      -- Inserting data into table2 in schema2
      insert into schema2.table2 (id, "table1_id", description)
      values
      (1, 1, 'Description for record 1'),
      (2, 2, 'Description for record 2'),
      (3, 3, 'Description for record 3');
      `,
      sourceConnectionString
    )

    await expect(
      runSnapletCLI(
        [
          'config',
          'generate',
          `--connection-string=${sourceConnectionString.toString()}`,
        ],
        {},
        paths
      )
    ).resolves.not.toThrow()
  })
  test('parse error with a invalid value for the select', async () => {
    const sourceConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      select: {
        $default: "yolo",
        schema1: "nope",
        schema2: false,
        schema3: {
          $default: "nope",
          table1: false,
          table2: "nope",
          $extensions: false,
        },
        schema4: {
          $extensions: false,
        },
        shema5: {
          $default: false,
          $extensions: {
            extensionName: 'okdos',
          },
        },
        schema6: true,
      },
    })`

    await fs.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `
      -- Creating schema1 and schema2
      create schema schema1;
      create schema schema2;

      -- Creating table1 in schema1 with a primary key
      create table schema1.table1 (
          id int primary key,
          name varchar(255)
      );
      -- Creating table2 in schema2 with a foreign key referencing table1 in schema1
      create table schema2.table2 (
          id int primary key,
          "table1_id" int,
          description varchar(255),
          foreign key ("table1_id") references schema1.table1(id)
      );
      `,
      sourceConnectionString
    )
    await execQueryNext(
      `-- Inserting data into table1 in schema1
      insert into schema1.table1 (id, name)
      values
      (1, 'John Doe'),
      (2, 'Jane Smith'),
      (3, 'Mike Johnson');

      -- Inserting data into table2 in schema2
      insert into schema2.table2 (id, "table1_id", description)
      values
      (1, 1, 'Description for record 1'),
      (2, 2, 'Description for record 2'),
      (3, 3, 'Description for record 3');
      `,
      sourceConnectionString
    )

    await expect(
      runSnapletCLI(
        [
          'config',
          'generate',
          `--connection-string=${sourceConnectionString.toString()}`,
        ],
        {},
        paths
      )
    ).rejects.toThrow(`Failed to parse config file: ${paths.snapletConfig}
Expected boolean | "structure" at "select.$default" and
Expected boolean | { "<tableName>": SelectTableConfig } at "select.schema1" and
Expected boolean | "structure" at "select.schema3.$default" and
Expected boolean at "select.shema5.$extensions.extensionName"`)
  })
  test('parse error with a invalid transform options', async () => {
    const sourceConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      transform: {
        $mode: 'toto',
        $parseJson: 'tata',
      }
    })`

    await fs.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `
      -- Creating schema1 and schema2
      create schema schema1;
      create schema schema2;

      -- Creating table1 in schema1 with a primary key
      create table schema1.table1 (
          id int primary key,
          name varchar(255)
      );
      -- Creating table2 in schema2 with a foreign key referencing table1 in schema1
      create table schema2.table2 (
          id int primary key,
          "table1_id" int,
          description varchar(255),
          foreign key ("table1_id") references schema1.table1(id)
      );
      `,
      sourceConnectionString
    )
    await execQueryNext(
      `-- Inserting data into table1 in schema1
      insert into schema1.table1 (id, name)
      values
      (1, 'John Doe'),
      (2, 'Jane Smith'),
      (3, 'Mike Johnson');

      -- Inserting data into table2 in schema2
      insert into schema2.table2 (id, "table1_id", description)
      values
      (1, 1, 'Description for record 1'),
      (2, 2, 'Description for record 2'),
      (3, 3, 'Description for record 3');
      `,
      sourceConnectionString
    )

    await expect(
      runSnapletCLI(
        [
          'config',
          'generate',
          `--connection-string=${sourceConnectionString.toString()}`,
        ],
        {},
        paths
      )
    ).rejects.toThrow(`Failed to parse config file: ${paths.snapletConfig}
Invalid literal value, expected "auto" at "$mode" or Invalid literal value, expected "strict" at "$mode" or Invalid literal value, expected "unsafe" at "$mode" and
Expected boolean, received string at "$parseJson"`)
  })
  test('parse error with a invalid transformations', async () => {
    const sourceConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      transform: {
        schema1: {
          table1: (row) => ({
            ...row,
          }),
          table2: {},
          table3: "invalid"
        },
      }
    })`

    await fs.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `
      -- Creating schema1 and schema2
      create schema schema1;
      create schema schema2;

      -- Creating table1 in schema1 with a primary key
      create table schema1.table1 (
          id int primary key,
          name varchar(255)
      );
      -- Creating table2 in schema2 with a foreign key referencing table1 in schema1
      create table schema2.table2 (
          id int primary key,
          "table1_id" int,
          description varchar(255),
          foreign key ("table1_id") references schema1.table1(id)
      );
      `,
      sourceConnectionString
    )
    await execQueryNext(
      `-- Inserting data into table1 in schema1
      insert into schema1.table1 (id, name)
      values
      (1, 'John Doe'),
      (2, 'Jane Smith'),
      (3, 'Mike Johnson');

      -- Inserting data into table2 in schema2
      insert into schema2.table2 (id, "table1_id", description)
      values
      (1, 1, 'Description for record 1'),
      (2, 2, 'Description for record 2'),
      (3, 3, 'Description for record 3');
      `,
      sourceConnectionString
    )

    await expect(
      runSnapletCLI(
        [
          'config',
          'generate',
          `--connection-string=${sourceConnectionString.toString()}`,
        ],
        {},
        paths
      )
    ).rejects.toThrow(`Failed to parse config file: ${paths.snapletConfig}
Expected object, received string at "table3" or Expected function, received string at "table3"`)
  })
  test('parse error with a invalid subset', async () => {
    const sourceConnectionString = await createTestDb()

    const paths = await createTestProjectDirV2()

    const configContent = `
    import { copycat } from "@snaplet/copycat";
    import { defineConfig } from "snaplet";

    export default defineConfig({
      subset: {
        enabled: "nope",
      }
    })`

    await fs.writeFile(paths.snapletConfig, configContent)

    await execQueryNext(
      `
      -- Creating schema1 and schema2
      create schema schema1;
      create schema schema2;

      -- Creating table1 in schema1 with a primary key
      create table schema1.table1 (
          id int primary key,
          name varchar(255)
      );
      -- Creating table2 in schema2 with a foreign key referencing table1 in schema1
      create table schema2.table2 (
          id int primary key,
          "table1_id" int,
          description varchar(255),
          foreign key ("table1_id") references schema1.table1(id)
      );
      `,
      sourceConnectionString
    )
    await execQueryNext(
      `-- Inserting data into table1 in schema1
      insert into schema1.table1 (id, name)
      values
      (1, 'John Doe'),
      (2, 'Jane Smith'),
      (3, 'Mike Johnson');

      -- Inserting data into table2 in schema2
      insert into schema2.table2 (id, "table1_id", description)
      values
      (1, 1, 'Description for record 1'),
      (2, 2, 'Description for record 2'),
      (3, 3, 'Description for record 3');
      `,
      sourceConnectionString
    )

    await expect(
      runSnapletCLI(
        [
          'config',
          'generate',
          `--connection-string=${sourceConnectionString.toString()}`,
        ],
        {},
        paths
      )
    ).rejects.toThrow(`Failed to parse config file: ${paths.snapletConfig}
Expected boolean, received string at "subset.enabled" and
Required at "subset.targets"`)
  })
})
