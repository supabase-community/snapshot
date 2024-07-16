import { Client } from 'pg'

const EXCLUDED_SCHEMAS = ['information_schema', 'pg\\_%']

const escapeLiteral = Client.prototype.escapeLiteral
const escapeIdentifier = Client.prototype.escapeIdentifier

function buildSchemaExclusionClause(escapedColumn: string) {
  return EXCLUDED_SCHEMAS.map(
    (s) => `${escapedColumn} NOT LIKE ${escapeLiteral(s)}`
  ).join(' AND ')
}

export { buildSchemaExclusionClause, escapeIdentifier, escapeLiteral }
