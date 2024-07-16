import { Table } from './types.js'

class Node {
  adjacent: Set<Node> = new Set<Node>()

  constructor(public name: string) {}

  addAdjacent(node: Node) {
    this.adjacent.add(node)
  }

  isAdjacent(node: Node) {
    return this.adjacent.has(node)
  }
}

class Graph {
  nodes: Map<string, Node> = new Map<string, Node>()

  addNode(node: Node) {
    this.nodes.set(node.name, node)
  }

  getNode(name: string): Node | undefined {
    return this.nodes.get(name)
  }

  addEdge(fromNodeName: string, toNodeName: string) {
    const fromNode = this.getNode(fromNodeName)
    const toNode = this.getNode(toNodeName)

    if (fromNode && toNode) {
      fromNode.addAdjacent(toNode)
      toNode.addAdjacent(fromNode) // Making the graph bidirectional
    }
  }
}

// Depth-first search.
function dfs(
  graph: Graph,
  startNodeName: string,
  visited: Set<string> = new Set()
) {
  const startNode = graph.getNode(startNodeName)
  if (startNode) {
    visited.add(startNodeName)
    for (const adjacentNode of startNode.adjacent) {
      if (!visited.has(adjacentNode.name)) {
        visited.add(adjacentNode.name)
        dfs(graph, adjacentNode.name, visited)
      }
    }
  }
}
function findDisconnectedTables(
  tablesToCopy: Table[],
  targetIds: string[]
): Set<string> {
  const graph = new Graph()
  for (const table of tablesToCopy) {
    graph.addNode(new Node(table.id))
  }
  for (const table of tablesToCopy) {
    for (const parent of table.parents) {
      graph.addEdge(parent.fkTable, parent.targetTable)
    }
    for (const child of table.children) {
      graph.addEdge(child.fkTable, child.targetTable)
    }
  }

  // Find connected nodes for each target node.
  const visited = new Set<string>()
  for (const targetId of targetIds) {
    dfs(graph, targetId, visited)
  }

  // Find disconnected nodes.
  const disconnectedNodes = new Set<string>()
  for (const node of graph.nodes.values()) {
    if (!visited.has(node.name)) {
      disconnectedNodes.add(node.name)
    }
  }

  return disconnectedNodes
}

export { findDisconnectedTables }
