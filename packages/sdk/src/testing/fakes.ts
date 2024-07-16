import { IntrospectedStructure } from '../db/introspect/introspectDatabase.js'

type FakeFn<Data> = (overrides?: Partial<Data>) => Data

export const fakeColumnStructure: FakeFn<
  IntrospectedStructure['tables'][number]['columns'][number]
> = (overrides) => {
  const defaults: IntrospectedStructure['tables'][number]['columns'][number] = {
    name: 'id',
    type: 'text',
    table: 'test_customer',
    schema: 'public',
    nullable: false,
    default: '',
    generated: 'NEVER',
    identity: null,
    maxLength: null,
    constraints: [],
    typeCategory: 'S',
    id: `public.id`,
    typeId: 'text',
  }

  return {
    ...defaults,
    ...overrides,
  }
}

export const fakeTableStructure: FakeFn<
  IntrospectedStructure['tables'][number]
> = ({ name = 'test_customer', schema = 'public', ...overrides } = {}) => {
  const defaults: IntrospectedStructure['tables'][number] = {
    id: `${schema}.${name}`,
    name,
    schema,
    rows: 1,
    bytes: 1,
    parents: [],
    children: [],
    columns: [
      fakeColumnStructure({
        name: 'id',
      }),
      fakeColumnStructure({
        name: 'name',
      }),
      fakeColumnStructure({
        name: 'email',
      }),
      fakeColumnStructure({
        name: 'confirmed_at',
        generated: 'ALWAYS',
      }),
    ],
    partitioned: false,
    primaryKeys: {
      dirty: false,
      schema: schema,
      table: name,
      tableId: `${schema}.${name}`,
      keys: [
        {
          name: 'id',
          type: 'text',
        },
      ],
    },
  }

  const result = {
    ...defaults,
    ...overrides,
  }

  return {
    ...result,
    columns: result.columns.map((column) => ({
      ...column,
      table: name,
      schema,
    })),
  }
}

export const fakeDbStructure: FakeFn<IntrospectedStructure> = (overrides) => {
  const defaults: IntrospectedStructure = {
    indexes: [],
    tables: [fakeTableStructure()],
    schemas: [],
    extensions: [],
    enums: [],
    server: {
      version: '14.2',
    },
  }

  return {
    ...defaults,
    ...overrides,
  }
}
