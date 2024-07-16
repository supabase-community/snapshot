import { SnapshotStatus } from '@snaplet/sdk/cli'
import { SingleBar, MultiBar } from 'cli-progress'
import { throttle } from 'lodash'

const PROGRESS_THROTTLE_DELAY = 60_000

export function displayMultibarCopyProgress(
  multibar: MultiBar,
  bars: { name: string; bar: SingleBar }[],
  data: any
) {
  const name = `${data.schema}.${data.tableName}`
  switch (data.status as keyof typeof SnapshotStatus) {
    case 'IN_PROGRESS': {
      if (data.totalRows > 0) {
        let displayName
        if (name.length > 30) {
          displayName = name.slice(0, 27).concat('...')
        } else {
          displayName = name.padEnd(30, ' ')
        }
        const bar = multibar.create(data.totalRows, 0, {
          displayName,
        })
        bars.push({ name, bar })
      }
      break
    }
    case 'SUCCESS': {
      const entry = bars.find((b) => b.name == name)
      if (entry?.bar) {
        entry.bar.update(data.rows)
      }
      break
    }
    default: {
      if (data.totalRows > 0 && data.rows > 0) {
        // Update the bar for the table with the number of rows copied
        const toUpdateBar = bars.find((b) => b.name == name)?.bar
        if (toUpdateBar) {
          toUpdateBar.update(data.rows)
        }
      }
    }
  }
}
const throttleDisplayMinimalCopyProgress = throttle(
  (name: string, data: any) => {
    console.log(`${name.padEnd(30, ' ')} ${data.rows}/${data.totalRows}`)
  },
  PROGRESS_THROTTLE_DELAY,
  { leading: true }
)
export function displayMinimalCopyProgress(data: {
  name: string
  done: boolean
  rows?: number
  totalRows: number
}) {
  if (data.done) {
    throttleDisplayMinimalCopyProgress.cancel()
    console.log(
      `${data.name.padEnd(30, ' ')} Done ${data.totalRows} rows copied`
    )
  } else if (data.rows && data.totalRows) {
    throttleDisplayMinimalCopyProgress(data.name, data)
  }
}

const throttleDisplayMinimalSubsetProgress = throttle(
  (tableName: string, currentSubsetdRows: number) => {
    console.log(
      `${currentSubsetdRows
        .toString()
        .padEnd(10, ' ')} subsetd rows crawling ${tableName}`
    )
  },
  PROGRESS_THROTTLE_DELAY,
  { leading: true }
)
export function displayMinimalSubsetProgress(data: {
  tableName: string
  currentSubsetdRows: number
  done: boolean
}) {
  if (data.done) {
    throttleDisplayMinimalSubsetProgress.cancel()
    console.log(`Subsetting finished`)
  } else {
    throttleDisplayMinimalSubsetProgress(
      data.tableName,
      data.currentSubsetdRows
    )
  }
}
