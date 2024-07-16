import * as timeago from 'timeago.js'

import { getSystemConfig } from './config/index.js'

export function formatTime(
  timeValue: timeago.TDate,
  desiredFormat = getSystemConfig()?.timeFormat
) {
  return desiredFormat === 'PRECISE' ? timeValue : timeago.format(timeValue)
}
