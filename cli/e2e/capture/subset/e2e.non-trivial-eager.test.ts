import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
  checkConstraints,
} from '../../../src/testing/index.js'
import fs from 'fs'
import fsExtra from 'fs-extra'
import path from 'path'

import { splitSchema } from '../../../src/commands/snapshot/actions/restore/lib/pgSchemaTools.js'

vi.setConfig({
  testTimeout: 10 * 60 * 1000,
})

const FIXTURES_DIR = path.resolve(__dirname, '../../../__fixtures__')

async function loadDbDumpFixture(
  // The dump must be a .sql file located into __fixtures__
  dumpName: string,
  connectionString: string
) {
  const fileContent = fs
    .readFileSync(path.join(FIXTURES_DIR, dumpName))
    .toString('utf-8')
  const queries = splitSchema(fileContent)
  for (const stmt of queries) {
    try {
      await execQueryNext(stmt, connectionString)
    } catch (e) {
      console.log(stmt)
      console.log(e)
      throw e
    }
  }
}

test('capturing and restoring a non-trivial database folders entrypoint eagerly', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture(
    'non-trivial-database.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      maxCyclesLoop: 10,
      eager: true,
      keepDisconnectedTables: true,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.folders',
          where: "folders.id = 'd1533f47-afc9-4f98-aa74-c954fbec6000'",
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)

  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  const restoredProjectToUsers = await execQueryNext(
    'SELECT * FROM projects_to_users',
    targetConnectionString
  )
  const restoredFileVersions = await execQueryNext(
    'SELECT * FROM file_versions',
    targetConnectionString
  )
  const restoredTasks = await execQueryNext(
    'SELECT * FROM tasks',
    targetConnectionString
  )
  const restoredFiles = await execQueryNext(
    'SELECT * FROM files',
    targetConnectionString
  )
  const restoredFolders = await execQueryNext(
    'SELECT * FROM folders',
    targetConnectionString
  )
  const restoredUsers = await execQueryNext(
    'SELECT * FROM users',
    targetConnectionString
  )

  expect(restoredProjectToUsers.rowCount).toBe(48)
  expect(restoredFolders.rowCount).toBe(47)
  expect(restoredFileVersions.rowCount).toBe(42)
  expect(restoredFiles.rowCount).toBe(40)
  expect(restoredTasks.rowCount).toBe(27)
  expect(restoredUsers.rowCount).toBe(19)
})
test('capturing and restoring a non-trivial database projects entrypoint eagerly', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture(
    'non-trivial-database.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      maxCyclesLoop: 10,
      eager: true,
      keepDisconnectedTables: true,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.projects',
          where: "projects.name = 'Tour Eiffel'",
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )

  // test created and extracted by using slice-db
  const expectedResult = [
    { relname: 'file_version_wopi', rowcount: '0' },
    { relname: 'user_metadatas', rowcount: '0' },
    { relname: 'task_validation_migrations', rowcount: '0' },
    { relname: 't_folder_pwd', rowcount: '0' },
    { relname: 'file_label_migrations', rowcount: '0' },
    { relname: 'task_locations', rowcount: '0' },
    { relname: 'org_project_summary_migrations', rowcount: '0' },
    { relname: 'project_member_migrations', rowcount: '0' },
    { relname: 'user_migrations', rowcount: '0' },
    { relname: 'org_migrations', rowcount: '0' },
    { relname: 'project_views', rowcount: '0' },
    { relname: 'presigned_urls', rowcount: '0' },
    { relname: 'project_labels_migrations', rowcount: '0' },
    { relname: 'file_version_approval_migrations', rowcount: '0' },
    { relname: 'task_assignation_migrations', rowcount: '0' },
    { relname: 'org_member_migrations', rowcount: '0' },
    { relname: 'events_workers_status', rowcount: '0' },
    { relname: 'project_categories_migrations', rowcount: '0' },
    { relname: 'folder_migrations', rowcount: '0' },
    { relname: 'file_views', rowcount: '0' },
    { relname: 'file_migrations', rowcount: '0' },
    { relname: 'folder_label_migrations', rowcount: '0' },
    { relname: 'folder_assignation_migrations', rowcount: '0' },
    { relname: 'project_migrations', rowcount: '0' },
    { relname: 'file_version_migrations', rowcount: '0' },
    { relname: 't_folder_notification_badge', rowcount: '0' },
    { relname: 'task_label_migrations', rowcount: '0' },
    { relname: 'folder_views', rowcount: '0' },
    { relname: 'file_assignation_migrations', rowcount: '0' },
    { relname: 'task_attachment_migrations', rowcount: '0' },
    { relname: 'org_licenses', rowcount: '0' },
    { relname: 'task_migrations', rowcount: '0' },
    { relname: 'subtask_migrations', rowcount: '0' },
    { relname: 'team_migrations', rowcount: '0' },
    { relname: 'file_permissions_teams', rowcount: '1' },
    { relname: 'file_permissions_users', rowcount: '1' },
    { relname: 'project_templates', rowcount: '1' },
    { relname: 'file_permissions', rowcount: '1' },
    { relname: 'folder_assignations_users', rowcount: '1' },
    { relname: 'file_assignations_orgs', rowcount: '1' },
    { relname: 'push_notifications', rowcount: '1' },
    { relname: 'file_assignations_teams', rowcount: '1' },
    { relname: 'folder_assignations_orgs', rowcount: '1' },
    { relname: 'file_permissions_orgs', rowcount: '1' },
    { relname: 'user_actions', rowcount: '1' },
    { relname: 'task_views', rowcount: '1' },
    { relname: 'file_signatures', rowcount: '1' },
    { relname: 'orgs_to_user_actions', rowcount: '1' },
    { relname: 'folder_permissions_users', rowcount: '1' },
    { relname: 'folder_assignations_teams', rowcount: '1' },
    { relname: 'folder_permissions_orgs', rowcount: '1' },
    { relname: 'folder_assignations', rowcount: '1' },
    { relname: 'folder_permissions_teams', rowcount: '1' },
    { relname: 'user_devices', rowcount: '1' },
    { relname: 'file_access_enum', rowcount: '2' },
    { relname: 'user_avatars', rowcount: '2' },
    { relname: 'folder_access_enum', rowcount: '2' },
    { relname: 'user_connections', rowcount: '2' },
    { relname: 'org_backgrounds', rowcount: '2' },
    { relname: 'folder_permissions', rowcount: '2' },
    { relname: 'org_avatars', rowcount: '2' },
    { relname: 'user_notifications', rowcount: '2' },
    { relname: 'user_locations', rowcount: '2' },
    { relname: 'events', rowcount: '3' },
    { relname: 'project_banners', rowcount: '3' },
    { relname: 'org_address', rowcount: '3' },
    { relname: 'folders_to_project_labels', rowcount: '3' },
    { relname: 'file_comments', rowcount: '3' },
    { relname: 'project_backgrounds', rowcount: '3' },
    { relname: 'project_avatars', rowcount: '4' },
    { relname: 'task_validations', rowcount: '4' },
    { relname: 'files_to_project_labels', rowcount: '4' },
    { relname: 'file_approvals_status_enum', rowcount: '4' },
    { relname: 'file_assignations', rowcount: '4' },
    { relname: 'orgs', rowcount: '5' },
    { relname: 'teams_to_users', rowcount: '5' },
    { relname: 'project_roles', rowcount: '5' },
    { relname: 'org_roles', rowcount: '5' },
    { relname: 'teams', rowcount: '6' },
    { relname: 'task_file_version_location', rowcount: '7' },
    { relname: 'file_version_approval_requests', rowcount: '7' },
    { relname: 'tasks_file_versions', rowcount: '7' },
    { relname: 'file_approvals', rowcount: '7' },
    { relname: 'task_attachments', rowcount: '10' },
    { relname: 'task_assignations_orgs', rowcount: '11' },
    { relname: 'email_notifications', rowcount: '11' },
    { relname: 'project_categories', rowcount: '11' },
    { relname: 'project_labels', rowcount: '11' },
    {
      relname: 'org_project_summary_to_project_categories',
      rowcount: '12',
    },
    { relname: 'project_address', rowcount: '12' },
    { relname: 'task_assignations_users', rowcount: '13' },
    { relname: 'task_assignations_teams', rowcount: '13' },
    { relname: 'org_project_summary', rowcount: '14' },
    { relname: 'orgs_to_users', rowcount: '16' },
    { relname: 'file_assignations_users', rowcount: '19' },
    { relname: 'projects', rowcount: '19' },
    { relname: 'users', rowcount: '19' },
    { relname: 'task_assignations', rowcount: '25' },
    { relname: 'tasks', rowcount: '27' },
    { relname: 'file_version_approval_request_users', rowcount: '27' },
    { relname: 'task_subtasks', rowcount: '29' },
    { relname: 'tasks_to_project_labels', rowcount: '32' },
    { relname: 'files', rowcount: '40' },
    { relname: 'file_versions', rowcount: '42' },
    { relname: 'folders', rowcount: '47' },
    { relname: 'projects_to_users', rowcount: '48' },
  ]

  const tablesCounts = await execQueryNext<{
    relname: string
    count: string
  }>(
    expectedResult
      .map(
        (r) =>
          `SELECT '${r.relname}'::text as relname, count(*)::text as rowcount FROM ${r.relname}`
      )
      .join(' UNION ALL '),
    targetConnectionString.toString()
  )
  for (const count of tablesCounts.rows) {
    const expectedCount = expectedResult.find(
      (e) => e.relname === count.relname
    )
    expect(count).toEqual(expectedCount)
  }
})
test('capturing and restoring a non-trivial database user isolated entrypoint eagerly', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture(
    'non-trivial-database.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      maxCyclesLoop: 10,
      eager: true,
      keepDisconnectedTables: false,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.users',
          where: "users.email = 'isolated@test.com'",
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  const restoredProjectToUsers = await execQueryNext(
    'SELECT * FROM projects_to_users',
    targetConnectionString
  )
  const restoredFileVersions = await execQueryNext(
    'SELECT * FROM file_versions',
    targetConnectionString
  )
  const restoredFiles = await execQueryNext(
    'SELECT * FROM files',
    targetConnectionString
  )
  const restoredFolders = await execQueryNext(
    'SELECT * FROM folders',
    targetConnectionString
  )
  const restoredUsers = await execQueryNext(
    'SELECT * FROM users',
    targetConnectionString
  )

  expect(restoredProjectToUsers.rowCount).toBe(0)
  expect(restoredFileVersions.rowCount).toBe(0)
  expect(restoredFiles.rowCount).toBe(0)
  expect(restoredFolders.rowCount).toBe(0)
  expect(restoredUsers.rowCount).toBe(1)
})
test('capturing and restoring a non-trivial database user entrypoint eagerly', async () => {
  const sourceConnectionString = await createTestDb()
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()

  // Setup our database
  // user -> primary_db_id, secondary_db_id -> db
  await loadDbDumpFixture(
    'non-trivial-database.sql',
    sourceConnectionString.toString()
  )
  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,
      maxCyclesLoop: 10,
      eager: true,
      keepDisconnectedTables: true,
      followNullableRelations: true,
      targets: [
        {
          table: 'public.users',
          where: "users.email = 'withoutorg@test.com'",
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  // test created and extracted by using slice-db
  const expectedResult = [
    { relname: 'email_notifications', rowcount: '11' },
    { relname: 'events', rowcount: '3' },
    { relname: 'events_workers_status', rowcount: '0' },
    { relname: 'file_access_enum', rowcount: '2' },
    { relname: 'file_approvals', rowcount: '7' },
    { relname: 'file_approvals_status_enum', rowcount: '4' },
    { relname: 'file_assignation_migrations', rowcount: '0' },
    { relname: 'file_assignations', rowcount: '4' },
    { relname: 'file_assignations_orgs', rowcount: '1' },
    { relname: 'file_assignations_teams', rowcount: '1' },
    { relname: 'file_assignations_users', rowcount: '19' },
    { relname: 'file_comments', rowcount: '3' },
    { relname: 'file_label_migrations', rowcount: '0' },
    { relname: 'file_migrations', rowcount: '0' },
    { relname: 'file_permissions', rowcount: '1' },
    { relname: 'file_permissions_orgs', rowcount: '1' },
    { relname: 'file_permissions_teams', rowcount: '1' },
    { relname: 'file_permissions_users', rowcount: '1' },
    { relname: 'file_signatures', rowcount: '1' },
    { relname: 'file_version_approval_migrations', rowcount: '0' },
    { relname: 'file_version_approval_request_users', rowcount: '27' },
    { relname: 'file_version_approval_requests', rowcount: '7' },
    { relname: 'file_version_migrations', rowcount: '0' },
    { relname: 'file_version_wopi', rowcount: '0' },
    { relname: 'file_versions', rowcount: '42' },
    { relname: 'file_views', rowcount: '0' },
    { relname: 'files', rowcount: '40' },
    { relname: 'files_to_project_labels', rowcount: '4' },
    { relname: 'folder_access_enum', rowcount: '2' },
    { relname: 'folder_assignation_migrations', rowcount: '0' },
    { relname: 'folder_assignations', rowcount: '1' },
    { relname: 'folder_assignations_orgs', rowcount: '1' },
    { relname: 'folder_assignations_teams', rowcount: '1' },
    { relname: 'folder_assignations_users', rowcount: '1' },
    { relname: 'folder_label_migrations', rowcount: '0' },
    { relname: 'folder_migrations', rowcount: '0' },
    { relname: 'folder_permissions', rowcount: '2' },
    { relname: 'folder_permissions_orgs', rowcount: '1' },
    { relname: 'folder_permissions_teams', rowcount: '1' },
    { relname: 'folder_permissions_users', rowcount: '1' },
    { relname: 'folder_views', rowcount: '0' },
    { relname: 'folders', rowcount: '47' },
    { relname: 'folders_to_project_labels', rowcount: '3' },
    { relname: 'org_address', rowcount: '3' },
    { relname: 'org_avatars', rowcount: '2' },
    { relname: 'org_backgrounds', rowcount: '2' },
    { relname: 'org_licenses', rowcount: '0' },
    { relname: 'org_member_migrations', rowcount: '0' },
    { relname: 'org_migrations', rowcount: '0' },
    { relname: 'org_project_summary', rowcount: '14' },
    { relname: 'org_project_summary_migrations', rowcount: '0' },
    {
      relname: 'org_project_summary_to_project_categories',
      rowcount: '12',
    },
    { relname: 'org_roles', rowcount: '5' },
    { relname: 'orgs', rowcount: '5' },
    { relname: 'orgs_to_user_actions', rowcount: '1' },
    { relname: 'orgs_to_users', rowcount: '16' },
    { relname: 'presigned_urls', rowcount: '0' },
    { relname: 'project_address', rowcount: '12' },
    { relname: 'project_avatars', rowcount: '4' },
    { relname: 'project_backgrounds', rowcount: '3' },
    { relname: 'project_banners', rowcount: '3' },
    { relname: 'project_categories', rowcount: '11' },
    { relname: 'project_categories_migrations', rowcount: '0' },
    { relname: 'project_labels', rowcount: '11' },
    { relname: 'project_labels_migrations', rowcount: '0' },
    { relname: 'project_member_migrations', rowcount: '0' },
    { relname: 'project_migrations', rowcount: '0' },
    { relname: 'project_roles', rowcount: '5' },
    { relname: 'project_templates', rowcount: '1' },
    { relname: 'project_views', rowcount: '0' },
    { relname: 'projects', rowcount: '19' },
    { relname: 'projects_to_users', rowcount: '48' },
    { relname: 'push_notifications', rowcount: '1' },
    { relname: 'subtask_migrations', rowcount: '0' },
    { relname: 't_folder_notification_badge', rowcount: '0' },
    { relname: 't_folder_pwd', rowcount: '0' },
    { relname: 'task_assignation_migrations', rowcount: '0' },
    { relname: 'task_assignations', rowcount: '25' },
    { relname: 'task_assignations_orgs', rowcount: '11' },
    { relname: 'task_assignations_teams', rowcount: '13' },
    { relname: 'task_assignations_users', rowcount: '13' },
    { relname: 'task_attachment_migrations', rowcount: '0' },
    { relname: 'task_attachments', rowcount: '10' },
    { relname: 'task_file_version_location', rowcount: '7' },
    { relname: 'task_label_migrations', rowcount: '0' },
    { relname: 'task_locations', rowcount: '0' },
    { relname: 'task_migrations', rowcount: '0' },
    { relname: 'task_subtasks', rowcount: '29' },
    { relname: 'task_validation_migrations', rowcount: '0' },
    { relname: 'task_validations', rowcount: '4' },
    { relname: 'task_views', rowcount: '1' },
    { relname: 'tasks', rowcount: '27' },
    { relname: 'tasks_file_versions', rowcount: '7' },
    { relname: 'tasks_to_project_labels', rowcount: '32' },
    { relname: 'team_migrations', rowcount: '0' },
    { relname: 'teams', rowcount: '6' },
    { relname: 'teams_to_users', rowcount: '5' },
    { relname: 'user_actions', rowcount: '1' },
    { relname: 'user_avatars', rowcount: '2' },
    { relname: 'user_connections', rowcount: '2' },
    { relname: 'user_devices', rowcount: '1' },
    { relname: 'user_locations', rowcount: '2' },
    { relname: 'user_metadatas', rowcount: '0' },
    { relname: 'user_migrations', rowcount: '0' },
    { relname: 'user_notifications', rowcount: '2' },
    { relname: 'users', rowcount: '19' },
  ]

  const tablesCounts = await execQueryNext<{
    relname: string
    count: string
  }>(
    expectedResult
      .map(
        (r) =>
          `SELECT '${r.relname}'::text as relname, count(*)::text as rowcount FROM ${r.relname}`
      )
      .join(' UNION ALL '),
    targetConnectionString.toString()
  )
  for (const count of tablesCounts.rows) {
    const expectedCount = expectedResult.find(
      (e) => e.relname === count.relname
    )
    expect(count).toEqual(expectedCount)
  }
})
