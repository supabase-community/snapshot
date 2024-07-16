/// <reference path=".snaplet/snaplet.d.ts" />

import { defineConfig } from 'snaplet'

// TEST: Should raise error on invalid schema property
defineConfig({
  select: {
    //@ts-expect-error The expected type comes from property 'select' which is declared here on type '{ select?: Validate<SelectConfig, SelectConfig>; transform?: never; subset?: SubsetConfig<never>; }'
    invalidSchema: {},
  },
})

// TEST: Should raise error on invalid table property
defineConfig({
  select: {
    public: {
      //@ts-expect-error The expected type comes from property 'public' which is declared here on type 'Validate<SelectConfig, SelectConfig>'
      invalidTable: true,
    },
  },
})

// TEST: Should only allow to tranform and target tables that are included in the schema
defineConfig({
  select: {
    public: true,
  },
  transform: {
    $mode: 'auto',
    public: {
      _prisma_migrations: (ctx) => {
        return ctx.row
      },
      Snapshot: (ctx) => ctx.row,
      //@ts-expect-error the table doesn't exist in the public schema
      nonExistentTable: (ctx) => {},
    },
  },
  subset: {
    enabled: true,
    // @ts-expect-error the table doesn't exist in the public schema
    targets: [
      { table: 'public.Snapshot', percent: 100 },
      { table: 'public.nonExitentTable', percent: 100 },
    ],
  },
})

// TEST: Should only allow to tranform and target tables that are explicitly selected when $default false for schema
defineConfig({
  select: {
    public: {
      $default: false,
      Snapshot: true,
    },
  },
  transform: {
    $mode: 'auto',
    public: {
      Snapshot: (ctx) => ctx.row,
      //@ts-expect-error the table is not selected
      _prisma_migrations: (ctx) => {
        return ctx.row
      },
    },
  },
  subset: {
    enabled: true,
    //@ts-expect-error the table _prisma_migrations is not selected
    targets: [
      { table: 'public.Snapshot', percent: 100 },
      { table: 'public._prisma_migrations', percent: 100 },
    ],
  },
})

// TEST: Should allow to tranform and target tables that are non explicitly selected when $default is undefined (true by default)
defineConfig({
  select: {
    public: {
      Snapshot: true,
    },
  },
  transform: {
    $mode: 'auto',
    public: {
      Snapshot: (ctx) => ctx.row,
      _prisma_migrations: (ctx) => {
        return ctx.row
      },
    },
  },
  subset: {
    enabled: true,
    targets: [
      { table: 'public.Snapshot', percent: 100 },
      { table: 'public._prisma_migrations', percent: 100 },
    ],
  },
})

// TEST: Should raise error if transform mode is strict and tables transformations are missing
defineConfig({
  select: {
    public: {
      Snapshot: true,
    },
  },
  transform: {
    $mode: 'strict',
    // @ts-expect-error some tables are missing transformations
    public: {
      Snapshot: (ctx) => ctx.row,
      _prisma_migrations: (ctx) => {
        return ctx.row
      },
    },
  },
  subset: {
    enabled: true,
    targets: [
      { table: 'public.Snapshot', percent: 100 },
      { table: 'public._prisma_migrations', percent: 100 },
    ],
  },
})

// TEST: Should work transform mode is unsafe and tables transformations are missing
defineConfig({
  select: {
    public: {
      Snapshot: true,
    },
  },
  transform: {
    $mode: 'unsafe',
    public: {},
  },
  subset: {
    enabled: true,
    targets: [
      { table: 'public.Snapshot', percent: 100 },
      { table: 'public._prisma_migrations', percent: 100 },
    ],
  },
})

// TEST: Should work transform mode is 'auto' and tables transformations are missing
defineConfig({
  select: {
    public: {
      Snapshot: true,
    },
  },
  transform: {
    $mode: 'auto',
    public: {
      Snapshot: (ctx) => ctx.row,
      _prisma_migrations: (ctx) => {
        return ctx.row
      },
    },
  },
  subset: {
    enabled: true,
    targets: [
      { table: 'public.Snapshot', percent: 100 },
      { table: 'public._prisma_migrations', percent: 100 },
    ],
  },
})

// TEST: Should raise error transform mode is 'strict' and a transform don't change all columns in object mode
defineConfig({
  select: {
    public: {
      Snapshot: true,
    },
  },
  transform: {
    $mode: 'strict',
    public: {
      //@ts-expect-error not all columns are returned
      Snapshot: {
        id: 'some id',
      },
      _prisma_migrations: (ctx) => {
        return ctx.row
      },
    },
  },
  subset: {
    enabled: true,
    targets: [
      { table: 'public.Snapshot', percent: 100 },
      { table: 'public._prisma_migrations', percent: 100 },
    ],
  },
})

// TEST: Should raise error transform mode is 'strict' and a transform don't change all columns in function callback
defineConfig({
  select: {
    public: {
      Snapshot: true,
    },
  },
  transform: {
    $mode: 'strict',
    public: {
      //@ts-expect-error not all columns are returned
      Snapshot: () => ({
        id: 'some id',
      }),
      _prisma_migrations: (ctx) => {
        return ctx.row
      },
    },
  },
  subset: {
    enabled: true,
    targets: [
      { table: 'public.Snapshot', percent: 100 },
      { table: 'public._prisma_migrations', percent: 100 },
    ],
  },
})

// TEST: Should raise error when you try to transform or target table with only "structure" selected as there will be no data in it
defineConfig({
  select: {
    public: {
      $default: 'structure',
      Snapshot: true,
    },
  },
  transform: {
    $mode: 'auto',
    public: {
      Snapshot: () => ({
        id: 'some id',
      }),
      // @ts-expect-error the default select is structure and _prisma_migrations data is not explicitly selected
      _prisma_migrations: (ctx) => {
        return ctx.row
      },
    },
  },
  subset: {
    enabled: true,
    // @ts-expect-error the default select is structure and _prisma_migrations data is not explicitly selected
    targets: [
      { table: 'public.Snapshot', percent: 100 },
      { table: 'public._prisma_migrations', percent: 100 },
    ],
  },
})

// TEST: Should be able to exclude extensions and schema from the selection
defineConfig({
  select: {
    public: {
      $default: 'structure',
      Snapshot: true,
      $extensions: {
        pgcrypto: false
      }
    },
  },
  transform: {
    $mode: 'auto',
    public: {
      Snapshot: () => ({
        id: 'some id',
      }),
      // @ts-expect-error the default select is structure and _prisma_migrations data is not explicitly selected
      _prisma_migrations: (ctx) => {
        return ctx.row
      },
    },
  },
  subset: {
    enabled: true,
    // @ts-expect-error the default select is structure and _prisma_migrations data is not explicitly selected
    targets: [
      { table: 'public.Snapshot', percent: 100 },
      { table: 'public._prisma_migrations', percent: 100 },
    ],
  },
})

// TEST: Should be able to only specify the transform config
defineConfig({
  transform: {
    $mode: 'auto',
  },
})

// TEST: Should be able to only specify the subset config
defineConfig({
  subset: {
    enabled: true,
    targets: [{ table: 'public.Snapshot', percent: 100 }],
  },
})

// TEST: Should be able to return litteral null for nullable fields
defineConfig({
  transform: {
    public: {
      Snapshot: () => {
        return {
          execTaskId: null,
        }
      },
    },
  },
})

// TEST: should be able to specify eager mode
defineConfig({
  subset: {
    enabled: true,
    eager: true,
    targets: [{ table: 'public.Snapshot', percent: 100 }],
  },
})

// TEST: should be able to only specify the where parameter
defineConfig({
  subset: {
    enabled: true,
    eager: true,
    targets: [{ table: 'public.Snapshot', where: '1 = 1'}],
  },
})

// TEST: should be able to only specify the where parameter and percent
defineConfig({
  subset: {
    enabled: true,
    eager: true,
    targets: [{ table: 'public.Snapshot', where: '1 = 1', percent: 10}],
  },
})
// TEST: should be able to only specify the where parameter and percent and rowLimit
defineConfig({
  subset: {
    enabled: true,
    eager: true,
    // @ts-expect-error rowLimit is not a valid parameter
    targets: [{ table: 'public.Snapshot', where: '1 = 1', percent: 10, rowLimit: 10}],
  },
})
// TEST: should be able to only specify parameter and percent and rowLimit
defineConfig({
  subset: {
    enabled: true,
    eager: true,
    // @ts-expect-error rowLimit is not a valid parameter
    targets: [{ table: 'public.Snapshot', percent: 10, rowLimit: 10}],
  },
})
// TEST: should be able to only specify where and rowLimit
defineConfig({
  subset: {
    enabled: true,
    eager: true,
    targets: [{ table: 'public.Snapshot', where: '1 = 1', rowLimit: 10}],
  },
})

// TEST: should be able to specify $default and down to relation options
defineConfig({
  subset: {
    enabled: true,
    eager: true,
    targets: [{ table: 'public.Snapshot', where: '1 = 1', rowLimit: 10}],
    followNullableRelations: {
      $default: false,
      "public.AccessToken": true,
      "public.ExecTask": {
        ExecTask_accessTokenId_fkey: false,
        ExecTask_projectId_fkey: true,
      },
      "public.InviteToken": {
        $default: true,
      },
      "public.Member": {
        $default: true,
        InviteToken_usedByMemberId_fkey: false,
      },
    },
    maxChildrenPerNode: {
      $default: 10,
      "public.AccessToken": 100,
      "public.ExecTask": {
        Snapshot_execTaskId_fkey: 10,
      },
      "public.InviteToken": {
        $default: 100,
      },
      "public.Member": {
        $default: 100,
        InviteToken_usedByMemberId_fkey: 10,
      },
    },
    maxCyclesLoop: {
      $default: 10,
      "public.AccessToken": 100,
      "public.ExecTask": {
        ExecTask_accessTokenId_fkey: 10,
        ExecTask_projectId_fkey: 100,
      },
      "public.InviteToken": {
        $default: 100,
      },
      "public.Member": {
        $default: 100,
        InviteToken_usedByMemberId_fkey: 10,
      },
    },
  }
})
// TEST: should throw an error if a table without relations have options
defineConfig({
  subset: {
    enabled: true,
    eager: true,
    targets: [{ table: 'public.Snapshot', where: '1 = 1', rowLimit: 10}],
    followNullableRelations: {
      $default: false,
      "public.AccessToken": true,
      "public.ExecTask": {
        ExecTask_accessTokenId_fkey: false,
        ExecTask_projectId_fkey: true,
      },
      "public.InviteToken": {
        $default: true,
      },
      "public.Member": {
        $default: true,
        InviteToken_usedByMemberId_fkey: false,
      },
      // @ts-expect-error the table doesn't have relations
      "public._prisma_migrations": false,
    },
    maxChildrenPerNode: {
      $default: 10,
      "public.AccessToken": 100,
      "public.ExecTask": {
        Snapshot_execTaskId_fkey: 10,
      },
      "public.InviteToken": {
        $default: 100,
      },
      "public.Member": {
        $default: 100,
        InviteToken_usedByMemberId_fkey: 10,
      },
      // @ts-expect-error the table doesn't have relations
      "public._prisma_migrations": 10,
    },
    maxCyclesLoop: {
      $default: 10,
      "public.AccessToken": 100,
      "public.ExecTask": {
        ExecTask_accessTokenId_fkey: 10,
        ExecTask_projectId_fkey: 100,
      },
      "public.InviteToken": {
        $default: 100,
      },
      "public.Member": {
        $default: 100,
        InviteToken_usedByMemberId_fkey: 10,
      },
      // @ts-expect-error the table doesn't have relations
      "public._prisma_migrations": 10,
    },
  }
})
// TEST: should throw an error if a table excluded in select have options
defineConfig({
  select: {
    public: {
      AccessToken: false,
    },
  },
  subset: {
    enabled: true,
    eager: true,
    targets: [{ table: 'public.Snapshot', where: '1 = 1', rowLimit: 10}],
    followNullableRelations: {
      $default: false,
      // @ts-expect-error the table has been excluded in select
      "public.AccessToken": true,
      "public.ExecTask": {
        ExecTask_accessTokenId_fkey: false,
        ExecTask_projectId_fkey: true,
      },
      "public.InviteToken": {
        $default: true,
      },
      "public.Member": {
        $default: true,
        InviteToken_usedByMemberId_fkey: false,
      },
    },
  }
})