import { xdebug } from '@snaplet/sdk/cli'

const xdebugConfig = xdebug.extend('config') // snaplet:config
export const xdebugConfigGenerate = xdebugConfig.extend('generate') // snaplet:config:generate
