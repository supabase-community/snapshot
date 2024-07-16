import { AliasModelNameConflict } from './generateOrm/dataModel/aliases.js'

export const ERROR_CODES = {
  USER_ORGANIZATION_REQUIRED: 3001,

  IMPORTER_SCHEMA_PARSE: 4001,
  IMPORTER_RESET_DATABASE: 4002,
  IMPORTER_LOCAL_PATH_INVALID: 4003,

  NET_REQUEST_MAX_RETRIES: 5001,
  NET_REQUEST_AUTH: 5002,
  NET_REQUEST_UNKNOWN: 5003,

  DB_CONNECTION_AUTH: 6010,
  DB_INSUFFICIENT_PRIVILEGES: 6011,
  /** @deprecated we no longer create an admin database */
  DB_CREATE_ADMIN_DATABASE: 6002,

  CONNECTION_URL_INVALID: 7101,
  SOURCE_DATABASE_URL_REQUIRED: 7102,
  TARGET_DATABASE_URL_REQUIRED: 7103,

  DATABASE_CONNECTION_FAILED: 7201,
  DATABASE_CONNECTION_CANNOT_CREATE: 7202,
  PREVIEW_DATABASE_SERVER_DOES_NOT_EXIST: 7203,
  PREVIEW_DATABASE_INFRASTRUCTURE_CREATION_FAILED: 7204,
  PREVIEW_DATABASE_DROP_FAILED: 7205,
  PREVIEW_DATABASE_DESTROY_FAILED: 7206,
  PREVIEW_DATABASE_NAME_REQUIRED: 7207,
  DATABASE_PASSWORD_AUTH_FAILED: 7208,
  PREVIEW_DATABASE_RESET_FAILED: 7209,

  /** @deprecated */
  CONFIG_NO_SOURCE_DB_URL: 7020,
  /** @deprecated */
  CONFIG_SOURCE_DB_CONNECTION: 7021,

  PROJECT_ID_REQUIRED: 7301,

  CONFIG_ERROR: 7030,
  CONFIG_REQUIRED_ENVAR: 7040,
  CONFIG_NO_ACCESS_TOKEN: 7050,
  CONFIG_INVALID_SCHEMA: 7060,

  CONFIG_NOT_FOUND: 7070,
  CONFIG_PK_NOT_FOUND: 7080,
  CONFIG_PK_ERROR: 7081,
  CONFIG_PUBLIC_KEY_NOT_FOUND: 7082,

  CONFIG_SUBSET_INVALID: 7090,

  CONFIG_STRICT_TRANSFORM_MISSING_SCHEMA: 7100,
  CONFIG_STRICT_TRANSFORM_MISSING_TABLE: 7101,
  CONFIG_STRICT_TRANSFORM_MISSING_COLUMN: 7102,

  SNAPSHOT_PATH_NOT_FOUND: 8010,
  SNAPSHOT_LIST_ERROR: 8011,
  SNAPSHOT_LIST_EMPTY: 8012,
  SNAPSHOT_NOT_FOUND: 8013,
  SNAPSHOT_NONE_AVAILABLE: 8014,
  SNAPSHOT_LOCAL_HOST_REQUIRED: 8020,
  SNAPSHOT_RESTORE_ERROR: 8030,
  SNAPSHOT_CAPTURE_TRANSFORM_ERROR: 8040,
  SNAPSHOT_CAPTURE_INCOMPLETE_ERROR: 8050,

  DEPRECATED_CLI_COMMAND: 8001,
  DEPRECATED_CLI_ACTION: 8002,
  DEPRECATED_CLI_OPTION: 8003,
  CLI_BIN_REQUIRE_BROTLI: 8100,
  CLI_BIN_REQUIRE_PGDUMP: 8101,

  SUBSET_TRAVERSAL_ERROR: 9000,
  SNAPSHOT_SAMPLE_ERROR: 9001,
  SNAPSHOT_SAMPLE_FILE_EXISTS: 9002,
  ECS_TASK_FAILED_TO_PROVISION: 9003,

  SNAPLET_CLIENT_PACKAGE_NOT_FOUND: 9100,
  WORKSPACE_ROOT_NOT_FOUND: 9101,
  PACKAGE_MANAGER_NOT_FOUND: 9102,
  PACKAGE_MANAGER_RUN_ERROR: 9103,

  PROJECT_BASE_DIR_NOT_CREATED: 9200,

  SEED_ALIAS_MODEL_NAME_CONFLICTS: 9300,

  UNHANDLED_ERROR: 9999,
}

type CodeType = keyof typeof ERROR_CODES
interface Data extends Record<CodeType, any> {
  CONFIG_INVALID_SCHEMA: {
    path: (string | number)[]
  }
  CONFIG_STRICT_TRANSFORM_MISSING_SCHEMA: {
    schema: string
  }
  CONFIG_STRICT_TRANSFORM_MISSING_TABLE: {
    schema: string
    table: string
  }
  CONFIG_STRICT_TRANSFORM_MISSING_COLUMN: {
    schema: string
    table: string
    column: string
  }
  PACKAGE_MANAGER_RUN_ERROR: {
    error: unknown
  }
  SEED_ALIAS_MODEL_NAME_CONFLICTS: {
    conflicts: AliasModelNameConflict[]
  }
}

export class ErrorList extends Error {
  name = 'ErrorList'

  constructor(public errors: Error[]) {
    super(errors.join('\n\n'))
    this.errors = errors
  }
}

export interface SnapletErrorBase<Code extends CodeType = CodeType> {
  readonly _tag: string
  name: string
  code: Code
  data: Data[Code]
}

export class SnapletError<Code extends CodeType = CodeType>
  extends Error
  implements SnapletErrorBase<Code>
{
  readonly _tag = 'SnapletError'
  name = 'SnapletError'

  static Codes = ERROR_CODES

  static UserErrors: CodeType[] = [
    'CONFIG_STRICT_TRANSFORM_MISSING_SCHEMA',
    'CONFIG_STRICT_TRANSFORM_MISSING_TABLE',
    'CONFIG_STRICT_TRANSFORM_MISSING_COLUMN',
  ]
  code
  data

  constructor(code: Code, data?: Data[Code]) {
    super()

    this.code = code
    this.data = data
  }

  static instanceof<Code extends CodeType>(
    err: Error | unknown,
    code: Code
  ): err is SnapletError<Code> {
    // @ts-expect-error
    return isError(err) && err?.code === code
  }
}

export function isError(e: any): e is Error {
  return (
    e instanceof Error ||
    // In some case, like jest test running environment, we can't rely on the instanceof
    // operator because jest override global Error object
    // Since some of our sdk code is integrated into the seed client which can be run in test environment
    // we need this custom function to check if an object is an error, or more accurately, if it's 'error like'
    (typeof e.message === 'string' &&
      typeof e.name === 'string' &&
      e.constructor)
  )
}
