import { addAndIntersect } from './addAndIntersect.js'

test('should return the diff with the new elements', () => {
  const set1 = new Set([1, 2, 3, 4])
  const set2 = new Set([1, 2, 3, 4, 5, 6])
  const newSet = addAndIntersect(set1, set2)
  expect(set1.size).toBe(6)
  expect(newSet.size).toBe(2)
  expect(newSet.has(5)).toBe(true)
  expect(newSet.has(6)).toBe(true)
})
