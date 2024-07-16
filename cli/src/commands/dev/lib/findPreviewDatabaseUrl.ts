import { trpc } from '~/lib/trpc.js'

export async function findPreviewDatabaseUrl({
  projectId,
  previewDatabaseName,
}: {
  projectId: string
  previewDatabaseName: string
}) {
  const previewDatabase = await trpc.previewDatabase.find.query({
    projectId,
    name: previewDatabaseName,
  })

  return previewDatabase?.connectionUrl ?? null
}
