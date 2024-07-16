type GraphNode = { [key: string]: any } | any[]

// In collaboration with ChatGPT :D
export function extractBranch(
  graph: GraphNode,
  path: (string | number)[]
): GraphNode | null {
  if (path.length === 0) {
    return graph
  }

  const [head, ...tail] = path

  if (Array.isArray(graph)) {
    if (typeof head === 'number' && head < graph.length) {
      const pruned = extractBranch(graph[head], tail)
      return pruned !== null ? [pruned] : null
    }
    return null
  }

  if (graph && typeof graph === 'object') {
    const newGraph: { [key: string]: any } = {}

    for (const key in graph) {
      if (key === head) {
        const pruned = extractBranch(graph[key], tail)
        if (pruned !== null) {
          newGraph[key] = pruned
        }
      } else if (path.indexOf(key) === -1) {
        newGraph[key] = graph[key] // Preserve sibling keys
      }
    }

    for (const key in newGraph) {
      if (Array.isArray(newGraph[key]) && newGraph[key].length === 1) {
        newGraph[key] = newGraph[key][0]
      }
    }

    return Object.keys(newGraph).length > 0 ? newGraph : null
  }

  return null
}
