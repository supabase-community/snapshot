import { Server } from 'http'
import { memoize } from 'lodash'

let server: Server

async function _getHttpServer() {
  const { createServer } = await import('http')
  if (!server) {
    server = createServer((req, res) => {
      // Set CORS headers
      res.setHeader('Access-Control-Allow-Origin', '*') // Allow any origin
      res.setHeader('Access-Control-Allow-Headers', '*')
      res.setHeader(
        'Access-Control-Allow-Methods',
        'OPTIONS, GET, POST, PUT, DELETE'
      )

      // Handle preflight requests
      if (req.method === 'OPTIONS') {
        res.writeHead(204)
        res.end()
        return
      }
    })
  }
  return server
}
export const getHttpServer = memoize(_getHttpServer)

export const closeHttpServer = async () => {
  const server = await getHttpServer()
  await server.close()
}
