import {
  ConnectionStringShape,
  CloudSnapshot,
  EncryptionPayload,
  withDbClient,
} from '@snaplet/sdk/cli'
import fs from 'fs'
import { EventEmitter } from 'stream'
import terminalLink from 'terminal-link'
import type TypedEmitter from '~/lib/typed-emitter.js'

import type SnapshotCache from '../SnapshotCache.js'
import {
  createConstraints as _createConstraints,
  CreateConstraintsEvents,
} from './createConstraints.js'
import {
  dropConstraints as _dropConstraints,
  DropConstraintsEvents,
} from './dropConstraints.js'
import { SideEffectStatements } from './fetchSideEffectStatements.js'
import {
  fixSequences as _fixSequences,
  FixSequencesEvents,
} from './fixSequences.js'
import { fixViews as _fixViews, FixViewsEvents } from './fixViews.js'
import {
  importSchema as _importSchema,
  ImportSchemaEvents,
} from './importSchema.js'
import {
  importTablesData as _importTablesData,
  ImportTablesDataEvents,
} from './importTablesData.js'
import {
  filterTables as _filterTables,
  FilterTablesEvents,
} from './filterTables.js'
import {
  truncateTables as _truncateTables,
  TruncateTablesEvents,
} from './truncateTables.js'
import {
  vacuumTables as _vacuumTables,
  VacuumTablesEvents,
} from './vaccumTables.js'
import { SnapshotTable } from '@snaplet/sdk/cli'

type Events = TruncateTablesEvents &
  ImportTablesDataEvents &
  DropConstraintsEvents &
  ImportSchemaEvents &
  CreateConstraintsEvents &
  FixViewsEvents &
  FixSequencesEvents &
  VacuumTablesEvents &
  FilterTablesEvents

export default class SnapshotImporter {
  readonly summary
  tables: SnapshotTable[]
  readonly cache: SnapshotCache
  constraints: Map<string, SideEffectStatements>
  readonly schema: string
  readonly connString: ConnectionStringShape
  readonly encryptionPayload?: EncryptionPayload
  readonly eventEmitter: TypedEmitter<Events>
  readonly showProgress: boolean
  readonly partialRestore: boolean

  constructor({
    summary,
    cache,
    schemaSource,
    connString,
    showProgress,
    encryptionPayload,
    partialRestore,
  }: {
    summary: CloudSnapshot
    cache: SnapshotCache
    schemaSource?: string
    connString: ConnectionStringShape
    showProgress: boolean
    partialRestore: boolean
    encryptionPayload?: EncryptionPayload
  }) {
    this.summary = summary
    this.tables = []
    this.cache = cache
    this.connString = connString
    this.encryptionPayload = encryptionPayload
    this.schema = schemaSource ?? this.readSchema()
    this.constraints = new Map()
    this.eventEmitter = new EventEmitter() as TypedEmitter<Events>
    this.showProgress = showProgress
    this.partialRestore = partialRestore
  }

  on: TypedEmitter<Events>['on'] = (...args) => {
    return this.eventEmitter.on(...args)
  }

  get schemasTerminalLink() {
    return terminalLink('schemas.sql', 'file://' + this.cache.paths.schemas)
  }

  readSchema = () => {
    if (!fs.existsSync(this?.cache?.paths?.schemas)) {
      throw new Error(
        'Cannot read schema' + this?.cache?.paths?.schemas + ' does not exist.'
      )
    }
    return fs.readFileSync(this.cache.paths.schemas, {
      encoding: 'utf-8',
    })
  }

  importSchema = async () => {
    await withDbClient(
      async (client) => {
        await _importSchema(
          { client, eventEmitter: this.eventEmitter },
          this.cache.paths.schemas,
          this.schema
        )
      },
      { connString: this.connString.toString() }
    )
  }

  filterTables = async (tables: string[], excludeTables: string[]) => {
    this.tables = await _filterTables(
      { eventEmitter: this.eventEmitter },
      this.summary,
      tables,
      excludeTables
    )
  }

  truncateTables = async () => {
    await withDbClient(
      async (client) => {
        await _truncateTables(
          { client, eventEmitter: this.eventEmitter },
          this.tables
        )
      },
      { connString: this.connString.toString() }
    )
  }

  dropConstraints = async () => {
    await withDbClient(
      async (client) => {
        const droppedConstraints = await _dropConstraints(
          { client, eventEmitter: this.eventEmitter },
          this.tables
        )
        this.constraints = droppedConstraints
      },
      { connString: this.connString.toString() }
    )
  }

  importTablesData = async (encryptionPayload?: EncryptionPayload) => {
    await _importTablesData(
      {
        cache: this.cache,
        connString: this.connString.toString(),
        eventEmitter: this.eventEmitter,
        encryptionPayload,
      },
      this.tables,
      this.partialRestore
    )
  }

  createConstraints = async () => {
    await withDbClient(
      async (client) => {
        await _createConstraints(
          { client, eventEmitter: this.eventEmitter },
          this.constraints
        )
      },
      { connString: this.connString.toString() }
    )
  }

  fixViews = async () => {
    await withDbClient(
      async (client) => {
        await _fixViews(
          { client, eventEmitter: this.eventEmitter },
          this.cache.paths.schemas,
          this.schema
        )
      },
      { connString: this.connString.toString() }
    )
  }

  fixSequences = async () => {
    await withDbClient(
      async (client) => {
        await _fixSequences(
          { client, eventEmitter: this.eventEmitter },
          this.tables
        )
      },
      { connString: this.connString.toString() }
    )
  }

  vacuumTables = async () => {
    await withDbClient(
      async (client) => {
        await _vacuumTables(
          { client, eventEmitter: this.eventEmitter },
          this.tables
        )
      },
      { connString: this.connString.toString() }
    )
  }
}
