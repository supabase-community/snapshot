const steps = [
  { completed: 5, step: 'reading extensions' },
  { completed: 10, step: 'identifying extension members' },
  { completed: 15, step: 'reading schemas' },
  { completed: 20, step: 'reading user-defined tables' },
  { completed: 30, step: 'reading default privileges' },
  { completed: 35, step: 'reading user-defined collations' },
  { completed: 40, step: 'reading user-defined conversions' },
  { completed: 45, step: 'reading type casts' },
  { completed: 50, step: 'reading transforms' },
  { completed: 55, step: 'reading table inheritance information' },
  { completed: 60, step: 'reading event triggers' },
  { completed: 65, step: 'finding extension tables' },
  {
    completed: 70,
    step: 'finding inheritance relationships',
    message: 'reading table specific info...',
  },
  // After this step we read each table's columns and types so will take longer
  // We could in the future add a step for each table
  { completed: 90, step: 'reading rewrite rules' },
  { completed: 95, step: 'reading dependency data' },
]

export const getPgDumpProgress = (text: string) => {
  const step = steps.find((s) => text.includes(`pg_dump: ${s.step}`))
  if (step) {
    const message = step.message || `${step.step}...`
    return {
      step: 'schemas' as const,
      completed: step.completed,
      metadata: { message },
    }
  } else {
    return undefined
  }
}
