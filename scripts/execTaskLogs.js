require('dotenv-defaults/config')
const axios = require('axios')
const { readAccessToken } = require('./readAccessToken.js')

const SNAPLET_API_HOSTNAME = process.env.USE_LOCALHOST
  ? 'http://localhost:8911'
  : 'https://api.snaplet.dev'

const DEFAULT_LOG_GROUP_NAME =
  'ExecTask-ExecTaskTaskDefinitionExecTaskContainerLogGroup04CBC5F7-8WJZ9KV3swb8'

const FIND_LOG_STREAM_NAME_WINDOW = 1000 * 60 * 60 * 2
const FIND_LOG_STREAM_NAME_OFFSET = 1000 * 60 * 60 * 24 * 14

// context(justinvdm, 6 June 2023): AWS restrict to 10 request per seconds before throttling, so we do half of this
// https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/cloudwatch_limits_cwl.html
const FIND_LOG_STREAM_NAME_BATCH_SIZE = 10
const FIND_LOG_STREAM_NAME_BATCH_COOLDOWN = 1000

const main = async () => {
  const execTaskId = process.argv[2]
  const details = await findExecTaskLogStreamDetails(execTaskId)

  if (!details) {
    console.log('Could not find exec task')
    return
  }

  await printLogStream(details)
}

const findExecTaskLogStreamNameInBatch = (execTaskId, logGroupName, batch) => {
  let responseCount = 0

  return new Promise((resolve) => {
    batch.forEach(async ([startTime, endTime]) => {
      const result = await send('FilterLogEventsCommand', {
        endTime,
        startTime,
        filterPattern: `SNAPLET_EXEC_TASK_ID=${execTaskId}`,
        logGroupName,
        limit: 1,
      })

      if (result.events.length) {
        resolve(result.events[0].logStreamName)
      } else if (++responseCount === batch.length) {
        resolve(null)
      }
    })
  })
}

// context(justinvdm, 6 June 2023): We actually need a way to tag/index log streams by exec task ids
// Doing a filter to find the relevant log stream is a workaround
const findExecTaskLogStreamDetails = async (execTaskId) => {
  const batches = computeTimeWindowBatches(
    FIND_LOG_STREAM_NAME_WINDOW,
    FIND_LOG_STREAM_NAME_OFFSET,
    FIND_LOG_STREAM_NAME_BATCH_SIZE
  )

  const logGroupName = await findLogGroupName()

  if (!logGroupName) {
    throw new Error('Could not find the exec task log group')
  }

  for (const batch of batches) {
    const logStreamName = await findExecTaskLogStreamNameInBatch(
      execTaskId,
      logGroupName,
      batch
    )

    if (logStreamName) {
      return {
        logGroupName,
        logStreamName,
      }
    }

    await new Promise((resolve) =>
      setTimeout(resolve, FIND_LOG_STREAM_NAME_BATCH_COOLDOWN)
    )
  }

  return null
}

// context(justinvdm, 1 June 2023): A small time window seems needed,
// otherwise recent logs are not returned - seems like we'd hit a
// different retention window and get different results or something
const computeTimeWindowBatches = (
  eventWindow,
  earliestEventOffset,
  batchSize
) => {
  const results = []
  let currentBatch = []
  let offset = 0
  let i = -1
  const now = Date.now()

  while (offset < earliestEventOffset) {
    if (++i >= batchSize) {
      results.push(currentBatch)
      currentBatch = []
      i = 0
    }

    const nextOffset = offset + eventWindow
    currentBatch.push([now - nextOffset, now - offset])
    offset = nextOffset
  }

  return results
}

const findLogGroupName = async () => {
  const result = await send('DescribeLogGroupsCommand')

  const logGroupNames = [
    DEFAULT_LOG_GROUP_NAME,
    ...result.logGroups.reverse().map((d) => d.logGroupName),
  ]

  for (const logGroupName of logGroupNames) {
    const result = await send('FilterLogEventsCommand', {
      endTime: Date.now(),
      startTime: Date.now() - FIND_LOG_STREAM_NAME_WINDOW,
      filterPattern: `SNAPLET_EXEC_TASK_ID=`,
      logGroupName,
      limit: 1,
    })

    if (result.events.length) {
      return logGroupName
    }
  }

  return null
}

const printLogStreamLine = (d) => {
  let content

  if (d.message.startsWith('[DEBUG]')) {
    try {
    const rawMessage = JSON.parse(d.message.slice('[DEBUG] '.length)).message
    const prefixes = rawMessage.split(' ', 3)
    const timestamp = prefixes[0]
    content = rawMessage
      .slice(prefixes.join(' ').length + 1)
      .split('\n')
      .map((line) => [timestamp, '[DEBUG]', line].join(' '))
      .join('\n')
    } catch {}
  }

  content = content ?? [new Date(d.timestamp).toISOString(), d.message].join(' ')
  console.log(content)
}

const printLogStream = async ({ logStreamName, logGroupName }) => {
  await doAll({
    fetch: (nextToken) =>
      send('FilterLogEventsCommand', {
        logGroupName,
        logStreamNames: [logStreamName],
        nextToken,
      }),
    get: (d) => d?.events ?? [],
    print: printLogStreamLine,
  })
}

const send = async (command, props = {}) => {
  const res = await axios({
    method: 'post',
    url: `${SNAPLET_API_HOSTNAME}/admin/cloudwatch.send`,
    responseType: 'json',
    data: {
      command,
      props,
    },
    headers: {
      authorization: `Bearer ${await readAccessToken()}`,
    },
  })

  return res?.data?.result?.data
}

const doAll = async ({ fetch, get, print }) => {
  let token = null
  let nextResults

  do {
    const resp = await fetch(token)
    nextResults = get(resp)
    token = resp.nextToken
    nextResults?.forEach(print)
  } while (nextResults?.length)
}

if (require.main === module) {
  main()
}
