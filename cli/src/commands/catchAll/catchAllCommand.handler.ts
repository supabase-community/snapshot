import c from 'ansi-colors'
import type { Argv } from 'yargs'
import yargs from 'yargs'

export async function handler(argv: Awaited<Argv['argv']>) {
  const deprecated: Record<string, [string, string?]> = {
    restore: ['snapshot restore', 'ss r'],
    list: ['snapshot list', 'ss ls'],
    ls: ['snapshot list', 'ss ls'],
    login: ['auth login'],
  }
  const [old] = argv._
  if (deprecated[old]) {
    const oldCommand = c.magenta('"snaplet ' + old + '"')
    let newCommand = c.magenta('"snaplet ' + deprecated[old][0] + '"')
    if (deprecated[old][1]) {
      newCommand += c.magenta(` (snaplet ${deprecated[old][1]})`)
    }
    console.log()
    console.log(
      c.yellow(
        `ERROR: ${oldCommand} is deprecated.\nPlease use ${newCommand} instead.`
      )
    )
    console.log()
  } else {
    yargs.showHelp()
  }
}
