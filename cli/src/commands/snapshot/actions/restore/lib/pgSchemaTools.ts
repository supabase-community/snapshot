export function isComment(line: string) {
  return line.trim().startsWith('--')
}

export function splitSchema(schema: string) {
  const lines = schema.split('\n').map((line) => line.trim())
  const statements: string[][] = []
  let groupIndex = 0
  for (const line of lines) {
    if (line && !isComment(line) && line !== 'CREATE SCHEMA public;') {
      statements[groupIndex] = [...(statements[groupIndex] ?? []), line]
    }
    if (line.startsWith('-- Name:')) {
      groupIndex += 1
    }
  }
  return statements
    .filter((group) => group !== null)
    .map((group) => group.join('\n'))
}
