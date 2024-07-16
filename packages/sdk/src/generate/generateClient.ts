import { mkdirp, writeFile } from 'fs-extra'
import path from 'path'
import { TableShapePredictions } from '~/db/structure.js'
import { SnapletError } from '~/errors.js'
import { generateTypes } from '../generateOrm/generateTypes.js'
import type { Fingerprint, DataModel } from '~/generateOrm/index.js'
import { generateModelDefaults } from './generateModelDefaults/generateModelDefaults.js'
import { IntrospectedStructure } from '~/db/introspect/introspectDatabase.js'
import { silent as resolveFrom } from 'resolve-from'
import findupSync from 'findup-sync'

export interface GenerateClientContext {
  dataModel: DataModel
  outputDir?: string
  introspection: IntrospectedStructure
  shapePredictions: TableShapePredictions[]
  shapeExamples: { shape: string; examples: string[] }[]
  fingerprint: Fingerprint
  isCopycatNext?: boolean
}

const FILES: Record<
  string,
  {
    name: string
    template: (context: GenerateClientContext) => string | Promise<string>
  }
> = {
  PKG: {
    name: 'package.json',
    template() {
      return `{
  "name": ".snaplet",
  "main": "index.js"
}`
    },
  },
  INDEX: {
    name: 'index.js',
    template() {
      return `
Object.defineProperty(exports, "__esModule", { value: true })

const { getSeedClient } = require("@snaplet/seed/runtime/pg")
const { config } = require("@snaplet/seed")

const dataModel = require("./${FILES.DATA_MODEL.name}")
const { modelDefaults } = require("./${FILES.MODEL_DEFAULTS.name}")

exports.createSeedClient = getSeedClient(dataModel, modelDefaults, config)
`
    },
  },
  TYPEDEFS: {
    name: 'index.d.ts',
    template({ dataModel, fingerprint }) {
      return generateTypes({ dataModel, fingerprint })
    },
  },
  DATA_MODEL: {
    name: 'dataModel.json',
    template({ dataModel }) {
      return JSON.stringify(dataModel)
    },
  },
  MODEL_DEFAULTS: {
    name: 'modelDefaults.js',
    async template({
      dataModel,
      introspection,
      shapePredictions,
      shapeExamples,
      fingerprint,
      isCopycatNext,
    }) {
      return await generateModelDefaults({
        dataModel,
        introspection,
        shapePredictions,
        shapeExamples,
        fingerprint,
        isCopycatNext,
      })
    },
  },
  SHAPE_EXAMPLES: {
    name: 'shapeExamples.json',
    async template({ shapeExamples }) {
      return JSON.stringify(shapeExamples)
    },
  },
}

const findPackageDirPath = () => {
  const cwd = process.env.SNAPLET_CWD ?? process.cwd()
  const pkgPath = resolveFrom(cwd, '@snaplet/seed')
  if (pkgPath == null) {
    throw new SnapletError('SNAPLET_CLIENT_PACKAGE_NOT_FOUND')
  }

  // context(justinvdm, 7 November 2023): `pkgPath` would look something like:
  // `/project/path/node_modules/@snaplet/seed/dist/index.cjs`.
  //
  // We want `/project/path/node_modules/.snaplet`
  const result = path.resolve(
    path.dirname(pkgPath),
    '..',
    '..',
    '..',
    '.snaplet'
  )

  if (result.includes('node_modules')) {
    return result
  }

  const packagePath = findupSync('package.json', { cwd })

  // context(justinvdm, 17 Jan 2024): This branch accomodates cases where `@snaplet/seed` is symlinked to
  // a place outside of node_modules.
  //
  // This includes our own monorepo case - ideally we're running `snaplet generate` the same way users are
  if (packagePath) {
    return path.resolve(path.dirname(packagePath), 'node_modules', '.snaplet')
  }

  return result
}

export const generateClient = async (context: GenerateClientContext) => {
  const packageDirPath = context.outputDir ?? findPackageDirPath()
  await mkdirp(packageDirPath)

  for (const file of Object.values(FILES)) {
    const filePath = path.join(packageDirPath, file.name)
    await writeFile(filePath, await file.template(context))
  }
}
