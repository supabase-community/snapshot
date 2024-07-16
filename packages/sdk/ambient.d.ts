declare global {
  // eslint-disable-next-line no-var
  var fetch: typeof import('undici').fetch
}

export {}
