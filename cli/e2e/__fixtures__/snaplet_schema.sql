--
-- PostgreSQL database dump
--

-- Dumped from database version 11.16
-- Dumped by pg_dump version 15.2 (Ubuntu 15.2-1.pgdg22.04+1)

-- Started on 2023-03-15 22:02:57 Africa

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 8 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- TOC entry 2 (class 3079 OID 22670)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 4068 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 659 (class 1247 OID 39068)
-- Name: AccessTokenType; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."AccessTokenType" AS ENUM (
    'CLI',
    'WORKER'
);


--
-- TOC entry 724 (class 1247 OID 65028)
-- Name: AuditLogActions; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."AuditLogActions" AS ENUM (
    'SNAPSHOT_CREATED',
    'SNAPSHOT_RESTORED_SUCCESS',
    'SNAPSHOT_RESTORED_FAILURE',
    'SNAPSHOT_DELETED',
    'SNAPSHOT_CONFIG_UPDATED',
    'PROJECT_DELETED',
    'ORGANIZATION_DELETED'
);


--
-- TOC entry 665 (class 1247 OID 62471)
-- Name: DatabaseStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."DatabaseStatus" AS ENUM (
    'ENABLED',
    'DISABLED',
    'DELETED'
);


--
-- TOC entry 672 (class 1247 OID 18145)
-- Name: MemberRole; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."MemberRole" AS ENUM (
    'OWNER',
    'ADMIN',
    'MEMBER'
);


--
-- TOC entry 745 (class 1247 OID 114449)
-- Name: ReleaseChannel; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."ReleaseChannel" AS ENUM (
    'PRIVATE',
    'PUBLIC',
    'BETA'
);


--
-- TOC entry 682 (class 1247 OID 17681)
-- Name: SnapshotStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."SnapshotStatus" AS ENUM (
    'PENDING',
    'STARTED',
    'SUCCESS',
    'FAILURE',
    'BOOTING',
    'DELETED',
    'STARTING',
    'PURGED',
    'TIMEOUT'
);


--
-- TOC entry 652 (class 1247 OID 430994)
-- Name: UserNotifications; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."UserNotifications" AS ENUM (
    'NONE',
    'EMAIL'
);


--
-- TOC entry 721 (class 1247 OID 58971)
-- Name: UserRole; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."UserRole" AS ENUM (
    'USER',
    'SUPERUSER',
    'ADMIN'
);


SET default_tablespace = '';

--
-- TOC entry 201 (class 1259 OID 18174)
-- Name: AccessToken; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AccessToken" (
    id text NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "userId" text NOT NULL,
    "userAgent" text,
    type public."AccessTokenType" DEFAULT 'CLI'::public."AccessTokenType" NOT NULL,
    name text
);


--
-- TOC entry 218 (class 1259 OID 65039)
-- Name: AuditLog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AuditLog" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    action public."AuditLogActions" NOT NULL,
    data jsonb,
    "userId" text,
    "organizationId" text NOT NULL
);


--
-- TOC entry 217 (class 1259 OID 60714)
-- Name: DatabaseProvider; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."DatabaseProvider" (
    id integer NOT NULL,
    name text NOT NULL,
    domain text NOT NULL,
    "defaultSnapshotConfig" jsonb
);


--
-- TOC entry 216 (class 1259 OID 60712)
-- Name: DatabaseProvider_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."DatabaseProvider_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4069 (class 0 OID 0)
-- Dependencies: 216
-- Name: DatabaseProvider_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."DatabaseProvider_id_seq" OWNED BY public."DatabaseProvider".id;


--
-- TOC entry 202 (class 1259 OID 18183)
-- Name: DbConnection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."DbConnection" (
    id text NOT NULL,
    name text,
    ssl boolean DEFAULT true NOT NULL,
    "connectionUrlHash" jsonb NOT NULL,
    "organizationId" text NOT NULL,
    "databaseProviderId" integer
);


--
-- TOC entry 219 (class 1259 OID 305753)
-- Name: ExecTask; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ExecTask" (
    id text NOT NULL,
    command text NOT NULL,
    env jsonb,
    "exitCode" integer,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "userId" text NOT NULL,
    "projectId" text NOT NULL,
    "needsSourceDatabaseUrl" boolean DEFAULT false NOT NULL,
    progress jsonb
);


--
-- TOC entry 214 (class 1259 OID 43445)
-- Name: InviteToken; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."InviteToken" (
    token text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "createdByUserId" text NOT NULL,
    "usedByMemberId" integer,
    "organizationId" text,
    "expiresAt" timestamp(3) without time zone NOT NULL
);


--
-- TOC entry 200 (class 1259 OID 18167)
-- Name: Member; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Member" (
    role public."MemberRole" DEFAULT 'MEMBER'::public."MemberRole" NOT NULL,
    "organizationId" text NOT NULL,
    "userId" text NOT NULL,
    id integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- TOC entry 213 (class 1259 OID 43431)
-- Name: Member_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Member_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4070 (class 0 OID 0)
-- Dependencies: 213
-- Name: Member_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Member_id_seq" OWNED BY public."Member".id;


--
-- TOC entry 199 (class 1259 OID 18159)
-- Name: Organization; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Organization" (
    id text NOT NULL,
    name text NOT NULL,
    "pricingPlanId" integer,
    "subscriptionData" jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    deleted boolean DEFAULT false NOT NULL
);


--
-- TOC entry 211 (class 1259 OID 22779)
-- Name: PricingPlan; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."PricingPlan" (
    id integer NOT NULL,
    name text NOT NULL,
    amount text NOT NULL,
    "isDefault" boolean NOT NULL,
    "storageLimit" integer NOT NULL,
    "processLimit" integer NOT NULL,
    "restoreLimit" integer NOT NULL,
    "productId" text NOT NULL
);


--
-- TOC entry 210 (class 1259 OID 22777)
-- Name: PricingPlan_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."PricingPlan_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4071 (class 0 OID 0)
-- Dependencies: 210
-- Name: PricingPlan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."PricingPlan_id_seq" OWNED BY public."PricingPlan".id;


--
-- TOC entry 212 (class 1259 OID 29552)
-- Name: Project; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Project" (
    name text NOT NULL,
    "organizationId" text NOT NULL,
    "dbConnectionId" text,
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "dbInfo" jsonb,
    "dbInfoLastUpdate" timestamp(3) without time zone,
    deleted boolean DEFAULT false NOT NULL,
    "autoDeleteDays" integer DEFAULT 7,
    "snapshotConfig" jsonb,
    schedule jsonb,
    "runTaskOptions" jsonb,
    "hostedDbUrlId" text,
    "hostedDbRegion" text
);


--
-- TOC entry 215 (class 1259 OID 54227)
-- Name: ReleaseVersion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ReleaseVersion" (
    version text NOT NULL,
    channel public."ReleaseChannel" DEFAULT 'PUBLIC'::public."ReleaseChannel" NOT NULL,
    "forceUpgrade" boolean DEFAULT false NOT NULL,
    "releaseDate" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "userId" text
);


--
-- TOC entry 203 (class 1259 OID 18200)
-- Name: Snapshot; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Snapshot" (
    id text NOT NULL,
    "uniqueName" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    status public."SnapshotStatus" DEFAULT 'BOOTING'::public."SnapshotStatus" NOT NULL,
    "organizationId" text NOT NULL,
    "dbConnectionId" text,
    "workerIpAddress" text,
    errors text[],
    "failureCount" integer DEFAULT 0 NOT NULL,
    "projectId" text NOT NULL,
    "dbSchemaDump" text,
    logs text[],
    "restoreCount" integer DEFAULT 0 NOT NULL,
    "dbInfo" jsonb,
    "snapshotConfig" jsonb,
    runtime jsonb,
    summary jsonb,
    "createdByUserId" text,
    "execTaskId" text,
    progress jsonb
);


--
-- TOC entry 204 (class 1259 OID 18219)
-- Name: Table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Table" (
    id text NOT NULL,
    "tableName" text NOT NULL,
    status public."SnapshotStatus" DEFAULT 'PENDING'::public."SnapshotStatus" NOT NULL,
    "bucketKey" text,
    bytes text,
    "timeToDump" integer,
    "timeToSave" integer,
    "snapshotId" text NOT NULL,
    "organizationId" text NOT NULL,
    checksum text,
    "timeToCompress" integer,
    "timeToEncrypt" integer,
    rows text,
    schema text NOT NULL,
    "totalRows" text
);


--
-- TOC entry 198 (class 1259 OID 18151)
-- Name: User; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."User" (
    id text NOT NULL,
    sub text NOT NULL,
    email text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    role public."UserRole" DEFAULT 'USER'::public."UserRole" NOT NULL,
    notifications public."UserNotifications" DEFAULT 'EMAIL'::public."UserNotifications" NOT NULL
);


--
-- TOC entry 205 (class 1259 OID 22643)
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


--
-- TOC entry 3862 (class 2604 OID 60717)
-- Name: DatabaseProvider id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DatabaseProvider" ALTER COLUMN id SET DEFAULT nextval('public."DatabaseProvider_id_seq"'::regclass);


--
-- TOC entry 3842 (class 2604 OID 43433)
-- Name: Member id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Member" ALTER COLUMN id SET DEFAULT nextval('public."Member_id_seq"'::regclass);


--
-- TOC entry 3854 (class 2604 OID 22782)
-- Name: PricingPlan id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PricingPlan" ALTER COLUMN id SET DEFAULT nextval('public."PricingPlan_id_seq"'::regclass);


--
-- TOC entry 3878 (class 2606 OID 18182)
-- Name: AccessToken AccessToken_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AccessToken"
    ADD CONSTRAINT "AccessToken_pkey" PRIMARY KEY (id);


--
-- TOC entry 3915 (class 2606 OID 65047)
-- Name: AuditLog AuditLog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AuditLog"
    ADD CONSTRAINT "AuditLog_pkey" PRIMARY KEY (id);


--
-- TOC entry 3912 (class 2606 OID 60722)
-- Name: DatabaseProvider DatabaseProvider_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DatabaseProvider"
    ADD CONSTRAINT "DatabaseProvider_pkey" PRIMARY KEY (id);


--
-- TOC entry 3883 (class 2606 OID 18191)
-- Name: DbConnection DbConnection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DbConnection"
    ADD CONSTRAINT "DbConnection_pkey" PRIMARY KEY (id);


--
-- TOC entry 3917 (class 2606 OID 305762)
-- Name: ExecTask ExecTask_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ExecTask"
    ADD CONSTRAINT "ExecTask_pkey" PRIMARY KEY (id);


--
-- TOC entry 3904 (class 2606 OID 43453)
-- Name: InviteToken InviteToken_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."InviteToken"
    ADD CONSTRAINT "InviteToken_pkey" PRIMARY KEY (token);


--
-- TOC entry 3874 (class 2606 OID 43435)
-- Name: Member Member_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Member"
    ADD CONSTRAINT "Member_pkey" PRIMARY KEY (id);


--
-- TOC entry 3872 (class 2606 OID 18166)
-- Name: Organization Organization_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Organization"
    ADD CONSTRAINT "Organization_pkey" PRIMARY KEY (id);


--
-- TOC entry 3896 (class 2606 OID 22787)
-- Name: PricingPlan PricingPlan_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PricingPlan"
    ADD CONSTRAINT "PricingPlan_pkey" PRIMARY KEY (id);


--
-- TOC entry 3902 (class 2606 OID 37283)
-- Name: Project Project_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Project"
    ADD CONSTRAINT "Project_pkey" PRIMARY KEY (id);


--
-- TOC entry 3907 (class 2606 OID 54237)
-- Name: ReleaseVersion ReleaseVersion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ReleaseVersion"
    ADD CONSTRAINT "ReleaseVersion_pkey" PRIMARY KEY (version);


--
-- TOC entry 3887 (class 2606 OID 18209)
-- Name: Snapshot Snapshot_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Snapshot"
    ADD CONSTRAINT "Snapshot_pkey" PRIMARY KEY (id);


--
-- TOC entry 3890 (class 2606 OID 18227)
-- Name: Table Table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Table"
    ADD CONSTRAINT "Table_pkey" PRIMARY KEY (id);


--
-- TOC entry 3869 (class 2606 OID 18158)
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (id);


--
-- TOC entry 3894 (class 2606 OID 22652)
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 3879 (class 1259 OID 18231)
-- Name: AccessToken_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "AccessToken_userId_idx" ON public."AccessToken" USING btree ("userId");


--
-- TOC entry 3913 (class 1259 OID 65048)
-- Name: AuditLog_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "AuditLog_organizationId_idx" ON public."AuditLog" USING btree ("organizationId");


--
-- TOC entry 3910 (class 1259 OID 60723)
-- Name: DatabaseProvider_domain_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "DatabaseProvider_domain_key" ON public."DatabaseProvider" USING btree (domain);


--
-- TOC entry 3880 (class 1259 OID 18232)
-- Name: DbConnection_id_organizationId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "DbConnection_id_organizationId_key" ON public."DbConnection" USING btree (id, "organizationId");


--
-- TOC entry 3881 (class 1259 OID 18234)
-- Name: DbConnection_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "DbConnection_organizationId_idx" ON public."DbConnection" USING btree ("organizationId");


--
-- TOC entry 3905 (class 1259 OID 43454)
-- Name: InviteToken_usedByMemberId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "InviteToken_usedByMemberId_key" ON public."InviteToken" USING btree ("usedByMemberId");


--
-- TOC entry 3875 (class 1259 OID 18230)
-- Name: Member_userId_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Member_userId_organizationId_idx" ON public."Member" USING btree ("userId", "organizationId");


--
-- TOC entry 3876 (class 1259 OID 18229)
-- Name: Member_userId_organizationId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Member_userId_organizationId_key" ON public."Member" USING btree ("userId", "organizationId");


--
-- TOC entry 3897 (class 1259 OID 38616)
-- Name: PricingPlan_productId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "PricingPlan_productId_key" ON public."PricingPlan" USING btree ("productId");


--
-- TOC entry 3898 (class 1259 OID 166490)
-- Name: Project_hostedDbUrlId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Project_hostedDbUrlId_key" ON public."Project" USING btree ("hostedDbUrlId");


--
-- TOC entry 3899 (class 1259 OID 37294)
-- Name: Project_organizationId_dbConnectionId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Project_organizationId_dbConnectionId_key" ON public."Project" USING btree ("organizationId", "dbConnectionId");


--
-- TOC entry 3900 (class 1259 OID 29559)
-- Name: Project_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Project_organizationId_idx" ON public."Project" USING btree ("organizationId");


--
-- TOC entry 3908 (class 1259 OID 54238)
-- Name: ReleaseVersion_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ReleaseVersion_userId_key" ON public."ReleaseVersion" USING btree ("userId");


--
-- TOC entry 3909 (class 1259 OID 54239)
-- Name: ReleaseVersion_version_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ReleaseVersion_version_userId_key" ON public."ReleaseVersion" USING btree (version, "userId");


--
-- TOC entry 3884 (class 1259 OID 18238)
-- Name: Snapshot_dbConnectionId_uniqueName_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Snapshot_dbConnectionId_uniqueName_key" ON public."Snapshot" USING btree ("dbConnectionId", "uniqueName");


--
-- TOC entry 3885 (class 1259 OID 18237)
-- Name: Snapshot_id_organizationId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Snapshot_id_organizationId_key" ON public."Snapshot" USING btree (id, "organizationId");


--
-- TOC entry 3888 (class 1259 OID 18239)
-- Name: Table_id_organizationId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Table_id_organizationId_key" ON public."Table" USING btree (id, "organizationId");


--
-- TOC entry 3891 (class 1259 OID 52228)
-- Name: Table_schema_tableName_snapshotId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Table_schema_tableName_snapshotId_key" ON public."Table" USING btree (schema, "tableName", "snapshotId");


--
-- TOC entry 3892 (class 1259 OID 235400)
-- Name: Table_snapshotId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Table_snapshotId_idx" ON public."Table" USING btree ("snapshotId");


--
-- TOC entry 3867 (class 1259 OID 18530)
-- Name: User_email_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "User_email_key" ON public."User" USING btree (email);


--
-- TOC entry 3870 (class 1259 OID 18228)
-- Name: User_sub_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "User_sub_key" ON public."User" USING btree (sub);


--
-- TOC entry 3921 (class 2606 OID 58991)
-- Name: AccessToken AccessToken_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AccessToken"
    ADD CONSTRAINT "AccessToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3938 (class 2606 OID 65054)
-- Name: AuditLog AuditLog_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AuditLog"
    ADD CONSTRAINT "AuditLog_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3939 (class 2606 OID 65049)
-- Name: AuditLog AuditLog_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AuditLog"
    ADD CONSTRAINT "AuditLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3922 (class 2606 OID 63262)
-- Name: DbConnection DbConnection_databaseProviderId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DbConnection"
    ADD CONSTRAINT "DbConnection_databaseProviderId_fkey" FOREIGN KEY ("databaseProviderId") REFERENCES public."DatabaseProvider"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3923 (class 2606 OID 59001)
-- Name: DbConnection DbConnection_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DbConnection"
    ADD CONSTRAINT "DbConnection_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3940 (class 2606 OID 305768)
-- Name: ExecTask ExecTask_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ExecTask"
    ADD CONSTRAINT "ExecTask_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3941 (class 2606 OID 305763)
-- Name: ExecTask ExecTask_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ExecTask"
    ADD CONSTRAINT "ExecTask_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3934 (class 2606 OID 58976)
-- Name: InviteToken InviteToken_createdByUserId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."InviteToken"
    ADD CONSTRAINT "InviteToken_createdByUserId_fkey" FOREIGN KEY ("createdByUserId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3935 (class 2606 OID 43465)
-- Name: InviteToken InviteToken_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."InviteToken"
    ADD CONSTRAINT "InviteToken_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3936 (class 2606 OID 43460)
-- Name: InviteToken InviteToken_usedByMemberId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."InviteToken"
    ADD CONSTRAINT "InviteToken_usedByMemberId_fkey" FOREIGN KEY ("usedByMemberId") REFERENCES public."Member"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3919 (class 2606 OID 58981)
-- Name: Member Member_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Member"
    ADD CONSTRAINT "Member_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3920 (class 2606 OID 58986)
-- Name: Member Member_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Member"
    ADD CONSTRAINT "Member_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3918 (class 2606 OID 51497)
-- Name: Organization Organization_pricingPlanId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Organization"
    ADD CONSTRAINT "Organization_pricingPlanId_fkey" FOREIGN KEY ("pricingPlanId") REFERENCES public."PricingPlan"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3931 (class 2606 OID 29565)
-- Name: Project Project_dbConnectionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Project"
    ADD CONSTRAINT "Project_dbConnectionId_fkey" FOREIGN KEY ("dbConnectionId") REFERENCES public."DbConnection"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3932 (class 2606 OID 166491)
-- Name: Project Project_hostedDbUrlId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Project"
    ADD CONSTRAINT "Project_hostedDbUrlId_fkey" FOREIGN KEY ("hostedDbUrlId") REFERENCES public."DbConnection"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3933 (class 2606 OID 58996)
-- Name: Project Project_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Project"
    ADD CONSTRAINT "Project_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3937 (class 2606 OID 54240)
-- Name: ReleaseVersion ReleaseVersion_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ReleaseVersion"
    ADD CONSTRAINT "ReleaseVersion_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3924 (class 2606 OID 122229)
-- Name: Snapshot Snapshot_createdByUserId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Snapshot"
    ADD CONSTRAINT "Snapshot_createdByUserId_fkey" FOREIGN KEY ("createdByUserId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3925 (class 2606 OID 18275)
-- Name: Snapshot Snapshot_dbConnectionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Snapshot"
    ADD CONSTRAINT "Snapshot_dbConnectionId_fkey" FOREIGN KEY ("dbConnectionId") REFERENCES public."DbConnection"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3926 (class 2606 OID 366787)
-- Name: Snapshot Snapshot_execTaskId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Snapshot"
    ADD CONSTRAINT "Snapshot_execTaskId_fkey" FOREIGN KEY ("execTaskId") REFERENCES public."ExecTask"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3927 (class 2606 OID 59011)
-- Name: Snapshot Snapshot_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Snapshot"
    ADD CONSTRAINT "Snapshot_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3928 (class 2606 OID 120381)
-- Name: Snapshot Snapshot_projectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Snapshot"
    ADD CONSTRAINT "Snapshot_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES public."Project"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3929 (class 2606 OID 59021)
-- Name: Table Table_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Table"
    ADD CONSTRAINT "Table_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public."Organization"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3930 (class 2606 OID 59016)
-- Name: Table Table_snapshotId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Table"
    ADD CONSTRAINT "Table_snapshotId_fkey" FOREIGN KEY ("snapshotId") REFERENCES public."Snapshot"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


-- Completed on 2023-03-15 22:02:57 Africa

--
-- PostgreSQL database dump complete
--