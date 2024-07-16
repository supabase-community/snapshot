import { isSupabaseUrl } from './isSupabaseUrl.js'

describe('isSupabaseUrl', () => {
  test('returns whether url is supabase url or not', () => {
    expect(
      isSupabaseUrl(
        'postgres://postgres.ckpxcqqstnvzmhyziibg:password@aws-0-us-west-1.pooler.supabase.com:5432/postgres'
      )
    ).toBe(true)

    expect(
      isSupabaseUrl(
        'postgresql://postgres:password@db.ckpxcqqstnvzmhyziibg.supabase.co:5432/postgres'
      )
    ).toBe(true)

    expect(isSupabaseUrl('foo')).toBe(false)

    expect(isSupabaseUrl('postgresql://postgres@localhost:5432/postgres')).toBe(
      false
    )
  })
})
