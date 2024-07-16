import { format as utilFormat } from 'util'
import { fmt } from './format.js'

// context(justinvdm, 5 Sep 2023): The idea is to use this wherever we want to display messages to the user in the
// console. We log to stderr so that we can use stdout for piping (e.g. snaplet generate --sql)
export const display = (...args: unknown[]) =>
  process.stderr.write(['\n', fmt(utilFormat(...args)), '\n', '\n'].join(''))
