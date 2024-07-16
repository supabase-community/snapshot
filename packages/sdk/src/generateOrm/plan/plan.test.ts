import { DataModel } from '../dataModel/dataModel.js'
import { Plan } from './plan.js'
import {
  ChildField,
  ConnectCallbackContext,
  CountCallback,
  GenerateCallbackContext,
  ParentField,
  PlanInputs,
  ScalarField,
  UserModels,
} from './types.js'
import { SeedClientBase } from '../client.js'
import { createDataModelFromSql } from '~/generate/testing.js'

describe('Plan', () => {
  test('it works with a very basic data model', async () => {
    // arrange
    const dataModel: DataModel = {
      enums: {},
      models: {
        test_customer: {
          uniqueConstraints: [],
          id: 'public.test_customer',
          tableName: 'test_customer',
          schemaName: 'public',
          fields: [
            {
              isId: true,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.name',
              name: 'name',
              columnName: 'name',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.email',
              name: 'email',
              columnName: 'email',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.confirmed_at',
              name: 'confirmed_at',
              columnName: 'confirmed_at',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
      },
    }
    const userModels: UserModels = {
      test_customer: {
        data: {
          id: ({ seed }) => seed,
          name: ({ seed }) => seed,
          email: ({ seed }) => seed,
          confirmed_at: ({ seed }) => seed,
        },
      },
    }
    const planInputs: PlanInputs = {
      model: 'test_customer',
      inputs: (x) => x(3),
    }
    const plan = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: planInputs,
    })
    // act
    const store = await plan.generate()
    // assert
    expect(store._store).toMatchObject({
      test_customer: [
        {
          confirmed_at: '0/test_customer/0/confirmed_at',
          email: '0/test_customer/0/email',
          id: '0/test_customer/0/id',
          name: '0/test_customer/0/name',
        },
        {
          confirmed_at: '0/test_customer/1/confirmed_at',
          email: '0/test_customer/1/email',
          id: '0/test_customer/1/id',
          name: '0/test_customer/1/name',
        },
        {
          confirmed_at: '0/test_customer/2/confirmed_at',
          email: '0/test_customer/2/email',
          id: '0/test_customer/2/id',
          name: '0/test_customer/2/name',
        },
      ],
    })
  })

  test('we can inject a seed to a plan to change its output', async () => {
    // arrange
    const dataModel: DataModel = {
      enums: {},
      models: {
        test_customer: {
          uniqueConstraints: [],
          id: 'public.test_customer',
          tableName: 'test_customer',
          schemaName: 'public',
          fields: [
            {
              isId: true,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.name',
              name: 'name',
              columnName: 'name',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.email',
              name: 'email',
              columnName: 'email',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.confirmed_at',
              name: 'confirmed_at',
              columnName: 'confirmed_at',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
      },
    }
    const userModels: UserModels = {
      test_customer: {
        data: {
          id: ({ seed }) => seed,
          name: ({ seed }) => seed,
          email: ({ seed }) => seed,
          confirmed_at: ({ seed }) => seed,
        },
      },
    }
    const planInputs: PlanInputs = {
      model: 'test_customer',
      inputs: [{}],
    }
    const planWithoutSeed1 = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: planInputs,
    })
    const planWithoutSeed2 = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: planInputs,
    })
    const planWithSeed1 = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: planInputs,
      options: {
        seed: 'hello',
      },
    })
    const planWithSeed2 = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: planInputs,
      options: {
        seed: 'world',
      },
    })
    // act
    const storeWithoutSeed1 = await planWithoutSeed1.generate()
    const storeWithoutSeed2 = await planWithoutSeed2.generate()
    const storeWithSeed1 = await planWithSeed1.generate()
    const storeWithSeed2 = await planWithSeed2.generate()
    // assert
    expect(storeWithoutSeed1._store).toEqual(storeWithoutSeed2._store)
    expect(storeWithoutSeed1).not.toEqual(storeWithSeed1)
    expect(storeWithSeed1).not.toEqual(storeWithSeed2)
    expect(storeWithSeed1._store).toMatchObject({
      test_customer: [
        {
          confirmed_at: 'hello/test_customer/0/confirmed_at',
          email: 'hello/test_customer/0/email',
          id: 'hello/test_customer/0/id',
          name: 'hello/test_customer/0/name',
        },
      ],
    })
    expect(storeWithSeed2._store).toMatchObject({
      test_customer: [
        {
          confirmed_at: 'world/test_customer/0/confirmed_at',
          email: 'world/test_customer/0/email',
          id: 'world/test_customer/0/id',
          name: 'world/test_customer/0/name',
        },
      ],
    })
  })

  test('it supports nulls given as data in the plan', async () => {
    // arrange
    const dataModel: DataModel = {
      enums: {},
      models: {
        test_customer: {
          uniqueConstraints: [],
          id: 'public.test_customer',
          tableName: 'test_customer',
          schemaName: 'public',
          fields: [
            {
              isId: true,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.test_customer.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: false,
              kind: 'scalar',
              id: 'public.test_customer.name',
              name: 'name',
              columnName: 'name',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
      },
    }
    const userModels: UserModels = {
      test_customer: {
        data: {
          id: ({ seed }) => seed,
          name: ({ seed }) => seed,
        },
      },
    }
    const planInputs: PlanInputs = {
      model: 'test_customer',
      inputs: [
        {
          name: null,
        },
      ],
    }
    const plan = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: planInputs,
    })
    // act
    const store = await plan.generate()
    // assert
    expect(store._store).toMatchObject({
      test_customer: [
        {
          id: '0/test_customer/0/id',
          name: null,
        },
      ],
    })
  })

  test('it works with a parent', async () => {
    // arrange
    const dataModel: DataModel = {
      enums: {},
      models: {
        city: {
          uniqueConstraints: [],
          id: 'public.city',
          tableName: 'city',
          schemaName: 'public',
          fields: [
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.city.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.city.name',
              name: 'name',
              columnName: 'name',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
        user: {
          uniqueConstraints: [],
          id: 'public.user',
          tableName: 'user',
          schemaName: 'public',
          fields: [
            {
              isId: true,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.user.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.user.city_id',
              name: 'city_id',
              columnName: 'city_id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'object',
              name: 'city',
              type: 'city',
              relationName: 'userTocity',
              relationFromFields: ['city_id'],
              relationToFields: ['id'],
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
      },
    }
    const userModels: UserModels = {
      city: {
        data: {
          id: ({ seed }) => seed,
          name: ({ seed }) => seed,
        },
      },
      user: {
        data: {
          id: ({ seed }) => seed,
          city_id: ({ seed }) => seed,
        },
      },
    }
    const planInputs: PlanInputs = {
      model: 'user',
      inputs: (x) => x(3),
    }
    const plan = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: planInputs,
    })
    // act
    const store = await plan.generate()
    // assert
    expect(store._store).toMatchObject({
      city: [
        {
          id: '0/user/0/city/0/id',
          name: '0/user/0/city/0/name',
        },
        {
          id: '0/user/1/city/0/id',
          name: '0/user/1/city/0/name',
        },
        {
          id: '0/user/2/city/0/id',
          name: '0/user/2/city/0/name',
        },
      ],
      user: [
        {
          city_id: '0/user/0/city/0/id',
          id: '0/user/0/id',
        },
        {
          city_id: '0/user/1/city/0/id',
          id: '0/user/1/id',
        },
        {
          city_id: '0/user/2/city/0/id',
          id: '0/user/2/id',
        },
      ],
    })
  })

  test('it works with children', async () => {
    // arrange
    const dataModel: DataModel = {
      enums: {},
      models: {
        city: {
          uniqueConstraints: [],
          id: 'public.city',
          tableName: 'city',
          schemaName: 'public',
          fields: [
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.city.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.city.name',
              name: 'name',
              columnName: 'name',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: true,
              isRequired: false,
              kind: 'object',
              name: 'user',
              type: 'user',
              relationName: 'userTocity',
              relationFromFields: [],
              relationToFields: [],
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
        user: {
          uniqueConstraints: [],
          id: 'public.user',
          tableName: 'user',
          schemaName: 'public',
          fields: [
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.user.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.user.city_id',
              name: 'city_id',
              columnName: 'city_id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'object',
              name: 'city',
              type: 'city',
              relationName: 'userTocity',
              relationFromFields: ['city_id'],
              relationToFields: ['id'],
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: true,
              isRequired: false,
              kind: 'object',
              name: 'book',
              type: 'book',
              relationName: 'bookTouser',
              relationFromFields: [],
              relationToFields: [],
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
        book: {
          uniqueConstraints: [],
          id: 'public.book',
          tableName: 'book',
          schemaName: 'public',
          fields: [
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.book.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.book.user_id',
              name: 'user_id',
              columnName: 'user_id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'object',
              name: 'user',
              type: 'user',
              relationName: 'bookTouser',
              relationFromFields: ['user_id'],
              relationToFields: ['id'],
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
      },
    }
    const userModels: UserModels = {
      city: {
        data: {
          id: ({ seed }) => seed,
          name: ({ seed }) => seed,
        },
      },
      user: {
        data: {
          id: ({ seed }) => seed,
          city_id: ({ seed }) => seed,
        },
      },
      book: {
        data: {
          id: ({ seed }) => seed,
          user_id: ({ seed }) => seed,
        },
      },
    }
    const planInputs: PlanInputs = {
      model: 'city',
      inputs: (x) =>
        x(2, {
          user: ((x) =>
            x(2, {
              book: ((x) => x(2)) as ChildField,
            })) as ChildField,
        }),
    }

    const plan = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: planInputs,
    })
    // act
    const store = await plan.generate()
    // assert
    expect(store._store).toMatchObject({
      book: [
        {
          id: '0/city/0/user/0/book/0/id',
          user_id: '0/city/0/user/0/id',
        },
        {
          id: '0/city/0/user/0/book/1/id',
          user_id: '0/city/0/user/0/id',
        },
        {
          id: '0/city/0/user/1/book/0/id',
          user_id: '0/city/0/user/1/id',
        },
        {
          id: '0/city/0/user/1/book/1/id',
          user_id: '0/city/0/user/1/id',
        },
        {
          id: '0/city/1/user/0/book/0/id',
          user_id: '0/city/1/user/0/id',
        },
        {
          id: '0/city/1/user/0/book/1/id',
          user_id: '0/city/1/user/0/id',
        },
        {
          id: '0/city/1/user/1/book/0/id',
          user_id: '0/city/1/user/1/id',
        },
        {
          id: '0/city/1/user/1/book/1/id',
          user_id: '0/city/1/user/1/id',
        },
      ],
      city: [
        {
          id: '0/city/0/id',
          name: '0/city/0/name',
        },
        {
          id: '0/city/1/id',
          name: '0/city/1/name',
        },
      ],
      user: [
        {
          city_id: '0/city/0/id',
          id: '0/city/0/user/0/id',
        },
        {
          city_id: '0/city/0/id',
          id: '0/city/0/user/1/id',
        },
        {
          city_id: '0/city/1/id',
          id: '0/city/1/user/0/id',
        },
        {
          city_id: '0/city/1/id',
          id: '0/city/1/user/1/id',
        },
      ],
    })
  })

  test('it works with two models with the same tableName in different schemas', async () => {
    // arrange
    const dataModel: DataModel = {
      enums: {},
      models: {
        public_User: {
          uniqueConstraints: [],
          id: 'public.User',
          tableName: 'User',
          schemaName: 'public',
          fields: [
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.User.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.User.name',
              name: 'name',
              columnName: 'name',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
        auth_User: {
          uniqueConstraints: [],
          id: 'auth.User',
          tableName: 'User',
          schemaName: 'auth',
          fields: [
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'auth.User.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'auth.User.password',
              name: 'password',
              columnName: 'password',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
      },
    }
    const userModels: UserModels = {
      public_User: {
        data: {
          id: ({ seed }) => seed,
          name: ({ seed }) => seed,
        },
      },
      auth_User: {
        data: {
          id: ({ seed }) => seed,
          password: ({ seed }) => seed,
        },
      },
    }
    const planInputs: PlanInputs = {
      model: 'public_User',
      inputs: (x) => x(3),
    }
    const plan = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: planInputs,
    })
    // act
    const store = await plan.generate()
    // assert
    expect(store._store).toMatchObject({
      public_User: [
        {
          id: '0/public_User/0/id',
          name: '0/public_User/0/name',
        },
        {
          id: '0/public_User/1/id',
          name: '0/public_User/1/name',
        },
        {
          id: '0/public_User/2/id',
          name: '0/public_User/2/name',
        },
      ],
    })
  })

  test('the child index is inherited from the parent', async () => {
    // arrange
    const dataModel: DataModel = {
      enums: {},
      models: {
        city: {
          uniqueConstraints: [],
          id: 'public.city',
          tableName: 'city',
          schemaName: 'public',
          fields: [
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.city.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.city.name',
              name: 'name',
              columnName: 'name',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
        user: {
          uniqueConstraints: [],
          id: 'public.user',
          tableName: 'user',
          schemaName: 'public',
          fields: [
            {
              isId: true,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.user.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.user.city_id',
              name: 'city_id',
              columnName: 'city_id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'object',
              name: 'city',
              type: 'city',
              relationName: 'userTocity',
              relationFromFields: ['city_id'],
              relationToFields: ['id'],
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
      },
    }
    const userModels: UserModels = {
      city: {
        data: {
          id: ({ seed }) => seed,
        },
      },
      user: {
        data: {
          id: ({ seed }) => seed,
          city_id: ({ seed }) => seed,
        },
      },
    }
    const planInputs: PlanInputs = {
      model: 'user',
      inputs: (x) =>
        x(3, {
          city: {
            name: ((ctx) => `city number ${ctx.index}`) as ScalarField,
          },
        }),
    }
    const plan = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: planInputs,
    })
    // act
    const store = await plan.generate()
    // assert
    expect(store._store).toMatchObject({
      city: [
        {
          id: '0/user/0/city/0/id',
          name: 'city number 0',
        },
        {
          id: '0/user/1/city/0/id',
          name: 'city number 1',
        },
        {
          id: '0/user/2/city/0/id',
          name: 'city number 2',
        },
      ],
      user: [
        {
          city_id: '0/user/0/city/0/id',
          id: '0/user/0/id',
        },
        {
          city_id: '0/user/1/city/0/id',
          id: '0/user/1/id',
        },
        {
          city_id: '0/user/2/city/0/id',
          id: '0/user/2/id',
        },
      ],
    })
  })

  test('seed values are unique within a plan when generating the same model in multiple locations', async () => {
    // arrange
    const dataModel: DataModel = {
      enums: {},
      models: {
        DbConnection: {
          fields: [
            {
              hasDefaultValue: false,
              isGenerated: false,
              sequence: false,
              isId: true,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.DbConnection.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
            },
            {
              hasDefaultValue: false,
              isGenerated: false,
              sequence: false,
              isId: false,
              isList: true,
              isRequired: false,
              kind: 'object',
              name: 'Project_Project_dbConnectionIdToDbConnection',
              relationFromFields: [],
              relationName: 'Project_dbConnectionIdToDbConnection',
              relationToFields: [],
              type: 'Project',
            },
            {
              hasDefaultValue: false,
              isGenerated: false,
              sequence: false,
              isId: false,
              isList: true,
              isRequired: false,
              kind: 'object',
              name: 'Project_Project_hostedDbUrlIdToDbConnection',
              relationFromFields: [],
              relationName: 'Project_hostedDbUrlIdToDbConnection',
              relationToFields: [],
              type: 'Project',
            },
          ],
          schemaName: 'public',
          uniqueConstraints: [],
          id: 'public.DbConnection',
          tableName: 'DbConnection',
        },
        Project: {
          fields: [
            {
              hasDefaultValue: false,
              isGenerated: false,
              sequence: false,
              isId: false,
              isList: false,
              isRequired: false,
              kind: 'scalar',
              id: 'public.Project.dbConnectionId',
              name: 'dbConnectionId',
              columnName: 'dbConnectionId',
              type: 'text',
            },
            {
              hasDefaultValue: false,
              isGenerated: false,
              sequence: false,
              isId: false,
              isList: false,
              isRequired: false,
              kind: 'scalar',
              id: 'public.Project.hostedDbUrlId',
              name: 'hostedDbUrlId',
              columnName: 'hostedDbUrlId',
              type: 'text',
            },
            {
              hasDefaultValue: false,
              isGenerated: false,
              sequence: false,
              isId: true,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              id: 'public.Project.id',
              name: 'id',
              columnName: 'id',
              type: 'text',
            },
            {
              hasDefaultValue: false,
              isGenerated: false,
              sequence: false,
              isId: false,
              isList: false,
              isRequired: false,
              kind: 'object',
              name: 'DbConnection_Project_dbConnectionIdToDbConnection',
              relationFromFields: ['dbConnectionId'],
              relationName: 'Project_dbConnectionIdToDbConnection',
              relationToFields: ['id'],
              type: 'DbConnection',
            },
            {
              hasDefaultValue: false,
              isGenerated: false,
              sequence: false,
              isId: false,
              isList: false,
              isRequired: false,
              kind: 'object',
              name: 'DbConnection_Project_hostedDbUrlIdToDbConnection',
              relationFromFields: ['hostedDbUrlId'],
              relationName: 'Project_hostedDbUrlIdToDbConnection',
              relationToFields: ['id'],
              type: 'DbConnection',
            },
          ],
          schemaName: 'public',
          uniqueConstraints: [],
          id: 'public.Project',
          tableName: 'Project',
        },
      },
    }
    const userModels: UserModels = {
      Project: {
        data: {
          id: ({ seed }) => seed,
          hostedDbUrlId: ({ seed }) => seed,
          dbConnectionId: ({ seed }) => seed,
        },
      },
      DbConnection: {
        data: {
          id: ({ seed }) => seed,
        },
      },
    }
    const plan = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: {
        model: 'Project',
        inputs: [
          {
            DbConnection_Project_dbConnectionIdToDbConnection: {},
            DbConnection_Project_hostedDbUrlIdToDbConnection: {},
          },
        ],
      },
    })
    // act
    const store = await plan.generate()
    // assert
    expect(store._store).toMatchObject({
      DbConnection: [
        {
          id: '0/Project/0/DbConnection_Project_dbConnectionIdToDbConnection/0/id',
        },
        {
          id: '0/Project/0/DbConnection_Project_hostedDbUrlIdToDbConnection/0/id',
        },
      ],
      Project: [
        {
          dbConnectionId:
            '0/Project/0/DbConnection_Project_dbConnectionIdToDbConnection/0/id',
          hostedDbUrlId:
            '0/Project/0/DbConnection_Project_hostedDbUrlIdToDbConnection/0/id',
          id: '0/Project/0/id',
        },
      ],
    })
  })

  test('connect functions override connect option', async () => {
    // arrange
    const dataModel: DataModel = {
      enums: {},
      models: {
        Project: {
          id: 'public.Project',
          uniqueConstraints: [],
          tableName: 'Project',
          schemaName: 'public',
          fields: [
            {
              id: 'public.Project.id',
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: true,
              isRequired: false,
              kind: 'object',
              name: 'Snapshot',
              type: 'Snapshot',
              relationName: 'SnapshotToProject',
              relationFromFields: [],
              relationToFields: [],
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: true,
              isRequired: false,
              kind: 'object',
              name: 'ExecTask',
              type: 'ExecTask',
              relationName: 'ExecTaskToProject',
              relationFromFields: [],
              relationToFields: [],
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
        ExecTask: {
          id: 'public.ExecTask',
          uniqueConstraints: [],
          tableName: 'ExecTask',
          schemaName: 'public',
          fields: [
            {
              id: 'public.ExecTask.id',
              isId: true,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              id: 'public.ExecTask.projectId',
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              name: 'projectId',
              columnName: 'projectId',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'object',
              name: 'Project',
              type: 'Project',
              relationName: 'ExecTaskToProject',
              relationFromFields: ['projectId'],
              relationToFields: ['id'],
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
      },
    }
    const userModels: UserModels = {
      Project: {
        data: {
          id: ({ seed }) => seed,
        },
      },
      ExecTask: {
        data: {
          id: ({ seed }) => seed,
          projectId: ({ seed }) => seed,
        },
      },
    }
    const planWithoutOverride = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: {
        model: 'ExecTask',
        inputs: [{}],
      },
      options: {
        connect: {
          Project: [{ id: 'externalProjectId' }],
        },
      },
    })
    const planWithOverride = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: {
        model: 'ExecTask',
        inputs: [
          {
            Project: () => ({ id: 'inlineProjectId' }),
          },
        ],
      },
      options: {
        connect: {
          Project: [{ id: 'externalProjectId' }],
        },
      },
    })
    // act
    const storeWithoutOverride = await planWithoutOverride.generate()
    const storeWithOverride = await planWithOverride.generate()
    // assert
    // connect links the ExecTask to the Project "externalProjectId" in the store
    expect(storeWithoutOverride._store).toMatchObject({
      ExecTask: [
        {
          id: '0/ExecTask/0/id',
          projectId: 'externalProjectId',
        },
      ],
    })
    // connect option is overridden by the connect function in the plan inputs, the ExecTask is linked to the Project "inlineProjectId"
    expect(storeWithOverride._store).toMatchObject({
      ExecTask: [
        {
          id: '0/ExecTask/0/id',
          projectId: 'inlineProjectId',
        },
      ],
    })
  })

  test('specifying "data" for a parent overwrite the connect option', async () => {
    // arrange
    const dataModel: DataModel = {
      enums: {},
      models: {
        city: {
          id: 'public.city',
          uniqueConstraints: [],
          tableName: 'city',
          schemaName: 'public',
          fields: [
            {
              id: 'public.city.id',
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              id: 'public.city.name',
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              name: 'name',
              columnName: 'name',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
        user: {
          id: 'public.user',
          uniqueConstraints: [],
          tableName: 'user',
          schemaName: 'public',
          fields: [
            {
              id: 'public.user.id',
              isId: true,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              name: 'id',
              columnName: 'id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              id: 'public.user.city_id',
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'scalar',
              name: 'city_id',
              columnName: 'city_id',
              type: 'text',
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              isId: false,
              isList: false,
              isRequired: true,
              kind: 'object',
              name: 'city',
              type: 'city',
              relationName: 'userTocity',
              relationFromFields: ['city_id'],
              relationToFields: ['id'],
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
      },
    }
    const userModels: UserModels = {
      city: {
        data: {
          id: ({ seed }) => seed,
          name: ({ seed }) => seed,
        },
      },
      user: {
        data: {
          id: ({ seed }) => seed,
          city_id: ({ seed }) => seed,
        },
      },
    }
    const planWithData = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: {
        model: 'user',
        inputs: [
          {
            city: {},
          },
        ],
      },
      options: {
        connect: {
          city: [{ id: '69001', name: 'Lyon' }],
        },
      },
    })
    const planWithoutData = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: {
        model: 'user',
        inputs: [{}],
      },
      options: {
        connect: {
          city: [{ id: '69001', name: 'Lyon' }],
        },
      },
    })
    // act
    const storeWithData = await planWithData.generate()
    const storeWithoutData = await planWithoutData.generate()
    // assert
    expect(storeWithData._store).toMatchObject({
      city: [
        {
          id: '0/user/0/city/0/id',
          name: '0/user/0/city/0/name',
        },
      ],
      user: [
        {
          city_id: '0/user/0/city/0/id',
          id: '0/user/0/id',
        },
      ],
    })
    console.log(storeWithoutData._store.city)
    expect(storeWithoutData._store.city.length).toBe(0)
    expect(storeWithoutData._store).toMatchObject({
      user: [
        {
          city_id: '69001',
          id: '0/user/0/id',
        },
      ],
    })
  })

  test('handle cyclic relationships', async () => {
    const dataModel: DataModel = {
      models: {
        category: {
          id: 'public.category',
          schemaName: 'public',
          uniqueConstraints: [],
          tableName: 'category',
          fields: [
            {
              id: 'public.category.id',
              name: 'id',
              columnName: 'id',
              type: 'uuid',
              isRequired: true,
              kind: 'scalar',
              isList: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: true,
              isId: true,
            },
            {
              id: 'public.category.name',
              name: 'name',
              columnName: 'name',
              type: 'text',
              isRequired: true,
              kind: 'scalar',
              isList: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
              isId: false,
            },
            {
              id: 'public.category.site_id',
              name: 'site_id',
              columnName: 'site_id',
              type: 'uuid',
              isRequired: true,
              kind: 'scalar',
              isList: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
              isId: false,
            },
            {
              name: 'site',
              type: 'site',
              isRequired: true,
              kind: 'object',
              relationName: 'categoryTosite',
              relationFromFields: ['site_id'],
              relationToFields: ['id'],
              isList: false,
              isId: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              name: 'site',
              type: 'site',
              isRequired: false,
              kind: 'object',
              relationName: 'siteTocategory',
              relationFromFields: [],
              relationToFields: [],
              isList: true,
              isId: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
        site: {
          id: 'public.site',
          schemaName: 'public',
          uniqueConstraints: [],
          tableName: 'site',
          fields: [
            {
              id: 'public.site.category_id',
              name: 'category_id',
              columnName: 'category_id',
              type: 'uuid',
              isRequired: false,
              kind: 'scalar',
              isList: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
              isId: false,
            },
            {
              id: 'public.site.id',
              name: 'id',
              columnName: 'id',
              type: 'uuid',
              isRequired: true,
              kind: 'scalar',
              isList: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: true,
              isId: true,
            },
            {
              name: 'category',
              type: 'category',
              isRequired: false,
              kind: 'object',
              relationName: 'siteTocategory',
              relationFromFields: ['category_id'],
              relationToFields: ['id'],
              isList: false,
              isId: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              name: 'category',
              type: 'category',
              isRequired: false,
              kind: 'object',
              relationName: 'categoryTosite',
              relationFromFields: [],
              relationToFields: [],
              isList: true,
              isId: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
      },
      enums: {},
    }
    const userModels: UserModels = {
      category: {
        data: {
          id: ({ seed }) => seed,
          name: ({ seed }) => seed,
        },
      },
      site: {
        data: {
          id: ({ seed }) => seed,
        },
      },
    }

    const plan = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: {
        model: 'site',
        inputs: [
          ({ seed }) => {
            const id = `${seed}/id`
            return {
              id,
              category: {
                site: (({ connect }) => connect(() => ({ id }))) as ParentField,
              },
            }
          },
        ],
      },
    })
    // act
    const store = await plan.generate()
    // assert
    expect(store._store).toMatchObject({
      category: [
        {
          id: '0/site/0/category/0/id',
          name: '0/site/0/category/0/name',
          site_id: '0/site/0/id',
        },
      ],
      site: [
        {
          category_id: '0/site/0/category/0/id',
          id: '0/site/0/id',
        },
      ],
    })
  })

  test('provide own sequences for always generated identity columns', async () => {
    const dataModel: DataModel = {
      models: {
        members: {
          id: 'public.members',
          schemaName: 'public',
          uniqueConstraints: [],
          tableName: 'members',
          fields: [
            {
              id: 'public.members.id',
              name: 'id',
              columnName: 'id',
              type: 'uuid',
              isRequired: true,
              kind: 'scalar',
              isList: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: true,
              isId: true,
            },
            {
              id: 'public.members.organization_id',
              name: 'organization_id',
              columnName: 'organization_id',
              type: 'int8',
              isRequired: true,
              kind: 'scalar',
              isList: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
              isId: false,
            },
            {
              id: 'public.members.user_id',
              name: 'user_id',
              columnName: 'user_id',
              type: 'int8',
              isRequired: true,
              kind: 'scalar',
              isList: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
              isId: false,
            },
            {
              name: 'organizations',
              type: 'organizations',
              isRequired: true,
              kind: 'object',
              relationName: 'membersToorganizations',
              relationFromFields: ['organization_id'],
              relationToFields: ['id'],
              isList: false,
              isId: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
            {
              name: 'users',
              type: 'users',
              isRequired: true,
              kind: 'object',
              relationName: 'membersTousers',
              relationFromFields: ['user_id'],
              relationToFields: ['id'],
              isList: false,
              isId: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
        organizations: {
          schemaName: 'public',
          uniqueConstraints: [],
          id: 'public.organizations',
          tableName: 'organizations',
          fields: [
            {
              id: 'public.organizations.id',
              name: 'id',
              columnName: 'id',
              type: 'int8',
              isRequired: true,
              kind: 'scalar',
              isList: false,
              isGenerated: false,
              sequence: {
                current: 1,
                start: 1,
                increment: 1,
                identifier: 'public."organizations_id_seq"',
              },
              hasDefaultValue: false,
              isId: true,
            },
            {
              id: 'public.organizations.name',
              name: 'name',
              columnName: 'name',
              type: 'text',
              isRequired: true,
              kind: 'scalar',
              isList: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
              isId: false,
            },
            {
              name: 'members',
              type: 'members',
              isRequired: false,
              kind: 'object',
              relationName: 'membersToorganizations',
              relationFromFields: [],
              relationToFields: [],
              isList: true,
              isId: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
        users: {
          id: 'public.users',
          schemaName: 'public',
          uniqueConstraints: [],
          tableName: 'users',
          fields: [
            {
              id: 'users.id',
              name: 'id',
              columnName: 'id',
              type: 'int8',
              isRequired: true,
              kind: 'scalar',
              isList: false,
              isGenerated: true,
              sequence: {
                current: 1,
                start: 1,
                increment: 1,
                identifier: 'public."users_id_seq"',
              },
              hasDefaultValue: false,
              isId: true,
            },
            {
              id: 'public.users.username',
              name: 'username',
              columnName: 'username',
              type: 'text',
              isRequired: true,
              kind: 'scalar',
              isList: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
              isId: false,
            },
            {
              name: 'members',
              type: 'members',
              isRequired: false,
              kind: 'object',
              relationName: 'membersTousers',
              relationFromFields: [],
              relationToFields: [],
              isList: true,
              isId: false,
              isGenerated: false,
              sequence: false,
              hasDefaultValue: false,
            },
          ],
        },
      },
      enums: {},
    }

    // helpers to generate a sequence of integers
    function* getAutoIncrementSequence(start?: number, increment?: number) {
      let i = start ?? 1
      while (true) {
        yield i
        i += increment ?? 1
      }
    }
    const sequence = (start?: number, increment?: number) => {
      const seq = getAutoIncrementSequence(start, increment)
      return () => seq.next().value!
    }

    const userModels: UserModels = {
      organizations: {
        data: {
          id: sequence(),
          name: ({ seed }) => seed,
        },
      },
      members: {
        data: {
          id: ({ seed }) => seed,
          user_id: ({ seed }) => seed,
          organization_id: ({ seed }) => seed,
        },
      },
      users: {
        data: {
          id: sequence(100),
          username: ({ seed }) => seed,
        },
      },
    }
    const planInputs: PlanInputs = {
      model: 'organizations',
      inputs: [
        {
          members: ((x) => x(2)) as ChildField,
        },
      ],
    }
    const plan = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: planInputs,
    })
    // act
    const store = await plan.generate()
    // assert
    expect(store._store).toMatchObject({
      members: [
        {
          id: '0/organizations/0/members/0/id',
          organization_id: 1,
          user_id: 100,
        },
        {
          id: '0/organizations/0/members/1/id',
          organization_id: 1,
          user_id: 101,
        },
      ],
      organizations: [
        {
          id: 1,
          name: '0/organizations/0/name',
        },
      ],
      users: [
        {
          id: 100,
          username: '0/organizations/0/members/0/users/0/username',
        },
        {
          id: 101,
          username: '0/organizations/0/members/1/users/0/username',
        },
      ],
    })
  })

  test('`connect` option with date properties', async () => {
    const dataModel = await createDataModelFromSql(`
          CREATE TABLE "A" (
            "date" timestamp not null primary key
          );
          CREATE TABLE "B" (
            "id" serial not null primary key,
            "aId" timestamp not null references "A"("date")
          );
        `)

    const userModels = {
      A: {
        data: {
          date: null,
        },
      },
      B: {
        data: {
          id: null,
        },
      },
    }

    const ctx = SeedClientBase.getInitialState({
      dataModel,
      userModels,
    })

    const plan = new Plan({
      ctx,
      dataModel,
      userModels,
      plan: {
        model: 'B',
        inputs: [{}],
      },
      options: {
        connect: { A: [{ date: new Date(23) }] },
      },
    })

    const store = await plan.generate()

    expect(store._store.B[0].aId).toEqual(new Date(23).toISOString())
  })

  describe('connect callback', () => {
    test('$store', async () => {
      const dataModel = await createDataModelFromSql(`
          CREATE TABLE "A" (
            "id" serial not null primary key
          );
          CREATE TABLE "B" (
            "id" serial not null primary key,
            "aId" int not null references "A"("id")
          );
        `)

      const userModels = {
        A: {
          data: {
            id: null,
          },
        },
        B: {
          data: {
            id: null,
          },
        },
      }

      const ctx = SeedClientBase.getInitialState({
        dataModel,
        userModels,
      })

      const planA = new Plan({
        ctx,
        dataModel,
        userModels,
        plan: {
          model: 'A',
          inputs: [{}, {}],
        },
      })

      const planB = new Plan({
        ctx,
        dataModel,
        userModels,
        plan: {
          model: 'B',
          inputs: [
            {
              A: (({ connect }) =>
                connect(
                  ({ $store }: ConnectCallbackContext) => $store.A[1]
                )) as ParentField,
            },
          ],
        },
      })

      await planA.generate()
      const store = await planB.generate()

      expect(store._store.B[0].aId).toEqual(2)
    })

    test('store', async () => {
      const dataModel = await createDataModelFromSql(`
          CREATE TABLE "authors" (
            "id" serial not null primary key
          );
          CREATE TABLE "posts" (
            "id" serial not null primary key,
            "authorId" int not null references "authors"("id")
          );
          CREATE TABLE "comments" (
            "id" serial not null primary key,
            "authorId" int not null references "authors"("id"),
            "postId" int not null references "posts"("id")
          );
        `)

      const userModels = {
        authors: {
          data: {
            id: null,
          },
        },
        posts: {
          data: {
            id: null,
          },
        },
        comments: {
          data: {
            id: null,
          },
        },
      }

      const ctx = SeedClientBase.getInitialState({
        dataModel,
        userModels,
      })

      // create other authors so we can assert that we did _not_ pick any of them,
      // but rather picked an other created as part of the plan's own store
      const otherPlan = new Plan({
        ctx,
        dataModel,
        userModels,
        plan: {
          model: 'authors',
          inputs: [{}, {}, {}],
        },
      })

      const plan = new Plan({
        ctx,
        dataModel,
        userModels,
        plan: {
          model: 'posts',
          inputs: [
            {
              comments: (x: CountCallback) =>
                x(2, {
                  authors: (({ connect }) =>
                    connect(
                      ({ store }: ConnectCallbackContext) => store.authors[0]
                    )) as ParentField,
                }),
            },
          ],
        },
      })

      await otherPlan.generate()
      const store = await plan.generate()

      expect(store._store.comments[0].authorId).toEqual(4)
    })

    test('return values with date properties', async () => {
      const dataModel = await createDataModelFromSql(`
          CREATE TABLE "A" (
            "date" timestamp not null primary key
          );
          CREATE TABLE "B" (
            "id" serial not null primary key,
            "aId" timestamp not null references "A"("date")
          );
        `)

      const userModels = {
        A: {
          data: {
            date: null,
          },
        },
        B: {
          data: {
            id: null,
          },
        },
      }

      const ctx = SeedClientBase.getInitialState({
        dataModel,
        userModels,
      })

      const plan = new Plan({
        ctx,
        dataModel,
        userModels,
        plan: {
          model: 'B',
          inputs: [
            {
              A: () => ({
                date: new Date(23),
              }),
            },
          ],
        },
      })

      const store = await plan.generate()

      expect(store._store.B[0].aId).toEqual(new Date(23).toISOString())
    })
  })

  describe('generate callback', () => {
    test('data', async () => {
      const dataModel = await createDataModelFromSql(`
          CREATE TABLE "Organization" (
            "id" serial not null primary key
          );
          CREATE TABLE "Member" (
            "result" text[] not null,
            "id" serial not null primary key,
            "organizationId" int not null references "Organization"("id"),
            "fromOptions" text not null,
            "fromDescription1" text not null,
            "fromDescription2" text not null,
            "notInDescription" text not null
          );
        `)

      const userModels = {
        Organization: {},
        Member: {
          data: {
            fromOptions: 'fromOptionsValue',
          },
        },
      }

      const inputs = [
        {
          fromDescription1: () => 'fromDescription1Value',
          fromDescription2: () => 'fromDescription2Value',
          result: ({ data }: GenerateCallbackContext) =>
            JSON.stringify(data, null, 2),
        },
      ]

      const plan = new Plan({
        ctx: SeedClientBase.getInitialState({
          dataModel,
          userModels,
        }),
        dataModel,
        userModels,
        plan: {
          model: 'Member',
          inputs,
        },
      })

      const store = await plan.generate()

      expect(store._store.Member[0].result).toEqual(
        JSON.stringify(
          {
            fromOptions: 'fromOptionsValue',
            fromDescription1: 'fromDescription1Value',
            fromDescription2: 'fromDescription2Value',
          },
          null,
          2
        )
      )
    })

    test('$store', async () => {
      const dataModel = await createDataModelFromSql(`
          CREATE TABLE "A" (
            "id" serial not null primary key
          );
          CREATE TABLE "B" (
            "id" serial not null primary key,
            "memo" text
          );
        `)

      const userModels = {
        A: {
          data: {
            id: null,
          },
        },
        B: {
          data: {
            id: null,
          },
        },
      }

      const ctx = SeedClientBase.getInitialState({
        dataModel,
        userModels,
      })

      const planA = new Plan({
        ctx,
        dataModel,
        userModels,
        plan: {
          model: 'A',
          inputs: [{}, {}],
        },
      })

      const planB = new Plan({
        ctx,
        dataModel,
        userModels,
        plan: {
          model: 'B',
          inputs: [
            {},
            {
              memo: ({ $store }: GenerateCallbackContext) =>
                JSON.stringify($store, null, 2),
            },
          ],
        },
      })

      await planA.generate()
      const store = await planB.generate()

      expect(store._store.B[1].memo).toEqual(
        JSON.stringify(
          {
            A: [
              {
                id: 1,
              },
              {
                id: 2,
              },
            ],
            B: [
              {
                id: 1,
              },
              {
                id: 2,
              },
            ],
          },
          null,
          2
        )
      )
    })

    test('store', async () => {
      const dataModel = await createDataModelFromSql(`
          CREATE TABLE "A" (
            "id" serial not null primary key
          );
          CREATE TABLE "B" (
            "id" serial not null primary key,
            "memo" text
          );
        `)

      const userModels = {
        A: {
          data: {
            id: null,
          },
        },
        B: {
          data: {
            id: null,
          },
        },
      }

      const ctx = SeedClientBase.getInitialState({
        dataModel,
        userModels,
      })

      const planA = new Plan({
        ctx,
        dataModel,
        userModels,
        plan: {
          model: 'A',
          inputs: [{}, {}],
        },
      })

      const planB = new Plan({
        ctx,
        dataModel,
        userModels,
        plan: {
          model: 'B',
          inputs: [
            {},
            {
              memo: ({ store }: GenerateCallbackContext) =>
                JSON.stringify(store, null, 2),
            },
          ],
        },
      })

      await planA.generate()
      const store = await planB.generate()

      expect(store._store.B[1].memo).toEqual(
        JSON.stringify(
          {
            A: [],
            B: [
              {
                id: 1,
              },
              {
                id: 2,
              },
            ],
          },
          null,
          2
        )
      )
    })

    test('options', async () => {
      const dataModel = await createDataModelFromSql(`
          CREATE TABLE "Thing" (
            "value" int4 not null
          );
        `)

      const userModels = {
        Thing: {
          data: {
            value: ({ options }: GenerateCallbackContext) =>
              (Number(options.min) + Number(options.max)) / 2,
          },
        },
      }

      const ctx = SeedClientBase.getInitialState({
        dataModel,
        userModels,
      })

      const plan = new Plan({
        ctx,
        dataModel,
        userModels,
        fingerprint: {
          Thing: {
            value: {
              options: {
                min: 2,
                max: 4,
              },
            },
          },
        },
        plan: {
          model: 'Thing',
          inputs: [{}],
        },
      })

      await plan.generate()
      const store = await plan.generate()

      expect(store._store.Thing[0].value).toEqual(3)
    })

    test('date return values', async () => {
      const dataModel = await createDataModelFromSql(`
          CREATE TABLE "Thing" (
            "value" int4 not null
          );
        `)

      const userModels = {
        Thing: {},
      }

      const ctx = SeedClientBase.getInitialState({
        dataModel,
        userModels,
      })

      const plan = new Plan({
        ctx,
        dataModel,
        userModels,
        plan: {
          model: 'Thing',
          inputs: [
            {
              value: () => new Date(3),
            },
          ],
        },
      })

      await plan.generate()
      const store = await plan.generate()

      expect(store._store.Thing[0].value).toEqual(new Date(3).toISOString())
    })
  })

  test('`seed` is different according to the context', async () => {
    const dataModel = await createDataModelFromSql(`
      CREATE TABLE public.user (
        id uuid NOT NULL PRIMARY KEY,
        email text NOT NULL
      );
      CREATE TABLE public.post (
        id uuid NOT NULL PRIMARY KEY,
        title text NOT NULL,
        author_id uuid NOT NULL REFERENCES public.user(id)
      );
      CREATE TABLE public.comment (
        id uuid NOT NULL PRIMARY KEY,
        content text NOT NULL,
        author_id uuid NOT NULL REFERENCES public.user(id),
        post_id uuid NOT NULL REFERENCES public.post(id)
      );
    `)

    const userModels: UserModels = {
      user: {
        data: {
          id: ({ seed }) => seed,
        },
      },
      post: {
        data: {
          id: ({ seed }) => seed,
        },
      },
      comment: {
        data: {
          id: ({ seed }) => seed,
        },
      },
    }

    const plan = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: {
        model: 'post',
        inputs: [
          ({ seed }) => ({
            title: seed,
            user: (({ seed }) => ({
              email: seed,
            })) as ParentField,
            comment: ((x) =>
              x(2, ({ seed }) => ({
                content: seed,
              }))) as ChildField,
          }),
        ],
      },
    })

    const store = await plan.generate()

    expect(store._store).toMatchObject({
      comment: [
        {
          author_id: '0/post/0/comment/0/user/0/id',
          // comment's modelSeed from the root post
          content: '0/post/0/comment/0',
          id: '0/post/0/comment/0/id',
          post_id: '0/post/0/id',
        },
        {
          author_id: '0/post/0/comment/1/user/0/id',
          // comment's modelSeed from the root post
          content: '0/post/0/comment/1',
          id: '0/post/0/comment/1/id',
          post_id: '0/post/0/id',
        },
      ],
      post: [
        {
          author_id: '0/post/0/user/0/id',
          id: '0/post/0/id',
          // root post's modelSeed
          title: '0/post/0',
        },
      ],
      user: [
        {
          // user's modelSeed from the root post
          email: '0/post/0/user/0',
          id: '0/post/0/user/0/id',
        },
        {
          email: undefined,
          id: '0/post/0/comment/0/user/0/id',
        },
        {
          email: undefined,
          id: '0/post/0/comment/1/user/0/id',
        },
      ],
    })
  })

  test('`x` callback accepts static and dynamic data', async () => {
    const dataModel = await createDataModelFromSql(`
      CREATE TABLE public.user (
        id uuid NOT NULL PRIMARY KEY,
        email text NOT NULL
      );
      CREATE TABLE public.post (
        id uuid NOT NULL PRIMARY KEY,
        title text NOT NULL,
        author_id uuid NOT NULL REFERENCES public.user(id)
      );
      CREATE TABLE public.comment (
        id uuid NOT NULL PRIMARY KEY,
        content text NOT NULL,
        author_id uuid NOT NULL REFERENCES public.user(id),
        post_id uuid NOT NULL REFERENCES public.post(id)
      );
    `)

    const userModels: UserModels = {
      user: {
        data: {
          id: ({ seed }) => seed,
        },
      },
      post: {
        data: {
          id: ({ seed }) => seed,
        },
      },
      comment: {
        data: {
          id: ({ seed }) => seed,
        },
      },
    }

    const plan = new Plan({
      ctx: SeedClientBase.getInitialState({
        dataModel,
        userModels,
      }),
      dataModel,
      userModels,
      plan: {
        model: 'post',
        inputs: (x) =>
          x(1, {
            comment: ((x) =>
              x(2, ({ index }) => ({
                content: index,
              }))) as ChildField,
          }),
      },
    })

    const store = await plan.generate()

    expect(store._store).toMatchObject({
      comment: [
        {
          content: 0,
        },
        {
          content: 1,
        },
      ],
    })
  })
})
