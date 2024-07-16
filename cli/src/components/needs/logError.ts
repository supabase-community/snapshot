import c from 'ansi-colors'
import wordwrap from 'word-wrap'
import { display } from '~/lib/display.js'

export const logError = (message: string[], example?: string) => {
  const m = wordwrap(`${c.red('✖')} ${message.join('\n')}`, { width: 80 })
  const e = example
    ? wordwrap(`${c.blue('i')} ${example}`, { width: 80 })
    : undefined

  display(m)

  if (e) {
    display(e)
  }
}
