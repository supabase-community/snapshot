import c from 'ansi-colors'
import path from 'path'

export interface RestoreContext {
  filePath: string
  schema: string
  table: string
  columns: string[]
  row?: {
    line: number
    value: string
  }
}

export class RestoreError extends Error {
  constructor(
    public context: RestoreContext,
    message: string
  ) {
    super(message)
    this.context = context
    this.name = 'RestoreError'
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
    const relativeFilePath = path.relative(process.cwd(), this.context.filePath)
    const location = this.context.row?.line ? `:${this.context.row!.line}` : ''
    let rowError: string[] = []
    let marginLeft = ''
    const paddingLeft = ' '.repeat(2)
    if (this.context.row) {
      const header = this.context.columns.join(',')
      const lineNumber = `∙ ${this.context.row.line} │`
      marginLeft = ' '.repeat(lineNumber.length - 1)
      const hightlightBarRow = RestoreError.createHighlightBar(
        this.context.row.value.length,
        5
      )
      const pointerIndex = hightlightBarRow.indexOf('┬')
      const message = ' '.repeat(pointerIndex) + '╰────── ' + this.message
      rowError = [
        `${'1'.padStart(marginLeft.length - 1)} │${paddingLeft}${header}`,
        `${marginLeft}·`,
        `${marginLeft}·`,
        `${lineNumber.replace('∙', c.red('∙'))}${paddingLeft}${
          this.context.row.value
        }`,
        `${marginLeft}·${paddingLeft}${c.red(hightlightBarRow)}`,
        `${marginLeft}·${paddingLeft}${c.red(message)}`,
      ]
    } else {
      rowError = [`${marginLeft}·${paddingLeft}${c.red(this.message)}`]
    }

    return [
      `${marginLeft}┌─[${relativeFilePath}${location}]`,
      `${marginLeft}│`,
      ...rowError,
      `${marginLeft}│`,
      `${marginLeft}└─`,
    ].join('\n')
  }
}
