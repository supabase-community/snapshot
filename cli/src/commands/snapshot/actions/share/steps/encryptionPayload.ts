import { generateEncryptionPayload } from "@snaplet/sdk/cli";
import { config } from "~/lib/config.js";
import { exitWithError } from "~/lib/exit.js";

export const encryptionPayloadStep = async () => {
  const { publicKey } = await config.getProject()
  if (publicKey) {
    return generateEncryptionPayload(publicKey)
  } else {
    console.log(
      'Error: Encryption is enabled, but public key not found, please use the "--no-encrypt" or create a public key'
    )
    await exitWithError('CONFIG_PK_NOT_FOUND')
  }
}