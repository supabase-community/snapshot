import { createTestDb } from '../../../testing.js'
import { withDbClient } from '../../client.js'
import { fetchServerVersion } from './fetchServerVersion.js'

test('should retrieve server version', async () => {
  const connString = await createTestDb()
  const serverVersion = await withDbClient(fetchServerVersion, {
    connString: connString.toString(),
  })
  expect(serverVersion).toMatch(/\d+\.\d+/)
})
