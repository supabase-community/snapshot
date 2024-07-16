import { ConnectionString, ConnectionStringShape } from './ConnectionString.js'

export const isSupabaseUrl = (url: ConnectionStringShape): boolean => {
  try {
    const domain = new ConnectionString(url).domain
    return (
      domain.includes('supabase.co') || domain.includes('pooler.supabase.com')
    )
  } catch {
    return false
  }
}
