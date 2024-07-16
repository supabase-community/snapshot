import { computeApplicableMigrations } from './runAllMigrationsMiddleware.js'

describe('computeApplicableMigrations', () => {
  test('returns migrations in ascending semver order', () => {
    const migrations = {
      '1.0.0'() {},
      '0.2.0'() {},
    }

    const results = computeApplicableMigrations(migrations, '0.1.0')

    expect(results).toEqual([migrations['0.2.0'], migrations['1.0.0']])
  })

  test('only returns the migrations needed to bring the cli up to date', () => {
    const migrations = {
      '0.1.0'() {},
      '1.0.0'() {},
    }

    const results = computeApplicableMigrations(migrations, '0.2.0')

    expect(results).toEqual([migrations['1.0.0']])
  })
})
