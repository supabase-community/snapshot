import c from 'ansi-colors'
import dedent from 'dedent'

export function fmt(
  ...message: string[] | TemplateStringsArray | [TemplateStringsArray]
) {
  return dedent(message.join(' ').trim())
    .replace(/^# (.*$)/gim, c.bold('$1'))
    .replace(/\*\*(.+?)\*\*/gim, c.bold('$1'))
    .replace(/\__(.+?)\__/gim, c.italic('$1'))
}
