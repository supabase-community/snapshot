import c from 'ansi-colors'
import { stringify } from 'csv-stringify/sync'
import wrap from 'word-wrap'

import type { TransformContext } from './types.js'

export class TransformError extends Error {
  error: Error

  constructor(
    public context: TransformContext,
    rawError: Error | string
  ) {
    const error = typeof rawError === 'string' ? new Error(rawError) : rawError
    super(error.message)
    this.error = error
    this.context = context
    this.name = 'TransformError'
  }

  static createHighlightBar(
    length: number,
    pointerIndex: number = Math.trunc(length / 2)
  ): string {
    const bar = '─'.repeat(length)
    return (
      bar.substring(0, pointerIndex) + '┬' + bar.substring(pointerIndex + 1)
    )
  }

  toString(): string {
    const table = `"${this.context.schema}"."${this.context.table}"`
    const lineNumber = `∙ ${
      this.context.row.line ? this.context.row.line + 1 : 2
    } │`
    const marginLeft = ' '.repeat(lineNumber.length - 1)
    const paddingLeft = '  '
    const row = Object.fromEntries(
      Object.entries(this.context.row.raw).map(([key, value]) => [
        key,
        // We alter the value for displaying purpose, we don't want multiline csv row
        String(value).replace(/\n/g, ' ').replace(/\r/g, ''),
      ])
    )
    const [header, raw] = stringify([row], {
      columns: this.context.columns,
      header: true,
      record_delimiter: 'unix',
    }).split('\n')
    let hightlightBarRow = TransformError.createHighlightBar(raw.length, 5)
    let pointerIndex = hightlightBarRow.indexOf('┬')

    const computeMessageLine = () => {
      let prefix
      let indent
      const longLineThreshold = 100
      const isTooCloseToEnd =
        pointerIndex + this.message.length > longLineThreshold

      if (isTooCloseToEnd) {
        prefix = ' \n'
        indent = marginLeft + '∙ '
      } else {
        prefix = ' '.repeat(pointerIndex) + '╰────── '
        indent = marginLeft + '∙' + ' '.repeat(prefix.length + 2)
      }

      return (
        prefix +
        wrap(this.message, {
          width: longLineThreshold,
          indent,
        }).slice(isTooCloseToEnd ? 0 : indent.length)
      )
    }

    let message = computeMessageLine()

    if (this.context.column) {
      const value = this.context.row.raw[this.context.column]
      const from = raw.indexOf(String(value))
      const to = from + String(value).length
      const length = to - from
      const highlightBar = TransformError.createHighlightBar(length)
      hightlightBarRow = ' '.repeat(from) + highlightBar
      pointerIndex = hightlightBarRow.indexOf('┬')
      message = computeMessageLine()
    }

    return [
      `${marginLeft}┌─[${table}]`,
      `${marginLeft}│`,
      `${'1'.padStart(marginLeft.length - 1)} │${paddingLeft}${header}`,
      `${marginLeft}·`,
      `${marginLeft}·`,
      `${lineNumber.replace('∙', c.red('∙'))}${paddingLeft}${raw}`,
      `${marginLeft}·${paddingLeft}${c.red(hightlightBarRow)}`,
      `${marginLeft}·${paddingLeft}${c.red(message)}`,
      `${marginLeft}│`,
      `${marginLeft}└─`,
    ].join('\n')
  }
}
