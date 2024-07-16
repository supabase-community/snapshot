import { execQueryNext } from '@snaplet/sdk/cli'

export async function checkConstraints(
  sourceConnectionString: string,
  targetConnectionString: string,
  expectedMissingContraints: string[] = []
) {
  const sourceConstraintsResult = await execQueryNext(
    `SELECT con.conname
      FROM pg_catalog.pg_constraint con
      INNER JOIN pg_catalog.pg_class rel
            ON rel.oid = con.conrelid
      INNER JOIN pg_catalog.pg_namespace nsp
            ON nsp.oid = connamespace
      WHERE nsp.nspname = 'public';`,
    sourceConnectionString
  )

  const targetConstraintsResult = await execQueryNext(
    `SELECT con.conname
      FROM pg_catalog.pg_constraint con
      INNER JOIN pg_catalog.pg_class rel
            ON rel.oid = con.conrelid
      INNER JOIN pg_catalog.pg_namespace nsp
            ON nsp.oid = connamespace
      WHERE nsp.nspname = 'public';`,
    targetConnectionString
  )

  const sourceConstraints = sourceConstraintsResult.rows.map((c) => c.conname)
  const targetConstraints = targetConstraintsResult.rows.map((c) => c.conname)
  const missingTargetConstraints = sourceConstraints.filter(
    (c) => !targetConstraints.includes(c)
  )
  expect(missingTargetConstraints).toEqual(expectedMissingContraints)
}
