import tmp from 'tmp-promise'
import path from 'path'
import fs from 'fs-extra'
import {
  decryptSessionKey,
  generateSessionKey,
  generateRSAKeys,
  encryptAndCompressSnapshotFile,
  generateEncryptionPayload,
  hydrateEncryptionPayload,
  decompressAndDecrypt,
} from './crypto.js'

test('Ensure stable session key between operations', async () => {
  const { publicKey, privateKey } = await generateRSAKeys()

  const { key, encryptedKey } = await generateSessionKey(publicKey)

  const unencryptedKey = await decryptSessionKey(privateKey, encryptedKey)

  expect(new Uint8Array(key)).toEqual(unencryptedKey)
})

for (const version of ['1', '2'] as const) {
  test(`Version ${version}: Ensure encryption + decryption work together`, async () => {
    const { publicKey, privateKey } = await generateRSAKeys()

    const tmpDir = await tmp.dir()

    const projectPath = path.join(tmpDir.path, '.snaplet')

    await fs.mkdir(projectPath)

    const csvFile = {
      path: path.join(projectPath, 'test.csv'),
      content: 'actor_id,first_name,last_name,last_update\n'.concat(
        '1,Ludwig,Fahey,2006-02-15 09:34:33\n'.repeat(10)
      ),
    }

    await fs.writeFile(csvFile.path, csvFile.content)

    const payload = generateEncryptionPayload(publicKey, version)
    const hydratedPayload = hydrateEncryptionPayload(privateKey, payload.public)

    const result = await encryptAndCompressSnapshotFile(csvFile.path, payload)

    await fs.unlink(csvFile.path)

    await decompressAndDecrypt(
      result.compressedFilePath,
      result.compressedFilePath.replace('.br', ''),
      hydratedPayload
    )

    const readResult = await fs.readFile(csvFile.path, { encoding: 'utf-8' })

    expect(readResult).toEqual(csvFile.content)
  })
}
