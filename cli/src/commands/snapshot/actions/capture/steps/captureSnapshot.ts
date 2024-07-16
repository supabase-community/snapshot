import {
  calculateIncludedTables,
  Configuration,
  IntrospectedStructure,
} from '@snaplet/sdk/cli'
import fs from 'fs-extra'
import path from 'path'

import { needs } from '~/components/needs/index.js'

import type { getSnapshotPaths } from '../lib/paths.js'
import { pgDump } from '../lib/pgDump.js'
import {
  runCaptureV3,
  runSubsetAndCaptureV3,
  runOnlyCaptureV3,
} from '../lib/subsetV3/steps/runCaptureV3.js'
import { EventEmitter } from 'stream'
import { SnapshotCaptureEventEmitter } from '../lib/subsetV3/steps/events.js'
import {
  OnChangeHandler,
  emitterToOnUpdateProxy,
} from '../lib/subsetV3/steps/emitterToOnUpdate.js'

interface Snapshot {
  structure: IntrospectedStructure
  paths: Awaited<ReturnType<typeof getSnapshotPaths>>
  config: Configuration
}

export const captureSnapshot = async (
  options: Snapshot,
  onChange: OnChangeHandler
) => {
  const { structure, paths, config } = options
  const schemasConfig = await config.getSchemas()
  const subsetConfig = await config.getSubset()
  const introspectConfig = await config.getIntrospect()
  const transform = await config.getRuntimeTransform(structure)
  // let's make sure we have pg_dump available
  await needs.pgDumpCliCommand()

  const connectionUrl = await needs.sourceDatabaseUrl()
  // we ensure that we can't make any write operations
  connectionUrl.setReadOnly(true)
  const connString = connectionUrl.toString()

  await onChange('structure', structure)

  // we need to calculate schemas and tables to copy
  const tablesToCopy = calculateIncludedTables(
    structure['tables'],
    schemasConfig
  )
  await onChange('tables', tablesToCopy)
  await onChange('progress', {
    step: 'schemas',
    completed: 0,
  })
  const schemaDump = await pgDump(
    connString,
    structure,
    schemasConfig,
    onChange
  )
  // context(peterp, 06 April 2022): TODO: We update the "SourceDatabase.schema" and "Snapshot.schema" tables
  // with this information in order to debug. We will at some stage only upload these to S3,
  // and create a way to retrieve these in order to debug.
  console.log(`Saving database schema to: ${paths.schemas}`)
  await fs.writeFile(paths.schemas, schemaDump)
  await onChange('schema', schemaDump)
  await onChange('progress', {
    step: 'schemas',
    completed: 100,
  })
  const subsetFile = path.join(paths.base, 'subset.sqlite')
  if (subsetConfig?.enabled) {
    await onChange('progress', {
      step: 'subset',
      completed: 0,
    })
    const eventsEmitter = new EventEmitter() as SnapshotCaptureEventEmitter
    // This function will proxy all typed events comming from our event emitter to the onChange
    // function which will perform api calls / update the UI
    emitterToOnUpdateProxy(eventsEmitter, onChange)
    eventsEmitter.on('dumpTablesStart', () => {
      console.log(`Copying files to: ${paths?.tables}`)
    })
    if (fs.existsSync(subsetFile)) {
      console.log('Subset ready, using file: ', subsetFile)
      return await runCaptureV3(connString, eventsEmitter, {
        storagePath: subsetFile,
        paths,
        subsetConfig,
        transform,
        introspectConfig: introspectConfig ?? {},
      })
    }
    return await runSubsetAndCaptureV3(connString, eventsEmitter, {
      paths,
      subsetConfig,
      tablesToCopy,
      transform,
      introspectConfig: introspectConfig ?? {},
    })
  }
  await onChange('progress', {
    step: 'subset',
    completed: 100,
  })

  console.log(`Copying files to: ${paths?.tables}`)

  const eventsEmitter = new EventEmitter() as SnapshotCaptureEventEmitter
  // This function will proxy all typed events comming from our event emitter to the onChange
  // function which will perform api calls / update the UI
  emitterToOnUpdateProxy(eventsEmitter, onChange)
  eventsEmitter.emit('progress', { completed: 100, step: 'schemas' })
  eventsEmitter.emit('progress', { completed: 100, step: 'subset' })
  const files = await runOnlyCaptureV3(connString, eventsEmitter, {
    tablesToCopy,
    paths,
    transform,
  })
  await onChange('progress', {
    step: 'data',
    completed: 100,
  })
  return files
}
