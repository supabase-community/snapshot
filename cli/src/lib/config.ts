import { Configuration } from '@snaplet/sdk/cli'

const config = new Configuration()

function getConfig() {
  return config
}

export { config, getConfig }
