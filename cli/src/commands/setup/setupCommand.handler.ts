import { needs } from "~/components/needs/index.js"
import { inputTargetDatabaseCloudUrl } from "../lib/inputTargetDatabaseUrl.js"

import c from 'ansi-colors'

export const handler = async () => {
  await inputTargetDatabaseCloudUrl()

  const paths = await needs.projectPathsV2()
  console.log(`Generated config: ${c.bold(paths.snapletConfig)}`)
}