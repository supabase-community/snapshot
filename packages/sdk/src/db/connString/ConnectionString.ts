import { URLSearchParams, URL } from 'url'
interface ConnectionObject {
  protocol: string
  hostname: string
  port: number | null
  username: string
  password: string
  database: string | null
  search: string
}

export type ValidationErrorType =
  | 'INVALID'
  | 'UNSERIALIZABLE'
  | 'UNRECOGNIZED_PROTOCOL'
  | 'INVALID_URI_SEGMENT'
  | 'INVALID_SEGMENT'

export type ConnectionStringShape = string | ConnectionString

export const CONNECTION_STRING_PROTOCOLS = ['postgresql:', 'pg:', 'postgres:']

export class ConnectionString {
  protected asString: string
  validationErrors: ValidationErrorType | null

  constructor(asString: ConnectionStringShape) {
    asString = asString.toString()
    this.validationErrors = validateConnectionString(asString)

    if (!this.validationErrors) {
      this.asString = addConnectionStringDefaults(asString)
    } else {
      this.asString = asString
    }
  }

  static get default(): ConnectionString {
    return DEFAULT_CONNECTION_STRING_INSTANCE
  }

  static fromObject(obj: Partial<ConnectionObject>): ConnectionString {
    return new ConnectionString(
      serializeConnectionObject(addConnectionObjectDefaults(obj))
    )
  }

  get database(): string {
    return extractConnectionStringDatabase(this.asString)
  }

  get domain(): string {
    return extractConnectionStringDomain(this.asString)
  }

  get host(): string {
    return extractConnectionStringHost(this.asString)
  }

  get port(): number {
    return extractConnectionStringPort(this.asString)
  }

  get username(): string {
    return extractConnectionStringUsername(this.asString)
  }

  get password(): string {
    return extractConnectionStringPassword(this.asString)
  }

  get isReadOnly(): boolean {
    const url = parseConnectionString(this.asString)
    const searchParams = new URLSearchParams(url.search)
    const options = searchParams.get('options')
    return options?.includes('-c default_transaction_read_only=1') ?? false
  }

  get sslMode(): string | null {
    const url = parseConnectionString(this.asString)
    const searchParams = new URLSearchParams(url.search)
    return searchParams.get('sslmode')
  }

  setSslMode(sslMode: string | null): ConnectionString {
    const url = parseConnectionString(this.asString)
    const searchParams = new URLSearchParams(url.search)
    if (sslMode) {
      searchParams.set('sslmode', sslMode)
    } else {
      searchParams.delete('sslmode')
    }
    url.search = searchParams.toString()
    return new ConnectionString(serializeConnectionObject(url))
  }

  setReadOnly(readOnly: boolean): ConnectionString {
    const url = parseConnectionString(this.asString)
    const searchParams = new URLSearchParams(url.search)
    let options = searchParams.get('options')
    if (readOnly) {
      if (!options) {
        searchParams.set('options', '-c default_transaction_read_only=1')
      } else if (!options.includes('default_transaction_read_only=1')) {
        searchParams.set(
          'options',
          `${options} -c default_transaction_read_only=1`
        )
      }
    } else {
      if (options?.includes('-c default_transaction_read_only=1')) {
        options = options
          .replace('-c default_transaction_read_only=1', '')
          .replace(/  +/g, ' ')
          .trim()
        if (options.length > 0) {
          searchParams.set('options', options)
        } else {
          searchParams.delete('options')
        }
      }
    }
    url.search = searchParams.toString()
    return new ConnectionString(serializeConnectionObject(url))
  }

  setDatabase(database: string | null): ConnectionString {
    return new ConnectionString(
      changeConnectionStringDatabase(this.asString, database)
    )
  }

  setHostname(hostname: string): ConnectionString {
    return new ConnectionString(
      changeConnectionStringHostname(this.asString, hostname)
    )
  }

  setUsername(username: string): ConnectionString {
    return new ConnectionString(
      changeConnectionStringUsername(this.asString, username)
    )
  }

  setPassword(password: string): ConnectionString {
    return new ConnectionString(
      changeConnectionStringPassword(this.asString, password)
    )
  }

  setPort(port: number): ConnectionString {
    return new ConnectionString(changeConnectionStringPort(this.asString, port))
  }

  toString(): string {
    return this.asString
  }

  toScrubbedString(): string {
    if (this.password?.length > 0) {
      // TODO: add 'setPassword' method.
      return this.toString().replace(this.password, '[secret]')
    } else {
      return this.toString()
    }
  }
}

const DEFAULT_CONNECTION_STRING =
  'postgresql://postgres@localhost:5432/postgres'

// context(justinvdm, 7 Mar 2022): Chrome does not allow 'postgresql:' as a protocol when using
// URL. We replace it with 'https:' to work with the url segments correctly
const SURROGATE_PROTOCOL = 'https:'
const SURROGATE_HOSTNAME = '__snaplet_surrogate_hostname__'

const uriSegmentIsValid = (segment: string | null | undefined): boolean => {
  let encodedResult
  let fixedEncodedResult

  try {
    const decoded = decodeURIComponent(segment ?? '')
    encodedResult = encodeURIComponent(decoded)
    fixedEncodedResult = fixedEncodeURIComponent(decoded)
  } catch {
    return false
  }

  return segment === encodedResult || segment === fixedEncodedResult
}

const validateConnectionString = (
  connString: string
): ValidationErrorType | null => {
  try {
    new URL(connString)
  } catch (err: any) {
    if (err.code === 'ERR_INVALID_URL') {
      return 'INVALID'
    } else {
      throw err
    }
  }

  const obj = safeParseConnectionString(connString)

  if (!obj) {
    return 'INVALID'
  }

  if (
    serializeConnectionObject(obj).toLocaleLowerCase() !==
    connString.toLocaleLowerCase()
  ) {
    return 'UNSERIALIZABLE'
  }

  const segmentsToValidate = [
    obj.hostname,
    obj.username,
    obj.password,
    obj.database,
  ]

  if (!segmentsToValidate.filter(Boolean).every(uriSegmentIsValid)) {
    return 'INVALID_URI_SEGMENT'
  }

  // context(justinvdm, 3 March 2022): We need to inspect the url
  // with defaults added separately and after the checks done above,
  // since URL does some encoding of url segments that would mess up
  // the checks above
  const fullUrl = parseConnectionString(addConnectionStringDefaults(connString))

  if (!isValidDBProtocol(fullUrl.protocol)) {
    return 'UNRECOGNIZED_PROTOCOL'
  }

  const requiredSegments = [
    fullUrl.protocol,
    fullUrl.hostname,
    fullUrl.username,
    fullUrl.port,
  ]

  // returns null or 'INVALID_SEGMENT'
  return requiredSegments.every(Boolean) ? null : 'INVALID_SEGMENT'
}

const isValidDBProtocol = (protocol: string) =>
  CONNECTION_STRING_PROTOCOLS.includes(protocol)

const changeConnectionStringDatabase = (
  connString: string,
  database: string | null
): string => {
  const url = parseConnectionString(connString)
  url.database = database
  return serializeConnectionObject(url)
}

const changeConnectionStringHostname = (
  connString: string,
  hostname: string
): string => {
  const url = parseConnectionString(connString)
  url.hostname = hostname
  return serializeConnectionObject(url)
}

const changeConnectionStringUsername = (
  connString: string,
  username: string
): string => {
  const url = parseConnectionString(connString)
  url.username = username
  return serializeConnectionObject(url)
}

const changeConnectionStringPassword = (
  connString: string,
  password: string
): string => {
  const url = parseConnectionString(connString)
  url.password = password
  return serializeConnectionObject(url)
}

const changeConnectionStringPort = (
  connString: string,
  port: number
): string => {
  const url = parseConnectionString(connString)
  url.port = port
  return serializeConnectionObject(url)
}

// context(justinvdm, 6 Oct 2022): Adapted from
// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
// > To be more stringent in adhering to RFC 3986 (which reserves !, ', (, ), and *),
// > even though these characters have no formalized URI delimiting uses, the following can be safely used:
export const fixedEncodeURIComponent = (str: string): string => {
  return encodeURIComponent(str).replace(
    /[!'()*-.!~_]/g,
    (c) => `%${c.charCodeAt(0).toString(16).toUpperCase()}`
  )
}

const addConnectionObjectDefaults = (
  connObject: Partial<ConnectionObject>
): ConnectionObject => ({
  protocol: connObject.protocol || DEFAULT_CONNECTION_OBJECT.protocol,
  hostname: connObject.hostname || DEFAULT_CONNECTION_OBJECT.hostname,
  port: connObject.port || DEFAULT_CONNECTION_OBJECT.port,
  database:
    connObject.database === null
      ? null
      : connObject.database || DEFAULT_CONNECTION_OBJECT.database,
  username: connObject.username || DEFAULT_CONNECTION_OBJECT.username,
  password: connObject.password || DEFAULT_CONNECTION_OBJECT.password,
  search: connObject.search || DEFAULT_CONNECTION_OBJECT.search,
})

const addConnectionStringDefaults = (connString: string): string =>
  serializeConnectionObject(
    addConnectionObjectDefaults(parseConnectionString(connString))
  )

const extractConnectionStringDatabase = (connString: string): string =>
  parseConnectionString(connString).database ?? ''

const extractConnectionStringDomain = (connString: string): string =>
  (parseConnectionString(connString).hostname || '')
    .split('.')
    .slice(-2)
    .join('.')

const extractConnectionStringHost = (connString: string): string =>
  parseConnectionString(addConnectionStringDefaults(connString)).hostname || ''

const extractConnectionStringUsername = (connString: string): string =>
  parseConnectionString(addConnectionStringDefaults(connString)).username || ''

const extractConnectionStringPassword = (connString: string): string =>
  parseConnectionString(addConnectionStringDefaults(connString)).password || ''

const extractConnectionStringPort = (connString: string): number =>
  parseConnectionString(connString).port ?? DEFAULT_CONNECTION_OBJECT.port

// context(justinvdm, 7 Mar 2022): Chrome does not allow 'postgresql:' as a protocol when using
// URL. We need to change the protocol to be able to access the other object segments, and
// then return a plain object
const parseConnectionUrl = (url: URL): ConnectionObject => {
  const protocol = url.protocol
  url.protocol = SURROGATE_PROTOCOL

  const database = url.pathname.slice(1)

  const { hostname, port, username, password, search } = url

  return {
    protocol,
    hostname,
    port: port ? +port : null,
    username,
    password,
    database,
    search,
  }
}

/** helper function to encode a connection string */
export const encodeConnectionString = (connString: ConnectionString) => {
  const params = {
    // password is always scrubbed
    password: connString.password
      ? fixedEncodeURIComponent(decodeURIComponent(connString.password))
      : '',
    port: connString.port ? `:${connString.port}` : '',
    host: encodeURIComponent(decodeURIComponent(connString.host)),
    username: encodeURIComponent(decodeURIComponent(connString.username)),
    database: encodeURIComponent(decodeURIComponent(connString.database)),
  }

  return {
    toString: () =>
      `postgresql://${params.username}${
        params.password ? `:${params.password}` : ''
      }@${params.host}${params.port}/${params.database}`.trim(),
    params,
  }
}

const parseConnectionString = (input: string): ConnectionObject =>
  parseConnectionUrl(new URL(input))

const safeParseConnectionString = (input: string): ConnectionObject | null => {
  let url

  // context(justinvdm, 16 Mar 2022): If this throws, it means we have an invalid URL.
  // This is a `safe*` function, so return null in this case
  try {
    url = new URL(input)
  } catch {
    return null
  }

  return parseConnectionUrl(url)
}

const serializeConnectionObject = (input: ConnectionObject): string => {
  const url = new URL(`${SURROGATE_PROTOCOL}//${SURROGATE_HOSTNAME}`)

  if (input.port) {
    url.port = input.port.toString()
  }

  url.pathname = `/${input.database ?? ''}`
  url.username = input.username
  url.password = input.password
  url.search = input.search

  url.host = input.hostname

  // context(justinvdm, 7 Mar 2022): Chrome does not allow 'postgresql:' as a protocol when using
  // URL. We need to use 'https:' to be able to alter the other url segments, and
  // manually concatenate the protocol at the end
  let result = [
    input.protocol,
    url.toString().slice(SURROGATE_PROTOCOL.length),
  ].join('')

  // context(justinvdm, 7 Mar 2022): Urls without pathnames end up getting a `/` when URL is stringified
  if (input.database === '') {
    result = result.slice(0, -1)
  }

  // context(justinvdm, 16 Mar 2022): URL does not replace hostname if hostname is ''
  result = result.replace(SURROGATE_HOSTNAME, input.hostname)

  return result
}

const parseDefaultConnectionString = () => {
  const { port, ...obj } = parseConnectionString(DEFAULT_CONNECTION_STRING)

  if (port === null) {
    throw new Error('Default snaplet connection string needs a port')
  }

  return {
    port,
    ...obj,
  }
}

const DEFAULT_CONNECTION_OBJECT = parseDefaultConnectionString()

const DEFAULT_CONNECTION_STRING_INSTANCE = new ConnectionString(
  DEFAULT_CONNECTION_STRING
)
