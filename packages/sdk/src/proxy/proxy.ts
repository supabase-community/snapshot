import { ConnectionString } from '../db/connString/ConnectionString.js'
import { Backend } from './Backend.js'
import { Frontend, isStartupMessage, parseStartupMessage } from './Frontend.js'
import { PgSocket } from './PgSocket.js'
import * as net from 'net'
import * as tls from 'tls'

const PROXY_DATABASE_NAME = 'snaplet'

export function createProxy(remote: ConnectionString) {
  const frontend = new Frontend()
  const backend = new Backend()

  const sockets: net.Socket[] = []

  const server = net.createServer((localSocket) => {
    let remoteSocket: PgSocket
    let socketConnectionString

    sockets.push(localSocket)

    localSocket.on('data', (data) => {
      if (isStartupMessage(data)) {
        const startupMessage = parseStartupMessage(data)
        initialiseRemoteSocket(startupMessage.args)
      }

      if (frontend.getGSSAPIRequestMessage().compare(data) === 0) {
        localSocket.write(Buffer.from('N')) // GSSAPI not supported
      }
      if (frontend.getSSLRequestMessage().compare(data) === 0) {
        localSocket.write(Buffer.from('N')) // SSL not supported
      }
    })

    const initialiseRemoteSocket = (args: Frontend.StartupMessageArgs) => {
      // context(justinvdm, 3 October 2023): If the database is `snaplet`, or no database
      // is given we proxy through to given `remote` connection string's database. Otherwise,
      // we use the database given in the connection string.
      if (args.database === PROXY_DATABASE_NAME || args.database == null) {
        socketConnectionString = remote
      } else {
        socketConnectionString = remote.setDatabase(args.database)
      }

      remoteSocket = createRemoteSocket(socketConnectionString)

      remoteSocket.on('authenticate', () => {
        // Once the remoteSocket is authenticated, we can send the authenticationOk as well
        localSocket.write(backend.getAuthenticationOk())
        localSocket.removeAllListeners('data')
        // Then, will come the parameterStatus messages we forward them to the local socket
        remoteSocket.on(
          'parameterStatus',
          (data: { name: string; value: string }) => {
            localSocket.write(frontend.getParameterStatus(data))
          }
        )
      })

      remoteSocket.on('ready', () => {
        remoteSocket.removeListeners()
        localSocket.write(backend.getReadyForQuery())
        proxyPass(localSocket, remoteSocket.socket as tls.TLSSocket)
      })
    }
  })

  server.on('error', (err) => {
    console.log('Server error:', err)
  })

  const kill = () =>
    new Promise<void>((resolve, reject) => {
      server.close((err) => {
        if (err) {
          reject(err)
        } else {
          resolve()
        }
      })

      sockets.forEach((socket) => socket.destroy())
    })

  // for some reason, I can't do a spread here, because
  // typescript freaks out and doesn't infer correctly.
  return { server, kill }
}

const isLocalhost = (host: string) =>
  ['localhost', '127.0.0.1', '[::1]'].indexOf(host) !== -1

const shouldEnableSsl = (remote: ConnectionString) =>
  !isLocalhost(remote.host) || [null, 'disable'].indexOf(remote.sslMode) === -1

function createRemoteSocket(remote: ConnectionString): PgSocket {
  const pgSocket = new PgSocket({
    host: remote.host,
    port: remote.port,
    user: remote.username,
    password: remote.password,
    database: remote.database,
    ssl: shouldEnableSsl(remote) ? { rejectUnauthorized: false } : undefined,
  })

  pgSocket.connect()
  return pgSocket
}

function proxyPass(localSocket: net.Socket, remoteSocket: tls.TLSSocket) {
  localSocket
    .on('data', (data) => {
      const flushed = remoteSocket.write(data)
      if (!flushed) {
        localSocket.pause()
      }
    })
    .on('drain', () => {
      remoteSocket.resume()
    })
    .on('error', (err) => {
      console.log('Local socket error:', err)
      remoteSocket.end()
    })
    .on('close', () => {
      remoteSocket.end()
    })

  remoteSocket
    .on('data', (data) => {
      const flushed = localSocket.write(data)
      if (!flushed) {
        remoteSocket.pause()
      }
    })
    .on('drain', () => {
      localSocket.resume()
    })
    .on('error', (err) => {
      console.log('Remote socket error:', err)
      localSocket.end()
    })
    .on('close', () => {
      localSocket.end()
    })
}
