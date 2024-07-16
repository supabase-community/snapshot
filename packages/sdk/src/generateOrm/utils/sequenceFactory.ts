import type { DataModelSequence } from '../index.js'

export function sequenceGeneratorFactory(sequence: DataModelSequence) {
  return function* () {
    let current = sequence.current
    while (true) {
      yield current
      current += sequence.increment
    }
  }
}
