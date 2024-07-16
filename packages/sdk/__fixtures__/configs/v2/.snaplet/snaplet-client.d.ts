type JsonPrimitive = null | number | string | boolean;
type Nested<V> = V | { [s: string]: V | Nested<V> } | Array<V | Nested<V>>;
type Json = Nested<JsonPrimitive>;

type ColumnValueCallbackContext = {
  /**
   * The seed of the field's model.
   *
   * \@example
   * ```ts
   * "<hash>/0/users/0"
   * ```
   */
  modelSeed: string;
  /**
   * The seed of the field.
   *
   * \@example
   * ```ts
   * "<hash>/0/users/0/email"
   * ```
   */
  seed: string;
};

/**
 * helper type to get the possible values of a scalar field
 */
type ColumnValue<T> = T | ((ctx: ColumnValueCallbackContext) => T);

/**
 * helper type to map a record of scalars to a record of ColumnValue
 */
type MapToColumnValue<T> = { [K in keyof T]: ColumnValue<T[K]> };

/**
 * Create an array of `n` models.
 *
 * Can be read as "Generate `model` times `n`".
 *
 * @param `n` The number of models to generate.
 * @param `callbackFn` The `x` function calls the `callbackFn` function one time for each element in the array.
 *
 * @example Generate 10 users:
 * ```ts
 * snaplet.users((x) => x(10));
 * ```
 *
 * @example Generate 3 projects with a specific name:
 * ```ts
 * snaplet.projects((x) => x(3, (index) => ({ name: `Project ${index}` })));
 * ```
 */
declare function xCallbackFn<T>(
  n: number | MinMaxOption,
  callbackFn?: (index: number) => T
): Array<T>;

type ChildCallbackInputs<T> = (
  x: typeof xCallbackFn<T>,
) => Array<T>;

/**
 * all the possible types for a child field
 */
type ChildInputs<T> = Array<T> | ChildCallbackInputs<T>;

/**
 * omit some keys TKeys from a child field
 * @example we remove ExecTask from the Snapshot child field values as we're coming from ExecTask
 * type ExecTaskChildrenInputs<TPath extends string[]> = {
 *   Snapshot: OmitChildInputs<SnapshotChildInputs<[...TPath, "Snapshot"]>, "ExecTask">;
 * };
 */
type OmitChildInputs<T, TKeys extends string> = T extends ChildCallbackInputs<
  infer U
>
  ? ChildCallbackInputs<Omit<U, TKeys>>
  : T extends Array<infer U>
  ? Array<Omit<U, TKeys>>
  : never;

type ConnectCallbackContext<TGraph, TPath extends string[]> = {
  /**
   * The branch of the current iteration for the relationship field.
   *
   * Learn more in the {@link https://docs.snaplet.dev/core-concepts/seed#branch | documentation}.
   */
  branch: GetBranch<TGraph, TPath>;
  /**
   * The plan's graph.
   *
   * Learn more in the {@link https://docs.snaplet.dev/core-concepts/seed#graph | documentation}.
   */
  graph: TGraph;
  /**
   * The index of the current iteration.
   */
  index: number;
  /**
   * The seed of the relationship field.
   */
  seed: string;
  /**
   * The plan's store.
   */
  store: Store;
};

/**
 * the callback function we can pass to a parent field to connect it to another model
 * @example
 * snaplet.Post({ User: (ctx) => ({ id: ctx.store.User[0] }) })
 */
type ConnectCallback<T, TGraph, TPath extends string[]> = (
  ctx: ConnectCallbackContext<TGraph, TPath>
) => T;

/**
 * compute the Graph type and the tracked path to pass to the connect callback
 */
type ParentCallbackInputs<T, TPath extends string[]> = TPath extends [
  infer TRoot,
  ...infer TRest extends string[],
]
  ? TRoot extends keyof Graph
    ? MergeGraphParts<Graph[TRoot]> extends infer TGraph
      ? ConnectCallback<T, TGraph, TRest>
      : never
    : never
  : never;

type ParentInputs<T, TPath extends string[]> =
  | T
  | ParentCallbackInputs<T, TPath>;

/**
 * omit some keys TKeys from a parent field
 * @example we remove Member from the Organization and User parent fields values as we're coming from Member
 * type MemberParentsInputs<TPath extends string[]> = {
 *   Organization: OmitParentInputs<OrganizationParentInputs<[...TPath, "Organization"]>, "Member", [...TPath, "Organization"]>;
 *   User: OmitParentInputs<UserParentInputs<[...TPath, "User"]>, "Member", [...TPath, "User"]>;
 * };
 */
type OmitParentInputs<
  T,
  TKeys extends string,
  TPath extends string[],
> = T extends ConnectCallback<infer U, any, any>
  ? ParentCallbackInputs<Omit<U, TKeys>, TPath>
  : Omit<T, TKeys>;

/**
 * compute the inputs type for a given model
 */
type Inputs<TScalars, TParents, TChildren> = Partial<
  MapToColumnValue<TScalars> & TParents & TChildren
>;

type OmitChildGraph<
  T extends Array<unknown>,
  TKeys extends string,
> = T extends Array<
  infer TGraph extends { Scalars: any; Parents: any; Children: any }
>
  ? Array<{
      Scalars: TGraph["Scalars"];
      Parents: TGraph["Parents"];
      Children: Omit<TGraph["Children"], TKeys>;
    }>
  : never;

type OmitParentGraph<
  T extends Array<unknown>,
  TKeys extends string,
> = T extends Array<
  infer TGraph extends { Scalars: any; Parents: any; Children: any }
>
  ? Array<{
      Scalars: TGraph["Scalars"];
      Parents: Omit<TGraph["Parents"], TKeys>;
      Children: TGraph["Children"];
    }>
  : never;

type UnwrapArray<T> = T extends Array<infer U> ? U : T;

type DeepUnwrapKeys<TGraph, TKeys extends any[]> = TKeys extends [
  infer THead,
  ...infer TTail,
]
  ? TTail extends any[]
    ? {
        [P in keyof TGraph]: P extends THead
          ? DeepUnwrapKeys<UnwrapArray<TGraph[P]>, TTail>
          : TGraph[P];
      }
    : TGraph
  : TGraph;

type GetBranch<T, K extends any[]> = T extends Array<infer U>
  ? DeepUnwrapKeys<U, K>
  : T;

type MergeGraphParts<T> = T extends Array<
  infer U extends { Scalars: unknown; Parents: unknown; Children: unknown }
>
  ? Array<
      U["Scalars"] & {
        [K in keyof U["Children"]]: MergeGraphParts<U["Children"][K]>;
      } & {
        [K in keyof U["Parents"]]: MergeGraphParts<
          U["Parents"][K]
        > extends Array<infer TParent>
          ? TParent
          : never;
      }
    >
  : never;

/**
 * the configurable map of models' generate and connect functions
 */
export type UserModels = {
  [KStore in keyof Store]?: Store[KStore] extends Array<
    infer TFields extends Record<string, any>
  >
    ? {
        connect?: (ctx: { store: Store }) => TFields;
        data?: Partial<MapToColumnValue<TFields>>;
      }
    : never;
};

type PlanOptions = {
  /**
   * Connect the missing relationships to one of the corresponding models in the store.
   *
   * Learn more in the {@link https://docs.snaplet.dev/core-concepts/seed#using-autoconnect-option | documentation}.
   */
  autoConnect?: boolean;
  /**
   * Provide custom data generation and connect functions for this plan.
   *
   * Learn more in the {@link https://docs.snaplet.dev/core-concepts/seed#using-autoconnect-option | documentation}.
   */
  models?: UserModels;
  /**
   * Pass a custom store instance to use for this plan.
   *
   * Learn more in the {@link https://docs.snaplet.dev/core-concepts/seed#augmenting-external-data-with-createstore | documentation}.
   */
  store?: StoreInstance;
  /**
   * Use a custom seed for this plan.
   */
  seed?: string;
};

/**
 * the plan is extending PromiseLike so it can be awaited
 * @example
 * await snaplet.User({ name: "John" });
 */
export interface Plan extends PromiseLike<any> {
  generate: (initialStore?: Store) => Promise<Store>;
  /**
   * Compose multiple plans together, injecting the store of the previous plan into the next plan.
   *
   * Learn more in the {@link https://docs.snaplet.dev/core-concepts/seed#using-pipe | documentation}.
   */
  pipe: Pipe;
  /**
   * Compose multiple plans together, without injecting the store of the previous plan into the next plan.
   * All stores stay independent and are merged together once all the plans are generated.
   *
   * Learn more in the {@link https://docs.snaplet.dev/core-concepts/seed#using-merge | documentation}.
   */
  merge: Merge;
}

type Pipe = (plans: Plan[], options?: { models?: UserModels, seed?: string }) => Plan;

type Merge = (plans: Plan[], options?: { models?: UserModels, seed?: string }) => Plan;

type StoreInstance<T extends Partial<Store> = {}> = {
  _store: T;
  toSQL: () => string[];
};

type CreateStore = <T extends Partial<Store>>(
  initialData?: T,
  options?: { external: boolean },
) => StoreInstance<T>;
type Store = {
  accessTokens: Array<accessTokensScalars>;
  auditLogs: Array<auditLogsScalars>;
  awsConsumptionHistories: Array<awsConsumptionHistoriesScalars>;
  databaseProviders: Array<databaseProvidersScalars>;
  dbConnections: Array<dbConnectionsScalars>;
  execTasks: Array<execTasksScalars>;
  inviteTokens: Array<inviteTokensScalars>;
  members: Array<membersScalars>;
  neonConsumptionHistories: Array<neonConsumptionHistoriesScalars>;
  neonProjects: Array<neonProjectsScalars>;
  organizations: Array<organizationsScalars>;
  predictionDataSets: Array<predictionDataSetsScalars>;
  predictionJobs: Array<predictionJobsScalars>;
  previewDatabases: Array<previewDatabasesScalars>;
  pricingPlans: Array<pricingPlansScalars>;
  projects: Array<projectsScalars>;
  releaseVersions: Array<releaseVersionsScalars>;
  shapePredictionOverrides: Array<shapePredictionOverridesScalars>;
  shapePredictionStores: Array<shapePredictionStoresScalars>;
  snapshots: Array<snapshotsScalars>;
  supabaseProjects: Array<supabaseProjectsScalars>;
  tables: Array<tablesScalars>;
  users: Array<usersScalars>;
  PrismaMigrations: Array<PrismaMigrationsScalars>;
  jobs: Array<jobsScalars>;
  schedules: Array<schedulesScalars>;
  versions: Array<versionsScalars>;
};
type job_stateEnum = "active" | "cancelled" | "completed" | "created" | "expired" | "failed" | "retry";
type AccessTokenTypeEnum = "CLI" | "WORKER";
type AuditLogActionsEnum = "EMAIL_SENT_INCOMPLETE_ONBOARDING" | "EMAIL_SENT_ORGANIZATION_CHURN" | "ORGANIZATION_DELETED" | "PII_UPDATED_PREDICTIONS_OVERRIDE" | "PREVIEW_DATABASE_CREATED" | "PREVIEW_DATABASE_DEPLOYED" | "PREVIEW_DATABASE_DESTROYED" | "PREVIEW_DATABASE_DROPPED" | "PREVIEW_DATABASE_RESET" | "PROJECT_DELETED" | "SNAPSHOT_CONFIG_UPDATED" | "SNAPSHOT_CREATED" | "SNAPSHOT_DELETED" | "SNAPSHOT_RESTORED_FAILURE" | "SNAPSHOT_RESTORED_SUCCESS";
type DatabaseStatusEnum = "DELETED" | "DISABLED" | "ENABLED";
type MemberRoleEnum = "ADMIN" | "MEMBER" | "OWNER";
type PredictionsEngineEnum = "FINETUNED_BERT";
type ReleaseChannelEnum = "BETA" | "PRIVATE" | "PUBLIC";
type SnapshotStatusEnum = "BOOTING" | "DELETED" | "FAILURE" | "IN_PROGRESS" | "PENDING" | "PURGED" | "STARTED" | "STARTING" | "SUCCESS" | "TIMEOUT";
type UserNotificationsEnum = "EMAIL" | "NONE";
type UserRoleEnum = "ADMIN" | "SUPERUSER" | "USER";
type accessTokensScalars = {
  /**
   * Column `AccessToken.id`.
   */
  id: string;
  /**
   * Column `AccessToken.updatedAt`.
   */
  updatedAt: string;
  /**
   * Column `AccessToken.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `AccessToken.userId`.
   */
  userId: string;
  /**
   * Column `AccessToken.userAgent`.
   */
  userAgent: string | null;
  /**
   * Column `AccessToken.type`.
   */
  type?: AccessTokenTypeEnum;
  /**
   * Column `AccessToken.name`.
   */
  name: string | null;
  /**
   * Column `AccessToken.hash`.
   */
  hash: string | null;
}
type accessTokensParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `AccessToken` to table `User` through the column `AccessToken.userId`.
   */
  user: OmitParentInputs<usersParentInputs<[...TPath, "user"]>, "accessTokens", [...TPath, "user"]>;
};
type accessTokensChildrenInputs<TPath extends string[]> = {
  /**
  * Relationship from table `AccessToken` to table `ExecTask` through the column `ExecTask.accessTokenId`.
  */
  execTasks: OmitChildInputs<execTasksChildInputs<[...TPath, "execTasks"]>, "accessToken" | "accessTokenId">;
};
type accessTokensInputs<TPath extends string[]> = Inputs<
  accessTokensScalars,
  accessTokensParentsInputs<TPath>,
  accessTokensChildrenInputs<TPath>
>;
type accessTokensChildInputs<TPath extends string[]> = ChildInputs<accessTokensInputs<TPath>>;
type accessTokensParentInputs<TPath extends string[]> = ParentInputs<
accessTokensInputs<TPath>,
  TPath
>;
type auditLogsScalars = {
  /**
   * Column `AuditLog.id`.
   */
  id: string;
  /**
   * Column `AuditLog.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `AuditLog.action`.
   */
  action: AuditLogActionsEnum;
  /**
   * Column `AuditLog.data`.
   */
  data: Json | null;
  /**
   * Column `AuditLog.userId`.
   */
  userId: string | null;
  /**
   * Column `AuditLog.organizationId`.
   */
  organizationId: string;
  /**
   * Column `AuditLog.projectId`.
   */
  projectId: string | null;
}
type auditLogsParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `AuditLog` to table `Organization` through the column `AuditLog.organizationId`.
   */
  organization: OmitParentInputs<organizationsParentInputs<[...TPath, "organization"]>, "auditLogs", [...TPath, "organization"]>;
  /**
   * Relationship from table `AuditLog` to table `Project` through the column `AuditLog.projectId`.
   */
  project: OmitParentInputs<projectsParentInputs<[...TPath, "project"]>, "auditLogs", [...TPath, "project"]>;
  /**
   * Relationship from table `AuditLog` to table `User` through the column `AuditLog.userId`.
   */
  user: OmitParentInputs<usersParentInputs<[...TPath, "user"]>, "auditLogs", [...TPath, "user"]>;
};
type auditLogsChildrenInputs<TPath extends string[]> = {

};
type auditLogsInputs<TPath extends string[]> = Inputs<
  auditLogsScalars,
  auditLogsParentsInputs<TPath>,
  auditLogsChildrenInputs<TPath>
>;
type auditLogsChildInputs<TPath extends string[]> = ChildInputs<auditLogsInputs<TPath>>;
type auditLogsParentInputs<TPath extends string[]> = ParentInputs<
auditLogsInputs<TPath>,
  TPath
>;
type awsConsumptionHistoriesScalars = {
  /**
   * Column `AwsConsumptionHistory.name`.
   */
  name: string;
  /**
   * Column `AwsConsumptionHistory.startPeriod`.
   */
  startPeriod: string;
  /**
   * Column `AwsConsumptionHistory.endPeriod`.
   */
  endPeriod: string;
  /**
   * Column `AwsConsumptionHistory.awsStorageBytes`.
   */
  awsStorageBytes: number | null;
  /**
   * Column `AwsConsumptionHistory.awsComputeTimeSeconds`.
   */
  awsComputeTimeSeconds: number | null;
  /**
   * Column `AwsConsumptionHistory.awsDataTransferBytes`.
   */
  awsDataTransferBytes: number | null;
  /**
   * Column `AwsConsumptionHistory.snapshotId`.
   */
  snapshotId: string | null;
  /**
   * Column `AwsConsumptionHistory.projectId`.
   */
  projectId: string | null;
  /**
   * Column `AwsConsumptionHistory.organizationId`.
   */
  organizationId: string;
}
type awsConsumptionHistoriesParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `AwsConsumptionHistory` to table `Organization` through the column `AwsConsumptionHistory.organizationId`.
   */
  organization: OmitParentInputs<organizationsParentInputs<[...TPath, "organization"]>, "awsConsumptionHistories", [...TPath, "organization"]>;
  /**
   * Relationship from table `AwsConsumptionHistory` to table `Project` through the column `AwsConsumptionHistory.projectId`.
   */
  project: OmitParentInputs<projectsParentInputs<[...TPath, "project"]>, "awsConsumptionHistories", [...TPath, "project"]>;
  /**
   * Relationship from table `AwsConsumptionHistory` to table `Snapshot` through the column `AwsConsumptionHistory.snapshotId`.
   */
  snapshot: OmitParentInputs<snapshotsParentInputs<[...TPath, "snapshot"]>, "awsConsumptionHistories", [...TPath, "snapshot"]>;
};
type awsConsumptionHistoriesChildrenInputs<TPath extends string[]> = {

};
type awsConsumptionHistoriesInputs<TPath extends string[]> = Inputs<
  awsConsumptionHistoriesScalars,
  awsConsumptionHistoriesParentsInputs<TPath>,
  awsConsumptionHistoriesChildrenInputs<TPath>
>;
type awsConsumptionHistoriesChildInputs<TPath extends string[]> = ChildInputs<awsConsumptionHistoriesInputs<TPath>>;
type awsConsumptionHistoriesParentInputs<TPath extends string[]> = ParentInputs<
awsConsumptionHistoriesInputs<TPath>,
  TPath
>;
type databaseProvidersScalars = {
  /**
   * Column `DatabaseProvider.id`.
   */
  id?: number;
  /**
   * Column `DatabaseProvider.name`.
   */
  name: string;
  /**
   * Column `DatabaseProvider.domain`.
   */
  domain: string;
}
type databaseProvidersParentsInputs<TPath extends string[]> = {

};
type databaseProvidersChildrenInputs<TPath extends string[]> = {
  /**
  * Relationship from table `DatabaseProvider` to table `DbConnection` through the column `DbConnection.databaseProviderId`.
  */
  dbConnections: OmitChildInputs<dbConnectionsChildInputs<[...TPath, "dbConnections"]>, "databaseProvider" | "databaseProviderId">;
};
type databaseProvidersInputs<TPath extends string[]> = Inputs<
  databaseProvidersScalars,
  databaseProvidersParentsInputs<TPath>,
  databaseProvidersChildrenInputs<TPath>
>;
type databaseProvidersChildInputs<TPath extends string[]> = ChildInputs<databaseProvidersInputs<TPath>>;
type databaseProvidersParentInputs<TPath extends string[]> = ParentInputs<
databaseProvidersInputs<TPath>,
  TPath
>;
type dbConnectionsScalars = {
  /**
   * Column `DbConnection.id`.
   */
  id: string;
  /**
   * Column `DbConnection.name`.
   */
  name: string | null;
  /**
   * Column `DbConnection.ssl`.
   */
  ssl?: boolean;
  /**
   * Column `DbConnection.connectionUrlHash`.
   */
  connectionUrlHash: Json;
  /**
   * Column `DbConnection.organizationId`.
   */
  organizationId: string;
  /**
   * Column `DbConnection.databaseProviderId`.
   */
  databaseProviderId: number | null;
}
type dbConnectionsParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `DbConnection` to table `DatabaseProvider` through the column `DbConnection.databaseProviderId`.
   */
  databaseProvider: OmitParentInputs<databaseProvidersParentInputs<[...TPath, "databaseProvider"]>, "dbConnections", [...TPath, "databaseProvider"]>;
  /**
   * Relationship from table `DbConnection` to table `Organization` through the column `DbConnection.organizationId`.
   */
  organization: OmitParentInputs<organizationsParentInputs<[...TPath, "organization"]>, "dbConnections", [...TPath, "organization"]>;
};
type dbConnectionsChildrenInputs<TPath extends string[]> = {
  /**
  * Relationship from table `DbConnection` to table `Project` through the column `Project.dbConnectionId`.
  */
  projects: OmitChildInputs<projectsChildInputs<[...TPath, "projects"]>, "dbConnection" | "dbConnectionId">;
  /**
  * Relationship from table `DbConnection` to table `Project` through the column `Project.hostedDbUrlId`.
  */
  projectsByHostedDbUrlId: OmitChildInputs<projectsChildInputs<[...TPath, "projectsByHostedDbUrlId"]>, "hostedDbUrl" | "hostedDbUrlId">;
  /**
  * Relationship from table `DbConnection` to table `Snapshot` through the column `Snapshot.dbConnectionId`.
  */
  snapshots: OmitChildInputs<snapshotsChildInputs<[...TPath, "snapshots"]>, "dbConnection" | "dbConnectionId">;
};
type dbConnectionsInputs<TPath extends string[]> = Inputs<
  dbConnectionsScalars,
  dbConnectionsParentsInputs<TPath>,
  dbConnectionsChildrenInputs<TPath>
>;
type dbConnectionsChildInputs<TPath extends string[]> = ChildInputs<dbConnectionsInputs<TPath>>;
type dbConnectionsParentInputs<TPath extends string[]> = ParentInputs<
dbConnectionsInputs<TPath>,
  TPath
>;
type execTasksScalars = {
  /**
   * Column `ExecTask.id`.
   */
  id: string;
  /**
   * Column `ExecTask.command`.
   */
  command: string;
  /**
   * Column `ExecTask.env`.
   */
  env: Json | null;
  /**
   * Column `ExecTask.exitCode`.
   */
  exitCode: number | null;
  /**
   * Column `ExecTask.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `ExecTask.updatedAt`.
   */
  updatedAt?: string;
  /**
   * Column `ExecTask.projectId`.
   */
  projectId: string;
  /**
   * Column `ExecTask.needsSourceDatabaseUrl`.
   */
  needsSourceDatabaseUrl?: boolean;
  /**
   * Column `ExecTask.progress`.
   */
  progress: Json | null;
  /**
   * Column `ExecTask.endedAt`.
   */
  endedAt: string | null;
  /**
   * Column `ExecTask.arn`.
   */
  arn: string | null;
  /**
   * Column `ExecTask.accessTokenId`.
   */
  accessTokenId: string | null;
  /**
   * Column `ExecTask.lastNotifiedAt`.
   */
  lastNotifiedAt: string | null;
}
type execTasksParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `ExecTask` to table `AccessToken` through the column `ExecTask.accessTokenId`.
   */
  accessToken: OmitParentInputs<accessTokensParentInputs<[...TPath, "accessToken"]>, "execTasks", [...TPath, "accessToken"]>;
  /**
   * Relationship from table `ExecTask` to table `Project` through the column `ExecTask.projectId`.
   */
  project: OmitParentInputs<projectsParentInputs<[...TPath, "project"]>, "execTasks", [...TPath, "project"]>;
};
type execTasksChildrenInputs<TPath extends string[]> = {
  /**
  * Relationship from table `ExecTask` to table `Snapshot` through the column `Snapshot.execTaskId`.
  */
  snapshots: OmitChildInputs<snapshotsChildInputs<[...TPath, "snapshots"]>, "execTask" | "execTaskId">;
};
type execTasksInputs<TPath extends string[]> = Inputs<
  execTasksScalars,
  execTasksParentsInputs<TPath>,
  execTasksChildrenInputs<TPath>
>;
type execTasksChildInputs<TPath extends string[]> = ChildInputs<execTasksInputs<TPath>>;
type execTasksParentInputs<TPath extends string[]> = ParentInputs<
execTasksInputs<TPath>,
  TPath
>;
type inviteTokensScalars = {
  /**
   * Column `InviteToken.token`.
   */
  token: string;
  /**
   * Column `InviteToken.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `InviteToken.updatedAt`.
   */
  updatedAt: string;
  /**
   * Column `InviteToken.createdByUserId`.
   */
  createdByUserId: string;
  /**
   * Column `InviteToken.usedByMemberId`.
   */
  usedByMemberId: number | null;
  /**
   * Column `InviteToken.organizationId`.
   */
  organizationId: string | null;
  /**
   * Column `InviteToken.expiresAt`.
   */
  expiresAt: string;
}
type inviteTokensParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `InviteToken` to table `Member` through the column `InviteToken.usedByMemberId`.
   */
  usedByMember: OmitParentInputs<membersParentInputs<[...TPath, "usedByMember"]>, "inviteTokensByUsedByMemberId", [...TPath, "usedByMember"]>;
  /**
   * Relationship from table `InviteToken` to table `Organization` through the column `InviteToken.organizationId`.
   */
  organization: OmitParentInputs<organizationsParentInputs<[...TPath, "organization"]>, "inviteTokens", [...TPath, "organization"]>;
  /**
   * Relationship from table `InviteToken` to table `User` through the column `InviteToken.createdByUserId`.
   */
  createdByUser: OmitParentInputs<usersParentInputs<[...TPath, "createdByUser"]>, "inviteTokensByCreatedByUserId", [...TPath, "createdByUser"]>;
};
type inviteTokensChildrenInputs<TPath extends string[]> = {

};
type inviteTokensInputs<TPath extends string[]> = Inputs<
  inviteTokensScalars,
  inviteTokensParentsInputs<TPath>,
  inviteTokensChildrenInputs<TPath>
>;
type inviteTokensChildInputs<TPath extends string[]> = ChildInputs<inviteTokensInputs<TPath>>;
type inviteTokensParentInputs<TPath extends string[]> = ParentInputs<
inviteTokensInputs<TPath>,
  TPath
>;
type membersScalars = {
  /**
   * Column `Member.role`.
   */
  role?: MemberRoleEnum;
  /**
   * Column `Member.organizationId`.
   */
  organizationId: string;
  /**
   * Column `Member.userId`.
   */
  userId: string;
  /**
   * Column `Member.id`.
   */
  id?: number;
  /**
   * Column `Member.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `Member.updatedAt`.
   */
  updatedAt: string;
}
type membersParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `Member` to table `Organization` through the column `Member.organizationId`.
   */
  organization: OmitParentInputs<organizationsParentInputs<[...TPath, "organization"]>, "members", [...TPath, "organization"]>;
  /**
   * Relationship from table `Member` to table `User` through the column `Member.userId`.
   */
  user: OmitParentInputs<usersParentInputs<[...TPath, "user"]>, "members", [...TPath, "user"]>;
};
type membersChildrenInputs<TPath extends string[]> = {
  /**
  * Relationship from table `Member` to table `InviteToken` through the column `InviteToken.usedByMemberId`.
  */
  inviteTokensByUsedByMemberId: OmitChildInputs<inviteTokensChildInputs<[...TPath, "inviteTokensByUsedByMemberId"]>, "usedByMember" | "usedByMemberId">;
};
type membersInputs<TPath extends string[]> = Inputs<
  membersScalars,
  membersParentsInputs<TPath>,
  membersChildrenInputs<TPath>
>;
type membersChildInputs<TPath extends string[]> = ChildInputs<membersInputs<TPath>>;
type membersParentInputs<TPath extends string[]> = ParentInputs<
membersInputs<TPath>,
  TPath
>;
type neonConsumptionHistoriesScalars = {
  /**
   * Column `NeonConsumptionHistory.name`.
   */
  name: string;
  /**
   * Column `NeonConsumptionHistory.startPeriod`.
   */
  startPeriod: string;
  /**
   * Column `NeonConsumptionHistory.endPeriod`.
   */
  endPeriod: string;
  /**
   * Column `NeonConsumptionHistory.neonDataStorageBytesHour`.
   */
  neonDataStorageBytesHour: number | null;
  /**
   * Column `NeonConsumptionHistory.neonSyntheticStorageSize`.
   */
  neonSyntheticStorageSize: number | null;
  /**
   * Column `NeonConsumptionHistory.neonDataTransferBytes`.
   */
  neonDataTransferBytes: number | null;
  /**
   * Column `NeonConsumptionHistory.neonWrittenDataBytes`.
   */
  neonWrittenDataBytes: number | null;
  /**
   * Column `NeonConsumptionHistory.neonComputeTimeSeconds`.
   */
  neonComputeTimeSeconds: number | null;
  /**
   * Column `NeonConsumptionHistory.neonActiveTimeSeconds`.
   */
  neonActiveTimeSeconds: number | null;
  /**
   * Column `NeonConsumptionHistory.snapshotId`.
   */
  snapshotId: string | null;
  /**
   * Column `NeonConsumptionHistory.projectId`.
   */
  projectId: string | null;
  /**
   * Column `NeonConsumptionHistory.organizationId`.
   */
  organizationId: string;
}
type neonConsumptionHistoriesParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `NeonConsumptionHistory` to table `Organization` through the column `NeonConsumptionHistory.organizationId`.
   */
  organization: OmitParentInputs<organizationsParentInputs<[...TPath, "organization"]>, "neonConsumptionHistories", [...TPath, "organization"]>;
  /**
   * Relationship from table `NeonConsumptionHistory` to table `Project` through the column `NeonConsumptionHistory.projectId`.
   */
  project: OmitParentInputs<projectsParentInputs<[...TPath, "project"]>, "neonConsumptionHistories", [...TPath, "project"]>;
  /**
   * Relationship from table `NeonConsumptionHistory` to table `Snapshot` through the column `NeonConsumptionHistory.snapshotId`.
   */
  snapshot: OmitParentInputs<snapshotsParentInputs<[...TPath, "snapshot"]>, "neonConsumptionHistories", [...TPath, "snapshot"]>;
};
type neonConsumptionHistoriesChildrenInputs<TPath extends string[]> = {

};
type neonConsumptionHistoriesInputs<TPath extends string[]> = Inputs<
  neonConsumptionHistoriesScalars,
  neonConsumptionHistoriesParentsInputs<TPath>,
  neonConsumptionHistoriesChildrenInputs<TPath>
>;
type neonConsumptionHistoriesChildInputs<TPath extends string[]> = ChildInputs<neonConsumptionHistoriesInputs<TPath>>;
type neonConsumptionHistoriesParentInputs<TPath extends string[]> = ParentInputs<
neonConsumptionHistoriesInputs<TPath>,
  TPath
>;
type neonProjectsScalars = {
  /**
   * Column `NeonProject.id`.
   */
  id: string;
  /**
   * Column `NeonProject.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `NeonProject.updatedAt`.
   */
  updatedAt: string;
  /**
   * Column `NeonProject.neonProjectId`.
   */
  neonProjectId: string;
  /**
   * Column `NeonProject.snapshotId`.
   */
  snapshotId: string | null;
  /**
   * Column `NeonProject.connectionUrlHash`.
   */
  connectionUrlHash: Json;
  /**
   * Column `NeonProject.projectId`.
   */
  projectId: string;
}
type neonProjectsParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `NeonProject` to table `Project` through the column `NeonProject.projectId`.
   */
  project: OmitParentInputs<projectsParentInputs<[...TPath, "project"]>, "neonProjects", [...TPath, "project"]>;
  /**
   * Relationship from table `NeonProject` to table `Snapshot` through the column `NeonProject.snapshotId`.
   */
  snapshot: OmitParentInputs<snapshotsParentInputs<[...TPath, "snapshot"]>, "neonProjects", [...TPath, "snapshot"]>;
};
type neonProjectsChildrenInputs<TPath extends string[]> = {
  /**
  * Relationship from table `NeonProject` to table `PreviewDatabase` through the column `PreviewDatabase.neonProjectId`.
  */
  previewDatabases: OmitChildInputs<previewDatabasesChildInputs<[...TPath, "previewDatabases"]>, "neonProject" | "neonProjectId">;
};
type neonProjectsInputs<TPath extends string[]> = Inputs<
  neonProjectsScalars,
  neonProjectsParentsInputs<TPath>,
  neonProjectsChildrenInputs<TPath>
>;
type neonProjectsChildInputs<TPath extends string[]> = ChildInputs<neonProjectsInputs<TPath>>;
type neonProjectsParentInputs<TPath extends string[]> = ParentInputs<
neonProjectsInputs<TPath>,
  TPath
>;
type organizationsScalars = {
  /**
   * Column `Organization.id`.
   */
  id: string;
  /**
   * Column `Organization.name`.
   */
  name: string;
  /**
   * Column `Organization.pricingPlanId`.
   */
  pricingPlanId: number | null;
  /**
   * Column `Organization.subscriptionData`.
   */
  subscriptionData: Json | null;
  /**
   * Column `Organization.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `Organization.updatedAt`.
   */
  updatedAt: string;
  /**
   * Column `Organization.deleted`.
   */
  deleted?: boolean;
}
type organizationsParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `Organization` to table `PricingPlan` through the column `Organization.pricingPlanId`.
   */
  pricingPlan: OmitParentInputs<pricingPlansParentInputs<[...TPath, "pricingPlan"]>, "organizations", [...TPath, "pricingPlan"]>;
};
type organizationsChildrenInputs<TPath extends string[]> = {
  /**
  * Relationship from table `Organization` to table `AuditLog` through the column `AuditLog.organizationId`.
  */
  auditLogs: OmitChildInputs<auditLogsChildInputs<[...TPath, "auditLogs"]>, "organization" | "organizationId">;
  /**
  * Relationship from table `Organization` to table `AwsConsumptionHistory` through the column `AwsConsumptionHistory.organizationId`.
  */
  awsConsumptionHistories: OmitChildInputs<awsConsumptionHistoriesChildInputs<[...TPath, "awsConsumptionHistories"]>, "organization" | "organizationId">;
  /**
  * Relationship from table `Organization` to table `DbConnection` through the column `DbConnection.organizationId`.
  */
  dbConnections: OmitChildInputs<dbConnectionsChildInputs<[...TPath, "dbConnections"]>, "organization" | "organizationId">;
  /**
  * Relationship from table `Organization` to table `InviteToken` through the column `InviteToken.organizationId`.
  */
  inviteTokens: OmitChildInputs<inviteTokensChildInputs<[...TPath, "inviteTokens"]>, "organization" | "organizationId">;
  /**
  * Relationship from table `Organization` to table `Member` through the column `Member.organizationId`.
  */
  members: OmitChildInputs<membersChildInputs<[...TPath, "members"]>, "organization" | "organizationId">;
  /**
  * Relationship from table `Organization` to table `NeonConsumptionHistory` through the column `NeonConsumptionHistory.organizationId`.
  */
  neonConsumptionHistories: OmitChildInputs<neonConsumptionHistoriesChildInputs<[...TPath, "neonConsumptionHistories"]>, "organization" | "organizationId">;
  /**
  * Relationship from table `Organization` to table `Project` through the column `Project.organizationId`.
  */
  projects: OmitChildInputs<projectsChildInputs<[...TPath, "projects"]>, "organization" | "organizationId">;
  /**
  * Relationship from table `Organization` to table `Snapshot` through the column `Snapshot.organizationId`.
  */
  snapshots: OmitChildInputs<snapshotsChildInputs<[...TPath, "snapshots"]>, "organization" | "organizationId">;
  /**
  * Relationship from table `Organization` to table `Table` through the column `Table.organizationId`.
  */
  tables: OmitChildInputs<tablesChildInputs<[...TPath, "tables"]>, "organization" | "organizationId">;
};
type organizationsInputs<TPath extends string[]> = Inputs<
  organizationsScalars,
  organizationsParentsInputs<TPath>,
  organizationsChildrenInputs<TPath>
>;
type organizationsChildInputs<TPath extends string[]> = ChildInputs<organizationsInputs<TPath>>;
type organizationsParentInputs<TPath extends string[]> = ParentInputs<
organizationsInputs<TPath>,
  TPath
>;
type predictionDataSetsScalars = {
  /**
   * Column `PredictionDataSet.id`.
   */
  id: string;
  /**
   * Column `PredictionDataSet.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `PredictionDataSet.updatedAt`.
   */
  updatedAt: string;
  /**
   * Column `PredictionDataSet.input`.
   */
  input: string;
  /**
   * Column `PredictionDataSet.context`.
   */
  context: string;
  /**
   * Column `PredictionDataSet.shape`.
   */
  shape: string;
  /**
   * Column `PredictionDataSet.contextSkipTraining`.
   */
  contextSkipTraining?: boolean;
  /**
   * Column `PredictionDataSet.shapeSkipTraining`.
   */
  shapeSkipTraining?: boolean;
}
type predictionDataSetsParentsInputs<TPath extends string[]> = {

};
type predictionDataSetsChildrenInputs<TPath extends string[]> = {

};
type predictionDataSetsInputs<TPath extends string[]> = Inputs<
  predictionDataSetsScalars,
  predictionDataSetsParentsInputs<TPath>,
  predictionDataSetsChildrenInputs<TPath>
>;
type predictionDataSetsChildInputs<TPath extends string[]> = ChildInputs<predictionDataSetsInputs<TPath>>;
type predictionDataSetsParentInputs<TPath extends string[]> = ParentInputs<
predictionDataSetsInputs<TPath>,
  TPath
>;
type predictionJobsScalars = {
  /**
   * Column `PredictionJob.id`.
   */
  id: string;
  /**
   * Column `PredictionJob.engine`.
   */
  engine?: PredictionsEngineEnum;
  /**
   * Column `PredictionJob.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `PredictionJob.updatedAt`.
   */
  updatedAt: string;
  /**
   * Column `PredictionJob.endedAt`.
   */
  endedAt: string | null;
  /**
   * Column `PredictionJob.rawInput`.
   */
  rawInput: Json;
  /**
   * Column `PredictionJob.engineInput`.
   */
  engineInput: Json;
  /**
   * Column `PredictionJob.progress`.
   */
  progress: Json;
  /**
   * Column `PredictionJob.engineOptions`.
   */
  engineOptions: Json | null;
}
type predictionJobsParentsInputs<TPath extends string[]> = {

};
type predictionJobsChildrenInputs<TPath extends string[]> = {
  /**
  * Relationship from table `PredictionJob` to table `Project` through the column `Project.predictionJobId`.
  */
  projects: OmitChildInputs<projectsChildInputs<[...TPath, "projects"]>, "predictionJob" | "predictionJobId">;
};
type predictionJobsInputs<TPath extends string[]> = Inputs<
  predictionJobsScalars,
  predictionJobsParentsInputs<TPath>,
  predictionJobsChildrenInputs<TPath>
>;
type predictionJobsChildInputs<TPath extends string[]> = ChildInputs<predictionJobsInputs<TPath>>;
type predictionJobsParentInputs<TPath extends string[]> = ParentInputs<
predictionJobsInputs<TPath>,
  TPath
>;
type previewDatabasesScalars = {
  /**
   * Column `PreviewDatabase.id`.
   */
  id: string;
  /**
   * Column `PreviewDatabase.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `PreviewDatabase.updatedAt`.
   */
  updatedAt: string;
  /**
   * Column `PreviewDatabase.name`.
   */
  name: string;
  /**
   * Column `PreviewDatabase.neonBranchId`.
   */
  neonBranchId: string;
  /**
   * Column `PreviewDatabase.neonProjectId`.
   */
  neonProjectId: string;
  /**
   * Column `PreviewDatabase.connectionUrlHash`.
   */
  connectionUrlHash: Json;
}
type previewDatabasesParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `PreviewDatabase` to table `NeonProject` through the column `PreviewDatabase.neonProjectId`.
   */
  neonProject: OmitParentInputs<neonProjectsParentInputs<[...TPath, "neonProject"]>, "previewDatabases", [...TPath, "neonProject"]>;
};
type previewDatabasesChildrenInputs<TPath extends string[]> = {

};
type previewDatabasesInputs<TPath extends string[]> = Inputs<
  previewDatabasesScalars,
  previewDatabasesParentsInputs<TPath>,
  previewDatabasesChildrenInputs<TPath>
>;
type previewDatabasesChildInputs<TPath extends string[]> = ChildInputs<previewDatabasesInputs<TPath>>;
type previewDatabasesParentInputs<TPath extends string[]> = ParentInputs<
previewDatabasesInputs<TPath>,
  TPath
>;
type pricingPlansScalars = {
  /**
   * Column `PricingPlan.id`.
   */
  id?: number;
  /**
   * Column `PricingPlan.name`.
   */
  name: string;
  /**
   * Column `PricingPlan.amount`.
   */
  amount: string;
  /**
   * Column `PricingPlan.isDefault`.
   */
  isDefault: boolean;
  /**
   * Column `PricingPlan.storageLimit`.
   */
  storageLimit: number;
  /**
   * Column `PricingPlan.processLimit`.
   */
  processLimit: number;
  /**
   * Column `PricingPlan.restoreLimit`.
   */
  restoreLimit: number;
  /**
   * Column `PricingPlan.productId`.
   */
  productId: string;
}
type pricingPlansParentsInputs<TPath extends string[]> = {

};
type pricingPlansChildrenInputs<TPath extends string[]> = {
  /**
  * Relationship from table `PricingPlan` to table `Organization` through the column `Organization.pricingPlanId`.
  */
  organizations: OmitChildInputs<organizationsChildInputs<[...TPath, "organizations"]>, "pricingPlan" | "pricingPlanId">;
};
type pricingPlansInputs<TPath extends string[]> = Inputs<
  pricingPlansScalars,
  pricingPlansParentsInputs<TPath>,
  pricingPlansChildrenInputs<TPath>
>;
type pricingPlansChildInputs<TPath extends string[]> = ChildInputs<pricingPlansInputs<TPath>>;
type pricingPlansParentInputs<TPath extends string[]> = ParentInputs<
pricingPlansInputs<TPath>,
  TPath
>;
type projectsScalars = {
  /**
   * Column `Project.name`.
   */
  name: string;
  /**
   * Column `Project.organizationId`.
   */
  organizationId: string;
  /**
   * Column `Project.dbConnectionId`.
   */
  dbConnectionId: string | null;
  /**
   * Column `Project.id`.
   */
  id: string;
  /**
   * Column `Project.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `Project.updatedAt`.
   */
  updatedAt: string;
  /**
   * Column `Project.dbInfo`.
   */
  dbInfo: Json | null;
  /**
   * Column `Project.dbInfoLastUpdate`.
   */
  dbInfoLastUpdate: string | null;
  /**
   * Column `Project.deleted`.
   */
  deleted?: boolean;
  /**
   * Column `Project.autoDeleteDays`.
   */
  autoDeleteDays: number | null;
  /**
   * Column `Project.snapshotConfig`.
   */
  snapshotConfig: Json | null;
  /**
   * Column `Project.schedule`.
   */
  schedule: Json | null;
  /**
   * Column `Project.runTaskOptions`.
   */
  runTaskOptions: Json | null;
  /**
   * Column `Project.hostedDbUrlId`.
   */
  hostedDbUrlId: string | null;
  /**
   * Column `Project.hostedDbRegion`.
   */
  hostedDbRegion: string | null;
  /**
   * Column `Project.scheduleTags`.
   */
  scheduleTags: string[] | null;
  /**
   * Column `Project.previewDatabaseRegion`.
   */
  previewDatabaseRegion: string | null;
  /**
   * Column `Project.predictionJobId`.
   */
  predictionJobId: string | null;
  /**
   * Column `Project.supabaseProjectId`.
   */
  supabaseProjectId: string | null;
  /**
   * Column `Project.preseedPreviewDatabases`.
   */
  preseedPreviewDatabases?: boolean;
}
type projectsParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `Project` to table `DbConnection` through the column `Project.dbConnectionId`.
   */
  dbConnection: OmitParentInputs<dbConnectionsParentInputs<[...TPath, "dbConnection"]>, "projects", [...TPath, "dbConnection"]>;
  /**
   * Relationship from table `Project` to table `DbConnection` through the column `Project.hostedDbUrlId`.
   */
  hostedDbUrl: OmitParentInputs<dbConnectionsParentInputs<[...TPath, "hostedDbUrl"]>, "projectsByHostedDbUrlId", [...TPath, "hostedDbUrl"]>;
  /**
   * Relationship from table `Project` to table `Organization` through the column `Project.organizationId`.
   */
  organization: OmitParentInputs<organizationsParentInputs<[...TPath, "organization"]>, "projects", [...TPath, "organization"]>;
  /**
   * Relationship from table `Project` to table `PredictionJob` through the column `Project.predictionJobId`.
   */
  predictionJob: OmitParentInputs<predictionJobsParentInputs<[...TPath, "predictionJob"]>, "projects", [...TPath, "predictionJob"]>;
  /**
   * Relationship from table `Project` to table `SupabaseProject` through the column `Project.supabaseProjectId`.
   */
  supabaseProject: OmitParentInputs<supabaseProjectsParentInputs<[...TPath, "supabaseProject"]>, "projects", [...TPath, "supabaseProject"]>;
};
type projectsChildrenInputs<TPath extends string[]> = {
  /**
  * Relationship from table `Project` to table `AuditLog` through the column `AuditLog.projectId`.
  */
  auditLogs: OmitChildInputs<auditLogsChildInputs<[...TPath, "auditLogs"]>, "project" | "projectId">;
  /**
  * Relationship from table `Project` to table `AwsConsumptionHistory` through the column `AwsConsumptionHistory.projectId`.
  */
  awsConsumptionHistories: OmitChildInputs<awsConsumptionHistoriesChildInputs<[...TPath, "awsConsumptionHistories"]>, "project" | "projectId">;
  /**
  * Relationship from table `Project` to table `ExecTask` through the column `ExecTask.projectId`.
  */
  execTasks: OmitChildInputs<execTasksChildInputs<[...TPath, "execTasks"]>, "project" | "projectId">;
  /**
  * Relationship from table `Project` to table `NeonConsumptionHistory` through the column `NeonConsumptionHistory.projectId`.
  */
  neonConsumptionHistories: OmitChildInputs<neonConsumptionHistoriesChildInputs<[...TPath, "neonConsumptionHistories"]>, "project" | "projectId">;
  /**
  * Relationship from table `Project` to table `NeonProject` through the column `NeonProject.projectId`.
  */
  neonProjects: OmitChildInputs<neonProjectsChildInputs<[...TPath, "neonProjects"]>, "project" | "projectId">;
  /**
  * Relationship from table `Project` to table `ShapePredictionOverride` through the column `ShapePredictionOverride.projectId`.
  */
  shapePredictionOverrides: OmitChildInputs<shapePredictionOverridesChildInputs<[...TPath, "shapePredictionOverrides"]>, "project" | "projectId">;
  /**
  * Relationship from table `Project` to table `Snapshot` through the column `Snapshot.projectId`.
  */
  snapshots: OmitChildInputs<snapshotsChildInputs<[...TPath, "snapshots"]>, "project" | "projectId">;
};
type projectsInputs<TPath extends string[]> = Inputs<
  projectsScalars,
  projectsParentsInputs<TPath>,
  projectsChildrenInputs<TPath>
>;
type projectsChildInputs<TPath extends string[]> = ChildInputs<projectsInputs<TPath>>;
type projectsParentInputs<TPath extends string[]> = ParentInputs<
projectsInputs<TPath>,
  TPath
>;
type releaseVersionsScalars = {
  /**
   * Column `ReleaseVersion.version`.
   */
  version: string;
  /**
   * Column `ReleaseVersion.channel`.
   */
  channel?: ReleaseChannelEnum;
  /**
   * Column `ReleaseVersion.forceUpgrade`.
   */
  forceUpgrade?: boolean;
  /**
   * Column `ReleaseVersion.releaseDate`.
   */
  releaseDate?: string;
  /**
   * Column `ReleaseVersion.userId`.
   */
  userId: string | null;
}
type releaseVersionsParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `ReleaseVersion` to table `User` through the column `ReleaseVersion.userId`.
   */
  user: OmitParentInputs<usersParentInputs<[...TPath, "user"]>, "releaseVersions", [...TPath, "user"]>;
};
type releaseVersionsChildrenInputs<TPath extends string[]> = {

};
type releaseVersionsInputs<TPath extends string[]> = Inputs<
  releaseVersionsScalars,
  releaseVersionsParentsInputs<TPath>,
  releaseVersionsChildrenInputs<TPath>
>;
type releaseVersionsChildInputs<TPath extends string[]> = ChildInputs<releaseVersionsInputs<TPath>>;
type releaseVersionsParentInputs<TPath extends string[]> = ParentInputs<
releaseVersionsInputs<TPath>,
  TPath
>;
type shapePredictionOverridesScalars = {
  /**
   * Column `ShapePredictionOverride.id`.
   */
  id: string;
  /**
   * Column `ShapePredictionOverride.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `ShapePredictionOverride.updatedAt`.
   */
  updatedAt: string;
  /**
   * Column `ShapePredictionOverride.input`.
   */
  input: string;
  /**
   * Column `ShapePredictionOverride.shape`.
   */
  shape: string;
  /**
   * Column `ShapePredictionOverride.context`.
   */
  context: string;
  /**
   * Column `ShapePredictionOverride.projectId`.
   */
  projectId: string;
}
type shapePredictionOverridesParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `ShapePredictionOverride` to table `Project` through the column `ShapePredictionOverride.projectId`.
   */
  project: OmitParentInputs<projectsParentInputs<[...TPath, "project"]>, "shapePredictionOverrides", [...TPath, "project"]>;
};
type shapePredictionOverridesChildrenInputs<TPath extends string[]> = {

};
type shapePredictionOverridesInputs<TPath extends string[]> = Inputs<
  shapePredictionOverridesScalars,
  shapePredictionOverridesParentsInputs<TPath>,
  shapePredictionOverridesChildrenInputs<TPath>
>;
type shapePredictionOverridesChildInputs<TPath extends string[]> = ChildInputs<shapePredictionOverridesInputs<TPath>>;
type shapePredictionOverridesParentInputs<TPath extends string[]> = ParentInputs<
shapePredictionOverridesInputs<TPath>,
  TPath
>;
type shapePredictionStoresScalars = {
  /**
   * Column `ShapePredictionStore.id`.
   */
  id: string;
  /**
   * Column `ShapePredictionStore.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `ShapePredictionStore.updatedAt`.
   */
  updatedAt: string;
  /**
   * Column `ShapePredictionStore.input`.
   */
  input: string;
  /**
   * Column `ShapePredictionStore.predictedLabel`.
   */
  predictedLabel: string;
  /**
   * Column `ShapePredictionStore.confidence`.
   */
  confidence: number | null;
  /**
   * Column `ShapePredictionStore.overrideLabel`.
   */
  overrideLabel: string | null;
  /**
   * Column `ShapePredictionStore.confidenceContext`.
   */
  confidenceContext: number | null;
  /**
   * Column `ShapePredictionStore.overrideContext`.
   */
  overrideContext: string | null;
  /**
   * Column `ShapePredictionStore.predictedContext`.
   */
  predictedContext?: string;
  /**
   * Column `ShapePredictionStore.engine`.
   */
  engine?: PredictionsEngineEnum;
}
type shapePredictionStoresParentsInputs<TPath extends string[]> = {

};
type shapePredictionStoresChildrenInputs<TPath extends string[]> = {

};
type shapePredictionStoresInputs<TPath extends string[]> = Inputs<
  shapePredictionStoresScalars,
  shapePredictionStoresParentsInputs<TPath>,
  shapePredictionStoresChildrenInputs<TPath>
>;
type shapePredictionStoresChildInputs<TPath extends string[]> = ChildInputs<shapePredictionStoresInputs<TPath>>;
type shapePredictionStoresParentInputs<TPath extends string[]> = ParentInputs<
shapePredictionStoresInputs<TPath>,
  TPath
>;
type snapshotsScalars = {
  /**
   * Column `Snapshot.id`.
   */
  id: string;
  /**
   * Column `Snapshot.uniqueName`.
   */
  uniqueName: string;
  /**
   * Column `Snapshot.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `Snapshot.updatedAt`.
   */
  updatedAt: string;
  /**
   * Column `Snapshot.statusOld`.
   */
  statusOld?: SnapshotStatusEnum;
  /**
   * Column `Snapshot.organizationId`.
   */
  organizationId: string;
  /**
   * Column `Snapshot.dbConnectionId`.
   */
  dbConnectionId: string | null;
  /**
   * Column `Snapshot.workerIpAddress`.
   */
  workerIpAddress: string | null;
  /**
   * Column `Snapshot.errors`.
   */
  errors: string[] | null;
  /**
   * Column `Snapshot.failureCount`.
   */
  failureCount?: number;
  /**
   * Column `Snapshot.projectId`.
   */
  projectId: string;
  /**
   * Column `Snapshot.dbSchemaDump`.
   */
  dbSchemaDump: string | null;
  /**
   * Column `Snapshot.logs`.
   */
  logs: string[] | null;
  /**
   * Column `Snapshot.restoreCount`.
   */
  restoreCount?: number;
  /**
   * Column `Snapshot.dbInfo`.
   */
  dbInfo: Json | null;
  /**
   * Column `Snapshot.snapshotConfig`.
   */
  snapshotConfig: Json | null;
  /**
   * Column `Snapshot.runtime`.
   */
  runtime: Json | null;
  /**
   * Column `Snapshot.summary`.
   */
  summary: Json | null;
  /**
   * Column `Snapshot.createdByUserId`.
   */
  createdByUserId: string | null;
  /**
   * Column `Snapshot.execTaskId`.
   */
  execTaskId: string | null;
  /**
   * Column `Snapshot.progress`.
   */
  progress: Json | null;
  /**
   * Column `Snapshot.notifyOnSuccess`.
   */
  notifyOnSuccess: boolean | null;
  /**
   * Column `Snapshot.deletedAt`.
   */
  deletedAt: string | null;
  /**
   * Column `Snapshot.purgedAt`.
   */
  purgedAt: string | null;
  /**
   * Column `Snapshot.storage`.
   */
  storage: Json | null;
  /**
   * Column `Snapshot.isScheduled`.
   */
  isScheduled: boolean | null;
  /**
   * Column `Snapshot.preseedPreviewDatabase`.
   */
  preseedPreviewDatabase?: boolean;
}
type snapshotsParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `Snapshot` to table `DbConnection` through the column `Snapshot.dbConnectionId`.
   */
  dbConnection: OmitParentInputs<dbConnectionsParentInputs<[...TPath, "dbConnection"]>, "snapshots", [...TPath, "dbConnection"]>;
  /**
   * Relationship from table `Snapshot` to table `ExecTask` through the column `Snapshot.execTaskId`.
   */
  execTask: OmitParentInputs<execTasksParentInputs<[...TPath, "execTask"]>, "snapshots", [...TPath, "execTask"]>;
  /**
   * Relationship from table `Snapshot` to table `Organization` through the column `Snapshot.organizationId`.
   */
  organization: OmitParentInputs<organizationsParentInputs<[...TPath, "organization"]>, "snapshots", [...TPath, "organization"]>;
  /**
   * Relationship from table `Snapshot` to table `Project` through the column `Snapshot.projectId`.
   */
  project: OmitParentInputs<projectsParentInputs<[...TPath, "project"]>, "snapshots", [...TPath, "project"]>;
  /**
   * Relationship from table `Snapshot` to table `User` through the column `Snapshot.createdByUserId`.
   */
  createdByUser: OmitParentInputs<usersParentInputs<[...TPath, "createdByUser"]>, "snapshotsByCreatedByUserId", [...TPath, "createdByUser"]>;
};
type snapshotsChildrenInputs<TPath extends string[]> = {
  /**
  * Relationship from table `Snapshot` to table `AwsConsumptionHistory` through the column `AwsConsumptionHistory.snapshotId`.
  */
  awsConsumptionHistories: OmitChildInputs<awsConsumptionHistoriesChildInputs<[...TPath, "awsConsumptionHistories"]>, "snapshot" | "snapshotId">;
  /**
  * Relationship from table `Snapshot` to table `NeonConsumptionHistory` through the column `NeonConsumptionHistory.snapshotId`.
  */
  neonConsumptionHistories: OmitChildInputs<neonConsumptionHistoriesChildInputs<[...TPath, "neonConsumptionHistories"]>, "snapshot" | "snapshotId">;
  /**
  * Relationship from table `Snapshot` to table `NeonProject` through the column `NeonProject.snapshotId`.
  */
  neonProjects: OmitChildInputs<neonProjectsChildInputs<[...TPath, "neonProjects"]>, "snapshot" | "snapshotId">;
  /**
  * Relationship from table `Snapshot` to table `Table` through the column `Table.snapshotId`.
  */
  tables: OmitChildInputs<tablesChildInputs<[...TPath, "tables"]>, "snapshot" | "snapshotId">;
};
type snapshotsInputs<TPath extends string[]> = Inputs<
  snapshotsScalars,
  snapshotsParentsInputs<TPath>,
  snapshotsChildrenInputs<TPath>
>;
type snapshotsChildInputs<TPath extends string[]> = ChildInputs<snapshotsInputs<TPath>>;
type snapshotsParentInputs<TPath extends string[]> = ParentInputs<
snapshotsInputs<TPath>,
  TPath
>;
type supabaseProjectsScalars = {
  /**
   * Column `SupabaseProject.id`.
   */
  id: string;
  /**
   * Column `SupabaseProject.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `SupabaseProject.updatedAt`.
   */
  updatedAt?: string;
  /**
   * Column `SupabaseProject.projectId`.
   */
  projectId: string;
  /**
   * Column `SupabaseProject.supabaseAuthCodeHash`.
   */
  supabaseAuthCodeHash: Json;
  /**
   * Column `SupabaseProject.supabaseRefreshToken`.
   */
  supabaseRefreshToken: string | null;
  /**
   * Column `SupabaseProject.supabaseAccessTokenHash`.
   */
  supabaseAccessTokenHash: Json | null;
  /**
   * Column `SupabaseProject.supabaseAccessTokenExpiresAt`.
   */
  supabaseAccessTokenExpiresAt: string | null;
}
type supabaseProjectsParentsInputs<TPath extends string[]> = {

};
type supabaseProjectsChildrenInputs<TPath extends string[]> = {
  /**
  * Relationship from table `SupabaseProject` to table `Project` through the column `Project.supabaseProjectId`.
  */
  projects: OmitChildInputs<projectsChildInputs<[...TPath, "projects"]>, "supabaseProject" | "supabaseProjectId">;
};
type supabaseProjectsInputs<TPath extends string[]> = Inputs<
  supabaseProjectsScalars,
  supabaseProjectsParentsInputs<TPath>,
  supabaseProjectsChildrenInputs<TPath>
>;
type supabaseProjectsChildInputs<TPath extends string[]> = ChildInputs<supabaseProjectsInputs<TPath>>;
type supabaseProjectsParentInputs<TPath extends string[]> = ParentInputs<
supabaseProjectsInputs<TPath>,
  TPath
>;
type tablesScalars = {
  /**
   * Column `Table.id`.
   */
  id: string;
  /**
   * Column `Table.tableName`.
   */
  tableName: string;
  /**
   * Column `Table.status`.
   */
  status?: SnapshotStatusEnum;
  /**
   * Column `Table.bucketKey`.
   */
  bucketKey: string | null;
  /**
   * Column `Table.bytes`.
   */
  bytes: string | null;
  /**
   * Column `Table.timeToDump`.
   */
  timeToDump: number | null;
  /**
   * Column `Table.timeToSave`.
   */
  timeToSave: number | null;
  /**
   * Column `Table.snapshotId`.
   */
  snapshotId: string;
  /**
   * Column `Table.organizationId`.
   */
  organizationId: string;
  /**
   * Column `Table.checksum`.
   */
  checksum: string | null;
  /**
   * Column `Table.timeToCompress`.
   */
  timeToCompress: number | null;
  /**
   * Column `Table.timeToEncrypt`.
   */
  timeToEncrypt: number | null;
  /**
   * Column `Table.rows`.
   */
  rows: string | null;
  /**
   * Column `Table.schema`.
   */
  schema: string;
  /**
   * Column `Table.totalRows`.
   */
  totalRows: string | null;
}
type tablesParentsInputs<TPath extends string[]> = {
  /**
   * Relationship from table `Table` to table `Organization` through the column `Table.organizationId`.
   */
  organization: OmitParentInputs<organizationsParentInputs<[...TPath, "organization"]>, "tables", [...TPath, "organization"]>;
  /**
   * Relationship from table `Table` to table `Snapshot` through the column `Table.snapshotId`.
   */
  snapshot: OmitParentInputs<snapshotsParentInputs<[...TPath, "snapshot"]>, "tables", [...TPath, "snapshot"]>;
};
type tablesChildrenInputs<TPath extends string[]> = {

};
type tablesInputs<TPath extends string[]> = Inputs<
  tablesScalars,
  tablesParentsInputs<TPath>,
  tablesChildrenInputs<TPath>
>;
type tablesChildInputs<TPath extends string[]> = ChildInputs<tablesInputs<TPath>>;
type tablesParentInputs<TPath extends string[]> = ParentInputs<
tablesInputs<TPath>,
  TPath
>;
type usersScalars = {
  /**
   * Column `User.id`.
   */
  id: string;
  /**
   * Column `User.sub`.
   */
  sub: string;
  /**
   * Column `User.email`.
   */
  email: string;
  /**
   * Column `User.createdAt`.
   */
  createdAt?: string;
  /**
   * Column `User.updatedAt`.
   */
  updatedAt: string;
  /**
   * Column `User.role`.
   */
  role?: UserRoleEnum;
  /**
   * Column `User.notifications`.
   */
  notifications?: UserNotificationsEnum;
}
type usersParentsInputs<TPath extends string[]> = {

};
type usersChildrenInputs<TPath extends string[]> = {
  /**
  * Relationship from table `User` to table `AccessToken` through the column `AccessToken.userId`.
  */
  accessTokens: OmitChildInputs<accessTokensChildInputs<[...TPath, "accessTokens"]>, "user" | "userId">;
  /**
  * Relationship from table `User` to table `AuditLog` through the column `AuditLog.userId`.
  */
  auditLogs: OmitChildInputs<auditLogsChildInputs<[...TPath, "auditLogs"]>, "user" | "userId">;
  /**
  * Relationship from table `User` to table `InviteToken` through the column `InviteToken.createdByUserId`.
  */
  inviteTokensByCreatedByUserId: OmitChildInputs<inviteTokensChildInputs<[...TPath, "inviteTokensByCreatedByUserId"]>, "createdByUser" | "createdByUserId">;
  /**
  * Relationship from table `User` to table `Member` through the column `Member.userId`.
  */
  members: OmitChildInputs<membersChildInputs<[...TPath, "members"]>, "user" | "userId">;
  /**
  * Relationship from table `User` to table `ReleaseVersion` through the column `ReleaseVersion.userId`.
  */
  releaseVersions: OmitChildInputs<releaseVersionsChildInputs<[...TPath, "releaseVersions"]>, "user" | "userId">;
  /**
  * Relationship from table `User` to table `Snapshot` through the column `Snapshot.createdByUserId`.
  */
  snapshotsByCreatedByUserId: OmitChildInputs<snapshotsChildInputs<[...TPath, "snapshotsByCreatedByUserId"]>, "createdByUser" | "createdByUserId">;
};
type usersInputs<TPath extends string[]> = Inputs<
  usersScalars,
  usersParentsInputs<TPath>,
  usersChildrenInputs<TPath>
>;
type usersChildInputs<TPath extends string[]> = ChildInputs<usersInputs<TPath>>;
type usersParentInputs<TPath extends string[]> = ParentInputs<
usersInputs<TPath>,
  TPath
>;
type PrismaMigrationsScalars = {
  /**
   * Column `_prisma_migrations.id`.
   */
  id: string;
  /**
   * Column `_prisma_migrations.checksum`.
   */
  checksum: string;
  /**
   * Column `_prisma_migrations.finished_at`.
   */
  finishedAt: string | null;
  /**
   * Column `_prisma_migrations.migration_name`.
   */
  migrationName: string;
  /**
   * Column `_prisma_migrations.logs`.
   */
  logs: string | null;
  /**
   * Column `_prisma_migrations.rolled_back_at`.
   */
  rolledBackAt: string | null;
  /**
   * Column `_prisma_migrations.started_at`.
   */
  startedAt?: string;
  /**
   * Column `_prisma_migrations.applied_steps_count`.
   */
  appliedStepsCount?: number;
}
type PrismaMigrationsParentsInputs<TPath extends string[]> = {

};
type PrismaMigrationsChildrenInputs<TPath extends string[]> = {

};
type PrismaMigrationsInputs<TPath extends string[]> = Inputs<
  PrismaMigrationsScalars,
  PrismaMigrationsParentsInputs<TPath>,
  PrismaMigrationsChildrenInputs<TPath>
>;
type PrismaMigrationsChildInputs<TPath extends string[]> = ChildInputs<PrismaMigrationsInputs<TPath>>;
type PrismaMigrationsParentInputs<TPath extends string[]> = ParentInputs<
PrismaMigrationsInputs<TPath>,
  TPath
>;
type jobsScalars = {
  /**
   * Column `job.id`.
   */
  id?: string;
  /**
   * Column `job.name`.
   */
  name: string;
  /**
   * Column `job.priority`.
   */
  priority?: number;
  /**
   * Column `job.data`.
   */
  data: Json | null;
  /**
   * Column `job.state`.
   */
  state?: job_stateEnum;
  /**
   * Column `job.retrylimit`.
   */
  retrylimit?: number;
  /**
   * Column `job.retrycount`.
   */
  retrycount?: number;
  /**
   * Column `job.retrydelay`.
   */
  retrydelay?: number;
  /**
   * Column `job.retrybackoff`.
   */
  retrybackoff?: boolean;
  /**
   * Column `job.startafter`.
   */
  startafter?: string;
  /**
   * Column `job.startedon`.
   */
  startedon: string | null;
  /**
   * Column `job.singletonkey`.
   */
  singletonkey: string | null;
  /**
   * Column `job.singletonon`.
   */
  singletonon: string | null;
  /**
   * Column `job.expirein`.
   */
  expirein?: string;
  /**
   * Column `job.createdon`.
   */
  createdon?: string;
  /**
   * Column `job.completedon`.
   */
  completedon: string | null;
  /**
   * Column `job.keepuntil`.
   */
  keepuntil?: string;
  /**
   * Column `job.on_complete`.
   */
  onComplete?: boolean;
  /**
   * Column `job.output`.
   */
  output: Json | null;
}
type jobsParentsInputs<TPath extends string[]> = {

};
type jobsChildrenInputs<TPath extends string[]> = {

};
type jobsInputs<TPath extends string[]> = Inputs<
  jobsScalars,
  jobsParentsInputs<TPath>,
  jobsChildrenInputs<TPath>
>;
type jobsChildInputs<TPath extends string[]> = ChildInputs<jobsInputs<TPath>>;
type jobsParentInputs<TPath extends string[]> = ParentInputs<
jobsInputs<TPath>,
  TPath
>;
type schedulesScalars = {
  /**
   * Column `schedule.name`.
   */
  name: string;
  /**
   * Column `schedule.cron`.
   */
  cron: string;
  /**
   * Column `schedule.timezone`.
   */
  timezone: string | null;
  /**
   * Column `schedule.data`.
   */
  data: Json | null;
  /**
   * Column `schedule.options`.
   */
  options: Json | null;
  /**
   * Column `schedule.created_on`.
   */
  createdOn?: string;
  /**
   * Column `schedule.updated_on`.
   */
  updatedOn?: string;
}
type schedulesParentsInputs<TPath extends string[]> = {

};
type schedulesChildrenInputs<TPath extends string[]> = {

};
type schedulesInputs<TPath extends string[]> = Inputs<
  schedulesScalars,
  schedulesParentsInputs<TPath>,
  schedulesChildrenInputs<TPath>
>;
type schedulesChildInputs<TPath extends string[]> = ChildInputs<schedulesInputs<TPath>>;
type schedulesParentInputs<TPath extends string[]> = ParentInputs<
schedulesInputs<TPath>,
  TPath
>;
type versionsScalars = {
  /**
   * Column `version.version`.
   */
  version: number;
  /**
   * Column `version.maintained_on`.
   */
  maintainedOn: string | null;
  /**
   * Column `version.cron_on`.
   */
  cronOn: string | null;
}
type versionsParentsInputs<TPath extends string[]> = {

};
type versionsChildrenInputs<TPath extends string[]> = {

};
type versionsInputs<TPath extends string[]> = Inputs<
  versionsScalars,
  versionsParentsInputs<TPath>,
  versionsChildrenInputs<TPath>
>;
type versionsChildInputs<TPath extends string[]> = ChildInputs<versionsInputs<TPath>>;
type versionsParentInputs<TPath extends string[]> = ParentInputs<
versionsInputs<TPath>,
  TPath
>;
type accessTokensParentsGraph = {
 user: OmitChildGraph<usersGraph, "accessTokens">;
};
type accessTokensChildrenGraph = {
 execTasks: OmitParentGraph<execTasksGraph, "accessToken">;
};
type accessTokensGraph = Array<{
  Scalars: accessTokensScalars;
  Parents: accessTokensParentsGraph;
  Children: accessTokensChildrenGraph;
}>;
type auditLogsParentsGraph = {
 organization: OmitChildGraph<organizationsGraph, "auditLogs">;
 project: OmitChildGraph<projectsGraph, "auditLogs">;
 user: OmitChildGraph<usersGraph, "auditLogs">;
};
type auditLogsChildrenGraph = {

};
type auditLogsGraph = Array<{
  Scalars: auditLogsScalars;
  Parents: auditLogsParentsGraph;
  Children: auditLogsChildrenGraph;
}>;
type awsConsumptionHistoriesParentsGraph = {
 organization: OmitChildGraph<organizationsGraph, "awsConsumptionHistories">;
 project: OmitChildGraph<projectsGraph, "awsConsumptionHistories">;
 snapshot: OmitChildGraph<snapshotsGraph, "awsConsumptionHistories">;
};
type awsConsumptionHistoriesChildrenGraph = {

};
type awsConsumptionHistoriesGraph = Array<{
  Scalars: awsConsumptionHistoriesScalars;
  Parents: awsConsumptionHistoriesParentsGraph;
  Children: awsConsumptionHistoriesChildrenGraph;
}>;
type databaseProvidersParentsGraph = {

};
type databaseProvidersChildrenGraph = {
 dbConnections: OmitParentGraph<dbConnectionsGraph, "databaseProvider">;
};
type databaseProvidersGraph = Array<{
  Scalars: databaseProvidersScalars;
  Parents: databaseProvidersParentsGraph;
  Children: databaseProvidersChildrenGraph;
}>;
type dbConnectionsParentsGraph = {
 databaseProvider: OmitChildGraph<databaseProvidersGraph, "dbConnections">;
 organization: OmitChildGraph<organizationsGraph, "dbConnections">;
};
type dbConnectionsChildrenGraph = {
 projects: OmitParentGraph<projectsGraph, "dbConnection">;
 projectsByHostedDbUrlId: OmitParentGraph<projectsGraph, "hostedDbUrl">;
 snapshots: OmitParentGraph<snapshotsGraph, "dbConnection">;
};
type dbConnectionsGraph = Array<{
  Scalars: dbConnectionsScalars;
  Parents: dbConnectionsParentsGraph;
  Children: dbConnectionsChildrenGraph;
}>;
type execTasksParentsGraph = {
 accessToken: OmitChildGraph<accessTokensGraph, "execTasks">;
 project: OmitChildGraph<projectsGraph, "execTasks">;
};
type execTasksChildrenGraph = {
 snapshots: OmitParentGraph<snapshotsGraph, "execTask">;
};
type execTasksGraph = Array<{
  Scalars: execTasksScalars;
  Parents: execTasksParentsGraph;
  Children: execTasksChildrenGraph;
}>;
type inviteTokensParentsGraph = {
 usedByMember: OmitChildGraph<membersGraph, "inviteTokensByUsedByMemberId">;
 organization: OmitChildGraph<organizationsGraph, "inviteTokens">;
 createdByUser: OmitChildGraph<usersGraph, "inviteTokensByCreatedByUserId">;
};
type inviteTokensChildrenGraph = {

};
type inviteTokensGraph = Array<{
  Scalars: inviteTokensScalars;
  Parents: inviteTokensParentsGraph;
  Children: inviteTokensChildrenGraph;
}>;
type membersParentsGraph = {
 organization: OmitChildGraph<organizationsGraph, "members">;
 user: OmitChildGraph<usersGraph, "members">;
};
type membersChildrenGraph = {
 inviteTokensByUsedByMemberId: OmitParentGraph<inviteTokensGraph, "usedByMember">;
};
type membersGraph = Array<{
  Scalars: membersScalars;
  Parents: membersParentsGraph;
  Children: membersChildrenGraph;
}>;
type neonConsumptionHistoriesParentsGraph = {
 organization: OmitChildGraph<organizationsGraph, "neonConsumptionHistories">;
 project: OmitChildGraph<projectsGraph, "neonConsumptionHistories">;
 snapshot: OmitChildGraph<snapshotsGraph, "neonConsumptionHistories">;
};
type neonConsumptionHistoriesChildrenGraph = {

};
type neonConsumptionHistoriesGraph = Array<{
  Scalars: neonConsumptionHistoriesScalars;
  Parents: neonConsumptionHistoriesParentsGraph;
  Children: neonConsumptionHistoriesChildrenGraph;
}>;
type neonProjectsParentsGraph = {
 project: OmitChildGraph<projectsGraph, "neonProjects">;
 snapshot: OmitChildGraph<snapshotsGraph, "neonProjects">;
};
type neonProjectsChildrenGraph = {
 previewDatabases: OmitParentGraph<previewDatabasesGraph, "neonProject">;
};
type neonProjectsGraph = Array<{
  Scalars: neonProjectsScalars;
  Parents: neonProjectsParentsGraph;
  Children: neonProjectsChildrenGraph;
}>;
type organizationsParentsGraph = {
 pricingPlan: OmitChildGraph<pricingPlansGraph, "organizations">;
};
type organizationsChildrenGraph = {
 auditLogs: OmitParentGraph<auditLogsGraph, "organization">;
 awsConsumptionHistories: OmitParentGraph<awsConsumptionHistoriesGraph, "organization">;
 dbConnections: OmitParentGraph<dbConnectionsGraph, "organization">;
 inviteTokens: OmitParentGraph<inviteTokensGraph, "organization">;
 members: OmitParentGraph<membersGraph, "organization">;
 neonConsumptionHistories: OmitParentGraph<neonConsumptionHistoriesGraph, "organization">;
 projects: OmitParentGraph<projectsGraph, "organization">;
 snapshots: OmitParentGraph<snapshotsGraph, "organization">;
 tables: OmitParentGraph<tablesGraph, "organization">;
};
type organizationsGraph = Array<{
  Scalars: organizationsScalars;
  Parents: organizationsParentsGraph;
  Children: organizationsChildrenGraph;
}>;
type predictionDataSetsParentsGraph = {

};
type predictionDataSetsChildrenGraph = {

};
type predictionDataSetsGraph = Array<{
  Scalars: predictionDataSetsScalars;
  Parents: predictionDataSetsParentsGraph;
  Children: predictionDataSetsChildrenGraph;
}>;
type predictionJobsParentsGraph = {

};
type predictionJobsChildrenGraph = {
 projects: OmitParentGraph<projectsGraph, "predictionJob">;
};
type predictionJobsGraph = Array<{
  Scalars: predictionJobsScalars;
  Parents: predictionJobsParentsGraph;
  Children: predictionJobsChildrenGraph;
}>;
type previewDatabasesParentsGraph = {
 neonProject: OmitChildGraph<neonProjectsGraph, "previewDatabases">;
};
type previewDatabasesChildrenGraph = {

};
type previewDatabasesGraph = Array<{
  Scalars: previewDatabasesScalars;
  Parents: previewDatabasesParentsGraph;
  Children: previewDatabasesChildrenGraph;
}>;
type pricingPlansParentsGraph = {

};
type pricingPlansChildrenGraph = {
 organizations: OmitParentGraph<organizationsGraph, "pricingPlan">;
};
type pricingPlansGraph = Array<{
  Scalars: pricingPlansScalars;
  Parents: pricingPlansParentsGraph;
  Children: pricingPlansChildrenGraph;
}>;
type projectsParentsGraph = {
 dbConnection: OmitChildGraph<dbConnectionsGraph, "projects">;
 hostedDbUrl: OmitChildGraph<dbConnectionsGraph, "projectsByHostedDbUrlId">;
 organization: OmitChildGraph<organizationsGraph, "projects">;
 predictionJob: OmitChildGraph<predictionJobsGraph, "projects">;
 supabaseProject: OmitChildGraph<supabaseProjectsGraph, "projects">;
};
type projectsChildrenGraph = {
 auditLogs: OmitParentGraph<auditLogsGraph, "project">;
 awsConsumptionHistories: OmitParentGraph<awsConsumptionHistoriesGraph, "project">;
 execTasks: OmitParentGraph<execTasksGraph, "project">;
 neonConsumptionHistories: OmitParentGraph<neonConsumptionHistoriesGraph, "project">;
 neonProjects: OmitParentGraph<neonProjectsGraph, "project">;
 shapePredictionOverrides: OmitParentGraph<shapePredictionOverridesGraph, "project">;
 snapshots: OmitParentGraph<snapshotsGraph, "project">;
};
type projectsGraph = Array<{
  Scalars: projectsScalars;
  Parents: projectsParentsGraph;
  Children: projectsChildrenGraph;
}>;
type releaseVersionsParentsGraph = {
 user: OmitChildGraph<usersGraph, "releaseVersions">;
};
type releaseVersionsChildrenGraph = {

};
type releaseVersionsGraph = Array<{
  Scalars: releaseVersionsScalars;
  Parents: releaseVersionsParentsGraph;
  Children: releaseVersionsChildrenGraph;
}>;
type shapePredictionOverridesParentsGraph = {
 project: OmitChildGraph<projectsGraph, "shapePredictionOverrides">;
};
type shapePredictionOverridesChildrenGraph = {

};
type shapePredictionOverridesGraph = Array<{
  Scalars: shapePredictionOverridesScalars;
  Parents: shapePredictionOverridesParentsGraph;
  Children: shapePredictionOverridesChildrenGraph;
}>;
type shapePredictionStoresParentsGraph = {

};
type shapePredictionStoresChildrenGraph = {

};
type shapePredictionStoresGraph = Array<{
  Scalars: shapePredictionStoresScalars;
  Parents: shapePredictionStoresParentsGraph;
  Children: shapePredictionStoresChildrenGraph;
}>;
type snapshotsParentsGraph = {
 dbConnection: OmitChildGraph<dbConnectionsGraph, "snapshots">;
 execTask: OmitChildGraph<execTasksGraph, "snapshots">;
 organization: OmitChildGraph<organizationsGraph, "snapshots">;
 project: OmitChildGraph<projectsGraph, "snapshots">;
 createdByUser: OmitChildGraph<usersGraph, "snapshotsByCreatedByUserId">;
};
type snapshotsChildrenGraph = {
 awsConsumptionHistories: OmitParentGraph<awsConsumptionHistoriesGraph, "snapshot">;
 neonConsumptionHistories: OmitParentGraph<neonConsumptionHistoriesGraph, "snapshot">;
 neonProjects: OmitParentGraph<neonProjectsGraph, "snapshot">;
 tables: OmitParentGraph<tablesGraph, "snapshot">;
};
type snapshotsGraph = Array<{
  Scalars: snapshotsScalars;
  Parents: snapshotsParentsGraph;
  Children: snapshotsChildrenGraph;
}>;
type supabaseProjectsParentsGraph = {

};
type supabaseProjectsChildrenGraph = {
 projects: OmitParentGraph<projectsGraph, "supabaseProject">;
};
type supabaseProjectsGraph = Array<{
  Scalars: supabaseProjectsScalars;
  Parents: supabaseProjectsParentsGraph;
  Children: supabaseProjectsChildrenGraph;
}>;
type tablesParentsGraph = {
 organization: OmitChildGraph<organizationsGraph, "tables">;
 snapshot: OmitChildGraph<snapshotsGraph, "tables">;
};
type tablesChildrenGraph = {

};
type tablesGraph = Array<{
  Scalars: tablesScalars;
  Parents: tablesParentsGraph;
  Children: tablesChildrenGraph;
}>;
type usersParentsGraph = {

};
type usersChildrenGraph = {
 accessTokens: OmitParentGraph<accessTokensGraph, "user">;
 auditLogs: OmitParentGraph<auditLogsGraph, "user">;
 inviteTokensByCreatedByUserId: OmitParentGraph<inviteTokensGraph, "createdByUser">;
 members: OmitParentGraph<membersGraph, "user">;
 releaseVersions: OmitParentGraph<releaseVersionsGraph, "user">;
 snapshotsByCreatedByUserId: OmitParentGraph<snapshotsGraph, "createdByUser">;
};
type usersGraph = Array<{
  Scalars: usersScalars;
  Parents: usersParentsGraph;
  Children: usersChildrenGraph;
}>;
type PrismaMigrationsParentsGraph = {

};
type PrismaMigrationsChildrenGraph = {

};
type PrismaMigrationsGraph = Array<{
  Scalars: PrismaMigrationsScalars;
  Parents: PrismaMigrationsParentsGraph;
  Children: PrismaMigrationsChildrenGraph;
}>;
type jobsParentsGraph = {

};
type jobsChildrenGraph = {

};
type jobsGraph = Array<{
  Scalars: jobsScalars;
  Parents: jobsParentsGraph;
  Children: jobsChildrenGraph;
}>;
type schedulesParentsGraph = {

};
type schedulesChildrenGraph = {

};
type schedulesGraph = Array<{
  Scalars: schedulesScalars;
  Parents: schedulesParentsGraph;
  Children: schedulesChildrenGraph;
}>;
type versionsParentsGraph = {

};
type versionsChildrenGraph = {

};
type versionsGraph = Array<{
  Scalars: versionsScalars;
  Parents: versionsParentsGraph;
  Children: versionsChildrenGraph;
}>;
type Graph = {
  accessTokens: accessTokensGraph;
  auditLogs: auditLogsGraph;
  awsConsumptionHistories: awsConsumptionHistoriesGraph;
  databaseProviders: databaseProvidersGraph;
  dbConnections: dbConnectionsGraph;
  execTasks: execTasksGraph;
  inviteTokens: inviteTokensGraph;
  members: membersGraph;
  neonConsumptionHistories: neonConsumptionHistoriesGraph;
  neonProjects: neonProjectsGraph;
  organizations: organizationsGraph;
  predictionDataSets: predictionDataSetsGraph;
  predictionJobs: predictionJobsGraph;
  previewDatabases: previewDatabasesGraph;
  pricingPlans: pricingPlansGraph;
  projects: projectsGraph;
  releaseVersions: releaseVersionsGraph;
  shapePredictionOverrides: shapePredictionOverridesGraph;
  shapePredictionStores: shapePredictionStoresGraph;
  snapshots: snapshotsGraph;
  supabaseProjects: supabaseProjectsGraph;
  tables: tablesGraph;
  users: usersGraph;
  PrismaMigrations: PrismaMigrationsGraph;
  jobs: jobsGraph;
  schedules: schedulesGraph;
  versions: versionsGraph;
};
export declare class SeedClientBase {
  /**
   * Generate one or more `accessTokens`.
   * @example With static inputs:
   * ```ts
   * snaplet.accessTokens([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.accessTokens((x) => x(3));
   * snaplet.accessTokens((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.accessTokens((x) => [{}, ...x(3), {}]);
   * ```
   */
  accessTokens: (
    inputs: accessTokensChildInputs<["accessTokens"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `auditLogs`.
   * @example With static inputs:
   * ```ts
   * snaplet.auditLogs([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.auditLogs((x) => x(3));
   * snaplet.auditLogs((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.auditLogs((x) => [{}, ...x(3), {}]);
   * ```
   */
  auditLogs: (
    inputs: auditLogsChildInputs<["auditLogs"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `awsConsumptionHistories`.
   * @example With static inputs:
   * ```ts
   * snaplet.awsConsumptionHistories([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.awsConsumptionHistories((x) => x(3));
   * snaplet.awsConsumptionHistories((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.awsConsumptionHistories((x) => [{}, ...x(3), {}]);
   * ```
   */
  awsConsumptionHistories: (
    inputs: awsConsumptionHistoriesChildInputs<["awsConsumptionHistories"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `databaseProviders`.
   * @example With static inputs:
   * ```ts
   * snaplet.databaseProviders([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.databaseProviders((x) => x(3));
   * snaplet.databaseProviders((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.databaseProviders((x) => [{}, ...x(3), {}]);
   * ```
   */
  databaseProviders: (
    inputs: databaseProvidersChildInputs<["databaseProviders"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `dbConnections`.
   * @example With static inputs:
   * ```ts
   * snaplet.dbConnections([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.dbConnections((x) => x(3));
   * snaplet.dbConnections((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.dbConnections((x) => [{}, ...x(3), {}]);
   * ```
   */
  dbConnections: (
    inputs: dbConnectionsChildInputs<["dbConnections"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `execTasks`.
   * @example With static inputs:
   * ```ts
   * snaplet.execTasks([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.execTasks((x) => x(3));
   * snaplet.execTasks((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.execTasks((x) => [{}, ...x(3), {}]);
   * ```
   */
  execTasks: (
    inputs: execTasksChildInputs<["execTasks"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `inviteTokens`.
   * @example With static inputs:
   * ```ts
   * snaplet.inviteTokens([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.inviteTokens((x) => x(3));
   * snaplet.inviteTokens((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.inviteTokens((x) => [{}, ...x(3), {}]);
   * ```
   */
  inviteTokens: (
    inputs: inviteTokensChildInputs<["inviteTokens"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `members`.
   * @example With static inputs:
   * ```ts
   * snaplet.members([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.members((x) => x(3));
   * snaplet.members((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.members((x) => [{}, ...x(3), {}]);
   * ```
   */
  members: (
    inputs: membersChildInputs<["members"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `neonConsumptionHistories`.
   * @example With static inputs:
   * ```ts
   * snaplet.neonConsumptionHistories([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.neonConsumptionHistories((x) => x(3));
   * snaplet.neonConsumptionHistories((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.neonConsumptionHistories((x) => [{}, ...x(3), {}]);
   * ```
   */
  neonConsumptionHistories: (
    inputs: neonConsumptionHistoriesChildInputs<["neonConsumptionHistories"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `neonProjects`.
   * @example With static inputs:
   * ```ts
   * snaplet.neonProjects([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.neonProjects((x) => x(3));
   * snaplet.neonProjects((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.neonProjects((x) => [{}, ...x(3), {}]);
   * ```
   */
  neonProjects: (
    inputs: neonProjectsChildInputs<["neonProjects"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `organizations`.
   * @example With static inputs:
   * ```ts
   * snaplet.organizations([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.organizations((x) => x(3));
   * snaplet.organizations((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.organizations((x) => [{}, ...x(3), {}]);
   * ```
   */
  organizations: (
    inputs: organizationsChildInputs<["organizations"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `predictionDataSets`.
   * @example With static inputs:
   * ```ts
   * snaplet.predictionDataSets([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.predictionDataSets((x) => x(3));
   * snaplet.predictionDataSets((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.predictionDataSets((x) => [{}, ...x(3), {}]);
   * ```
   */
  predictionDataSets: (
    inputs: predictionDataSetsChildInputs<["predictionDataSets"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `predictionJobs`.
   * @example With static inputs:
   * ```ts
   * snaplet.predictionJobs([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.predictionJobs((x) => x(3));
   * snaplet.predictionJobs((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.predictionJobs((x) => [{}, ...x(3), {}]);
   * ```
   */
  predictionJobs: (
    inputs: predictionJobsChildInputs<["predictionJobs"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `previewDatabases`.
   * @example With static inputs:
   * ```ts
   * snaplet.previewDatabases([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.previewDatabases((x) => x(3));
   * snaplet.previewDatabases((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.previewDatabases((x) => [{}, ...x(3), {}]);
   * ```
   */
  previewDatabases: (
    inputs: previewDatabasesChildInputs<["previewDatabases"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `pricingPlans`.
   * @example With static inputs:
   * ```ts
   * snaplet.pricingPlans([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.pricingPlans((x) => x(3));
   * snaplet.pricingPlans((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.pricingPlans((x) => [{}, ...x(3), {}]);
   * ```
   */
  pricingPlans: (
    inputs: pricingPlansChildInputs<["pricingPlans"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `projects`.
   * @example With static inputs:
   * ```ts
   * snaplet.projects([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.projects((x) => x(3));
   * snaplet.projects((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.projects((x) => [{}, ...x(3), {}]);
   * ```
   */
  projects: (
    inputs: projectsChildInputs<["projects"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `releaseVersions`.
   * @example With static inputs:
   * ```ts
   * snaplet.releaseVersions([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.releaseVersions((x) => x(3));
   * snaplet.releaseVersions((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.releaseVersions((x) => [{}, ...x(3), {}]);
   * ```
   */
  releaseVersions: (
    inputs: releaseVersionsChildInputs<["releaseVersions"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `shapePredictionOverrides`.
   * @example With static inputs:
   * ```ts
   * snaplet.shapePredictionOverrides([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.shapePredictionOverrides((x) => x(3));
   * snaplet.shapePredictionOverrides((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.shapePredictionOverrides((x) => [{}, ...x(3), {}]);
   * ```
   */
  shapePredictionOverrides: (
    inputs: shapePredictionOverridesChildInputs<["shapePredictionOverrides"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `shapePredictionStores`.
   * @example With static inputs:
   * ```ts
   * snaplet.shapePredictionStores([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.shapePredictionStores((x) => x(3));
   * snaplet.shapePredictionStores((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.shapePredictionStores((x) => [{}, ...x(3), {}]);
   * ```
   */
  shapePredictionStores: (
    inputs: shapePredictionStoresChildInputs<["shapePredictionStores"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `snapshots`.
   * @example With static inputs:
   * ```ts
   * snaplet.snapshots([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.snapshots((x) => x(3));
   * snaplet.snapshots((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.snapshots((x) => [{}, ...x(3), {}]);
   * ```
   */
  snapshots: (
    inputs: snapshotsChildInputs<["snapshots"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `supabaseProjects`.
   * @example With static inputs:
   * ```ts
   * snaplet.supabaseProjects([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.supabaseProjects((x) => x(3));
   * snaplet.supabaseProjects((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.supabaseProjects((x) => [{}, ...x(3), {}]);
   * ```
   */
  supabaseProjects: (
    inputs: supabaseProjectsChildInputs<["supabaseProjects"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `tables`.
   * @example With static inputs:
   * ```ts
   * snaplet.tables([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.tables((x) => x(3));
   * snaplet.tables((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.tables((x) => [{}, ...x(3), {}]);
   * ```
   */
  tables: (
    inputs: tablesChildInputs<["tables"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `users`.
   * @example With static inputs:
   * ```ts
   * snaplet.users([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.users((x) => x(3));
   * snaplet.users((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.users((x) => [{}, ...x(3), {}]);
   * ```
   */
  users: (
    inputs: usersChildInputs<["users"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `PrismaMigrations`.
   * @example With static inputs:
   * ```ts
   * snaplet.PrismaMigrations([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.PrismaMigrations((x) => x(3));
   * snaplet.PrismaMigrations((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.PrismaMigrations((x) => [{}, ...x(3), {}]);
   * ```
   */
  PrismaMigrations: (
    inputs: PrismaMigrationsChildInputs<["PrismaMigrations"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `jobs`.
   * @example With static inputs:
   * ```ts
   * snaplet.jobs([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.jobs((x) => x(3));
   * snaplet.jobs((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.jobs((x) => [{}, ...x(3), {}]);
   * ```
   */
  jobs: (
    inputs: jobsChildInputs<["jobs"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `schedules`.
   * @example With static inputs:
   * ```ts
   * snaplet.schedules([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.schedules((x) => x(3));
   * snaplet.schedules((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.schedules((x) => [{}, ...x(3), {}]);
   * ```
   */
  schedules: (
    inputs: schedulesChildInputs<["schedules"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Generate one or more `versions`.
   * @example With static inputs:
   * ```ts
   * snaplet.versions([{}, {}]);
   * ```
   * @example Using the `x` helper:
   * ```ts
   * snaplet.versions((x) => x(3));
   * snaplet.versions((x) => x({ min: 1, max: 10 }));
   * ```
   * @example Mixing both:
   * ```ts
   * snaplet.versions((x) => [{}, ...x(3), {}]);
   * ```
   */
  versions: (
    inputs: versionsChildInputs<["versions"]>,
    options?: PlanOptions,
  ) => Plan;
  /**
   * Compose multiple plans together, injecting the store of the previous plan into the next plan.
   *
   * Learn more in the {@link https://docs.snaplet.dev/core-concepts/seed#using-pipe | documentation}.
   */
  $pipe: Pipe;
  /**
   * Compose multiple plans together, without injecting the store of the previous plan into the next plan.
   * All stores stay independent and are merged together once all the plans are generated.
   *
   * Learn more in the {@link https://docs.snaplet.dev/core-concepts/seed#using-merge | documentation}.
   */
  $merge: Merge;
  /**
   * Create a store instance.
   *
   * Learn more in the {@link https://docs.snaplet.dev/core-concepts/seed#augmenting-external-data-with-createstore | documentation}.
   */
  $createStore: CreateStore;
};
type ScalarField = {
  name: string;
  type: string;
};
type ObjectField = ScalarField & {
  relationFromFields: string[];
  relationToFields: string[];
};
type Inflection = {
  modelName?: (name: string) => string;
  scalarField?: (field: ScalarField) => string;
  parentField?: (field: ObjectField, oppositeBaseNameMap: Record<string, string>) => string;
  childField?: (field: ObjectField, oppositeField: ObjectField, oppositeBaseNameMap: Record<string, string>) => string;
  oppositeBaseNameMap?: Record<string, string>;
};
type Override = {
  AccessToken?: {
    name?: string;
    fields?: {
      id?: string;
      updatedAt?: string;
      createdAt?: string;
      userId?: string;
      userAgent?: string;
      type?: string;
      name?: string;
      hash?: string;
      User?: string;
      ExecTask?: string;
    };
  }
  AuditLog?: {
    name?: string;
    fields?: {
      id?: string;
      createdAt?: string;
      action?: string;
      data?: string;
      userId?: string;
      organizationId?: string;
      projectId?: string;
      Organization?: string;
      Project?: string;
      User?: string;
    };
  }
  AwsConsumptionHistory?: {
    name?: string;
    fields?: {
      name?: string;
      startPeriod?: string;
      endPeriod?: string;
      awsStorageBytes?: string;
      awsComputeTimeSeconds?: string;
      awsDataTransferBytes?: string;
      snapshotId?: string;
      projectId?: string;
      organizationId?: string;
      Organization?: string;
      Project?: string;
      Snapshot?: string;
    };
  }
  DatabaseProvider?: {
    name?: string;
    fields?: {
      id?: string;
      name?: string;
      domain?: string;
      DbConnection?: string;
    };
  }
  DbConnection?: {
    name?: string;
    fields?: {
      id?: string;
      name?: string;
      ssl?: string;
      connectionUrlHash?: string;
      organizationId?: string;
      databaseProviderId?: string;
      DatabaseProvider?: string;
      Organization?: string;
      Project_Project_dbConnectionIdToDbConnection?: string;
      Project_Project_hostedDbUrlIdToDbConnection?: string;
      Snapshot?: string;
    };
  }
  ExecTask?: {
    name?: string;
    fields?: {
      id?: string;
      command?: string;
      env?: string;
      exitCode?: string;
      createdAt?: string;
      updatedAt?: string;
      projectId?: string;
      needsSourceDatabaseUrl?: string;
      progress?: string;
      endedAt?: string;
      arn?: string;
      accessTokenId?: string;
      lastNotifiedAt?: string;
      AccessToken?: string;
      Project?: string;
      Snapshot?: string;
    };
  }
  InviteToken?: {
    name?: string;
    fields?: {
      token?: string;
      createdAt?: string;
      updatedAt?: string;
      createdByUserId?: string;
      usedByMemberId?: string;
      organizationId?: string;
      expiresAt?: string;
      Member?: string;
      Organization?: string;
      User?: string;
    };
  }
  Member?: {
    name?: string;
    fields?: {
      role?: string;
      organizationId?: string;
      userId?: string;
      id?: string;
      createdAt?: string;
      updatedAt?: string;
      Organization?: string;
      User?: string;
      InviteToken?: string;
    };
  }
  NeonConsumptionHistory?: {
    name?: string;
    fields?: {
      name?: string;
      startPeriod?: string;
      endPeriod?: string;
      neonDataStorageBytesHour?: string;
      neonSyntheticStorageSize?: string;
      neonDataTransferBytes?: string;
      neonWrittenDataBytes?: string;
      neonComputeTimeSeconds?: string;
      neonActiveTimeSeconds?: string;
      snapshotId?: string;
      projectId?: string;
      organizationId?: string;
      Organization?: string;
      Project?: string;
      Snapshot?: string;
    };
  }
  NeonProject?: {
    name?: string;
    fields?: {
      id?: string;
      createdAt?: string;
      updatedAt?: string;
      neonProjectId?: string;
      snapshotId?: string;
      connectionUrlHash?: string;
      projectId?: string;
      Project?: string;
      Snapshot?: string;
      PreviewDatabase?: string;
    };
  }
  Organization?: {
    name?: string;
    fields?: {
      id?: string;
      name?: string;
      pricingPlanId?: string;
      subscriptionData?: string;
      createdAt?: string;
      updatedAt?: string;
      deleted?: string;
      PricingPlan?: string;
      AuditLog?: string;
      AwsConsumptionHistory?: string;
      DbConnection?: string;
      InviteToken?: string;
      Member?: string;
      NeonConsumptionHistory?: string;
      Project?: string;
      Snapshot?: string;
      Table?: string;
    };
  }
  PredictionDataSet?: {
    name?: string;
    fields?: {
      id?: string;
      createdAt?: string;
      updatedAt?: string;
      input?: string;
      context?: string;
      shape?: string;
      contextSkipTraining?: string;
      shapeSkipTraining?: string;
    };
  }
  PredictionJob?: {
    name?: string;
    fields?: {
      id?: string;
      engine?: string;
      createdAt?: string;
      updatedAt?: string;
      endedAt?: string;
      rawInput?: string;
      engineInput?: string;
      progress?: string;
      engineOptions?: string;
      Project?: string;
    };
  }
  PreviewDatabase?: {
    name?: string;
    fields?: {
      id?: string;
      createdAt?: string;
      updatedAt?: string;
      name?: string;
      neonBranchId?: string;
      neonProjectId?: string;
      connectionUrlHash?: string;
      NeonProject?: string;
    };
  }
  PricingPlan?: {
    name?: string;
    fields?: {
      id?: string;
      name?: string;
      amount?: string;
      isDefault?: string;
      storageLimit?: string;
      processLimit?: string;
      restoreLimit?: string;
      productId?: string;
      Organization?: string;
    };
  }
  Project?: {
    name?: string;
    fields?: {
      name?: string;
      organizationId?: string;
      dbConnectionId?: string;
      id?: string;
      createdAt?: string;
      updatedAt?: string;
      dbInfo?: string;
      dbInfoLastUpdate?: string;
      deleted?: string;
      autoDeleteDays?: string;
      snapshotConfig?: string;
      schedule?: string;
      runTaskOptions?: string;
      hostedDbUrlId?: string;
      hostedDbRegion?: string;
      scheduleTags?: string;
      previewDatabaseRegion?: string;
      predictionJobId?: string;
      supabaseProjectId?: string;
      preseedPreviewDatabases?: string;
      DbConnection_Project_dbConnectionIdToDbConnection?: string;
      DbConnection_Project_hostedDbUrlIdToDbConnection?: string;
      Organization?: string;
      PredictionJob?: string;
      SupabaseProject?: string;
      AuditLog?: string;
      AwsConsumptionHistory?: string;
      ExecTask?: string;
      NeonConsumptionHistory?: string;
      NeonProject?: string;
      ShapePredictionOverride?: string;
      Snapshot?: string;
    };
  }
  ReleaseVersion?: {
    name?: string;
    fields?: {
      version?: string;
      channel?: string;
      forceUpgrade?: string;
      releaseDate?: string;
      userId?: string;
      User?: string;
    };
  }
  ShapePredictionOverride?: {
    name?: string;
    fields?: {
      id?: string;
      createdAt?: string;
      updatedAt?: string;
      input?: string;
      shape?: string;
      context?: string;
      projectId?: string;
      Project?: string;
    };
  }
  ShapePredictionStore?: {
    name?: string;
    fields?: {
      id?: string;
      createdAt?: string;
      updatedAt?: string;
      input?: string;
      predictedLabel?: string;
      confidence?: string;
      overrideLabel?: string;
      confidenceContext?: string;
      overrideContext?: string;
      predictedContext?: string;
      engine?: string;
    };
  }
  Snapshot?: {
    name?: string;
    fields?: {
      id?: string;
      uniqueName?: string;
      createdAt?: string;
      updatedAt?: string;
      statusOld?: string;
      organizationId?: string;
      dbConnectionId?: string;
      workerIpAddress?: string;
      errors?: string;
      failureCount?: string;
      projectId?: string;
      dbSchemaDump?: string;
      logs?: string;
      restoreCount?: string;
      dbInfo?: string;
      snapshotConfig?: string;
      runtime?: string;
      summary?: string;
      createdByUserId?: string;
      execTaskId?: string;
      progress?: string;
      notifyOnSuccess?: string;
      deletedAt?: string;
      purgedAt?: string;
      storage?: string;
      isScheduled?: string;
      preseedPreviewDatabase?: string;
      DbConnection?: string;
      ExecTask?: string;
      Organization?: string;
      Project?: string;
      User?: string;
      AwsConsumptionHistory?: string;
      NeonConsumptionHistory?: string;
      NeonProject?: string;
      Table?: string;
    };
  }
  SupabaseProject?: {
    name?: string;
    fields?: {
      id?: string;
      createdAt?: string;
      updatedAt?: string;
      projectId?: string;
      supabaseAuthCodeHash?: string;
      supabaseRefreshToken?: string;
      supabaseAccessTokenHash?: string;
      supabaseAccessTokenExpiresAt?: string;
      Project?: string;
    };
  }
  Table?: {
    name?: string;
    fields?: {
      id?: string;
      tableName?: string;
      status?: string;
      bucketKey?: string;
      bytes?: string;
      timeToDump?: string;
      timeToSave?: string;
      snapshotId?: string;
      organizationId?: string;
      checksum?: string;
      timeToCompress?: string;
      timeToEncrypt?: string;
      rows?: string;
      schema?: string;
      totalRows?: string;
      Organization?: string;
      Snapshot?: string;
    };
  }
  User?: {
    name?: string;
    fields?: {
      id?: string;
      sub?: string;
      email?: string;
      createdAt?: string;
      updatedAt?: string;
      role?: string;
      notifications?: string;
      AccessToken?: string;
      AuditLog?: string;
      InviteToken?: string;
      Member?: string;
      ReleaseVersion?: string;
      Snapshot?: string;
    };
  }
  _prisma_migrations?: {
    name?: string;
    fields?: {
      id?: string;
      checksum?: string;
      finished_at?: string;
      migration_name?: string;
      logs?: string;
      rolled_back_at?: string;
      started_at?: string;
      applied_steps_count?: string;
    };
  }
  job?: {
    name?: string;
    fields?: {
      id?: string;
      name?: string;
      priority?: string;
      data?: string;
      state?: string;
      retrylimit?: string;
      retrycount?: string;
      retrydelay?: string;
      retrybackoff?: string;
      startafter?: string;
      startedon?: string;
      singletonkey?: string;
      singletonon?: string;
      expirein?: string;
      createdon?: string;
      completedon?: string;
      keepuntil?: string;
      on_complete?: string;
      output?: string;
    };
  }
  schedule?: {
    name?: string;
    fields?: {
      name?: string;
      cron?: string;
      timezone?: string;
      data?: string;
      options?: string;
      created_on?: string;
      updated_on?: string;
    };
  }
  version?: {
    name?: string;
    fields?: {
      version?: string;
      maintained_on?: string;
      cron_on?: string;
    };
  }}
export type Alias = {
  inflection?: Inflection | false;
  override?: Override;
};