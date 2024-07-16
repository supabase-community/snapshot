import type { IntrospectedStructure } from '../../../db/introspect/introspectDatabase.js'

import { SnapletConfigV2 } from './getConfig/parseConfig.js'
import {
  calculateIncludedTables,
  calculateIncludedExtensions,
} from './calculateIncludedTables.js'

describe('calculateIncludedExtensions', () => {
  test('it works', () => {
    const structure: IntrospectedStructure = {
      schemas: ['public', 'pgboss'],
      tables: [
        {
          name: 'users',
          schema: 'public',
        },
        {
          name: 'jobs',
          schema: 'pgboss',
        },
      ],
      enums: [
        {
          name: 'status',
          schema: 'public',
        },
      ],
      extensions: [
        {
          name: 'graphql',
          schema: 'public',
        },
        {
          name: 'pgcrypto',
          schema: 'public',
        },
        {
          name: 'queue',
          schema: 'pgboss',
        },
      ],
      indexes: [
        {
          schema: 'pgboss',
        },
      ],
    } as IntrospectedStructure
    const schemasConfig: SnapletConfigV2['select'] = {
      public: {
        $extensions: {
          pgcrypto: false,
        },
      },
      pgboss: false,
    }

    const result = calculateIncludedExtensions(
      structure['extensions'],
      schemasConfig
    )

    expect(result).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          schema: 'public',
          name: 'graphql',
        }),
      ])
    )
  })
})

describe('calculateIncludedTables', () => {
  test('it works', () => {
    const structure: IntrospectedStructure = {
      schemas: ['public', 'pgboss'],
      tables: [
        {
          name: 'users',
          schema: 'public',
        },
        {
          name: 'jobs',
          schema: 'pgboss',
        },
      ],
      enums: [
        {
          name: 'status',
          schema: 'public',
        },
      ],
      extensions: [
        {
          name: 'graphql',
          schema: 'public',
        },
        {
          name: 'pgcrypto',
          schema: 'public',
        },
        {
          name: 'queue',
          schema: 'pgboss',
        },
      ],
      indexes: [
        {
          schema: 'pgboss',
        },
      ],
    } as IntrospectedStructure
    const schemasConfig: SnapletConfigV2['select'] = {
      public: {
        $extensions: {
          pgcrypto: false,
        },
      },
      pgboss: false,
    }

    const result = calculateIncludedTables(structure['tables'], schemasConfig)

    expect(result).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          schema: 'public',
          name: 'users',
        }),
      ])
    )
  })
})
