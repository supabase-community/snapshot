//#region structure
type JsonPrimitive = null | number | string | boolean;
type Nested<V> = V | { [s: string]: V | Nested<V> } | Array<V | Nested<V>>;
type Json = Nested<JsonPrimitive>;
type Enum_pgboss_job_state = 'active' | 'cancelled' | 'completed' | 'created' | 'expired' | 'failed' | 'retry';
type Enum_public_access_token_type = 'CLI' | 'WORKER';
type Enum_public_audit_log_actions = 'EMAIL_SENT_INCOMPLETE_ONBOARDING' | 'EMAIL_SENT_ORGANIZATION_CHURN' | 'ORGANIZATION_DELETED' | 'PII_UPDATED_PREDICTIONS_OVERRIDE' | 'PREVIEW_DATABASE_CREATED' | 'PREVIEW_DATABASE_DEPLOYED' | 'PREVIEW_DATABASE_DESTROYED' | 'PREVIEW_DATABASE_DROPPED' | 'PREVIEW_DATABASE_RESET' | 'PROJECT_DELETED' | 'SNAPSHOT_CONFIG_UPDATED' | 'SNAPSHOT_CREATED' | 'SNAPSHOT_DELETED' | 'SNAPSHOT_RESTORED_FAILURE' | 'SNAPSHOT_RESTORED_SUCCESS';
type Enum_public_database_status = 'DELETED' | 'DISABLED' | 'ENABLED';
type Enum_public_member_role = 'ADMIN' | 'MEMBER' | 'OWNER';
type Enum_public_predictions_engine = 'FINETUNED_BERT';
type Enum_public_release_channel = 'BETA' | 'PRIVATE' | 'PUBLIC';
type Enum_public_snapshot_status = 'BOOTING' | 'DELETED' | 'FAILURE' | 'IN_PROGRESS' | 'PENDING' | 'PURGED' | 'STARTED' | 'STARTING' | 'SUCCESS' | 'TIMEOUT';
type Enum_public_user_notifications = 'EMAIL' | 'NONE';
type Enum_public_user_role = 'ADMIN' | 'SUPERUSER' | 'USER';
interface Table_public_access_token {
  id: string;
  updatedAt: string;
  createdAt: string;
  userId: string;
  userAgent: string | null;
  type: Enum_public_access_token_type;
  name: string | null;
  hash: string | null;
}
interface Table_public_audit_log {
  id: string;
  createdAt: string;
  action: Enum_public_audit_log_actions;
  data: Json | null;
  userId: string | null;
  organizationId: string;
  projectId: string | null;
}
interface Table_public_aws_consumption_history {
  name: string;
  startPeriod: string;
  endPeriod: string;
  awsStorageBytes: number | null;
  awsComputeTimeSeconds: number | null;
  awsDataTransferBytes: number | null;
  snapshotId: string | null;
  projectId: string | null;
  organizationId: string;
}
interface Table_public_database_provider {
  id: number;
  name: string;
  domain: string;
}
interface Table_public_db_connection {
  id: string;
  name: string | null;
  ssl: boolean;
  connectionUrlHash: Json;
  organizationId: string;
  databaseProviderId: number | null;
}
interface Table_public_exec_task {
  id: string;
  command: string;
  env: Json | null;
  exitCode: number | null;
  createdAt: string;
  updatedAt: string;
  projectId: string;
  needsSourceDatabaseUrl: boolean;
  progress: Json | null;
  endedAt: string | null;
  arn: string | null;
  accessTokenId: string | null;
  lastNotifiedAt: string | null;
}
interface Table_public_invite_token {
  token: string;
  createdAt: string;
  updatedAt: string;
  createdByUserId: string;
  usedByMemberId: number | null;
  organizationId: string | null;
  expiresAt: string;
}
interface Table_public_member {
  role: Enum_public_member_role;
  organizationId: string;
  userId: string;
  id: number;
  createdAt: string;
  updatedAt: string;
}
interface Table_public_neon_consumption_history {
  name: string;
  startPeriod: string;
  endPeriod: string;
  neonDataStorageBytesHour: number | null;
  neonSyntheticStorageSize: number | null;
  neonDataTransferBytes: number | null;
  neonWrittenDataBytes: number | null;
  neonComputeTimeSeconds: number | null;
  neonActiveTimeSeconds: number | null;
  snapshotId: string | null;
  projectId: string | null;
  organizationId: string;
}
interface Table_public_neon_project {
  id: string;
  createdAt: string;
  updatedAt: string;
  neonProjectId: string;
  snapshotId: string | null;
  connectionUrlHash: Json;
  projectId: string;
}
interface Table_public_organization {
  id: string;
  name: string;
  pricingPlanId: number | null;
  subscriptionData: Json | null;
  createdAt: string;
  updatedAt: string;
  deleted: boolean;
}
interface Table_public_prediction_data_set {
  id: string;
  createdAt: string;
  updatedAt: string;
  input: string;
  context: string;
  shape: string;
  contextSkipTraining: boolean;
  shapeSkipTraining: boolean;
}
interface Table_public_prediction_job {
  id: string;
  engine: Enum_public_predictions_engine;
  createdAt: string;
  updatedAt: string;
  endedAt: string | null;
  rawInput: Json;
  engineInput: Json;
  progress: Json;
  engineOptions: Json | null;
}
interface Table_public_preview_database {
  id: string;
  createdAt: string;
  updatedAt: string;
  name: string;
  neonBranchId: string;
  neonProjectId: string;
  connectionUrlHash: Json;
}
interface Table_public_pricing_plan {
  id: number;
  name: string;
  amount: string;
  isDefault: boolean;
  storageLimit: number;
  processLimit: number;
  restoreLimit: number;
  productId: string;
}
interface Table_public_project {
  name: string;
  organizationId: string;
  dbConnectionId: string | null;
  id: string;
  createdAt: string;
  updatedAt: string;
  dbInfo: Json | null;
  dbInfoLastUpdate: string | null;
  deleted: boolean;
  autoDeleteDays: number | null;
  snapshotConfig: Json | null;
  schedule: Json | null;
  runTaskOptions: Json | null;
  hostedDbUrlId: string | null;
  hostedDbRegion: string | null;
  scheduleTags: string[] | null;
  previewDatabaseRegion: string | null;
  predictionJobId: string | null;
  supabaseProjectId: string | null;
  preseedPreviewDatabases: boolean;
}
interface Table_public_release_version {
  version: string;
  channel: Enum_public_release_channel;
  forceUpgrade: boolean;
  releaseDate: string;
  userId: string | null;
}
interface Table_public_shape_prediction_override {
  id: string;
  createdAt: string;
  updatedAt: string;
  input: string;
  shape: string;
  context: string;
  projectId: string;
}
interface Table_public_shape_prediction_store {
  id: string;
  createdAt: string;
  updatedAt: string;
  input: string;
  predictedLabel: string;
  confidence: number | null;
  overrideLabel: string | null;
  confidenceContext: number | null;
  overrideContext: string | null;
  predictedContext: string;
  engine: Enum_public_predictions_engine;
}
interface Table_public_snapshot {
  id: string;
  uniqueName: string;
  createdAt: string;
  updatedAt: string;
  statusOld: Enum_public_snapshot_status;
  organizationId: string;
  dbConnectionId: string | null;
  workerIpAddress: string | null;
  errors: string[] | null;
  failureCount: number;
  projectId: string;
  dbSchemaDump: string | null;
  logs: string[] | null;
  restoreCount: number;
  dbInfo: Json | null;
  snapshotConfig: Json | null;
  runtime: Json | null;
  summary: Json | null;
  createdByUserId: string | null;
  execTaskId: string | null;
  progress: Json | null;
  notifyOnSuccess: boolean | null;
  deletedAt: string | null;
  purgedAt: string | null;
  storage: Json | null;
  isScheduled: boolean | null;
  preseedPreviewDatabase: boolean;
}
interface Table_public_supabase_project {
  id: string;
  createdAt: string;
  updatedAt: string;
  projectId: string;
  supabaseAuthCodeHash: Json;
  supabaseRefreshToken: string | null;
  supabaseAccessTokenHash: Json | null;
  supabaseAccessTokenExpiresAt: string | null;
}
interface Table_public_table {
  id: string;
  tableName: string;
  status: Enum_public_snapshot_status;
  bucketKey: string | null;
  bytes: string | null;
  timeToDump: number | null;
  timeToSave: number | null;
  snapshotId: string;
  organizationId: string;
  checksum: string | null;
  timeToCompress: number | null;
  timeToEncrypt: number | null;
  rows: string | null;
  schema: string;
  totalRows: string | null;
}
interface Table_public_user {
  id: string;
  sub: string;
  email: string;
  createdAt: string;
  updatedAt: string;
  role: Enum_public_user_role;
  notifications: Enum_public_user_notifications;
}
interface Table_public_prisma_migrations {
  id: string;
  checksum: string;
  finished_at: string | null;
  migration_name: string;
  logs: string | null;
  rolled_back_at: string | null;
  started_at: string;
  applied_steps_count: number;
}
interface Table_pgboss_job {
  id: string;
  name: string;
  priority: number;
  data: Json | null;
  state: Enum_pgboss_job_state;
  retrylimit: number;
  retrycount: number;
  retrydelay: number;
  retrybackoff: boolean;
  startafter: string;
  startedon: string | null;
  singletonkey: string | null;
  singletonon: string | null;
  expirein: string;
  createdon: string;
  completedon: string | null;
  keepuntil: string;
  on_complete: boolean;
  output: Json | null;
}
interface Table_pgboss_schedule {
  name: string;
  cron: string;
  timezone: string | null;
  data: Json | null;
  options: Json | null;
  created_on: string;
  updated_on: string;
}
interface Table_pgboss_version {
  version: number;
  maintained_on: string | null;
  cron_on: string | null;
}
interface Schema_pgboss {
  job: Table_pgboss_job;
  schedule: Table_pgboss_schedule;
  version: Table_pgboss_version;
}
interface Schema_public {
  AccessToken: Table_public_access_token;
  AuditLog: Table_public_audit_log;
  AwsConsumptionHistory: Table_public_aws_consumption_history;
  DatabaseProvider: Table_public_database_provider;
  DbConnection: Table_public_db_connection;
  ExecTask: Table_public_exec_task;
  InviteToken: Table_public_invite_token;
  Member: Table_public_member;
  NeonConsumptionHistory: Table_public_neon_consumption_history;
  NeonProject: Table_public_neon_project;
  Organization: Table_public_organization;
  PredictionDataSet: Table_public_prediction_data_set;
  PredictionJob: Table_public_prediction_job;
  PreviewDatabase: Table_public_preview_database;
  PricingPlan: Table_public_pricing_plan;
  Project: Table_public_project;
  ReleaseVersion: Table_public_release_version;
  ShapePredictionOverride: Table_public_shape_prediction_override;
  ShapePredictionStore: Table_public_shape_prediction_store;
  Snapshot: Table_public_snapshot;
  SupabaseProject: Table_public_supabase_project;
  Table: Table_public_table;
  User: Table_public_user;
  _prisma_migrations: Table_public_prisma_migrations;
}
interface Database {
  pgboss: Schema_pgboss;
  public: Schema_public;
}
interface Extension {
  public: "pgcrypto";
}
interface Tables_relationships {
  "public.AccessToken": {
    parent: {
       AccessToken_userId_fkey: "public.User";
    };
    children: {
       ExecTask_accessTokenId_fkey: "public.ExecTask";
    };
  };
  "public.AuditLog": {
    parent: {
       AuditLog_organizationId_fkey: "public.Organization";
       AuditLog_projectId_fkey: "public.Project";
       AuditLog_userId_fkey: "public.User";
    };
    children: {

    };
  };
  "public.AwsConsumptionHistory": {
    parent: {
       AwsConsumptionHistory_organizationId_fkey: "public.Organization";
       AwsConsumptionHistory_projectId_fkey: "public.Project";
       AwsConsumptionHistory_snapshotId_fkey: "public.Snapshot";
    };
    children: {

    };
  };
  "public.DatabaseProvider": {
    parent: {

    };
    children: {
       DbConnection_databaseProviderId_fkey: "public.DbConnection";
    };
  };
  "public.DbConnection": {
    parent: {
       DbConnection_databaseProviderId_fkey: "public.DatabaseProvider";
       DbConnection_organizationId_fkey: "public.Organization";
    };
    children: {
       Project_dbConnectionId_fkey: "public.Project";
       Project_hostedDbUrlId_fkey: "public.Project";
       Snapshot_dbConnectionId_fkey: "public.Snapshot";
    };
  };
  "public.ExecTask": {
    parent: {
       ExecTask_accessTokenId_fkey: "public.AccessToken";
       ExecTask_projectId_fkey: "public.Project";
    };
    children: {
       Snapshot_execTaskId_fkey: "public.Snapshot";
    };
  };
  "public.InviteToken": {
    parent: {
       InviteToken_usedByMemberId_fkey: "public.Member";
       InviteToken_organizationId_fkey: "public.Organization";
       InviteToken_createdByUserId_fkey: "public.User";
    };
    children: {

    };
  };
  "public.Member": {
    parent: {
       Member_organizationId_fkey: "public.Organization";
       Member_userId_fkey: "public.User";
    };
    children: {
       InviteToken_usedByMemberId_fkey: "public.InviteToken";
    };
  };
  "public.NeonConsumptionHistory": {
    parent: {
       NeonConsumptionHistory_organizationId_fkey: "public.Organization";
       NeonConsumptionHistory_projectId_fkey: "public.Project";
       NeonConsumptionHistory_snapshotId_fkey: "public.Snapshot";
    };
    children: {

    };
  };
  "public.NeonProject": {
    parent: {
       NeonProject_projectId_fkey: "public.Project";
       NeonProject_snapshotId_fkey: "public.Snapshot";
    };
    children: {
       PreviewDatabase_neonProjectId_fkey: "public.PreviewDatabase";
    };
  };
  "public.Organization": {
    parent: {
       Organization_pricingPlanId_fkey: "public.PricingPlan";
    };
    children: {
       AuditLog_organizationId_fkey: "public.AuditLog";
       AwsConsumptionHistory_organizationId_fkey: "public.AwsConsumptionHistory";
       DbConnection_organizationId_fkey: "public.DbConnection";
       InviteToken_organizationId_fkey: "public.InviteToken";
       Member_organizationId_fkey: "public.Member";
       NeonConsumptionHistory_organizationId_fkey: "public.NeonConsumptionHistory";
       Project_organizationId_fkey: "public.Project";
       Snapshot_organizationId_fkey: "public.Snapshot";
       Table_organizationId_fkey: "public.Table";
    };
  };
  "public.PredictionJob": {
    parent: {

    };
    children: {
       Project_predictionJobId_fkey: "public.Project";
    };
  };
  "public.PreviewDatabase": {
    parent: {
       PreviewDatabase_neonProjectId_fkey: "public.NeonProject";
    };
    children: {

    };
  };
  "public.PricingPlan": {
    parent: {

    };
    children: {
       Organization_pricingPlanId_fkey: "public.Organization";
    };
  };
  "public.Project": {
    parent: {
       Project_dbConnectionId_fkey: "public.DbConnection";
       Project_hostedDbUrlId_fkey: "public.DbConnection";
       Project_organizationId_fkey: "public.Organization";
       Project_predictionJobId_fkey: "public.PredictionJob";
       Project_supabaseProjectId_fkey: "public.SupabaseProject";
    };
    children: {
       AuditLog_projectId_fkey: "public.AuditLog";
       AwsConsumptionHistory_projectId_fkey: "public.AwsConsumptionHistory";
       ExecTask_projectId_fkey: "public.ExecTask";
       NeonConsumptionHistory_projectId_fkey: "public.NeonConsumptionHistory";
       NeonProject_projectId_fkey: "public.NeonProject";
       ShapePredictionOverride_projectId_fkey: "public.ShapePredictionOverride";
       Snapshot_projectId_fkey: "public.Snapshot";
    };
  };
  "public.ReleaseVersion": {
    parent: {
       ReleaseVersion_userId_fkey: "public.User";
    };
    children: {

    };
  };
  "public.ShapePredictionOverride": {
    parent: {
       ShapePredictionOverride_projectId_fkey: "public.Project";
    };
    children: {

    };
  };
  "public.Snapshot": {
    parent: {
       Snapshot_dbConnectionId_fkey: "public.DbConnection";
       Snapshot_execTaskId_fkey: "public.ExecTask";
       Snapshot_organizationId_fkey: "public.Organization";
       Snapshot_projectId_fkey: "public.Project";
       Snapshot_createdByUserId_fkey: "public.User";
    };
    children: {
       AwsConsumptionHistory_snapshotId_fkey: "public.AwsConsumptionHistory";
       NeonConsumptionHistory_snapshotId_fkey: "public.NeonConsumptionHistory";
       NeonProject_snapshotId_fkey: "public.NeonProject";
       Table_snapshotId_fkey: "public.Table";
    };
  };
  "public.SupabaseProject": {
    parent: {

    };
    children: {
       Project_supabaseProjectId_fkey: "public.Project";
    };
  };
  "public.Table": {
    parent: {
       Table_organizationId_fkey: "public.Organization";
       Table_snapshotId_fkey: "public.Snapshot";
    };
    children: {

    };
  };
  "public.User": {
    parent: {

    };
    children: {
       AccessToken_userId_fkey: "public.AccessToken";
       AuditLog_userId_fkey: "public.AuditLog";
       InviteToken_createdByUserId_fkey: "public.InviteToken";
       Member_userId_fkey: "public.Member";
       ReleaseVersion_userId_fkey: "public.ReleaseVersion";
       Snapshot_createdByUserId_fkey: "public.Snapshot";
    };
  };
}
//#endregion

//#region select
type SelectedTable = { id: string; schema: string; table: string };

type SelectDefault = {
  /**
   * Define the "default" behavior to use for the tables in the schema.
   * If true, select all tables in the schema.
   * If false, select no tables in the schema.
   * If "structure", select only the structure of the tables in the schema but not the data.
   * @defaultValue true
   */
  $default?: SelectObject;
};

type DefaultKey = keyof SelectDefault;

type SelectObject = boolean | "structure";

type ExtensionsSelect<TSchema extends keyof Database> =
  TSchema extends keyof Extension
    ? {
        /**
         * Define if you want to select the extension data.
         * @defaultValue false
         */
        $extensions?:
          | boolean
          | {
              [TExtension in Extension[TSchema]]?: boolean;
            };
      }
    : {};

type SelectConfig = SelectDefault & {
  [TSchema in keyof Database]?:
    | SelectObject
    | (SelectDefault &
        ExtensionsSelect<TSchema> & {
          [TTable in keyof Database[TSchema]]?: SelectObject;
        });
};

// Apply the __default key if it exists to each level of the select config (schemas and tables)
type ApplyDefault<TSelectConfig extends SelectConfig> = {
  [TSchema in keyof Database]-?: {
    [TTable in keyof Database[TSchema]]-?: TSelectConfig[TSchema] extends SelectObject
      ? TSelectConfig[TSchema]
      : TSelectConfig[TSchema] extends Record<any, any>
      ? TSelectConfig[TSchema][TTable] extends SelectObject
        ? TSelectConfig[TSchema][TTable]
        : TSelectConfig[TSchema][DefaultKey] extends SelectObject
        ? TSelectConfig[TSchema][DefaultKey]
        : TSelectConfig[DefaultKey] extends SelectObject
        ? TSelectConfig[DefaultKey]
        : true
      : TSelectConfig[DefaultKey] extends SelectObject
      ? TSelectConfig[DefaultKey]
      : true;
  };
};

type ExtractValues<T> = T extends object ? T[keyof T] : never;

type GetSelectedTable<TSelectSchemas extends SelectConfig> = ExtractValues<
  ExtractValues<{
    [TSchema in keyof TSelectSchemas]: {
      [TTable in keyof TSelectSchemas[TSchema] as TSelectSchemas[TSchema][TTable] extends true
        ? TTable
        : never]: TSchema extends string
        ? TTable extends string
          ? { id: `${TSchema}.${TTable}`; schema: TSchema; table: TTable }
          : never
        : never;
    };
  }>
>;
//#endregion

//#region transform
type TransformMode = "auto" | "strict" | "unsafe" | undefined;


type TransformOptions<TTransformMode extends TransformMode> = {
  /**
   * The type for defining the transform mode.
   *
   * There are three modes available:
   *
   * - "auto" - Automatically transform the data for any columns, tables or schemas that have not been specified in the config
   * - "strict" - In this mode, Snaplet expects a transformation to be given in the config for every column in the database. If any columns have not been provided in the config, Snaplet will not capture the snapshot, but instead tell you which columns, tables, or schemas have not been given
   * - "unsafe" - This mode copies over values without any transformation. If a transformation is given for a column in the config, the transformation will be used instead
   * @defaultValue "unsafe"
   */
  $mode?: TTransformMode;
  /**
   * If true, parse JSON objects during transformation.
   * @defaultValue false
   */
  $parseJson?: boolean;
};

// This type is here to turn a Table with scalars values (string, number, etc..) for columns into a Table
// with either scalar values or a callback function that returns the scalar value
type ColumnWithCallback<TSchema extends keyof Database, TTable extends keyof Database[TSchema]> = {
  [TColumn in keyof Database[TSchema][TTable]]:
    Database[TSchema][TTable][TColumn] |
    ((ctx: {
      row: Database[TSchema][TTable];
      value: Database[TSchema][TTable][TColumn];
    }) => Database[TSchema][TTable][TColumn])
};

type DatabaseWithCallback = {
  [TSchema in keyof Database]: {
    [TTable in keyof Database[TSchema]]:
      | ((ctx: {
          row: Database[TSchema][TTable];
          rowIndex: number;
        }) => ColumnWithCallback<TSchema, TTable>)
      | ColumnWithCallback<TSchema, TTable>
  };
};

type SelectDatabase<TSelectedTable extends SelectedTable> = {
  [TSchema in keyof DatabaseWithCallback as TSchema extends NonNullable<TSelectedTable>["schema"]
    ? TSchema
    : never]: {
    [TTable in keyof DatabaseWithCallback[TSchema] as TTable extends Extract<
      TSelectedTable,
      { schema: TSchema }
    >["table"]
      ? TTable
      : never]: DatabaseWithCallback[TSchema][TTable];
  };
};

type PartialTransform<T> = T extends (...args: infer P) => infer R
  ? (...args: P) => Partial<R>
  : Partial<T>;

type IsNever<T> = [T] extends [never] ? true : false;

type TransformConfig<
  TTransformMode extends TransformMode,
  TSelectedTable extends SelectedTable
> = TransformOptions<TTransformMode> &
  (IsNever<TSelectedTable> extends true
    ? never
    : SelectDatabase<TSelectedTable> extends infer TSelectedDatabase
    ? TTransformMode extends "strict"
      ? TSelectedDatabase
      : {
          [TSchema in keyof TSelectedDatabase]?: {
            [TTable in keyof TSelectedDatabase[TSchema]]?: PartialTransform<
              TSelectedDatabase[TSchema][TTable]
            >;
          };
        }
    : never);
//#endregion

//#region subset
type NonEmptyArray<T> = [T, ...T[]];

/**
 * Represents an exclusive row limit percent.
 */
type ExclusiveRowLimitPercent =
| {
  percent?: never;
  /**
   * Represents a strict limit of the number of rows captured on target
   */
  rowLimit: number
}
| {
  /**
   * Represents a random percent to be captured on target (1-100)
   */
  percent: number;
  rowLimit?: never
}

// Get the type of a target in the config.subset.targets array
type SubsetTarget<TSelectedTable extends SelectedTable> = {
  /**
   * The ID of the table to target
   */
  table: TSelectedTable["id"];
  /**
   * The order on which your target will be filtered useful with rowLimit parameter
   *
   * @example
   * orderBy: `"User"."createdAt" desc`
   */
  orderBy?: string;
} & (
  | {
    /**
     * The where filter to be applied on the target
     *
     * @example
     * where: `"_prisma_migrations"."name" IN ('migration1', 'migration2')`
     */
    where: string
  } & Partial<ExclusiveRowLimitPercent>
  | {
    /**
     * The where filter to be applied on the target
     */
    where?: string
  } & ExclusiveRowLimitPercent
);

type GetSelectedTableChildrenKeys<TTable extends keyof Tables_relationships> = keyof Tables_relationships[TTable]['children']
type GetSelectedTableParentKeys<TTable extends keyof Tables_relationships> = keyof Tables_relationships[TTable]['parent']
type GetSelectedTableRelationsKeys<TTable extends keyof Tables_relationships> = GetSelectedTableChildrenKeys<TTable> | GetSelectedTableParentKeys<TTable>
type SelectedTablesWithRelationsIds<TSelectedTable extends SelectedTable['id']> = TSelectedTable extends keyof Tables_relationships ? TSelectedTable : never

/**
 * Represents the options to choose the followNullableRelations of subsetting.
 */
type FollowNullableRelationsOptions<TSelectedTable extends SelectedTable> =
  // Type can be a global boolean definition
  boolean
  // Or can be a mix of $default and table specific definition
  | { $default: boolean } & ({
  // If it's a table specific definition and the table has relationships
  [TTable in SelectedTablesWithRelationsIds<TSelectedTable["id"]>]?:
    // It's either a boolean or a mix of $default and relationship specific definition
    boolean |
    {
      [Key in GetSelectedTableRelationsKeys<TTable> | '$default']?:  boolean
    }
});


/**
 * Represents the options to choose the maxCyclesLoop of subsetting.
 */
type MaxCyclesLoopOptions<TSelectedTable extends SelectedTable> =
// Type can be a global number definition
number
// Or can be a mix of $default and table specific definition
| { $default: number } & ({
  // If it's a table specific definition and the table has relationships
  [TTable in SelectedTablesWithRelationsIds<TSelectedTable["id"]>]?:
    // It's either a number or a mix of $default and relationship specific definition
    number |
    {
      [Key in GetSelectedTableRelationsKeys<TTable> | '$default']?:  number
    }
});


/**
 * Represents the options to choose the maxChildrenPerNode of subsetting.
 */
type MaxChildrenPerNodeOptions<TSelectedTable extends SelectedTable> =
// Type can be a global number definition
number
// Or can be a mix of $default and table specific definition
| { $default: number } & ({
  // If it's a table specific definition and the table has relationships
  [TTable in SelectedTablesWithRelationsIds<TSelectedTable["id"]>]?:
    // It's either a number or a mix of $default and relationship specific definition
    number |
    {
      [Key in GetSelectedTableRelationsKeys<TTable> | '$default']?:  number
    }
});

/**
 * Represents the configuration for subsetting the snapshot.
 */
type SubsetConfig<TSelectedTable extends SelectedTable> = {
  /**
   * Specifies whether subsetting is enabled.
   *  @defaultValue true
   */
  enabled?: boolean;

  /**
   * Specifies the version of the subsetting algorithm
   *
   * @defaultValue "3"
   * @deprecated
   */
  version?: "1" | "2" | "3";

  /**
   * Specifies whether to eagerly load related tables.
   * @defaultValue false
   */
  eager?: boolean;

  /**
   * Specifies whether to keep tables that are not connected to any other tables.
   * @defaultValue false
   */
  keepDisconnectedTables?: boolean;

  /**
   * Specifies whether to follow nullable relations.
   * @defaultValue false
   */
  followNullableRelations?: FollowNullableRelationsOptions<TSelectedTable>;

  /**
   *  Specifies the maximum number of children per node.
   *  @defaultValue unlimited
   */
  maxChildrenPerNode?: MaxChildrenPerNodeOptions<TSelectedTable>;

  /**
   * Specifies the maximum number of cycles in a loop.
   * @defaultValue 10
   */
  maxCyclesLoop?: MaxCyclesLoopOptions<TSelectedTable>;

  /**
   * Specifies the root targets for subsetting. Must be a non-empty array
   */
  targets: NonEmptyArray<SubsetTarget<TSelectedTable>>;

  /**
   * Specifies the task sorting algorithm.
   * By default, the algorithm will not sort the tasks.
   */
  taskSortAlgorithm?: "children" | "idsCount";
}
//#endregion


  //#region introspect
  type VirtualForeignKey<
    TTFkTable extends SelectedTable,
    TTargetTable extends SelectedTable
  > =
  {
    fkTable: TTFkTable['id'];
    targetTable: TTargetTable['id'];
    keys: NonEmptyArray<
      {
        // TODO: Find a way to strongly type this to provide autocomplete when writing the config
        /**
         * The column name present in the fkTable that is a foreign key to the targetTable
         */
        fkColumn: string;
        /**
         * The column name present in the targetTable that is a foreign key to the fkTable
         */
        targetColumn: string;
      }
    >
  }

  type IntrospectConfig<TSelectedTable extends SelectedTable> = {
    /**
     * Allows you to declare virtual foreign keys that are not present as foreign keys in the database.
     * But are still used and enforced by the application.
     */
    virtualForeignKeys?: Array<VirtualForeignKey<TSelectedTable, TSelectedTable>>;
  }
  //#endregion

type Validate<T, Target> = {
  [K in keyof T]: K extends keyof Target ? T[K] : never;
};

type TypedConfig<
  TSelectConfig extends SelectConfig,
  TTransformMode extends TransformMode
> =  GetSelectedTable<
  ApplyDefault<TSelectConfig>
> extends SelectedTable
  ? {
    /**
     * Parameter to configure the generation of data.
     * {@link https://docs.snaplet.dev/core-concepts/seed}
     */
      generate?: {
        alias?: import("./snaplet-client").Alias;
        models?: import("./snaplet-client").UserModels;
        run: (snaplet: import("./snaplet-client").SeedClientBase) => Promise<any>;
      }
    /**
     * Parameter to configure the inclusion/exclusion of schemas and tables from the snapshot.
     * {@link https://docs.snaplet.dev/reference/configuration#select}
     */
      select?: Validate<TSelectConfig, SelectConfig>;
      /**
       * Parameter to configure the transformations applied to the data.
       * {@link https://docs.snaplet.dev/reference/configuration#transform}
       */
      transform?: TransformConfig<TTransformMode, GetSelectedTable<ApplyDefault<TSelectConfig>>>;
      /**
       * Parameter to capture a subset of the data.
       * {@link https://docs.snaplet.dev/reference/configuration#subset}
       */
      subset?: SubsetConfig<GetSelectedTable<ApplyDefault<TSelectConfig>>>;

      /**
       * Parameter to augment the result of the introspection of your database.
       * {@link https://docs.snaplet.dev/references/data-operations/introspect}
       */
      introspect?: IntrospectConfig<GetSelectedTable<ApplyDefault<TSelectConfig>>>;
    }
  : never;

declare module "snaplet" {
  class JsonNull {}
  type JsonClass = typeof JsonNull;
  /**
   * Use this value to explicitely set a json or jsonb column to json null instead of the database NULL value.
   */
  export const jsonNull: InstanceType<JsonClass>;
  /**
  * Define the configuration for Snaplet capture process.
  * {@link https://docs.snaplet.dev/reference/configuration}
  */
  export function defineConfig<
    TSelectConfig extends SelectConfig,
    TTransformMode extends TransformMode = undefined
  >(
    config: TypedConfig<TSelectConfig, TTransformMode>
  ): TypedConfig<TSelectConfig, TTransformMode>;
}