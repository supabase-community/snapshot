import { DatabaseClient, escapeLiteral } from '@snaplet/sdk/cli'

// We you call this function, you should call transactionEnd to end the transaction
// and release the snapshot
export async function getPgSnapshotId(client: DatabaseClient) {
  await client.query(
    'BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;'
  )
  const pgSnapshotQuery = await client.query<{ pgSnapshotId: string }>(
    'SELECT pg_export_snapshot() as "pgSnapshotId"'
  )
  const pgSnapshotId = pgSnapshotQuery.rows[0].pgSnapshotId
  // To avoid the transaction to be killed by idle_transaction_timeout parameter
  // we keep it warm by perfomring a dummy query every 10s
  // Note: idle_transaction_timeout is disabled in postgresql per default but some
  // DB provider (Supabase, Neon) set a default value for it
  const keepAliveInterval = setInterval(async () => {
    await client.query('SELECT 1;')
  }, 10_000)
  return {
    pgSnapshotId,
    transactionEnd: async () => {
      clearInterval(keepAliveInterval)
      await client.query('COMMIT;')
    },
  }
}

export async function setTransactionSnapshotId(
  client: DatabaseClient,
  pgSnapshotId?: string
) {
  await client.query(`
    BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;
  `)
  if (pgSnapshotId) {
    await client.query(
      `SET TRANSACTION SNAPSHOT ${escapeLiteral(pgSnapshotId)};`
    )
  }
  return {
    pgSnapshotId,
    transactionEnd: async () => {
      await client.query('COMMIT;')
    },
  }
}

// Will be used accross the subset / capture process
// with pg_export_snapshot to ensure every query is consistent with the same snapshot
export type PgSnapshotConnection = {
  pgSnapshotId?: string
  connString: string
  client?: DatabaseClient
}
