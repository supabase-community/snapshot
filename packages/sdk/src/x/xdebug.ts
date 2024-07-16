import util from 'util'
import debug, { Debugger } from 'debug'

type Logger = (logger: Debugger, ...args: Parameters<typeof xdebug>) => void
;(debug as any).inspectOpts.colors = false

if (process.env.SNAPLET_EXEC_TASK_ID != null) {
  debug.log = function snapletDebugLog(...args) {
    const serialized = JSON.stringify({
      timestamp: new Date().toISOString(),
      message: util.format(...args),
    })

    return process.stderr.write(`[DEBUG] ${serialized}\n`)
  }
}

const defaultXdebugLogger: Logger = (instance, ...args) => {
  const formattedArgs = [...args]

  debug.formatArgs.call(
    {
      ...instance,
      useColors: (debug as any).useColors(),
    } as unknown as Debugger,
    formattedArgs
  )

  return debug.log.call(instance, ...formattedArgs)
}

// Log without any additional timestamp or extra prefixes
const rawXdebugLogger: Logger = (instance, ...args) => {
  const formattedArgs = [...args]

  debug.formatArgs = formatArgs
  function formatArgs(this: Debugger, args: any) {
    if (this.namespace) {
      // Just prepend the current namespace to the output
      args[0] = this.namespace + ' ' + args[0]
    }
  }
  return debug.log.call(instance, ...formattedArgs)
}

const baseDebug = debug('snaplet')
const baseDebugRaw = debug('snaplet')

baseDebug.log = function (...args: Parameters<Debugger>) {
  for (const logger of xdebug.loggers) {
    logger(this, ...args)
  }
}

baseDebugRaw.log = function (...args: Parameters<Debugger>) {
  rawXdebugLogger(baseDebugRaw, ...args)
}

const api = {
  loggers: [defaultXdebugLogger],
  enable(namespace: string) {
    debug.enable(namespace)
  },
}

export const xdebug: typeof baseDebug & typeof api = Object.assign(
  Object.create(baseDebug),
  api
)

export const xdebugRaw: typeof baseDebugRaw = Object.create(baseDebugRaw)
