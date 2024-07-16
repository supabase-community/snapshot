import dotenv from 'dotenv-defaults'
import path from 'path'

const CLI_BASE_DIR = path.resolve(__dirname, '../../../../')

dotenv.config({
  defaults: path.resolve(CLI_BASE_DIR, '../.env.defaults'),
})
