export function escapeKey(key: string): string {
  // This regex checks for a valid JavaScript identifier.
  // It should start with a letter, underscore or dollar, followed by zero or more letters, underscores, dollars or digits.
  const isValidIdentifier = /^[a-zA-Z_$][0-9a-zA-Z_$]*$/.test(key)

  if (isValidIdentifier) {
    return key
  } else {
    return `"${key}"`
  }
}
