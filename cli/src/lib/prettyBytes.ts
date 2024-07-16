import format from 'pretty-bytes'

export const prettyBytes = (bytes: any) => {
  bytes = Number(bytes)

  if (isNaN(bytes)) {
    return '0 B'
  } else {
    return format(bytes, {})
  }
}
