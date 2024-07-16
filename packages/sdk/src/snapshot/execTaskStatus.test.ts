import { isExecTaskTimeout } from './execTaskStatus.js'

test('should timeout after 5 minutes of inactivity', () => {
  const pastMinute = new Date()
  pastMinute.setMinutes(pastMinute.getMinutes() - 1)
  expect(isExecTaskTimeout(pastMinute, 5)).toEqual(false)

  const pastHour = new Date()
  pastHour.setMinutes(pastHour.getMinutes() - 60)
  expect(isExecTaskTimeout(pastHour, 5)).toEqual(true)

  const pastFourMinutes = new Date()
  pastFourMinutes.setMinutes(pastFourMinutes.getMinutes() - 4)
  expect(isExecTaskTimeout(pastFourMinutes, 5)).toEqual(false)

  const pastFiveMinutes = new Date()
  pastFiveMinutes.setMinutes(pastFiveMinutes.getMinutes() - 5)
  expect(isExecTaskTimeout(pastFiveMinutes, 5)).toEqual(true)

  const pastSixMinutes = new Date()
  pastSixMinutes.setMinutes(pastSixMinutes.getMinutes() - 6)
  expect(isExecTaskTimeout(pastSixMinutes, 5)).toEqual(true)
})
