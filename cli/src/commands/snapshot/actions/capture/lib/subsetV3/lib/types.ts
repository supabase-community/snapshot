import { IntrospectedStructure } from '@snaplet/sdk/cli'

type ReferenceDirection = 'FORWARD' | 'REVERSE'

type Reference = {
  directions: Array<ReferenceDirection>
  id: string
  fkTable: string
  fkColumns: string[]
  targetTable: string
  targetColumns: string[]
  eager?: boolean
  followNullable?: boolean
  nullable?: boolean
  maxChildrenPerNode?: number
  maxCyclesLoop?: number
  currentLoop: number
}

type Table = IntrospectedStructure['tables'][number]
// Used to define tables after there primary keys has been falled back onto
// columns if the primary keys were not found via columnsToPrimaryKeys
type TableWithPrimaryKeys = Table & {
  primaryKeys: NonNullable<Table['primaryKeys']>
}

type TableSegment = {
  originRootId: string
  segmentId: number
  tableId: string
}

type Task = {
  // Can be used alongside sourceReference?.id to uniquely identify a task accross all his chunks
  step: number
  segment: TableSegment
  sourceDirection?: ReferenceDirection
  sourceReference?: Reference
}

type SubsettingTable = Pick<
  TableWithPrimaryKeys,
  'id' | 'name' | 'schema' | 'columns' | 'primaryKeys' | 'partitioned'
> & {
  columnsToNullate: Set<string>
  parents: Reference[]
  children: Reference[]
  isDisconnected: boolean
}

export type {
  Table,
  TableSegment,
  Task,
  Reference,
  ReferenceDirection,
  SubsettingTable,
}
