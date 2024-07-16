import { findWorkspaces } from 'find-workspaces'
import { readFile } from 'fs/promises'
import { parsePrismaSchema } from '@loancrate/prisma-schema-parser'
import fg from 'fast-glob'
import readPackage, { NormalizedPackageJson } from 'read-pkg'
import path from 'path'

type MigrationTool = {
  provider: 'prisma' | 'drizzle'
  path: string
  envVariable: string | null
}

export async function detectMigrationTool(rootPath: string) {
  const workspaces = findWorkspaces(rootPath, {
    stopDir: path.resolve(rootPath, '..'),
  })

  if (workspaces) {
    for (const workspace of workspaces) {
      const migrationTool = await detectMigrationToolInFolder({
        packageJson: workspace.package as NormalizedPackageJson,
        rootPath: workspace.location,
      })
      if (migrationTool) {
        return migrationTool
      }
    }
  }

  const packageJson = await readPackage({ cwd: rootPath })
  const migrationTool = await detectMigrationToolInFolder({
    packageJson,
    rootPath,
  })
  return migrationTool
}

async function detectMigrationToolInFolder({
  packageJson,
  rootPath,
}: {
  packageJson: NormalizedPackageJson
  rootPath: string
}): Promise<MigrationTool | null> {
  if (
    packageJson.dependencies?.['prisma'] ||
    packageJson.devDependencies?.['prisma']
  ) {
    return {
      path: rootPath,
      provider: 'prisma',
      envVariable: await getPrismaEnvVariable(rootPath),
    }
  } else if (
    packageJson.dependencies?.['drizzle-kit'] ||
    packageJson.devDependencies?.['drizzle-kit']
  ) {
    return {
      path: rootPath,
      provider: 'drizzle',
      envVariable: await getDrizzleEnvVariable(rootPath),
    }
  }

  return null
}

async function getPrismaEnvVariable(rootPath: string) {
  const [prismaSchemaPath] = await fg(
    path.posix.join(rootPath, '**', 'schema.prisma'),
    {
      cwd: rootPath,
      absolute: true,
      ignore: ['**/node_modules/**'],
    }
  )

  if (!prismaSchemaPath) {
    return null
  }

  const prismaSchema = await readFile(prismaSchemaPath, 'utf-8')

  const parsedPrismaSchema = parsePrismaSchema(prismaSchema)

  for (const declaration of parsedPrismaSchema.declarations) {
    if (
      declaration.kind === 'datasource' &&
      declaration.name.value === 'db' &&
      declaration.members.find(
        (m) =>
          m.kind === 'config' &&
          m.name.value === 'provider' &&
          m.value.kind === 'literal' &&
          m.value.value === 'postgresql'
      )
    ) {
      for (const member of declaration.members) {
        if (
          member.kind === 'config' &&
          member.name.value === 'url' &&
          member.value.kind === 'functionCall' &&
          member.value.path.value[0] === 'env' &&
          member.value.args?.[0].kind === 'literal'
        ) {
          return (member.value.args?.[0].value as string) ?? null
        }
      }
    }
  }

  return null
}

async function getDrizzleEnvVariable(rootPath: string) {
  const [drizzleConfigPath] = await fg(
    path.posix.join(rootPath, '**', 'drizzle.config.{js,ts}'),
    {
      cwd: rootPath,
      absolute: true,
      ignore: ['**/node_modules/**'],
    }
  )

  if (!drizzleConfigPath) {
    return null
  }

  const drizzleConfig = await readFile(drizzleConfigPath, 'utf-8')

  const match = drizzleConfig.match(/connectionString:\s*process\.env\.(\w+)/)

  return match?.[1] ?? null
}
