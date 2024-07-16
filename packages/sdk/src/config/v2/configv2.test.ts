import execa from 'execa'
import path from 'path'
import fs from 'fs'
import { copySync } from 'fs-extra'
import { generateTypes } from '../snapletConfig/v2/generateTypes/generateTypes.js'
import { generateTypes as generateDataClientTypes } from '~/generateOrm/generateTypes.js'
import { createSnapletTestDb, createTestTmpDirectory } from '~/testing.js'
import { introspectionToDataModel } from '~/generateOrm/dataModel/dataModel.js'
import { introspectDatabaseV3, withDbClient } from '~/exports/api.js'
// Just one dumb test to make jest happy.
// The "real" tests will be performed by tsc to make sure our config give
// us the expected types.

const FIXTURES_DIR = path.resolve(__dirname, '../../../__fixtures__')
const CONFIG_V2_TYPES_TESTS_DIR = path.resolve(FIXTURES_DIR, 'configs', 'v2')

test('config v2', async () => {
  const fakeSnapletDatabase = await createSnapletTestDb()
  const snapletIntrospect = await withDbClient(introspectDatabaseV3, {
    connString: fakeSnapletDatabase.toString(),
  })
  // We create a new temporary dir and copy our types tests + tsconfig.json which will be used
  // to assert the types in it
  const tmpDir = createTestTmpDirectory()
  // Copy our whole test directory structure to the tmp dir
  copySync(CONFIG_V2_TYPES_TESTS_DIR, tmpDir.name)
  // Then we generate the new .d.ts definitions types using our V2 config types generator
  // and write them into the destination directory
  const dataModel = introspectionToDataModel(snapletIntrospect)
  const typedDataClient = await generateDataClientTypes({ dataModel })
  fs.writeFileSync(
    path.join(tmpDir.name, '.snaplet', 'snaplet-client.d.ts'),
    typedDataClient
  )
  const typedGeneratedConfig = generateTypes(snapletIntrospect)
  fs.writeFileSync(
    path.join(tmpDir.name, '.snaplet', 'snaplet.d.ts'),
    typedGeneratedConfig
  )
  // Finally we run tsc to assert the types are correct and pass our tests
  const result = await execa('tsc', ['--noEmit', '--project', tmpDir.name])
  // tsc should have type-checked the config without any errors
  expect(result.exitCode).toBe(0)
})
