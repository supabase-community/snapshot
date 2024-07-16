const EXEC_TASK_TIMEOUT_MINS = 5

export const EXEC_TASK_STATUS_TYPE = {
  IN_PROGRESS: 'IN_PROGRESS',
  SUCCESS: 'SUCCESS',
  FAILURE: 'FAILURE',
  TIMEOUT: 'TIMEOUT',
  LONG_RUNNING: 'LONG_RUNNING',
} as const

export const EXEC_TASK_STATUS_SELECTION = {
  exitCode: true,
  updatedAt: true,
  createdAt: true,
  arn: true,
} as const

export type ExecTaskStatusType =
  (typeof EXEC_TASK_STATUS_TYPE)[keyof typeof EXEC_TASK_STATUS_TYPE]

export const isExecTaskTimeout = (
  date: Date,
  timeoutAfterMinutes = EXEC_TASK_TIMEOUT_MINS
) => {
  // Get the current date and time
  const now = new Date()

  // Calculate the difference in milliseconds between the provided date and the current date
  const millisecondsDifference = now.getTime() - date.getTime()

  // Convert the difference to minutes
  const minutesDifference = millisecondsDifference / (1000 * 60)

  // Check if the difference in minutes is greater than or equal to the timeout minutes
  if (minutesDifference >= timeoutAfterMinutes) {
    return true
  } else {
    return false
  }
}

export const determineExecTaskStatus = (task: {
  exitCode: number | null
  updatedAt: Date
}) => {
  if (task.exitCode != null) {
    if (task.exitCode !== 0) {
      return EXEC_TASK_STATUS_TYPE.FAILURE
    } else {
      return EXEC_TASK_STATUS_TYPE.SUCCESS
    }
  }

  if (isExecTaskTimeout(task.updatedAt)) {
    return EXEC_TASK_STATUS_TYPE.TIMEOUT
  } else {
    return EXEC_TASK_STATUS_TYPE.IN_PROGRESS
  }
}
