import { execQueryNext, hashPassword } from '@snaplet/sdk/cli'
import { sleep } from '~/lib/sleep.js'

async function getAccessToken(projectId: string) {
  const password = projectId + '-' + new Date().getTime()
  const hash = await hashPassword(password)
  // Get access token id

  const r = await execQueryNext(
    `
  SELECT "Member"."userId" FROM "Member"
	  INNER JOIN "Project" ON "Project"."organizationId" = "Member"."organizationId"
  	WHERE "Project".id = '${projectId}'
  LIMIT 1;`,
    process.env.DATABASE_URL!
  )

  const userId = r?.rows[0]?.userId
  if (!userId) {
    throw new Error(
      `No user id for project "${projectId}" . Please create one.`
    )
  }

  // Use the hash value as the ID because Prisma generates the id itself.
  const id = hash
  await execQueryNext(
    `INSERT INTO "AccessToken" ("id", "userId", "hash", "type", "updatedAt", "createdAt") VALUES ('${id}', '${userId}', '${hash}', 'CLI', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
    process.env.DATABASE_URL!
  )
  return password
}

// We don't reuse our execQueryNext function here, as they use the pooling
// and will create "openHandle" when used into beforeAll jest hooks
// Instead we prefer a raw client that we close at the end
export async function getTestAccessToken(
  projectId = process.env.SNAPLET_PROJECT_ID
) {
  try {
    return await getAccessToken(projectId!)
  } catch (e) {
    // Sometimes when running tests in parrallel we can get a conflict in the generated access token
    // this retry is here to mitigate that behavior, it's not perfect but it's better than nothing
    await sleep(2)
    return await getAccessToken(projectId!)
  }
}
