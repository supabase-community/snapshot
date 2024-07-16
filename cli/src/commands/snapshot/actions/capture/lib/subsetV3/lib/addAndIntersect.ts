// Take two sets, try to add the second to the first, and return a new set of the added values who wasn't already present
export function addAndIntersect<T>(mutated: Set<T>, toAdd: Set<T>) {
  const added = new Set<T>()
  // TODO: (avallete) find a more efficient way to do this
  for (const elem of toAdd.values()) {
    if (mutated.size < mutated.add(elem).size) {
      added.add(elem)
    }
  }
  return added
}
