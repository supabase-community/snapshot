--
-- PostgreSQL database dump
--

-- Dumped from database version 14.7 (Homebrew)
-- Dumped by pg_dump version 15.1

-- Started on 2023-03-05 23:38:11 WET

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
-- TOC entry 6 (class 2615 OID 260680)
-- Name: hdb_catalog; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA hdb_catalog;


ALTER SCHEMA hdb_catalog OWNER TO postgres;

--
-- TOC entry 7 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 2 (class 3079 OID 260681)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 5314 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 1110 (class 1247 OID 260720)
-- Name: permission_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.permission_type AS (
	entity_id uuid,
	access text
);


ALTER TYPE public.permission_type OWNER TO postgres;


--
-- TOC entry 374 (class 1255 OID 260721)
-- Name: gen_hasura_uuid(); Type: FUNCTION; Schema: hdb_catalog; Owner: postgres
--

CREATE FUNCTION hdb_catalog.gen_hasura_uuid() RETURNS uuid
    LANGUAGE sql
    AS $$select gen_random_uuid()$$;


ALTER FUNCTION hdb_catalog.gen_hasura_uuid() OWNER TO postgres;

--
-- TOC entry 385 (class 1255 OID 260722)
-- Name: insert_event_log(text, text, text, text, json); Type: FUNCTION; Schema: hdb_catalog; Owner: postgres
--

CREATE FUNCTION hdb_catalog.insert_event_log(schema_name text, table_name text, trigger_name text, op text, row_data json) RETURNS text
    LANGUAGE plpgsql
    AS $$
  DECLARE
    id text;
    payload json;
    session_variables json;
    server_version_num int;
    trace_context json;
  BEGIN
    id := gen_random_uuid();
    server_version_num := current_setting('server_version_num');
    IF server_version_num >= 90600 THEN
      session_variables := current_setting('hasura.user', 't');
      trace_context := current_setting('hasura.tracecontext', 't');
    ELSE
      BEGIN
        session_variables := current_setting('hasura.user');
      EXCEPTION WHEN OTHERS THEN
                  session_variables := NULL;
      END;
      BEGIN
        trace_context := current_setting('hasura.tracecontext');
      EXCEPTION WHEN OTHERS THEN
        trace_context := NULL;
      END;
    END IF;
    payload := json_build_object(
      'op', op,
      'data', row_data,
      'session_variables', session_variables,
      'trace_context', trace_context
    );
    INSERT INTO hdb_catalog.event_log
                (id, schema_name, table_name, trigger_name, payload)
    VALUES
    (id, schema_name, table_name, trigger_name, payload);
    RETURN id;
  END;
$$;


ALTER FUNCTION hdb_catalog.insert_event_log(schema_name text, table_name text, trigger_name text, op text, row_data json) OWNER TO postgres;

--
-- TOC entry 395 (class 1255 OID 260723)
-- Name: notify_hasura_events_INSERT(); Type: FUNCTION; Schema: hdb_catalog; Owner: postgres
--

CREATE FUNCTION hdb_catalog."notify_hasura_events_INSERT"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    _old record;
    _new record;
    _data json;
  BEGIN
    IF TG_OP = 'UPDATE' THEN
      _old := row((SELECT  "e"  FROM  (SELECT  OLD."payload" , OLD."updated_at" , OLD."created_at" , OLD."id" , OLD."type" , OLD."creator_id"        ) AS "e"      ) );
      _new := row((SELECT  "e"  FROM  (SELECT  NEW."payload" , NEW."updated_at" , NEW."created_at" , NEW."id" , NEW."type" , NEW."creator_id"        ) AS "e"      ) );
    ELSE
    /* initialize _old and _new with dummy values for INSERT and UPDATE events*/
      _old := row((select 1));
      _new := row((select 1));
    END IF;
    _data := json_build_object(
      'old', NULL,
      'new', row_to_json((SELECT  "e"  FROM  (SELECT  NEW."payload" , NEW."updated_at" , NEW."created_at" , NEW."id" , NEW."type" , NEW."creator_id"        ) AS "e"      ) )
    );
    BEGIN
    /* NOTE: formerly we used TG_TABLE_NAME in place of tableName here. However in the case of
    partitioned tables this will give the name of the partitioned table and since we use the table name to
    get the event trigger configuration from the schema, this fails because the event trigger is only created
    on the original table.  */
      IF (TG_OP <> 'UPDATE') OR (_old <> _new) THEN
        PERFORM hdb_catalog.insert_event_log(CAST('public' AS text), CAST('events' AS text), CAST('events' AS text), TG_OP, _data);
      END IF;
      EXCEPTION WHEN undefined_function THEN
        IF (TG_OP <> 'UPDATE') OR (_old *<> _new) THEN
          PERFORM hdb_catalog.insert_event_log(CAST('public' AS text), CAST('events' AS text), CAST('events' AS text), TG_OP, _data);
        END IF;
    END;

    RETURN NULL;
  END;
$$;


ALTER FUNCTION hdb_catalog."notify_hasura_events_INSERT"() OWNER TO postgres;


--
-- TOC entry 230 (class 1259 OID 260988)
-- Name: event_invocation_logs; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.event_invocation_logs (
    id text DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    event_id text,
    status integer,
    request json,
    response json,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE hdb_catalog.event_invocation_logs OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 260995)
-- Name: event_log; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.event_log (
    id text DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    trigger_name text NOT NULL,
    payload jsonb NOT NULL,
    delivered boolean DEFAULT false NOT NULL,
    error boolean DEFAULT false NOT NULL,
    tries integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    locked timestamp with time zone,
    next_retry_at timestamp without time zone,
    archived boolean DEFAULT false NOT NULL
);


ALTER TABLE hdb_catalog.event_log OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 261006)
-- Name: hdb_action_log; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_action_log (
    id uuid DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    action_name text,
    input_payload jsonb NOT NULL,
    request_headers jsonb NOT NULL,
    session_variables jsonb NOT NULL,
    response_payload jsonb,
    errors jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    response_received_at timestamp with time zone,
    status text NOT NULL,
    CONSTRAINT hdb_action_log_status_check CHECK ((status = ANY (ARRAY['created'::text, 'processing'::text, 'completed'::text, 'error'::text])))
);


ALTER TABLE hdb_catalog.hdb_action_log OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 261014)
-- Name: hdb_cron_event_invocation_logs; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_cron_event_invocation_logs (
    id text DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    event_id text,
    status integer,
    request json,
    response json,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE hdb_catalog.hdb_cron_event_invocation_logs OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 261021)
-- Name: hdb_cron_events; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_cron_events (
    id text DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    trigger_name text NOT NULL,
    scheduled_time timestamp with time zone NOT NULL,
    status text DEFAULT 'scheduled'::text NOT NULL,
    tries integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    next_retry_at timestamp with time zone,
    CONSTRAINT valid_status CHECK ((status = ANY (ARRAY['scheduled'::text, 'locked'::text, 'delivered'::text, 'error'::text, 'dead'::text])))
);


ALTER TABLE hdb_catalog.hdb_cron_events OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 261031)
-- Name: hdb_metadata; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_metadata (
    id integer NOT NULL,
    metadata json NOT NULL,
    resource_version integer DEFAULT 1 NOT NULL
);


ALTER TABLE hdb_catalog.hdb_metadata OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 261037)
-- Name: hdb_scheduled_event_invocation_logs; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_scheduled_event_invocation_logs (
    id text DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    event_id text,
    status integer,
    request json,
    response json,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE hdb_catalog.hdb_scheduled_event_invocation_logs OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 261044)
-- Name: hdb_scheduled_events; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_scheduled_events (
    id text DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    webhook_conf json NOT NULL,
    scheduled_time timestamp with time zone NOT NULL,
    retry_conf json,
    payload json,
    header_conf json,
    status text DEFAULT 'scheduled'::text NOT NULL,
    tries integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    next_retry_at timestamp with time zone,
    comment text,
    CONSTRAINT valid_status CHECK ((status = ANY (ARRAY['scheduled'::text, 'locked'::text, 'delivered'::text, 'error'::text, 'dead'::text])))
);


ALTER TABLE hdb_catalog.hdb_scheduled_events OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 261054)
-- Name: hdb_schema_notifications; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_schema_notifications (
    id integer NOT NULL,
    notification json NOT NULL,
    resource_version integer DEFAULT 1 NOT NULL,
    instance_id uuid NOT NULL,
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT hdb_schema_notifications_id_check CHECK ((id = 1))
);


ALTER TABLE hdb_catalog.hdb_schema_notifications OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 261062)
-- Name: hdb_source_catalog_version; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_source_catalog_version (
    version text NOT NULL,
    upgraded_on timestamp with time zone NOT NULL
);


ALTER TABLE hdb_catalog.hdb_source_catalog_version OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 261067)
-- Name: hdb_version; Type: TABLE; Schema: hdb_catalog; Owner: postgres
--

CREATE TABLE hdb_catalog.hdb_version (
    hasura_uuid uuid DEFAULT hdb_catalog.gen_hasura_uuid() NOT NULL,
    version text NOT NULL,
    upgraded_on timestamp with time zone NOT NULL,
    cli_state jsonb DEFAULT '{}'::jsonb NOT NULL,
    console_state jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE hdb_catalog.hdb_version OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 261075)
-- Name: email_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    weekly_report boolean DEFAULT true NOT NULL,
    unread_notification_report boolean DEFAULT true NOT NULL,
    invitation boolean DEFAULT true NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.email_notifications OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 261082)
-- Name: events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    type text NOT NULL,
    creator_id uuid NOT NULL,
    payload jsonb
);


ALTER TABLE public.events OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 261090)
-- Name: events_workers_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.events_workers_status (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    creator_id uuid NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    type text NOT NULL,
    status text NOT NULL,
    payload jsonb NOT NULL
);


ALTER TABLE public.events_workers_status OWNER TO postgres;

--
-- TOC entry 5326 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE events_workers_status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.events_workers_status IS 'Will be used to track the status of a designed events in our workers';


--
-- TOC entry 244 (class 1259 OID 261098)
-- Name: file_access_enum; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_access_enum (
    value text NOT NULL,
    description text NOT NULL
);


ALTER TABLE public.file_access_enum OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 261103)
-- Name: file_approvals_status_enum; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_approvals_status_enum (
    value text NOT NULL,
    description text NOT NULL
);


ALTER TABLE public.file_approvals_status_enum OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 261108)
-- Name: file_assignation_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_assignation_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_file_id text NOT NULL,
    new_file_id uuid NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL
);


ALTER TABLE public.file_assignation_migrations OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 261114)
-- Name: file_assignations_orgs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_assignations_orgs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_assignation_id uuid NOT NULL,
    org_id uuid NOT NULL,
    creator_id uuid
);


ALTER TABLE public.file_assignations_orgs OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 261120)
-- Name: file_assignations_teams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_assignations_teams (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_assignation_id uuid NOT NULL,
    team_id uuid NOT NULL,
    creator_id uuid
);


ALTER TABLE public.file_assignations_teams OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 261126)
-- Name: file_assignations_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_assignations_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_assignation_id uuid NOT NULL,
    user_id uuid NOT NULL,
    creator_id uuid
);


ALTER TABLE public.file_assignations_users OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 261132)
-- Name: file_comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_comments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_version_id uuid NOT NULL,
    creator_id uuid NOT NULL,
    file_approval_id uuid,
    content text NOT NULL
);


ALTER TABLE public.file_comments OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 261140)
-- Name: file_label_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_label_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_label_id text NOT NULL,
    new_label_id uuid NOT NULL,
    old_file_id text NOT NULL,
    new_file_id uuid NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL
);


ALTER TABLE public.file_label_migrations OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 261146)
-- Name: file_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL,
    old_folder_id text NOT NULL,
    new_folder_id uuid NOT NULL,
    old_file_id text NOT NULL,
    new_file_id uuid NOT NULL
);


ALTER TABLE public.file_migrations OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 261152)
-- Name: file_permissions_orgs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_permissions_orgs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_permission_id uuid NOT NULL,
    org_id uuid NOT NULL,
    access text NOT NULL
);


ALTER TABLE public.file_permissions_orgs OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 261160)
-- Name: file_permissions_teams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_permissions_teams (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_permission_id uuid NOT NULL,
    team_id uuid NOT NULL,
    access text NOT NULL
);


ALTER TABLE public.file_permissions_teams OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 261168)
-- Name: file_permissions_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_permissions_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_permission_id uuid NOT NULL,
    user_id uuid NOT NULL,
    access text NOT NULL
);


ALTER TABLE public.file_permissions_users OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 261176)
-- Name: file_signatures; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_signatures (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_version_id uuid NOT NULL,
    signed_by uuid NOT NULL,
    signed_at timestamp with time zone NOT NULL
);


ALTER TABLE public.file_signatures OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 261182)
-- Name: file_version_approval_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_version_approval_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL,
    old_folder_id text NOT NULL,
    new_folder_id uuid NOT NULL,
    old_file_id text NOT NULL,
    new_file_id uuid NOT NULL,
    old_file_version_id text NOT NULL,
    new_file_version_id uuid NOT NULL
);


ALTER TABLE public.file_version_approval_migrations OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 261188)
-- Name: file_version_approval_request_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_version_approval_request_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    file_version_approval_request_id uuid NOT NULL,
    file_approval_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.file_version_approval_request_users OWNER TO postgres;

--
-- TOC entry 5327 (class 0 OID 0)
-- Dependencies: 258
-- Name: TABLE file_version_approval_request_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.file_version_approval_request_users IS 'Link -> file_version_approval_requests -> user';


--
-- TOC entry 259 (class 1259 OID 261194)
-- Name: file_version_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_version_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL,
    old_folder_id text NOT NULL,
    new_folder_id uuid NOT NULL,
    old_file_id text NOT NULL,
    new_file_id uuid NOT NULL,
    old_file_version_id text NOT NULL,
    new_file_version_id uuid NOT NULL
);


ALTER TABLE public.file_version_migrations OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 261200)
-- Name: file_version_wopi; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_version_wopi (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_version_id uuid NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    lock_value text,
    lock_expires_at timestamp with time zone
);


ALTER TABLE public.file_version_wopi OWNER TO postgres;

--
-- TOC entry 5328 (class 0 OID 0)
-- Dependencies: 260
-- Name: TABLE file_version_wopi; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.file_version_wopi IS 'Save the WOPI information linked to a file version';

--
-- TOC entry 262 (class 1259 OID 261214)
-- Name: file_views; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_views (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_version_id uuid NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.file_views OWNER TO postgres;

--
-- TOC entry 5329 (class 0 OID 0)
-- Dependencies: 262
-- Name: TABLE file_views; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.file_views IS 'This table record everytime a user viewed a specific version of a file';


--
-- TOC entry 263 (class 1259 OID 261219)
-- Name: file_views_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.file_views_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.file_views_id_seq OWNER TO postgres;

--
-- TOC entry 5330 (class 0 OID 0)
-- Dependencies: 263
-- Name: file_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.file_views_id_seq OWNED BY public.file_views.id;


--
-- TOC entry 264 (class 1259 OID 261220)
-- Name: files_to_project_labels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.files_to_project_labels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_id uuid NOT NULL,
    project_label_id uuid NOT NULL,
    "order" integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.files_to_project_labels OWNER TO postgres;

--
-- TOC entry 5331 (class 0 OID 0)
-- Dependencies: 264
-- Name: TABLE files_to_project_labels; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.files_to_project_labels IS 'relationship table between file and label';


--
-- TOC entry 265 (class 1259 OID 261227)
-- Name: folder_access_enum; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_access_enum (
    value text NOT NULL,
    description text NOT NULL
);


ALTER TABLE public.folder_access_enum OWNER TO postgres;

--
-- TOC entry 5332 (class 0 OID 0)
-- Dependencies: 265
-- Name: TABLE folder_access_enum; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.folder_access_enum IS 'Enum table with the access folder values';


--
-- TOC entry 266 (class 1259 OID 261232)
-- Name: folder_assignation_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_assignation_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_folder_id text NOT NULL,
    new_folder_id uuid NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL
);


ALTER TABLE public.folder_assignation_migrations OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 261238)
-- Name: folder_assignations_orgs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_assignations_orgs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    folder_assignation_id uuid NOT NULL,
    org_id uuid NOT NULL,
    creator_id uuid
);


ALTER TABLE public.folder_assignations_orgs OWNER TO postgres;

--
-- TOC entry 5333 (class 0 OID 0)
-- Dependencies: 267
-- Name: TABLE folder_assignations_orgs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.folder_assignations_orgs IS 'Link folder -> folder_assignations -> org';


--
-- TOC entry 268 (class 1259 OID 261244)
-- Name: folder_assignations_teams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_assignations_teams (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    folder_assignation_id uuid NOT NULL,
    team_id uuid NOT NULL,
    creator_id uuid
);


ALTER TABLE public.folder_assignations_teams OWNER TO postgres;

--
-- TOC entry 5334 (class 0 OID 0)
-- Dependencies: 268
-- Name: TABLE folder_assignations_teams; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.folder_assignations_teams IS 'Link folder -> folder_assignations -> team';


--
-- TOC entry 269 (class 1259 OID 261250)
-- Name: folder_assignations_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_assignations_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    folder_assignation_id uuid NOT NULL,
    user_id uuid NOT NULL,
    creator_id uuid
);


ALTER TABLE public.folder_assignations_users OWNER TO postgres;

--
-- TOC entry 5335 (class 0 OID 0)
-- Dependencies: 269
-- Name: TABLE folder_assignations_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.folder_assignations_users IS 'Link folder -> folder_assignations -> user';


--
-- TOC entry 270 (class 1259 OID 261256)
-- Name: folder_label_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_label_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_label_id text NOT NULL,
    new_label_id uuid NOT NULL,
    old_folder_id text NOT NULL,
    new_folder_id uuid NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL
);


ALTER TABLE public.folder_label_migrations OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 261262)
-- Name: folder_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL,
    old_folder_id text NOT NULL,
    new_folder_id uuid NOT NULL,
    old_parent_id text,
    new_parent_id uuid
);


ALTER TABLE public.folder_migrations OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 261268)
-- Name: folder_permissions_orgs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_permissions_orgs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    folder_permission_id uuid NOT NULL,
    access text NOT NULL,
    org_id uuid NOT NULL,
    creator_id uuid
);


ALTER TABLE public.folder_permissions_orgs OWNER TO postgres;

--
-- TOC entry 5336 (class 0 OID 0)
-- Dependencies: 272
-- Name: TABLE folder_permissions_orgs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.folder_permissions_orgs IS 'Link folder -> folder_permissions -> org';


--
-- TOC entry 273 (class 1259 OID 261276)
-- Name: folder_permissions_teams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_permissions_teams (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    folder_permission_id uuid NOT NULL,
    access text NOT NULL,
    team_id uuid NOT NULL,
    creator_id uuid
);


ALTER TABLE public.folder_permissions_teams OWNER TO postgres;

--
-- TOC entry 5337 (class 0 OID 0)
-- Dependencies: 273
-- Name: TABLE folder_permissions_teams; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.folder_permissions_teams IS 'Link folder -> folder_permissions -> team';


--
-- TOC entry 274 (class 1259 OID 261284)
-- Name: folder_permissions_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_permissions_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    folder_permission_id uuid NOT NULL,
    access text NOT NULL,
    user_id uuid NOT NULL,
    creator_id uuid
);


ALTER TABLE public.folder_permissions_users OWNER TO postgres;

--
-- TOC entry 5338 (class 0 OID 0)
-- Dependencies: 274
-- Name: TABLE folder_permissions_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.folder_permissions_users IS 'Link folder -> folder_permissions -> user';


--
-- TOC entry 275 (class 1259 OID 261292)
-- Name: folder_views; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_views (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    folder_id uuid NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.folder_views OWNER TO postgres;

--
-- TOC entry 5339 (class 0 OID 0)
-- Dependencies: 275
-- Name: TABLE folder_views; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.folder_views IS 'This table record everytime a user viewed a specific folder';


--
-- TOC entry 276 (class 1259 OID 261297)
-- Name: folder_views_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.folder_views_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.folder_views_id_seq OWNER TO postgres;

--
-- TOC entry 5340 (class 0 OID 0)
-- Dependencies: 276
-- Name: folder_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.folder_views_id_seq OWNED BY public.folder_views.id;


--
-- TOC entry 277 (class 1259 OID 261298)
-- Name: folders_to_project_labels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folders_to_project_labels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    folder_id uuid NOT NULL,
    project_label_id uuid NOT NULL,
    "order" integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.folders_to_project_labels OWNER TO postgres;

--
-- TOC entry 5341 (class 0 OID 0)
-- Dependencies: 277
-- Name: TABLE folders_to_project_labels; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.folders_to_project_labels IS 'relationship table between folder and label';


--
-- TOC entry 278 (class 1259 OID 261305)
-- Name: org_address; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_address (
    org_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    street text,
    postal_code text,
    administrative_area_level1 text,
    administrative_area_level2 text,
    country text,
    city text,
    lat double precision,
    lng double precision
);


ALTER TABLE public.org_address OWNER TO postgres;

--
-- TOC entry 5342 (class 0 OID 0)
-- Dependencies: 278
-- Name: TABLE org_address; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.org_address IS 'Address of an org';


--
-- TOC entry 279 (class 1259 OID 261312)
-- Name: org_avatars; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_avatars (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    org_id uuid NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    content_type text,
    extension text,
    size integer
);


ALTER TABLE public.org_avatars OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 261319)
-- Name: org_backgrounds; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_backgrounds (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    org_id uuid NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    content_type text,
    extension text,
    size integer
);


ALTER TABLE public.org_backgrounds OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 261326)
-- Name: org_licenses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_licenses (
    org_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    trial_start_date timestamp with time zone DEFAULT now(),
    trial_end_date timestamp with time zone,
    subscription_start_date timestamp with time zone,
    subscription_end_date timestamp with time zone,
    subscription_plan text,
    "subscription_MRR" integer,
    "subscription_ARR" integer,
    subscription_period text,
    subscription_licences integer,
    activity text
);


ALTER TABLE public.org_licenses OWNER TO postgres;

--
-- TOC entry 5343 (class 0 OID 0)
-- Dependencies: 281
-- Name: TABLE org_licenses; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.org_licenses IS 'Contains basic informations about paying licences of for each org';


--
-- TOC entry 282 (class 1259 OID 261334)
-- Name: org_member_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_member_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_user_id text NOT NULL,
    new_user_id uuid NOT NULL,
    old_org_id text NOT NULL,
    new_org_id uuid NOT NULL
);


ALTER TABLE public.org_member_migrations OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 261340)
-- Name: org_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_org_id text NOT NULL,
    new_org_id uuid NOT NULL
);


ALTER TABLE public.org_migrations OWNER TO postgres;

--
-- TOC entry 5344 (class 0 OID 0)
-- Dependencies: 283
-- Name: TABLE org_migrations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.org_migrations IS 'State table for the migration mongodb org to postgresql (V1 => V2)';


--
-- TOC entry 284 (class 1259 OID 261346)
-- Name: org_project_summary_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_project_summary_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL,
    new_org_id uuid NOT NULL
);


ALTER TABLE public.org_project_summary_migrations OWNER TO postgres;

--
-- TOC entry 285 (class 1259 OID 261352)
-- Name: org_project_summary_to_project_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_project_summary_to_project_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_categories_id uuid NOT NULL,
    org_project_summary_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    "order" integer DEFAULT 0
);


ALTER TABLE public.org_project_summary_to_project_categories OWNER TO postgres;

--
-- TOC entry 5345 (class 0 OID 0)
-- Dependencies: 285
-- Name: TABLE org_project_summary_to_project_categories; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.org_project_summary_to_project_categories IS 'This relation table allow a org_project_summary to contain a subset of project_categories labels';


--
-- TOC entry 286 (class 1259 OID 261359)
-- Name: org_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_roles (
    name text NOT NULL,
    weight integer NOT NULL
);


ALTER TABLE public.org_roles OWNER TO postgres;

--
-- TOC entry 287 (class 1259 OID 261364)
-- Name: orgs_to_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orgs_to_users (
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    org_id uuid NOT NULL,
    inviter_id uuid,
    role_id text NOT NULL,
    updater_id uuid
);


ALTER TABLE public.orgs_to_users OWNER TO postgres;

--
-- TOC entry 288 (class 1259 OID 261371)
-- Name: projects_to_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_to_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid NOT NULL,
    inviter_id uuid,
    project_id uuid NOT NULL,
    role_id text NOT NULL,
    updater_id uuid
);


ALTER TABLE public.projects_to_users OWNER TO postgres;

--
-- TOC entry 289 (class 1259 OID 261379)
-- Name: orgs_projects_users; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.orgs_projects_users AS
 SELECT orgs_privileged_project_members.project_id,
    orgs_privileged_project_members.user_id
   FROM ( SELECT org_members.org_id,
            projects_to_users.project_id,
            unnest(org_members.org_privileged_user_ids) AS user_id
           FROM (public.projects_to_users
             JOIN ( SELECT orgs_to_users.org_id,
                    array_agg(DISTINCT orgs_to_users.user_id) AS org_user_ids,
                    array_agg(DISTINCT orgs_to_users.user_id) FILTER (WHERE (orgs_to_users.role_id = ANY (ARRAY['standard'::text, 'owner'::text, 'administrator'::text]))) AS org_privileged_user_ids
                   FROM public.orgs_to_users
                  GROUP BY orgs_to_users.org_id) org_members ON ((projects_to_users.user_id = ANY (org_members.org_user_ids))))
          WHERE (projects_to_users.role_id <> 'disabled'::text)
          GROUP BY org_members.org_id, projects_to_users.project_id, org_members.org_privileged_user_ids) orgs_privileged_project_members
  GROUP BY orgs_privileged_project_members.project_id, orgs_privileged_project_members.user_id
  WITH NO DATA;


ALTER TABLE public.orgs_projects_users OWNER TO postgres;

--
-- TOC entry 290 (class 1259 OID 261384)
-- Name: orgs_to_user_actions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orgs_to_user_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    org_id uuid NOT NULL,
    user_action_id uuid NOT NULL
);


ALTER TABLE public.orgs_to_user_actions OWNER TO postgres;

--
-- TOC entry 291 (class 1259 OID 261390)
-- Name: presigned_urls; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.presigned_urls (
    key text NOT NULL,
    name text,
    url text NOT NULL,
    expires_at timestamp with time zone NOT NULL
);


ALTER TABLE public.presigned_urls OWNER TO postgres;

--
-- TOC entry 5346 (class 0 OID 0)
-- Dependencies: 291
-- Name: TABLE presigned_urls; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.presigned_urls IS 'Record of all the already generated presigned urls';


--
-- TOC entry 292 (class 1259 OID 261395)
-- Name: project_address; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_address (
    project_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    street text,
    postal_code text,
    administrative_area_level1 text,
    administrative_area_level2 text,
    country text,
    city text,
    lat double precision,
    lng double precision
);


ALTER TABLE public.project_address OWNER TO postgres;

--
-- TOC entry 5347 (class 0 OID 0)
-- Dependencies: 292
-- Name: TABLE project_address; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.project_address IS 'Address of a project';


--
-- TOC entry 293 (class 1259 OID 261402)
-- Name: project_avatars; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_avatars (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    project_id uuid NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    content_type text,
    extension text,
    size integer
);


ALTER TABLE public.project_avatars OWNER TO postgres;

--
-- TOC entry 294 (class 1259 OID 261409)
-- Name: project_backgrounds; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_backgrounds (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    project_id uuid NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    content_type text,
    extension text,
    size integer
);


ALTER TABLE public.project_backgrounds OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 261416)
-- Name: project_banners; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_banners (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    project_id uuid NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    content_type text,
    extension text,
    size integer
);


ALTER TABLE public.project_banners OWNER TO postgres;

--
-- TOC entry 296 (class 1259 OID 261423)
-- Name: project_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    color text NOT NULL,
    org_id uuid NOT NULL
);


ALTER TABLE public.project_categories OWNER TO postgres;

--
-- TOC entry 5348 (class 0 OID 0)
-- Dependencies: 296
-- Name: TABLE project_categories; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.project_categories IS 'This table regroup all project_categories';


--
-- TOC entry 297 (class 1259 OID 261431)
-- Name: project_categories_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_categories_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_id text NOT NULL,
    new_id uuid NOT NULL
);


ALTER TABLE public.project_categories_migrations OWNER TO postgres;

--
-- TOC entry 5349 (class 0 OID 0)
-- Dependencies: 297
-- Name: TABLE project_categories_migrations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.project_categories_migrations IS 'State table for the migration mongodb org to postgresql (V1 => V2)';


--
-- TOC entry 298 (class 1259 OID 261437)
-- Name: project_labels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_labels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    color text NOT NULL,
    project_id uuid NOT NULL,
    "order" integer
);


ALTER TABLE public.project_labels OWNER TO postgres;

--
-- TOC entry 5350 (class 0 OID 0)
-- Dependencies: 298
-- Name: TABLE project_labels; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.project_labels IS 'This table regroup all project_labels';


--
-- TOC entry 299 (class 1259 OID 261445)
-- Name: project_labels_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_labels_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_id text NOT NULL,
    new_id uuid NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL
);


ALTER TABLE public.project_labels_migrations OWNER TO postgres;

--
-- TOC entry 5351 (class 0 OID 0)
-- Dependencies: 299
-- Name: TABLE project_labels_migrations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.project_labels_migrations IS 'State table for the migration mongodb org to postgresql (V1 => V2)';


--
-- TOC entry 300 (class 1259 OID 261451)
-- Name: project_member_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_member_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_user_id text NOT NULL,
    new_user_id uuid NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL
);


ALTER TABLE public.project_member_migrations OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 261457)
-- Name: project_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_id text NOT NULL,
    new_id uuid NOT NULL
);


ALTER TABLE public.project_migrations OWNER TO postgres;

--
-- TOC entry 5352 (class 0 OID 0)
-- Dependencies: 301
-- Name: TABLE project_migrations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.project_migrations IS 'State table for the migration mongodb org to postgresql (V1 => V2)';


--
-- TOC entry 302 (class 1259 OID 261463)
-- Name: project_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_roles (
    name text NOT NULL,
    weight integer NOT NULL
);


ALTER TABLE public.project_roles OWNER TO postgres;

--
-- TOC entry 303 (class 1259 OID 261468)
-- Name: project_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    project_id uuid NOT NULL,
    type text DEFAULT 'generic'::text NOT NULL,
    language text DEFAULT 'en'::text NOT NULL
);


ALTER TABLE public.project_templates OWNER TO postgres;

--
-- TOC entry 5353 (class 0 OID 0)
-- Dependencies: 303
-- Name: TABLE project_templates; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.project_templates IS 'Projects marked as template to create new demo project';

--
-- TOC entry 305 (class 1259 OID 261482)
-- Name: project_views; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_views (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    project_id uuid NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.project_views OWNER TO postgres;

--
-- TOC entry 5354 (class 0 OID 0)
-- Dependencies: 305
-- Name: TABLE project_views; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.project_views IS 'This table record everytime a user viewed a specific project url (docs/infos/tasks/...)';


--
-- TOC entry 306 (class 1259 OID 261487)
-- Name: project_views_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.project_views_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_views_id_seq OWNER TO postgres;

--
-- TOC entry 5355 (class 0 OID 0)
-- Dependencies: 306
-- Name: project_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.project_views_id_seq OWNED BY public.project_views.id;


--
-- TOC entry 307 (class 1259 OID 261488)
-- Name: push_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.push_notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    chat_channel boolean DEFAULT true NOT NULL,
    chat_direct_message boolean DEFAULT true NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.push_notifications OWNER TO postgres;

--
-- TOC entry 308 (class 1259 OID 261496)
-- Name: subtask_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subtask_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_id text NOT NULL,
    new_id uuid NOT NULL,
    old_task_id text NOT NULL,
    new_task_id uuid NOT NULL,
    old_project_id text,
    new_project_id uuid
);


ALTER TABLE public.subtask_migrations OWNER TO postgres;

--
-- TOC entry 309 (class 1259 OID 261502)
-- Name: task_assignation_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_assignation_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_task_id text NOT NULL,
    new_task_id uuid NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL
);


ALTER TABLE public.task_assignation_migrations OWNER TO postgres;

--
-- TOC entry 310 (class 1259 OID 261508)
-- Name: task_assignations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_assignations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    task_id uuid NOT NULL
);


ALTER TABLE public.task_assignations OWNER TO postgres;

--
-- TOC entry 311 (class 1259 OID 261514)
-- Name: task_assignations_orgs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_assignations_orgs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    task_assignation_id uuid NOT NULL,
    org_id uuid NOT NULL,
    creator_id uuid
);


ALTER TABLE public.task_assignations_orgs OWNER TO postgres;

--
-- TOC entry 312 (class 1259 OID 261520)
-- Name: task_assignations_teams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_assignations_teams (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    task_assignation_id uuid NOT NULL,
    team_id uuid NOT NULL,
    creator_id uuid
);


ALTER TABLE public.task_assignations_teams OWNER TO postgres;

--
-- TOC entry 313 (class 1259 OID 261526)
-- Name: task_assignations_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_assignations_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    task_assignation_id uuid NOT NULL,
    user_id uuid NOT NULL,
    creator_id uuid
);


ALTER TABLE public.task_assignations_users OWNER TO postgres;

--
-- TOC entry 314 (class 1259 OID 261532)
-- Name: task_attachment_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_attachment_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_key_prefix text NOT NULL,
    new_key_prefix text NOT NULL,
    old_task_id text NOT NULL,
    new_task_id uuid NOT NULL
);


ALTER TABLE public.task_attachment_migrations OWNER TO postgres;

--
-- TOC entry 315 (class 1259 OID 261538)
-- Name: task_attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    task_id uuid NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    creator_id uuid NOT NULL,
    content_type text,
    extension text,
    size integer
);


ALTER TABLE public.task_attachments OWNER TO postgres;

--
-- TOC entry 5356 (class 0 OID 0)
-- Dependencies: 315
-- Name: TABLE task_attachments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.task_attachments IS 'This table is the attachment task part';


--
-- TOC entry 316 (class 1259 OID 261546)
-- Name: task_file_version_location; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_file_version_location (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    page_number integer NOT NULL,
    x numeric NOT NULL,
    y numeric NOT NULL
);


ALTER TABLE public.task_file_version_location OWNER TO postgres;

--
-- TOC entry 5357 (class 0 OID 0)
-- Dependencies: 316
-- Name: TABLE task_file_version_location; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.task_file_version_location IS 'Location of a task on a file version';


--
-- TOC entry 317 (class 1259 OID 261554)
-- Name: task_label_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_label_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_label_id text NOT NULL,
    new_label_id uuid NOT NULL,
    old_task_id text NOT NULL,
    new_task_id uuid NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL
);


ALTER TABLE public.task_label_migrations OWNER TO postgres;

--
-- TOC entry 318 (class 1259 OID 261560)
-- Name: task_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_locations (
    task_id uuid NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL
);


ALTER TABLE public.task_locations OWNER TO postgres;

--
-- TOC entry 5358 (class 0 OID 0)
-- Dependencies: 318
-- Name: TABLE task_locations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.task_locations IS 'GPS location of a task';


--
-- TOC entry 319 (class 1259 OID 261563)
-- Name: task_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_id text NOT NULL,
    new_id uuid NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL
);


ALTER TABLE public.task_migrations OWNER TO postgres;

--
-- TOC entry 320 (class 1259 OID 261569)
-- Name: task_subtasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_subtasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    creator_id uuid NOT NULL,
    task_id uuid NOT NULL,
    closed boolean DEFAULT false,
    description text NOT NULL,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    "order" integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.task_subtasks OWNER TO postgres;

--
-- TOC entry 5359 (class 0 OID 0)
-- Dependencies: 320
-- Name: TABLE task_subtasks; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.task_subtasks IS 'This table groups the subtasks';


--
-- TOC entry 321 (class 1259 OID 261579)
-- Name: task_validation_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_validation_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_task_id text NOT NULL,
    new_task_id uuid NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL
);


ALTER TABLE public.task_validation_migrations OWNER TO postgres;

--
-- TOC entry 322 (class 1259 OID 261585)
-- Name: task_validations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_validations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    task_id uuid NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.task_validations OWNER TO postgres;

--
-- TOC entry 5360 (class 0 OID 0)
-- Dependencies: 322
-- Name: TABLE task_validations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.task_validations IS 'This table groups the users validated task';


--
-- TOC entry 323 (class 1259 OID 261591)
-- Name: task_views; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_views (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    task_id uuid NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.task_views OWNER TO postgres;

--
-- TOC entry 5361 (class 0 OID 0)
-- Dependencies: 323
-- Name: TABLE task_views; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.task_views IS 'This table record everytime a user viewed a specific task';


--
-- TOC entry 324 (class 1259 OID 261596)
-- Name: task_views_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.task_views_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.task_views_id_seq OWNER TO postgres;

--
-- TOC entry 5362 (class 0 OID 0)
-- Dependencies: 324
-- Name: task_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.task_views_id_seq OWNED BY public.task_views.id;


--
-- TOC entry 325 (class 1259 OID 261597)
-- Name: tasks_file_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tasks_file_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    task_id uuid NOT NULL,
    file_version_id uuid NOT NULL,
    task_location_id uuid
);


ALTER TABLE public.tasks_file_versions OWNER TO postgres;

--
-- TOC entry 5363 (class 0 OID 0)
-- Dependencies: 325
-- Name: TABLE tasks_file_versions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.tasks_file_versions IS 'File versions attached to a task';


--
-- TOC entry 326 (class 1259 OID 261603)
-- Name: tasks_to_project_labels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tasks_to_project_labels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    task_id uuid NOT NULL,
    project_label_id uuid NOT NULL,
    "order" integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.tasks_to_project_labels OWNER TO postgres;

--
-- TOC entry 5364 (class 0 OID 0)
-- Dependencies: 326
-- Name: TABLE tasks_to_project_labels; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.tasks_to_project_labels IS 'Relationship table between task and label';


--
-- TOC entry 327 (class 1259 OID 261610)
-- Name: team_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.team_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_id text NOT NULL,
    new_id uuid NOT NULL,
    old_project_id text NOT NULL,
    new_project_id uuid NOT NULL
);


ALTER TABLE public.team_migrations OWNER TO postgres;

--
-- TOC entry 328 (class 1259 OID 261616)
-- Name: teams_to_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teams_to_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid NOT NULL,
    team_id uuid NOT NULL
);


ALTER TABLE public.teams_to_users OWNER TO postgres;

--
-- TOC entry 329 (class 1259 OID 261622)
-- Name: user_actions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    creator_id uuid NOT NULL,
    event_id uuid,
    type text NOT NULL,
    payload jsonb NOT NULL
);


ALTER TABLE public.user_actions OWNER TO postgres;

--
-- TOC entry 330 (class 1259 OID 261630)
-- Name: user_avatars; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_avatars (
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    content_type text,
    extension text,
    size integer
);


ALTER TABLE public.user_avatars OWNER TO postgres;

--
-- TOC entry 331 (class 1259 OID 261637)
-- Name: user_connections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_connections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid NOT NULL,
    ip text NOT NULL,
    browser_name text,
    browser_version text,
    device_model text,
    device_type text,
    device_vendor text,
    os_name text,
    os_version text,
    engine_name text,
    engine_version text,
    cpu text,
    is_manual_login boolean
);


ALTER TABLE public.user_connections OWNER TO postgres;

--
-- TOC entry 333 (class 1259 OID 261649)
-- Name: user_devices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_devices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    app_version text NOT NULL,
    firebase_token text NOT NULL,
    manufacturer text NOT NULL,
    model text NOT NULL,
    operating_system text NOT NULL,
    os_version text NOT NULL,
    platform text NOT NULL,
    user_agent text NOT NULL,
    webview_version text NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.user_devices OWNER TO postgres;

--
-- TOC entry 334 (class 1259 OID 261657)
-- Name: user_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid NOT NULL,
    user_connection_id uuid NOT NULL,
    country_code text,
    country_code3 text,
    country_name text,
    city_name text,
    latitude double precision,
    longitude double precision,
    time_zone text,
    continent_code text
);


ALTER TABLE public.user_locations OWNER TO postgres;

--
-- TOC entry 335 (class 1259 OID 261665)
-- Name: user_metadatas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_metadatas (
    placeholder_company_name text,
    user_id uuid NOT NULL,
    browser_language text,
    app_mobile_installed boolean,
    app_desktop_installed boolean,
    country_code text,
    legal_number text,
    standard_industrial_classification text,
    city text,
    postal_code text,
    latitude integer,
    longitude integer,
    size_min integer,
    size_max integer,
    creation_date date
);


ALTER TABLE public.user_metadatas OWNER TO postgres;

--
-- TOC entry 5365 (class 0 OID 0)
-- Dependencies: 335
-- Name: TABLE user_metadatas; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_metadatas IS 'External metadatas for users like placeholder company';


--
-- TOC entry 336 (class 1259 OID 261670)
-- Name: user_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_migrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    old_user_id text NOT NULL,
    new_user_id uuid NOT NULL
);


ALTER TABLE public.user_migrations OWNER TO postgres;

--
-- TOC entry 5366 (class 0 OID 0)
-- Dependencies: 336
-- Name: TABLE user_migrations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_migrations IS 'State table for the migration mongodb to postgresql (V1 => V2)';


--
-- TOC entry 337 (class 1259 OID 261676)
-- Name: user_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    creator_id uuid NOT NULL,
    recipient_id uuid NOT NULL,
    event_id uuid,
    read_at timestamp with time zone,
    is_strong boolean DEFAULT false NOT NULL,
    type text NOT NULL,
    payload jsonb NOT NULL
);


ALTER TABLE public.user_notifications OWNER TO postgres;


--
-- TOC entry 212 (class 1259 OID 260740)
-- Name: folder_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    folder_id uuid NOT NULL,
    inherited_from uuid
);


--
-- TOC entry 213 (class 1259 OID 260749)
-- Name: file_assignations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_assignations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_id uuid NOT NULL
);


ALTER TABLE public.file_assignations OWNER TO postgres;
--
-- TOC entry 214 (class 1259 OID 260756)
-- Name: files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.files (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    parent_id uuid NOT NULL,
    project_id uuid NOT NULL,
    name text NOT NULL,
    is_approval_mode boolean DEFAULT false NOT NULL,
    due_date timestamp with time zone
);

--
-- TOC entry 215 (class 1259 OID 260765)
-- Name: orgs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orgs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    description text,
    legal_number text,
    phone text,
    project_id uuid
);


--
-- TOC entry 216 (class 1259 OID 260774)
-- Name: teams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teams (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    color text NOT NULL,
    project_id uuid NOT NULL,
    creator_id uuid NOT NULL
);

--
-- TOC entry 217 (class 1259 OID 260783)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    auth0_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    email text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    phone text,
    is_connected boolean DEFAULT false NOT NULL,
    language text DEFAULT 'en'::text NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    wopi_user_info text,
    stream_user_id text DEFAULT gen_random_uuid() NOT NULL,
    is_legacy_user boolean DEFAULT false NOT NULL,
    timezone text DEFAULT 'Europe/Paris'::text NOT NULL,
    is_locked boolean DEFAULT false NOT NULL
);


--
-- TOC entry 332 (class 1259 OID 261645)
-- Name: user_contact; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.user_contact AS
 SELECT users.id,
    users.email,
    users.phone
   FROM public.users;


ALTER TABLE public.user_contact OWNER TO postgres;


--
-- TOC entry 218 (class 1259 OID 260800)
-- Name: file_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_id uuid NOT NULL
);
--
-- TOC entry 219 (class 1259 OID 260810)
-- Name: file_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_id uuid NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    number integer DEFAULT 0 NOT NULL,
    creator_id uuid NOT NULL,
    content_type text DEFAULT 'binary/octet-stream'::text NOT NULL,
    extension text DEFAULT 'bin'::text NOT NULL,
    size integer,
    is_annotated boolean DEFAULT false NOT NULL
);

--
-- TOC entry 220 (class 1259 OID 260823)
-- Name: file_version_approval_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_version_approval_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    file_version_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

--
-- TOC entry 221 (class 1259 OID 260832)
-- Name: folder_assignations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_assignations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    folder_id uuid NOT NULL
);



--
-- TOC entry 222 (class 1259 OID 260839)
-- Name: folders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    parent_id uuid,
    project_id uuid NOT NULL,
    root boolean DEFAULT false,
    root_bin boolean DEFAULT false,
    creator_id uuid,
    CONSTRAINT valid_folder_root_parent_constraint CHECK ((((parent_id IS NULL) AND ((root = true) OR (root_bin = true))) OR ((parent_id IS NOT NULL) AND ((root = false) AND (root_bin = false)) AND (parent_id <> id))))
);

--
-- TOC entry 223 (class 1259 OID 260857)
-- Name: t_folder_pwd; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_folder_pwd (
    id uuid NOT NULL,
    name text NOT NULL,
    level integer NOT NULL
);



--
-- TOC entry 224 (class 1259 OID 260867)
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name character varying NOT NULL,
    description text,
    is_demo boolean DEFAULT false NOT NULL,
    is_archived boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    creator_id uuid
);


--
-- TOC entry 304 (class 1259 OID 261478)
-- Name: project_templates_overview; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.project_templates_overview AS
 SELECT projects.id,
    projects.created_at,
    projects.updated_at,
    projects.name,
    projects.description,
    projects.is_demo,
    projects.is_archived,
    projects.deleted_at,
    projects.creator_id,
    project_templates.type,
    project_templates.language
   FROM (public.projects
     JOIN public.project_templates ON ((projects.id = project_templates.project_id)));


ALTER TABLE public.project_templates_overview OWNER TO postgres;


--
-- TOC entry 226 (class 1259 OID 260891)
-- Name: file_approvals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_approvals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    file_version_id uuid NOT NULL,
    status text NOT NULL,
    user_id uuid NOT NULL
);

--
-- TOC entry 261 (class 1259 OID 261209)
-- Name: file_versions_approvals_overview; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.file_versions_approvals_overview AS
 SELECT approvals_overview.file_version_id,
    approvals_overview.is_completed,
    approvals_overview.is_approved_with_comments,
    approvals_overview.is_approved_without_comments,
    approvals_overview.is_denied
   FROM ( SELECT file_approvals.file_version_id,
            (count(*) FILTER (WHERE (file_version_approval_request_users.file_approval_id IS NULL)) = 0) AS is_completed,
            (count(*) FILTER (WHERE (file_approvals.status = 'APPROVED_WITH_COMMENTS'::text)) > 0) AS is_approved_with_comments,
            (count(*) FILTER (WHERE (file_approvals.status = 'APPROVED_WITHOUT_COMMENTS'::text)) > 0) AS is_approved_without_comments,
            (count(*) FILTER (WHERE (file_approvals.status = 'DENIED'::text)) > 0) AS is_denied
           FROM ((public.file_version_approval_requests
             LEFT JOIN public.file_version_approval_request_users ON ((file_version_approval_request_users.file_version_approval_request_id = file_version_approval_requests.id)))
             JOIN public.file_approvals ON ((file_approvals.file_version_id = file_version_approval_requests.file_version_id)))
          GROUP BY file_approvals.file_version_id) approvals_overview
  WITH NO DATA;


ALTER TABLE public.file_versions_approvals_overview OWNER TO postgres;
--
-- TOC entry 227 (class 1259 OID 260900)
-- Name: t_folder_notification_badge; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t_folder_notification_badge (
    folder_id uuid NOT NULL,
    strong_notification_count numeric NOT NULL,
    weak_notification boolean NOT NULL
);

--
-- TOC entry 228 (class 1259 OID 260907)
-- Name: org_project_summary; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_project_summary (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    org_id uuid NOT NULL,
    project_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    reference text,
    client_fullname text,
    client_phone_number text,
    client_email text,
    price_estimate text
);


--
-- TOC entry 229 (class 1259 OID 260924)
-- Name: tasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    number integer DEFAULT 0 NOT NULL,
    description text NOT NULL,
    creator_id uuid NOT NULL,
    project_id uuid NOT NULL,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    deleted_at timestamp with time zone,
    deleted boolean DEFAULT false NOT NULL
);



ALTER TABLE public.folder_permissions OWNER TO postgres;

--
-- TOC entry 5315 (class 0 OID 0)
-- Dependencies: 212
-- Name: TABLE folder_permissions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.folder_permissions IS 'Intermediate table that link folder to user, org, team permission';

--
-- TOC entry 4242 (class 2604 OID 261685)
-- Name: file_views id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_views ALTER COLUMN id SET DEFAULT nextval('public.file_views_id_seq'::regclass);


--
-- TOC entry 4270 (class 2604 OID 261686)
-- Name: folder_views id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_views ALTER COLUMN id SET DEFAULT nextval('public.folder_views_id_seq'::regclass);


--
-- TOC entry 4324 (class 2604 OID 261687)
-- Name: project_views id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_views ALTER COLUMN id SET DEFAULT nextval('public.project_views_id_seq'::regclass);


--
-- TOC entry 4364 (class 2604 OID 261688)
-- Name: task_views id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_views ALTER COLUMN id SET DEFAULT nextval('public.task_views_id_seq'::regclass);

--
-- TOC entry 396 (class 1255 OID 260724)
-- Name: clean_users_phone(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.clean_users_phone() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Remove each character that is not + or 0-9
    UPDATE users SET phone=REGEXP_REPLACE(phone,'[^\+\d]','','g') WHERE phone != '';
    -- Convert each empty string to NULL
    UPDATE users SET phone=NULL WHERE phone = '';
END;
$$;


ALTER FUNCTION public.clean_users_phone() OWNER TO postgres;

--
-- TOC entry 397 (class 1255 OID 260725)
-- Name: cleanup_files_assignations(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cleanup_files_assignations() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- For all files with empty assignations, remove the file_assignation entry
	DELETE FROM file_assignations
	WHERE
		file_assignations.id IN (
			SELECT
				file_assignations.id
			FROM file_assignations
			LEFT JOIN file_assignations_orgs  ON file_assignations.id = file_assignations_orgs.file_assignation_id
			LEFT JOIN file_assignations_teams ON file_assignations.id = file_assignations_teams.file_assignation_id
			LEFT JOIN file_assignations_users ON file_assignations.id = file_assignations_users.file_assignation_id
			WHERE
				(
					file_assignations_orgs.org_id IS NULL AND
					file_assignations_teams.team_id IS NULL AND
					file_assignations_users.user_id IS NULL
				)
	);
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.cleanup_files_assignations() OWNER TO postgres;

--
-- TOC entry 398 (class 1255 OID 260726)
-- Name: cleanup_files_folders_permissions_assignations(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cleanup_files_folders_permissions_assignations() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
	PERFORM cleanup_files_permissions();
	PERFORM cleanup_folders_permissions();
	PERFORM cleanup_files_assignations();
	PERFORM cleanup_folders_assignations();
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.cleanup_files_folders_permissions_assignations() OWNER TO postgres;

--
-- TOC entry 399 (class 1255 OID 260727)
-- Name: cleanup_files_permissions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cleanup_files_permissions() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- For all files with empty permissions, remove the file_permissions entry
	DELETE FROM file_permissions
	WHERE
		file_permissions.id IN (
			SELECT
				file_permissions.id
			FROM file_permissions
			LEFT JOIN file_permissions_orgs  ON file_permissions.id = file_permissions_orgs.file_permission_id
			LEFT JOIN file_permissions_teams ON file_permissions.id = file_permissions_teams.file_permission_id
			LEFT JOIN file_permissions_users ON file_permissions.id = file_permissions_users.file_permission_id
			WHERE
				(
					file_permissions_orgs.org_id IS NULL AND
					file_permissions_teams.team_id IS NULL AND
					file_permissions_users.user_id IS NULL
				)
	);
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.cleanup_files_permissions() OWNER TO postgres;

--
-- TOC entry 400 (class 1255 OID 260728)
-- Name: cleanup_folders_assignations(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cleanup_folders_assignations() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- For all folders with empty assignations, remove the folder_assignation entry
	DELETE FROM folder_assignations
	WHERE
		folder_assignations.id IN (
			SELECT
				folder_assignations.id
			FROM folder_assignations
			LEFT JOIN folder_assignations_orgs  ON folder_assignations.id = folder_assignations_orgs.folder_assignation_id
			LEFT JOIN folder_assignations_teams ON folder_assignations.id = folder_assignations_teams.folder_assignation_id
			LEFT JOIN folder_assignations_users ON folder_assignations.id = folder_assignations_users.folder_assignation_id
			WHERE
				(
					folder_assignations_orgs.org_id IS NULL AND
					folder_assignations_teams.team_id IS NULL AND
					folder_assignations_users.user_id IS NULL
				)
	);
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.cleanup_folders_assignations() OWNER TO postgres;

--
-- TOC entry 401 (class 1255 OID 260729)
-- Name: cleanup_folders_permissions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cleanup_folders_permissions() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- For all folders with some inherited_from but also with direct permissions, set the inherited_from to NULL
	UPDATE folder_permissions
	SET inherited_from = NULL
	WHERE
		folder_permissions.id IN (
		SELECT
			folder_permissions.id
		FROM folder_permissions
		LEFT JOIN folder_permissions_orgs  ON folder_permissions.id = folder_permissions_orgs.folder_permission_id
		LEFT JOIN folder_permissions_teams ON folder_permissions.id = folder_permissions_teams.folder_permission_id
		LEFT JOIN folder_permissions_users ON folder_permissions.id = folder_permissions_users.folder_permission_id
		WHERE
			folder_permissions.inherited_from IS NOT NULL AND
			(
				folder_permissions_orgs.org_id IS NOT NULL OR
				folder_permissions_teams.team_id IS NOT NULL OR
				folder_permissions_users.user_id IS NOT NULL
			)
	);
	-- For all folders with "inherited_from" is NULL and NO direct permissions, delete the row from folder_permissions table
	DELETE FROM folder_permissions
	WHERE
		folder_permissions.id IN (
			SELECT
				folder_permissions.id
			FROM folder_permissions
			LEFT JOIN folder_permissions_orgs  ON folder_permissions.id = folder_permissions_orgs.folder_permission_id
			LEFT JOIN folder_permissions_teams ON folder_permissions.id = folder_permissions_teams.folder_permission_id
			LEFT JOIN folder_permissions_users ON folder_permissions.id = folder_permissions_users.folder_permission_id
			WHERE
				folder_permissions.inherited_from IS NULL AND
				(
					folder_permissions_orgs.org_id IS NULL AND
					folder_permissions_teams.team_id IS NULL AND
					folder_permissions_users.user_id IS NULL
				)
	);
	-- For all folders where inherited_from doesn't point to a folder with permissions anymore, delete thems
	DELETE FROM folder_permissions
	WHERE
		folder_permissions.id IN (
			SELECT
				folder_permissions.id
			FROM folder_permissions
			LEFT JOIN folder_permissions AS inherit_perms ON folder_permissions.inherited_from = inherit_perms.folder_id
			WHERE
				folder_permissions.inherited_from IS NOT NULL AND
				inherit_perms.id IS NULL
	);
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.cleanup_folders_permissions() OWNER TO postgres;

--
-- TOC entry 402 (class 1255 OID 260730)
-- Name: copy_all_inherited_permissions_on_file(uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.copy_all_inherited_permissions_on_file(parent_project_id uuid, dest_file_parent_id uuid, dest_file_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	dest_folder_permissions folder_permissions;
	dest_file_permissions file_permissions;
	permission_record record;
	dest_file_permission_id uuid;
BEGIN
	dest_file_permissions := get_file_permission(dest_file_id);
	-- File already have direct non-empty permissions, do not copy the inherited
	IF dest_file_permissions.id IS NOT NULL THEN
		-- RAISE NOTICE 'file have direct permissions, no need to copy inherited';
		RETURN TRUE;
	ELSE
		-- Check if a permssions apply to the file via his folder location
		dest_folder_permissions := get_folder_permission(dest_file_parent_id);
		-- RAISE NOTICE 'file have not direct permissions, folder have permissions: %', dest_folder_permissions;
		-- No need to do anything, no permissions applies to the file in hierarchy
		IF dest_folder_permissions.id IS NULL THEN
			RETURN TRUE;
		ELSE
			-- Some permssions apply on the folder the file is in, check if it's inherited or direct
			IF dest_folder_permissions.inherited_from IS NOT NULL THEN
				-- If permissions are inherited, get the original permissions set to extract all values from it
				dest_folder_permissions := get_direct_folder_permission(dest_folder_permissions.inherited_from);
			END IF;
			-- RAISE NOTICE 'folder final permissions found, %', dest_folder_permissions;
			-- Create our file_permission group to put all permissions in it
			INSERT INTO file_permissions(file_id) VALUES (dest_file_id) RETURNING (id) INTO dest_file_permission_id;
			-- Upsert all the orgs permissions
			FOR permission_record IN (
					SELECT org_id, access
					FROM folder_permissions_orgs
					WHERE folder_permissions_orgs.folder_permission_id = dest_folder_permissions.id
				) LOOP
				-- RAISE NOTICE 'file insert orgs permissions, %', permission_record;
				INSERT INTO file_permissions_orgs(file_permission_id, org_id, access)
				VALUES (dest_file_permission_id, permission_record.org_id, permission_record.access)
				ON CONFLICT ON CONSTRAINT unique_org_by_file_permission_id DO NOTHING;
			END LOOP;
			-- Upsert all the teams permissions
			FOR permission_record IN (
					SELECT team_id, access
					FROM folder_permissions_teams
					WHERE folder_permissions_teams.folder_permission_id = dest_folder_permissions.id
				) LOOP
				-- RAISE NOTICE 'file insert teams permissions, %', permission_record;
				INSERT INTO file_permissions_teams(file_permission_id, team_id, access)
				VALUES (dest_file_permission_id, permission_record.team_id, permission_record.access)
				ON CONFLICT ON CONSTRAINT unique_team_by_file_permission_id DO NOTHING;
			END LOOP;
			-- Upsert all the users permissions
			FOR permission_record IN (
					SELECT user_id, access
					FROM folder_permissions_users
					WHERE folder_permissions_users.folder_permission_id = dest_folder_permissions.id
				) LOOP
				-- RAISE NOTICE 'file insert users permissions, %', permission_record;
				INSERT INTO file_permissions_users(file_permission_id, user_id, access)
				VALUES (dest_file_permission_id, permission_record.user_id, permission_record.access)
				ON CONFLICT ON CONSTRAINT unique_user_by_file_permission_id DO NOTHING;
			END LOOP;
			PERFORM cleanup_files_permissions();
		END IF;
	END IF;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.copy_all_inherited_permissions_on_file(parent_project_id uuid, dest_file_parent_id uuid, dest_file_id uuid) OWNER TO postgres;

--
-- TOC entry 403 (class 1255 OID 260731)
-- Name: copy_approvals_requests_after_new_version_created(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.copy_approvals_requests_after_new_version_created() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	is_file_approval_mode boolean;
	current_file_assignations file_assignations;
	approvals_requests_id uuid;
	user_request_to_create_id uuid;
BEGIN
	IF NEW.file_id IS NOT NULL THEN
		is_file_approval_mode := (SELECT files.is_approval_mode FROM files WHERE files.id = NEW.file_id);
		IF is_file_approval_mode IS TRUE THEN
			INSERT INTO file_version_approval_requests(file_version_id) VALUES (NEW.id) RETURNING (id) INTO approvals_requests_id;
			current_file_assignations := get_file_assignations(NEW.file_id);
			IF current_file_assignations.id IS NOT NULL THEN
				FOR user_request_to_create_id IN (SELECT file_assignations_users.user_id FROM file_assignations_users WHERE file_assignations_users.file_assignation_id = current_file_assignations.id) LOOP
					INSERT INTO file_version_approval_request_users(file_version_approval_request_id, user_id) VALUES (approvals_requests_id, user_request_to_create_id) ON CONFLICT DO NOTHING;
				END LOOP;
			END IF;
		END IF;
	END IF;
	RETURN NEW;
END
$$;


ALTER FUNCTION public.copy_approvals_requests_after_new_version_created() OWNER TO postgres;

--
-- TOC entry 404 (class 1255 OID 260732)
-- Name: copy_inherited_from_permissions_on_folder(uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.copy_inherited_from_permissions_on_folder(parent_project_id uuid, inherited_from_folder uuid, dest_folder_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	inherited_from_unnested_permissions record;
	dest_folder_permissions folder_permissions;
	inherited_folder_permissions folder_permissions;
	permission_record record;
	dest_folder_permission_id uuid;
BEGIN
	inherited_folder_permissions := get_folder_permission(inherited_from_folder);
	dest_folder_permissions := get_direct_folder_permission(dest_folder_id);
	IF dest_folder_permissions.id IS NOT NULL THEN
		dest_folder_permission_id := dest_folder_permissions.id;
	ELSE
		-- Create the permission group for the destination folder
		INSERT INTO folder_permissions(folder_id, inherited_from) VALUES (dest_folder_id, NULL)  RETURNING (id) INTO dest_folder_permission_id;
	END IF;
	-- Upsert all the orgs permissions
	FOR permission_record IN (
			SELECT org_id, access
			FROM folder_permissions_orgs
			WHERE folder_permissions_orgs.folder_permission_id = inherited_folder_permissions.id
		) LOOP
		INSERT INTO folder_permissions_orgs(folder_permission_id, org_id, access)
		VALUES (dest_folder_permission_id, permission_record.org_id, permission_record.access)
		ON CONFLICT ON CONSTRAINT unique_org_by_folder_permission_id DO NOTHING;
	END LOOP;
	-- Upsert all the teams permissions
	FOR permission_record IN (
			SELECT team_id, access
			FROM folder_permissions_teams
			WHERE folder_permissions_teams.folder_permission_id = inherited_folder_permissions.id
		) LOOP
		INSERT INTO folder_permissions_teams(folder_permission_id, team_id, access)
		VALUES (dest_folder_permission_id, permission_record.team_id, permission_record.access)
		ON CONFLICT ON CONSTRAINT unique_team_by_folder_permission_id DO NOTHING;
	END LOOP;
	-- Upsert all the users permissions
	FOR permission_record IN (
			SELECT user_id, access
			FROM folder_permissions_users
			WHERE folder_permissions_users.folder_permission_id = inherited_folder_permissions.id
		) LOOP
		INSERT INTO folder_permissions_users(folder_permission_id, user_id, access)
		VALUES (dest_folder_permission_id, permission_record.user_id, permission_record.access)
		ON CONFLICT ON CONSTRAINT unique_user_by_folder_permission_id DO NOTHING;
	END LOOP;
	UPDATE folder_permissions SET inherited_from = NULL WHERE folder_permissions.id = dest_folder_permission_id;
	PERFORM cleanup_folders_permissions();
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.copy_inherited_from_permissions_on_folder(parent_project_id uuid, inherited_from_folder uuid, dest_folder_id uuid) OWNER TO postgres;

--
-- TOC entry 405 (class 1255 OID 260733)
-- Name: count_all_folder_permissions(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.count_all_folder_permissions(permission_id uuid, OUT result record) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
	SELECT
		COALESCE(COUNT(DISTINCT folder_permissions_orgs.id), 0) AS orgs,
		COALESCE(COUNT(DISTINCT folder_permissions_teams.id), 0) AS teams,
		COALESCE(COUNT(DISTINCT folder_permissions_users.id), 0) AS users
	FROM folder_permissions
	LEFT JOIN folder_permissions_orgs ON folder_permissions_orgs.folder_permission_id = permission_id
	LEFT JOIN folder_permissions_teams ON folder_permissions_teams.folder_permission_id = permission_id
	LEFT JOIN folder_permissions_users ON folder_permissions_users.folder_permission_id = permission_id
	WHERE folder_permissions.id = permission_id INTO result;
END
$$;


ALTER FUNCTION public.count_all_folder_permissions(permission_id uuid, OUT result record) OWNER TO postgres;

--
-- TOC entry 406 (class 1255 OID 260734)
-- Name: count_file_conflicting_permissions(uuid[], uuid[], uuid[], uuid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.count_file_conflicting_permissions(parent_file_perms_orgs uuid[], parent_file_perms_teams uuid[], parent_file_perms_possibles_users uuid[], permission_ids uuid[], OUT orgs numeric, OUT teams numeric, OUT users numeric) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
	SELECT COALESCE(COUNT(DISTINCT file_permissions_orgs.id), 0) FROM
		file_permissions_orgs
	WHERE
		file_permissions_orgs.file_permission_id = ANY(permission_ids) AND
		NOT file_permissions_orgs.org_id = ANY(parent_file_perms_orgs)
	INTO orgs;
	SELECT COALESCE(COUNT(DISTINCT file_permissions_teams.id), 0) FROM
		file_permissions_teams
	WHERE
		file_permissions_teams.file_permission_id = ANY(permission_ids) AND
		NOT file_permissions_teams.team_id = ANY(parent_file_perms_teams)
	INTO teams;
	SELECT COALESCE(COUNT(DISTINCT file_permissions_users.id), 0) FROM
		file_permissions_users
	WHERE
		file_permissions_users.file_permission_id = ANY(permission_ids) AND
		NOT file_permissions_users.user_id = ANY(parent_file_perms_possibles_users)
	INTO users;
END
$$;


ALTER FUNCTION public.count_file_conflicting_permissions(parent_file_perms_orgs uuid[], parent_file_perms_teams uuid[], parent_file_perms_possibles_users uuid[], permission_ids uuid[], OUT orgs numeric, OUT teams numeric, OUT users numeric) OWNER TO postgres;

--
-- TOC entry 408 (class 1255 OID 260735)
-- Name: count_folder_conflicting_permissions(uuid[], uuid[], uuid[], uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.count_folder_conflicting_permissions(parent_folder_perms_orgs uuid[], parent_folder_perms_teams uuid[], parent_folder_perms_possibles_users uuid[], permission_id uuid, OUT orgs numeric, OUT teams numeric, OUT users numeric) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
	SELECT COALESCE(COUNT(DISTINCT folder_permissions_orgs.id), 0) FROM
		folder_permissions_orgs
	WHERE
		folder_permissions_orgs.folder_permission_id = permission_id AND
		NOT folder_permissions_orgs.org_id = ANY(parent_folder_perms_orgs)
	INTO orgs;
	SELECT COALESCE(COUNT(DISTINCT folder_permissions_teams.id), 0) FROM
		folder_permissions_teams
	WHERE
		folder_permissions_teams.folder_permission_id = permission_id AND
		NOT folder_permissions_teams.team_id = ANY(parent_folder_perms_teams)
	INTO teams;
	SELECT COALESCE(COUNT(DISTINCT folder_permissions_users.id), 0) FROM
		folder_permissions_users
	WHERE
		folder_permissions_users.folder_permission_id = permission_id AND
		NOT folder_permissions_users.user_id = ANY(parent_folder_perms_possibles_users)
	INTO users;
END
$$;


ALTER FUNCTION public.count_folder_conflicting_permissions(parent_folder_perms_orgs uuid[], parent_folder_perms_teams uuid[], parent_folder_perms_possibles_users uuid[], permission_id uuid, OUT orgs numeric, OUT teams numeric, OUT users numeric) OWNER TO postgres;

--
-- TOC entry 409 (class 1255 OID 260736)
-- Name: detect_child_files_permissions_conflicts(uuid, uuid, uuid[], uuid[], uuid[], uuid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.detect_child_files_permissions_conflicts(parent_project_id uuid, parent_folder_id uuid, parent_folder_perms_orgs uuid[], parent_folder_perms_teams uuid[], parent_folder_perms_possibles_users uuid[], file_permissions_ids uuid[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	child_permissions_to_delete_count record;
	child_permissions_to_delete_total numeric;
BEGIN
	child_permissions_to_delete_count := count_file_conflicting_permissions(
		parent_folder_perms_orgs, parent_folder_perms_teams, parent_folder_perms_possibles_users,
		file_permissions_ids
	);
	child_permissions_to_delete_total := child_permissions_to_delete_count.users + child_permissions_to_delete_count.teams + child_permissions_to_delete_count.orgs;
	IF child_permissions_to_delete_total > 0 THEN
		RAISE EXCEPTION 'Permission conflict detected on file';
	END IF;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.detect_child_files_permissions_conflicts(parent_project_id uuid, parent_folder_id uuid, parent_folder_perms_orgs uuid[], parent_folder_perms_teams uuid[], parent_folder_perms_possibles_users uuid[], file_permissions_ids uuid[]) OWNER TO postgres;

--
-- TOC entry 410 (class 1255 OID 260737)
-- Name: detect_child_folder_permissions_conflicts(uuid, uuid, uuid, uuid[], uuid[], uuid[], uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.detect_child_folder_permissions_conflicts(parent_project_id uuid, parent_folder_perms_inherited_from uuid, parent_folder_perms_folder_id uuid, parent_folder_perms_orgs uuid[], parent_folder_perms_teams uuid[], parent_folder_perms_possibles_users uuid[], child_folder_perms_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	actual_child_permissions_count record;
	actual_child_permissions_count_total numeric;
	child_permissions_to_delete_count record;
	child_permissions_to_delete_total numeric;
BEGIN
	actual_child_permissions_count := count_all_folder_permissions(child_folder_perms_id);
	actual_child_permissions_count_total := actual_child_permissions_count.orgs + actual_child_permissions_count.teams + actual_child_permissions_count.users;
	-- RAISE NOTICE 'Actual child_permissions_count: orgs: %, teams: %, users: %', actual_child_permissions_count.orgs, actual_child_permissions_count.teams, actual_child_permissions_count.users;
	IF actual_child_permissions_count_total > 0 THEN
		child_permissions_to_delete_count := count_folder_conflicting_permissions(
			parent_folder_perms_orgs, parent_folder_perms_teams, parent_folder_perms_possibles_users,
			child_folder_perms_id
		);
		child_permissions_to_delete_total := child_permissions_to_delete_count.orgs + child_permissions_to_delete_count.teams + child_permissions_to_delete_count.users;
		-- RAISE NOTICE 'actual_child_permissions_count_total: %', actual_child_permissions_count_total;
		-- RAISE NOTICE 'child_permissions_to_delete_count: %', child_permissions_to_delete_count;
		IF child_permissions_to_delete_total > 0 THEN
			RAISE EXCEPTION 'Permission conflict detected on subfolder';
		END IF;
	ELSE
		-- RAISE NOTICE 'No permissions on the child, nothing todo';
	END IF;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.detect_child_folder_permissions_conflicts(parent_project_id uuid, parent_folder_perms_inherited_from uuid, parent_folder_perms_folder_id uuid, parent_folder_perms_orgs uuid[], parent_folder_perms_teams uuid[], parent_folder_perms_possibles_users uuid[], child_folder_perms_id uuid) OWNER TO postgres;

--
-- TOC entry 411 (class 1255 OID 260738)
-- Name: detect_files_permissions_conflicts(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.detect_files_permissions_conflicts(parent_project_id uuid, parent_folder_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	parent_folder_perms folder_permissions;
	unnested_parent_folder_perms record;
	unnested_child_folder_perms record;
	all_possibles_users uuid[];
	file_ids uuid[];
	files_permissions_ids uuid[];
BEGIN
	-- RAISE NOTICE '=======================> check into: %', parent_folder_id;
	files_permissions_ids := (
		SELECT
			COALESCE(array_agg(file_permissions.id), array[]::uuid[])
		FROM file_permissions
		LEFT JOIN files ON file_permissions.file_id = files.id
		WHERE files.parent_id = parent_folder_id
	);
	-- RAISE NOTICE 'file_permissions_ids: %', files_permissions_ids;
	-- No permissions on any of the files, no need to do any conflict resolutions
	IF array_length(files_permissions_ids, 1) < 1 THEN
		-- RAISE NOTICE 'no permissions, early exit found on files %', files_permissions_ids;
		RETURN TRUE;
	END IF;
	parent_folder_perms := get_folder_permission(parent_folder_id);
	IF parent_folder_perms.id IS NULL THEN
		-- RAISE NOTICE 'no permissions, early exit, the parent_folder have no permissions either direct or inherited';
		RETURN TRUE;
	END IF;
	IF parent_folder_perms.inherited_from IS NOT NULL THEN
		-- RAISE NOTICE 'extract permissions from parent inherited_from';
		parent_folder_perms := get_direct_folder_permission(parent_folder_perms.inherited_from);
	END IF;
	unnested_parent_folder_perms := unnest_folder_permissions(parent_folder_perms.id);
	all_possibles_users := get_all_possibles_users_from_permissions(
		parent_project_id,
		unnested_parent_folder_perms.orgs, unnested_parent_folder_perms.teams, unnested_parent_folder_perms.users
	);

	-- Perform conflict resolutions on files
	IF array_length(files_permissions_ids, 1) > 0 THEN
		-- RAISE NOTICE 'some files in the folder have permissions, check thems';
		-- RAISE NOTICE 'unnested_parent_folder_perms: %, all_possibles_users: %', unnested_parent_folder_perms, all_possibles_users;
		PERFORM detect_child_files_permissions_conflicts(
			parent_project_id,
			parent_folder_id,
			unnested_parent_folder_perms.orgs, unnested_parent_folder_perms.teams, all_possibles_users,
			files_permissions_ids
		);
	END IF;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.detect_files_permissions_conflicts(parent_project_id uuid, parent_folder_id uuid) OWNER TO postgres;

--
-- TOC entry 412 (class 1255 OID 260739)
-- Name: f_regexp_escape(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.f_regexp_escape(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
	SELECT regexp_replace($1, '([!$()*+.:<=>?[\\\]^{|}-])', '\\\1', 'g')
$_$;


ALTER FUNCTION public.f_regexp_escape(text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;


--
-- TOC entry 413 (class 1255 OID 260746)
-- Name: find_folder_permission(uuid, smallint, smallint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_folder_permission(checked_folder_id uuid, recursion_level smallint, recursion_limit smallint) RETURNS public.folder_permissions
    LANGUAGE plpgsql STABLE
    AS $$
  DECLARE
  	folder_parent_id uuid;
	perms folder_permissions;
  BEGIN
	IF recursion_limit > -1 AND recursion_level > recursion_limit THEN
		RETURN NULL;
	END IF;
	SELECT
		*
	FROM folder_permissions
	WHERE folder_permissions.folder_id = checked_folder_id
	LIMIT 1 INTO perms;
	IF perms.id IS NOT NULL THEN
		-- Return the current folder_permissions
		RETURN perms;
	END IF;
	folder_parent_id := (SELECT folders.parent_id FROM folders WHERE folders.id = checked_folder_id);
	IF folder_parent_id IS NOT NULL THEN
	-- Go up in the parent hierarchy and continue to search for permissions
		RETURN find_folder_permission(folder_parent_id, (recursion_level + 1)::smallint, recursion_limit);
	ELSE
	-- At the top of the folder tree level we haven't found a permission anywhere down the tree
		RETURN NULL;
	END IF;
  END
$$;


ALTER FUNCTION public.find_folder_permission(checked_folder_id uuid, recursion_level smallint, recursion_limit smallint) OWNER TO postgres;

--
-- TOC entry 416 (class 1255 OID 260747)
-- Name: get_all_possibles_users_from_permissions(uuid, uuid[], uuid[], uuid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_all_possibles_users_from_permissions(perms_project_id uuid, perms_orgs_ids uuid[], perms_teams_ids uuid[], perms_users_ids uuid[]) RETURNS uuid[]
    LANGUAGE plpgsql
    AS $$
DECLARE
	all_possibles_users uuid[];
	project_members uuid[];
	teams_users uuid[];
	orgs_project_users uuid[];
BEGIN
	project_members := (
		SELECT array_agg(projects_to_users.user_id)
		FROM projects_to_users
		WHERE projects_to_users.project_id = perms_project_id
	);
	-- If no permissions are present, there is no need for fetching and exploding users
	IF	array_length(perms_orgs_ids, 1) > 0 OR
		array_length(perms_teams_ids, 1) > 0 OR
		array_length(perms_users_ids, 1) > 0 THEN
		IF array_length(perms_orgs_ids, 1) > 0 THEN
			-- Extract all the users members of the orgs and members of the current project
			orgs_project_users := (
				SELECT
					array_agg(orgs_to_users.user_id)
				FROM orgs_to_users
				WHERE
					orgs_to_users.org_id = ANY(perms_orgs_ids) AND
					orgs_to_users.user_id = ANY(project_members)
			);
		END IF;
		IF array_length(perms_teams_ids, 1) > 0 THEN
			-- Extract all users from the teams
			teams_users := (
				SELECT
					array_agg(DISTINCT teams_to_users.user_id)
				FROM teams_to_users
				WHERE
					teams_to_users.team_id = ANY(perms_teams_ids)
			);
		END IF;
		-- Merge and dedup all previously fetched arrays of users
		all_possibles_users := (SELECT ARRAY(SELECT DISTINCT UNNEST(orgs_project_users || teams_users || perms_users_ids)));
		-- If one of the subsets wasn't null return the intersections betweens all
		IF all_possibles_users IS NOT NULL THEN
			RETURN all_possibles_users;
		END IF;
	END IF;
	-- No permissions apply, therefore, any project members is available
	RETURN project_members;
END
$$;


ALTER FUNCTION public.get_all_possibles_users_from_permissions(perms_project_id uuid, perms_orgs_ids uuid[], perms_teams_ids uuid[], perms_users_ids uuid[]) OWNER TO postgres;

--
-- TOC entry 417 (class 1255 OID 260748)
-- Name: get_direct_folder_permission(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_direct_folder_permission(checked_folder_id uuid) RETURNS public.folder_permissions
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
	RETURN find_folder_permission(checked_folder_id, 0::smallint, 0::smallint);
  END
$$;


ALTER FUNCTION public.get_direct_folder_permission(checked_folder_id uuid) OWNER TO postgres;


--
-- TOC entry 418 (class 1255 OID 260755)
-- Name: get_file_assignations(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_file_assignations(checked_file_id uuid) RETURNS public.file_assignations
    LANGUAGE plpgsql STABLE
    AS $$
  DECLARE
	assigns file_assignations;
  BEGIN
		SELECT
			*
		FROM file_assignations
		WHERE file_assignations.file_id = checked_file_id
		LIMIT 1 INTO assigns;
		RETURN assigns;
  END
$$;


ALTER FUNCTION public.get_file_assignations(checked_file_id uuid) OWNER TO postgres;



ALTER TABLE public.files OWNER TO postgres;

--
-- TOC entry 5316 (class 0 OID 0)
-- Dependencies: 214
-- Name: TABLE files; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.files IS 'Table that define Files';




ALTER TABLE public.orgs OWNER TO postgres;

--
-- TOC entry 419 (class 1255 OID 260773)
-- Name: get_file_assignations_suggestions_orgs(public.files); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_file_assignations_suggestions_orgs(file_row public.files) RETURNS SETOF public.orgs
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
	perms		 file_permissions;
	parent_perms folder_permissions;
BEGIN
	parent_perms := get_final_folder_permissions(file_row.parent_id);
	perms := get_file_permission(file_row.id);
	IF perms.id IS NOT NULL THEN
		RETURN QUERY (
			SELECT orgs.*
			FROM file_permissions_orgs
			LEFT JOIN orgs ON orgs.id = file_permissions_orgs.org_id
			WHERE file_permissions_orgs.file_permission_id = perms.id
		);
	ELSEIF parent_perms.id IS NOT NULL THEN
		RETURN QUERY (
			SELECT orgs.*
			FROM folder_permissions_orgs
			LEFT JOIN orgs ON orgs.id = folder_permissions_orgs.org_id
			WHERE folder_permissions_orgs.folder_permission_id = parent_perms.id
		);
	ELSE
		-- if no permissions apply, return all the orgs of all the members of the project
		RETURN QUERY (
			SELECT * FROM orgs
			WHERE orgs.id IN (
				SELECT DISTINCT(orgs_to_users.org_id)
					FROM projects_to_users
				INNER JOIN orgs_to_users ON orgs_to_users.user_id = projects_to_users.user_id
				WHERE projects_to_users.project_id = file_row.project_id
			)
		);
	END IF;
END
$$;


ALTER FUNCTION public.get_file_assignations_suggestions_orgs(file_row public.files) OWNER TO postgres;


ALTER TABLE public.teams OWNER TO postgres;

--
-- TOC entry 5317 (class 0 OID 0)
-- Dependencies: 216
-- Name: TABLE teams; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.teams IS 'Define a user group (like role)';


--
-- TOC entry 420 (class 1255 OID 260782)
-- Name: get_file_assignations_suggestions_teams(public.files); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_file_assignations_suggestions_teams(file_row public.files) RETURNS SETOF public.teams
    LANGUAGE plpgsql STABLE
    AS $$
 DECLARE
	perms		 file_permissions;
	parent_perms folder_permissions;
 BEGIN
	parent_perms := get_final_folder_permissions(file_row.parent_id);
	perms := get_file_permission(file_row.id);
	IF perms.id IS NOT NULL THEN
		RETURN QUERY (
			SELECT teams.*
			FROM file_permissions_teams
			LEFT JOIN teams ON teams.id = file_permissions_teams.team_id
			WHERE file_permissions_teams.file_permission_id = perms.id
		);
	ELSEIF parent_perms.id IS NOT NULL THEN
		RETURN QUERY (
			SELECT teams.*
			FROM folder_permissions_teams
			LEFT JOIN teams ON teams.id = folder_permissions_teams.team_id
			WHERE folder_permissions_teams.folder_permission_id = parent_perms.id
		);
	ELSE
		-- if no permissions apply, return all the teams of all the members of the project
		RETURN QUERY (
			SELECT * FROM teams
			WHERE teams.project_id = file_row.project_id
		);
	END IF;
 END
$$;


ALTER FUNCTION public.get_file_assignations_suggestions_teams(file_row public.files) OWNER TO postgres;




ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 421 (class 1255 OID 260798)
-- Name: get_file_assignations_suggestions_users(public.files); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_file_assignations_suggestions_users(file_row public.files) RETURNS SETOF public.users
    LANGUAGE plpgsql STABLE
    AS $$
 DECLARE
	perms		 			file_permissions;
	parent_perms			folder_permissions;
	unnested_folder_perms	record;
	unnested_file_perms		record;
	all_possibles_user_ids	uuid[];
 BEGIN
	parent_perms := get_final_folder_permissions(file_row.parent_id);
	perms := get_file_permission(file_row.id);
	IF perms.id IS NOT NULL THEN
		unnested_file_perms := unnest_file_permissions(perms.id);
		all_possibles_user_ids := get_all_possibles_users_from_permissions(
			file_row.project_id,
			unnested_file_perms.orgs, unnested_file_perms.teams, unnested_file_perms.users
		);
		RETURN QUERY (
			SELECT * FROM users
			WHERE users.id = ANY(all_possibles_user_ids)
		);
	ELSEIF parent_perms.id IS NOT NULL THEN
		unnested_folder_perms := unnest_folder_permissions(parent_perms.id);
		all_possibles_user_ids := get_all_possibles_users_from_permissions(
			file_row.project_id,
			unnested_folder_perms.orgs, unnested_folder_perms.teams, unnested_folder_perms.users
		);
		RETURN QUERY (
			SELECT * FROM users
			WHERE users.id = ANY(all_possibles_user_ids)
		);
	ELSE
		-- if no permissions apply, return all the users of all the members of the project
		RETURN QUERY (
			SELECT users.*
			FROM projects_to_users
			INNER JOIN users ON users.id = projects_to_users.user_id
			WHERE projects_to_users.project_id = file_row.project_id
		);
	END IF;
 END
$$;


ALTER FUNCTION public.get_file_assignations_suggestions_users(file_row public.files) OWNER TO postgres;


ALTER TABLE public.file_permissions OWNER TO postgres;

--
-- TOC entry 5318 (class 0 OID 0)
-- Dependencies: 218
-- Name: TABLE file_permissions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.file_permissions IS 'Intermediate table to link file to users, orgs, teams permissions';


--
-- TOC entry 423 (class 1255 OID 260806)
-- Name: get_file_permission(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_file_permission(checked_file_id uuid) RETURNS public.file_permissions
    LANGUAGE plpgsql STABLE
    AS $$
  DECLARE
	perms file_permissions;
  BEGIN
	SELECT * FROM file_permissions WHERE file_permissions.file_id = checked_file_id INTO perms;
	RETURN perms;
  END
$$;


ALTER FUNCTION public.get_file_permission(checked_file_id uuid) OWNER TO postgres;

--
-- TOC entry 414 (class 1255 OID 260807)
-- Name: get_file_permissions_suggestions_orgs(public.files); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_file_permissions_suggestions_orgs(file_row public.files) RETURNS SETOF public.orgs
    LANGUAGE plpgsql STABLE
    AS $$
 DECLARE
	perms folder_permissions;
 BEGIN
	perms := get_final_folder_permissions(file_row.parent_id);
	IF perms.id IS NOT NULL THEN
		RETURN QUERY (
			SELECT orgs.*
			FROM folder_permissions_orgs
			LEFT JOIN orgs ON orgs.id = folder_permissions_orgs.org_id
			WHERE folder_permissions_orgs.folder_permission_id = perms.id
		);
	ELSE
		-- if no permissions apply, return all the orgs of all the members of the project
		RETURN QUERY (
			SELECT * FROM orgs
			WHERE orgs.id IN (
				SELECT DISTINCT(orgs_to_users.org_id)
					FROM projects_to_users
				INNER JOIN orgs_to_users ON orgs_to_users.user_id = projects_to_users.user_id
				WHERE projects_to_users.project_id = file_row.project_id
			)
		);
	END IF;
 END
$$;


ALTER FUNCTION public.get_file_permissions_suggestions_orgs(file_row public.files) OWNER TO postgres;

--
-- TOC entry 424 (class 1255 OID 260808)
-- Name: get_file_permissions_suggestions_teams(public.files); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_file_permissions_suggestions_teams(file_row public.files) RETURNS SETOF public.teams
    LANGUAGE plpgsql STABLE
    AS $$
 DECLARE
	perms folder_permissions;
 BEGIN
	perms := get_final_folder_permissions(file_row.parent_id);
	IF perms.id IS NOT NULL THEN
		RETURN QUERY (
			SELECT teams.*
			FROM folder_permissions_teams
			LEFT JOIN teams ON teams.id = folder_permissions_teams.team_id
			WHERE folder_permissions_teams.folder_permission_id = perms.id
		);
	ELSE
		-- if no permissions apply, return all the teams of all the members of the project
		RETURN QUERY (
			SELECT * FROM teams
			WHERE teams.project_id = file_row.project_id
		);
	END IF;
 END
$$;


ALTER FUNCTION public.get_file_permissions_suggestions_teams(file_row public.files) OWNER TO postgres;

--
-- TOC entry 425 (class 1255 OID 260809)
-- Name: get_file_permissions_suggestions_users(public.files); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_file_permissions_suggestions_users(file_row public.files) RETURNS SETOF public.users
    LANGUAGE plpgsql STABLE
    AS $$
 DECLARE
	perms folder_permissions;
	unnested_folder_perms record;
	all_possibles_user_ids uuid[];
 BEGIN
	perms := get_final_folder_permissions(file_row.parent_id);
	IF perms.id IS NOT NULL THEN
		unnested_folder_perms := unnest_folder_permissions(perms.id);
		all_possibles_user_ids := get_all_possibles_users_from_permissions(
			file_row.project_id,
			unnested_folder_perms.orgs, unnested_folder_perms.teams, unnested_folder_perms.users
		);
		RETURN QUERY (
			SELECT * FROM users
			WHERE users.id = ANY(all_possibles_user_ids)
		);
	ELSE
		-- if no permissions apply, return all the users of all the members of the project
		RETURN QUERY (
			SELECT users.*
			FROM projects_to_users
			INNER JOIN users ON users.id = projects_to_users.user_id
			WHERE projects_to_users.project_id = file_row.project_id
		);
	END IF;
 END
$$;


ALTER FUNCTION public.get_file_permissions_suggestions_users(file_row public.files) OWNER TO postgres;



ALTER TABLE public.file_versions OWNER TO postgres;

--
-- TOC entry 426 (class 1255 OID 260822)
-- Name: get_file_version(public.files, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_file_version(file_row public.files, file_version_id uuid) RETURNS SETOF public.file_versions
    LANGUAGE sql STABLE
    AS $$
  SELECT *
  FROM file_versions
  WHERE
    file_id = file_row.id AND
    file_versions.id = file_version_id
$$;


ALTER FUNCTION public.get_file_version(file_row public.files, file_version_id uuid) OWNER TO postgres;



ALTER TABLE public.file_version_approval_requests OWNER TO postgres;

--
-- TOC entry 5319 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE file_version_approval_requests; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.file_version_approval_requests IS 'Intermediate table that link approvals requests for differents entities (users, ...)';


--
-- TOC entry 427 (class 1255 OID 260829)
-- Name: get_file_version_approval_requests(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_file_version_approval_requests(checked_file_version_id uuid) RETURNS public.file_version_approval_requests
    LANGUAGE plpgsql STABLE
    AS $$
  DECLARE
	requests file_version_approval_requests;
  BEGIN
		SELECT
			*
		FROM file_version_approval_requests
		WHERE file_version_approval_requests.file_version_id = checked_file_version_id
		LIMIT 1 INTO requests;
		RETURN requests;
  END
$$;


ALTER FUNCTION public.get_file_version_approval_requests(checked_file_version_id uuid) OWNER TO postgres;

--
-- TOC entry 428 (class 1255 OID 260830)
-- Name: get_file_version_extension(public.file_versions); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_file_version_extension(file_version_row public.file_versions) RETURNS text
    LANGUAGE sql STABLE
    AS $$
    SELECT
        CASE WHEN file_version_row.is_annotated=true THEN 'pdf' ELSE file_version_row.extension
    END
$$;


ALTER FUNCTION public.get_file_version_extension(file_version_row public.file_versions) OWNER TO postgres;


--
-- TOC entry 422 (class 1255 OID 260799)
-- Name: get_file_extension(public.files); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_file_extension(file_row public.files) RETURNS text
    LANGUAGE sql STABLE
    AS $$
    SELECT get_file_version_extension(file_versions.*)
    FROM file_versions
    WHERE file_versions.file_id = file_row.id
    ORDER BY file_versions.number DESC
    LIMIT 1
$$;


ALTER FUNCTION public.get_file_extension(file_row public.files) OWNER TO postgres;



--
-- TOC entry 429 (class 1255 OID 260831)
-- Name: get_final_folder_permissions(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_final_folder_permissions(searched_folder_id uuid) RETURNS public.folder_permissions
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
	perms folder_permissions;
BEGIN
	-- Check if a permission apply on the folder
	perms := get_folder_permission(searched_folder_id);
	IF perms.id IS NOT NULL THEN
		-- If the permissions on the folder are inherited, retrieve the original permission
		IF perms.inherited_from IS NOT NULL THEN
			perms := get_direct_folder_permission(perms.inherited_from);
		END IF;
	END IF;
	RETURN perms;
END
$$;


ALTER FUNCTION public.get_final_folder_permissions(searched_folder_id uuid) OWNER TO postgres;


ALTER TABLE public.folder_assignations OWNER TO postgres;

--
-- TOC entry 5320 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE folder_assignations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.folder_assignations IS 'Intermediate table that link folder to user, org, team assignation';


--
-- TOC entry 430 (class 1255 OID 260838)
-- Name: get_folder_assignations(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_folder_assignations(checked_folder_id uuid) RETURNS public.folder_assignations
    LANGUAGE plpgsql STABLE
    AS $$
  DECLARE
	assigns folder_assignations;
  BEGIN
		SELECT
			*
		FROM folder_assignations
		WHERE folder_assignations.folder_id = checked_folder_id
		LIMIT 1 INTO assigns;
		RETURN assigns;
  END
$$;


ALTER FUNCTION public.get_folder_assignations(checked_folder_id uuid) OWNER TO postgres;



ALTER TABLE public.folders OWNER TO postgres;

--
-- TOC entry 5321 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE folders; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.folders IS 'Table of folders';


--
-- TOC entry 431 (class 1255 OID 260850)
-- Name: get_folder_assignations_suggestions_orgs(public.folders); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_folder_assignations_suggestions_orgs(folder_row public.folders) RETURNS SETOF public.orgs
    LANGUAGE plpgsql STABLE
    AS $$
 DECLARE
	perms folder_permissions;
 BEGIN
	perms := get_final_folder_permissions(folder_row.id);
	IF perms.id IS NOT NULL THEN
		RETURN QUERY (
			SELECT orgs.*
			FROM folder_permissions_orgs
			LEFT JOIN orgs ON orgs.id = folder_permissions_orgs.org_id
			WHERE folder_permissions_orgs.folder_permission_id = perms.id
		);
	ELSE
		-- if no permissions apply, return all the orgs of all the members of the project
		RETURN QUERY (
			SELECT * FROM orgs
			WHERE orgs.id IN (
				SELECT DISTINCT(orgs_to_users.org_id)
					FROM projects_to_users
				INNER JOIN orgs_to_users ON orgs_to_users.user_id = projects_to_users.user_id
				WHERE projects_to_users.project_id = folder_row.project_id
			)
		);
	END IF;
 END
$$;


ALTER FUNCTION public.get_folder_assignations_suggestions_orgs(folder_row public.folders) OWNER TO postgres;

--
-- TOC entry 432 (class 1255 OID 260851)
-- Name: get_folder_assignations_suggestions_teams(public.folders); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_folder_assignations_suggestions_teams(folder_row public.folders) RETURNS SETOF public.teams
    LANGUAGE plpgsql STABLE
    AS $$
 DECLARE
	perms folder_permissions;
 BEGIN
	perms := get_final_folder_permissions(folder_row.id);
	IF perms.id IS NOT NULL THEN
		RETURN QUERY (
			SELECT teams.*
			FROM folder_permissions_teams
			LEFT JOIN teams ON teams.id = folder_permissions_teams.team_id
			WHERE folder_permissions_teams.folder_permission_id = perms.id
		);
	ELSE
		-- if no permissions apply, return all the teams of all the members of the project
		RETURN QUERY (
			SELECT * FROM teams
			WHERE teams.project_id = folder_row.project_id
		);
	END IF;
 END
$$;


ALTER FUNCTION public.get_folder_assignations_suggestions_teams(folder_row public.folders) OWNER TO postgres;

--
-- TOC entry 433 (class 1255 OID 260852)
-- Name: get_folder_assignations_suggestions_users(public.folders); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_folder_assignations_suggestions_users(folder_row public.folders) RETURNS SETOF public.users
    LANGUAGE plpgsql STABLE
    AS $$
 DECLARE
	perms folder_permissions;
	unnested_folder_perms record;
	all_possibles_user_ids uuid[];
 BEGIN
	perms := get_final_folder_permissions(folder_row.id);
	IF perms.id IS NOT NULL THEN
		unnested_folder_perms := unnest_folder_permissions(perms.id);
		all_possibles_user_ids := get_all_possibles_users_from_permissions(
			folder_row.project_id,
			unnested_folder_perms.orgs, unnested_folder_perms.teams, unnested_folder_perms.users
		);
		RETURN QUERY (
			SELECT * FROM users
			WHERE users.id = ANY(all_possibles_user_ids)
		);
	ELSE
		-- if no permissions apply, return all the users of all the members of the project
		RETURN QUERY (
			SELECT users.*
			FROM projects_to_users
			INNER JOIN users ON users.id = projects_to_users.user_id
			WHERE projects_to_users.project_id = folder_row.project_id
		);
	END IF;
 END
$$;


ALTER FUNCTION public.get_folder_assignations_suggestions_users(folder_row public.folders) OWNER TO postgres;

--
-- TOC entry 434 (class 1255 OID 260853)
-- Name: get_folder_permission(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_folder_permission(checked_folder_id uuid) RETURNS public.folder_permissions
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
	-- Search until we are at the end of the folders hierarchy or 32767e recursive call
	RETURN find_folder_permission(checked_folder_id, 0::smallint, -1::smallint);
  END
$$;


ALTER FUNCTION public.get_folder_permission(checked_folder_id uuid) OWNER TO postgres;

--
-- TOC entry 435 (class 1255 OID 260854)
-- Name: get_folder_permissions_suggestions_orgs(public.folders); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_folder_permissions_suggestions_orgs(folder_row public.folders) RETURNS SETOF public.orgs
    LANGUAGE plpgsql STABLE
    AS $$
 DECLARE
	perms folder_permissions;
 BEGIN
	perms := get_final_folder_permissions(folder_row.parent_id);
	IF perms.id IS NOT NULL THEN
		RETURN QUERY (
			SELECT orgs.*
			FROM folder_permissions_orgs
			LEFT JOIN orgs ON orgs.id = folder_permissions_orgs.org_id
			WHERE folder_permissions_orgs.folder_permission_id = perms.id
		);
	ELSE
		-- if no permissions apply, return all the orgs of all the members of the project
		RETURN QUERY (
			SELECT * FROM orgs
			WHERE orgs.id IN (
				SELECT DISTINCT(orgs_to_users.org_id)
					FROM projects_to_users
				INNER JOIN orgs_to_users ON orgs_to_users.user_id = projects_to_users.user_id
				WHERE projects_to_users.project_id = folder_row.project_id
			)
		);
	END IF;
 END
$$;


ALTER FUNCTION public.get_folder_permissions_suggestions_orgs(folder_row public.folders) OWNER TO postgres;

--
-- TOC entry 436 (class 1255 OID 260855)
-- Name: get_folder_permissions_suggestions_teams(public.folders); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_folder_permissions_suggestions_teams(folder_row public.folders) RETURNS SETOF public.teams
    LANGUAGE plpgsql STABLE
    AS $$
 DECLARE
	perms folder_permissions;
 BEGIN
	perms := get_final_folder_permissions(folder_row.parent_id);
	IF perms.id IS NOT NULL THEN
		RETURN QUERY (
			SELECT teams.*
			FROM folder_permissions_teams
			LEFT JOIN teams ON teams.id = folder_permissions_teams.team_id
			WHERE folder_permissions_teams.folder_permission_id = perms.id
		);
	ELSE
		-- if no permissions apply, return all the teams of all the members of the project
		RETURN QUERY (
			SELECT * FROM teams
			WHERE teams.project_id = folder_row.project_id
		);
	END IF;
 END
$$;


ALTER FUNCTION public.get_folder_permissions_suggestions_teams(folder_row public.folders) OWNER TO postgres;

--
-- TOC entry 437 (class 1255 OID 260856)
-- Name: get_folder_permissions_suggestions_users(public.folders); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_folder_permissions_suggestions_users(folder_row public.folders) RETURNS SETOF public.users
    LANGUAGE plpgsql STABLE
    AS $$
 DECLARE
	perms folder_permissions;
	unnested_folder_perms record;
	all_possibles_user_ids uuid[];
 BEGIN
	perms := get_final_folder_permissions(folder_row.parent_id);
	IF perms.id IS NOT NULL THEN
		unnested_folder_perms := unnest_folder_permissions(perms.id);
		all_possibles_user_ids := get_all_possibles_users_from_permissions(
			folder_row.project_id,
			unnested_folder_perms.orgs, unnested_folder_perms.teams, unnested_folder_perms.users
		);
		RETURN QUERY (
			SELECT * FROM users
			WHERE users.id = ANY(all_possibles_user_ids)
		);
	ELSE
		-- if no permissions apply, return all the users of all the members of the project
		RETURN QUERY (
			SELECT users.*
			FROM projects_to_users
			INNER JOIN users ON users.id = projects_to_users.user_id
			WHERE projects_to_users.project_id = folder_row.project_id
		);
	END IF;
 END
$$;


ALTER FUNCTION public.get_folder_permissions_suggestions_users(folder_row public.folders) OWNER TO postgres;

ALTER TABLE public.t_folder_pwd OWNER TO postgres;

--
-- TOC entry 5322 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE t_folder_pwd; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.t_folder_pwd IS 'Empty table to have type into folders->pwd';


--
-- TOC entry 438 (class 1255 OID 260862)
-- Name: get_folder_pwd(public.folders); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_folder_pwd(folder_row public.folders) RETURNS SETOF public.t_folder_pwd
    LANGUAGE sql STABLE
    AS $$
WITH RECURSIVE recurse_folder_pwd (id, level, name, folder_path) AS (
    SELECT id, 0, name, ARRAY[ROW(id, name, 0)::t_folder_pwd]
    FROM folders
    WHERE parent_id IS NULL AND folders.project_id = folder_row.project_id

    UNION ALL

    SELECT
        f.id, t0.level + 1, f.name, ARRAY_APPEND(t0.folder_path, ROW(f.id, f.name, t0.level + 1)::t_folder_pwd)
    FROM folders AS f
    INNER JOIN recurse_folder_pwd AS t0 ON t0.id = f.parent_id
	  WHERE f.project_id = folder_row.project_id
)
SELECT
    DISTINCT UNNEST(folder_path) AS pwd
FROM recurse_folder_pwd
WHERE recurse_folder_pwd.id = folder_row.id
$$;


ALTER FUNCTION public.get_folder_pwd(folder_row public.folders) OWNER TO postgres;

--
-- TOC entry 439 (class 1255 OID 260863)
-- Name: get_folder_pwd_ids(public.folders); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_folder_pwd_ids(folder_row public.folders) RETURNS uuid[]
    LANGUAGE sql STABLE
    AS $$
WITH RECURSIVE recurse_folder_pwd_ids (id, level, name, folder_path) AS (
    SELECT id, 0, name, ARRAY[id]
    FROM folders
    WHERE parent_id IS NULL AND folders.project_id = folder_row.project_id

    UNION ALL

    SELECT
        f.id, t0.level + 1, f.name, ARRAY_APPEND(t0.folder_path, f.id)
    FROM folders AS f
    INNER JOIN recurse_folder_pwd_ids AS t0 ON t0.id = f.parent_id
	  WHERE f.project_id = folder_row.project_id
)
SELECT
    folder_path AS pwd
FROM recurse_folder_pwd_ids
WHERE recurse_folder_pwd_ids.id = folder_row.id
$$;


ALTER FUNCTION public.get_folder_pwd_ids(folder_row public.folders) OWNER TO postgres;

--
-- TOC entry 440 (class 1255 OID 260864)
-- Name: get_last_file_version(public.files); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_last_file_version(file_row public.files) RETURNS SETOF public.file_versions
    LANGUAGE sql STABLE
    AS $$
    SELECT * from file_versions
    WHERE file_versions.file_id = file_row.id
    ORDER BY file_versions.number DESC
    LIMIT 1
$$;


ALTER FUNCTION public.get_last_file_version(file_row public.files) OWNER TO postgres;

--
-- TOC entry 441 (class 1255 OID 260865)
-- Name: get_non_conflicting_file_name(text, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_non_conflicting_file_name(file_name text, folder_parent_id uuid) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
	has_folder_conflict_name boolean;
	has_file_conflict_name boolean;
	has_conflict_name boolean;
	folders_conflicts_count numeric;
	files_conflicts_count numeric;
	max_conflict_count numeric;
	name_matching_regex text;
	document_extension_name text;
	name_without_extension text;
BEGIN
	has_folder_conflict_name := (
		SELECT 1 FROM folders WHERE folders.name = file_name AND folders.parent_id = folder_parent_id LIMIT 1
	);
	has_file_conflict_name := (
		SELECT 1 FROM files WHERE files.name = file_name AND files.parent_id = folder_parent_id LIMIT 1
	);
	has_conflict_name := COALESCE(has_folder_conflict_name, has_file_conflict_name, FALSE);
	IF has_conflict_name THEN
		-- Extract the filename extension if it exist to append it at the end of rename;
		document_extension_name := COALESCE((SELECT regexp_match(file_name, '(\.[a-zA-Z0-9]+)$'))[1], '');
		-- Get the filename without his extension, to add the (XX) part in the name
		name_without_extension := regexp_replace(file_name, document_extension_name, '');
		-- Create the regex we'll use to match in our tables
		name_matching_regex := f_regexp_escape(name_without_extension) || ' \(([0-9]+)\)' || f_regexp_escape(document_extension_name) || '$';
		folders_conflicts_count := (
			SELECT MAX(COALESCE(((regexp_match(folders.name, name_matching_regex))[1])::numeric, 0))
			FROM folders WHERE folders.name ~ name_matching_regex
			AND folders.parent_id = folder_parent_id
		);
		files_conflicts_count := (
			SELECT MAX(COALESCE(((regexp_match(files.name, name_matching_regex))[1])::numeric, 0))
			FROM files WHERE files.name ~ name_matching_regex
			AND files.parent_id = folder_parent_id
		);
		max_conflict_count := COALESCE(GREATEST(folders_conflicts_count, files_conflicts_count), 0);
		RETURN name_without_extension || ' (' || (max_conflict_count + 1)::text || ')' || document_extension_name;
	END IF;
	RETURN file_name;
END
$_$;


ALTER FUNCTION public.get_non_conflicting_file_name(file_name text, folder_parent_id uuid) OWNER TO postgres;

--
-- TOC entry 442 (class 1255 OID 260866)
-- Name: get_non_conflicting_folder_name(text, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_non_conflicting_folder_name(folder_name text, folder_parent_id uuid) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
	has_folder_conflict_name boolean;
	has_file_conflict_name boolean;
	has_conflict_name boolean;
	folders_conflicts_count numeric;
	files_conflicts_count numeric;
	max_conflict_count numeric;
	name_matching_regex text;
BEGIN
	has_folder_conflict_name := (
		SELECT 1 FROM folders WHERE folders.name = folder_name AND folders.parent_id = folder_parent_id LIMIT 1
	);
	has_file_conflict_name := (
		SELECT 1 FROM files WHERE files.name = folder_name AND files.parent_id = folder_parent_id LIMIT 1
	);
	-- A file/folder cannot have a name duplicate at the same place so we check for conflict in both tables
	has_conflict_name := COALESCE(has_folder_conflict_name, has_file_conflict_name, FALSE);
	IF has_conflict_name THEN
		-- used to match anything like: `folder_name (XX)` and capture the `(XX)` value
		name_matching_regex := (f_regexp_escape(folder_name) || ' \(([0-9]+)\)$');
		-- If a conflict exist, find the max duplicate number the XX part of (folder_name (XX)) in folders
		folders_conflicts_count := (
			SELECT MAX(COALESCE(((regexp_match(folders.name, name_matching_regex))[1])::numeric, 0))
			FROM folders WHERE folders.name ~ name_matching_regex
			AND folders.parent_id = folder_parent_id
		);
		-- Do the same for the files
		files_conflicts_count := (
			SELECT MAX(COALESCE(((regexp_match(files.name, name_matching_regex))[1])::numeric, 0))
			FROM files WHERE files.name ~ name_matching_regex
			AND files.parent_id = folder_parent_id
		);
		-- Get the greatest between both
		max_conflict_count := COALESCE(GREATEST(folders_conflicts_count, files_conflicts_count), 0);
		-- Increment it with 1, and return the new "folder name"
		RETURN folder_name || ' (' || (max_conflict_count + 1)::text || ')';
	END IF;
	RETURN folder_name;
END
$_$;


ALTER FUNCTION public.get_non_conflicting_folder_name(folder_name text, folder_parent_id uuid) OWNER TO postgres;



ALTER TABLE public.projects OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 260877)
-- Name: projects_map_overview; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.projects_map_overview AS
 SELECT projects.id,
    projects.created_at,
    projects.updated_at,
    projects.name,
    projects.description,
    projects.is_demo,
    projects.is_archived,
    projects.deleted_at,
    projects.creator_id
   FROM (public.projects
     LEFT JOIN public.orgs ON ((orgs.project_id = projects.id)))
  WHERE (orgs.id IS NULL);


ALTER TABLE public.projects_map_overview OWNER TO postgres;

--
-- TOC entry 443 (class 1255 OID 260881)
-- Name: get_project_was_created_by_user_active_org(public.projects_map_overview, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_project_was_created_by_user_active_org(project_row public.projects_map_overview, hasura_session json) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	DECLARE
		current_user_id uuid;
		current_user_active_org uuid;
		creator_org_id uuid;
 	BEGIN
	current_user_id := (VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid;
	current_user_active_org := (select org_id from public.orgs_to_users where user_id = current_user_id limit 1);
	if current_user_active_org is null then
		-- user has not org early return
		return false;
	end if;

	-- get the creator org id
	creator_org_id := (select org_id from public.orgs_to_users where user_id = project_row.creator_id limit 1);

 	-- check if is the same org
	if creator_org_id = current_user_active_org then
		return true;
	end if;

	return false;
  END
$$;


ALTER FUNCTION public.get_project_was_created_by_user_active_org(project_row public.projects_map_overview, hasura_session json) OWNER TO postgres;

--
-- TOC entry 444 (class 1255 OID 260882)
-- Name: get_user_can_read_file(public.files, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_can_read_file(file_row public.files, hasura_session json) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	DECLARE
		current_user_id uuid;
 	BEGIN
	current_user_id := (VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid;
  	IF user_has_project_role(current_user_id, file_row.project_id, '{"owner","administrator","standard","limited","readonly","disabled"}') THEN
		-- Return true if the user have ither read or write access on the file permissions
		RETURN user_has_file_access(current_user_id, file_row.id, file_row.parent_id, '{"write","read"}');
	END IF;
	RETURN FALSE;
  END
$$;


ALTER FUNCTION public.get_user_can_read_file(file_row public.files, hasura_session json) OWNER TO postgres;

--
-- TOC entry 376 (class 1255 OID 260883)
-- Name: get_user_can_read_folder(public.folders, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_can_read_folder(folder_row public.folders, hasura_session json) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
  DECLARE
	current_user_id uuid;
  BEGIN
	current_user_id := (VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid;
	IF user_has_project_role(current_user_id, folder_row.project_id, '{"owner","administrator","standard","limited","readonly","disabled"}') THEN
		-- Return true if the user have ither read or write access on the folder permissions
		RETURN user_has_folder_access(current_user_id, folder_row.id, '{"write","read"}');
	END IF;
	RETURN FALSE;
  END
$$;


ALTER FUNCTION public.get_user_can_read_folder(folder_row public.folders, hasura_session json) OWNER TO postgres;

--
-- TOC entry 377 (class 1255 OID 260884)
-- Name: get_user_can_read_org(public.orgs, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_can_read_org(org_row public.orgs, hasura_session json) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	DECLARE
		current_user_id uuid;
 	BEGIN
	current_user_id := (VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid;
	RETURN user_has_org_read_access(current_user_id, org_row.id);
  END
$$;


ALTER FUNCTION public.get_user_can_read_org(org_row public.orgs, hasura_session json) OWNER TO postgres;

--
-- TOC entry 378 (class 1255 OID 260885)
-- Name: get_user_can_read_project(public.projects, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_can_read_project(project_row public.projects, hasura_session json) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	DECLARE
		current_user_id uuid;
 	BEGIN
	current_user_id := (VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid;
	RETURN user_has_project_read_access(current_user_id, project_row.id);
  END
$$;


ALTER FUNCTION public.get_user_can_read_project(project_row public.projects, hasura_session json) OWNER TO postgres;

--
-- TOC entry 379 (class 1255 OID 260886)
-- Name: get_user_can_read_project_map_overview(public.projects_map_overview, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_can_read_project_map_overview(project_row public.projects_map_overview, hasura_session json) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	DECLARE
		current_user_id uuid;
 	BEGIN
	current_user_id := (VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid;
	RETURN user_has_project_read_access(current_user_id, project_row.id);
  END
$$;


ALTER FUNCTION public.get_user_can_read_project_map_overview(project_row public.projects_map_overview, hasura_session json) OWNER TO postgres;

--
-- TOC entry 381 (class 1255 OID 260887)
-- Name: get_user_can_read_user(public.users, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_can_read_user(user_row public.users, hasura_session json) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	DECLARE
		current_user_id uuid;
 	BEGIN
	current_user_id := (VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid;
	-- If the asked user is "me", early exit and allow to read
	IF user_row.id = current_user_id THEN
		RETURN TRUE;
	END IF;
	-- Check if we can access the user either via a shared project or a shared org
	RETURN user_has_user_read_access(current_user_id, user_row.id);
  END
$$;


ALTER FUNCTION public.get_user_can_read_user(user_row public.users, hasura_session json) OWNER TO postgres;

--
-- TOC entry 446 (class 1255 OID 260888)
-- Name: get_user_can_read_user_contact(public.users, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_can_read_user_contact(user_row public.users, hasura_session json) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	DECLARE
	    current_user_id uuid;
	    current_user_org_id uuid;
	    user_org_id uuid;
	BEGIN
	current_user_id := (VALUES  (hasura_session ->> 'x-hasura-user-id'))::uuid;
	user_org_id := (SELECT org_id FROM orgs_to_users AS user_data WHERE user_data.user_id = user_row.id );
	current_user_org_id := (SELECT org_id FROM orgs_to_users AS user_data WHERE user_data.user_id = current_user_id);
	IF user_row.id = current_user_id OR user_org_id = current_user_org_id THEN
	    RETURN TRUE;
	END IF;
	RETURN (
	    SELECT EXISTS (
			    SELECT
				    1
			    -- Get the projects of the current user is a member of
			    FROM projects_to_users AS projects_of_current_user
			    -- Search in all members of those projects, if the searched user is a member of it
			    INNER JOIN projects_to_users AS members_of_current_user_projects ON members_of_current_user_projects.project_id = projects_of_current_user.project_id
			    WHERE
			    -- Actually apply the  "projects of the current user is a member of" filter
				    projects_of_current_user.user_id = current_user_id
				    AND members_of_current_user_projects.user_id = user_row.id
				    AND projects_of_current_user.role_id IN ('owner', 'administrator', 'standard')
			    LIMIT 1
			)
	);
    END
$$;


ALTER FUNCTION public.get_user_can_read_user_contact(user_row public.users, hasura_session json) OWNER TO postgres;

--
-- TOC entry 447 (class 1255 OID 260889)
-- Name: get_user_company_name(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_company_name(row_user_id uuid) RETURNS text
    LANGUAGE sql STABLE
    AS $$
    SELECT
        COALESCE(orgs.name, user_metadatas.placeholder_company_name)
    FROM
        users
    LEFT JOIN orgs_to_users ON orgs_to_users.user_id = users.id
    LEFT JOIN orgs ON orgs_to_users.org_id = orgs.id
    LEFT JOIN user_metadatas ON user_metadatas.user_id = users.id
    WHERE users.id = row_user_id
$$;


ALTER FUNCTION public.get_user_company_name(row_user_id uuid) OWNER TO postgres;

--
-- TOC entry 448 (class 1255 OID 260890)
-- Name: get_user_country_code(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_country_code(row_user_id uuid) RETURNS text
    LANGUAGE sql STABLE
    AS $$
    SELECT
        COALESCE(user_metadatas.country_code, UL.country_code, NULL)
    FROM
        users
    LEFT JOIN user_metadatas ON user_metadatas.user_id = users.id
    LEFT JOIN (SELECT * FROM user_locations WHERE user_locations.user_id = row_user_id AND user_locations.country_code IS NOT NULL ORDER BY user_locations.created_at DESC LIMIT 1) AS UL ON UL.user_id = users.id
    WHERE users.id = row_user_id
$$;


ALTER FUNCTION public.get_user_country_code(row_user_id uuid) OWNER TO postgres;



ALTER TABLE public.file_approvals OWNER TO postgres;

--
-- TOC entry 449 (class 1255 OID 260899)
-- Name: get_user_file_version_approvals(public.file_versions, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_file_version_approvals(file_version_row public.file_versions, hasura_session json) RETURNS SETOF public.file_approvals
    LANGUAGE sql STABLE
    AS $$
  SELECT *
  FROM file_approvals
  WHERE
      file_approvals.file_version_id = file_version_row.id
      AND file_approvals.user_id = ((VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid)
$$;


ALTER FUNCTION public.get_user_file_version_approvals(file_version_row public.file_versions, hasura_session json) OWNER TO postgres;




ALTER TABLE public.t_folder_notification_badge OWNER TO postgres;

--
-- TOC entry 5323 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE t_folder_notification_badge; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.t_folder_notification_badge IS 'Empty table to have type into folders->notification_badge';


--
-- TOC entry 450 (class 1255 OID 260905)
-- Name: get_user_folder_notification(public.folders, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_folder_notification(folder_row public.folders, hasura_session json) RETURNS SETOF public.t_folder_notification_badge
    LANGUAGE plpgsql STABLE
    AS $$
	DECLARE
		current_user_id uuid := (VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid;
 	BEGIN
		RETURN QUERY (
			SELECT
				folder_row.id AS folder_id,
				COALESCE(SUM(notifications_count_for_pwd.strong_notifs_count), 0) AS strong_notification_count,
				COALESCE(SUM(notifications_count_for_pwd.weak_notifs_count) > 0, false) AS weak_notification
			FROM (
				SELECT
					target_grouped_notifications.strong_notifs_count,
					target_grouped_notifications.weak_notifs_count,
					-- Get the pwd for each distinct target with notifications identified
					get_folder_pwd_ids(folders.*) AS pwd
				FROM (
					-- First, we select all notifications for our user concerning documents on the project
					SELECT
						project_document_notifications.target_id,
						-- We aggregate the number of notifications for each target
						COUNT(1) FILTER (WHERE project_document_notifications.is_strong = true) as strong_notifs_count,
						COUNT(1) FILTER (WHERE project_document_notifications.is_strong = false) as weak_notifs_count
						FROM (
							SELECT
								user_notifications.is_strong,
								-- populate the target_id either with folder_id from the payload if it's a folder notification
								-- or from the files.parent_id join if it's a file notification
								-- so this target_id will always contain a folder_id
								COALESCE(files.parent_id, (user_notifications.payload -> 'folder' ->> 'id')::uuid) AS target_id
							FROM user_notifications
							LEFT JOIN
								-- 	for files types notifications we need to retrieve the current file location in the project
								-- 	folders hierarchy
								files ON
									-- Allow PG to shortcut payload check and dismiss all FOLDER notifications
									user_notifications.type LIKE 'PROJECT/DOCUMENT/FILE/%'
									AND files.id = (user_notifications.payload -> 'file' ->> 'id')::uuid
							WHERE
								-- Retrieve all unread notifications of type document for this user for this project
								user_notifications.type LIKE 'PROJECT/DOCUMENT/%'
								AND user_notifications.read_at IS NULL
								AND user_notifications.recipient_id = current_user_id
								AND (user_notifications.payload -> 'project' ->> 'id')::uuid = folder_row.project_id
						) AS project_document_notifications
					-- We group our notifications by targeted entity, it allows us to check a reduced amount of pwd
					-- to know if the notification should be counted on the current folder_row (notification on one of his children) or not
					GROUP BY project_document_notifications.target_id
				) AS target_grouped_notifications
				LEFT JOIN folders ON folders.id = target_grouped_notifications.target_id
			) AS notifications_count_for_pwd
			-- filter out the notifications which are not children of our current folder_row
			WHERE folder_row.id = ANY(notifications_count_for_pwd.pwd)
		);
  END
$$;


ALTER FUNCTION public.get_user_folder_notification(folder_row public.folders, hasura_session json) OWNER TO postgres;

--
-- TOC entry 451 (class 1255 OID 260906)
-- Name: get_user_is_member_project_map_overview(public.projects_map_overview, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_is_member_project_map_overview(project_row public.projects_map_overview, hasura_session json) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	DECLARE
		current_user_id uuid;
 	BEGIN
	current_user_id := (VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid;
	RETURN user_is_project_member_enabled(current_user_id, project_row.id);
  END
$$;


ALTER FUNCTION public.get_user_is_member_project_map_overview(project_row public.projects_map_overview, hasura_session json) OWNER TO postgres;


ALTER TABLE public.org_project_summary OWNER TO postgres;

--
-- TOC entry 5324 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE org_project_summary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.org_project_summary IS 'This table contain the custom data that an org have on a project';


--
-- TOC entry 452 (class 1255 OID 260915)
-- Name: get_user_org_project_map_overview_summary(public.projects_map_overview, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_org_project_map_overview_summary(project_row public.projects_map_overview, hasura_session json) RETURNS SETOF public.org_project_summary
    LANGUAGE sql STABLE
    AS $$
  SELECT org_project_summary.*
    FROM org_project_summary
    LEFT JOIN orgs_to_users ON org_project_summary.org_id = orgs_to_users.org_id
    WHERE
      org_project_summary.project_id = project_row.id
      AND orgs_to_users.user_id = ((VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid)
    LIMIT 1
$$;


ALTER FUNCTION public.get_user_org_project_map_overview_summary(project_row public.projects_map_overview, hasura_session json) OWNER TO postgres;

--
-- TOC entry 453 (class 1255 OID 260916)
-- Name: get_user_org_project_summary(public.projects, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_org_project_summary(project_row public.projects, hasura_session json) RETURNS SETOF public.org_project_summary
    LANGUAGE sql STABLE
    AS $$
  SELECT org_project_summary.*
    FROM org_project_summary
    LEFT JOIN orgs_to_users ON org_project_summary.org_id = orgs_to_users.org_id
    WHERE
      org_project_summary.project_id = project_row.id
      AND orgs_to_users.user_id = ((VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid)
    LIMIT 1
$$;


ALTER FUNCTION public.get_user_org_project_summary(project_row public.projects, hasura_session json) OWNER TO postgres;

--
-- TOC entry 454 (class 1255 OID 260917)
-- Name: increment_file_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.increment_file_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _new record;
BEGIN
  _new := NEW;
  SELECT COALESCE(MAX(number) + 1, 1)
    INTO _new."number"
    FROM "public"."file_versions"
    WHERE file_id = _new."file_id";
  RETURN _new;
END;
$$;


ALTER FUNCTION public.increment_file_version() OWNER TO postgres;

--
-- TOC entry 455 (class 1255 OID 260918)
-- Name: increment_subtask_order(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.increment_subtask_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _new record;
BEGIN
  _new := NEW;
  SELECT COALESCE(MAX("order") + 1, 1)
    INTO _new."order"
    FROM "public"."task_subtasks"
    WHERE task_id = _new."task_id";
  RETURN _new;
END;
$$;


ALTER FUNCTION public.increment_subtask_order() OWNER TO postgres;

--
-- TOC entry 456 (class 1255 OID 260919)
-- Name: increment_task_number(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.increment_task_number() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _new record;
BEGIN
  _new := NEW;
  SELECT COALESCE(MAX(number) + 1, 1)
    INTO _new."number"
    FROM "public"."tasks"
    WHERE project_id = _new."project_id";
  RETURN _new;
END;
$$;


ALTER FUNCTION public.increment_task_number() OWNER TO postgres;

--
-- TOC entry 457 (class 1255 OID 260920)
-- Name: is_approved_on_a_version(public.files); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_approved_on_a_version(file_row public.files) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
	SELECT TRUE as exists FROM file_approvals
	LEFT JOIN file_versions ON file_approvals.file_version_id = file_versions.id
	WHERE
		file_versions.file_id = file_row.id
	LIMIT 1
$$;


ALTER FUNCTION public.is_approved_on_a_version(file_row public.files) OWNER TO postgres;

--
-- TOC entry 407 (class 1255 OID 260921)
-- Name: is_folder_in_bin(public.folders); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_folder_in_bin(folder_row public.folders) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	DECLARE
		project_root_bin_id uuid;
 	BEGIN
	  project_root_bin_id := (SELECT id FROM folders WHERE folders.project_id = folder_row.project_id AND root_bin = true);
  	IF project_root_bin_id = folder_row.id THEN
      -- Return if the folder is the bin himself, return true
      RETURN TRUE;
	  END IF;
	  RETURN coalesce(is_subfolder(project_root_bin_id, folder_row.id), FALSE);
  END
$$;


ALTER FUNCTION public.is_folder_in_bin(folder_row public.folders) OWNER TO postgres;

--
-- TOC entry 458 (class 1255 OID 260922)
-- Name: is_subfolder(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_subfolder(parent_folder_id uuid, folder_id uuid) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
	WITH RECURSIVE is_subfolder_of(parent_id, is_child) AS (
      SELECT
        parent_id,
        coalesce(parent_id = parent_folder_id, false)
      FROM folders
      WHERE
        id = folder_id
    UNION
      SELECT
        ff.parent_id,
        coalesce(ff.parent_id = parent_folder_id, false)
      FROM folders ff, is_subfolder_of iso
      WHERE
        ff.id = iso.parent_id
        -- Stop the recursion once we found our parent
        AND iso.is_child = false
	)
	SELECT true
	FROM is_subfolder_of
	WHERE is_subfolder_of.is_child = true;
$$;


ALTER FUNCTION public.is_subfolder(parent_folder_id uuid, folder_id uuid) OWNER TO postgres;

--
-- TOC entry 459 (class 1255 OID 260923)
-- Name: is_task_done(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_task_done(current_task_id uuid, current_user_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
    BEGIN
        RETURN (
            SELECT EXISTS (
                SELECT 1
                    FROM task_validations TV
                    INNER JOIN orgs_to_users U on U.user_id = TV.user_id
                    INNER JOIN orgs_to_users CU on CU.user_id = current_user_id
                    WHERE TV.task_id = current_task_id AND CU.org_id = U.org_id
                UNION
                    SELECT 1
                    FROM task_validations TV
                    WHERE TV.task_id = current_task_id AND TV.user_id = current_user_id
            LIMIT 1
        ));
    END
$$;


ALTER FUNCTION public.is_task_done(current_task_id uuid, current_user_id uuid) OWNER TO postgres;


ALTER TABLE public.tasks OWNER TO postgres;

--
-- TOC entry 5325 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE tasks; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.tasks IS 'This table groups the tasks, they are then linked to projects or orgs by relationship tables';


--
-- TOC entry 460 (class 1255 OID 260934)
-- Name: is_task_validated(public.tasks, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_task_validated(task_row public.tasks, hasura_session json) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	BEGIN
		RETURN (
			is_task_done(task_row.id, (VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid)
        );
	END
$$;


ALTER FUNCTION public.is_task_validated(task_row public.tasks, hasura_session json) OWNER TO postgres;

--
-- TOC entry 461 (class 1255 OID 260935)
-- Name: is_task_validated_by(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_task_validated_by(current_task_id uuid, current_user_id uuid) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    --if no validations for this task, return 'none'
    IF NOT EXISTS(SELECT * FROM task_validations TV WHERE TV.task_id = current_task_id) THEN
        RETURN 'none';
    --if user has validate it, return 'user'
    ELSEIF EXISTS(SELECT * FROM task_validations TV WHERE TV.task_id = current_task_id AND TV.user_id = current_user_id) THEN
        RETURN 'user';
    --if someone in the same org has validate it, return 'org'
    ELSEIF EXISTS(SELECT 1
            FROM task_validations TV
            INNER JOIN orgs_to_users U on U.user_id = TV.user_id
            INNER JOIN orgs_to_users CU on CU.user_id = current_user_id
            WHERE TV.task_id = current_task_id AND CU.org_id = U.org_id AND TV.user_id != current_user_id
           ) THEN
        RETURN 'org';
    --else return 'external'
    ELSE
        RETURN 'external';
    END IF;
END
$$;


ALTER FUNCTION public.is_task_validated_by(current_task_id uuid, current_user_id uuid) OWNER TO postgres;

--
-- TOC entry 462 (class 1255 OID 260936)
-- Name: lowercase_user_email_on_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.lowercase_user_email_on_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        NEW.email = LOWER(NEW.email);
        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.lowercase_user_email_on_insert() OWNER TO postgres;

--
-- TOC entry 463 (class 1255 OID 260937)
-- Name: move_file(uuid, uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.move_file(parent_project_id uuid, file_parent_id uuid, current_file_id uuid, dest_folder_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	current_name text;
	new_name text;
BEGIN
	-- The file is already in the destination, nothing todo
	IF dest_folder_id = file_parent_id THEN
		RETURN TRUE;
	END IF;
	-- Copy inherited permissions as direct permissions on the file if needed too
	PERFORM copy_all_inherited_permissions_on_file(parent_project_id, file_parent_id, current_file_id);
	current_name := (SELECT files.name FROM files WHERE files.id = current_file_id);
	new_name := get_non_conflicting_file_name(current_name, dest_folder_id);
	UPDATE files SET parent_id = dest_folder_id, name = new_name WHERE files.id = current_file_id;
	-- Update the file direct permissions and resolve conflicts with his new destinations
	PERFORM detect_files_permissions_conflicts(parent_project_id, dest_folder_id);
	PERFORM resolve_files_permissions_assignations_conflicts(parent_project_id, dest_folder_id);
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.move_file(parent_project_id uuid, file_parent_id uuid, current_file_id uuid, dest_folder_id uuid) OWNER TO postgres;

--
-- TOC entry 464 (class 1255 OID 260938)
-- Name: move_folder(uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.move_folder(parent_project_id uuid, folder_to_move_id uuid, dest_folder_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	dest_pwd_ids uuid[];
	is_circular boolean;
	current_name text;
	new_name text;
BEGIN
	dest_pwd_ids := (SELECT get_folder_pwd_ids(folders.*) FROM folders WHERE folders.id = dest_folder_id);
	is_circular := (SELECT TRUE WHERE folder_to_move_id = ANY(dest_pwd_ids));
	-- If the move would result in a circular list, do not update and raise an error
	IF is_circular OR (folder_to_move_id = dest_folder_id) IS TRUE THEN
		RAISE EXCEPTION 'moving folder would result in a circular dependency';
		RETURN FALSE;
	END IF;
	current_name := (SELECT folders.name FROM folders WHERE folders.id = folder_to_move_id);
	RAISE NOTICE 'current_name: %', current_name;
	new_name := get_non_conflicting_folder_name(current_name, dest_folder_id);
	RAISE NOTICE 'new_name: %', new_name;
	UPDATE folders SET parent_id = dest_folder_id, name = new_name WHERE folders.id = folder_to_move_id;
	RAISE NOTICE 'updated';
	PERFORM walk_and_detect_permissions_conflicts(parent_project_id, dest_folder_id, array[folder_to_move_id]::uuid[]);
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.move_folder(parent_project_id uuid, folder_to_move_id uuid, dest_folder_id uuid) OWNER TO postgres;

--
-- TOC entry 465 (class 1255 OID 260939)
-- Name: perform_recursive_permissions_conflict_resolution(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.perform_recursive_permissions_conflict_resolution(parent_project_id uuid, parent_folder_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
	PERFORM cleanup_files_folders_permissions_assignations();
	RETURN walk_and_resolve_permissions_conflicts(
		parent_project_id,
		parent_folder_id,
		(SELECT COALESCE(array_agg(folders.id), array[]::uuid[]) FROM folders WHERE folders.parent_id = parent_folder_id)
	);
END
$$;


ALTER FUNCTION public.perform_recursive_permissions_conflict_resolution(parent_project_id uuid, parent_folder_id uuid) OWNER TO postgres;

--
-- TOC entry 466 (class 1255 OID 260940)
-- Name: presigned_urls_delete_old_rows(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.presigned_urls_delete_old_rows() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
  DELETE FROM "public"."presigned_urls" WHERE expires_at < NOW() - INTERVAL '1 days';
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.presigned_urls_delete_old_rows() OWNER TO postgres;

--
-- TOC entry 467 (class 1255 OID 260941)
-- Name: project_root_bin_folder_id(public.projects); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.project_root_bin_folder_id(project_row public.projects) RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  SELECT folders.id
  FROM folders
  WHERE folders.root_bin = true AND folders.project_id = project_row.id
$$;


ALTER FUNCTION public.project_root_bin_folder_id(project_row public.projects) OWNER TO postgres;

--
-- TOC entry 468 (class 1255 OID 260942)
-- Name: project_root_folder_id(public.projects); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.project_root_folder_id(project_row public.projects) RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  SELECT folders.id
  FROM folders
  WHERE folders.root = true AND folders.project_id = project_row.id
$$;


ALTER FUNCTION public.project_root_folder_id(project_row public.projects) OWNER TO postgres;

--
-- TOC entry 469 (class 1255 OID 260943)
-- Name: refresh_file_versions_approvals_overview_materialized_view(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.refresh_file_versions_approvals_overview_materialized_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY file_versions_approvals_overview;
    RETURN null;
end $$;


ALTER FUNCTION public.refresh_file_versions_approvals_overview_materialized_view() OWNER TO postgres;

--
-- TOC entry 470 (class 1255 OID 260944)
-- Name: refresh_orgs_projects_users_materialized_view(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.refresh_orgs_projects_users_materialized_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY orgs_projects_users;
    RETURN null;
end $$;


ALTER FUNCTION public.refresh_orgs_projects_users_materialized_view() OWNER TO postgres;

--
-- TOC entry 471 (class 1255 OID 260945)
-- Name: resolve_child_files_permissions(uuid, uuid, uuid[], uuid[], uuid[], uuid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.resolve_child_files_permissions(parent_project_id uuid, parent_folder_id uuid, parent_folder_perms_orgs uuid[], parent_folder_perms_teams uuid[], parent_folder_perms_possibles_users uuid[], file_permissions_ids uuid[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	file_ids_to_check uuid[];
	file_id_loop uuid;
	deleted_orgs numeric;
	deleted_teams numeric;
	deleted_users numeric;
BEGIN
	-- RAISE NOTICE 'Perform conflict resolutions on files_permissions %', file_permissions_ids;
	WITH deleted AS (DELETE FROM
		file_permissions_orgs
	WHERE
		file_permissions_orgs.file_permission_id = ANY(file_permissions_ids) AND
		NOT file_permissions_orgs.org_id = ANY(parent_folder_perms_orgs)
	RETURNING *) SELECT count(*) FROM deleted INTO deleted_orgs;
	-- RAISE NOTICE 'Perform conflict resolutions orgs: %', deleted_orgs;
	WITH deleted AS (DELETE FROM
		file_permissions_teams
	WHERE
		file_permissions_teams.file_permission_id = ANY(file_permissions_ids) AND
		NOT file_permissions_teams.team_id = ANY(parent_folder_perms_teams)
	RETURNING *) SELECT count(*) FROM deleted INTO deleted_teams;
	-- RAISE NOTICE 'Perform conflict resolutions teams: %', deleted_teams;
	WITH deleted AS (DELETE FROM
		file_permissions_users
	WHERE
		file_permissions_users.file_permission_id = ANY(file_permissions_ids) AND
		NOT file_permissions_users.user_id = ANY(parent_folder_perms_possibles_users)
	RETURNING *) SELECT count(*) FROM deleted INTO deleted_users;
	-- RAISE NOTICE 'Perform conflict resolutions users: %', deleted_users;
	IF deleted_orgs > 0 OR deleted_teams > 0 OR deleted_users > 0 THEN
		-- RAISE NOTICE 'ACT: deleted: orgs %, teams %, users %', deleted_orgs, deleted_teams, deleted_users;
		PERFORM cleanup_files_permissions();
	ELSE
		-- RAISE NOTICE 'no permissions in conflict, NOTHING TODO';
	END IF;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.resolve_child_files_permissions(parent_project_id uuid, parent_folder_id uuid, parent_folder_perms_orgs uuid[], parent_folder_perms_teams uuid[], parent_folder_perms_possibles_users uuid[], file_permissions_ids uuid[]) OWNER TO postgres;

--
-- TOC entry 472 (class 1255 OID 260946)
-- Name: resolve_child_folder_permissions(uuid, uuid, uuid, uuid[], uuid[], uuid[], uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.resolve_child_folder_permissions(parent_project_id uuid, parent_folder_perms_inherited_from uuid, parent_folder_perms_folder_id uuid, parent_folder_perms_orgs uuid[], parent_folder_perms_teams uuid[], parent_folder_perms_possibles_users uuid[], child_folder_perms_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	actual_child_permissions_count record;
	actual_child_permissions_count_total numeric;
	child_permissions_to_delete_count record;
	child_permissions_to_delete_total numeric;
BEGIN
	actual_child_permissions_count := count_all_folder_permissions(child_folder_perms_id);
	actual_child_permissions_count_total := actual_child_permissions_count.orgs + actual_child_permissions_count.teams + actual_child_permissions_count.users;
	-- RAISE NOTICE 'Actual child_permissions_count: orgs: %, teams: %, users: %', actual_child_permissions_count.orgs, actual_child_permissions_count.teams, actual_child_permissions_count.users;
	IF actual_child_permissions_count_total > 0 THEN
		child_permissions_to_delete_count := count_folder_conflicting_permissions(
			parent_folder_perms_orgs, parent_folder_perms_teams, parent_folder_perms_possibles_users,
			child_folder_perms_id
		);
		child_permissions_to_delete_total := child_permissions_to_delete_count.orgs + child_permissions_to_delete_count.teams + child_permissions_to_delete_count.users;
		-- RAISE NOTICE 'actual_child_permissions_count_total: %', actual_child_permissions_count_total;
		-- RAISE NOTICE 'child_permissions_to_delete_count: %', child_permissions_to_delete_count;
		IF child_permissions_to_delete_total = actual_child_permissions_count_total THEN
			-- RAISE NOTICE 'ACT: After conflict resolutions, all current permissions will be deleted, resulting into an empty permission set, just update the inherited_from and delete all old permissions';
			UPDATE folder_permissions
			SET inherited_from = COALESCE(parent_folder_perms_inherited_from, parent_folder_perms_folder_id)
			WHERE id = child_folder_perms_id;
			-- Delete all the old permissions
			DELETE FROM
				folder_permissions_orgs
			WHERE
				folder_permissions_orgs.folder_permission_id = child_folder_perms_id;
			DELETE FROM
				folder_permissions_teams
			WHERE
				folder_permissions_teams.folder_permission_id = child_folder_perms_id;
			DELETE FROM
				folder_permissions_users
			WHERE
				folder_permissions_users.folder_permission_id = child_folder_perms_id;
		ELSEIF child_permissions_to_delete_total > 0 THEN
			-- RAISE NOTICE 'ACT: Perform conflict resolutions on folder';
			DELETE FROM
				folder_permissions_orgs
			WHERE
				folder_permissions_orgs.folder_permission_id = child_folder_perms_id AND
				NOT folder_permissions_orgs.org_id = ANY(parent_folder_perms_orgs);
			DELETE FROM
				folder_permissions_teams
			WHERE
				folder_permissions_teams.folder_permission_id = child_folder_perms_id AND
				NOT folder_permissions_teams.team_id = ANY(parent_folder_perms_teams);
			DELETE FROM
				folder_permissions_users
			WHERE
				folder_permissions_users.folder_permission_id = child_folder_perms_id AND
				NOT folder_permissions_users.user_id = ANY(parent_folder_perms_possibles_users);
			PERFORM cleanup_folders_permissions();
		ELSE
			-- RAISE NOTICE 'No permissions are in conflict, NOTHING TODO';
		END IF;
	ELSE
		-- RAISE NOTICE 'No permissions on the child, nothing todo';
	END IF;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.resolve_child_folder_permissions(parent_project_id uuid, parent_folder_perms_inherited_from uuid, parent_folder_perms_folder_id uuid, parent_folder_perms_orgs uuid[], parent_folder_perms_teams uuid[], parent_folder_perms_possibles_users uuid[], child_folder_perms_id uuid) OWNER TO postgres;

--
-- TOC entry 473 (class 1255 OID 260947)
-- Name: resolve_file_assignations_approvals_requests_conflicts(uuid, uuid[], uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.resolve_file_assignations_approvals_requests_conflicts(parent_project_id uuid, file_assigns_users uuid[], current_file_version_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	approvals_requests file_version_approval_requests;
	deleted_users numeric;
BEGIN
	-- RAISE NOTICE 'Perform conflict resolutions on file_version_approvals_requests %', current_file_version_id;
	approvals_requests := get_file_version_approval_requests(current_file_version_id);
	IF approvals_requests.id IS NULL THEN
		-- RAISE NOTICE 'no approvals requests are set on the file_version, NOTING TODO';
		RETURN TRUE;
	END IF;
	IF COALESCE(array_length(file_assigns_users, 1), 0) < 1 THEN
		-- RAISE NOTICE 'new users assignations is empty, must remove all users from approvals_requests';
		-- must remove all users from the assignations requests
		WITH deleted AS (DELETE FROM
			file_version_approval_request_users
		WHERE
			file_version_approval_request_users.file_version_approval_request_id = approvals_requests.id AND
			-- Only sync with "pending" approvals
			file_version_approval_request_users.file_approval_id IS NULL
		RETURNING *) SELECT count(*) FROM deleted INTO deleted_users;
		-- RAISE NOTICE 'Perform conflict resolutions users: %', deleted_users;
		IF deleted_users > 0 THEN
			-- RAISE NOTICE 'ACT: deleted: users %', deleted_users;
		ELSE
			-- RAISE NOTICE 'no approvals requests in conflict, NOTHING TODO';
		END IF;
	ELSE
		WITH deleted AS (DELETE FROM
			file_version_approval_request_users
		WHERE
			file_version_approval_request_users.file_version_approval_request_id = approvals_requests.id AND
			-- Only sync with "pending" approvals
			file_version_approval_request_users.file_approval_id IS NULL AND
			NOT file_version_approval_request_users.user_id = ANY(file_assigns_users)
		RETURNING *) SELECT count(*) FROM deleted INTO deleted_users;
		-- RAISE NOTICE 'Perform conflict resolutions users: %', deleted_users;
		IF deleted_users > 0 THEN
			-- RAISE NOTICE 'ACT: deleted: users %', deleted_users;
		ELSE
			-- RAISE NOTICE 'no approvals requests in conflict, NOTHING TODO';
		END IF;
	END IF;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.resolve_file_assignations_approvals_requests_conflicts(parent_project_id uuid, file_assigns_users uuid[], current_file_version_id uuid) OWNER TO postgres;

--
-- TOC entry 474 (class 1255 OID 260948)
-- Name: resolve_file_permissions_assignations_conflicts(uuid, uuid[], uuid[], uuid[], uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.resolve_file_permissions_assignations_conflicts(parent_project_id uuid, file_perms_orgs uuid[], file_perms_teams uuid[], file_perms_possibles_users uuid[], current_file_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	assign file_assignations;
	deleted_orgs numeric;
	deleted_teams numeric;
	deleted_users numeric;
BEGIN
	-- RAISE NOTICE 'Perform conflict resolutions on file_assignations %', current_file_id;
	assign := get_file_assignations(current_file_id);
	IF assign.id IS NULL THEN
		-- RAISE NOTICE 'no assignations are set on the file, NOTING TODO';
		RETURN TRUE;
	END IF;
	WITH deleted AS (DELETE FROM
		file_assignations_orgs
	WHERE
		file_assignations_orgs.file_assignation_id = assign.id AND
		NOT file_assignations_orgs.org_id = ANY(file_perms_orgs)
	RETURNING *) SELECT count(*) FROM deleted INTO deleted_orgs;
	-- RAISE NOTICE 'Perform conflict resolutions orgs: %', deleted_orgs;
	WITH deleted AS (DELETE FROM
		file_assignations_teams
	WHERE
		file_assignations_teams.file_assignation_id = assign.id AND
		NOT file_assignations_teams.team_id = ANY(file_perms_teams)
	RETURNING *) SELECT count(*) FROM deleted INTO deleted_teams;
	-- RAISE NOTICE 'Perform conflict resolutions teams: %', deleted_teams;
	WITH deleted AS (DELETE FROM
		file_assignations_users
	WHERE
		file_assignations_users.file_assignation_id = assign.id AND
		NOT file_assignations_users.user_id = ANY(file_perms_possibles_users)
	RETURNING *) SELECT count(*) FROM deleted INTO deleted_users;
	-- RAISE NOTICE 'Perform conflict resolutions users: %', deleted_users;
	IF deleted_orgs > 0 OR deleted_teams > 0 OR deleted_users > 0 THEN
		-- RAISE NOTICE 'ACT: deleted: orgs %, teams %, users %', deleted_orgs, deleted_teams, deleted_users;
		PERFORM cleanup_files_assignations();
	ELSE
		-- RAISE NOTICE 'no assignations in conflict, NOTHING TODO';
	END IF;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.resolve_file_permissions_assignations_conflicts(parent_project_id uuid, file_perms_orgs uuid[], file_perms_teams uuid[], file_perms_possibles_users uuid[], current_file_id uuid) OWNER TO postgres;

--
-- TOC entry 475 (class 1255 OID 260949)
-- Name: resolve_files_permissions_assignations_conflicts(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.resolve_files_permissions_assignations_conflicts(parent_project_id uuid, parent_folder_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	file_with_assignations_id uuid;
BEGIN
	-- RAISE NOTICE '=======================> resolve_file_assignations_conflicts for files in : %', parent_folder_id;
	FOR file_with_assignations_id IN (
		SELECT
			file_assignations.file_id
		FROM file_assignations
		LEFT JOIN files ON file_assignations.file_id = files.id
		WHERE files.parent_id = parent_folder_id
	) LOOP
		-- RAISE NOTICE 'Sync file permissions and assignations for file: %', file_with_assignations_id;
		PERFORM sync_file_permissions_assignations(parent_project_id, parent_folder_id, file_with_assignations_id);
	END LOOP;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.resolve_files_permissions_assignations_conflicts(parent_project_id uuid, parent_folder_id uuid) OWNER TO postgres;

--
-- TOC entry 477 (class 1255 OID 260950)
-- Name: resolve_files_permissions_conflicts(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.resolve_files_permissions_conflicts(parent_project_id uuid, parent_folder_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	parent_folder_perms folder_permissions;
	unnested_parent_folder_perms record;
	unnested_child_folder_perms record;
	all_possibles_users uuid[];
	file_ids uuid[];
	files_permissions_ids uuid[];
BEGIN
	-- RAISE NOTICE '=======================> check into: %', parent_folder_id;
	files_permissions_ids := (
		SELECT
			COALESCE(array_agg(file_permissions.id), array[]::uuid[])
		FROM file_permissions
		LEFT JOIN files ON file_permissions.file_id = files.id
		WHERE files.parent_id = parent_folder_id
	);
	-- RAISE NOTICE 'file_permissions_ids: %', files_permissions_ids;
	-- No permissions on any of the files, no need to do any conflict resolutions
	IF array_length(files_permissions_ids, 1) < 1 THEN
		-- RAISE NOTICE 'no permissions, early exit found on files %', files_permissions_ids;
		RETURN TRUE;
	END IF;
	parent_folder_perms := get_folder_permission(parent_folder_id);
	IF parent_folder_perms.id IS NULL THEN
		-- RAISE NOTICE 'no permissions, early exit, the parent_folder have no permissions either direct or inherited';
		RETURN TRUE;
	END IF;
	IF parent_folder_perms.inherited_from IS NOT NULL THEN
		-- RAISE NOTICE 'extract permissions from parent inherited_from';
		parent_folder_perms := get_direct_folder_permission(parent_folder_perms.inherited_from);
	END IF;
	unnested_parent_folder_perms := unnest_folder_permissions(parent_folder_perms.id);
	all_possibles_users := get_all_possibles_users_from_permissions(
		parent_project_id,
		unnested_parent_folder_perms.orgs, unnested_parent_folder_perms.teams, unnested_parent_folder_perms.users
	);

	-- Perform conflict resolutions on files
	IF array_length(files_permissions_ids, 1) > 0 THEN
		-- RAISE NOTICE 'some files in the folder have permissions, check thems';
		-- RAISE NOTICE 'unnested_parent_folder_perms: %, all_possibles_users: %', unnested_parent_folder_perms, all_possibles_users;
		PERFORM resolve_child_files_permissions(
			parent_project_id,
			parent_folder_id,
			unnested_parent_folder_perms.orgs, unnested_parent_folder_perms.teams, all_possibles_users,
			files_permissions_ids
		);
	END IF;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.resolve_files_permissions_conflicts(parent_project_id uuid, parent_folder_id uuid) OWNER TO postgres;

--
-- TOC entry 478 (class 1255 OID 260951)
-- Name: resolve_folder_permissions_assignations_conflicts(uuid, uuid[], uuid[], uuid[], uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.resolve_folder_permissions_assignations_conflicts(parent_project_id uuid, folder_perms_orgs uuid[], folder_perms_teams uuid[], folder_perms_possibles_users uuid[], current_folder_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	assign folder_assignations;
	deleted_orgs numeric;
	deleted_teams numeric;
	deleted_users numeric;
BEGIN
	-- RAISE NOTICE 'Perform conflict resolutions on folder_assignations %', current_folder_id;
	-- RAISE NOTICE 'folder_perms_possibles_users: %', folder_perms_possibles_users;
	assign := get_folder_assignations(current_folder_id);
	IF assign.id IS NULL THEN
		-- RAISE NOTICE 'no assignations are set on the folder, NOTING TODO';
		RETURN TRUE;
	END IF;
	WITH deleted AS (DELETE FROM
		folder_assignations_orgs
	WHERE
		folder_assignations_orgs.folder_assignation_id = assign.id AND
		NOT folder_assignations_orgs.org_id = ANY(folder_perms_orgs)
	RETURNING *) SELECT count(*) FROM deleted INTO deleted_orgs;
	-- RAISE NOTICE 'Perform conflict resolutions orgs: %', deleted_orgs;
	WITH deleted AS (DELETE FROM
		folder_assignations_teams
	WHERE
		folder_assignations_teams.folder_assignation_id  = assign.id AND
		NOT folder_assignations_teams.team_id = ANY(folder_perms_teams)
	RETURNING *) SELECT count(*) FROM deleted INTO deleted_teams;
	-- RAISE NOTICE 'Perform conflict resolutions teams: %', deleted_teams;
	WITH deleted AS (DELETE FROM
		folder_assignations_users
	WHERE
		folder_assignations_users.folder_assignation_id  = assign.id AND
		NOT folder_assignations_users.user_id = ANY(folder_perms_possibles_users)
	RETURNING *) SELECT count(*) FROM deleted INTO deleted_users;
	-- RAISE NOTICE 'Perform conflict resolutions users: %', deleted_users;
	IF deleted_orgs > 0 OR deleted_teams > 0 OR deleted_users > 0 THEN
		-- RAISE NOTICE 'ACT: deleted: orgs %, teams %, users %', deleted_orgs, deleted_teams, deleted_users;
		PERFORM cleanup_folders_assignations();
	ELSE
		-- RAISE NOTICE 'no assignations in conflict, NOTHING TODO';
	END IF;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.resolve_folder_permissions_assignations_conflicts(parent_project_id uuid, folder_perms_orgs uuid[], folder_perms_teams uuid[], folder_perms_possibles_users uuid[], current_folder_id uuid) OWNER TO postgres;

--
-- TOC entry 479 (class 1255 OID 260952)
-- Name: set_current_timestamp_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_current_timestamp_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _new record;
BEGIN
  _new := NEW;
  _new."updated_at" = NOW();
  RETURN _new;
END;
$$;


ALTER FUNCTION public.set_current_timestamp_updated_at() OWNER TO postgres;

--
-- TOC entry 480 (class 1255 OID 260953)
-- Name: set_permissions_after_folder_created(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_permissions_after_folder_created() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	parent_perms folder_permissions;
BEGIN
	IF NEW.parent_id IS NOT NULL THEN
    	parent_perms := get_direct_folder_permission(NEW.parent_id);
		IF parent_perms.id IS NOT NULL THEN
			INSERT INTO folder_permissions(folder_id, inherited_from) VALUES (NEW.id, COALESCE(parent_perms.inherited_from, parent_perms.folder_id));
		END IF;
	END IF;
	RETURN NEW;
END
$$;


ALTER FUNCTION public.set_permissions_after_folder_created() OWNER TO postgres;

--
-- TOC entry 481 (class 1255 OID 260954)
-- Name: sync_file_assignations_file_version_approval_requests(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sync_file_assignations_file_version_approval_requests(folder_project_id uuid, current_file_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	current_file_assignations file_assignations;
	unnested_assignations record;
	all_possibles_users uuid[];
	last_file_version_id uuid;
	current_file_is_approval_mode boolean;
BEGIN
	-- RAISE NOTICE 'sync_file_assignations_file_version_approval_requests';
	current_file_is_approval_mode := (SELECT files.is_approval_mode FROM files WHERE files.id = current_file_id);
	-- RAISE NOTICE 'file_is_approval_mode: %', current_file_is_approval_mode;
	-- If the file is not in approval mode, no need for any sync
	IF current_file_is_approval_mode THEN
		last_file_version_id := (
			SELECT file_versions.id FROM file_versions
			WHERE file_versions.file_id = current_file_id
			ORDER BY file_versions.number DESC
			LIMIT 1
		);
		current_file_assignations := get_file_assignations(current_file_id);
		-- RAISE NOTICE 'current_file_assignations: %', current_file_assignations;
		-- If the file have some assignations
		IF current_file_assignations.id IS NOT NULL THEN
			-- RAISE NOTICE 'current_file_assignations_id is not null';
			unnested_assignations := unnest_file_assignations(current_file_assignations.id);
			-- Resolve conflicts between assignations and current pending approvals requests if they exists
			PERFORM resolve_file_assignations_approvals_requests_conflicts(
				folder_project_id,
				unnested_assignations.users,
				last_file_version_id
			);
		ELSE
			-- No more assignations on the file, remove all pending approvals requests
			PERFORM resolve_file_assignations_approvals_requests_conflicts(
				folder_project_id,
				array[]::uuid[],
				last_file_version_id
			);
		END IF;
	END IF;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.sync_file_assignations_file_version_approval_requests(folder_project_id uuid, current_file_id uuid) OWNER TO postgres;

--
-- TOC entry 482 (class 1255 OID 260955)
-- Name: sync_file_permissions_assignations(uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sync_file_permissions_assignations(folder_project_id uuid, parent_folder_id uuid, current_file_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	parent_perms folder_permissions;
	current_file_perms file_permissions;
	unnested_permissions record;
	all_possibles_users uuid[];
BEGIN
	-- RAISE NOTICE 'sync file permissions and assignations';
	current_file_perms := get_file_permission(current_file_id);
	-- If the file have direct permissions applied to himself
	IF current_file_perms.id IS NOT NULL THEN
		-- RAISE NOTICE 'permissions are directly on file';
		unnested_permissions := unnest_file_permissions(current_file_perms.id);
	ELSE
		-- If the file have permissions applied to it via hierarchy
		parent_perms := get_folder_permission(parent_folder_id);
		IF parent_perms.id IS NOT NULL THEN
			-- RAISE NOTICE 'permissions come from hierarchy';
			-- If the permissions from closest hierarchy point is inherited, retrieve the original permission set
			IF parent_perms.inherited_from IS NOT NULL THEN
				parent_perms := get_direct_folder_permission(parent_perms.inherited_from);
			END IF;
			unnested_permissions := unnest_folder_permissions(parent_perms.id);
		END IF;
	END IF;
	-- If some permissions apply on the file, either inherited or directly
	IF (parent_perms.id IS NOT NULL) OR (current_file_perms.id IS NOT NULL) THEN
		all_possibles_users := get_all_possibles_users_from_permissions(
			folder_project_id,
			unnested_permissions.orgs,
			unnested_permissions.teams,
			unnested_permissions.users
		);
		-- Resolve conflicts between permissions and assignations if they exists
		PERFORM resolve_file_permissions_assignations_conflicts(
			folder_project_id,
			unnested_permissions.orgs, unnested_permissions.teams, all_possibles_users,
			current_file_id
		);
	END IF;
	PERFORM sync_file_assignations_file_version_approval_requests(folder_project_id, current_file_id);
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.sync_file_permissions_assignations(folder_project_id uuid, parent_folder_id uuid, current_file_id uuid) OWNER TO postgres;

--
-- TOC entry 483 (class 1255 OID 260956)
-- Name: sync_folder_permissions_assignations(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sync_folder_permissions_assignations(folder_project_id uuid, current_folder_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	perms folder_permissions;
	unnested_folder_permission record;
	all_possibles_users uuid[];
BEGIN
	perms := get_folder_permission(current_folder_id);
	-- If some permissions apply on the folder, if not, nothing todo
	IF perms.id IS NOT NULL THEN
		IF perms.inherited_from IS NOT NULL THEN
			perms := get_direct_folder_permission(perms.inherited_from);
		END IF;
		unnested_folder_permission := unnest_folder_permissions(perms.id);
		all_possibles_users := get_all_possibles_users_from_permissions(
			folder_project_id,
			unnested_folder_permission.orgs,
			unnested_folder_permission.teams,
			unnested_folder_permission.users
		);
		-- Resolve conflicts between permissions and assignations if they exists
		PERFORM resolve_folder_permissions_assignations_conflicts(
			folder_project_id,
			unnested_folder_permission.orgs, unnested_folder_permission.teams, all_possibles_users,
			current_folder_id
		);
	END IF;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.sync_folder_permissions_assignations(folder_project_id uuid, current_folder_id uuid) OWNER TO postgres;

--
-- TOC entry 484 (class 1255 OID 260957)
-- Name: task_progress(public.tasks); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.task_progress(task_row public.tasks) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
SELECT CASE WHEN COUNT(1) > 0 THEN
CAST(
    CAST(COUNT(1) FILTER (WHERE task_subtasks.closed = true) AS float) / CAST(COUNT(1) AS float
) * 100 AS int)
END
FROM task_subtasks
WHERE task_subtasks.task_id = task_row.id
$$;


ALTER FUNCTION public.task_progress(task_row public.tasks) OWNER TO postgres;

--
-- TOC entry 485 (class 1255 OID 260958)
-- Name: task_validated_by(public.tasks, json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.task_validated_by(task_row public.tasks, hasura_session json) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
	BEGIN
		RETURN (
			is_task_validated_by(task_row.id, (VALUES (hasura_session ->> 'x-hasura-user-id'))::uuid)
        );
	END
$$;


ALTER FUNCTION public.task_validated_by(task_row public.tasks, hasura_session json) OWNER TO postgres;

--
-- TOC entry 486 (class 1255 OID 260959)
-- Name: unnest_file_assignations(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.unnest_file_assignations(assignation_id uuid, OUT orgs uuid[], OUT teams uuid[], OUT users uuid[], OUT total numeric) RETURNS record
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- Select and put all orgs assignations into orgs, not need to return the "out" syntax will do the job
	SELECT COALESCE(array_agg(file_assignations_orgs.org_id), array[]::uuid[])
	FROM file_assignations_orgs
	WHERE file_assignations_orgs.file_assignation_id = assignation_id
	INTO orgs;
	-- Select and put all teams assignations into teams, not need to return the "out" syntax will do the job
	SELECT COALESCE(array_agg(file_assignations_teams.team_id), array[]::uuid[])
	FROM file_assignations_teams
	WHERE file_assignations_teams.file_assignation_id = assignation_id
	INTO teams;
	-- Select and put all users assignations into users, not need to return the "out" syntax will do the job
	SELECT COALESCE(array_agg(file_assignations_users.user_id), array[]::uuid[])
	FROM file_assignations_users
	WHERE file_assignations_users.file_assignation_id = assignation_id
	INTO users;
	SELECT
		COALESCE(array_length(orgs,1),0) + COALESCE(array_length(teams,1),0) + COALESCE(array_length(users,1),0)
	INTO total;
END
$$;


ALTER FUNCTION public.unnest_file_assignations(assignation_id uuid, OUT orgs uuid[], OUT teams uuid[], OUT users uuid[], OUT total numeric) OWNER TO postgres;

--
-- TOC entry 487 (class 1255 OID 260960)
-- Name: unnest_file_permissions(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.unnest_file_permissions(permission_id uuid, OUT orgs uuid[], OUT teams uuid[], OUT users uuid[], OUT total numeric) RETURNS record
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- Select and put all orgs permissions into orgs, not need to return the "out" syntax will do the job
	SELECT COALESCE(array_agg(file_permissions_orgs.org_id), array[]::uuid[])
	FROM file_permissions_orgs
	WHERE file_permissions_orgs.file_permission_id = permission_id
	INTO orgs;
	-- Select and put all teams permissions into teams, not need to return the "out" syntax will do the job
	SELECT COALESCE(array_agg(file_permissions_teams.team_id), array[]::uuid[])
	FROM file_permissions_teams
	WHERE file_permissions_teams.file_permission_id = permission_id
	INTO teams;
	-- Select and put all users permissions into users, not need to return the "out" syntax will do the job
	SELECT COALESCE(array_agg(file_permissions_users.user_id), array[]::uuid[])
	FROM file_permissions_users
	WHERE file_permissions_users.file_permission_id = permission_id
	INTO users;
	SELECT
		COALESCE(array_length(orgs,1),0) + COALESCE(array_length(teams,1),0) + COALESCE(array_length(users,1),0)
	INTO total;
END
$$;


ALTER FUNCTION public.unnest_file_permissions(permission_id uuid, OUT orgs uuid[], OUT teams uuid[], OUT users uuid[], OUT total numeric) OWNER TO postgres;

--
-- TOC entry 488 (class 1255 OID 260961)
-- Name: unnest_folder_permissions(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.unnest_folder_permissions(permission_id uuid, OUT orgs uuid[], OUT teams uuid[], OUT users uuid[], OUT total numeric) RETURNS record
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- Select and put all orgs permissions into orgs, not need to return the "out" syntax will do the job
	SELECT COALESCE(array_agg(folder_permissions_orgs.org_id), array[]::uuid[])
	FROM folder_permissions_orgs
	WHERE folder_permissions_orgs.folder_permission_id = permission_id
	INTO orgs;
	-- Select and put all teams permissions into teams, not need to return the "out" syntax will do the job
	SELECT COALESCE(array_agg(folder_permissions_teams.team_id), array[]::uuid[])
	FROM folder_permissions_teams
	WHERE folder_permissions_teams.folder_permission_id = permission_id
	INTO teams;
	-- Select and put all users permissions into users, not need to return the "out" syntax will do the job
	SELECT COALESCE(array_agg(folder_permissions_users.user_id), array[]::uuid[])
	FROM folder_permissions_users
	WHERE folder_permissions_users.folder_permission_id = permission_id
	INTO users;
	SELECT
		COALESCE(array_length(orgs,1),0) + COALESCE(array_length(teams,1),0) + COALESCE(array_length(users,1),0)
	INTO total;
END
$$;


ALTER FUNCTION public.unnest_folder_permissions(permission_id uuid, OUT orgs uuid[], OUT teams uuid[], OUT users uuid[], OUT total numeric) OWNER TO postgres;

--
-- TOC entry 489 (class 1255 OID 260962)
-- Name: update_file_assignation_users(uuid, uuid, uuid, uuid, uuid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_file_assignation_users(user_creator_id uuid, parent_project_id uuid, folder_parent_id uuid, current_file_id uuid, new_users uuid[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	current_assignations file_assignations;
	current_assignations_id uuid;
	entity_id_to_create uuid;
BEGIN
	-- Get the current file assignations
	current_assignations := get_file_assignations(current_file_id);
	-- If no current assignation exists, create it
	IF current_assignations.id IS NULL THEN
		INSERT INTO file_assignations(file_id) VALUES (current_file_id) RETURNING (id) INTO current_assignations_id;
	ELSE
		current_assignations_id := current_assignations.id;
	END IF;
	-- upsert for all the new users
	FOR entity_id_to_create IN (SELECT * FROM unnest(new_users)) LOOP
		INSERT INTO file_assignations_users(file_assignation_id, user_id, creator_id) VALUES (current_assignations_id, entity_id_to_create, user_creator_id) ON CONFLICT ON CONSTRAINT unique_user_by_file_assignation_id DO NOTHING;
	END LOOP;
	-- No more users on the assignation, delete it all
	IF COALESCE(array_length(new_users, 1), 0) < 1 THEN
		DELETE FROM file_assignations_users WHERE file_assignations_users.file_assignation_id = current_assignations_id;
		PERFORM cleanup_files_assignations();
	ELSE
		-- Delete all remaining users assignations not present in the new set of perms
		DELETE FROM file_assignations_users WHERE
			file_assignations_users.file_assignation_id = current_assignations_id AND
			NOT file_assignations_users.user_id = ANY(new_users);
	END IF;
	PERFORM sync_file_permissions_assignations(parent_project_id, folder_parent_id, current_file_id);
	-- Will create/update approvals requests on the file last version if necessary
	PERFORM update_file_version_approvals_requests(parent_project_id, current_file_id, new_users);
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.update_file_assignation_users(user_creator_id uuid, parent_project_id uuid, folder_parent_id uuid, current_file_id uuid, new_users uuid[]) OWNER TO postgres;

--
-- TOC entry 490 (class 1255 OID 260963)
-- Name: update_file_assignations(uuid, uuid, uuid, uuid, uuid[], uuid[], uuid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_file_assignations(user_creator_id uuid, parent_project_id uuid, folder_parent_id uuid, current_file_id uuid, new_orgs uuid[], new_teams uuid[], new_users uuid[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	current_assignations file_assignations;
	current_assignations_id uuid;
	entity_id_to_create uuid;
BEGIN
	-- Get the current file assignations
	current_assignations := get_file_assignations(current_file_id);
	-- We just want to delete all assignations on the file
	IF COALESCE(array_length(new_orgs, 1), 0) < 1 AND COALESCE(array_length(new_teams, 1), 0) < 1 AND COALESCE(array_length(new_users, 1), 0) < 1 THEN
		IF current_assignations.id IS NOT NULL THEN
			-- Delete all remaining orgs assignations not present in the new set of perms
			DELETE FROM file_assignations_orgs WHERE
				file_assignations_orgs.file_assignation_id = current_assignations.id;
			-- Delete all remaining teams assignations not present in the new set of perms
			DELETE FROM file_assignations_teams WHERE
				file_assignations_teams.file_assignation_id = current_assignations.id;
			-- Delete all remaining users assignations not present in the new set of perms
			DELETE FROM file_assignations_users WHERE
				file_assignations_users.file_assignation_id = current_assignations.id;
			-- Delete the empty file_assignation as well
			DELETE FROM file_assignations WHERE id = current_assignations.id;
		END IF;
	ELSE
		-- If no current assignation exists, create it
		IF current_assignations.id IS NULL THEN
			INSERT INTO file_assignations(file_id) VALUES (current_file_id) RETURNING (id) INTO current_assignations_id;
		ELSE
			current_assignations_id := current_assignations.id;
		END IF;
		-- upsert for all the new orgs
		FOR entity_id_to_create IN (SELECT unnest(new_orgs)) LOOP
			INSERT INTO file_assignations_orgs(file_assignation_id, org_id, creator_id) VALUES (current_assignations_id, entity_id_to_create, user_creator_id) ON CONFLICT ON CONSTRAINT unique_org_by_file_assignation_id DO NOTHING;
		END LOOP;
		-- upsert for all the new teams
		FOR entity_id_to_create IN (SELECT unnest(new_teams)) LOOP
			INSERT INTO file_assignations_teams(file_assignation_id, team_id, creator_id) VALUES (current_assignations_id, entity_id_to_create, user_creator_id) ON CONFLICT ON CONSTRAINT unique_team_by_file_assignation_id DO NOTHING;
		END LOOP;
		-- upsert for all the new users
		FOR entity_id_to_create IN (SELECT unnest(new_users)) LOOP
			INSERT INTO file_assignations_users(file_assignation_id, user_id, creator_id) VALUES (current_assignations_id, entity_id_to_create, user_creator_id) ON CONFLICT ON CONSTRAINT unique_user_by_file_assignation_id DO NOTHING;
		END LOOP;
		-- No more orgs on the assignation, delete it all
		IF COALESCE(array_length(new_orgs, 1), 0) < 1 THEN
			DELETE FROM file_assignations_orgs WHERE file_assignations_orgs.file_assignation_id = current_assignations_id;
		ELSE
			-- Delete all remaining orgs assignations not present in the new set of perms
			DELETE FROM file_assignations_orgs WHERE
				file_assignations_orgs.file_assignation_id = current_assignations_id AND
				NOT file_assignations_orgs.org_id = ANY(new_orgs);
		END IF;
		-- No more teams on the assignation, delete it all
		IF COALESCE(array_length(new_teams, 1), 0) < 1 THEN
			DELETE FROM file_assignations_teams WHERE file_assignations_teams.file_assignation_id = current_assignations_id;
		ELSE
			-- Delete all remaining teams assignations not present in the new set of perms
			DELETE FROM file_assignations_teams WHERE
				file_assignations_teams.file_assignation_id = current_assignations_id AND
				NOT file_assignations_teams.team_id = ANY(new_teams);
		END IF;
		-- No more users on the assignation, delete it all
		IF COALESCE(array_length(new_users, 1), 0) < 1 THEN
			DELETE FROM file_assignations_users WHERE file_assignations_users.file_assignation_id = current_assignations_id;
		ELSE
			-- Delete all remaining users assignations not present in the new set of perms
			DELETE FROM file_assignations_users WHERE
				file_assignations_users.file_assignation_id = current_assignations_id AND
				NOT file_assignations_users.user_id = ANY(new_users);
		END IF;
		PERFORM cleanup_files_assignations();
	END IF;
	PERFORM sync_file_permissions_assignations(parent_project_id, folder_parent_id, current_file_id);
	-- Will create/update approvals requests on the file last version if necessary
	PERFORM update_file_version_approvals_requests(parent_project_id, current_file_id, new_users);
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.update_file_assignations(user_creator_id uuid, parent_project_id uuid, folder_parent_id uuid, current_file_id uuid, new_orgs uuid[], new_teams uuid[], new_users uuid[]) OWNER TO postgres;

--
-- TOC entry 492 (class 1255 OID 260964)
-- Name: update_file_permissions(uuid, uuid, uuid, public.permission_type[], public.permission_type[], public.permission_type[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_file_permissions(parent_project_id uuid, folder_parent_id uuid, current_file_id uuid, new_orgs public.permission_type[], new_teams public.permission_type[], new_users public.permission_type[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	current_permissions file_permissions;
	current_permissions_id uuid;
	permission_to_create permission_type;
BEGIN
	-- Get the current file permissions
	current_permissions := get_file_permission(current_file_id);
	-- We just want to delete all permissions on the file
	IF COALESCE(array_length(new_orgs, 1), 0) < 1 AND COALESCE(array_length(new_teams, 1), 0) < 1 AND COALESCE(array_length(new_users, 1), 0) < 1 THEN
		IF current_permissions.id IS NOT NULL THEN
			-- Delete all remaining orgs permissions not present in the new set of perms
			DELETE FROM file_permissions_orgs WHERE
				file_permissions_orgs.file_permission_id = current_permissions.id;
			-- Delete all remaining teams permissions not present in the new set of perms
			DELETE FROM file_permissions_teams WHERE
				file_permissions_teams.file_permission_id = current_permissions.id;
			-- Delete all remaining users permissions not present in the new set of perms
			DELETE FROM file_permissions_users WHERE
				file_permissions_users.file_permission_id = current_permissions.id;
			-- Delete the empty file_permission as well
			DELETE FROM file_permissions WHERE id = current_permissions.id;
		END IF;
	ELSE
		-- If no current permission exists, create it
		IF current_permissions.id IS NULL THEN
			INSERT INTO file_permissions(file_id) VALUES (current_file_id) RETURNING (id) INTO current_permissions_id;
		ELSE
			current_permissions_id := current_permissions.id;
		END IF;
		-- upsert for all the new orgs
		FOR permission_to_create IN (SELECT * FROM unnest(new_orgs)) LOOP
			INSERT INTO file_permissions_orgs(file_permission_id, org_id, access) VALUES (current_permissions_id, permission_to_create.entity_id, permission_to_create.access) ON CONFLICT ON CONSTRAINT unique_org_by_file_permission_id DO UPDATE SET access = EXCLUDED.access;
		END LOOP;
		-- upsert for all the new teams
		FOR permission_to_create IN (SELECT * FROM unnest(new_teams)) LOOP
			INSERT INTO file_permissions_teams(file_permission_id, team_id, access) VALUES (current_permissions_id, permission_to_create.entity_id, permission_to_create.access) ON CONFLICT ON CONSTRAINT unique_team_by_file_permission_id DO UPDATE SET access = EXCLUDED.access;
		END LOOP;
		-- upsert for all the new users
		FOR permission_to_create IN (SELECT * FROM unnest(new_users)) LOOP
			INSERT INTO file_permissions_users(file_permission_id, user_id, access) VALUES (current_permissions_id, permission_to_create.entity_id, permission_to_create.access) ON CONFLICT ON CONSTRAINT unique_user_by_file_permission_id DO UPDATE SET access = EXCLUDED.access;
		END LOOP;
		-- No more orgs on the permission, delete it all
		IF COALESCE(array_length(new_orgs, 1), 0) < 1 THEN
			DELETE FROM file_permissions_orgs WHERE file_permissions_orgs.file_permission_id = current_permissions_id;
		ELSE
			-- Delete all remaining orgs permissions not present in the new set of perms
			DELETE FROM file_permissions_orgs WHERE
				file_permissions_orgs.file_permission_id = current_permissions_id AND
				NOT file_permissions_orgs.org_id IN (SELECT entity_id FROM unnest(new_orgs));
		END IF;
		-- No more teams on the permission, delete it all
		IF COALESCE(array_length(new_teams, 1), 0) < 1 THEN
			DELETE FROM file_permissions_teams WHERE file_permissions_teams.file_permission_id = current_permissions_id;
		ELSE
			-- Delete all remaining teams permissions not present in the new set of perms
			DELETE FROM file_permissions_teams WHERE
				file_permissions_teams.file_permission_id = current_permissions_id AND
				NOT file_permissions_teams.team_id IN (SELECT entity_id FROM unnest(new_teams));
		END IF;
		-- No more users on the permission, delete it all
		IF COALESCE(array_length(new_users, 1), 0) < 1 THEN
			DELETE FROM file_permissions_users WHERE file_permissions_users.file_permission_id = current_permissions_id;
		ELSE
			-- Delete all remaining users permissions not present in the new set of perms
			DELETE FROM file_permissions_users WHERE
				file_permissions_users.file_permission_id = current_permissions_id AND
				NOT file_permissions_users.user_id IN (SELECT entity_id FROM unnest(new_users));
		END IF;
		PERFORM cleanup_files_permissions();
	END IF;
	PERFORM detect_files_permissions_conflicts(parent_project_id, folder_parent_id);
	PERFORM sync_file_permissions_assignations(parent_project_id, folder_parent_id, current_file_id);
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.update_file_permissions(parent_project_id uuid, folder_parent_id uuid, current_file_id uuid, new_orgs public.permission_type[], new_teams public.permission_type[], new_users public.permission_type[]) OWNER TO postgres;

--
-- TOC entry 493 (class 1255 OID 260965)
-- Name: update_file_version_approvals_requests(uuid, uuid, uuid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_file_version_approvals_requests(parent_project_id uuid, current_file_id uuid, new_users uuid[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	current_approvals_requests file_version_approval_requests;
	entity_id_to_create uuid;
	current_file_is_approval_mode boolean;
	current_file_version_id uuid;
BEGIN
	current_file_is_approval_mode := (SELECT files.is_approval_mode FROM files WHERE files.id = current_file_id);
	IF current_file_is_approval_mode IS TRUE THEN
		-- Get the current file version
		current_file_version_id := (SELECT file_versions.id from file_versions WHERE file_versions.file_id = current_file_id ORDER BY file_versions.number DESC LIMIT 1);
		current_approvals_requests := get_file_version_approval_requests(current_file_version_id);
		IF current_approvals_requests.id IS NULL THEN
			INSERT INTO file_version_approval_requests(file_version_id) VALUES (current_file_version_id) ON CONFLICT DO NOTHING;
			current_approvals_requests := get_file_version_approval_requests(current_file_version_id);
		END IF;
		IF current_approvals_requests.id IS NOT NULL THEN
			-- upsert for all the new users
			FOR entity_id_to_create IN (SELECT * FROM unnest(new_users)) LOOP
				INSERT INTO file_version_approval_request_users(file_version_approval_request_id, user_id) VALUES (current_approvals_requests.id, entity_id_to_create) ON CONFLICT DO NOTHING;
			END LOOP;
		END IF;
	END IF;
	RETURN TRUE;
	-- Will remove any pending approvals requests incompatibles with file assignations
	PERFORM sync_file_assignations_file_version_approval_requests(parent_project_id, current_file_id);
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.update_file_version_approvals_requests(parent_project_id uuid, current_file_id uuid, new_users uuid[]) OWNER TO postgres;

--
-- TOC entry 494 (class 1255 OID 260966)
-- Name: update_folder_assignations(uuid, uuid, uuid, uuid, uuid[], uuid[], uuid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_folder_assignations(user_creator_id uuid, parent_project_id uuid, folder_parent_id uuid, current_folder_id uuid, new_orgs uuid[], new_teams uuid[], new_users uuid[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	current_assignations folder_assignations;
	current_assignations_id uuid;
	entity_id_to_create uuid;
BEGIN
	-- Get the current folder assignations
	current_assignations := get_folder_assignations(current_folder_id);
	-- We just want to delete all assignations on the folder
	IF COALESCE(array_length(new_orgs, 1), 0) < 1 AND COALESCE(array_length(new_teams, 1), 0) < 1 AND COALESCE(array_length(new_users, 1), 0) < 1 THEN
		IF current_assignations.id IS NOT NULL THEN
			-- Delete all remaining orgs assignations not present in the new set of perms
			DELETE FROM folder_assignations_orgs WHERE
				folder_assignations_orgs.folder_assignation_id = current_assignations.id;
			-- Delete all remaining teams assignations not present in the new set of perms
			DELETE FROM folder_assignations_teams WHERE
				folder_assignations_teams.folder_assignation_id = current_assignations.id;
			-- Delete all remaining users assignations not present in the new set of perms
			DELETE FROM folder_assignations_users WHERE
				folder_assignations_users.folder_assignation_id = current_assignations.id;
			-- Delete the empty folder_assignation as well
			DELETE FROM folder_assignations WHERE id = current_assignations.id;
			PERFORM cleanup_folders_assignations();
		END IF;
	ELSE
		-- If no current assignation exists, create it
		IF current_assignations.id IS NULL THEN
			INSERT INTO folder_assignations(folder_id) VALUES (current_folder_id) RETURNING (id) INTO current_assignations_id;
		ELSE
			current_assignations_id := current_assignations.id;
		END IF;
		-- upsert for all the new orgs
		FOR entity_id_to_create IN (SELECT unnest(new_orgs)) LOOP
			INSERT INTO folder_assignations_orgs(folder_assignation_id, org_id, creator_id) VALUES (current_assignations_id, entity_id_to_create, user_creator_id) ON CONFLICT ON CONSTRAINT unique_org_by_folder_assignation_id DO NOTHING;
		END LOOP;
		-- upsert for all the new teams
		FOR entity_id_to_create IN (SELECT unnest(new_teams)) LOOP
			INSERT INTO folder_assignations_teams(folder_assignation_id, team_id, creator_id) VALUES (current_assignations_id, entity_id_to_create, user_creator_id) ON CONFLICT ON CONSTRAINT unique_team_by_folder_assignation_id DO NOTHING;
		END LOOP;
		-- upsert for all the new users
		FOR entity_id_to_create IN (SELECT unnest(new_users)) LOOP
			INSERT INTO folder_assignations_users(folder_assignation_id, user_id, creator_id) VALUES (current_assignations_id, entity_id_to_create, user_creator_id) ON CONFLICT ON CONSTRAINT unique_user_by_folder_assignation_id DO NOTHING;
		END LOOP;
		-- No more orgs on the assignation, delete it all
		IF COALESCE(array_length(new_orgs, 1), 0) < 1 THEN
			DELETE FROM folder_assignations_orgs WHERE folder_assignations_orgs.folder_assignation_id = current_assignations_id;
		ELSE
			-- Delete all remaining orgs assignations not present in the new set of perms
			DELETE FROM folder_assignations_orgs WHERE
				folder_assignations_orgs.folder_assignation_id = current_assignations_id AND
				NOT folder_assignations_orgs.org_id = ANY(new_orgs);
		END IF;
		-- No more teams on the assignation, delete it all
		IF COALESCE(array_length(new_teams, 1), 0) < 1 THEN
			DELETE FROM folder_assignations_teams WHERE folder_assignations_teams.folder_assignation_id = current_assignations_id;
		ELSE
			-- Delete all remaining teams assignations not present in the new set of perms
			DELETE FROM folder_assignations_teams WHERE
				folder_assignations_teams.folder_assignation_id = current_assignations_id AND
				NOT folder_assignations_teams.team_id = ANY(new_teams);
		END IF;
		-- No more users on the assignation, delete it all
		IF COALESCE(array_length(new_users, 1), 0) < 1 THEN
			DELETE FROM folder_assignations_users WHERE folder_assignations_users.folder_assignation_id = current_assignations_id;
		ELSE
			-- Delete all remaining users assignations not present in the new set of perms
			DELETE FROM folder_assignations_users WHERE
				folder_assignations_users.folder_assignation_id = current_assignations_id AND
				NOT folder_assignations_users.user_id = ANY(new_users);
		END IF;
		PERFORM cleanup_folders_assignations();
	END IF;
	PERFORM sync_folder_permissions_assignations(parent_project_id, current_folder_id);
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.update_folder_assignations(user_creator_id uuid, parent_project_id uuid, folder_parent_id uuid, current_folder_id uuid, new_orgs uuid[], new_teams uuid[], new_users uuid[]) OWNER TO postgres;

--
-- TOC entry 495 (class 1255 OID 260967)
-- Name: update_folder_permissions(uuid, uuid, uuid, public.permission_type[], public.permission_type[], public.permission_type[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_folder_permissions(parent_project_id uuid, folder_parent_id uuid, current_folder_id uuid, new_orgs public.permission_type[], new_teams public.permission_type[], new_users public.permission_type[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	parent_permissions folder_permissions;
	current_permissions folder_permissions;
	current_permissions_id uuid;
	permission_to_create permission_type;
BEGIN
	-- Get the current folder permissions
	current_permissions := get_direct_folder_permission(current_folder_id);
	-- We just want to delete all permissions on the file
	IF COALESCE(array_length(new_orgs, 1), 0) < 1 AND COALESCE(array_length(new_teams, 1), 0) < 1 AND COALESCE(array_length(new_users, 1), 0) < 1 THEN
		-- RAISE NOTICE 'received empty permissions set';
		IF current_permissions.id IS NOT NULL THEN
			-- RAISE NOTICE 'delete all old direct permissions on this folder';
			-- Delete all remaining orgs permissions not present in the new set of perms
			DELETE FROM folder_permissions_orgs WHERE
				folder_permissions_orgs.folder_permission_id = current_permissions.id;
			-- Delete all remaining teams permissions not present in the new set of perms
			DELETE FROM folder_permissions_teams WHERE
				folder_permissions_teams.folder_permission_id = current_permissions.id;
			-- Delete all remaining users permissions not present in the new set of perms
			DELETE FROM folder_permissions_users WHERE
				folder_permissions_users.folder_permission_id = current_permissions.id;
			parent_permissions = get_direct_folder_permission(folder_parent_id);
			IF parent_permissions.id IS NOT NULL THEN
				-- RAISE NOTICE 'some permissions exists on the parent folder_permissions became inherited';
				-- Some permissions exists on the parent, the folder_permissions must became inherited
				IF parent_permissions.inherited_from IS NOT NULL THEN
					UPDATE folder_permissions SET inherited_from = parent_permissions.inherited_from WHERE folder_permissions.id = current_permissions.id;
				ELSE
					UPDATE folder_permissions SET inherited_from = folder_parent_id WHERE folder_permissions.id = current_permissions.id;
				END IF;
			ELSE
				-- No permissions comes from parent, remove the folder_permissions group
				DELETE FROM folder_permissions WHERE id = current_permissions.id;
			END IF;
			-- Folder cleanup will also be in charge of removing the permissions with now invalid inherited_from
			PERFORM cleanup_folders_permissions();
		END IF;
	ELSE
		-- RAISE NOTICE 'non empty permissions, perform update';
		-- If no current permission exists, create it
		IF current_permissions.id IS NULL THEN
			-- RAISE NOTICE 'ACT: no current permissions exist on folder, create one';
			INSERT INTO folder_permissions(folder_id) VALUES (current_folder_id) RETURNING (id) INTO current_permissions_id;
		ELSE
			current_permissions_id := current_permissions.id;
		END IF;
		-- RAISE NOTICE 'current permission id: %', current_permissions_id;
		-- upsert for all the new orgs
		FOR permission_to_create IN (SELECT * FROM unnest(new_orgs)) LOOP
			INSERT INTO folder_permissions_orgs(folder_permission_id, org_id, access) VALUES (current_permissions_id, permission_to_create.entity_id, permission_to_create.access) ON CONFLICT ON CONSTRAINT unique_org_by_folder_permission_id DO UPDATE SET access = EXCLUDED.access;
		END LOOP;
		-- upsert for all the new teams
		FOR permission_to_create IN (SELECT * FROM unnest(new_teams)) LOOP
			INSERT INTO folder_permissions_teams(folder_permission_id, team_id, access) VALUES (current_permissions_id, permission_to_create.entity_id, permission_to_create.access) ON CONFLICT ON CONSTRAINT unique_team_by_folder_permission_id DO UPDATE SET access = EXCLUDED.access;
		END LOOP;
		-- upsert for all the new users
		FOR permission_to_create IN (SELECT * FROM unnest(new_users)) LOOP
			INSERT INTO folder_permissions_users(folder_permission_id, user_id, access) VALUES (current_permissions_id, permission_to_create.entity_id, permission_to_create.access) ON CONFLICT ON CONSTRAINT unique_user_by_folder_permission_id DO UPDATE SET access = EXCLUDED.access;
		END LOOP;
		-- RAISE NOTICE 'created everyting needing to be created';
		-- No more orgs on the permission, delete it all
		IF COALESCE(array_length(new_orgs, 1), 0) < 1 THEN
			-- RAISE NOTICE 'no more orgs on it, remove them all';
			DELETE FROM folder_permissions_orgs WHERE folder_permissions_orgs.folder_permission_id = current_permissions_id;
		ELSE
			-- RAISE NOTICE 'intersect and remove old orgs';
			-- Delete all remaining orgs permissions not present in the new set of perms
			DELETE FROM folder_permissions_orgs WHERE
				folder_permissions_orgs.folder_permission_id = current_permissions_id AND
				NOT folder_permissions_orgs.org_id IN (SELECT entity_id FROM unnest(new_orgs));
		END IF;
		-- No more teams on the permission, delete it all
		IF COALESCE(array_length(new_teams, 1), 0) < 1 THEN
			-- RAISE NOTICE 'no more teams on it, remove them all';
			DELETE FROM folder_permissions_teams WHERE folder_permissions_teams.folder_permission_id = current_permissions_id;
		ELSE
			-- RAISE NOTICE 'intersect and remove old teams';
			-- Delete all remaining teams permissions not present in the new set of perms
			DELETE FROM folder_permissions_teams WHERE
				folder_permissions_teams.folder_permission_id = current_permissions_id AND
				NOT folder_permissions_teams.team_id IN (SELECT entity_id FROM unnest(new_teams));
		END IF;
		-- No more users on the permission, delete it all
		IF COALESCE(array_length(new_users, 1), 0) < 1 THEN
			-- RAISE NOTICE 'no more users on it, remove them all';
			DELETE FROM folder_permissions_users WHERE folder_permissions_users.folder_permission_id = current_permissions_id;
		ELSE
			-- RAISE NOTICE 'intersect and remove old users';
			-- Delete all remaining users permissions not present in the new set of perms
			DELETE FROM folder_permissions_users WHERE
				folder_permissions_users.folder_permission_id = current_permissions_id AND
				NOT folder_permissions_users.user_id IN (SELECT entity_id FROM unnest(new_users));
		END IF;
		PERFORM cleanup_folders_permissions();
	END IF;
	PERFORM walk_and_detect_permissions_conflicts(parent_project_id, folder_parent_id, array[current_folder_id]::uuid[]);
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.update_folder_permissions(parent_project_id uuid, folder_parent_id uuid, current_folder_id uuid, new_orgs public.permission_type[], new_teams public.permission_type[], new_users public.permission_type[]) OWNER TO postgres;

--
-- TOC entry 496 (class 1255 OID 260968)
-- Name: user_can_see_org_trough_shared_project(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_can_see_org_trough_shared_project(checked_user_id uuid, checked_org_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	BEGIN
		RETURN (
			SELECT EXISTS (
				SELECT
					1
				FROM orgs_to_users
				-- Get all the projects of all the org members
				INNER JOIN projects_to_users AS project_of_org_members ON project_of_org_members.user_id = orgs_to_users.user_id
				-- For each project of a member of the org, check if the current user is in the same project
				INNER JOIN projects_to_users AS share_project_with_member
				ON share_project_with_member.project_id = project_of_org_members.project_id
					AND share_project_with_member.user_id = checked_user_id
				WHERE
					orgs_to_users.org_id = checked_org_id
				LIMIT 1
			)
		);
	END
$$;


ALTER FUNCTION public.user_can_see_org_trough_shared_project(checked_user_id uuid, checked_org_id uuid) OWNER TO postgres;

--
-- TOC entry 497 (class 1255 OID 260969)
-- Name: user_can_see_project_trough_their_org(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_can_see_project_trough_their_org(checked_user_id uuid, checked_project_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	BEGIN
		RETURN (
			SELECT EXISTS (
				SELECT 1
				-- This "table" is a materialized view in charge of storing which user can see a project trough org members
				-- EG: u1 and u2 members of org O1 and project p1
				-- u3 member of org O1 with role "standard" can see project p1 because he share the same org as u1 and u2
				FROM orgs_projects_users
				WHERE orgs_projects_users.user_id = checked_user_id AND orgs_projects_users.project_id = checked_project_id
				LIMIT 1
			)
		);
	END
$$;


ALTER FUNCTION public.user_can_see_project_trough_their_org(checked_user_id uuid, checked_project_id uuid) OWNER TO postgres;

--
-- TOC entry 476 (class 1255 OID 260970)
-- Name: user_can_see_user_trough_shared_org(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_can_see_user_trough_shared_org(current_user_id uuid, checked_user_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	BEGIN
		RETURN (
			SELECT EXISTS (
				SELECT
					1
				-- Get the orgs of the current user is a member of
				FROM orgs_to_users AS orgs_of_current_user
				-- Search in all members of those orgs, if the searched user is a member of it
				INNER JOIN orgs_to_users AS members_of_current_user_orgs ON members_of_current_user_orgs.org_id = orgs_of_current_user.org_id
					AND members_of_current_user_orgs.user_id = checked_user_id
				WHERE
				-- Actually apply the  "orgs of the current user is a member of" filter
					orgs_of_current_user.user_id = current_user_id
				LIMIT 1
			)
		);
	END
$$;


ALTER FUNCTION public.user_can_see_user_trough_shared_org(current_user_id uuid, checked_user_id uuid) OWNER TO postgres;

--
-- TOC entry 498 (class 1255 OID 260971)
-- Name: user_can_see_user_trough_shared_project(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_can_see_user_trough_shared_project(current_user_id uuid, checked_user_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	BEGIN
		RETURN (
			SELECT EXISTS (
				SELECT
					1
				-- Get the projects of the current user is a member of
				FROM projects_to_users AS projects_of_current_user
				-- Search in all members of those projects, if the searched user is a member of it
				INNER JOIN projects_to_users AS members_of_current_user_projects ON members_of_current_user_projects.project_id = projects_of_current_user.project_id
					AND members_of_current_user_projects.user_id = checked_user_id
				WHERE
				-- Actually apply the  "projects of the current user is a member of" filter
					projects_of_current_user.user_id = current_user_id
				LIMIT 1
			)
		);
	END
$$;


ALTER FUNCTION public.user_can_see_user_trough_shared_project(current_user_id uuid, checked_user_id uuid) OWNER TO postgres;

--
-- TOC entry 499 (class 1255 OID 260972)
-- Name: user_company_name(public.users); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_company_name(user_row public.users) RETURNS text
    LANGUAGE sql STABLE
    AS $$
  SELECT get_user_company_name(user_row.id);
$$;


ALTER FUNCTION public.user_company_name(user_row public.users) OWNER TO postgres;

--
-- TOC entry 500 (class 1255 OID 260973)
-- Name: user_country_code(public.users); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_country_code(user_row public.users) RETURNS text
    LANGUAGE sql STABLE
    AS $$
  SELECT get_user_country_code(user_row.id);
$$;


ALTER FUNCTION public.user_country_code(user_row public.users) OWNER TO postgres;

--
-- TOC entry 501 (class 1255 OID 260974)
-- Name: user_full_name(public.users); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_full_name(user_row public.users) RETURNS text
    LANGUAGE sql STABLE
    AS $$
  SELECT user_row.first_name || ' ' || user_row.last_name
$$;


ALTER FUNCTION public.user_full_name(user_row public.users) OWNER TO postgres;

--
-- TOC entry 502 (class 1255 OID 260975)
-- Name: user_has_file_access(uuid, uuid, uuid, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_has_file_access(checked_user_id uuid, checked_file_id uuid, checked_parent_id uuid, required_access text[]) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
  DECLARE
	-- Will check if the file have any permissions set, either on it
	-- or inherited from another file
	file_have_permissions boolean;
  BEGIN
	-- We know that user have access to the project, now we check if the file actually have permissions set on it
	file_have_permissions := (SELECT EXISTS (
		SELECT
			file_permissions.file_id
		FROM file_permissions
			LEFT JOIN file_permissions_users ON file_permissions_users.file_permission_id = file_permissions.id
			LEFT JOIN file_permissions_orgs ON file_permissions_orgs.file_permission_id = file_permissions.id
			LEFT JOIN file_permissions_teams ON file_permissions_teams.file_permission_id = file_permissions.id
		WHERE
			file_permissions.file_id = checked_file_id
			AND (
				file_permissions_users.file_permission_id IS NOT NULL
				OR file_permissions_orgs.file_permission_id IS NOT NULL
				OR file_permissions_teams.file_permission_id IS NOT NULL
			)
	));
	IF file_have_permissions THEN
		RETURN user_has_file_permission_access(checked_user_id, checked_file_id, required_access);
	ELSE
		-- If there is no permissions on the file, check the permissions on the parent folder
		RETURN user_has_folder_access(checked_user_id, checked_parent_id, required_access);
	END IF;
  END
$$;


ALTER FUNCTION public.user_has_file_access(checked_user_id uuid, checked_file_id uuid, checked_parent_id uuid, required_access text[]) OWNER TO postgres;

--
-- TOC entry 503 (class 1255 OID 260976)
-- Name: user_has_file_permission_access(uuid, uuid, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_has_file_permission_access(checked_user_id uuid, checked_file_id uuid, required_access text[]) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
  DECLARE
    has_permission_trough_user_permissions boolean;
	has_permission_trough_org_permissions boolean;
	has_permission_trough_team_permissions boolean;
  BEGIN
	-- Check if our user have access directly assigned as "user"
	has_permission_trough_user_permissions := (SELECT EXISTS (
		SELECT
			file_permissions_users.access AS access
		FROM
			file_permissions
		INNER JOIN
			file_permissions_users ON file_permissions_users.file_permission_id = file_permissions.id
		WHERE
			file_permissions.file_id = checked_file_id
			AND file_permissions_users.user_id = checked_user_id
		LIMIT 1
	));
	IF has_permission_trough_user_permissions THEN
		-- If our user have a permssion it override all other permissions, so early exit by checking if it match the required access
		RETURN (SELECT EXISTS (
			SELECT
				file_permissions_users.access AS access
			FROM
				file_permissions
			INNER JOIN
				file_permissions_users ON file_permissions_users.file_permission_id = file_permissions.id
			WHERE
				file_permissions.file_id = checked_file_id
				AND file_permissions_users.user_id = checked_user_id
				AND file_permissions_users.access = ANY(required_access)
			LIMIT 1
		));
	ELSE
		-- If the user doesn't have the "user" permission assigned, then continue and check if our user have access via "teams" permissions
		has_permission_trough_team_permissions := (SELECT EXISTS (
			SELECT
				file_permissions_teams.access AS access
			FROM
				file_permissions
			INNER JOIN
				file_permissions_teams ON file_permissions_teams.file_permission_id = file_permissions.id
			LEFT JOIN
				-- if the user is member of the designated team
				teams_to_users ON teams_to_users.team_id = file_permissions_teams.team_id
			WHERE
				file_permissions.file_id = checked_file_id
				AND teams_to_users.user_id = checked_user_id
			LIMIT 1
		));
		IF has_permission_trough_team_permissions THEN
			-- If our user have a permssion via team it override orgs permissions, so early exit by checking if it match the required access
			RETURN (SELECT EXISTS (
				SELECT
					file_permissions_teams.access AS access
				FROM
					file_permissions
				INNER JOIN
					file_permissions_teams ON file_permissions_teams.file_permission_id = file_permissions.id
				LEFT JOIN
					-- if the user is member of the designated team
					teams_to_users ON teams_to_users.team_id = file_permissions_teams.team_id
				WHERE
					file_permissions.file_id = checked_file_id
					AND teams_to_users.user_id = checked_user_id
					AND file_permissions_teams.access = ANY(required_access)
				LIMIT 1
			));
		ELSE
			-- If the user doesn't have the "user" or "teams" permission assigned, then continue and check if our user have access via "orgs" permissions
			has_permission_trough_org_permissions := (SELECT EXISTS (
				SELECT
					file_permissions_orgs.access AS access
				FROM
					file_permissions
				INNER JOIN
					file_permissions_orgs ON file_permissions_orgs.file_permission_id = file_permissions.id
				-- If the user is in the org members
				LEFT JOIN
					orgs_to_users ON orgs_to_users.org_id = file_permissions_orgs.org_id AND orgs_to_users.user_id = checked_user_id
				WHERE
					file_permissions.file_id = checked_file_id
					AND orgs_to_users.user_id = checked_user_id
					AND file_permissions_orgs.access = ANY(required_access)
				LIMIT 1
			));
			IF has_permission_trough_org_permissions THEN
				RETURN TRUE;
			END IF;
		END IF;
	-- If none of our permissions checks already returned TRUE, the user don't have access to the file
	RETURN FALSE;
	END IF;
  END
$$;


ALTER FUNCTION public.user_has_file_permission_access(checked_user_id uuid, checked_file_id uuid, required_access text[]) OWNER TO postgres;

--
-- TOC entry 504 (class 1255 OID 260977)
-- Name: user_has_folder_access(uuid, uuid, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_has_folder_access(checked_user_id uuid, checked_folder_id uuid, required_access text[]) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
  DECLARE
	-- Will check if the folder have any permissions set, either on it
	-- or inherited from another folder
	folder_have_permissions boolean;
  BEGIN
	-- Check if the folder actually have permissions set on it
	folder_have_permissions := (SELECT EXISTS (
		SELECT
			folder_permissions.folder_id
		FROM folder_permissions
			LEFT JOIN folder_permissions_users ON folder_permissions_users.folder_permission_id = folder_permissions.id
			LEFT JOIN folder_permissions_orgs ON folder_permissions_orgs.folder_permission_id = folder_permissions.id
			LEFT JOIN folder_permissions_teams ON folder_permissions_teams.folder_permission_id = folder_permissions.id
		WHERE
			folder_permissions.folder_id = checked_folder_id
			AND (
				folder_permissions.inherited_from IS NOT NULL
				OR folder_permissions_users.folder_permission_id IS NOT NULL
				OR folder_permissions_orgs.folder_permission_id IS NOT NULL
				OR folder_permissions_teams.folder_permission_id IS NOT NULL
			)
	));
	IF folder_have_permissions THEN
		RETURN user_has_folder_permission_access(checked_user_id, checked_folder_id, required_access);
	ELSE
		-- If the user have none permissions neither inherited or assigned, it's public to all project members
		RETURN TRUE;
	END IF;
  END
$$;


ALTER FUNCTION public.user_has_folder_access(checked_user_id uuid, checked_folder_id uuid, required_access text[]) OWNER TO postgres;

--
-- TOC entry 505 (class 1255 OID 260978)
-- Name: user_has_folder_permission_access(uuid, uuid, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_has_folder_permission_access(checked_user_id uuid, checked_folder_id uuid, required_access text[]) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
  DECLARE
    has_permission_trough_user_permissions boolean;
	has_permission_trough_org_permissions boolean;
	has_permission_trough_team_permissions boolean;
	folder_inhertied_from uuid;
  BEGIN
	-- First, we check if our permissions come from and inherited_from
  	folder_inhertied_from := (
		SELECT folder_permissions.inherited_from
			FROM folder_permissions
		WHERE
			folder_permissions.folder_id = checked_folder_id
		AND folder_permissions.inherited_from IS NOT NULL
	);
	IF folder_inhertied_from IS NOT NULL THEN
		-- Call back our function with the folder from wich our permission is actually set
		RETURN user_has_folder_permission_access(checked_user_id, folder_inhertied_from, required_access);
	-- The permission is actually set on our current folder, we can start to apply our rules
	-- We do it into nestead IF/ELSE to keep our number of queries to 3/folders maximum
	-- And we check it from the less "heavy" query to the one with biggest computation time
	ELSE
		-- Check if our user have access directly assigned as "user"
		has_permission_trough_user_permissions := (SELECT EXISTS (
			SELECT
				folder_permissions_users.access AS access
			FROM
				folder_permissions
			INNER JOIN
				folder_permissions_users ON folder_permissions_users.folder_permission_id = folder_permissions.id
			WHERE
				folder_permissions.folder_id = checked_folder_id
				AND folder_permissions_users.user_id = checked_user_id
			LIMIT 1
		));
		IF has_permission_trough_user_permissions THEN
			-- If our user have a permssion it override all other permissions, so early exit by checking if it match the required access
			RETURN (SELECT EXISTS (
				SELECT
					folder_permissions_users.access AS access
				FROM
					folder_permissions
				INNER JOIN
					folder_permissions_users ON folder_permissions_users.folder_permission_id = folder_permissions.id
				WHERE
					folder_permissions.folder_id = checked_folder_id
					AND folder_permissions_users.user_id = checked_user_id
					AND folder_permissions_users.access = ANY(required_access)
				LIMIT 1
			));
		ELSE
			-- If the user doesn't have the "user" permission assigned, then continue and check if our user have access via "teams" permissions
			has_permission_trough_team_permissions := (SELECT EXISTS (
				SELECT
					folder_permissions_teams.access AS access
				FROM
					folder_permissions
				INNER JOIN
					folder_permissions_teams ON folder_permissions_teams.folder_permission_id = folder_permissions.id
				LEFT JOIN
					-- if the user is member of the designated team
					teams_to_users ON teams_to_users.team_id = folder_permissions_teams.team_id
				WHERE
					folder_permissions.folder_id = checked_folder_id
					AND teams_to_users.user_id = checked_user_id
				LIMIT 1
			));
			IF has_permission_trough_team_permissions THEN
				-- If our team have a permssion on the folder, check that it match the required access
				RETURN (SELECT EXISTS (
					SELECT
						folder_permissions_teams.access AS access
					FROM
						folder_permissions
					INNER JOIN
						folder_permissions_teams ON folder_permissions_teams.folder_permission_id = folder_permissions.id
					LEFT JOIN
						-- if the user is member of the designated team
						teams_to_users ON teams_to_users.team_id = folder_permissions_teams.team_id
					WHERE
						folder_permissions.folder_id = checked_folder_id
						AND teams_to_users.user_id = checked_user_id
						AND folder_permissions_teams.access = ANY(required_access)
					LIMIT 1
				));
			ELSE
				-- If the user doesn't have the "user" or "team" permission assigned, then continue and check if our user have access via "orgs" permissions
				has_permission_trough_org_permissions := (SELECT EXISTS (
					SELECT
						folder_permissions_orgs.access AS access
					FROM
						folder_permissions
					INNER JOIN
						folder_permissions_orgs ON folder_permissions_orgs.folder_permission_id = folder_permissions.id
					LEFT JOIN
						-- if the user is member of the designated orgs
						orgs_to_users ON orgs_to_users.org_id = folder_permissions_orgs.org_id AND orgs_to_users.user_id = checked_user_id
					WHERE
						folder_permissions.folder_id = checked_folder_id
						AND orgs_to_users.user_id = checked_user_id
						AND folder_permissions_orgs.access = ANY(required_access)
					LIMIT 1
				));
				IF has_permission_trough_org_permissions THEN
					RETURN TRUE;
				END IF;
			END IF;
		END IF;
	-- If none of our permissions checks already returned TRUE, the user don't have access to the folder
	RETURN FALSE;
	END IF;
  END
$$;


ALTER FUNCTION public.user_has_folder_permission_access(checked_user_id uuid, checked_folder_id uuid, required_access text[]) OWNER TO postgres;

--
-- TOC entry 506 (class 1255 OID 260979)
-- Name: user_has_org_read_access(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_has_org_read_access(checked_user_id uuid, checked_org_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	BEGIN
		RETURN user_is_org_member(checked_user_id, checked_org_id) OR user_can_see_org_trough_shared_project(checked_user_id, checked_org_id);
	END
$$;


ALTER FUNCTION public.user_has_org_read_access(checked_user_id uuid, checked_org_id uuid) OWNER TO postgres;

--
-- TOC entry 491 (class 1255 OID 260980)
-- Name: user_has_org_role(uuid, uuid, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_has_org_role(checked_user_id uuid, checked_org_id uuid, allowed_roles text[]) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	BEGIN
		RETURN (
			SELECT EXISTS (
				SELECT
					orgs_to_users.role_id
				FROM orgs_to_users
				WHERE
					orgs_to_users.user_id = checked_user_id
					AND orgs_to_users.project_id = checked_org_id
					AND orgs_to_users.role_id = ANY(allowed_roles)
			LIMIT 1
		));
	END
$$;


ALTER FUNCTION public.user_has_org_role(checked_user_id uuid, checked_org_id uuid, allowed_roles text[]) OWNER TO postgres;

--
-- TOC entry 375 (class 1255 OID 260981)
-- Name: user_has_project_read_access(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_has_project_read_access(checked_user_id uuid, checked_project_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	BEGIN
		RETURN user_is_project_member_enabled(checked_user_id, checked_project_id) OR user_can_see_project_trough_their_org(checked_user_id, checked_project_id);
	END
$$;


ALTER FUNCTION public.user_has_project_read_access(checked_user_id uuid, checked_project_id uuid) OWNER TO postgres;

--
-- TOC entry 415 (class 1255 OID 260982)
-- Name: user_has_project_role(uuid, uuid, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_has_project_role(checked_user_id uuid, checked_project_id uuid, allowed_roles text[]) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	BEGIN
		RETURN (
			SELECT EXISTS (
				SELECT
					projects_to_users.role_id
				FROM projects_to_users
				WHERE
					projects_to_users.user_id = checked_user_id
					AND projects_to_users.project_id = checked_project_id
					AND projects_to_users.role_id = ANY(allowed_roles)
			LIMIT 1
		));
	END
$$;


ALTER FUNCTION public.user_has_project_role(checked_user_id uuid, checked_project_id uuid, allowed_roles text[]) OWNER TO postgres;

--
-- TOC entry 445 (class 1255 OID 260983)
-- Name: user_has_user_read_access(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_has_user_read_access(current_user_id uuid, checked_user_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	BEGIN
		RETURN user_can_see_user_trough_shared_org(current_user_id, checked_user_id) OR user_can_see_user_trough_shared_project(current_user_id, checked_user_id);
	END
$$;


ALTER FUNCTION public.user_has_user_read_access(current_user_id uuid, checked_user_id uuid) OWNER TO postgres;

--
-- TOC entry 380 (class 1255 OID 260984)
-- Name: user_is_org_member(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_is_org_member(checked_user_id uuid, checked_org_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	BEGIN
		RETURN (
			SELECT EXISTS (
				SELECT 1
				FROM orgs_to_users
				WHERE orgs_to_users.user_id = checked_user_id AND orgs_to_users.org_id = checked_org_id
				LIMIT 1
			)
		);
	END
$$;


ALTER FUNCTION public.user_is_org_member(checked_user_id uuid, checked_org_id uuid) OWNER TO postgres;

--
-- TOC entry 392 (class 1255 OID 260985)
-- Name: user_is_project_member_enabled(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_is_project_member_enabled(checked_user_id uuid, checked_project_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
	BEGIN
		RETURN (
			SELECT EXISTS (
				SELECT 1
				FROM projects_to_users
				WHERE projects_to_users.user_id = checked_user_id AND projects_to_users.project_id = checked_project_id AND projects_to_users.role_id <> 'disabled'
				LIMIT 1
			)
		);
	END
$$;


ALTER FUNCTION public.user_is_project_member_enabled(checked_user_id uuid, checked_project_id uuid) OWNER TO postgres;

--
-- TOC entry 507 (class 1255 OID 260986)
-- Name: walk_and_detect_permissions_conflicts(uuid, uuid, uuid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.walk_and_detect_permissions_conflicts(parent_project_id uuid, parent_folder_id uuid, child_folders uuid[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	parent_folder_perms folder_permissions;
	child_folder_perms folder_permissions;
	child_inherited_perms folder_permissions;
	unnested_parent_folder_perms record;
	unnested_child_folder_perms record;
	all_possibles_users uuid[];
	next_childs uuid[];
	files_permissions_ids uuid[];
	files_assignations_ids uuid[];
	child_folder_id uuid;
BEGIN
	-- RAISE NOTICE 'walk_and_resolve: =======================> check into: %', parent_folder_id;
	files_permissions_ids := (
		SELECT
			COALESCE(array_agg(file_permissions.id), array[]::uuid[])
		FROM file_permissions
		LEFT JOIN files ON file_permissions.file_id = files.id
		WHERE files.parent_id = parent_folder_id
	);
	files_assignations_ids := (
		SELECT
			COALESCE(array_agg(file_assignations.file_id), array[]::uuid[])
		FROM file_assignations
		LEFT JOIN files ON file_assignations.file_id = files.id
		WHERE files.parent_id = parent_folder_id
	);
	-- RAISE NOTICE 'files_assignations_ids: %', files_assignations_ids;
	IF COALESCE(array_length(files_permissions_ids, 1), 0) < 1 AND COALESCE(array_length(files_assignations_ids,1), 0) < 1  AND COALESCE(array_length(child_folders,1), 0) < 1 THEN
		-- RAISE NOTICE 'files_permissions, assignations and child folders are empty, early exit';
		RETURN TRUE;
	END IF;
	parent_folder_perms := get_folder_permission(parent_folder_id);
	IF parent_folder_perms.id IS NOT NULL THEN
		-- RAISE NOTICE 'parent_folder_perms: %', parent_folder_perms;
		IF parent_folder_perms.inherited_from IS NOT NULL THEN
			-- RAISE NOTICE 'extract permissions from parent inherited_from';
			parent_folder_perms := get_direct_folder_permission(parent_folder_perms.inherited_from);
		END IF;
		unnested_parent_folder_perms := unnest_folder_permissions(parent_folder_perms.id);
		all_possibles_users := get_all_possibles_users_from_permissions(
			parent_project_id,
			unnested_parent_folder_perms.orgs, unnested_parent_folder_perms.teams, unnested_parent_folder_perms.users
		);
		-- RAISE NOTICE 'parent_folder_perms is not null, resolve conflicts between his permissions and assignations';
		PERFORM resolve_folder_permissions_assignations_conflicts(
			parent_project_id,
			unnested_parent_folder_perms.orgs, unnested_parent_folder_perms.teams, all_possibles_users,
			parent_folder_id
		);
		PERFORM detect_files_permissions_conflicts(parent_project_id, parent_folder_id);
		PERFORM resolve_files_permissions_assignations_conflicts(parent_project_id, parent_folder_id);
	END IF;
	-- Perform conflict resolutions on child folders
	FOR child_folder_id IN SELECT unnest(child_folders) LOOP
		-- RAISE NOTICE 'check child: %', child_folder_id;
		child_folder_perms := get_direct_folder_permission(child_folder_id);
		IF parent_folder_perms.id IS NULL THEN
			-- RAISE NOTICE 'no parent permissions';
			IF child_folder_perms.id IS NULL THEN
				-- RAISE NOTICE 'parent and current have no permissions, NOTHING TODO';
			ELSE
				IF child_folder_perms.inherited_from IS NULL THEN
					-- RAISE NOTICE 'current permissions are on the folder itself, NOTHING TODO';
				ELSE
					-- RAISE NOTICE 'ACT: child_folder_perms are inherited from other ones, bring thems on the current folder directly';
					PERFORM copy_inherited_from_permissions_on_folder(
						parent_project_id,
						child_folder_perms.inherited_from,
						child_folder_id
					);
				END IF;
			END IF;
		ELSE
			-- RAISE NOTICE 'parent permissions exists';
			IF child_folder_perms.id IS NULL THEN
				-- RAISE NOTICE 'ACT: child has no permissions, create one and make it inherit';
				INSERT INTO folder_permissions(folder_id, inherited_from)
				VALUES (child_folder_id, COALESCE(parent_folder_perms.inherited_from, parent_folder_perms.folder_id)) ON CONFLICT (folder_id) DO NOTHING;
			ELSE
				-- RAISE NOTICE 'child has permissions: %', child_folder_perms;
				IF child_folder_perms.inherited_from IS NOT NULL AND parent_folder_perms.inherited_from IS NOT NULL THEN
					-- RAISE NOTICE 'child has permissions inherited_from and parent also inherit_from, update the inherited_from of the child';
					IF child_folder_perms.inherited_from != parent_folder_perms.inherited_from THEN
						-- RAISE NOTICE 'ACT: update inherited_from';
						UPDATE folder_permissions SET inherited_from = parent_folder_perms.inherited_from WHERE id = child_folder_perms.id;
					ELSE
						-- RAISE NOTICE 'child already have proper inherited, NOTHING TODO';
					END IF;
				ELSEIF child_folder_perms.inherited_from IS NOT NULL AND parent_folder_perms.inherited_from IS NULL THEN
					-- RAISE NOTICE 'child has permissions inherited_from and parent doesnt, update the inherited_from of the child with parent.folder_id';
					IF child_folder_perms.inherited_from != parent_folder_perms.folder_id THEN
						-- RAISE NOTICE 'ACT: update inherited_from';
						UPDATE folder_permissions SET inherited_from = parent_folder_perms.folder_id WHERE id = child_folder_perms.id;
					ELSE
						-- RAISE NOTICE 'child already have proper inherited, NOTHING TODO';
					END IF;
				ELSEIF child_folder_perms.inherited_from IS NULL AND parent_folder_perms.inherited_from IS NOT NULL THEN
					-- RAISE NOTICE 'child have direct permissions and parent have inherited permissions';
					PERFORM detect_child_folder_permissions_conflicts(
						parent_project_id,
						parent_folder_perms.inherited_from, parent_folder_perms.folder_id,
						unnested_parent_folder_perms.orgs, unnested_parent_folder_perms.teams, all_possibles_users,
						child_folder_perms.id
					);
				ELSE
					-- RAISE NOTICE 'child have direct permissions and parent have direct permissions';
					PERFORM detect_child_folder_permissions_conflicts(
						parent_project_id,
						parent_folder_perms.inherited_from, parent_folder_perms.folder_id,
						unnested_parent_folder_perms.orgs, unnested_parent_folder_perms.teams, all_possibles_users,
						child_folder_perms.id
					);
				END IF;
			END IF;
		END IF;
		PERFORM walk_and_detect_permissions_conflicts(
			parent_project_id,
			child_folder_id,
			(SELECT COALESCE(array_agg(folders.id), array[]::uuid[]) FROM folders WHERE folders.parent_id = child_folder_id)
		);
		PERFORM sync_folder_permissions_assignations(parent_project_id, child_folder_id);
	END LOOP;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.walk_and_detect_permissions_conflicts(parent_project_id uuid, parent_folder_id uuid, child_folders uuid[]) OWNER TO postgres;

--
-- TOC entry 508 (class 1255 OID 260987)
-- Name: walk_and_resolve_permissions_conflicts(uuid, uuid, uuid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.walk_and_resolve_permissions_conflicts(parent_project_id uuid, parent_folder_id uuid, child_folders uuid[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	parent_folder_perms folder_permissions;
	child_folder_perms folder_permissions;
	unnested_parent_folder_perms record;
	unnested_child_folder_perms record;
	all_possibles_users uuid[];
	next_childs uuid[];
	files_permissions_ids uuid[];
	files_assignations_ids uuid[];
	child_folder_id uuid;
BEGIN
	-- RAISE NOTICE 'walk_and_resolve: =======================> check into: %', parent_folder_id;
	files_permissions_ids := (
		SELECT
			COALESCE(array_agg(file_permissions.id), array[]::uuid[])
		FROM file_permissions
		LEFT JOIN files ON file_permissions.file_id = files.id
		WHERE files.parent_id = parent_folder_id
	);
	files_assignations_ids := (
		SELECT
			COALESCE(array_agg(file_assignations.file_id), array[]::uuid[])
		FROM file_assignations
		LEFT JOIN files ON file_assignations.file_id = files.id
		WHERE files.parent_id = parent_folder_id
	);
	-- RAISE NOTICE 'files_assignations_ids: %', files_assignations_ids;
	IF COALESCE(array_length(files_permissions_ids, 1), 0) < 1 AND COALESCE(array_length(files_assignations_ids,1), 0) < 1  AND COALESCE(array_length(child_folders,1), 0) < 1 THEN
		-- RAISE NOTICE 'files_permissions, assignations and child folders are empty, early exit';
		RETURN TRUE;
	END IF;
	parent_folder_perms := get_folder_permission(parent_folder_id);
	IF parent_folder_perms.id IS NOT NULL THEN
		-- RAISE NOTICE 'parent_folder_perms: %', parent_folder_perms;
		IF parent_folder_perms.inherited_from IS NOT NULL THEN
			-- RAISE NOTICE 'extract permissions from parent inherited_from';
			parent_folder_perms := get_direct_folder_permission(parent_folder_perms.inherited_from);
		END IF;
		unnested_parent_folder_perms := unnest_folder_permissions(parent_folder_perms.id);
		all_possibles_users := get_all_possibles_users_from_permissions(
			parent_project_id,
			unnested_parent_folder_perms.orgs, unnested_parent_folder_perms.teams, unnested_parent_folder_perms.users
		);
		-- RAISE NOTICE 'parent_folder_perms is not null, resolve conflicts between his permissions and assignations';
		PERFORM resolve_folder_permissions_assignations_conflicts(
			parent_project_id,
			unnested_parent_folder_perms.orgs, unnested_parent_folder_perms.teams, all_possibles_users,
			parent_folder_id
		);
		PERFORM resolve_files_permissions_conflicts(parent_project_id, parent_folder_id);
		PERFORM resolve_files_permissions_assignations_conflicts(parent_project_id, parent_folder_id);
	END IF;
	-- Perform conflict resolutions on child folders
	FOR child_folder_id IN SELECT unnest(child_folders) LOOP
		-- RAISE NOTICE 'check child: %', child_folder_id;
		child_folder_perms := get_direct_folder_permission(child_folder_id);
		IF parent_folder_perms.id IS NULL THEN
			-- RAISE NOTICE 'no parent permissions';
			IF child_folder_perms.id IS NULL THEN
				-- RAISE NOTICE 'parent and current have no permissions, NOTHING TODO';
			ELSE
				IF child_folder_perms.inherited_from IS NULL THEN
					-- RAISE NOTICE 'current permissions are on the folder itself, NOTHING TODO';
				ELSE
					-- RAISE NOTICE 'ACT: child_folder_perms are inherited from other ones, bring thems on the current folder directly';
					PERFORM copy_inherited_from_permissions_on_folder(
						parent_project_id,
						child_folder_perms.inherited_from,
						child_folder_id
					);
				END IF;
			END IF;
		ELSE
			-- RAISE NOTICE 'parent permissions exists';
			IF child_folder_perms.id IS NULL THEN
				-- RAISE NOTICE 'ACT: child has no permissions, create one and make it inherit';
				INSERT INTO folder_permissions(folder_id, inherited_from)
				VALUES (child_folder_id, COALESCE(parent_folder_perms.inherited_from, parent_folder_perms.folder_id)) ON CONFLICT (folder_id) DO NOTHING;
			ELSE
				-- RAISE NOTICE 'child has permissions: %', child_folder_perms;
				IF child_folder_perms.inherited_from IS NOT NULL AND parent_folder_perms.inherited_from IS NOT NULL THEN
					-- RAISE NOTICE 'child has permissions inherited_from and parent also inherit_from, update the inherited_from of the child';
					IF child_folder_perms.inherited_from != parent_folder_perms.inherited_from THEN
						-- RAISE NOTICE 'ACT: update inherited_from';
						UPDATE folder_permissions SET inherited_from = parent_folder_perms.inherited_from WHERE id = child_folder_perms.id;
					ELSE
						-- RAISE NOTICE 'child already have proper inherited, NOTHING TODO';
					END IF;
				ELSEIF child_folder_perms.inherited_from IS NOT NULL AND parent_folder_perms.inherited_from IS NULL THEN
					-- RAISE NOTICE 'child has permissions inherited_from and parent doesnt, update the inherited_from of the child with parent.folder_id';
					IF child_folder_perms.inherited_from != parent_folder_perms.folder_id THEN
						-- RAISE NOTICE 'ACT: update inherited_from';
						UPDATE folder_permissions SET inherited_from = parent_folder_perms.folder_id WHERE id = child_folder_perms.id;
					ELSE
						-- RAISE NOTICE 'child already have proper inherited, NOTHING TODO';
					END IF;
				ELSEIF child_folder_perms.inherited_from IS NULL AND parent_folder_perms.inherited_from IS NOT NULL THEN
					-- RAISE NOTICE 'child have direct permissions and parent have permissions inherited';
					PERFORM resolve_child_folder_permissions(
						parent_project_id,
						parent_folder_perms.inherited_from, parent_folder_perms.folder_id,
						unnested_parent_folder_perms.orgs, unnested_parent_folder_perms.teams, all_possibles_users,
						child_folder_perms.id
					);
				ELSE
					-- RAISE NOTICE 'child have direct permissions and parent have direct permissions';
					PERFORM resolve_child_folder_permissions(
						parent_project_id,
						parent_folder_perms.inherited_from, parent_folder_perms.folder_id,
						unnested_parent_folder_perms.orgs, unnested_parent_folder_perms.teams, all_possibles_users,
						child_folder_perms.id
					);
				END IF;
			END IF;
		END IF;
		PERFORM walk_and_resolve_permissions_conflicts(
			parent_project_id,
			child_folder_id,
			(SELECT COALESCE(array_agg(folders.id), array[]::uuid[]) FROM folders WHERE folders.parent_id = child_folder_id)
		);
		PERFORM sync_folder_permissions_assignations(parent_project_id, child_folder_id);
	END LOOP;
	RETURN TRUE;
END
$$;


ALTER FUNCTION public.walk_and_resolve_permissions_conflicts(parent_project_id uuid, parent_folder_id uuid, child_folders uuid[]) OWNER TO postgres;



--
-- TOC entry 5202 (class 0 OID 260988)
-- Dependencies: 230
-- Data for Name: event_invocation_logs; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--



--
-- TOC entry 5203 (class 0 OID 260995)
-- Dependencies: 231
-- Data for Name: event_log; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--



--
-- TOC entry 5204 (class 0 OID 261006)
-- Dependencies: 232
-- Data for Name: hdb_action_log; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--



--
-- TOC entry 5205 (class 0 OID 261014)
-- Dependencies: 233
-- Data for Name: hdb_cron_event_invocation_logs; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--



--
-- TOC entry 5206 (class 0 OID 261021)
-- Dependencies: 234
-- Data for Name: hdb_cron_events; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--



--
-- TOC entry 5207 (class 0 OID 261031)
-- Dependencies: 235
-- Data for Name: hdb_metadata; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

INSERT INTO hdb_catalog.hdb_metadata VALUES (1, '{"allowlist":[{"collection":"allowed-queries","scope":{"global":true}}],"sources":[{"kind":"postgres","name":"default","tables":[{"select_permissions":[{"role":"user","permission":{"columns":["id","weekly_report","unread_notification_report","invitation","user_id"],"filter":{}}}],"table":{"schema":"public","name":"email_notifications"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","payload","type"],"limit":10,"filter":{"creator_id":{"_eq":"X-Hasura-User-Id"}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"creator_id"},"name":"user"}],"event_triggers":[{"definition":{"enable_manual":false,"insert":{"columns":"*"}},"webhook_from_env":"EVENT_SERVER_URL","name":"events","request_transform":{"body":{"action":"transform","template":"{\n  \"id\": {{$body.event.data.new.id}},\n  \"created_at\": {{$body.event.data.new.created_at}},\n  \"updated_at\": {{$body.event.data.new.updated_at}},\n  \"type\": {{$body.event.data.new.type}},\n  \"creator_id\": {{$body.event.data.new.creator_id}},\n  \"payload\": \"placeholder_from_hasura\"\n}"},"version":2,"template_engine":"Kriti"},"retry_conf":{"num_retries":3,"interval_sec":10,"timeout_sec":60}}],"table":{"schema":"public","name":"events"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","creator_id","event_id","id","payload","status","type","updated_at"],"filter":{"creator_id":{"_eq":"X-Hasura-User-Id"}}}}],"table":{"schema":"public","name":"events_workers_status"}},{"is_enum":true,"table":{"schema":"public","name":"file_access_enum"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","file_version_id","status","user_id"],"filter":{"file_version":{"file":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"file_version_id"},"name":"file_version"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"file_approvals"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"file_approval_id","table":{"schema":"public","name":"file_comments"}}},"name":"comments"}]},{"is_enum":true,"table":{"schema":"public","name":"file_approvals_status_enum"}},{"table":{"schema":"public","name":"file_assignation_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","file_id"],"filter":{"file":{"user_can_read":{"_eq":true}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"file_id"},"name":"file"}],"table":{"schema":"public","name":"file_assignations"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"file_assignation_id","table":{"schema":"public","name":"file_assignations_orgs"}}},"name":"orgs"},{"using":{"foreign_key_constraint_on":{"column":"file_assignation_id","table":{"schema":"public","name":"file_assignations_teams"}}},"name":"teams"},{"using":{"foreign_key_constraint_on":{"column":"file_assignation_id","table":{"schema":"public","name":"file_assignations_users"}}},"name":"users"}]},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","creator_id","file_assignation_id","id","org_id","updated_at"],"filter":{"file_assignee":{"file":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"creator_id"},"name":"creator"},{"using":{"foreign_key_constraint_on":"file_assignation_id"},"name":"file_assignee"},{"using":{"foreign_key_constraint_on":"org_id"},"name":"org"}],"table":{"schema":"public","name":"file_assignations_orgs"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","creator_id","file_assignation_id","id","team_id","updated_at"],"filter":{"file_assignee":{"file":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"creator_id"},"name":"creator"},{"using":{"foreign_key_constraint_on":"file_assignation_id"},"name":"file_assignee"},{"using":{"foreign_key_constraint_on":"team_id"},"name":"team"}],"table":{"schema":"public","name":"file_assignations_teams"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","creator_id","file_assignation_id","id","updated_at","user_id"],"filter":{"file_assignee":{"file":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"creator_id"},"name":"creator"},{"using":{"foreign_key_constraint_on":"file_assignation_id"},"name":"file_assignee"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"file_assignations_users"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","file_version_id","creator_id","file_approval_id","content"],"filter":{"file_version":{"file":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"creator_id"},"name":"creator"},{"using":{"foreign_key_constraint_on":"file_approval_id"},"name":"file_approval"},{"using":{"foreign_key_constraint_on":"file_version_id"},"name":"file_version"}],"table":{"schema":"public","name":"file_comments"}},{"table":{"schema":"public","name":"file_label_migrations"}},{"table":{"schema":"public","name":"file_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","file_id"],"filter":{"file":{"user_can_read":{"_eq":true}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"file_id"},"name":"file"}],"table":{"schema":"public","name":"file_permissions"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"file_permission_id","table":{"schema":"public","name":"file_permissions_orgs"}}},"name":"orgs"},{"using":{"foreign_key_constraint_on":{"column":"file_permission_id","table":{"schema":"public","name":"file_permissions_teams"}}},"name":"teams"},{"using":{"foreign_key_constraint_on":{"column":"file_permission_id","table":{"schema":"public","name":"file_permissions_users"}}},"name":"users"}]},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","file_permission_id","org_id","access"],"filter":{"file_permission":{"file":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"file_permission_id"},"name":"file_permission"},{"using":{"foreign_key_constraint_on":"org_id"},"name":"org"}],"table":{"schema":"public","name":"file_permissions_orgs"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","file_permission_id","team_id","access"],"filter":{"file_permission":{"file":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"file_permission_id"},"name":"file_permission"},{"using":{"foreign_key_constraint_on":"team_id"},"name":"team"}],"table":{"schema":"public","name":"file_permissions_teams"}},{"select_permissions":[{"role":"user","permission":{"columns":["access","created_at","updated_at","file_permission_id","id","user_id"],"filter":{"file_permission":{"file":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"file_permission_id"},"name":"file_permission"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"file_permissions_users"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","file_version_id","id","signed_at","signed_by","updated_at"],"filter":{"file_version":{"file":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"file_version_id"},"name":"file_version"},{"using":{"foreign_key_constraint_on":"signed_by"},"name":"user"}],"table":{"schema":"public","name":"file_signatures"}},{"table":{"schema":"public","name":"file_version_approval_migrations"}},{"select_permissions":[{"role":"user","permission":{"allow_aggregations":true,"columns":["created_at","file_approval_id","file_version_approval_request_id","id","updated_at","user_id"],"filter":{"file_version_approval_request":{"file_version":{"file":{"user_can_read":{"_eq":true}}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"file_approval_id"},"name":"file_approval"},{"using":{"foreign_key_constraint_on":"file_version_approval_request_id"},"name":"file_version_approval_request"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"file_version_approval_request_users"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","file_version_id","id","updated_at"],"limit":1,"filter":{"file_version":{"file":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"file_version_id"},"name":"file_version"}],"table":{"schema":"public","name":"file_version_approval_requests"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"file_version_approval_request_id","table":{"schema":"public","name":"file_version_approval_request_users"}}},"name":"users"}]},{"table":{"schema":"public","name":"file_version_migrations"}},{"table":{"schema":"public","name":"file_version_wopi"}},{"select_permissions":[{"role":"user","permission":{"computed_fields":["current_extension"],"columns":["content_type","created_at","creator_id","extension","file_id","id","is_annotated","key","name","number","size","updated_at"],"filter":{"file":{"user_can_read":{"_eq":true}}}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"file_version_approval_requests"},"insertion_order":null,"column_mapping":{"id":"file_version_id"}}},"name":"approval_requests"},{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"file_versions_approvals_overview"},"insertion_order":null,"column_mapping":{"id":"file_version_id"}}},"name":"approvals_overview"},{"using":{"foreign_key_constraint_on":"creator_id"},"name":"creator"},{"using":{"foreign_key_constraint_on":"file_id"},"name":"file"},{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"file_version_wopi"},"insertion_order":null,"column_mapping":{"id":"file_version_id"}}},"name":"wopi"}],"remote_relationships":[{"definition":{"remote_field":{"getPresignedOriginalFileUrl":{"arguments":{"id":"$id"}}},"hasura_fields":["id"],"remote_schema":"Apollo"},"name":"original_url"},{"definition":{"remote_field":{"getPresignedFileUrl":{"arguments":{"id":"$id"}}},"hasura_fields":["id"],"remote_schema":"Apollo"},"name":"url"}],"computed_fields":[{"definition":{"function":{"schema":"public","name":"get_file_version_extension"}},"name":"current_extension"},{"definition":{"function":{"schema":"public","name":"get_user_file_version_approvals"},"session_argument":"hasura_session"},"name":"user_approvals","comment":"Get the approvals of the current user on this file_version"}],"table":{"schema":"public","name":"file_versions"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"file_version_id","table":{"schema":"public","name":"file_approvals"}}},"name":"approvals"},{"using":{"foreign_key_constraint_on":{"column":"file_version_id","table":{"schema":"public","name":"file_comments"}}},"name":"comments"},{"using":{"foreign_key_constraint_on":{"column":"file_version_id","table":{"schema":"public","name":"file_signatures"}}},"name":"signatures"},{"using":{"foreign_key_constraint_on":{"column":"file_version_id","table":{"schema":"public","name":"tasks_file_versions"}}},"name":"tasks"},{"using":{"foreign_key_constraint_on":{"column":"file_version_id","table":{"schema":"public","name":"file_views"}}},"name":"views"}]},{"select_permissions":[{"role":"user","permission":{"columns":["file_version_id","is_completed","is_approved_with_comments","is_approved_without_comments","is_denied"],"filter":{}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"file_versions"},"insertion_order":null,"column_mapping":{"file_version_id":"id"}}},"name":"file_version"}],"table":{"schema":"public","name":"file_versions_approvals_overview"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","file_version_id","user_id"],"filter":{"file_version":{"file":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"file_version_id"},"name":"file_version"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"file_views"}},{"select_permissions":[{"role":"user","permission":{"computed_fields":["extension","is_approved_on_a_version"],"columns":["created_at","due_date","id","is_approval_mode","name","parent_id","updated_at"],"filter":{"user_can_read":{"_eq":true}}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"file_assignations"},"insertion_order":null,"column_mapping":{"id":"file_id"}}},"name":"assignation"},{"using":{"foreign_key_constraint_on":"parent_id"},"name":"folder"},{"using":{"foreign_key_constraint_on":{"column":"file_id","table":{"schema":"public","name":"file_permissions"}}},"name":"permission"},{"using":{"foreign_key_constraint_on":"project_id"},"name":"project"}],"computed_fields":[{"definition":{"function":{"schema":"public","name":"get_file_extension"}},"name":"extension","comment":"file extension in lowercase extracted last_file_version extension"},{"definition":{"function":{"schema":"public","name":"is_approved_on_a_version"}},"name":"is_approved_on_a_version","comment":"Will be true if an approval has been created on any of the file versions"},{"definition":{"function":{"schema":"public","name":"get_last_file_version"}},"name":"last_version","comment":"Get the last file_version of the file (the one with the greateast number)"},{"definition":{"function":{"schema":"public","name":"get_file_assignations_suggestions_orgs"}},"name":"suggestions_assignations_orgs","comment":"Used to display contextual orgs assignations suggestions depending of the file permissions"},{"definition":{"function":{"schema":"public","name":"get_file_assignations_suggestions_teams"}},"name":"suggestions_assignations_teams","comment":"Used to display contextual teams assignations suggestions depending of the file permissions"},{"definition":{"function":{"schema":"public","name":"get_file_assignations_suggestions_users"}},"name":"suggestions_assignations_users","comment":"Used to display contextual users assignations suggestions depending of the file permissions"},{"definition":{"function":{"schema":"public","name":"get_file_permissions_suggestions_orgs"}},"name":"suggestions_permissions_orgs","comment":"Used to display contextual orgs permissions suggestions depending of the file parent permissions"},{"definition":{"function":{"schema":"public","name":"get_file_permissions_suggestions_teams"}},"name":"suggestions_permissions_teams","comment":"Used to display contextual teams permissions suggestions depending of the file parent permissions"},{"definition":{"function":{"schema":"public","name":"get_file_permissions_suggestions_users"}},"name":"suggestions_permissions_users","comment":"Used to display contextual users permissions suggestions depending of the file parent permissions"},{"definition":{"function":{"schema":"public","name":"get_user_can_read_file"},"session_argument":"hasura_session"},"name":"user_can_read","comment":"true if the user should be able to see this file row"},{"definition":{"function":{"schema":"public","name":"get_file_version"}},"name":"versions_by_pk","comment":""}],"table":{"schema":"public","name":"files"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"file_id","table":{"schema":"public","name":"files_to_project_labels"}}},"name":"labels"},{"using":{"foreign_key_constraint_on":{"column":"file_id","table":{"schema":"public","name":"file_versions"}}},"name":"versions"}]},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","file_id","id","order","project_label_id","updated_at"],"filter":{"file":{"user_can_read":{"_eq":true}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"file_id"},"name":"file"},{"using":{"foreign_key_constraint_on":"project_label_id"},"name":"label"}],"table":{"schema":"public","name":"files_to_project_labels"}},{"is_enum":true,"table":{"schema":"public","name":"folder_access_enum"}},{"table":{"schema":"public","name":"folder_assignation_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","folder_id"],"filter":{"folder":{"user_can_read":{"_eq":true}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"folder_id"},"name":"folder"}],"table":{"schema":"public","name":"folder_assignations"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"folder_assignation_id","table":{"schema":"public","name":"folder_assignations_orgs"}}},"name":"orgs"},{"using":{"foreign_key_constraint_on":{"column":"folder_assignation_id","table":{"schema":"public","name":"folder_assignations_teams"}}},"name":"teams"},{"using":{"foreign_key_constraint_on":{"column":"folder_assignation_id","table":{"schema":"public","name":"folder_assignations_users"}}},"name":"users"}]},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","creator_id","folder_assignation_id","id","org_id","updated_at"],"filter":{"folder_assignee":{"folder":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"creator_id"},"name":"creator"},{"using":{"foreign_key_constraint_on":"folder_assignation_id"},"name":"folder_assignee"},{"using":{"foreign_key_constraint_on":"org_id"},"name":"org"}],"table":{"schema":"public","name":"folder_assignations_orgs"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","creator_id","folder_assignation_id","id","team_id","updated_at"],"filter":{"folder_assignee":{"folder":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"creator_id"},"name":"creator"},{"using":{"foreign_key_constraint_on":"folder_assignation_id"},"name":"folder_assignee"},{"using":{"foreign_key_constraint_on":"team_id"},"name":"team"}],"table":{"schema":"public","name":"folder_assignations_teams"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","creator_id","folder_assignation_id","id","updated_at","user_id"],"filter":{"folder_assignee":{"folder":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"creator_id"},"name":"creator"},{"using":{"foreign_key_constraint_on":"folder_assignation_id"},"name":"folder_assignee"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"folder_assignations_users"}},{"table":{"schema":"public","name":"folder_label_migrations"}},{"table":{"schema":"public","name":"folder_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","folder_id","inherited_from"],"filter":{"folder":{"user_can_read":{"_eq":true}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"folder_id"},"name":"folder"}],"table":{"schema":"public","name":"folder_permissions"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"folder_permission_id","table":{"schema":"public","name":"folder_permissions_orgs"}}},"name":"orgs"},{"using":{"foreign_key_constraint_on":{"column":"folder_permission_id","table":{"schema":"public","name":"folder_permissions_teams"}}},"name":"teams"},{"using":{"foreign_key_constraint_on":{"column":"folder_permission_id","table":{"schema":"public","name":"folder_permissions_users"}}},"name":"users"}]},{"select_permissions":[{"role":"user","permission":{"columns":["access","created_at","creator_id","folder_permission_id","id","org_id","updated_at"],"filter":{"permission":{"folder":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"users"},"insertion_order":null,"column_mapping":{"creator_id":"id"}}},"name":"creator"},{"using":{"foreign_key_constraint_on":"org_id"},"name":"org"},{"using":{"foreign_key_constraint_on":"folder_permission_id"},"name":"permission"}],"table":{"schema":"public","name":"folder_permissions_orgs"}},{"select_permissions":[{"role":"user","permission":{"columns":["access","created_at","creator_id","folder_permission_id","id","team_id","updated_at"],"filter":{"permission":{"folder":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"users"},"insertion_order":null,"column_mapping":{"creator_id":"id"}}},"name":"creator"},{"using":{"foreign_key_constraint_on":"folder_permission_id"},"name":"permission"},{"using":{"foreign_key_constraint_on":"team_id"},"name":"team"}],"table":{"schema":"public","name":"folder_permissions_teams"}},{"select_permissions":[{"role":"user","permission":{"columns":["access","created_at","creator_id","folder_permission_id","id","updated_at","user_id"],"filter":{"permission":{"folder":{"user_can_read":{"_eq":true}}}}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"users"},"insertion_order":null,"column_mapping":{"creator_id":"id"}}},"name":"creator"},{"using":{"foreign_key_constraint_on":"folder_permission_id"},"name":"permission"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"folder_permissions_users"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","folder_id","user_id"],"filter":{"folder":{"user_can_read":{"_eq":true}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"folder_id"},"name":"folder"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"folder_views"}},{"select_permissions":[{"role":"user","permission":{"computed_fields":["is_in_bin"],"columns":["created_at","creator_id","id","name","parent_id","updated_at"],"filter":{"user_can_read":{"_eq":true}}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"folder_assignations"},"insertion_order":null,"column_mapping":{"id":"folder_id"}}},"name":"assignation"},{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"users"},"insertion_order":null,"column_mapping":{"creator_id":"id"}}},"name":"creator"},{"using":{"foreign_key_constraint_on":"parent_id"},"name":"parent"},{"using":{"foreign_key_constraint_on":{"column":"folder_id","table":{"schema":"public","name":"folder_permissions"}}},"name":"permission"},{"using":{"foreign_key_constraint_on":"project_id"},"name":"project"}],"computed_fields":[{"definition":{"function":{"schema":"public","name":"is_folder_in_bin"}},"name":"is_in_bin","comment":"true if the folder is currently in the bin of this project"},{"definition":{"function":{"schema":"public","name":"get_user_folder_notification"},"session_argument":"hasura_session"},"name":"notification_badge"},{"definition":{"function":{"schema":"public","name":"get_folder_pwd"}},"name":"pwd","comment":"The path of this folder from the nearest root"},{"definition":{"function":{"schema":"public","name":"get_folder_assignations_suggestions_orgs"}},"name":"suggestions_assignations_orgs","comment":"Used to display contextual orgs assignations suggestions depending of the folder permissions"},{"definition":{"function":{"schema":"public","name":"get_folder_assignations_suggestions_teams"}},"name":"suggestions_assignations_teams","comment":"Used to display contextual teams assignations suggestions depending of the folder permissions"},{"definition":{"function":{"schema":"public","name":"get_folder_assignations_suggestions_users"}},"name":"suggestions_assignations_users","comment":"Used to display contextual users assignations suggestions depending of the folder permissions"},{"definition":{"function":{"schema":"public","name":"get_folder_permissions_suggestions_orgs"}},"name":"suggestions_permissions_orgs","comment":"Used to display contextual orgs permissions suggestions depending of the folder parent permissions"},{"definition":{"function":{"schema":"public","name":"get_folder_permissions_suggestions_teams"}},"name":"suggestions_permissions_teams","comment":"Used to display contextual teams permissions suggestions depending of the folder parent permissions"},{"definition":{"function":{"schema":"public","name":"get_folder_permissions_suggestions_users"}},"name":"suggestions_permissions_users","comment":"Used to display contextual users permissions suggestions depending of the folder parent permissions"},{"definition":{"function":{"schema":"public","name":"get_user_can_read_folder"},"session_argument":"hasura_session"},"name":"user_can_read","comment":"true if the user should be able to see this folder row"}],"table":{"schema":"public","name":"folders"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"parent_id","table":{"schema":"public","name":"files"}}},"name":"files"},{"using":{"foreign_key_constraint_on":{"column":"parent_id","table":{"schema":"public","name":"folders"}}},"name":"folders"},{"using":{"foreign_key_constraint_on":{"column":"folder_id","table":{"schema":"public","name":"folders_to_project_labels"}}},"name":"labels"},{"using":{"foreign_key_constraint_on":{"column":"folder_id","table":{"schema":"public","name":"folder_views"}}},"name":"views"}]},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","folder_id","id","order","project_label_id","updated_at"],"filter":{"folder":{"user_can_read":{"_eq":true}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"folder_id"},"name":"folder"},{"using":{"foreign_key_constraint_on":"project_label_id"},"name":"label"}],"table":{"schema":"public","name":"folders_to_project_labels"}},{"select_permissions":[{"role":"user","permission":{"columns":["org_id","created_at","updated_at","street","postal_code","administrative_area_level1","administrative_area_level2","country","city","lat","lng"],"filter":{"org":{"members":{"user_id":{"_eq":"X-Hasura-User-Id"}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"org_id"},"name":"org"}],"table":{"schema":"public","name":"org_address"}},{"table":{"schema":"public","name":"org_avatars"}},{"table":{"schema":"public","name":"org_backgrounds"}},{"table":{"schema":"public","name":"org_licenses"}},{"table":{"schema":"public","name":"org_member_migrations"}},{"table":{"schema":"public","name":"org_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","org_id","project_id","created_at","updated_at","start_date","end_date","reference","client_fullname","client_phone_number","client_email","price_estimate"],"filter":{}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"org_id"},"name":"org"},{"using":{"foreign_key_constraint_on":"project_id"},"name":"project"}],"table":{"schema":"public","name":"org_project_summary"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"org_project_summary_id","table":{"schema":"public","name":"org_project_summary_to_project_categories"}}},"name":"project_categories"}]},{"table":{"schema":"public","name":"org_project_summary_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","id","order","org_project_summary_id","project_categories_id","updated_at"],"filter":{}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"org_project_summary_id"},"name":"org_project_summary"},{"using":{"foreign_key_constraint_on":"project_categories_id"},"name":"project_category"}],"table":{"schema":"public","name":"org_project_summary_to_project_categories"}},{"select_permissions":[{"role":"user","permission":{"columns":["name"],"filter":{}}}],"table":{"schema":"public","name":"org_roles"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"role_id","table":{"schema":"public","name":"orgs_to_users"}}},"name":"orgs_to_users"}]},{"select_permissions":[{"role":"user","permission":{"columns":["description","id","legal_number","name","phone"],"filter":{"has_access":{"_eq":true}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":{"column":"org_id","table":{"schema":"public","name":"org_address"}}},"name":"address"},{"using":{"foreign_key_constraint_on":"project_id"},"name":"project"}],"remote_relationships":[{"definition":{"remote_field":{"getOrgAvatarUrl":{"arguments":{"id":"$id"}}},"hasura_fields":["id"],"remote_schema":"Apollo"},"name":"avatar"},{"definition":{"remote_field":{"getOrgBackgroundUrl":{"arguments":{"id":"$id"}}},"hasura_fields":["id"],"remote_schema":"Apollo"},"name":"background"}],"computed_fields":[{"definition":{"function":{"schema":"public","name":"get_user_can_read_org"},"session_argument":"hasura_session"},"name":"has_access","comment":"true if the current user can access the org row, either because he''s a member of it or because he share a project with one of the member of this org"}],"table":{"schema":"public","name":"orgs"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"org_id","table":{"schema":"public","name":"folder_assignations_orgs"}}},"name":"folder_assignations"},{"using":{"foreign_key_constraint_on":{"column":"org_id","table":{"schema":"public","name":"folder_permissions_orgs"}}},"name":"folder_permissions"},{"using":{"foreign_key_constraint_on":{"column":"org_id","table":{"schema":"public","name":"orgs_to_users"}}},"name":"members"},{"using":{"foreign_key_constraint_on":{"column":"org_id","table":{"schema":"public","name":"project_categories"}}},"name":"project_categories"}]},{"table":{"schema":"public","name":"orgs_projects_users"}},{"table":{"schema":"public","name":"orgs_to_user_actions"}},{"select_permissions":[{"role":"user","permission":{"columns":["role_id","created_at","updated_at","inviter_id","org_id","user_id"],"filter":{"user":{"has_user_contact_access":{"_eq":true}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"inviter_id"},"name":"inviter"},{"using":{"foreign_key_constraint_on":"org_id"},"name":"org"},{"using":{"foreign_key_constraint_on":"role_id"},"name":"role"},{"using":{"foreign_key_constraint_on":"updater_id"},"name":"updater"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"orgs_to_users"}},{"select_permissions":[{"role":"user","permission":{"columns":["administrative_area_level1","administrative_area_level2","city","country","created_at","lat","lng","postal_code","project_id","street","updated_at"],"filter":{}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"project_id"},"name":"project"}],"table":{"schema":"public","name":"project_address"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","updated_at","project_id","key","name","content_type","extension","size"],"filter":{}}}],"table":{"schema":"public","name":"project_avatars"}},{"table":{"schema":"public","name":"project_backgrounds"}},{"table":{"schema":"public","name":"project_banners"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","name","color","org_id"],"filter":{}}}],"table":{"schema":"public","name":"project_categories"}},{"table":{"schema":"public","name":"project_categories_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","name","color","project_id"],"filter":{}}}],"table":{"schema":"public","name":"project_labels"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"project_label_id","table":{"schema":"public","name":"tasks_to_project_labels"}}},"name":"tasks"}]},{"table":{"schema":"public","name":"project_labels_migrations"}},{"table":{"schema":"public","name":"project_member_migrations"}},{"table":{"schema":"public","name":"project_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["name"],"filter":{}}}],"table":{"schema":"public","name":"project_roles"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"role_id","table":{"schema":"public","name":"projects_to_users"}}},"name":"projects_to_users"}]},{"table":{"schema":"public","name":"project_templates"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","description","id","is_archived","is_demo","language","name","type","updated_at"],"filter":{"deleted_at":{"_is_null":true}}}}],"table":{"schema":"public","name":"project_templates_overview"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","project_id","user_id"],"filter":{}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"project_id"},"name":"project"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"project_views"}},{"select_permissions":[{"role":"user","permission":{"computed_fields":["root_bin_folder_id","root_folder_id"],"columns":["created_at","description","id","is_archived","is_demo","name","updated_at"],"filter":{"_and":[{"deleted_at":{"_is_null":true}},{"members":{"_and":[{"user_id":{"_eq":"X-Hasura-User-Id"}},{"role_id":{"_neq":"disabled"}}]}}]}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":{"column":"project_id","table":{"schema":"public","name":"project_address"}}},"name":"address"},{"using":{"foreign_key_constraint_on":{"column":"project_id","table":{"schema":"public","name":"project_templates"}}},"name":"template"}],"remote_relationships":[{"definition":{"remote_field":{"getProjectAvatarUrl":{"arguments":{"id":"$id"}}},"hasura_fields":["id"],"remote_schema":"Apollo"},"name":"avatar"},{"definition":{"remote_field":{"getProjectBackgroundUrl":{"arguments":{"id":"$id"}}},"hasura_fields":["id"],"remote_schema":"Apollo"},"name":"background"},{"definition":{"remote_field":{"getProjectBannerUrl":{"arguments":{"id":"$id"}}},"hasura_fields":["id"],"remote_schema":"Apollo"},"name":"banner"}],"computed_fields":[{"definition":{"function":{"schema":"public","name":"get_user_org_project_summary"},"session_argument":"hasura_session"},"name":"org_project_summary","comment":"Get the org_project_summary for the current user depending on his org"},{"definition":{"function":{"schema":"public","name":"project_root_bin_folder_id"}},"name":"root_bin_folder_id","comment":"Get the bin root folder id for the project"},{"definition":{"function":{"schema":"public","name":"project_root_folder_id"}},"name":"root_folder_id","comment":"Get the root folder for the project"}],"table":{"schema":"public","name":"projects"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"project_id","table":{"schema":"public","name":"folders"}}},"name":"folders"},{"using":{"foreign_key_constraint_on":{"column":"project_id","table":{"schema":"public","name":"project_labels"}}},"name":"labels"},{"using":{"foreign_key_constraint_on":{"column":"project_id","table":{"schema":"public","name":"projects_to_users"}}},"name":"members"},{"using":{"foreign_key_constraint_on":{"column":"project_id","table":{"schema":"public","name":"orgs"}}},"name":"org"},{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"orgs_projects_users"},"insertion_order":null,"column_mapping":{"id":"project_id"}}},"name":"orgs_members"},{"using":{"foreign_key_constraint_on":{"column":"project_id","table":{"schema":"public","name":"tasks"}}},"name":"tasks"},{"using":{"foreign_key_constraint_on":{"column":"project_id","table":{"schema":"public","name":"teams"}}},"name":"teams"},{"using":{"foreign_key_constraint_on":{"column":"project_id","table":{"schema":"public","name":"project_views"}}},"name":"views"}]},{"select_permissions":[{"role":"user","permission":{"allow_aggregations":true,"computed_fields":["is_creator_in_my_org","is_member"],"columns":["created_at","description","id","is_archived","is_demo","name","updated_at"],"filter":{"_and":[{"has_access":{"_eq":true}},{"deleted_at":{"_is_null":true}}]}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"project_address"},"insertion_order":null,"column_mapping":{"id":"project_id"}}},"name":"address"}],"remote_relationships":[{"definition":{"remote_field":{"getProjectAvatarUrl":{"arguments":{"id":"$id"}}},"hasura_fields":["id"],"remote_schema":"Apollo"},"name":"avatar"}],"computed_fields":[{"definition":{"function":{"schema":"public","name":"get_user_can_read_project_map_overview"},"session_argument":"hasura_session"},"name":"has_access"},{"definition":{"function":{"schema":"public","name":"get_project_was_created_by_user_active_org"},"session_argument":"hasura_session"},"name":"is_creator_in_my_org","comment":"Get if the creator is member of the active org of the current user"},{"definition":{"function":{"schema":"public","name":"get_user_is_member_project_map_overview"},"session_argument":"hasura_session"},"name":"is_member"},{"definition":{"function":{"schema":"public","name":"get_user_org_project_map_overview_summary"},"session_argument":"hasura_session"},"name":"org_project_summary","comment":"Get the org_project_summary for the current user depending on his org"}],"table":{"schema":"public","name":"projects_map_overview"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at"],"filter":{}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"inviter_id"},"name":"inviter"},{"using":{"foreign_key_constraint_on":"project_id"},"name":"project"},{"using":{"foreign_key_constraint_on":"role_id"},"name":"role"},{"using":{"foreign_key_constraint_on":"updater_id"},"name":"updater"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"projects_to_users"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","chat_channel","chat_direct_message","user_id"],"filter":{}}}],"table":{"schema":"public","name":"push_notifications"}},{"table":{"schema":"public","name":"subtask_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["weak_notification","strong_notification_count","folder_id"],"filter":{}}}],"table":{"schema":"public","name":"t_folder_notification_badge"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","level","name"],"filter":{}}}],"table":{"schema":"public","name":"t_folder_pwd"}},{"table":{"schema":"public","name":"task_assignation_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","task_id"],"filter":{}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"task_id"},"name":"task"}],"table":{"schema":"public","name":"task_assignations"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"task_assignation_id","table":{"schema":"public","name":"task_assignations_orgs"}}},"name":"orgs"},{"using":{"foreign_key_constraint_on":{"column":"task_assignation_id","table":{"schema":"public","name":"task_assignations_teams"}}},"name":"teams"},{"using":{"foreign_key_constraint_on":{"column":"task_assignation_id","table":{"schema":"public","name":"task_assignations_users"}}},"name":"users"}]},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","creator_id","id","org_id","task_assignation_id","updated_at"],"filter":{}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"users"},"insertion_order":null,"column_mapping":{"creator_id":"id"}}},"name":"creator"},{"using":{"foreign_key_constraint_on":"org_id"},"name":"org"},{"using":{"foreign_key_constraint_on":"task_assignation_id"},"name":"task_assignee"}],"table":{"schema":"public","name":"task_assignations_orgs"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","creator_id","id","task_assignation_id","team_id","updated_at"],"filter":{}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"users"},"insertion_order":null,"column_mapping":{"creator_id":"id"}}},"name":"creator"},{"using":{"foreign_key_constraint_on":"task_assignation_id"},"name":"task_assignee"},{"using":{"foreign_key_constraint_on":"team_id"},"name":"team"}],"table":{"schema":"public","name":"task_assignations_teams"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","creator_id","id","task_assignation_id","updated_at","user_id"],"filter":{}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"users"},"insertion_order":null,"column_mapping":{"creator_id":"id"}}},"name":"creator"},{"using":{"foreign_key_constraint_on":"task_assignation_id"},"name":"task_assignee"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"task_assignations_users"}},{"table":{"schema":"public","name":"task_attachment_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["content_type","created_at","id","key","name","task_id","updated_at"],"filter":{"task":{"project":{"members":{"user_id":{"_eq":"X-Hasura-User-Id"}}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"task_id"},"name":"task"}],"remote_relationships":[{"definition":{"remote_field":{"getPresignedTaskAttachmentUrl":{"arguments":{"id":"$id"}}},"hasura_fields":["id"],"remote_schema":"Apollo"},"name":"url"}],"table":{"schema":"public","name":"task_attachments"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","page_number","x","y"],"filter":{}}}],"table":{"schema":"public","name":"task_file_version_location"}},{"table":{"schema":"public","name":"task_label_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["task_id","lat","lng"],"filter":{}}}],"table":{"schema":"public","name":"task_locations"}},{"table":{"schema":"public","name":"task_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["closed","created_at","creator_id","description","end_date","id","order","start_date","task_id","updated_at"],"filter":{}}}],"table":{"schema":"public","name":"task_subtasks"}},{"table":{"schema":"public","name":"task_validation_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","task_id","user_id"],"filter":{}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"task_validations"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","task_id","user_id"],"filter":{}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"task_id"},"name":"task"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"task_views"}},{"select_permissions":[{"role":"user","permission":{"allow_aggregations":true,"computed_fields":["is_validated_by","subtasks_progress"],"columns":["created_at","creator_id","deleted","deleted_at","description","end_date","id","number","project_id","start_date","updated_at"],"filter":{"deleted":{"_eq":false}}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"task_assignations"},"insertion_order":null,"column_mapping":{"id":"task_id"}}},"name":"assignations"},{"using":{"foreign_key_constraint_on":"creator_id"},"name":"creator"},{"using":{"foreign_key_constraint_on":{"column":"task_id","table":{"schema":"public","name":"task_locations"}}},"name":"location"},{"using":{"foreign_key_constraint_on":"project_id"},"name":"project"}],"computed_fields":[{"definition":{"function":{"schema":"public","name":"task_validated_by"},"session_argument":"hasura_session"},"name":"is_validated_by","comment":"This field will show by who the task is validated, if it is : « none » if non validated, « user » if validated only by the user, « org » if validated by someone of his/her org, or « external » if validated by one user not in user org."},{"definition":{"function":{"schema":"public","name":"task_progress"}},"name":"subtasks_progress","comment":"This field will show the progress (in percentage) of the closed subtasks"}],"table":{"schema":"public","name":"tasks"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"task_id","table":{"schema":"public","name":"task_attachments"}}},"name":"attachments"},{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"tasks_file_versions"},"insertion_order":null,"column_mapping":{"id":"task_id"}}},"name":"file_versions"},{"using":{"foreign_key_constraint_on":{"column":"task_id","table":{"schema":"public","name":"tasks_to_project_labels"}}},"name":"labels"},{"using":{"foreign_key_constraint_on":{"column":"task_id","table":{"schema":"public","name":"task_subtasks"}}},"name":"subtasks"},{"using":{"foreign_key_constraint_on":{"column":"task_id","table":{"schema":"public","name":"task_validations"}}},"name":"validations"},{"using":{"foreign_key_constraint_on":{"column":"task_id","table":{"schema":"public","name":"task_views"}}},"name":"views"}]},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","task_id","file_version_id","task_location_id"],"filter":{"_and":[{"file_version":{"file":{"user_can_read":{"_eq":true}}}},{"task":{"deleted":{"_eq":false}}}]}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"file_version_id"},"name":"file_version"},{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"task_file_version_location"},"insertion_order":null,"column_mapping":{"task_location_id":"id"}}},"name":"location"},{"using":{"foreign_key_constraint_on":"task_id"},"name":"task"}],"table":{"schema":"public","name":"tasks_file_versions"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","id","order","project_label_id","task_id","updated_at"],"filter":{"task":{"project":{"members":{"user_id":{"_eq":"X-Hasura-User-Id"}}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"project_label_id"},"name":"label"},{"using":{"foreign_key_constraint_on":"task_id"},"name":"task"}],"table":{"schema":"public","name":"tasks_to_project_labels"}},{"table":{"schema":"public","name":"team_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["color","created_at","id","name","updated_at","project_id"],"filter":{"project":{"members":{"user_id":{"_eq":"X-Hasura-User-Id"}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"project_id"},"name":"project"}],"table":{"schema":"public","name":"teams"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"team_id","table":{"schema":"public","name":"folder_assignations_teams"}}},"name":"folder_assignations"},{"using":{"foreign_key_constraint_on":{"column":"team_id","table":{"schema":"public","name":"teams_to_users"}}},"name":"users"}]},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","user_id","team_id"],"filter":{"team":{"project":{"members":{"user_id":{"_eq":"X-Hasura-User-Id"}}}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"team_id"},"name":"team"},{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"teams_to_users"}},{"table":{"schema":"public","name":"user_actions"}},{"table":{"schema":"public","name":"user_avatars"}},{"select_permissions":[{"role":"user","permission":{"columns":["created_at","id","user_id"],"limit":25,"filter":{"user":{"has_access":true}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"user_connections"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"user_connection_id","table":{"schema":"public","name":"user_locations"}}},"name":"user_locations"}]},{"select_permissions":[{"role":"user","permission":{"columns":["id","email","phone"],"filter":{"user":{"has_user_contact_access":{"_eq":true}}}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"users"},"insertion_order":null,"column_mapping":{"id":"id"}}},"name":"user"}],"table":{"schema":"public","name":"user_contact"}},{"table":{"schema":"public","name":"user_devices"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","user_id","user_connection_id","country_code","country_code3","country_name","city_name","latitude","longitude","time_zone","continent_code"],"limit":25,"filter":{"user_id":{"_eq":"X-Hasura-User-Id"}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"},{"using":{"foreign_key_constraint_on":"user_connection_id"},"name":"user_connection"}],"table":{"schema":"public","name":"user_locations"}},{"select_permissions":[{"role":"user","permission":{"columns":["country_code","placeholder_company_name"],"filter":{"user":{"has_access":{"_eq":true}}}}}],"object_relationships":[{"using":{"foreign_key_constraint_on":"user_id"},"name":"user"}],"table":{"schema":"public","name":"user_metadatas"}},{"table":{"schema":"public","name":"user_migrations"}},{"select_permissions":[{"role":"user","permission":{"columns":["id","created_at","updated_at","creator_id","recipient_id","event_id","read_at","is_strong","type","payload"],"filter":{"recipient_id":{"_eq":"X-Hasura-User-Id"}}}}],"table":{"schema":"public","name":"user_notifications"}},{"select_permissions":[{"role":"user","permission":{"computed_fields":["company_name","country_code","full_name"],"columns":["auth0_id","created_at","deleted_at","first_name","id","is_active","is_connected","is_legacy_user","is_locked","language","last_name","stream_user_id","timezone","updated_at"],"filter":{"has_access":{"_eq":true}}}}],"object_relationships":[{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"orgs_to_users"},"insertion_order":null,"column_mapping":{"id":"user_id"}}},"name":"active_org"},{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"user_contact"},"insertion_order":null,"column_mapping":{"id":"id"}}},"name":"contact"},{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"email_notifications"},"insertion_order":null,"column_mapping":{"id":"user_id"}}},"name":"email_notifications"},{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"user_metadatas"},"insertion_order":null,"column_mapping":{"id":"user_id"}}},"name":"metadatas"},{"using":{"manual_configuration":{"remote_table":{"schema":"public","name":"push_notifications"},"insertion_order":null,"column_mapping":{"id":"user_id"}}},"name":"push_notifications"}],"remote_relationships":[{"definition":{"remote_field":{"getAlgoliaUserApiKey":{"arguments":{}}},"hasura_fields":[],"remote_schema":"Apollo"},"name":"algolia_key"},{"definition":{"remote_field":{"getUserAvatarUrl":{"arguments":{"id":"$id"}}},"hasura_fields":["id"],"remote_schema":"Apollo"},"name":"avatar"},{"definition":{"remote_field":{"getStreamChatUserToken":{"arguments":{}}},"hasura_fields":[],"remote_schema":"Apollo"},"name":"stream_chat_token"}],"computed_fields":[{"definition":{"function":{"schema":"public","name":"user_company_name"}},"name":"company_name","comment":"Retrieve either the org name or the user placeholder_company_name"},{"definition":{"function":{"schema":"public","name":"user_country_code"}},"name":"country_code","comment":"Retrieve either the user metadatas country_code or the user locations country_code or null"},{"definition":{"function":{"schema":"public","name":"user_full_name"}},"name":"full_name"},{"definition":{"function":{"schema":"public","name":"get_user_can_read_user"},"session_argument":"hasura_session"},"name":"has_access","comment":"true if the current user has permission to access desired user row"},{"definition":{"function":{"schema":"public","name":"get_user_can_read_user_contact"},"session_argument":"hasura_session"},"name":"has_user_contact_access"}],"table":{"schema":"public","name":"users"},"array_relationships":[{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"user_connections"}}},"name":"connections"},{"using":{"foreign_key_constraint_on":{"column":"creator_id","table":{"schema":"public","name":"events"}}},"name":"events"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"file_approvals"}}},"name":"file_approvals"},{"using":{"foreign_key_constraint_on":{"column":"creator_id","table":{"schema":"public","name":"file_assignations_orgs"}}},"name":"file_assignations_orgs"},{"using":{"foreign_key_constraint_on":{"column":"creator_id","table":{"schema":"public","name":"file_assignations_teams"}}},"name":"file_assignations_teams"},{"using":{"foreign_key_constraint_on":{"column":"creator_id","table":{"schema":"public","name":"file_assignations_users"}}},"name":"file_assignations_users"},{"using":{"foreign_key_constraint_on":{"column":"creator_id","table":{"schema":"public","name":"file_comments"}}},"name":"file_comments"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"file_permissions_users"}}},"name":"file_permissions_users"},{"using":{"foreign_key_constraint_on":{"column":"signed_by","table":{"schema":"public","name":"file_signatures"}}},"name":"file_signatures"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"file_version_approval_request_users"}}},"name":"file_version_approval_request_users"},{"using":{"foreign_key_constraint_on":{"column":"creator_id","table":{"schema":"public","name":"file_versions"}}},"name":"file_versions"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"file_views"}}},"name":"file_views"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"folder_assignations_users"}}},"name":"folder_assignations"},{"using":{"foreign_key_constraint_on":{"column":"creator_id","table":{"schema":"public","name":"folder_assignations_orgs"}}},"name":"folder_assignations_orgs"},{"using":{"foreign_key_constraint_on":{"column":"creator_id","table":{"schema":"public","name":"folder_assignations_teams"}}},"name":"folder_assignations_teams"},{"using":{"foreign_key_constraint_on":{"column":"creator_id","table":{"schema":"public","name":"folder_assignations_users"}}},"name":"folder_assignations_users"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"folder_permissions_users"}}},"name":"folder_permissions"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"folder_views"}}},"name":"folder_views"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"user_locations"}}},"name":"locations"},{"using":{"foreign_key_constraint_on":{"column":"inviter_id","table":{"schema":"public","name":"orgs_to_users"}}},"name":"org_invitations"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"project_views"}}},"name":"project_views"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"projects_to_users"}}},"name":"projects"},{"using":{"foreign_key_constraint_on":{"column":"inviter_id","table":{"schema":"public","name":"projects_to_users"}}},"name":"projects_invited"},{"using":{"foreign_key_constraint_on":{"column":"updater_id","table":{"schema":"public","name":"projects_to_users"}}},"name":"projects_to_users"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"task_assignations_users"}}},"name":"task_assignations_users"},{"using":{"foreign_key_constraint_on":{"column":"creator_id","table":{"schema":"public","name":"task_subtasks"}}},"name":"task_subtasks"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"task_validations"}}},"name":"task_validations"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"task_views"}}},"name":"task_views"},{"using":{"foreign_key_constraint_on":{"column":"creator_id","table":{"schema":"public","name":"tasks"}}},"name":"tasks"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"teams_to_users"}}},"name":"teams"},{"using":{"foreign_key_constraint_on":{"column":"creator_id","table":{"schema":"public","name":"user_actions"}}},"name":"user_actions"},{"using":{"foreign_key_constraint_on":{"column":"user_id","table":{"schema":"public","name":"user_devices"}}},"name":"user_devices"},{"using":{"foreign_key_constraint_on":{"column":"creator_id","table":{"schema":"public","name":"user_notifications"}}},"name":"user_notifications"}]}],"configuration":{"connection_info":{"use_prepared_statements":false,"database_url":{"from_env":"HASURA_GRAPHQL_DATABASE_URL"},"isolation_level":"read-committed"}},"functions":[{"function":{"schema":"public","name":"get_file_version"}}]}],"remote_schemas":[{"definition":{"timeout_seconds":60,"url_from_env":"APOLLO_URL","forward_client_headers":true},"name":"Apollo","permissions":[{"definition":{"schema":"schema  { query: Query mutation: Mutation }\n\nscalar float8\n\nscalar json\n\nscalar timestamptz\n\nscalar uuid\n\ntype AddMembersToProjectChannelErrors { errors: [AddMembersToProjectChannelError!]!\n}\n\ntype AddMembersToProjectChannelSuccess { channel_id: String!\n  project_id: uuid!\n}\n\ntype AddUserApprovalToFileVersionErrors { errors: [AddUserApprovalToFileVersionError!]!\n}\n\ntype AddUserApprovalToFileVersionSuccess { file_version_id: uuid!\n}\n\ntype AddUserInTeamErrors { errors: [AddUserInTeamError!]!\n}\n\ntype AddUserInTeamSuccess { project_id: uuid!\n  team_id: uuid!\n  user_id: uuid!\n}\n\ntype AddUserViewToFileVersionErrors { errors: [AddUserViewToFileVersionError!]!\n}\n\ntype AddUserViewToFileVersionSuccess { file_version_id: uuid!\n}\n\ntype AddUserViewToFolderErrors { errors: [AddUserViewToFolderError!]!\n}\n\ntype AddUserViewToFolderSuccess { folder_id: uuid!\n}\n\ntype AddUserViewToProjectErrors { errors: [AddUserViewToProjectError!]!\n}\n\ntype AddUserViewToProjectSuccess { project_id: uuid!\n}\n\ntype AddUserViewToTaskErrors { errors: [AddUserViewToTaskError!]!\n}\n\ntype AddUserViewToTaskSuccess { task_id: uuid!\n}\n\ntype AnnotateFileErrors { errors: [AnnotateFileError!]!\n}\n\ntype AnnotateFileSuccess { file_version_id: uuid!\n}\n\ntype CannotArchiveOrgProject { message: String!\n  type: String!\n}\n\ntype CannotCreateOrgProjectSummaryOnOrgProject { message: String!\n  type: String!\n}\n\ntype CannotDeleteOrgProject { message: String!\n  type: String!\n}\n\ntype CannotDeleteProjectSharedWithMultipleOrgs { message: String!\n  type: String!\n}\n\ntype CannotInviteOnProject { message: String!\n  type: String!\n}\n\ntype CannotModifyEmailOfActiveUser { message: String!\n  type: String!\n}\n\ntype CannotModifyUserWithGreaterProjectRoleThanYours { message: String!\n  type: String!\n}\n\ntype CannotRemoveApprovalOnFile { message: String!\n  type: String!\n}\n\ntype CannotSetGreaterProjectRoleThanYours { message: String!\n  type: String!\n}\n\ntype CannotUpdateProjectRole { message: String!\n  type: String!\n}\n\ntype ChannelDoesNotExist { message: String!\n  type: String!\n}\n\ntype CopyFromTemporaryBucketFailed { message: String!\n  type: String!\n}\n\ntype CopyProjectErrors { errors: [CopyProjectError!]!\n}\n\ntype CopyProjectSuccess { project_id: uuid!\n  steps: optionsSuccess!\n}\n\ntype CreateChannelForProjectErrors { errors: [CreateChannelForProjectError!]!\n}\n\ntype CreateChannelForProjectSuccess { channel_id: String!\n  project_id: uuid!\n}\n\ntype CreateChannelForTaskErrors { errors: [CreateChannelForTaskError!]!\n}\n\ntype CreateChannelForTaskSuccess { channel_id: String!\n  task_id: uuid!\n}\n\ntype CreateEmptyFileErrors { errors: [CreateEmptyFileError!]!\n}\n\ntype CreateEmptyFileSuccess { fileId: uuid!\n  fileVersionId: uuid!\n}\n\ntype CreateFolderErrors { errors: [CreateFolderError!]!\n}\n\ntype CreateFolderSuccess { folder_id: uuid!\n}\n\ntype CreateOrgErrors { errors: [CreateOrgError!]!\n}\n\ntype CreateOrgFailed { message: String!\n  type: String!\n}\n\ntype CreateOrgProjectSummaryErrors { errors: [CreateOrgProjectSummaryError!]!\n}\n\ntype CreateOrgProjectSummarySuccess { org_project_summary_id: uuid!\n}\n\ntype CreateOrgSuccess { org_id: uuid!\n}\n\ntype CreateProjectCategoryErrors { errors: [CreateProjectCategoryError!]!\n}\n\ntype CreateProjectCategorySuccess { project_category_id: uuid!\n}\n\ntype CreateProjectDirectMessageErrors { errors: [CreateProjectDirectMessageError!]!\n}\n\ntype CreateProjectDirectMessageSuccess { channel_id: String!\n}\n\ntype CreateProjectErrors { errors: [CreateProjectError!]!\n}\n\ntype CreateProjectLabelErrors { errors: [CreateProjectLabelError!]!\n}\n\ntype CreateProjectLabelSuccess { project_label_id: uuid!\n}\n\ntype CreateProjectSuccess { project_id: uuid!\n}\n\ntype CreateSubtaskErrors { errors: [CreateSubtaskError!]!\n}\n\ntype CreateSubtaskSuccess { subtask_id: uuid!\n  task_id: uuid!\n}\n\ntype CreateTaskErrors { errors: [CreateTaskError!]!\n}\n\ntype CreateTaskSuccess { task_id: uuid!\n}\n\ntype CreateTeamErrors { errors: [CreateTeamError!]!\n}\n\ntype CreateTeamSuccess { project_id: uuid!\n  team_id: uuid!\n}\n\ntype DeleteFileErrors { errors: [DeleteFileError!]!\n}\n\ntype DeleteFileSuccess { file_id: uuid!\n}\n\ntype DeleteFirebaseTokenErrors { errors: [DeleteFirebaseTokenError!]!\n}\n\ntype DeleteFirebaseTokenSuccess { user_id: uuid!\n}\n\ntype DeleteFolderErrors { errors: [DeleteFolderError!]!\n}\n\ntype DeleteFolderSuccess { folder_id: uuid!\n}\n\ntype DeleteProjectCategoryErrors { errors: [DeleteProjectCategoryError!]!\n}\n\ntype DeleteProjectCategorySuccess { project_category_id: uuid!\n}\n\ntype DeleteProjectErrors { errors: [DeleteProjectError!]!\n}\n\ntype DeleteProjectLabelErrors { errors: [DeleteProjectLabelError!]!\n}\n\ntype DeleteProjectLabelSuccess { project_label_id: uuid!\n}\n\ntype DeleteProjectSuccess { project_id: uuid!\n}\n\ntype DeleteSubtaskErrors { errors: [DeleteSubtaskError!]!\n}\n\ntype DeleteSubtaskSuccess { subtask_id: uuid!\n  task_id: uuid!\n}\n\ntype DeleteTaskAttachmentErrors { errors: [DeleteTaskAttachmentError!]!\n}\n\ntype DeleteTaskAttachmentSuccess { task_id: uuid!\n}\n\ntype DeleteTaskErrors { errors: [DeleteTaskError!]!\n}\n\ntype DeleteTaskSuccess { task_id: uuid!\n}\n\ntype DeleteTeamErrors { errors: [DeleteTeamError!]!\n}\n\ntype DeleteTeamSuccess { project_id: uuid!\n  team_id: uuid!\n}\n\ntype DownloadFolderErrors { errors: [DownloadFolderError!]!\n}\n\ntype DownloadFolderSuccess { folder_id: uuid!\n}\n\ntype DuplicateApprovalOnFileVersion { message: String!\n  type: String!\n}\n\ntype DuplicateFilesErrors { errors: [DuplicateFilesError!]!\n}\n\ntype DuplicateFilesSuccess { file_ids: [uuid!]!\n}\n\ntype EmailAlreadyUsedByAnotherUser { message: String!\n  type: String!\n}\n\ntype FileAccessDenied { message: String!\n  type: String!\n}\n\ntype FileDoesNotExists { message: String!\n  type: String!\n}\n\ntype FileFormatNotSupported { message: String!\n  type: String!\n}\n\ntype FileNotInApprovalMode { message: String!\n  type: String!\n}\n\ntype FileTooLarge { message: String!\n  type: String!\n}\n\ntype FileVersionDoesNotExists { message: String!\n  type: String!\n}\n\ntype FinalizeUploadedChannelAssetErrors { errors: [FinalizeUploadedChannelAssetError!]!\n}\n\ntype FinalizeUploadedChannelAssetSuccess { channel_id: String!\n  public_url: String!\n}\n\ntype FinalizeUploadedFileErrors { errors: [FinalizeUploadedFileError!]!\n}\n\ntype FinalizeUploadedFileStructureErrors { errors: [FinalizeUploadedFileStructureError!]!\n}\n\ntype FinalizeUploadedFileStructureSuccess { parent_id: uuid!\n}\n\ntype FinalizeUploadedFileSuccess { file_id: uuid!\n}\n\ntype FinalizeUploadedFileVersionErrors { errors: [FinalizeUploadedFileVersionError!]!\n}\n\ntype FinalizeUploadedFileVersionSuccess { file_version_id: uuid!\n}\n\ntype FinalizeUploadedOrgAvatarErrors { errors: [FinalizeUploadedOrgAvatarError!]!\n}\n\ntype FinalizeUploadedOrgAvatarSuccess { org_id: uuid!\n}\n\ntype FinalizeUploadedOrgBackgroundErrors { errors: [FinalizeUploadedOrgBackgroundError!]!\n}\n\ntype FinalizeUploadedOrgBackgroundSuccess { org_id: uuid!\n}\n\ntype FinalizeUploadedProjectAvatarErrors { errors: [FinalizeUploadedProjectAvatarError!]!\n}\n\ntype FinalizeUploadedProjectAvatarSuccess { project_id: uuid!\n}\n\ntype FinalizeUploadedProjectBackgroundErrors { errors: [FinalizeUploadedProjectBackgroundError!]!\n}\n\ntype FinalizeUploadedProjectBackgroundSuccess { project_id: uuid!\n}\n\ntype FinalizeUploadedProjectBannerErrors { errors: [FinalizeUploadedProjectBannerError!]!\n}\n\ntype FinalizeUploadedProjectBannerSuccess { project_id: uuid!\n}\n\ntype FinalizeUploadedProjectSpreadsheetErrors { errors: [FinalizeUploadedProjectSpreadsheetError!]!\n}\n\ntype FinalizeUploadedProjectSpreadsheetSuccess { org_id: uuid!\n}\n\ntype FinalizeUploadedTaskAttachmentAnnotationErrors { errors: [FinalizeUploadedTaskAttachmentAnnotationError!]!\n}\n\ntype FinalizeUploadedTaskAttachmentAnnotationSuccess { task_attachment_id: uuid!\n}\n\ntype FinalizeUploadedTaskAttachmentErrors { errors: [FinalizeUploadedTaskAttachmentError!]!\n}\n\ntype FinalizeUploadedTaskAttachmentSuccess { task_attachment_id: uuid!\n}\n\ntype FinalizeUploadedTaskSpreadsheetErrors { errors: [FinalizeUploadedTaskSpreadsheetError!]!\n}\n\ntype FinalizeUploadedTaskSpreadsheetSuccess { project_id: uuid!\n}\n\ntype FinalizeUploadedUserAvatarErrors { errors: [FinalizeUploadedUserAvatarError!]!\n}\n\ntype FinalizeUploadedUserAvatarSuccess { user_id: uuid!\n}\n\ntype FolderAccessDenied { message: String!\n  type: String!\n}\n\ntype FolderCannotBeMoveInAnotherProject { message: String!\n  type: String!\n}\n\ntype FolderDoesNotExists { message: String!\n  type: String!\n}\n\ntype GetAlgoliaUserApiKeySuccess { exp: timestamptz!\n  key: String!\n}\n\ntype GetStreamChatUserTokenSuccess { token: String!\n}\n\ntype InputValidationError { fieldErrors: json!\n  formErrors: [String]!\n}\n\ntype InvalidContentType { message: String!\n  type: String!\n}\n\ntype JoinOrgUserProjectErrors { errors: [JoinOrgUserProjectError!]!\n}\n\ntype JoinOrgUserProjectPermissionDenied { message: String!\n  type: String!\n}\n\ntype JoinOrgUserProjectSuccess { projectId: uuid!\n}\n\ntype KeyDoesNotExists { message: String!\n  type: String!\n}\n\ntype MissingMetadata { message: String!\n  type: String!\n}\n\ntype MoveFilesErrors { errors: [MoveFilesError!]!\n}\n\ntype MoveFilesSuccess { file_ids: [uuid!]!\n}\n\ntype MoveFoldersErrors { errors: [MoveFoldersError!]!\n}\n\ntype MoveFoldersSuccess { folder_ids: [uuid!]!\n}\n\ntype Mutation { addMembersToProjectChannel(input: AddMembersToProjectChannelInput!): AddMembersToProjectChannelResult\n  addUserApprovalToFileVersion(input: AddUserApprovalToFileVersionInput!): AddUserApprovalToFileVersionResult\n  addUserInTeam(input: AddUserInTeamInput!): AddUserInTeamResult\n  addUserViewToFileVersion(input: AddUserViewToFileVersionInput!): AddUserViewToFileVersionResult\n  addUserViewToFolder(input: AddUserViewToFolderInput!): AddUserViewToFolderResult\n  addUserViewToProject(input: AddUserViewToProjectInput!): AddUserViewToProjectResult\n  addUserViewToTask(input: AddUserViewToTaskInput!): AddUserViewToTaskResult\n  annotateFile(input: AnnotateFileInput!): AnnotateFileResult\n  copyProject(input: CopyProjectInput!): CopyProjectResult\n  createChannelForProject(input: CreateChannelForProjectInput!): CreateChannelForProjectResult\n  createChannelForTask(input: CreateChannelForTaskInput!): CreateChannelForTaskResult\n  createEmptyFile(input: CreateEmptyFileInput!): CreateEmptyFileResult\n  createFolder(input: CreateFolderInput!): CreateFolderResult\n  createOrg(input: CreateOrgInput!): CreateOrgResult\n  createOrgProjectSummary(input: CreateOrgProjectSummaryInput!): CreateOrgProjectSummaryResult\n  createProject(input: CreateProjectInput!): CreateProjectResult\n  createProjectCategory(input: CreateProjectCategoryInput!): CreateProjectCategoryResult\n  createProjectDirectMessage(input: CreateProjectDirectMessageInput!): CreateProjectDirectMessageResult\n  createProjectLabel(input: CreateProjectLabelInput!): CreateProjectLabelResult\n  createSubtask(input: CreateSubtaskInput!): CreateSubtaskResult\n  createTask(input: CreateTaskInput!): CreateTaskResult\n  createTeam(input: CreateTeamInput!): CreateTeamResult\n  deleteFile(input: DeleteFileInput!): DeleteFileResult\n  deleteFirebaseToken(input: DeleteFirebaseTokenInput!): DeleteFirebaseTokenResult\n  deleteFolder(input: DeleteFolderInput!): DeleteFolderResult\n  deleteProject(input: DeleteProjectInput!): DeleteProjectResult\n  deleteProjectCategory(input: DeleteProjectCategoryInput!): DeleteProjectCategoryResult\n  deleteProjectLabel(input: DeleteProjectLabelInput!): DeleteProjectLabelResult\n  deleteSubtask(input: DeleteSubtaskInput!): DeleteSubtaskResult\n  deleteTask(input: DeleteTaskInput!): DeleteTaskResult\n  deleteTaskAttachment(input: DeleteTaskAttachmentInput!): DeleteTaskAttachmentResult\n  deleteTeam(input: DeleteTeamInput!): DeleteTeamResult\n  downloadFolder(input: DownloadFolderInput!): DownloadFolderResult\n  duplicateFiles(input: DuplicateFilesInput!): DuplicateFilesResult\n  finalizeUploadedChannelAsset(input: FinalizeUploadedChannelAssetInput!): FinalizeUploadedChannelAssetResult\n  finalizeUploadedFile(input: FinalizeUploadedFileInput!): FinalizeUploadedFileResult\n  finalizeUploadedFileStructure(input: FinalizeUploadedFileStructureInput!): FinalizeUploadedFileStructureResult\n  finalizeUploadedFileVersion(input: FinalizeUploadedFileVersionInput!): FinalizeUploadedFileVersionResult\n  finalizeUploadedOrgAvatar(input: FinalizeUploadedOrgAvatarInput!): FinalizeUploadedOrgAvatarResult\n  finalizeUploadedOrgBackground(input: FinalizeUploadedOrgBackgroundInput!): FinalizeUploadedOrgBackgroundResult\n  finalizeUploadedProjectAvatar(input: FinalizeUploadedProjectAvatarInput!): FinalizeUploadedProjectAvatarResult\n  finalizeUploadedProjectBackground(input: FinalizeUploadedProjectBackgroundInput!): FinalizeUploadedProjectBackgroundResult\n  finalizeUploadedProjectBanner(input: FinalizeUploadedProjectBannerInput!): FinalizeUploadedProjectBannerResult\n  finalizeUploadedProjectSpreadsheet(input: FinalizeUploadedProjectSpreadsheetInput!): FinalizeUploadedProjectSpreadsheetResult\n  finalizeUploadedTaskAttachment(input: FinalizeUploadedTaskAttachmentInput!): FinalizeUploadedTaskAttachmentResult\n  finalizeUploadedTaskAttachmentAnnotation(input: FinalizeUploadedTaskAttachmentAnnotationInput!): FinalizeUploadedTaskAttachmentAnnotationResult\n  finalizeUploadedTaskSpreadsheet(input: FinalizeUploadedTaskSpreadsheetInput!): FinalizeUploadedTaskSpreadsheetResult\n  finalizeUploadedUserAvatar(input: FinalizeUploadedUserAvatarInput!): FinalizeUploadedUserAvatarResult\n  joinOrgUserProject(input: JoinOrgUserProjectInput!): JoinOrgUserProjectResult\n  moveFiles(input: MoveFilesInput!): MoveFilesResult\n  moveFolders(input: MoveFoldersInput!): MoveFoldersResult\n  prepareChannelAssetForUpload(input: PrepareChannelAssetForUploadInput!): PrepareChannelAssetForUploadResult\n  prepareFileForUpload(input: PrepareFileForUploadInput!): PrepareFileForUploadResult\n  prepareFileStructureForUpload(input: PrepareFileStructureForUploadInput!): PrepareFileStructureForUploadResult\n  prepareFileVersionAnnotationForUpload(input: PrepareFileVersionAnnotationForUploadInput!): PrepareFileVersionAnnotationForUploadResult\n  prepareFileVersionForUpload(input: PrepareFileVersionForUploadInput!): PrepareFileVersionForUploadResult\n  prepareOrgAssetForUpload(input: PrepareOrgAssetForUploadInput!): PrepareOrgAssetForUploadResult\n  prepareProjectAssetForUpload(input: PrepareProjectAssetForUploadInput!): PrepareProjectAssetForUploadResult\n  prepareProjectSpreadsheetForUpload(input: PrepareProjectSpreadsheetForUploadInput!): PrepareProjectSpreadsheetForUploadResult\n  prepareProjectUserAvatarForUpload(input: PrepareProjectUserAvatarForUploadInput!): PrepareProjectUserAvatarForUploadResult\n  prepareTaskAttachmentAnnotationForUpload(input: PrepareTaskAttachmentAnnotationForUploadInput!): PrepareTaskAttachmentAnnotationForUploadResult\n  prepareTaskAttachmentForUpload(input: PrepareTaskAttachmentForUploadInput!): PrepareTaskAttachmentForUploadResult\n  prepareTaskSpreadsheetForUpload(input: PrepareTaskSpreadsheetForUploadInput!): PrepareTaskSpreadsheetForUploadResult\n  prepareUserAvatarForUpload(input: PrepareUserAvatarForUploadInput!): PrepareUserAvatarForUploadResult\n  projectInvitations(input: ProjectInvitationsInput!): ProjectInvitationsResult\n  readNotifications(input: ReadNotificationsInput!): ReadNotificationsResult\n  removeMembersFromProjectChannel(input: RemoveMembersFromProjectChannelInput!): RemoveMembersFromProjectChannelResult\n  removeUserInTeam(input: RemoveUserInTeamInput!): RemoveUserInTeamResult\n  renameChannelForProject(input: RenameChannelForProjectInput!): RenameChannelForProjectResult\n  renameFile(input: RenameFileInput!): RenameFileResult\n  renameFolder(input: RenameFolderInput!): RenameFolderResult\n  requestApprovalExport(input: RequestApprovalExportInput!): RequestApprovalExportResult\n  requestApprovalReport(input: RequestApprovalReportInput!): RequestApprovalReportResult\n  requestProjectExport(input: RequestProjectExportInput!): RequestProjectExportResult\n  requestTasksExport(input: RequestTasksExportInput!): RequestTasksExportResult\n  requestTasksReport(input: RequestTasksReportInput!): RequestTasksReportResult\n  requestUsersApprovalsFiles(input: RequestUsersApprovalsFilesInput!): RequestUsersApprovalsFilesResult\n  restoreFileVersion(input: RestoreFileVersionInput!): RestoreFileVersionResult\n  saveFirebaseToken(input: SaveFirebaseTokenInput!): SaveFirebaseTokenResult\n  signFile(input: SignFileInput!): SignFileResult\n  unreadNotifications(input: UnreadNotificationsInput!): UnreadNotificationsResult\n  updateArchiveTask(input: UpdateArchiveTaskInput!): UpdateArchiveTaskResult\n  updateAssignationsFiles(input: UpdateAssignationsFilesInput!): UpdateAssignationsFilesResult\n  updateAssignationsFilesFolders(input: UpdateAssignationsFilesFoldersInput!): UpdateAssignationsFilesFoldersResult\n  updateAssignationsFolders(input: UpdateAssignationsFoldersInput!): UpdateAssignationsFoldersResult\n  updateAssignationsTask(input: UpdateAssignationsTaskInput!): UpdateAssignationsTaskResult\n  updateBrowserLanguage(input: UpdateBrowserLanguageInput!): UpdateBrowserLanguageResult\n  updateBrowserTimezone(input: UpdateBrowserTimezoneInput!): UpdateBrowserTimezoneResult\n  updateDueDateFile(input: UpdateDueDateFileInput!): UpdateDueDateFileResult\n  updateEmailNotifications(input: UpdateEmailNotificationsInput!): UpdateEmailNotificationsResult\n  updateFilesApprovalMode(input: UpdateFilesApprovalModeInput!): UpdateFilesApprovalModeResult\n  updateLabelsFiles(input: UpdateLabelsFilesInput!): UpdateLabelsFilesResult\n  updateLabelsFolders(input: UpdateLabelsFoldersInput!): UpdateLabelsFoldersResult\n  updateLabelsTasks(input: UpdateLabelsTasksInput!): UpdateLabelsTasksResult\n  updateOrgProfile(input: UpdateOrgProfileInput!): UpdateOrgProfileResult\n  updateOrgProjectSummary(input: UpdateOrgProjectSummaryInput!): UpdateOrgProjectSummaryResult\n  updatePermissionsFile(input: UpdatePermissionsFileInput!): UpdatePermissionsFileResult\n  updatePermissionsFolder(input: UpdatePermissionsFolderInput!): UpdatePermissionsFolderResult\n  updateProjectArchive(input: UpdateProjectArchiveInput!): UpdateProjectArchiveResult\n  updateProjectCategory(input: UpdateProjectCategoryInput!): UpdateProjectCategoryResult\n  updateProjectLabel(input: UpdateProjectLabelInput!): UpdateProjectLabelResult\n  updateProjectMembersRole(input: UpdateProjectMembersRoleInput!): UpdateProjectMembersRoleResult\n  updateProjectProfile(input: UpdateProjectProfileInput!): UpdateProjectProfileResult\n  updateProjectRole(input: UpdateProjectRoleInput!): UpdateProjectRoleResult\n  updateProjectUserInfos(input: UpdateProjectUserInfosInput!): UpdateProjectUserInfosResult\n  updateProjectsCategories(input: UpdateProjectsCategoriesInput!): UpdateProjectsCategoriesResult\n  updateProjectsClient(input: UpdateProjectsClientInput!): UpdateProjectsClientResult\n  updatePushNotifications(input: UpdatePushNotificationsInput!): UpdatePushNotificationsResult\n  updateSubtask(input: UpdateSubtaskInput!): UpdateSubtaskResult\n  updateTask(input: UpdateTaskInput!): UpdateTaskResult\n  updateTasksAssignations(input: UpdateTasksAssignationsInput!): UpdateTasksAssignationsResult\n  updateTasksDates(input: UpdateTasksDatesInput!): UpdateTasksDatesResult\n  updateTeam(input: UpdateTeamInput!): UpdateTeamResult\n  updateUserAppMetadata(input: UpdateUserAppMetadataInput!): UpdateUserAppMetadataResult\n  updateUserProfile(input: UpdateUserProfileInput!): UpdateUserProfileResult\n  updateUserTeams(input: UpdateUserTeamsInput!): UpdateUserTeamsResult\n  updateUsersCompanyName(input: UpdateUsersCompanyNameInput!): UpdateUsersCompanyNameResult\n  updateUsersInTeam(input: UpdateUsersInTeamInput!): UpdateUsersInTeamResult\n  updateUsersTeams(input: UpdateUsersTeamsInput!): UpdateUsersTeamsResult\n  updateValidationTask(input: UpdateValidationTaskInput!): UpdateValidationTaskResult\n  updateValidationsTasks(input: UpdateValidationsTasksInput!): UpdateValidationsTasksResult\n}\n\ntype NotAuthorOfTheUpload { message: String!\n  type: String!\n}\n\ntype NotFoundFilesInApprovalMode { message: String!\n  type: String!\n}\n\ntype NotMemberOfThisChannel { message: String!\n  type: String!\n}\n\ntype NotificationDoesNotExists { message: String!\n  type: String!\n}\n\ntype OrgAccessDenied { message: String!\n  type: String!\n}\n\ntype OrgDoesNotExist { message: String!\n  type: String!\n}\n\ntype OrgProjectSummaryAlreadyExist { message: String!\n  type: String!\n}\n\ntype OrgProjectSummaryDoesNotExist { message: String!\n  type: String!\n}\n\ntype OrgRequired { message: String!\n  type: String!\n}\n\ntype PermissionsConflictError { message: String!\n  type: String!\n}\n\ntype PrepareChannelAssetForUploadErrors { errors: [PrepareChannelAssetForUploadError!]!\n}\n\ntype PrepareChannelAssetForUploadSuccess { key: uuid!\n  url: String!\n}\n\ntype PrepareFileForUploadErrors { errors: [PrepareFileForUploadError!]!\n}\n\ntype PrepareFileForUploadSuccess { key: uuid!\n  url: String!\n}\n\ntype PrepareFileStructureForUploadErrors { errors: [PrepareFileStructureForUploadError!]!\n}\n\ntype PrepareFileStructureForUploadSuccess { key: uuid!\n  url: String!\n}\n\ntype PrepareFileVersionAnnotationForUploadErrors { errors: [PrepareFileVersionAnnotationForUploadError!]!\n}\n\ntype PrepareFileVersionAnnotationForUploadSuccess { key: uuid!\n  url: String!\n}\n\ntype PrepareFileVersionForUploadErrors { errors: [PrepareFileVersionForUploadError!]!\n}\n\ntype PrepareFileVersionForUploadSuccess { key: uuid!\n  url: String!\n}\n\ntype PrepareOrgAssetForUploadErrors { errors: [PrepareOrgAssetForUploadError!]!\n}\n\ntype PrepareOrgAssetForUploadSuccess { key: uuid!\n  url: String!\n}\n\ntype PrepareProjectAssetForUploadErrors { errors: [PrepareProjectAssetForUploadError!]!\n}\n\ntype PrepareProjectAssetForUploadSuccess { key: uuid!\n  url: String!\n}\n\ntype PrepareProjectSpreadsheetForUploadErrors { errors: [PrepareProjectSpreadsheetForUploadError!]!\n}\n\ntype PrepareProjectSpreadsheetForUploadSuccess { key: uuid!\n  url: String!\n}\n\ntype PrepareProjectUserAvatarForUploadErrors { errors: [PrepareProjectUserAvatarForUploadError!]!\n}\n\ntype PrepareProjectUserAvatarForUploadSuccess { key: uuid!\n  url: String!\n}\n\ntype PrepareTaskAttachmentAnnotationForUploadErrors { errors: [PrepareTaskAttachmentAnnotationForUploadError!]!\n}\n\ntype PrepareTaskAttachmentAnnotationForUploadSuccess { key: uuid!\n  url: String!\n}\n\ntype PrepareTaskAttachmentForUploadErrors { errors: [PrepareTaskAttachmentForUploadError!]!\n}\n\ntype PrepareTaskAttachmentForUploadSuccess { key: uuid!\n  url: String!\n}\n\ntype PrepareTaskSpreadsheetForUploadErrors { errors: [PrepareTaskSpreadsheetForUploadError!]!\n}\n\ntype PrepareTaskSpreadsheetForUploadSuccess { key: uuid!\n  url: String!\n}\n\ntype PrepareUserAvatarForUploadErrors { errors: [PrepareUserAvatarForUploadError!]!\n}\n\ntype PrepareUserAvatarForUploadSuccess { key: uuid!\n  url: String!\n}\n\ntype ProjectAccessDenied { message: String!\n  type: String!\n}\n\ntype ProjectCategoryAccessDenied { message: String!\n  type: String!\n}\n\ntype ProjectCategoryDoesNotExist { message: String!\n  type: String!\n}\n\ntype ProjectDoesNotExist { message: String!\n  type: String!\n}\n\ntype ProjectInvitationsErrors { errors: [ProjectInvitationsError!]!\n}\n\ntype ProjectInvitationsSuccess { ok: Boolean!\n}\n\ntype ProjectLabelAccessDenied { message: String!\n  type: String!\n}\n\ntype ProjectLabelDoesNotExist { message: String!\n  type: String!\n}\n\ntype ProjectNeedsAtLeastOneOwner { message: String!\n  type: String!\n}\n\ntype Query { getAlgoliaUserApiKey: GetAlgoliaUserApiKeySuccess\n  getOrgAvatarUrl(id: uuid!): String\n  getOrgBackgroundUrl(id: uuid!): String\n  getPresignedFileUrl(id: uuid!): String\n  getPresignedOriginalFileUrl(id: uuid!): String\n  getPresignedTaskAttachmentUrl(id: uuid!): String\n  getProjectAvatarUrl(id: uuid!): String\n  getProjectBackgroundUrl(id: uuid!): String\n  getProjectBannerUrl(id: uuid!): String\n  getStreamChatUserToken: GetStreamChatUserTokenSuccess\n  getUserAuthLink(redirect: String, userId: uuid!): String\n  getUserAvatarUrl(id: uuid!): String\n}\n\ntype ReadNotificationsErrors { errors: [ReadNotificationsError!]!\n}\n\ntype ReadNotificationsSuccess { notification_ids: [uuid!]!\n}\n\ntype RemoveMembersFromProjectChannelErrors { errors: [RemoveMembersFromProjectChannelError!]!\n}\n\ntype RemoveMembersFromProjectChannelSuccess { channel_id: String!\n  project_id: uuid!\n}\n\ntype RemoveUserInTeamErrors { errors: [RemoveUserInTeamError!]!\n}\n\ntype RemoveUserInTeamSuccess { project_id: uuid!\n  team_id: uuid!\n  user_id: uuid!\n}\n\ntype RenameChannelForProjectErrors { errors: [RenameChannelForProjectError!]!\n}\n\ntype RenameChannelForProjectSuccess { channel_id: String!\n  project_id: uuid!\n}\n\ntype RenameFileErrors { errors: [RenameFileError!]!\n}\n\ntype RenameFileSuccess { file_id: uuid!\n}\n\ntype RenameFolderErrors { errors: [RenameFolderError!]!\n}\n\ntype RenameFolderSuccess { folder_id: uuid!\n}\n\ntype RequestApprovalExportErrors { errors: [RequestApprovalExportError!]!\n}\n\ntype RequestApprovalExportSuccess { project_id: uuid!\n}\n\ntype RequestApprovalReportErrors { errors: [RequestApprovalReportError!]!\n}\n\ntype RequestApprovalReportSuccess { project_id: uuid!\n}\n\ntype RequestProjectExportErrors { errors: [RequestProjectExportError!]!\n}\n\ntype RequestProjectExportSuccess { project_id: uuid!\n}\n\ntype RequestTasksExportErrors { errors: [RequestTasksExportError!]!\n}\n\ntype RequestTasksExportSuccess { project_id: uuid!\n}\n\ntype RequestTasksReportErrors { errors: [RequestTasksReportError!]!\n}\n\ntype RequestTasksReportSuccess { project_id: uuid!\n}\n\ntype RequestUsersApprovalsFilesErrors { errors: [RequestUsersApprovalsFilesError!]!\n}\n\ntype RequestUsersApprovalsFilesSuccess { file_ids: [uuid!]!\n}\n\ntype RestoreFileVersionErrors { errors: [RestoreFileVersionError!]!\n}\n\ntype RestoreFileVersionSuccess { file_version_id: uuid!\n}\n\ntype SaveFirebaseTokenErrors { errors: [SaveFirebaseTokenError!]!\n}\n\ntype SaveFirebaseTokenSuccess { user_device_id: uuid!\n  user_id: uuid!\n}\n\ntype SignFileErrors { errors: [SignFileError!]!\n}\n\ntype SignFileSuccess { file_version_id: uuid!\n}\n\ntype SubtaskAccessDenied { message: String!\n  type: String!\n}\n\ntype SubtaskDoesNotExist { message: String!\n  type: String!\n}\n\ntype TaskAccessDenied { message: String!\n  type: String!\n}\n\ntype TaskAssignationsNotAllowed { message: String!\n  type: String!\n}\n\ntype TaskAttachmentAccessDenied { message: String!\n  type: String!\n}\n\ntype TaskAttachmentDoesNotExist { message: String!\n  type: String!\n}\n\ntype TaskDoesNotExist { message: String!\n  type: String!\n}\n\ntype TeamAccessDenied { message: String!\n  type: String!\n}\n\ntype TeamDoesNotExist { message: String!\n  type: String!\n}\n\ntype TeamNameAlreadyExist { message: String!\n  type: String!\n}\n\ntype UnreadNotificationsErrors { errors: [UnreadNotificationsError!]!\n}\n\ntype UnreadNotificationsSuccess { notification_ids: [uuid!]!\n}\n\ntype UpdateArchiveTaskErrors { errors: [UpdateArchiveTaskError!]!\n}\n\ntype UpdateArchiveTaskSuccess { task_id: uuid!\n}\n\ntype UpdateAssignationTaskSuccess { task_id: uuid!\n}\n\ntype UpdateAssignationsFilesErrors { errors: [UpdateAssignationsFilesError!]!\n}\n\ntype UpdateAssignationsFilesFoldersErrors { errors: [UpdateAssignationsFilesFoldersError!]!\n}\n\ntype UpdateAssignationsFilesFoldersSuccess { file_ids: [uuid!]!\n  folder_ids: [uuid!]!\n}\n\ntype UpdateAssignationsFilesSuccess { file_ids: [uuid!]!\n}\n\ntype UpdateAssignationsFoldersErrors { errors: [UpdateAssignationsFoldersError!]!\n}\n\ntype UpdateAssignationsFoldersSuccess { folder_ids: [uuid!]!\n}\n\ntype UpdateAssignationsTaskErrors { errors: [UpdateAssignationsTaskError!]!\n}\n\ntype UpdateBrowserLanguageErrors { errors: [UpdateBrowserLanguageError!]!\n}\n\ntype UpdateBrowserLanguageSuccess { user_id: ID!\n}\n\ntype UpdateBrowserTimezoneErrors { errors: [UpdateBrowserTimezoneError!]!\n}\n\ntype UpdateBrowserTimezoneSuccess { user_id: ID!\n}\n\ntype UpdateDueDateFileErrors { errors: [UpdateDueDateFileError!]!\n}\n\ntype UpdateDueDateFileSuccess { file_id: uuid!\n}\n\ntype UpdateEmailNotificationsErrors { errors: [UpdateEmailNotificationsError!]!\n}\n\ntype UpdateEmailNotificationsSuccess { email_notifications_id: uuid!\n}\n\ntype UpdateFilesApprovalModeErrors { errors: [UpdateFilesApprovalModeError!]!\n}\n\ntype UpdateFilesApprovalModeSuccess { file_ids: [uuid!]!\n}\n\ntype UpdateLabelsFilesErrors { errors: [UpdateLabelsFilesError!]!\n}\n\ntype UpdateLabelsFilesSuccess { file_ids: [uuid!]!\n}\n\ntype UpdateLabelsFoldersErrors { errors: [UpdateLabelsFoldersError!]!\n}\n\ntype UpdateLabelsFoldersSuccess { folder_ids: [uuid!]!\n}\n\ntype UpdateLabelsTasksErrors { errors: [UpdateLabelsTasksError!]!\n}\n\ntype UpdateLabelsTasksSuccess { task_ids: [uuid!]!\n}\n\ntype UpdateOrgProfileErrors { errors: [UpdateOrgProfileError!]!\n}\n\ntype UpdateOrgProfilePermissionDenied { message: String!\n  type: String!\n}\n\ntype UpdateOrgProfileSuccess { org_id: ID!\n}\n\ntype UpdateOrgProjectSummaryErrors { errors: [UpdateOrgProjectSummaryError!]!\n}\n\ntype UpdateOrgProjectSummaryPermissionDenied { message: String!\n  type: String!\n}\n\ntype UpdateOrgProjectSummarySuccess { org_project_summary_id: uuid!\n}\n\ntype UpdatePermissionFileSuccess { file_id: uuid!\n}\n\ntype UpdatePermissionFolderSuccess { folder_id: uuid!\n}\n\ntype UpdatePermissionsFileErrors { errors: [UpdatePermissionsFileError!]!\n}\n\ntype UpdatePermissionsFolderErrors { errors: [UpdatePermissionsFolderError!]!\n}\n\ntype UpdateProjectArchiveErrors { errors: [UpdateProjectArchiveError!]!\n}\n\ntype UpdateProjectArchiveSuccess { project_id: uuid!\n}\n\ntype UpdateProjectCategoryErrors { errors: [UpdateProjectCategoryError!]!\n}\n\ntype UpdateProjectCategorySuccess { project_category_id: uuid!\n}\n\ntype UpdateProjectLabelErrors { errors: [UpdateProjectLabelError!]!\n}\n\ntype UpdateProjectLabelSuccess { project_label_id: uuid!\n}\n\ntype UpdateProjectMembersRoleErrors { errors: [UpdateProjectMembersRoleError!]!\n}\n\ntype UpdateProjectMembersRoleSuccess { project_id: uuid!\n  user_ids: [uuid]!\n}\n\ntype UpdateProjectProfileErrors { errors: [UpdateProjectProfileError!]!\n}\n\ntype UpdateProjectProfilePermissionDenied { message: String!\n  type: String!\n}\n\ntype UpdateProjectProfileSuccess { project_id: ID!\n}\n\ntype UpdateProjectRoleErrors { errors: [UpdateProjectRoleError!]!\n}\n\ntype UpdateProjectRoleSuccess { project_id: uuid!\n  user_id: uuid!\n}\n\ntype UpdateProjectUserInfosErrors { errors: [UpdateProjectUserInfosError!]!\n}\n\ntype UpdateProjectUserInfosPermissionDenied { message: String!\n  type: String!\n}\n\ntype UpdateProjectUserInfosSuccess { project_id: uuid!\n  user_id: uuid!\n}\n\ntype UpdateProjectsCategoriesErrors { errors: [UpdateProjectsCategoriesError!]!\n}\n\ntype UpdateProjectsCategoriesSuccess { categories: [uuid!]\n  orgId: uuid!\n  projectIds: [uuid!]\n}\n\ntype UpdateProjectsClientErrors { errors: [UpdateProjectsClientError!]!\n}\n\ntype UpdateProjectsClientSuccess { client_email: String\n  client_fullname: String!\n  client_phone_number: String\n}\n\ntype UpdatePushNotificationsErrors { errors: [UpdatePushNotificationsError!]!\n}\n\ntype UpdatePushNotificationsSuccess { user_id: uuid!\n}\n\ntype UpdateSubtaskErrors { errors: [UpdateSubtaskError!]!\n}\n\ntype UpdateSubtaskSuccess { subtask_id: uuid!\n  task_id: uuid!\n}\n\ntype UpdateTaskErrors { errors: [UpdateTaskError!]!\n}\n\ntype UpdateTaskPermissionDenied { message: String!\n  type: String!\n}\n\ntype UpdateTaskSuccess { task_id: uuid!\n}\n\ntype UpdateTasksAssignationsErrors { errors: [UpdateTasksAssignationsError!]!\n}\n\ntype UpdateTasksAssignationsSuccess { task_ids: [uuid!]!\n}\n\ntype UpdateTasksDatesErrors { errors: [UpdateTasksDatesError!]!\n}\n\ntype UpdateTasksDatesSuccess { task_ids: [uuid!]!\n}\n\ntype UpdateTeamErrors { errors: [UpdateTeamError!]!\n}\n\ntype UpdateTeamSuccess { project_id: uuid!\n  team_id: uuid!\n}\n\ntype UpdateUserAppMetadataErrors { errors: [UpdateUserAppMetadataError!]!\n}\n\ntype UpdateUserAppMetadataSuccess { user_id: ID!\n}\n\ntype UpdateUserProfileErrors { errors: [UpdateUserProfileError!]!\n}\n\ntype UpdateUserProfileSuccess { ok: Boolean!\n  user_id: ID!\n}\n\ntype UpdateUserTeamsErrors { errors: [UpdateUserTeamsError!]!\n}\n\ntype UpdateUserTeamsSuccess { project_id: uuid!\n  team_ids: [uuid]!\n  user_id: uuid!\n}\n\ntype UpdateUsersCompanyNameErrors { errors: [UpdateUsersCompanyNameError!]!\n}\n\ntype UpdateUsersCompanyNameSuccess { company_name: String!\n  project_id: uuid!\n  user_ids: [uuid]!\n}\n\ntype UpdateUsersInTeamErrors { errors: [UpdateUsersInTeamError!]!\n}\n\ntype UpdateUsersInTeamSuccess { project_id: uuid!\n  team_id: uuid!\n}\n\ntype UpdateUsersTeamsErrors { errors: [UpdateUsersTeamsError!]!\n}\n\ntype UpdateUsersTeamsSuccess { project_id: uuid!\n  team_ids: [uuid]!\n  user_ids: [uuid]!\n}\n\ntype UpdateValidationTaskErrors { errors: [UpdateValidationTaskError!]!\n}\n\ntype UpdateValidationTaskSuccess { task_id: uuid!\n}\n\ntype UpdateValidationsTasksErrors { errors: [UpdateValidationsTasksError!]!\n}\n\ntype UpdateValidationsTasksSuccess { task_ids: [uuid!]!\n}\n\ntype UserAlreadyPartOfThisTeam { message: String!\n  type: String!\n}\n\ntype UserDoesNotExist { message: String!\n  type: String!\n}\n\ntype UserNotAssignedToFile { message: String!\n  type: String!\n}\n\ntype UserNotModeratorOfThisChannel { message: String!\n  type: String!\n}\n\ntype UserNotPartOfThisTeam { message: String!\n  type: String!\n}\n\ntype optionsSuccess { labels: Boolean\n  members: Boolean\n  publicDocuments: Boolean\n  restrictedDocuments: Boolean\n  tasks: Boolean\n  tasksComments: Boolean\n  teams: Boolean\n}\n\nunion AddMembersToProjectChannelError  = ChannelDoesNotExist | InputValidationError | NotMemberOfThisChannel | ProjectAccessDenied | ProjectDoesNotExist | UserDoesNotExist | UserNotModeratorOfThisChannel\n\nunion AddMembersToProjectChannelResult  = AddMembersToProjectChannelErrors | AddMembersToProjectChannelSuccess\n\nunion AddUserApprovalToFileVersionError  = DuplicateApprovalOnFileVersion | FileAccessDenied | FileDoesNotExists | FileNotInApprovalMode | FileVersionDoesNotExists | InputValidationError | UserNotAssignedToFile\n\nunion AddUserApprovalToFileVersionResult  = AddUserApprovalToFileVersionErrors | AddUserApprovalToFileVersionSuccess\n\nunion AddUserInTeamError  = InputValidationError | TeamAccessDenied | TeamDoesNotExist | UserAlreadyPartOfThisTeam | UserDoesNotExist\n\nunion AddUserInTeamResult  = AddUserInTeamErrors | AddUserInTeamSuccess\n\nunion AddUserViewToFileVersionError  = FileAccessDenied | FileDoesNotExists | FileVersionDoesNotExists | InputValidationError\n\nunion AddUserViewToFileVersionResult  = AddUserViewToFileVersionErrors | AddUserViewToFileVersionSuccess\n\nunion AddUserViewToFolderError  = FolderAccessDenied | FolderDoesNotExists | InputValidationError\n\nunion AddUserViewToFolderResult  = AddUserViewToFolderErrors | AddUserViewToFolderSuccess\n\nunion AddUserViewToProjectError  = InputValidationError | ProjectAccessDenied | ProjectDoesNotExist\n\nunion AddUserViewToProjectResult  = AddUserViewToProjectErrors | AddUserViewToProjectSuccess\n\nunion AddUserViewToTaskError  = InputValidationError | TaskAccessDenied | TaskDoesNotExist\n\nunion AddUserViewToTaskResult  = AddUserViewToTaskErrors | AddUserViewToTaskSuccess\n\nunion AnnotateFileError  = FileAccessDenied | FileFormatNotSupported | FileVersionDoesNotExists\n\nunion AnnotateFileResult  = AnnotateFileErrors | AnnotateFileSuccess\n\nunion CopyProjectError  = InputValidationError | ProjectAccessDenied | ProjectDoesNotExist\n\nunion CopyProjectResult  = CopyProjectErrors | CopyProjectSuccess\n\nunion CreateChannelForProjectError  = InputValidationError | ProjectAccessDenied | ProjectDoesNotExist | UserDoesNotExist\n\nunion CreateChannelForProjectResult  = CreateChannelForProjectErrors | CreateChannelForProjectSuccess\n\nunion CreateChannelForTaskError  = InputValidationError | TaskAccessDenied | TaskDoesNotExist\n\nunion CreateChannelForTaskResult  = CreateChannelForTaskErrors | CreateChannelForTaskSuccess\n\nunion CreateEmptyFileError  = FileFormatNotSupported | FolderAccessDenied | FolderDoesNotExists | InputValidationError\n\nunion CreateEmptyFileResult  = CreateEmptyFileErrors | CreateEmptyFileSuccess\n\nunion CreateFolderError  = FolderAccessDenied | FolderDoesNotExists | InputValidationError\n\nunion CreateFolderResult  = CreateFolderErrors | CreateFolderSuccess\n\nunion CreateOrgError  = CreateOrgFailed | InputValidationError\n\nunion CreateOrgProjectSummaryError  = CannotCreateOrgProjectSummaryOnOrgProject | InputValidationError | OrgAccessDenied | OrgDoesNotExist | OrgProjectSummaryAlreadyExist | ProjectAccessDenied | ProjectCategoryDoesNotExist | ProjectDoesNotExist\n\nunion CreateOrgProjectSummaryResult  = CreateOrgProjectSummaryErrors | CreateOrgProjectSummarySuccess\n\nunion CreateOrgResult  = CreateOrgErrors | CreateOrgSuccess\n\nunion CreateProjectCategoryError  = InputValidationError | OrgDoesNotExist | ProjectCategoryAccessDenied\n\nunion CreateProjectCategoryResult  = CreateProjectCategoryErrors | CreateProjectCategorySuccess\n\nunion CreateProjectDirectMessageError  = InputValidationError | ProjectAccessDenied | ProjectDoesNotExist | UserDoesNotExist\n\nunion CreateProjectDirectMessageResult  = CreateProjectDirectMessageErrors | CreateProjectDirectMessageSuccess\n\nunion CreateProjectError  = InputValidationError | OrgRequired\n\nunion CreateProjectLabelError  = InputValidationError | ProjectDoesNotExist | ProjectLabelAccessDenied\n\nunion CreateProjectLabelResult  = CreateProjectLabelErrors | CreateProjectLabelSuccess\n\nunion CreateProjectResult  = CreateProjectErrors | CreateProjectSuccess\n\nunion CreateSubtaskError  = InputValidationError | TaskAccessDenied | TaskDoesNotExist\n\nunion CreateSubtaskResult  = CreateSubtaskErrors | CreateSubtaskSuccess\n\nunion CreateTaskError  = InputValidationError | ProjectDoesNotExist | TaskAccessDenied | TaskAssignationsNotAllowed\n\nunion CreateTaskResult  = CreateTaskErrors | CreateTaskSuccess\n\nunion CreateTeamError  = InputValidationError | ProjectDoesNotExist | TeamAccessDenied | TeamNameAlreadyExist\n\nunion CreateTeamResult  = CreateTeamErrors | CreateTeamSuccess\n\nunion DeleteFileError  = FileAccessDenied | FileDoesNotExists | InputValidationError\n\nunion DeleteFileResult  = DeleteFileErrors | DeleteFileSuccess\n\nunion DeleteFirebaseTokenError  = InputValidationError\n\nunion DeleteFirebaseTokenResult  = DeleteFirebaseTokenErrors | DeleteFirebaseTokenSuccess\n\nunion DeleteFolderError  = FolderAccessDenied | FolderDoesNotExists | InputValidationError\n\nunion DeleteFolderResult  = DeleteFolderErrors | DeleteFolderSuccess\n\nunion DeleteProjectCategoryError  = InputValidationError | ProjectCategoryAccessDenied | ProjectCategoryDoesNotExist\n\nunion DeleteProjectCategoryResult  = DeleteProjectCategoryErrors | DeleteProjectCategorySuccess\n\nunion DeleteProjectError  = CannotDeleteOrgProject | CannotDeleteProjectSharedWithMultipleOrgs | InputValidationError | ProjectAccessDenied | ProjectDoesNotExist\n\nunion DeleteProjectLabelError  = InputValidationError | ProjectLabelAccessDenied | ProjectLabelDoesNotExist\n\nunion DeleteProjectLabelResult  = DeleteProjectLabelErrors | DeleteProjectLabelSuccess\n\nunion DeleteProjectResult  = DeleteProjectErrors | DeleteProjectSuccess\n\nunion DeleteSubtaskError  = InputValidationError | SubtaskAccessDenied | SubtaskDoesNotExist\n\nunion DeleteSubtaskResult  = DeleteSubtaskErrors | DeleteSubtaskSuccess\n\nunion DeleteTaskAttachmentError  = InputValidationError | TaskAttachmentAccessDenied | TaskAttachmentDoesNotExist\n\nunion DeleteTaskAttachmentResult  = DeleteTaskAttachmentErrors | DeleteTaskAttachmentSuccess\n\nunion DeleteTaskError  = InputValidationError | TaskAccessDenied | TaskDoesNotExist\n\nunion DeleteTaskResult  = DeleteTaskErrors | DeleteTaskSuccess\n\nunion DeleteTeamError  = InputValidationError | TeamAccessDenied | TeamDoesNotExist\n\nunion DeleteTeamResult  = DeleteTeamErrors | DeleteTeamSuccess\n\nunion DownloadFolderError  = FolderAccessDenied | FolderDoesNotExists | InputValidationError\n\nunion DownloadFolderResult  = DownloadFolderErrors | DownloadFolderSuccess\n\nunion DuplicateFilesError  = FileAccessDenied | FileDoesNotExists | InputValidationError\n\nunion DuplicateFilesResult  = DuplicateFilesErrors | DuplicateFilesSuccess\n\nunion FinalizeUploadedChannelAssetError  = CopyFromTemporaryBucketFailed | InputValidationError | KeyDoesNotExists | MissingMetadata | NotAuthorOfTheUpload\n\nunion FinalizeUploadedChannelAssetResult  = FinalizeUploadedChannelAssetErrors | FinalizeUploadedChannelAssetSuccess\n\nunion FinalizeUploadedFileError  = CopyFromTemporaryBucketFailed | InputValidationError | KeyDoesNotExists | MissingMetadata | NotAuthorOfTheUpload\n\nunion FinalizeUploadedFileResult  = FinalizeUploadedFileErrors | FinalizeUploadedFileSuccess\n\nunion FinalizeUploadedFileStructureError  = FileTooLarge | InputValidationError | KeyDoesNotExists | MissingMetadata | NotAuthorOfTheUpload\n\nunion FinalizeUploadedFileStructureResult  = FinalizeUploadedFileStructureErrors | FinalizeUploadedFileStructureSuccess\n\nunion FinalizeUploadedFileVersionError  = CopyFromTemporaryBucketFailed | FileDoesNotExists | InputValidationError | KeyDoesNotExists | MissingMetadata | NotAuthorOfTheUpload\n\nunion FinalizeUploadedFileVersionResult  = FinalizeUploadedFileVersionErrors | FinalizeUploadedFileVersionSuccess\n\nunion FinalizeUploadedOrgAvatarError  = CopyFromTemporaryBucketFailed | InputValidationError | KeyDoesNotExists | MissingMetadata | NotAuthorOfTheUpload\n\nunion FinalizeUploadedOrgAvatarResult  = FinalizeUploadedOrgAvatarErrors | FinalizeUploadedOrgAvatarSuccess\n\nunion FinalizeUploadedOrgBackgroundError  = CopyFromTemporaryBucketFailed | InputValidationError | KeyDoesNotExists | MissingMetadata | NotAuthorOfTheUpload\n\nunion FinalizeUploadedOrgBackgroundResult  = FinalizeUploadedOrgBackgroundErrors | FinalizeUploadedOrgBackgroundSuccess\n\nunion FinalizeUploadedProjectAvatarError  = InputValidationError | KeyDoesNotExists | MissingMetadata | NotAuthorOfTheUpload\n\nunion FinalizeUploadedProjectAvatarResult  = FinalizeUploadedProjectAvatarErrors | FinalizeUploadedProjectAvatarSuccess\n\nunion FinalizeUploadedProjectBackgroundError  = InputValidationError | KeyDoesNotExists | MissingMetadata | NotAuthorOfTheUpload\n\nunion FinalizeUploadedProjectBackgroundResult  = FinalizeUploadedProjectBackgroundErrors | FinalizeUploadedProjectBackgroundSuccess\n\nunion FinalizeUploadedProjectBannerError  = InputValidationError | KeyDoesNotExists | MissingMetadata | NotAuthorOfTheUpload\n\nunion FinalizeUploadedProjectBannerResult  = FinalizeUploadedProjectBannerErrors | FinalizeUploadedProjectBannerSuccess\n\nunion FinalizeUploadedProjectSpreadsheetError  = FileTooLarge | InputValidationError | InvalidContentType | KeyDoesNotExists | MissingMetadata | NotAuthorOfTheUpload\n\nunion FinalizeUploadedProjectSpreadsheetResult  = FinalizeUploadedProjectSpreadsheetErrors | FinalizeUploadedProjectSpreadsheetSuccess\n\nunion FinalizeUploadedTaskAttachmentAnnotationError  = CopyFromTemporaryBucketFailed | InputValidationError | KeyDoesNotExists | MissingMetadata | NotAuthorOfTheUpload | TaskAttachmentDoesNotExist\n\nunion FinalizeUploadedTaskAttachmentAnnotationResult  = FinalizeUploadedTaskAttachmentAnnotationErrors | FinalizeUploadedTaskAttachmentAnnotationSuccess\n\nunion FinalizeUploadedTaskAttachmentError  = CopyFromTemporaryBucketFailed | InputValidationError | KeyDoesNotExists | MissingMetadata | NotAuthorOfTheUpload\n\nunion FinalizeUploadedTaskAttachmentResult  = FinalizeUploadedTaskAttachmentErrors | FinalizeUploadedTaskAttachmentSuccess\n\nunion FinalizeUploadedTaskSpreadsheetError  = FileTooLarge | InputValidationError | InvalidContentType | KeyDoesNotExists | MissingMetadata | NotAuthorOfTheUpload\n\nunion FinalizeUploadedTaskSpreadsheetResult  = FinalizeUploadedTaskSpreadsheetErrors | FinalizeUploadedTaskSpreadsheetSuccess\n\nunion FinalizeUploadedUserAvatarError  = CopyFromTemporaryBucketFailed | InputValidationError | KeyDoesNotExists | MissingMetadata\n\nunion FinalizeUploadedUserAvatarResult  = FinalizeUploadedUserAvatarErrors | FinalizeUploadedUserAvatarSuccess\n\nunion JoinOrgUserProjectError  = CannotInviteOnProject | InputValidationError | JoinOrgUserProjectPermissionDenied\n\nunion JoinOrgUserProjectResult  = JoinOrgUserProjectErrors | JoinOrgUserProjectSuccess\n\nunion MoveFilesError  = FileAccessDenied | FileDoesNotExists | InputValidationError | PermissionsConflictError\n\nunion MoveFilesResult  = MoveFilesErrors | MoveFilesSuccess\n\nunion MoveFoldersError  = FolderAccessDenied | FolderCannotBeMoveInAnotherProject | FolderDoesNotExists | InputValidationError | PermissionsConflictError\n\nunion MoveFoldersResult  = MoveFoldersErrors | MoveFoldersSuccess\n\nunion PrepareChannelAssetForUploadError  = ChannelDoesNotExist | InputValidationError | NotMemberOfThisChannel\n\nunion PrepareChannelAssetForUploadResult  = PrepareChannelAssetForUploadErrors | PrepareChannelAssetForUploadSuccess\n\nunion PrepareFileForUploadError  = FolderAccessDenied | FolderDoesNotExists | InputValidationError\n\nunion PrepareFileForUploadResult  = PrepareFileForUploadErrors | PrepareFileForUploadSuccess\n\nunion PrepareFileStructureForUploadError  = FolderAccessDenied | FolderDoesNotExists | InputValidationError\n\nunion PrepareFileStructureForUploadResult  = PrepareFileStructureForUploadErrors | PrepareFileStructureForUploadSuccess\n\nunion PrepareFileVersionAnnotationForUploadError  = FileAccessDenied | FileVersionDoesNotExists | InputValidationError\n\nunion PrepareFileVersionAnnotationForUploadResult  = PrepareFileVersionAnnotationForUploadErrors | PrepareFileVersionAnnotationForUploadSuccess\n\nunion PrepareFileVersionForUploadError  = FileAccessDenied | FileDoesNotExists | InputValidationError\n\nunion PrepareFileVersionForUploadResult  = PrepareFileVersionForUploadErrors | PrepareFileVersionForUploadSuccess\n\nunion PrepareOrgAssetForUploadError  = InputValidationError | OrgAccessDenied | OrgDoesNotExist\n\nunion PrepareOrgAssetForUploadResult  = PrepareOrgAssetForUploadErrors | PrepareOrgAssetForUploadSuccess\n\nunion PrepareProjectAssetForUploadError  = InputValidationError | ProjectAccessDenied | ProjectDoesNotExist\n\nunion PrepareProjectAssetForUploadResult  = PrepareProjectAssetForUploadErrors | PrepareProjectAssetForUploadSuccess\n\nunion PrepareProjectSpreadsheetForUploadError  = InputValidationError | OrgAccessDenied | OrgDoesNotExist\n\nunion PrepareProjectSpreadsheetForUploadResult  = PrepareProjectSpreadsheetForUploadErrors | PrepareProjectSpreadsheetForUploadSuccess\n\nunion PrepareProjectUserAvatarForUploadError  = InputValidationError | ProjectAccessDenied | ProjectDoesNotExist | UpdateProjectUserInfosPermissionDenied | UserDoesNotExist\n\nunion PrepareProjectUserAvatarForUploadResult  = PrepareProjectUserAvatarForUploadErrors | PrepareProjectUserAvatarForUploadSuccess\n\nunion PrepareTaskAttachmentAnnotationForUploadError  = InputValidationError | TaskAccessDenied | TaskAttachmentDoesNotExist | TaskDoesNotExist\n\nunion PrepareTaskAttachmentAnnotationForUploadResult  = PrepareTaskAttachmentAnnotationForUploadErrors | PrepareTaskAttachmentAnnotationForUploadSuccess\n\nunion PrepareTaskAttachmentForUploadError  = InputValidationError | TaskAccessDenied | TaskDoesNotExist\n\nunion PrepareTaskAttachmentForUploadResult  = PrepareTaskAttachmentForUploadErrors | PrepareTaskAttachmentForUploadSuccess\n\nunion PrepareTaskSpreadsheetForUploadError  = InputValidationError | ProjectAccessDenied | ProjectDoesNotExist\n\nunion PrepareTaskSpreadsheetForUploadResult  = PrepareTaskSpreadsheetForUploadErrors | PrepareTaskSpreadsheetForUploadSuccess\n\nunion PrepareUserAvatarForUploadError  = InputValidationError\n\nunion PrepareUserAvatarForUploadResult  = PrepareUserAvatarForUploadErrors | PrepareUserAvatarForUploadSuccess\n\nunion ProjectInvitationsError  = CannotUpdateProjectRole | InputValidationError | ProjectAccessDenied\n\nunion ProjectInvitationsResult  = ProjectInvitationsErrors | ProjectInvitationsSuccess\n\nunion ReadNotificationsError  = InputValidationError | NotificationDoesNotExists\n\nunion ReadNotificationsResult  = ReadNotificationsErrors | ReadNotificationsSuccess\n\nunion RemoveMembersFromProjectChannelError  = ChannelDoesNotExist | InputValidationError | NotMemberOfThisChannel | ProjectAccessDenied | ProjectDoesNotExist | UserNotModeratorOfThisChannel\n\nunion RemoveMembersFromProjectChannelResult  = RemoveMembersFromProjectChannelErrors | RemoveMembersFromProjectChannelSuccess\n\nunion RemoveUserInTeamError  = InputValidationError | TeamAccessDenied | TeamDoesNotExist | UserDoesNotExist | UserNotPartOfThisTeam\n\nunion RemoveUserInTeamResult  = RemoveUserInTeamErrors | RemoveUserInTeamSuccess\n\nunion RenameChannelForProjectError  = ChannelDoesNotExist | InputValidationError | NotMemberOfThisChannel | ProjectAccessDenied | ProjectDoesNotExist | UserNotModeratorOfThisChannel\n\nunion RenameChannelForProjectResult  = RenameChannelForProjectErrors | RenameChannelForProjectSuccess\n\nunion RenameFileError  = FileAccessDenied | FileDoesNotExists | InputValidationError\n\nunion RenameFileResult  = RenameFileErrors | RenameFileSuccess\n\nunion RenameFolderError  = FolderAccessDenied | FolderDoesNotExists | InputValidationError\n\nunion RenameFolderResult  = RenameFolderErrors | RenameFolderSuccess\n\nunion RequestApprovalExportError  = FileDoesNotExists | InputValidationError | NotFoundFilesInApprovalMode | ProjectAccessDenied | ProjectDoesNotExist\n\nunion RequestApprovalExportResult  = RequestApprovalExportErrors | RequestApprovalExportSuccess\n\nunion RequestApprovalReportError  = FileDoesNotExists | InputValidationError | NotFoundFilesInApprovalMode | ProjectAccessDenied | ProjectDoesNotExist\n\nunion RequestApprovalReportResult  = RequestApprovalReportErrors | RequestApprovalReportSuccess\n\nunion RequestProjectExportError  = InputValidationError | ProjectAccessDenied | ProjectDoesNotExist\n\nunion RequestProjectExportResult  = RequestProjectExportErrors | RequestProjectExportSuccess\n\nunion RequestTasksExportError  = InputValidationError | ProjectAccessDenied | ProjectDoesNotExist | TaskDoesNotExist | TeamDoesNotExist | UserDoesNotExist\n\nunion RequestTasksExportResult  = RequestTasksExportErrors | RequestTasksExportSuccess\n\nunion RequestTasksReportError  = InputValidationError | ProjectAccessDenied | ProjectDoesNotExist | TaskDoesNotExist | TeamDoesNotExist | UserDoesNotExist\n\nunion RequestTasksReportResult  = RequestTasksReportErrors | RequestTasksReportSuccess\n\nunion RequestUsersApprovalsFilesError  = FileAccessDenied | FileDoesNotExists | InputValidationError\n\nunion RequestUsersApprovalsFilesResult  = RequestUsersApprovalsFilesErrors | RequestUsersApprovalsFilesSuccess\n\nunion RestoreFileVersionError  = FileAccessDenied | FileVersionDoesNotExists | InputValidationError\n\nunion RestoreFileVersionResult  = RestoreFileVersionErrors | RestoreFileVersionSuccess\n\nunion SaveFirebaseTokenError  = InputValidationError\n\nunion SaveFirebaseTokenResult  = SaveFirebaseTokenErrors | SaveFirebaseTokenSuccess\n\nunion SignFileError  = FileAccessDenied | FileFormatNotSupported | FileVersionDoesNotExists | InputValidationError\n\nunion SignFileResult  = SignFileErrors | SignFileSuccess\n\nunion UnreadNotificationsError  = InputValidationError | NotificationDoesNotExists\n\nunion UnreadNotificationsResult  = UnreadNotificationsErrors | UnreadNotificationsSuccess\n\nunion UpdateArchiveTaskError  = InputValidationError | TaskAccessDenied | TaskDoesNotExist\n\nunion UpdateArchiveTaskResult  = UpdateArchiveTaskErrors | UpdateArchiveTaskSuccess\n\nunion UpdateAssignationsFilesError  = FileAccessDenied | FileDoesNotExists | InputValidationError\n\nunion UpdateAssignationsFilesFoldersError  = FileAccessDenied | FileDoesNotExists | FolderAccessDenied | FolderDoesNotExists | InputValidationError\n\nunion UpdateAssignationsFilesFoldersResult  = UpdateAssignationsFilesFoldersErrors | UpdateAssignationsFilesFoldersSuccess\n\nunion UpdateAssignationsFilesResult  = UpdateAssignationsFilesErrors | UpdateAssignationsFilesSuccess\n\nunion UpdateAssignationsFoldersError  = FolderAccessDenied | FolderDoesNotExists | InputValidationError\n\nunion UpdateAssignationsFoldersResult  = UpdateAssignationsFoldersErrors | UpdateAssignationsFoldersSuccess\n\nunion UpdateAssignationsTaskError  = InputValidationError | TaskAccessDenied | TaskAssignationsNotAllowed | TaskDoesNotExist\n\nunion UpdateAssignationsTaskResult  = UpdateAssignationTaskSuccess | UpdateAssignationsTaskErrors\n\nunion UpdateBrowserLanguageError  = InputValidationError\n\nunion UpdateBrowserLanguageResult  = UpdateBrowserLanguageErrors | UpdateBrowserLanguageSuccess\n\nunion UpdateBrowserTimezoneError  = InputValidationError\n\nunion UpdateBrowserTimezoneResult  = UpdateBrowserTimezoneErrors | UpdateBrowserTimezoneSuccess\n\nunion UpdateDueDateFileError  = FileAccessDenied | FileDoesNotExists | InputValidationError\n\nunion UpdateDueDateFileResult  = UpdateDueDateFileErrors | UpdateDueDateFileSuccess\n\nunion UpdateEmailNotificationsError  = InputValidationError\n\nunion UpdateEmailNotificationsResult  = UpdateEmailNotificationsErrors | UpdateEmailNotificationsSuccess\n\nunion UpdateFilesApprovalModeError  = CannotRemoveApprovalOnFile | FileAccessDenied | FileDoesNotExists | InputValidationError\n\nunion UpdateFilesApprovalModeResult  = UpdateFilesApprovalModeErrors | UpdateFilesApprovalModeSuccess\n\nunion UpdateLabelsFilesError  = FileAccessDenied | FileDoesNotExists | InputValidationError\n\nunion UpdateLabelsFilesResult  = UpdateLabelsFilesErrors | UpdateLabelsFilesSuccess\n\nunion UpdateLabelsFoldersError  = FolderAccessDenied | FolderDoesNotExists | InputValidationError\n\nunion UpdateLabelsFoldersResult  = UpdateLabelsFoldersErrors | UpdateLabelsFoldersSuccess\n\nunion UpdateLabelsTasksError  = InputValidationError | TaskAccessDenied | TaskDoesNotExist\n\nunion UpdateLabelsTasksResult  = UpdateLabelsTasksErrors | UpdateLabelsTasksSuccess\n\nunion UpdateOrgProfileError  = InputValidationError | OrgDoesNotExist | UpdateOrgProfilePermissionDenied\n\nunion UpdateOrgProfileResult  = UpdateOrgProfileErrors | UpdateOrgProfileSuccess\n\nunion UpdateOrgProjectSummaryError  = InputValidationError | OrgProjectSummaryDoesNotExist | ProjectAccessDenied | ProjectCategoryDoesNotExist | ProjectDoesNotExist | UpdateOrgProjectSummaryPermissionDenied\n\nunion UpdateOrgProjectSummaryResult  = UpdateOrgProjectSummaryErrors | UpdateOrgProjectSummarySuccess\n\nunion UpdatePermissionsFileError  = FileAccessDenied | FileDoesNotExists | InputValidationError | PermissionsConflictError\n\nunion UpdatePermissionsFileResult  = UpdatePermissionFileSuccess | UpdatePermissionsFileErrors\n\nunion UpdatePermissionsFolderError  = FolderAccessDenied | FolderDoesNotExists | InputValidationError | PermissionsConflictError\n\nunion UpdatePermissionsFolderResult  = UpdatePermissionFolderSuccess | UpdatePermissionsFolderErrors\n\nunion UpdateProjectArchiveError  = CannotArchiveOrgProject | InputValidationError | ProjectAccessDenied | ProjectDoesNotExist\n\nunion UpdateProjectArchiveResult  = UpdateProjectArchiveErrors | UpdateProjectArchiveSuccess\n\nunion UpdateProjectCategoryError  = InputValidationError | ProjectCategoryAccessDenied | ProjectCategoryDoesNotExist\n\nunion UpdateProjectCategoryResult  = UpdateProjectCategoryErrors | UpdateProjectCategorySuccess\n\nunion UpdateProjectLabelError  = InputValidationError | ProjectLabelAccessDenied | ProjectLabelDoesNotExist\n\nunion UpdateProjectLabelResult  = UpdateProjectLabelErrors | UpdateProjectLabelSuccess\n\nunion UpdateProjectMembersRoleError  = CannotModifyUserWithGreaterProjectRoleThanYours | CannotSetGreaterProjectRoleThanYours | InputValidationError | ProjectAccessDenied | ProjectDoesNotExist | ProjectNeedsAtLeastOneOwner | UserDoesNotExist\n\nunion UpdateProjectMembersRoleResult  = UpdateProjectMembersRoleErrors | UpdateProjectMembersRoleSuccess\n\nunion UpdateProjectProfileError  = InputValidationError | ProjectDoesNotExist | UpdateProjectProfilePermissionDenied\n\nunion UpdateProjectProfileResult  = UpdateProjectProfileErrors | UpdateProjectProfileSuccess\n\nunion UpdateProjectRoleError  = CannotModifyUserWithGreaterProjectRoleThanYours | CannotSetGreaterProjectRoleThanYours | InputValidationError | ProjectAccessDenied | ProjectDoesNotExist | ProjectNeedsAtLeastOneOwner | UserDoesNotExist\n\nunion UpdateProjectRoleResult  = UpdateProjectRoleErrors | UpdateProjectRoleSuccess\n\nunion UpdateProjectUserInfosError  = CannotModifyEmailOfActiveUser | CannotSetGreaterProjectRoleThanYours | EmailAlreadyUsedByAnotherUser | InputValidationError | ProjectAccessDenied | ProjectDoesNotExist | ProjectNeedsAtLeastOneOwner | TeamAccessDenied | TeamDoesNotExist | UpdateProjectUserInfosPermissionDenied | UserDoesNotExist\n\nunion UpdateProjectUserInfosResult  = UpdateProjectUserInfosErrors | UpdateProjectUserInfosSuccess\n\nunion UpdateProjectsCategoriesError  = InputValidationError | OrgDoesNotExist | OrgProjectSummaryDoesNotExist | ProjectAccessDenied | ProjectCategoryDoesNotExist | ProjectDoesNotExist | UpdateOrgProjectSummaryPermissionDenied\n\nunion UpdateProjectsCategoriesResult  = UpdateProjectsCategoriesErrors | UpdateProjectsCategoriesSuccess\n\nunion UpdateProjectsClientError  = InputValidationError | OrgDoesNotExist | OrgProjectSummaryDoesNotExist | ProjectAccessDenied | ProjectDoesNotExist | UpdateOrgProjectSummaryPermissionDenied\n\nunion UpdateProjectsClientResult  = UpdateProjectsClientErrors | UpdateProjectsClientSuccess\n\nunion UpdatePushNotificationsError  = InputValidationError | UserDoesNotExist\n\nunion UpdatePushNotificationsResult  = UpdatePushNotificationsErrors | UpdatePushNotificationsSuccess\n\nunion UpdateSubtaskError  = InputValidationError | SubtaskAccessDenied | SubtaskDoesNotExist\n\nunion UpdateSubtaskResult  = UpdateSubtaskErrors | UpdateSubtaskSuccess\n\nunion UpdateTaskError  = InputValidationError | ProjectDoesNotExist | TaskAssignationsNotAllowed | TaskDoesNotExist | UpdateTaskPermissionDenied\n\nunion UpdateTaskResult  = UpdateTaskErrors | UpdateTaskSuccess\n\nunion UpdateTasksAssignationsError  = InputValidationError | TaskAccessDenied | TaskAssignationsNotAllowed | TaskDoesNotExist\n\nunion UpdateTasksAssignationsResult  = UpdateTasksAssignationsErrors | UpdateTasksAssignationsSuccess\n\nunion UpdateTasksDatesError  = InputValidationError | TaskAccessDenied | TaskDoesNotExist\n\nunion UpdateTasksDatesResult  = UpdateTasksDatesErrors | UpdateTasksDatesSuccess\n\nunion UpdateTeamError  = InputValidationError | TeamAccessDenied | TeamDoesNotExist | TeamNameAlreadyExist\n\nunion UpdateTeamResult  = UpdateTeamErrors | UpdateTeamSuccess\n\nunion UpdateUserAppMetadataError  = InputValidationError\n\nunion UpdateUserAppMetadataResult  = UpdateUserAppMetadataErrors | UpdateUserAppMetadataSuccess\n\nunion UpdateUserProfileError  = InputValidationError | UserDoesNotExist\n\nunion UpdateUserProfileResult  = UpdateUserProfileErrors | UpdateUserProfileSuccess\n\nunion UpdateUserTeamsError  = InputValidationError | ProjectAccessDenied | ProjectDoesNotExist | TeamAccessDenied | TeamDoesNotExist | UserDoesNotExist\n\nunion UpdateUserTeamsResult  = UpdateUserTeamsErrors | UpdateUserTeamsSuccess\n\nunion UpdateUsersCompanyNameError  = InputValidationError | ProjectAccessDenied | ProjectDoesNotExist | UserDoesNotExist\n\nunion UpdateUsersCompanyNameResult  = UpdateUsersCompanyNameErrors | UpdateUsersCompanyNameSuccess\n\nunion UpdateUsersInTeamError  = InputValidationError | TeamAccessDenied | TeamDoesNotExist\n\nunion UpdateUsersInTeamResult  = UpdateUsersInTeamErrors | UpdateUsersInTeamSuccess\n\nunion UpdateUsersTeamsError  = InputValidationError | ProjectAccessDenied | ProjectDoesNotExist | TeamAccessDenied | TeamDoesNotExist | UserDoesNotExist\n\nunion UpdateUsersTeamsResult  = UpdateUsersTeamsErrors | UpdateUsersTeamsSuccess\n\nunion UpdateValidationTaskError  = InputValidationError | TaskAccessDenied | TaskDoesNotExist\n\nunion UpdateValidationTaskResult  = UpdateValidationTaskErrors | UpdateValidationTaskSuccess\n\nunion UpdateValidationsTasksError  = InputValidationError | TaskAccessDenied | TaskDoesNotExist\n\nunion UpdateValidationsTasksResult  = UpdateValidationsTasksErrors | UpdateValidationsTasksSuccess\n\ninput AddMembersToProjectChannelInput {channelId: String!\n  members: [String!]!\n}\n\ninput AddUserApprovalToFileVersionInput {comment: String\n  file_version_id: uuid!\n  status: String!\n}\n\ninput AddUserInTeamInput {teamId: uuid!\n  userId: uuid!\n}\n\ninput AddUserViewToFileVersionInput {file_version_id: uuid!\n}\n\ninput AddUserViewToFolderInput {folder_id: uuid!\n}\n\ninput AddUserViewToProjectInput {project_id: uuid!\n}\n\ninput AddUserViewToTaskInput {task_id: uuid!\n}\n\ninput AnnotateFileInput {file_version_id: uuid!\n  xfdf: String\n}\n\ninput CopyProjectInput {isDemoProject: Boolean\n  name: String\n  options: optionsInput!\n  projectId: uuid!\n}\n\ninput CreateAssignationsTask {orgs: [uuid!]!\n  teams: [uuid!]!\n  users: [uuid!]!\n}\n\ninput CreateChannelForProjectInput {members: [String!]\n  name: String!\n  projectId: uuid!\n  visibility: String!\n}\n\ninput CreateChannelForTaskInput {taskId: uuid!\n}\n\ninput CreateEmptyFileInput {folderId: uuid!\n  name: String!\n}\n\ninput CreateFolderInput {name: String!\n  parentId: uuid!\n}\n\ninput CreateOrgInput {description: String\n  legal_number: String\n  name: String!\n  phone: String\n}\n\ninput CreateOrgProjectSummaryInput {categories: [uuid]\n  client_email: String\n  client_fullname: String\n  client_phone_number: String\n  end_date: timestamptz\n  orgId: uuid!\n  price_estimate: String\n  projectId: uuid!\n  reference: String\n  start_date: timestamptz\n}\n\ninput CreateProjectCategoryInput {color: String!\n  name: String!\n  orgId: uuid!\n}\n\ninput CreateProjectDirectMessageInput {members: [String!]!\n  projectId: uuid!\n}\n\ninput CreateProjectInput {description: String\n  name: String!\n}\n\ninput CreateProjectLabelInput {color: String!\n  name: String!\n  projectId: uuid!\n}\n\ninput CreateSubtaskInput {closed: Boolean!\n  description: String!\n  endDate: timestamptz\n  startDate: timestamptz\n  taskId: uuid!\n}\n\ninput CreateTaskFileVersions {file_version_id: uuid!\n  location: CreateTaskFileVersionsLocation\n}\n\ninput CreateTaskFileVersionsLocation {page_number: Int!\n  x: Float!\n  y: Float!\n  z: Float\n}\n\ninput CreateTaskInput {assignations: CreateAssignationsTask\n  description: String!\n  end_date: timestamptz\n  file_versions: [CreateTaskFileVersions]\n  label_ids: [uuid!]\n  location: CreateTaskLocation\n  project_id: uuid!\n  start_date: timestamptz\n  subtasks: [CreateTaskSubtasks!]\n}\n\ninput CreateTaskLocation {lat: Float!\n  lng: Float!\n}\n\ninput CreateTaskSubtasks {closed: Boolean!\n  description: String!\n}\n\ninput CreateTeamInput {color: String!\n  name: String!\n  projectId: uuid!\n}\n\ninput DeleteFileInput {fileId: uuid!\n}\n\ninput DeleteFirebaseTokenInput {token: String!\n}\n\ninput DeleteFolderInput {folderId: uuid!\n}\n\ninput DeleteProjectCategoryInput {projectCategoryId: uuid!\n}\n\ninput DeleteProjectInput {projectId: uuid!\n}\n\ninput DeleteProjectLabelInput {projectLabelId: uuid!\n}\n\ninput DeleteSubtaskInput {subtaskId: uuid!\n}\n\ninput DeleteTaskAttachmentInput {taskAttachmentId: uuid!\n}\n\ninput DeleteTaskInput {id: uuid!\n}\n\ninput DeleteTeamInput {teamId: uuid!\n}\n\ninput DownloadFolderInput {folderId: uuid!\n}\n\ninput DuplicateFilesInput {fileIds: [uuid!]!\n}\n\ninput FinalizeUploadedChannelAssetInput {key: uuid!\n}\n\ninput FinalizeUploadedFileInput {key: uuid!\n}\n\ninput FinalizeUploadedFileStructureInput {key: uuid!\n}\n\ninput FinalizeUploadedFileVersionInput {key: uuid!\n}\n\ninput FinalizeUploadedOrgAvatarInput {key: uuid!\n}\n\ninput FinalizeUploadedOrgBackgroundInput {key: uuid!\n}\n\ninput FinalizeUploadedProjectAvatarInput {key: uuid!\n}\n\ninput FinalizeUploadedProjectBackgroundInput {key: uuid!\n}\n\ninput FinalizeUploadedProjectBannerInput {key: uuid!\n}\n\ninput FinalizeUploadedProjectSpreadsheetInput {key: uuid!\n}\n\ninput FinalizeUploadedTaskAttachmentAnnotationInput {key: uuid!\n}\n\ninput FinalizeUploadedTaskAttachmentInput {key: uuid!\n}\n\ninput FinalizeUploadedTaskSpreadsheetInput {key: uuid!\n}\n\ninput FinalizeUploadedUserAvatarInput {key: uuid!\n}\n\ninput JoinOrgUserProjectInput {project_id: uuid!\n}\n\ninput MoveFilesInput {fileIds: [uuid!]!\n  newParentId: uuid!\n}\n\ninput MoveFoldersInput {folderIds: [uuid!]!\n  newParentId: uuid!\n}\n\ninput OrgProfileAddress {city: String\n  country: String\n  lat: Float\n  lng: Float\n  postal_code: String\n  street: String\n}\n\ninput PrepareChannelAssetForUploadInput {channelId: String!\n  name: String!\n}\n\ninput PrepareFileForUploadInput {name: String!\n  parentId: uuid!\n}\n\ninput PrepareFileStructureForUploadInput {parentId: uuid!\n}\n\ninput PrepareFileVersionAnnotationForUploadInput {fileVersionId: uuid!\n}\n\ninput PrepareFileVersionForUploadInput {fileId: uuid!\n  name: String!\n}\n\ninput PrepareOrgAssetForUploadInput {name: String!\n  orgId: uuid!\n}\n\ninput PrepareProjectAssetForUploadInput {name: String!\n  projectId: uuid!\n}\n\ninput PrepareProjectSpreadsheetForUploadInput {orgId: uuid!\n}\n\ninput PrepareProjectUserAvatarForUploadInput {name: String!\n  project_id: uuid!\n  user_id: uuid!\n}\n\ninput PrepareTaskAttachmentAnnotationForUploadInput {taskAttachmentId: uuid!\n}\n\ninput PrepareTaskAttachmentForUploadInput {name: String!\n  taskId: uuid!\n}\n\ninput PrepareTaskSpreadsheetForUploadInput {projectId: uuid!\n}\n\ninput PrepareUserAvatarForUploadInput {name: String!\n}\n\ninput ProjectInvitationsInput {project_ids: [uuid!]!\n  users: [usersProjectInvitation!]!\n}\n\ninput ProjectProfileAddress {city: String\n  country: String\n  lat: Float\n  lng: Float\n  postal_code: String\n  street: String\n}\n\ninput ReadNotificationsInput {notificationIds: [uuid!]!\n}\n\ninput RemoveMembersFromProjectChannelInput {channelId: String!\n  members: [String!]!\n}\n\ninput RemoveUserInTeamInput {teamId: uuid!\n  userId: uuid!\n}\n\ninput RenameChannelForProjectInput {channelId: String!\n  name: String!\n}\n\ninput RenameFileInput {fileId: uuid!\n  name: String!\n}\n\ninput RenameFolderInput {folderId: uuid!\n  name: String!\n}\n\ninput RequestApprovalExportInput {broadcast: broadcastApprovalExport\n  fileIds: [uuid!]\n  folderIds: [uuid!]\n  format: String!\n  options: optionsApprovalExport\n  projectId: uuid!\n  title: String!\n}\n\ninput RequestApprovalReportInput {broadcast: broadcastApprovalReport\n  content: contentApprovalReport\n  fileIds: [uuid!]\n  folderIds: [uuid!]\n  format: String!\n  options: optionsApprovalReport\n  projectId: uuid!\n  title: String!\n}\n\ninput RequestProjectExportInput {projectId: uuid!\n}\n\ninput RequestTasksExportInput {broadcast: broadcastTasksExport\n  format: String!\n  projectId: uuid!\n  taskIds: [uuid!]!\n  title: String!\n}\n\ninput RequestTasksReportInput {broadcast: broadcastTasksReport\n  format: String!\n  introduction: String\n  options: optionsTasksReport\n  organization: organizationTasksReport\n  presentUsers: [presentUsersTasksReport]\n  projectId: uuid!\n  taskIds: [uuid!]!\n  title: String!\n}\n\ninput RequestUsersApprovalsFilesInput {dueDate: timestamptz\n  fileIds: [uuid!]!\n  users: [uuid!]!\n}\n\ninput RestoreFileVersionInput {fileVersionId: uuid!\n}\n\ninput SaveFirebaseTokenInput {appVersion: String!\n  manufacturer: String!\n  model: String!\n  operatingSystem: String!\n  osVersion: String!\n  platform: String!\n  token: String!\n  webViewVersion: String!\n}\n\ninput SignFileInput {file_version_id: uuid!\n  signature: SignFileSignatureInput\n}\n\ninput SignFileSignatureCoordinatesInput {page_number: Int!\n  x1: Float!\n  x2: Float!\n  y1: Float!\n  y2: Float!\n}\n\ninput SignFileSignatureInput {coordinates: SignFileSignatureCoordinatesInput\n  image: String!\n}\n\ninput UnreadNotificationsInput {notificationIds: [uuid!]!\n}\n\ninput UpdateArchiveTaskInput {taskId: uuid!\n}\n\ninput UpdateAssignationsFilesFoldersInput {fileIds: [uuid!]!\n  folderIds: [uuid!]!\n  orgs: [uuid!]!\n  teams: [uuid!]!\n  users: [uuid!]!\n}\n\ninput UpdateAssignationsFilesInput {fileIds: [uuid!]!\n  orgs: [uuid!]!\n  teams: [uuid!]!\n  users: [uuid!]!\n}\n\ninput UpdateAssignationsFoldersInput {folderIds: [uuid!]!\n  orgs: [uuid!]!\n  teams: [uuid!]!\n  users: [uuid!]!\n}\n\ninput UpdateAssignationsTaskInput {orgs: [uuid]!\n  taskId: uuid!\n  teams: [uuid]!\n  users: [uuid]!\n}\n\ninput UpdateBrowserLanguageInput {browser_language: String!\n}\n\ninput UpdateBrowserTimezoneInput {timezone: String!\n}\n\ninput UpdateDueDateFileInput {dueDate: timestamptz\n  fileId: uuid!\n}\n\ninput UpdateEmailNotificationsInput {invitation: Boolean\n  unread_notification_report: Boolean\n  weekly_report: Boolean\n}\n\ninput UpdateFilesApprovalModeInput {fileIds: [uuid!]!\n  isApprovalMode: Boolean!\n}\n\ninput UpdateLabelsFilesInput {fileIds: [uuid!]!\n  labelIds: [uuid!]!\n}\n\ninput UpdateLabelsFoldersInput {folderIds: [uuid!]!\n  labelIds: [uuid!]!\n}\n\ninput UpdateLabelsTasksInput {labelIds: [uuid!]!\n  taskIds: [uuid!]!\n}\n\ninput UpdateOrgProfileInput {address: OrgProfileAddress\n  description: String\n  id: ID!\n  legal_number: String\n  name: String\n  phone: String\n}\n\ninput UpdateOrgProjectSummaryInput {categories: [uuid]\n  client_email: String\n  client_fullname: String\n  client_phone_number: String\n  end_date: timestamptz\n  id: uuid!\n  price_estimate: String\n  reference: String\n  start_date: timestamptz\n}\n\ninput UpdatePermissionsFileInput {fileId: uuid!\n  orgs: [filePermission!]!\n  teams: [filePermission!]!\n  users: [filePermission!]!\n}\n\ninput UpdatePermissionsFolderInput {folderId: uuid!\n  orgs: [folderPermission!]!\n  teams: [folderPermission!]!\n  users: [folderPermission!]!\n}\n\ninput UpdateProjectArchiveInput {isArchived: Boolean!\n  projectId: uuid!\n}\n\ninput UpdateProjectCategoryInput {color: String\n  name: String\n  projectCategoryId: uuid!\n}\n\ninput UpdateProjectLabelInput {color: String\n  name: String\n  projectLabelId: uuid\n}\n\ninput UpdateProjectMembersRoleInput {projectId: uuid!\n  role: String!\n  userIds: [uuid]!\n}\n\ninput UpdateProjectProfileInput {address: ProjectProfileAddress\n  description: String\n  id: ID!\n  is_archived: Boolean\n  name: String!\n}\n\ninput UpdateProjectRoleInput {projectId: uuid!\n  role: String!\n  userId: uuid!\n}\n\ninput UpdateProjectUserInfosInput {companyData: usersCompanyData\n  email: String!\n  first_name: String\n  last_name: String\n  phone: String\n  projectId: uuid!\n  role: String!\n  teamIds: [uuid]!\n  userId: uuid!\n}\n\ninput UpdateProjectsCategoriesInput {categories: [uuid!]\n  orgId: uuid!\n  projects: [UpdateProjectsCategoriesProjects]\n}\n\ninput UpdateProjectsCategoriesProjects {orgProjectSummaryId: uuid\n  projectId: uuid!\n}\n\ninput UpdateProjectsClientInput {client_email: String\n  client_fullname: String!\n  client_phone_number: String\n  orgId: uuid!\n  projects: [UpdateProjectsClientProjects]\n}\n\ninput UpdateProjectsClientProjects {orgProjectSummaryId: uuid\n  projectId: uuid!\n}\n\ninput UpdatePushNotificationsInput {chat_channel: Boolean\n  chat_direct_message: Boolean\n}\n\ninput UpdateSubtaskInput {closed: Boolean\n  description: String\n  endDate: timestamptz\n  startDate: timestamptz\n  subtaskId: uuid!\n}\n\ninput UpdateTaskAssignations {orgs: [uuid!]!\n  teams: [uuid!]!\n  users: [uuid!]!\n}\n\ninput UpdateTaskFileVersions {file_version_id: uuid!\n  location: UpdateTaskFileVersionsLocation\n}\n\ninput UpdateTaskFileVersionsLocation {page_number: Int!\n  x: Float!\n  y: Float!\n  z: Float\n}\n\ninput UpdateTaskInput {assignations: UpdateTaskAssignations\n  description: String\n  end_date: timestamptz\n  file_versions: [UpdateTaskFileVersions]\n  id: uuid!\n  label_ids: [uuid!]\n  location: UpdateTaskLocation\n  start_date: timestamptz\n}\n\ninput UpdateTaskLocation {lat: Float!\n  lng: Float!\n}\n\ninput UpdateTasksAssignationsInput {orgs: [uuid]!\n  taskIds: [uuid!]!\n  teams: [uuid]!\n  users: [uuid]!\n}\n\ninput UpdateTasksDatesInput {end_date: timestamptz\n  start_date: timestamptz\n  taskIds: [uuid!]!\n}\n\ninput UpdateTeamInput {color: String\n  name: String\n  teamId: uuid!\n}\n\ninput UpdateUserAppMetadataInput {app_desktop_installed: Boolean\n  app_mobile_installed: Boolean\n}\n\ninput UpdateUserProfileInput {country_code: String!\n  first_name: String!\n  language: String!\n  last_name: String!\n  phone: String\n}\n\ninput UpdateUserTeamsInput {projectId: uuid!\n  teamIds: [uuid]!\n  userId: uuid!\n}\n\ninput UpdateUsersCompanyNameInput {companyData: usersCompanyData\n  projectId: uuid!\n  userIds: [uuid]!\n}\n\ninput UpdateUsersInTeamInput {teamId: uuid!\n  userIds: [uuid]!\n}\n\ninput UpdateUsersTeamsInput {projectId: uuid!\n  teamIds: [uuid]!\n  userIds: [uuid]!\n}\n\ninput UpdateValidationTaskInput {orgScope: Boolean\n  taskId: uuid!\n}\n\ninput UpdateValidationsTasksInput {taskIds: [uuid!]!\n  validate: Boolean!\n}\n\ninput broadcastApprovalExport {document: Boolean\n  email: Boolean\n}\n\ninput broadcastApprovalReport {document: Boolean\n  email: Boolean\n}\n\ninput broadcastTasksExport {document: Boolean\n  email: Boolean\n}\n\ninput broadcastTasksReport {document: Boolean\n  email: Boolean\n}\n\ninput contentApprovalReport {footer: String\n  title: String\n}\n\ninput filePermission {access: String!\n  id: uuid!\n}\n\ninput folderPermission {access: String!\n  id: uuid!\n}\n\ninput optionsApprovalExport {allVersions: Boolean\n  excludeSubfolders: Boolean\n}\n\ninput optionsApprovalReport {allVersions: Boolean\n  excludeSubfolders: Boolean\n}\n\ninput optionsInput {labels: Boolean\n  members: Boolean\n  publicDocuments: Boolean\n  restrictedDocuments: Boolean\n  tasks: Boolean\n  tasksComments: Boolean\n  teams: Boolean\n}\n\ninput optionsTasksReport {taskAssignees: Boolean\n  taskComments: Boolean\n  taskFiles: Boolean\n  taskImages: Boolean\n  taskSubtasks: Boolean\n  taskViews: Boolean\n}\n\ninput organizationTasksReport {org: Boolean\n  orgIds: [uuid]\n  tag: Boolean\n  tagIds: [uuid]\n  team: Boolean\n  teamIds: [uuid]\n  user: Boolean\n  userIds: [uuid]\n}\n\ninput presentUsersTasksReport {status: String\n  userId: uuid\n}\n\ninput usersCompanyData {city: String\n  country_code: String\n  creation_date: String\n  lat: Float\n  legal_number: String\n  lng: Float\n  name: String\n  postal_code: String\n  size_max: Int\n  size_min: Int\n  standard_industrial_classification: String\n}\n\ninput usersProjectInvitation {company_data: usersCompanyData\n  email: String!\n  firstName: String\n  lastName: String\n  phone: String\n  role: String\n  team_ids: [uuid!]\n}"},"role":"user"}]}],"version":3,"query_collections":[{"definition":{"queries":[]},"name":"allowed-queries"}]}', 3);


--
-- TOC entry 5208 (class 0 OID 261037)
-- Dependencies: 236
-- Data for Name: hdb_scheduled_event_invocation_logs; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--



--
-- TOC entry 5209 (class 0 OID 261044)
-- Dependencies: 237
-- Data for Name: hdb_scheduled_events; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--



--
-- TOC entry 5210 (class 0 OID 261054)
-- Dependencies: 238
-- Data for Name: hdb_schema_notifications; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

INSERT INTO hdb_catalog.hdb_schema_notifications VALUES (1, '{"metadata":true,"remote_schemas":["Apollo"],"sources":["default"]}', 3, '26de5d51-484f-4171-9aaa-4965898a83a7', '2023-03-05 21:06:24.101916+00');


--
-- TOC entry 5211 (class 0 OID 261062)
-- Dependencies: 239
-- Data for Name: hdb_source_catalog_version; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

INSERT INTO hdb_catalog.hdb_source_catalog_version VALUES ('2', '2023-03-05 21:06:24.025768+00');


--
-- TOC entry 5212 (class 0 OID 261067)
-- Dependencies: 240
-- Data for Name: hdb_version; Type: TABLE DATA; Schema: hdb_catalog; Owner: postgres
--

INSERT INTO hdb_catalog.hdb_version VALUES ('d44b7492-660c-4b68-a481-e8272d7d83e9', '47', '2023-03-05 21:06:16.661387+00', '{"settings": {"migration_mode": "true"}, "migrations": {"default": {"1618405790335": false, "1618405790339": false, "1619007472050": false, "1619008561681": false, "1619008561689": false, "1619008561690": false, "1619008561692": false, "1619008561697": false, "1619008561789": false, "1619008561790": false, "1619008561792": false, "1619105454402": false, "1619105454408": false, "1619105454409": false, "1619105454410": false, "1619105588930": false, "1619105588959": false, "1619105898089": false, "1619600292581": false, "1619600292582": false, "1619600292583": false, "1623156778214": false, "1624441536116": false, "1624441536117": false, "1624441536118": false, "1624450256341": false, "1624450666222": false, "1624450983857": false, "1624458186215": false, "1624465461838": false, "1624465898084": false, "1624466232796": false, "1624466701038": false, "1624473697381": false, "1624473782284": false, "1624474192137": false, "1624474192138": false, "1624474487676": false, "1624474787882": false, "1624899981912": false, "1624900388169": false, "1624900388170": false, "1624901208355": false, "1624901846715": false, "1624902128028": false, "1624903107734": false, "1624903328760": false, "1624903555182": false, "1624903843131": false, "1624904830663": false, "1624904830664": false, "1624905445625": false, "1624905779466": false, "1624906407778": false, "1624906533275": false, "1624906754770": false, "1624906754771": false, "1624906754772": false, "1625314262027": false, "1625474270344": false, "1626264433557": false, "1627394435081": false, "1627394980938": false, "1627394980939": false, "1627548690007": false, "1627548690008": false, "1627568389850": false, "1629303077916": false, "1629303077923": false, "1629303077924": false, "1629303077925": false, "1629303077930": false, "1629303077931": false, "1629303077941": false, "1629303077950": false, "1629303077951": false, "1629892516049": false, "1629892622230": false, "1629892724781": false, "1629892724783": false, "1630590151248": false, "1630682220683": false, "1630682220685": false, "1630690142464": false, "1631010298575": false, "1631010298576": false, "1632146270330": false, "1632146270331": false, "1632483870901": false, "1632818440346": false, "1634717597072": false, "1634717597073": false, "1634717597074": false, "1634717597075": false, "1634717597076": false, "1634717597077": false, "1634717597078": false, "1634717597079": false, "1635504640315": false, "1635860132580": false, "1635860132581": false, "1637657911007": false, "1637658363981": false, "1637658363983": false, "1637658363991": false, "1637658363993": false, "1637658363999": false, "1637658364000": false, "1637658364001": false, "1644578321557": false, "1644578321558": false, "1647252474946": false, "1647252474947": false, "1647275729654": false, "1647349185000": false, "1647349185001": false, "1648050262084": false, "1649074016307": false, "1649319822006": false, "1649421895115": false, "1649421895180": false, "1649421895190": false, "1649421895299": false, "1650442128631": false, "1650527872138": false, "1651049474948": false, "1651049474950": false, "1652199500477": false, "1652264729503": false, "1652266689454": false, "1652266786365": false, "1652358314243": false, "1652358314245": false, "1652358314500": false, "1652358314510": false, "1652358314520": false, "1652358314530": false, "1653048661252": false, "1653048661260": false, "1653048661270": false, "1653048661280": false, "1654004863000": false, "1654175470000": false, "1654175470020": false, "1654175470040": false, "1654175470060": false, "1654264420652": false, "1654704817109": false, "1655197954191": false, "1655226656433": false, "1655226656533": false, "1655226656733": false, "1655226656933": false, "1655226657000": false, "1656597973657": false, "1656597974657": false, "1657615926427": false, "1657615926430": false, "1657615926500": false, "1657615926600": false, "1657615926700": false, "1657615926800": false, "1657615926900": false, "1657615926990": false, "1657615927000": false, "1657615927100": false, "1661387721362": false, "1661418042771": false, "1661421101656": false, "1661661752480": false, "1661849754778": false, "1662044560230": false, "1662129199486": false, "1664412989476": false, "1664414291317": false, "1664414637469": false, "1664415442908": false, "1664416735796": false, "1664417233891": false, "1664417517444": false, "1664462519641": false, "1664901256503": false, "1665094619986": false, "1665094619989": false, "1665998373649": false, "1666261235771": false, "1666789484952": false, "1667402231706": false, "1668017741546": false, "1668519170272": false, "1668770794530": false, "1669370843466": false, "1670244257307": false, "1671030925223": false}}, "isStateCopyCompleted": true}', '{"console_notifications": {"admin": {"date": null, "read": [], "showBadge": true}}, "telemetryNotificationShown": true}');


--
-- TOC entry 5213 (class 0 OID 261075)
-- Dependencies: 241
-- Data for Name: email_notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.email_notifications VALUES ('b4dc10f2-19c9-4d6a-a8e4-8624e91a33f6', true, true, true, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.email_notifications VALUES ('b4dc10f2-19c9-4d6a-a8e4-8624e91a33f7', true, true, false, '86c8c162-3405-457c-9724-727aea142580');
INSERT INTO public.email_notifications VALUES ('b4dc10f2-19c9-4d6a-a8e4-8624e91a33f8', true, false, true, 'a76a395c-7f16-45d0-b748-8f726134e492');
INSERT INTO public.email_notifications VALUES ('b4dc10f2-19c9-4d6a-a8e4-8624e91a33f9', false, true, true, 'b03640d8-a9b9-46d9-8df3-8b0ba204540f');
INSERT INTO public.email_notifications VALUES ('b4dc10f2-19c9-4d6a-a8e4-8624e91a33f5', false, false, false, '2c301925-1afd-461b-a5c2-d7930596845d');
INSERT INTO public.email_notifications VALUES ('b4dc10f2-19c9-4d6a-a8e4-8624e91a33f4', true, true, true, '033af847-bded-487c-9228-5f7c5af19ac6');
INSERT INTO public.email_notifications VALUES ('debd2fb2-c61d-4e6d-9f31-5f06e6e8641a', true, true, true, '6272c659-9cc9-4125-a91d-b32046e23101');
INSERT INTO public.email_notifications VALUES ('319e217c-cd84-4cec-b8cd-4c634a7005e1', false, true, false, 'a7e70da0-bb65-4e30-b6f5-a86f983a109e');
INSERT INTO public.email_notifications VALUES ('44128b0d-e0f0-4efc-ac9c-1dafd382ab6f', false, false, false, 'a7e70da0-bb65-4e30-b6f5-a86f983a2357');
INSERT INTO public.email_notifications VALUES ('3f9a3a4a-f9c1-4b7e-9591-abe2994a6a3d', false, false, false, 'a7e70da0-bb65-4e30-b6f5-a86f983a2358');
INSERT INTO public.email_notifications VALUES ('8ddb1af1-55f5-4ceb-a0f6-6149145c2eb2', false, false, false, 'a7e70da0-bb65-4e30-b6f5-a86f983a2359');


--
-- TOC entry 5214 (class 0 OID 261082)
-- Dependencies: 242
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.events VALUES ('6a812687-2519-4a0e-aae4-af466dcd8d7d', '2021-06-23 13:56:48.342234+01', '2021-06-23 13:56:48.342234+01', 'PROJECT_CREATED', 'b091eda9-e766-46b5-914f-d34940d2267e', '{"id": "7b450b00-c9b5-4332-b087-46af26e8a525"}');
INSERT INTO public.events VALUES ('69f1c341-e83f-4bdb-9714-5a7156c8f269', '2021-08-23 14:21:49.560772+01', '2021-08-23 14:21:49.560772+01', 'USER_INVITED_TO_ORG', 'b091eda9-e766-46b5-914f-d34940d2267e', '{"orgId": "fc9df192-6313-4347-9317-8ee7b37952ba", "userId": "a7e70da0-bb65-4e30-b6f5-a86f983a139e"}');
INSERT INTO public.events VALUES ('da33b272-b51e-4490-b75c-c3722ba8edb4', '2021-10-26 09:40:49.420352+01', '2021-10-26 09:40:49.420352+01', 'TASK_UPDATED', '86c8c162-3405-457c-9724-727aea142580', '{"newTask": {"id": "357fb463-97aa-40b9-8ef3-f8ec1dc88f88", "number": 1, "end_date": "2045-06-22T00:00:00.000Z", "created_at": "2021-06-22T12:02:09.467Z", "creator_id": "b091eda9-e766-46b5-914f-d34940d2267e", "deleted_at": null, "project_id": "7b450b00-c9b5-4332-b087-46af26e8a525", "start_date": "2021-06-22T00:00:00.000Z", "updated_at": "2021-10-26T08:31:35.262Z", "description": "build  wall (Link to Tour Eiffel project)"}, "oldTask": {"id": "357fb463-97aa-40b9-8ef3-f8ec1dc88f88", "number": 1, "end_date": "2045-06-22T00:00:00.000Z", "created_at": "2021-06-22T12:02:09.467Z", "creator_id": "b091eda9-e766-46b5-914f-d34940d2267e", "deleted_at": null, "project_id": "7b450b00-c9b5-4332-b087-46af26e8a525", "start_date": "2021-06-22T00:00:00.000Z", "updated_at": "2021-12-24T08:31:13.661Z", "description": "build a wall (Link to Tour Eiffel project)"}}');


--
-- TOC entry 5215 (class 0 OID 261090)
-- Dependencies: 243
-- Data for Name: events_workers_status; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5216 (class 0 OID 261098)
-- Dependencies: 244
-- Data for Name: file_access_enum; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_access_enum VALUES ('write', 'All access');
INSERT INTO public.file_access_enum VALUES ('read', 'Read only');


--
-- TOC entry 5198 (class 0 OID 260891)
-- Dependencies: 226
-- Data for Name: file_approvals; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_approvals VALUES ('496e3080-51e1-4db5-9789-15bd870c7b1e', '2021-06-28 20:02:43.586764+01', '2021-06-28 20:02:43.586764+01', '3527410b-2c83-4f78-a4c5-2ed92484004b', 'APPROVED_WITHOUT_COMMENTS', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.file_approvals VALUES ('496e3080-51e1-4db5-9789-15bd870c7b3f', '2021-06-28 20:02:43.586764+01', '2021-06-28 20:02:43.586764+01', '3527410b-2c83-4f78-a4c5-2ed924810024', 'APPROVED_WITHOUT_COMMENTS', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.file_approvals VALUES ('766768e1-536a-4306-b6fc-96685e1fbe11', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '33d70211-d4bd-4709-8985-e345e292fb28', 'DENIED', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.file_approvals VALUES ('766768e1-536a-4306-b6fc-96685e1fbe12', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'ccfcf27f-99d0-4787-95f1-c7da8ba6425e', 'APPROVED_WITH_COMMENTS', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.file_approvals VALUES ('766768e1-536a-4306-b6fc-96685e1fbe13', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '7d1c3e06-9308-4fe6-86c5-3fdd8558638d', 'APPROVED_WITHOUT_COMMENTS', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.file_approvals VALUES ('766768e1-536a-4306-b6fc-96685e1fbe14', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd541193f-9748-4779-8e63-6e6bafe39c13', 'APPROVED_WITHOUT_COMMENTS', '86c8c162-3405-457c-9724-727aea142580');
INSERT INTO public.file_approvals VALUES ('766768e1-536a-4306-b6fc-96685e1fbe15', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '967aa6c7-cd19-4fda-8feb-2ca99c01c03b', 'NC', 'b091eda9-e766-46b5-914f-d34940d2267e');


--
-- TOC entry 5217 (class 0 OID 261103)
-- Dependencies: 245
-- Data for Name: file_approvals_status_enum; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_approvals_status_enum VALUES ('APPROVED_WITHOUT_COMMENTS', 'approved without observations');
INSERT INTO public.file_approvals_status_enum VALUES ('APPROVED_WITH_COMMENTS', 'approved with observations');
INSERT INTO public.file_approvals_status_enum VALUES ('DENIED', 'approval denied');
INSERT INTO public.file_approvals_status_enum VALUES ('NC', 'not concerned');


--
-- TOC entry 5218 (class 0 OID 261108)
-- Dependencies: 246
-- Data for Name: file_assignation_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5186 (class 0 OID 260749)
-- Dependencies: 213
-- Data for Name: file_assignations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_assignations VALUES ('bb93feff-e63c-4f98-8229-a4ced6d745a9', '2021-06-28 18:59:10.237448+01', '2021-06-28 18:59:10.237448+01', '24c2b0df-4b57-4f99-819a-cf2bca041564');
INSERT INTO public.file_assignations VALUES ('fe8a2f89-49ce-4d8a-88a4-4f283bb0cd2e', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'fda88eda-bc35-4bbd-bee7-ffd167ec7a05');
INSERT INTO public.file_assignations VALUES ('0b545e6b-4af8-48bb-819b-fd5ef72842af', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b9246647-4a52-45aa-852e-cd02eab3639c');
INSERT INTO public.file_assignations VALUES ('0c770fba-e7b1-451d-8af1-9f59bf6c85f2', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'af35fc46-fa72-491f-9dc9-0783a7e300df');


--
-- TOC entry 5219 (class 0 OID 261114)
-- Dependencies: 247
-- Data for Name: file_assignations_orgs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_assignations_orgs VALUES ('2cac796b-ee22-472f-8a16-5de3778114cf', '2021-06-28 19:07:22.816569+01', '2021-06-28 19:07:22.816569+01', 'bb93feff-e63c-4f98-8229-a4ced6d745a9', 'fc9df192-6313-4347-9317-8ee7b37952ba', NULL);


--
-- TOC entry 5220 (class 0 OID 261120)
-- Dependencies: 248
-- Data for Name: file_assignations_teams; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_assignations_teams VALUES ('6019848e-2cf3-404f-a3fd-d1478f7bcd9c', '2021-06-28 19:12:19.55762+01', '2021-06-28 19:12:19.55762+01', 'bb93feff-e63c-4f98-8229-a4ced6d745a9', '7f90ec6b-0cb2-413a-8157-ffc80b1b693e', NULL);


--
-- TOC entry 5221 (class 0 OID 261126)
-- Dependencies: 249
-- Data for Name: file_assignations_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_assignations_users VALUES ('8c54ddda-1218-4458-9023-870e9620178c', '2021-06-28 19:03:44.794152+01', '2021-06-28 19:03:44.794152+01', 'bb93feff-e63c-4f98-8229-a4ced6d745a9', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL);
INSERT INTO public.file_assignations_users VALUES ('6bc53601-1099-485b-8d73-c43cb4ce0a49', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'fe8a2f89-49ce-4d8a-88a4-4f283bb0cd2e', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL);
INSERT INTO public.file_assignations_users VALUES ('e42abe14-749d-4893-8cbe-d11ff12b5581', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'fe8a2f89-49ce-4d8a-88a4-4f283bb0cd2e', '86c8c162-3405-457c-9724-727aea142580', NULL);
INSERT INTO public.file_assignations_users VALUES ('97b783d6-e343-4e23-b4fb-ed0962413904', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'fe8a2f89-49ce-4d8a-88a4-4f283bb0cd2e', '033af847-bded-487c-9228-5f7c5af19ac6', NULL);
INSERT INTO public.file_assignations_users VALUES ('190df711-a488-46f9-89b9-c3c2196e5808', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'fe8a2f89-49ce-4d8a-88a4-4f283bb0cd2e', '2c301925-1afd-461b-a5c2-d7930596845d', NULL);
INSERT INTO public.file_assignations_users VALUES ('c2d81208-c2bb-4c30-ba89-787275a8f44d', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'fe8a2f89-49ce-4d8a-88a4-4f283bb0cd2e', 'b03640d8-a9b9-46d9-8df3-8b0ba204540f', NULL);
INSERT INTO public.file_assignations_users VALUES ('d6a95bb3-bb81-4796-a265-f1de47afec91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'fe8a2f89-49ce-4d8a-88a4-4f283bb0cd2e', 'a76a395c-7f16-45d0-b748-8f726134e492', NULL);
INSERT INTO public.file_assignations_users VALUES ('2d570a56-e65b-40ac-ba6e-6c96a604fd40', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '0b545e6b-4af8-48bb-819b-fd5ef72842af', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL);
INSERT INTO public.file_assignations_users VALUES ('2d570a56-e65b-40ac-ba6e-6c96a604fd41', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '0b545e6b-4af8-48bb-819b-fd5ef72842af', '86c8c162-3405-457c-9724-727aea142580', NULL);
INSERT INTO public.file_assignations_users VALUES ('2d570a56-e65b-40ac-ba6e-6c96a604fd42', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '0b545e6b-4af8-48bb-819b-fd5ef72842af', '033af847-bded-487c-9228-5f7c5af19ac6', NULL);
INSERT INTO public.file_assignations_users VALUES ('2d570a56-e65b-40ac-ba6e-6c96a604fd43', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '0b545e6b-4af8-48bb-819b-fd5ef72842af', '2c301925-1afd-461b-a5c2-d7930596845d', NULL);
INSERT INTO public.file_assignations_users VALUES ('2d570a56-e65b-40ac-ba6e-6c96a604fd44', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '0b545e6b-4af8-48bb-819b-fd5ef72842af', 'b03640d8-a9b9-46d9-8df3-8b0ba204540f', NULL);
INSERT INTO public.file_assignations_users VALUES ('2d570a56-e65b-40ac-ba6e-6c96a604fd45', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '0b545e6b-4af8-48bb-819b-fd5ef72842af', 'a76a395c-7f16-45d0-b748-8f726134e492', NULL);
INSERT INTO public.file_assignations_users VALUES ('715bc9ef-c0a5-4b03-9416-ce77e2c0e703', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '0c770fba-e7b1-451d-8af1-9f59bf6c85f2', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL);
INSERT INTO public.file_assignations_users VALUES ('715bc9ef-c0a5-4b03-9416-ce77e2c0e704', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '0c770fba-e7b1-451d-8af1-9f59bf6c85f2', '86c8c162-3405-457c-9724-727aea142580', NULL);
INSERT INTO public.file_assignations_users VALUES ('715bc9ef-c0a5-4b03-9416-ce77e2c0e705', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '0c770fba-e7b1-451d-8af1-9f59bf6c85f2', '033af847-bded-487c-9228-5f7c5af19ac6', NULL);
INSERT INTO public.file_assignations_users VALUES ('715bc9ef-c0a5-4b03-9416-ce77e2c0e706', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '0c770fba-e7b1-451d-8af1-9f59bf6c85f2', '2c301925-1afd-461b-a5c2-d7930596845d', NULL);
INSERT INTO public.file_assignations_users VALUES ('715bc9ef-c0a5-4b03-9416-ce77e2c0e707', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '0c770fba-e7b1-451d-8af1-9f59bf6c85f2', 'b03640d8-a9b9-46d9-8df3-8b0ba204540f', NULL);
INSERT INTO public.file_assignations_users VALUES ('715bc9ef-c0a5-4b03-9416-ce77e2c0e708', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '0c770fba-e7b1-451d-8af1-9f59bf6c85f2', 'a76a395c-7f16-45d0-b748-8f726134e492', NULL);


--
-- TOC entry 5222 (class 0 OID 261132)
-- Dependencies: 250
-- Data for Name: file_comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_comments VALUES ('4a57f680-e9b4-4235-8b96-ac48625b1447', '2021-06-28 19:47:41.09346+01', '2021-06-28 19:47:41.09346+01', '3527410b-2c83-4f78-a4c5-2ed92484004b', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL, 'This is a file comment');
INSERT INTO public.file_comments VALUES ('22b046a3-caf5-4d7a-9171-decb9b9f9b0e', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '33d70211-d4bd-4709-8985-e345e292fb28', 'b091eda9-e766-46b5-914f-d34940d2267e', '766768e1-536a-4306-b6fc-96685e1fbe11', 'I cannot approve this.');
INSERT INTO public.file_comments VALUES ('22b046a3-caf5-4d7a-9171-decb9b9f9b0f', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'ccfcf27f-99d0-4787-95f1-c7da8ba6425e', 'b091eda9-e766-46b5-914f-d34940d2267e', '766768e1-536a-4306-b6fc-96685e1fbe12', 'All good, but check the check the wall height');


--
-- TOC entry 5223 (class 0 OID 261140)
-- Dependencies: 251
-- Data for Name: file_label_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5224 (class 0 OID 261146)
-- Dependencies: 252
-- Data for Name: file_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5191 (class 0 OID 260800)
-- Dependencies: 218
-- Data for Name: file_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_permissions VALUES ('0372beda-cf88-4a15-ab08-227fc3225506', '2021-06-28 18:08:00.569397+01', '2021-06-28 18:08:00.569397+01', '24c2b0df-4b57-4f99-819a-cf2bca041564');


--
-- TOC entry 5225 (class 0 OID 261152)
-- Dependencies: 253
-- Data for Name: file_permissions_orgs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_permissions_orgs VALUES ('85d9c47d-6e59-4263-886d-a02ab5e0f1c6', '2021-06-28 18:39:20.611168+01', '2021-06-28 18:39:20.611168+01', '0372beda-cf88-4a15-ab08-227fc3225506', 'fc9df192-6313-4347-9317-8ee7b37952ba', 'write');


--
-- TOC entry 5226 (class 0 OID 261160)
-- Dependencies: 254
-- Data for Name: file_permissions_teams; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_permissions_teams VALUES ('4a379183-a7cc-47d1-bcab-f58a62cf7df0', '2021-06-28 18:43:17.946841+01', '2021-06-28 18:43:17.946841+01', '0372beda-cf88-4a15-ab08-227fc3225506', '7f90ec6b-0cb2-413a-8157-ffc80b1b693e', 'read');


--
-- TOC entry 5227 (class 0 OID 261168)
-- Dependencies: 255
-- Data for Name: file_permissions_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_permissions_users VALUES ('c623cc9a-34ca-4642-8457-4ce99f091910', '2021-06-28 18:29:23.638895+01', '2021-06-28 18:29:23.638895+01', '0372beda-cf88-4a15-ab08-227fc3225506', 'b091eda9-e766-46b5-914f-d34940d2267e', 'write');


--
-- TOC entry 5228 (class 0 OID 261176)
-- Dependencies: 256
-- Data for Name: file_signatures; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_signatures VALUES ('10cd99ba-8923-42a0-ab1d-2c581294bb65', '2021-06-28 19:39:20.508338+01', '2021-06-28 19:39:20.508338+01', '3527410b-2c83-4f78-a4c5-2ed92484004b', 'b091eda9-e766-46b5-914f-d34940d2267e', '2021-06-28 19:38:35.762+01');


--
-- TOC entry 5229 (class 0 OID 261182)
-- Dependencies: 257
-- Data for Name: file_version_approval_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5230 (class 0 OID 261188)
-- Dependencies: 258
-- Data for Name: file_version_approval_request_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_version_approval_request_users VALUES ('25e12537-09f9-4133-a5ae-eb3dbef4a5b8', 'f307d743-17bd-4914-9e1b-c5e5a7c4797b', '496e3080-51e1-4db5-9789-15bd870c7b1e', '2021-06-28 20:02:43.586764+01', '2021-06-28 20:02:43.586764+01', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.file_version_approval_request_users VALUES ('d849eb2d-e2b8-4b98-93a0-bc67b7013dcd', 'dd55473b-10c2-41db-9135-9e51b9cbc0f8', '496e3080-51e1-4db5-9789-15bd870c7b3f', '2021-06-28 20:02:43.586764+01', '2021-06-28 20:02:43.586764+01', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.file_version_approval_request_users VALUES ('38cd0faf-0ec0-420f-b310-10b41eddaaf8', '63d4275d-9e35-4875-af94-b01c87b3f10a', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '86c8c162-3405-457c-9724-727aea142580');
INSERT INTO public.file_version_approval_request_users VALUES ('ffd07683-3fbb-443c-9628-e40b9f4e9603', '63d4275d-9e35-4875-af94-b01c87b3f10a', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '2c301925-1afd-461b-a5c2-d7930596845d');
INSERT INTO public.file_version_approval_request_users VALUES ('2c351856-4b21-45df-8214-56366928e25d', '63d4275d-9e35-4875-af94-b01c87b3f10a', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b03640d8-a9b9-46d9-8df3-8b0ba204540f');
INSERT INTO public.file_version_approval_request_users VALUES ('90c5e789-82dd-47ba-842b-1d7ce70a3386', '63d4275d-9e35-4875-af94-b01c87b3f10a', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a76a395c-7f16-45d0-b748-8f726134e492');
INSERT INTO public.file_version_approval_request_users VALUES ('134b733d-7f8a-4741-a584-17e0d694a141', '63d4275d-9e35-4875-af94-b01c87b3f10a', '766768e1-536a-4306-b6fc-96685e1fbe15', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.file_version_approval_request_users VALUES ('6d9a274d-e93f-4c99-b97d-7ca3f8e9217c', '1753d40a-adcc-401c-89f7-d9c33f65be1a', '766768e1-536a-4306-b6fc-96685e1fbe14', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '86c8c162-3405-457c-9724-727aea142580');
INSERT INTO public.file_version_approval_request_users VALUES ('c86f92c4-f2e4-43e2-b937-b23018b58c58', '1753d40a-adcc-401c-89f7-d9c33f65be1a', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '033af847-bded-487c-9228-5f7c5af19ac6');
INSERT INTO public.file_version_approval_request_users VALUES ('8fdf718f-caaa-4841-a324-f3bb9500e1af', '1753d40a-adcc-401c-89f7-d9c33f65be1a', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '2c301925-1afd-461b-a5c2-d7930596845d');
INSERT INTO public.file_version_approval_request_users VALUES ('b5171ac7-c7da-45ba-baf8-d7ed51e1ca43', '1753d40a-adcc-401c-89f7-d9c33f65be1a', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a76a395c-7f16-45d0-b748-8f726134e492');
INSERT INTO public.file_version_approval_request_users VALUES ('197d35d7-1e1b-4686-8a92-63edf6e53a2e', '1753d40a-adcc-401c-89f7-d9c33f65be1a', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.file_version_approval_request_users VALUES ('d7fb282b-6610-4d91-be69-cb2492825594', 'dea9d0ae-cce7-4dfc-b200-dcf2cf3eddb5', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '86c8c162-3405-457c-9724-727aea142580');
INSERT INTO public.file_version_approval_request_users VALUES ('c4c6a3c2-386c-44fb-b96a-3a40e4cfdf90', 'dea9d0ae-cce7-4dfc-b200-dcf2cf3eddb5', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '2c301925-1afd-461b-a5c2-d7930596845d');
INSERT INTO public.file_version_approval_request_users VALUES ('f5b2ade8-2708-4023-aba3-2d2d120230e1', 'dea9d0ae-cce7-4dfc-b200-dcf2cf3eddb5', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b03640d8-a9b9-46d9-8df3-8b0ba204540f');
INSERT INTO public.file_version_approval_request_users VALUES ('7f6373c2-491a-4576-a107-3b4ebcea8e76', 'dea9d0ae-cce7-4dfc-b200-dcf2cf3eddb5', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a76a395c-7f16-45d0-b748-8f726134e492');
INSERT INTO public.file_version_approval_request_users VALUES ('75e1e891-e8ae-4b44-88ff-66c8d0f5117a', 'dea9d0ae-cce7-4dfc-b200-dcf2cf3eddb5', '766768e1-536a-4306-b6fc-96685e1fbe13', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.file_version_approval_request_users VALUES ('89e29ba6-51f2-4e8d-9dad-51af71f119fb', '4ab2364a-1079-432f-b5eb-43b2ef7f88c0', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '86c8c162-3405-457c-9724-727aea142580');
INSERT INTO public.file_version_approval_request_users VALUES ('89e29ba6-51f3-4e8d-9dad-51af71f119fb', '4ab2364a-1079-432f-b5eb-43b2ef7f88c0', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '2c301925-1afd-461b-a5c2-d7930596845d');
INSERT INTO public.file_version_approval_request_users VALUES ('89e29ba6-51f4-4e8d-9dad-51af71f119fb', '4ab2364a-1079-432f-b5eb-43b2ef7f88c0', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b03640d8-a9b9-46d9-8df3-8b0ba204540f');
INSERT INTO public.file_version_approval_request_users VALUES ('89e29ba6-51f5-4e8d-9dad-51af71f119fb', '4ab2364a-1079-432f-b5eb-43b2ef7f88c0', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a76a395c-7f16-45d0-b748-8f726134e492');
INSERT INTO public.file_version_approval_request_users VALUES ('89e29ba6-51f6-4e8d-9dad-51af71f119fb', '4ab2364a-1079-432f-b5eb-43b2ef7f88c0', '766768e1-536a-4306-b6fc-96685e1fbe12', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.file_version_approval_request_users VALUES ('89e29ba6-51f2-4e8d-9dad-71af71f119fb', '555f2733-6571-4ec5-a2b1-d869d22bdb20', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '86c8c162-3405-457c-9724-727aea142580');
INSERT INTO public.file_version_approval_request_users VALUES ('89e29ba6-51f3-4e8d-9dad-81af71f119fb', '555f2733-6571-4ec5-a2b1-d869d22bdb20', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '2c301925-1afd-461b-a5c2-d7930596845d');
INSERT INTO public.file_version_approval_request_users VALUES ('89e29ba6-51f4-4e8d-9dad-91af71f119fb', '555f2733-6571-4ec5-a2b1-d869d22bdb20', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b03640d8-a9b9-46d9-8df3-8b0ba204540f');
INSERT INTO public.file_version_approval_request_users VALUES ('89e29ba6-51f5-4e8d-9dad-11af71f119fb', '555f2733-6571-4ec5-a2b1-d869d22bdb20', NULL, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a76a395c-7f16-45d0-b748-8f726134e492');
INSERT INTO public.file_version_approval_request_users VALUES ('89e29ba6-51f6-4e8d-9dad-12af71f119fb', '555f2733-6571-4ec5-a2b1-d869d22bdb20', '766768e1-536a-4306-b6fc-96685e1fbe11', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b091eda9-e766-46b5-914f-d34940d2267e');


--
-- TOC entry 5193 (class 0 OID 260823)
-- Dependencies: 220
-- Data for Name: file_version_approval_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_version_approval_requests VALUES ('f307d743-17bd-4914-9e1b-c5e5a7c4797b', '3527410b-2c83-4f78-a4c5-2ed92484004b', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00');
INSERT INTO public.file_version_approval_requests VALUES ('dd55473b-10c2-41db-9135-9e51b9cbc0f8', '3527410b-2c83-4f78-a4c5-2ed924810024', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00');
INSERT INTO public.file_version_approval_requests VALUES ('63d4275d-9e35-4875-af94-b01c87b3f10a', '967aa6c7-cd19-4fda-8feb-2ca99c01c03b', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00');
INSERT INTO public.file_version_approval_requests VALUES ('1753d40a-adcc-401c-89f7-d9c33f65be1a', 'd541193f-9748-4779-8e63-6e6bafe39c13', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00');
INSERT INTO public.file_version_approval_requests VALUES ('dea9d0ae-cce7-4dfc-b200-dcf2cf3eddb5', '7d1c3e06-9308-4fe6-86c5-3fdd8558638d', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00');
INSERT INTO public.file_version_approval_requests VALUES ('4ab2364a-1079-432f-b5eb-43b2ef7f88c0', 'ccfcf27f-99d0-4787-95f1-c7da8ba6425e', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00');
INSERT INTO public.file_version_approval_requests VALUES ('555f2733-6571-4ec5-a2b1-d869d22bdb20', '33d70211-d4bd-4709-8985-e345e292fb28', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00');


--
-- TOC entry 5231 (class 0 OID 261194)
-- Dependencies: 259
-- Data for Name: file_version_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5232 (class 0 OID 261200)
-- Dependencies: 260
-- Data for Name: file_version_wopi; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5192 (class 0 OID 260810)
-- Dependencies: 219
-- Data for Name: file_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed92484004b', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', '24c2b0df-4b57-4f99-819a-cf2bca041564', '18214557-486f-4cdd-a714-a585c643c8a7', 'File Test', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'binary/octet-stream', 'bin', 43576, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840040', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', '3c84fd56-28cc-4730-8323-01ad0ea60772', '18214557-486f-4cdd-a714-a585c643c8a8', 'File Test 1', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'binary/octet-stream', 'bin', 56879, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840042', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db4bee1e0', '18214557-486f-4cdd-a714-a585c643c8b1', 'File12.mov', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'video/quicktime', 'mov', 85987, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840043', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db4bee2e0', '18214557-486f-4cdd-a714-a585c643c8b2', 'File13.mp4', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'video/mp4', 'mp4', 98547, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840044', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db4bee3e0', '18214557-486f-4cdd-a714-a585c643c8b3', 'File14.docx', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'docx', 54879, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840045', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db4bee4e0', '18214557-486f-4cdd-a714-a585c643c8b4', 'File15.png', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'image/png', 'png', 15478, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840046', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db4bee5e0', '18214557-486f-4cdd-a714-a585c643c8b5', 'File16.jpg', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'image/jpeg', 'jpg', 54789, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840047', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db4bee6e0', '18214557-486f-4cdd-a714-a585c643c8b6', 'File17.txt', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'text/plain', 'txt', 5458, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840048', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db4bee7e0', '18214557-486f-4cdd-a714-a585c643c8b7', 'File18.dwg', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'image/vnd.dwg', 'dwg', 87954, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840049', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db4bee8e0', '18214557-486f-4cdd-a714-a585c643c8b8', 'File19.xlsx', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'xlsx', 45879, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840050', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db4bee0f0', '18214557-486f-4cdd-a714-a585c643c8b9', 'File20.pdf', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/pdf', 'pdf', 21459, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840053', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db4bee000', '18214557-486f-4cdd-a714-a585c643c8c3', 'FileInProjectTourEiffel', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'binary/octet-stream', 'bin', 43577, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840041', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db4bee0e0', '18214557-486f-4cdd-a714-a585c643c8a9', 'File11', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'binary/octet-stream', 'bin', 36958, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840051', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db1bee9e8', '18214557-486f-4cdd-a714-a585c643c8c1', 'File1InFolder1Nested', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'binary/octet-stream', 'bin', 43577, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840052', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc1-4f18-aa74-f83db1bee9e8', '18214557-486f-4cdd-a714-a585c643c8c2', 'File2InFolder1Nested', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'binary/octet-stream', 'bin', 43577, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924810024', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc1-4f18-aa74-f83db1be4414', '18214557-486f-4cdd-a714-a585c643c5c8', 'File1InFolder3Nested', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'binary/octet-stream', 'bin', 43577, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840054', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db4bee100', '18214557-486f-4cdd-a714-a585c643c8c4', 'file.wopitest', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'binary/octet-stream', 'wopitest', 0, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840055', '2021-06-28 19:32:30.261578+01', '2021-06-28 19:32:30.261578+01', 'd1533f47-afc9-4f98-aa74-f83db4bee101', '18214557-486f-4cdd-a714-a585c643c8c5', 'Project Summary 2022 [Public Version].doc', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/msword', 'doc', 43577, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840100', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee110', '18214557-486f-4cdd-a714-a585c643c8a0', 'test.pdf', 1, 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', 'application/pdf', 'pdf', 21459, false);
INSERT INTO public.file_versions VALUES ('967aa6c7-cd19-4fda-8feb-2ca99c01c03b', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'fda88eda-bc35-4bbd-bee7-ffd167ec7a05', '967aa6c7-cd19-4fda-8feb-2ca99c01c03b', 'Plan_facade_est.pdf', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/pdf', 'pdf', 5814, false);
INSERT INTO public.file_versions VALUES ('d541193f-9748-4779-8e63-6e6bafe39c13', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b9246647-4a52-45aa-852e-cd02eab3639c', 'd541193f-9748-4779-8e63-6e6bafe39c13', 'Fiches test câbles réseau.pdf', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/pdf', 'pdf', 5814, false);
INSERT INTO public.file_versions VALUES ('33d70211-d4bd-4709-8985-e345e292fb28', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'af35fc46-fa72-491f-9dc9-0783a7e300df', '33d70211-d4bd-4709-8985-e345e292fb28', '301842MCC225-DDE.dwg', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'image/vnd.dwg', 'dwg', 87954, false);
INSERT INTO public.file_versions VALUES ('ccfcf27f-99d0-4787-95f1-c7da8ba6425e', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'af35fc46-fa72-491f-9dc9-0783a7e300df', 'ccfcf27f-99d0-4787-95f1-c7da8ba6425e', '301842MCC225-DDE.dwg', 2, 'b091eda9-e766-46b5-914f-d34940d2267e', 'image/vnd.dwg', 'dwg', 87954, false);
INSERT INTO public.file_versions VALUES ('7d1c3e06-9308-4fe6-86c5-3fdd8558638d', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'af35fc46-fa72-491f-9dc9-0783a7e300df', '7d1c3e06-9308-4fe6-86c5-3fdd8558638d', '301842MCC225-DDE.dwg', 3, 'b091eda9-e766-46b5-914f-d34940d2267e', 'image/vnd.dwg', 'dwg', 87954, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840142', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee1a0', '3527410b-2c83-4f78-a4c5-2ed924840142', 'Sample12.mov', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'video/quicktime', 'mov', 85987, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840143', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee2a0', '3527410b-2c83-4f78-a4c5-2ed924840143', 'Sample13.webm', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'video/webm', 'webm', 98547, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840144', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee3a0', '3527410b-2c83-4f78-a4c5-2ed924840144', 'Sample14.docx', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'docx', 54879, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840145', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee4a0', '3527410b-2c83-4f78-a4c5-2ed924840145', 'Sample15.png', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'image/png', 'png', 15478, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840146', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee5a0', '3527410b-2c83-4f78-a4c5-2ed924840146', 'Sample16.jpg', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'image/jpeg', 'jpg', 54789, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840147', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee6a0', '3527410b-2c83-4f78-a4c5-2ed924840147', 'Sample17.txt', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'text/plain', 'txt', 5458, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840148', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee7a0', '3527410b-2c83-4f78-a4c5-2ed924840148', 'Sample18.dwg', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'image/vnd.dwg', 'dwg', 87954, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840149', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee8a0', '3527410b-2c83-4f78-a4c5-2ed924840149', 'Sample19.xlsx', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'xlsx', 45879, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840150', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee0a0', '3527410b-2c83-4f78-a4c5-2ed924840150', 'Sample20.pdf', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/pdf', 'pdf', 21459, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840242', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee1b0', '3527410b-2c83-4f78-a4c5-2ed924840242', 'Demo-12_public-0x0.mov', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'video/quicktime', 'mov', 85987, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840243', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee2b0', '3527410b-2c83-4f78-a4c5-2ed924840243', 'very important requeriments to be fixed as soon as this text is long enough to get the point 2022-09.mp4', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'video/mp4', 'mp4', 98547, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840244', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee3b0', '3527410b-2c83-4f78-a4c5-2ed924840244', 'Document-14_public-0x0__20220923.docx', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'docx', 54879, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840245', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee4b0', '3527410b-2c83-4f78-a4c5-2ed924840245', 'Resistor-Color-Codes_&_AWG_wire_specifications_rev2022.png', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'image/png', 'png', 15478, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840246', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee5b0', '3527410b-2c83-4f78-a4c5-2ed924840246', 'Floor-samples-16_public-0x0.jpg', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'image/jpeg', 'jpg', 54789, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840247', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee6b0', '3527410b-2c83-4f78-a4c5-2ed924840247', 'meeting-notes-17-important_public-0x0__20220923.txt', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'text/plain', 'txt', 5458, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840248', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee7b0', '3527410b-2c83-4f78-a4c5-2ed924840248', 'file-18-samples-of-everything_public-0x0.dwg', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'image/vnd.dwg', 'dwg', 87954, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840249', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee8b0', '3527410b-2c83-4f78-a4c5-2ed924840249', 'measurements20220923-parts-bill.xlsx', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'xlsx', 45879, false);
INSERT INTO public.file_versions VALUES ('3527410b-2c83-4f78-a4c5-2ed924840250', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'd1533f47-afc9-4f98-aa74-f83db4bee0b0', '3527410b-2c83-4f78-a4c5-2ed924840250', 'documentation-20-theory-of-everything__rev023.pdf', 1, 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/pdf', 'pdf', 21459, false);


--
-- TOC entry 5234 (class 0 OID 261214)
-- Dependencies: 262
-- Data for Name: file_views; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5187 (class 0 OID 260756)
-- Dependencies: 214
-- Data for Name: files; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.files VALUES ('24c2b0df-4b57-4f99-819a-cf2bca041564', '2021-06-28 17:28:30.804427+01', '2021-06-28 17:28:30.804427+01', '729e75ad-b479-4659-a267-1b911c377c5e', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File Test', true, NULL);
INSERT INTO public.files VALUES ('3c84fd56-28cc-4730-8323-01ad0ea60772', '2021-06-28 17:28:35.566401+01', '2021-06-28 17:28:35.566401+01', '729e75ad-b479-4659-a267-1b911c377c5e', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File Test 1', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db1bee9e8', '2021-07-16 21:54:43.13+01', '2021-07-16 21:54:43.13+01', '82440cc2-20d4-416e-847d-c954fbec6921', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File1InFolder1Nested', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc1-4f18-aa74-f83db1bee9e8', '2021-07-16 21:54:43.13+01', '2021-07-16 21:54:43.13+01', '82440cc2-20d4-416e-847d-c954fbec6921', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File2InFolder1Nested', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc1-4f18-aa74-f83db1be4414', '2021-07-16 21:54:43.13+01', '2021-07-16 21:54:43.13+01', '30f917ad-7eb4-4449-8e63-f56d345ead21', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File1InFolder3Nested', true, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee000', '2021-07-16 21:54:43.117+01', '2021-07-16 21:54:43.117+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'FileInProjectTourEiffel', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee0e0', '2021-07-16 21:54:43.13+01', '2021-07-16 21:54:43.13+01', '79952888-ec76-473f-af48-337b8e5b04bf', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File11', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee1e0', '2021-07-16 21:54:43.13+01', '2021-07-16 21:54:43.13+01', '79952888-ec76-473f-af48-337b8e5b04bf', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File12.mov', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee2e0', '2021-07-16 21:54:43.13+01', '2021-07-16 21:54:43.13+01', '79952888-ec76-473f-af48-337b8e5b04bf', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File13.mp4', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee3e0', '2021-07-16 21:54:43.13+01', '2021-07-16 21:54:43.13+01', '79952888-ec76-473f-af48-337b8e5b04bf', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File14.docx', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee4e0', '2021-07-16 21:54:43.13+01', '2021-07-16 21:54:43.13+01', '79952888-ec76-473f-af48-337b8e5b04bf', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File15.png', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee5e0', '2021-07-16 21:54:43.13+01', '2021-07-16 21:54:43.13+01', '79952888-ec76-473f-af48-337b8e5b04bf', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File16.jpg', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee6e0', '2021-07-16 21:54:43.13+01', '2021-07-16 21:54:43.13+01', '79952888-ec76-473f-af48-337b8e5b04bf', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File17.txt', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee7e0', '2021-07-16 21:54:43.13+01', '2021-07-16 21:54:43.13+01', '79952888-ec76-473f-af48-337b8e5b04bf', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File18.dwg', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee8e0', '2021-07-16 21:54:43.13+01', '2021-07-16 21:54:43.13+01', '79952888-ec76-473f-af48-337b8e5b04bf', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File19.xlsx', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee0f0', '2021-07-16 21:54:43.13+01', '2021-07-16 21:54:43.13+01', '79952888-ec76-473f-af48-337b8e5b04bf', '7b450b00-c9b5-4332-b087-46af26e8a525', 'File20.pdf', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee100', '2021-07-16 21:54:43.117+01', '2021-07-16 21:54:43.117+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'file.wopitest', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee101', '2021-07-16 21:54:43.117+01', '2021-07-16 21:54:43.117+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Project Summary 2022 [Public Version].doc', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee1a0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Sample12.mov', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee2a0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Sample13.webm', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee3a0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Sample14.docx', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee4a0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Sample15.png', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee5a0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Sample16.jpg', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee6a0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Sample17.txt', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee7a0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Sample18.dwg', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee8a0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Sample19.xlsx', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee0a0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Sample20.pdf', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee1b0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Demo-12_public-0x0.mov', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee2b0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'very important requeriments to be fixed as soon as this text is long enough to get the point 2022-09.mp4', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee3b0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Document-14_public-0x0__20220923.docx', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee4b0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Resistor-Color-Codes_&_AWG_wire_specifications_rev2022.png', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee5b0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'Floor-samples-16_public-0x0.jpg', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee6b0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'meeting-notes-17-important_public-0x0__20220923.txt', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee7b0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'file-18-samples-of-everything_public-0x0.dwg', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee8b0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'measurements20220923-parts-bill.xlsx', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee0b0', '2022-09-13 21:54:43.13+01', '2022-09-19 21:54:43.13+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', 'documentation-20-theory-of-everything__rev023.pdf', false, NULL);
INSERT INTO public.files VALUES ('d1533f47-afc9-4f98-aa74-f83db4bee110', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '7d04e9ae-5ece-4ccb-8399-37797ae86e90', '915e171c-905a-423a-9916-2aa388d6dc7c', 'Test', false, NULL);
INSERT INTO public.files VALUES ('af35fc46-fa72-491f-9dc9-0783a7e300df', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '7d04e9ae-5ece-4ccb-8399-37797ae86ea0', '915e171c-905a-423a-9916-2aa388d6dc7b', '301842MCC225-DDE.dwg', true, NULL);
INSERT INTO public.files VALUES ('b9246647-4a52-45aa-852e-cd02eab3639c', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '7d04e9ae-5ece-4ccb-8399-37797ae86ea0', '915e171c-905a-423a-9916-2aa388d6dc7b', 'Fiches test câbles réseau.pdf', true, NULL);
INSERT INTO public.files VALUES ('fda88eda-bc35-4bbd-bee7-ffd167ec7a05', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '7d04e9ae-5ece-4ccb-8399-37797ae86ea0', '915e171c-905a-423a-9916-2aa388d6dc7b', 'Plan_facade_est.pdf', true, '2024-01-01 00:00:00+00');


--
-- TOC entry 5236 (class 0 OID 261220)
-- Dependencies: 264
-- Data for Name: files_to_project_labels; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.files_to_project_labels VALUES ('d7b2fc7a-4581-45c6-841a-330b31d44506', '2021-06-28 18:02:08.634997+01', '2021-06-28 18:02:08.634997+01', '24c2b0df-4b57-4f99-819a-cf2bca041564', '3a3a03f9-262c-45a9-8626-1c9098763783', 0);
INSERT INTO public.files_to_project_labels VALUES ('efe4814a-3ef3-4616-9515-f5511b6e4a11', '2021-10-06 09:50:06.629052+01', '2021-10-06 09:50:06.629052+01', 'd1533f47-afc9-4f98-aa74-f83db1bee9e8', '0af4ecd8-c41d-4c26-84e3-34fdb4987984', 0);
INSERT INTO public.files_to_project_labels VALUES ('1d23095d-6b40-48eb-971f-f812d0763f12', '2021-10-06 09:50:13.535257+01', '2021-10-06 09:50:13.535257+01', 'd1533f47-afc9-4f98-aa74-f83db1bee9e8', '0a57ca89-07f4-4372-b3a8-ed8b5ba52ba4', 0);
INSERT INTO public.files_to_project_labels VALUES ('04c3bc33-68d9-4a51-9d47-98192c808e13', '2021-10-06 09:50:19.618782+01', '2021-10-06 09:50:19.618782+01', 'd1533f47-afc9-4f98-aa74-f83db1bee9e8', 'ee092eaa-386f-48e7-9763-0c61f044526b', 0);


--
-- TOC entry 5237 (class 0 OID 261227)
-- Dependencies: 265
-- Data for Name: folder_access_enum; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.folder_access_enum VALUES ('write', 'All access');
INSERT INTO public.folder_access_enum VALUES ('read', 'Read only');


--
-- TOC entry 5238 (class 0 OID 261232)
-- Dependencies: 266
-- Data for Name: folder_assignation_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5194 (class 0 OID 260832)
-- Dependencies: 221
-- Data for Name: folder_assignations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.folder_assignations VALUES ('5a00e267-d743-44bb-a937-59d51b41552a', '2021-06-23 17:24:59.034608+01', '2021-06-23 17:24:59.034608+01', '729e75ad-b479-4659-a267-1b911c377c5e');


--
-- TOC entry 5239 (class 0 OID 261238)
-- Dependencies: 267
-- Data for Name: folder_assignations_orgs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.folder_assignations_orgs VALUES ('a89a7ef3-6c91-4e42-98ed-5c396c77e796', '2021-06-23 17:38:53.325104+01', '2021-06-23 17:38:53.325104+01', '5a00e267-d743-44bb-a937-59d51b41552a', 'fc9df192-6313-4347-9317-8ee7b37952ba', NULL);


--
-- TOC entry 5240 (class 0 OID 261244)
-- Dependencies: 268
-- Data for Name: folder_assignations_teams; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.folder_assignations_teams VALUES ('8c23e02f-05a9-4bc7-ab82-eec066f7c01d', '2021-06-23 17:46:42.255629+01', '2021-06-23 17:46:42.255629+01', '5a00e267-d743-44bb-a937-59d51b41552a', '7f90ec6b-0cb2-413a-8157-ffc80b1b693e', NULL);


--
-- TOC entry 5241 (class 0 OID 261250)
-- Dependencies: 269
-- Data for Name: folder_assignations_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.folder_assignations_users VALUES ('5df5ea95-10be-4cc8-b50d-b0ef67d704c5', '2021-06-23 17:32:51.898009+01', '2021-06-23 17:32:51.898009+01', '5a00e267-d743-44bb-a937-59d51b41552a', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL);


--
-- TOC entry 5242 (class 0 OID 261256)
-- Dependencies: 270
-- Data for Name: folder_label_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5243 (class 0 OID 261262)
-- Dependencies: 271
-- Data for Name: folder_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5185 (class 0 OID 260740)
-- Dependencies: 212
-- Data for Name: folder_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.folder_permissions VALUES ('151db028-d4f2-470b-833e-843fd75b579b', '2021-06-23 19:35:50.065359+01', '2021-06-23 19:35:50.065359+01', '729e75ad-b479-4659-a267-1b911c377c5e', NULL);
INSERT INTO public.folder_permissions VALUES ('151db028-d4f2-470b-833e-843fd75b579c', '2021-06-23 19:35:50.065359+01', '2021-06-23 19:35:50.065359+01', '7d04e9ae-5ece-4ccb-8399-37797ae86e81', '729e75ad-b479-4659-a267-1b911c377c5e');


--
-- TOC entry 5244 (class 0 OID 261268)
-- Dependencies: 272
-- Data for Name: folder_permissions_orgs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.folder_permissions_orgs VALUES ('007d5d46-3dfb-44cd-a050-2450fd5dc9a8', '2021-06-23 19:56:47.327101+01', '2021-06-23 19:56:47.327101+01', '151db028-d4f2-470b-833e-843fd75b579b', 'write', 'fc9df192-6313-4347-9317-8ee7b37952ba', NULL);


--
-- TOC entry 5245 (class 0 OID 261276)
-- Dependencies: 273
-- Data for Name: folder_permissions_teams; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.folder_permissions_teams VALUES ('10f6990b-c970-43e1-85c3-284cebd45f8d', '2021-06-23 20:01:09.839699+01', '2021-06-23 20:01:09.839699+01', '151db028-d4f2-470b-833e-843fd75b579b', 'read', '7f90ec6b-0cb2-413a-8157-ffc80b1b693e', NULL);


--
-- TOC entry 5246 (class 0 OID 261284)
-- Dependencies: 274
-- Data for Name: folder_permissions_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.folder_permissions_users VALUES ('0750394f-e70e-4ac2-84e1-86e93a40548e', '2021-06-23 19:51:37.625943+01', '2021-06-23 19:51:37.625943+01', '151db028-d4f2-470b-833e-843fd75b579b', 'write', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL);


--
-- TOC entry 5247 (class 0 OID 261292)
-- Dependencies: 275
-- Data for Name: folder_views; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5195 (class 0 OID 260839)
-- Dependencies: 222
-- Data for Name: folders; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-37797ae86e82', '2021-05-23 15:25:59.313904+01', '2021-06-23 15:25:59.313904+01', '[project] root - Tour Eiffel', NULL, '7b450b00-c9b5-4332-b087-46af26e8a525', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-37797ae86e83', '2021-05-23 15:25:59.313904+01', '2021-06-23 15:25:59.313904+01', '[project] root bin  - Tour Eiffel', NULL, '7b450b00-c9b5-4332-b087-46af26e8a525', false, true, NULL);
INSERT INTO public.folders VALUES ('729e75ad-b479-4659-a267-1b911c377c5e', '2021-06-01 15:25:44.895888+01', '2021-06-23 15:25:44.895888+01', 'Folder1', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', false, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-37797ae86e81', '2021-06-02 15:25:59.313904+01', '2021-06-23 15:25:59.313904+01', 'Folder2', '729e75ad-b479-4659-a267-1b911c377c5e', '7b450b00-c9b5-4332-b087-46af26e8a525', false, false, NULL);
INSERT INTO public.folders VALUES ('82440cc2-20d4-416e-847d-c954fbec6921', '2021-07-03 21:54:43.073+01', '2021-07-16 21:54:43.073+01', 'Folder1Nested', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', false, false, NULL);
INSERT INTO public.folders VALUES ('82440cc2-20d4-416e-847d-c954fbec6922', '2021-07-04 21:54:43.073+01', '2021-07-16 21:54:43.073+01', 'Folder1Nested1', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', false, false, NULL);
INSERT INTO public.folders VALUES ('e8690846-1621-47f4-bd15-535b1722218a', '2021-07-05 21:54:43.095+01', '2021-07-16 21:54:43.095+01', 'Folder2Nested', '82440cc2-20d4-416e-847d-c954fbec6921', '7b450b00-c9b5-4332-b087-46af26e8a525', false, false, NULL);
INSERT INTO public.folders VALUES ('30f917ad-7eb4-4449-8e63-f56d345ead21', '2021-07-06 21:54:43.105+01', '2021-07-16 21:54:43.105+01', 'Folder3Nested', 'e8690846-1621-47f4-bd15-535b1722218a', '7b450b00-c9b5-4332-b087-46af26e8a525', false, false, NULL);
INSERT INTO public.folders VALUES ('79952888-ec76-473f-af48-337b8e5b04bf', '2021-07-07 21:54:43.117+01', '2021-07-16 21:54:43.117+01', 'Folder4Nested', '30f917ad-7eb4-4449-8e63-f56d345ead21', '7b450b00-c9b5-4332-b087-46af26e8a525', false, false, NULL);
INSERT INTO public.folders VALUES ('d1533f47-afc9-4f98-aa74-c954fbec6000', '2021-07-08 21:54:43.117+01', '2021-07-16 21:54:43.117+01', 'FolderInProjectTourEiffel', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', false, false, NULL);
INSERT INTO public.folders VALUES ('12440cc2-20d4-416e-847d-c354fbec6924', '2021-07-09 21:54:43.073+01', '2021-07-16 21:54:43.073+01', 'EmptyFolder', '7d04e9ae-5ece-4ccb-8399-37797ae86e82', '7b450b00-c9b5-4332-b087-46af26e8a525', false, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-37797ae86e84', '2021-05-23 15:25:59.313904+01', '2021-06-23 15:25:59.313904+01', '[project] root - Notre-Dame de Paris', NULL, '915e171c-905a-423a-9916-2aa388d6dc4b', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-37797ae86e85', '2021-05-23 15:25:59.313904+01', '2021-06-23 15:25:59.313904+01', '[project] root bin  - Notre-Dame de Paris', NULL, '915e171c-905a-423a-9916-2aa388d6dc4b', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-37797ae86e86', '2021-05-23 15:25:59.313904+01', '2021-06-23 15:25:59.313904+01', '[project] root - Google Search Engine', NULL, '915e171c-905a-423a-9916-2aa388d6dc5b', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-37797ae86e87', '2021-05-23 15:25:59.313904+01', '2021-06-23 15:25:59.313904+01', '[project] root bin  - Google Search Engine', NULL, '915e171c-905a-423a-9916-2aa388d6dc5b', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-37797ae86e88', '2021-05-23 15:25:59.313904+01', '2021-06-23 15:25:59.313904+01', '[project] root - Google Image Engine', NULL, '915e171c-905a-423a-9916-2aa388d6dc6b', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-37797ae86e89', '2021-05-23 15:25:59.313904+01', '2021-06-23 15:25:59.313904+01', '[project] root bin  - Google Image Engine', NULL, '915e171c-905a-423a-9916-2aa388d6dc6b', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-37797ae86ea0', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, '915e171c-905a-423a-9916-2aa388d6dc7b', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-37797ae86ea1', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, '915e171c-905a-423a-9916-2aa388d6dc7b', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-37797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, '915e171c-905a-423a-9916-2aa388d6dc7c', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-37797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, '915e171c-905a-423a-9916-2aa388d6dc7c', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-17797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, '4385e95e-cc98-4712-86cf-4cfe0e88ecfc', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-17797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, '4385e95e-cc98-4712-86cf-4cfe0e88ecfc', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-27797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, '6eec8a9e-a3c4-4d75-9972-b18f4071e1fd', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-27797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, '6eec8a9e-a3c4-4d75-9972-b18f4071e1fd', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-a7797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, 'ff5160d0-036c-42b5-88da-12b55b556afb', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-a7797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, 'ff5160d0-036c-42b5-88da-12b55b556afb', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-57797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, '3d1a6331-14c4-492d-8d9b-569853accd60', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-57797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, '3d1a6331-14c4-492d-8d9b-569853accd60', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-67797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, '23d54a9c-2c62-4577-9752-3ffa765bba60', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-67797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, '23d54a9c-2c62-4577-9752-3ffa765bba60', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-77797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, '13740224-b781-4e56-ae26-c1620f326701', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-77797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, '13740224-b781-4e56-ae26-c1620f326701', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-87797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, '5cff40ca-26bd-4220-b80b-346703077c93', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-87797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, '5cff40ca-26bd-4220-b80b-346703077c93', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-97797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, 'b4b9bc3c-105a-48c3-a33f-6ec8e1c90288', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8399-97797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, 'b4b9bc3c-105a-48c3-a33f-6ec8e1c90288', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8388-37797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, 'dd720212-8b16-4a68-ac01-2728dc9482a4', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8377-37797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, 'dd720212-8b16-4a68-ac01-2728dc9482a4', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8488-37797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, '52eec533-137e-4a1e-8519-5eaaec62219e', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8477-37797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, '52eec533-137e-4a1e-8519-5eaaec62219e', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8588-37797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, '5720f0a7-3a09-409e-bce0-b2d4359c4e4a', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8577-37797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, '5720f0a7-3a09-409e-bce0-b2d4359c4e4a', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8688-37797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, '3c53c1f5-2959-4b8b-9fc5-3e095a695cbb', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8677-37797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, '3c53c1f5-2959-4b8b-9fc5-3e095a695cbb', false, true, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8788-37797ae86e90', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root', NULL, 'bd0ffe82-78f6-4c92-8623-bb06c9897a93', true, false, NULL);
INSERT INTO public.folders VALUES ('7d04e9ae-5ece-4ccb-8777-37797ae86e91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'root bin', NULL, 'bd0ffe82-78f6-4c92-8623-bb06c9897a93', false, true, NULL);


--
-- TOC entry 5249 (class 0 OID 261298)
-- Dependencies: 277
-- Data for Name: folders_to_project_labels; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.folders_to_project_labels VALUES ('efe4814a-3ef3-4616-9515-f5511b6e4a8b', '2021-10-06 09:50:06.629052+01', '2021-10-06 09:50:06.629052+01', '82440cc2-20d4-416e-847d-c954fbec6921', '0af4ecd8-c41d-4c26-84e3-34fdb4987984', 0);
INSERT INTO public.folders_to_project_labels VALUES ('1d23095d-6b40-48eb-971f-f812d0763fa8', '2021-10-06 09:50:13.535257+01', '2021-10-06 09:50:13.535257+01', '82440cc2-20d4-416e-847d-c954fbec6921', '0a57ca89-07f4-4372-b3a8-ed8b5ba52ba4', 0);
INSERT INTO public.folders_to_project_labels VALUES ('04c3bc33-68d9-4a51-9d47-98192c808e3e', '2021-10-06 09:50:19.618782+01', '2021-10-06 09:50:19.618782+01', '82440cc2-20d4-416e-847d-c954fbec6921', 'ee092eaa-386f-48e7-9763-0c61f044526b', 0);


--
-- TOC entry 5250 (class 0 OID 261305)
-- Dependencies: 278
-- Data for Name: org_address; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.org_address VALUES ('fc9df192-6313-4347-9317-8ee7b37952ba', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '26 Rue des Quatre Fils', '75003', NULL, NULL, 'France', 'Paris', 48.86090720160398, 2.3584584576171697);
INSERT INTO public.org_address VALUES ('fc9df192-6313-4347-9317-8ee7b37953cb', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '2 Rue d''Enfer', '51290', 'Rte de Drosnay, 51290 Saint-Remy-en-Bouzemont-Saint-Genest-et-Isson, France', '10 All. de la Formerie, 51290 Saint-Remy-en-Bouzemont-Saint-Genest-et-Isson, France', 'France', 'Saint-Remy-en-Bouzemont-Saint-Genest-et-Isson', 48.627639, 4.6432977);
INSERT INTO public.org_address VALUES ('fc9df192-6313-4347-9317-8ee7b37953cc', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'Pl. du Panthéon', '75005', 'Pl. de l''Opéra, 75009 Paris, France', '35 Rue du Chevalier de la Barre, 75018 Paris, France', 'France', 'Paris', 48.8462218, 2.3464138);


--
-- TOC entry 5251 (class 0 OID 261312)
-- Dependencies: 279
-- Data for Name: org_avatars; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.org_avatars VALUES ('2021-09-09 18:26:39.034496+01', '2021-09-09 18:26:39.034496+01', 'fc9df192-6313-4347-9317-8ee7b37952ba', 'org_avatar.jpg', 'orgAvatar', 'image/jpeg', 'jpg', 3123);
INSERT INTO public.org_avatars VALUES ('2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'fc9df192-6313-4347-9317-8ee7b37953cb', 'org_avatar.jpg', 'orgAvatar', 'image/jpeg', 'jpg', 3123);


--
-- TOC entry 5252 (class 0 OID 261319)
-- Dependencies: 280
-- Data for Name: org_backgrounds; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.org_backgrounds VALUES ('2021-09-09 18:26:39.034496+01', '2021-09-09 18:26:39.034496+01', 'fc9df192-6313-4347-9317-8ee7b37952ba', 'org_background.jpg', 'orgBackground', 'image/jpeg', 'jpg', 3123);
INSERT INTO public.org_backgrounds VALUES ('2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'fc9df192-6313-4347-9317-8ee7b37953cb', 'org_background.jpg', 'orgBackground', 'image/jpeg', 'jpg', 3123);


--
-- TOC entry 5253 (class 0 OID 261326)
-- Dependencies: 281
-- Data for Name: org_licenses; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5254 (class 0 OID 261334)
-- Dependencies: 282
-- Data for Name: org_member_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5255 (class 0 OID 261340)
-- Dependencies: 283
-- Data for Name: org_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5200 (class 0 OID 260907)
-- Dependencies: 228
-- Data for Name: org_project_summary; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.org_project_summary VALUES ('ba1056ec-4875-480a-ae60-d136c00590f3', 'fc9df192-6313-4347-9317-8ee7b37952ba', '7b450b00-c9b5-4332-b087-46af26e8a525', '2021-09-28 10:46:05.253155+01', '2021-09-28 10:46:05.253155+01', '2021-09-10 10:00:00+01', '2021-12-10 09:00:00+00', 'ABCDE7D', 'Jean Michel', '0643382134', 'michel@gmail.com', NULL);
INSERT INTO public.org_project_summary VALUES ('ba1056ec-4875-480a-ae60-d136c00590f4', 'fc9df192-6313-4347-9317-8ee7b37952ba', '915e171c-905a-423a-9916-2aa388d6dc4b', '2021-09-28 10:46:05.253155+01', '2021-09-28 10:46:05.253155+01', '2021-09-10 10:00:00+01', '2021-12-10 09:00:00+00', '6BCDE6D', 'Jean Michel', '0643382134', 'michel@gmail.com', NULL);
INSERT INTO public.org_project_summary VALUES ('ba1056ec-4875-480a-ae60-d136c00590f5', 'fc9df192-6313-4347-9317-8ee7b37952ba', '915e171c-905a-423a-9916-2aa388d6dc5b', '2021-09-28 10:46:05.253155+01', '2021-09-28 10:46:05.253155+01', '2021-09-10 10:00:00+01', '2021-12-10 09:00:00+00', '2BCDE8D', 'Jean Michel', '0643382134', 'michel@gmail.com', NULL);
INSERT INTO public.org_project_summary VALUES ('ba1056ec-4875-480a-ae60-d136c00590f6', 'fc9df192-6313-4347-9317-8ee7b37952ba', '915e171c-905a-423a-9916-2aa388d6dc6b', '2021-09-28 10:46:05.253155+01', '2021-09-28 10:46:05.253155+01', '2021-09-10 10:00:00+01', '2021-12-10 09:00:00+00', '0BCDE9D', 'Jean Michel', '0643382134', 'michel@gmail.com', NULL);
INSERT INTO public.org_project_summary VALUES ('ba1056ec-4875-480a-ae60-d136c00590f7', 'fc9df192-6313-4347-9317-8ee7b37953cb', '915e171c-905a-423a-9916-2aa388d6dc7c', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', '2021-09-10 10:00:00+01', '2021-12-10 09:00:00+00', '0BCDE9D', 'Jean Michel', '0643382134', 'michel@gmail.com', '2000000');
INSERT INTO public.org_project_summary VALUES ('ba1056ec-4875-480a-ae60-d136c00590f8', 'fc9df192-6313-4347-9317-8ee7b37953cc', '915e171c-905a-423a-9916-2aa388d6dc7c', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', '2022-07-10 10:00:00+01', '2022-10-10 10:00:00+01', 'AACDE9D', 'Jean Luc', '0643382135', 'other@gmail.com', '11000');
INSERT INTO public.org_project_summary VALUES ('6eef289c-55a8-4e6e-a48d-e3ad34a3a246', 'fc9df192-6313-4347-9317-8ee7b37952ba', '6eec8a9e-a3c4-4d75-9972-b18f4071e1fd', '2022-09-19 23:07:37.584+01', '2022-09-19 23:14:45.447279+01', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.org_project_summary VALUES ('99a1dfd1-9136-4479-9a95-fbd4712514dd', 'fc9df192-6313-4347-9317-8ee7b37952ba', '4385e95e-cc98-4712-86cf-4cfe0e88ecfc', '2022-09-19 23:07:04.163+01', '2022-09-19 23:15:35.249989+01', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.org_project_summary VALUES ('effa2daf-a715-4685-be02-ca5d61a17930', 'fc9df192-6313-4347-9317-8ee7b37952ba', 'ff5160d0-036c-42b5-88da-12b55b556afb', '2022-09-19 23:16:36.577+01', '2022-09-19 23:18:25.398199+01', '2022-09-23 05:00:00+01', NULL, 'DLN-008', 'Jean Michel', NULL, NULL, '23000');
INSERT INTO public.org_project_summary VALUES ('e9054bc2-ce6e-473e-b603-a30384b2eac0', 'fc9df192-6313-4347-9317-8ee7b37952ba', '3d1a6331-14c4-492d-8d9b-569853accd60', '2022-09-19 23:19:34.106+01', '2022-09-19 23:20:40.714202+01', '2022-09-19 05:00:00+01', NULL, 'ABCDEF', NULL, NULL, NULL, '235000');
INSERT INTO public.org_project_summary VALUES ('421d0875-7d28-44c3-ac10-b35ff790d8de', 'fc9df192-6313-4347-9317-8ee7b37952ba', '23d54a9c-2c62-4577-9752-3ffa765bba60', '2022-09-19 23:22:45.612+01', '2022-09-19 23:23:14.190223+01', '2022-09-09 05:00:00+01', '2023-02-24 04:00:00+00', 'AAAAAA', NULL, NULL, NULL, NULL);
INSERT INTO public.org_project_summary VALUES ('3072c6c9-3bcc-4d0b-9e60-eea531fe4900', 'fc9df192-6313-4347-9317-8ee7b37952ba', '13740224-b781-4e56-ae26-c1620f326701', '2022-09-19 23:23:55.682+01', '2022-09-19 23:24:44.507006+01', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.org_project_summary VALUES ('3af5c17c-ec0c-47f4-99c8-679e1663accd', 'fc9df192-6313-4347-9317-8ee7b37952ba', '5cff40ca-26bd-4220-b80b-346703077c93', '2022-09-19 23:25:42.833+01', '2022-09-19 23:26:07.622289+01', NULL, NULL, 'AAAAAF', NULL, NULL, NULL, '234567');
INSERT INTO public.org_project_summary VALUES ('1481b004-ac87-4a64-84cc-3c785c45bd66', 'fc9df192-6313-4347-9317-8ee7b37952ba', 'b4b9bc3c-105a-48c3-a33f-6ec8e1c90288', '2022-09-19 23:26:39.651+01', '2022-09-19 23:27:14.516496+01', '2022-09-09 05:00:00+01', '2023-09-08 05:00:00+01', 'DFD333', 'Jean Michel', NULL, NULL, '233333');


--
-- TOC entry 5256 (class 0 OID 261346)
-- Dependencies: 284
-- Data for Name: org_project_summary_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5257 (class 0 OID 261352)
-- Dependencies: 285
-- Data for Name: org_project_summary_to_project_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.org_project_summary_to_project_categories VALUES ('9140a625-97fe-4203-9d10-1a5a368c4f6e', '3a3a03f9-262c-45a9-8626-1c9198763794', 'ba1056ec-4875-480a-ae60-d136c00590f3', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 0);
INSERT INTO public.org_project_summary_to_project_categories VALUES ('d33b5f10-2d4d-43b2-94fd-53e9d5d87edf', '3a3a03f9-262c-45a9-8626-1c9198763796', 'ba1056ec-4875-480a-ae60-d136c00590f7', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 0);
INSERT INTO public.org_project_summary_to_project_categories VALUES ('6d4f6334-f294-40c4-a167-80d7029ee230', '3a3a03f9-262c-45a9-8626-1c9198763797', 'ba1056ec-4875-480a-ae60-d136c00590f7', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 0);
INSERT INTO public.org_project_summary_to_project_categories VALUES ('7529fbc5-f300-4563-87a9-a2f13acf1d01', '3a3a03f9-262c-45a9-8626-1c9198763798', 'ba1056ec-4875-480a-ae60-d136c00590f8', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 0);
INSERT INTO public.org_project_summary_to_project_categories VALUES ('d48c6464-23c4-41e9-a5e1-0982386aa648', 'cb88706b-5269-44fc-a4f8-0fc89700412f', '6eef289c-55a8-4e6e-a48d-e3ad34a3a246', '2022-09-19 23:14:45.456+01', '2022-09-19 23:14:45.456+01', 0);
INSERT INTO public.org_project_summary_to_project_categories VALUES ('49eed13e-2fd5-46e4-b500-5ca732c55f4d', '3a3a03f9-262c-45a9-8626-1c9198763795', '99a1dfd1-9136-4479-9a95-fbd4712514dd', '2022-09-19 23:15:35.26+01', '2022-09-19 23:15:35.26+01', 0);
INSERT INTO public.org_project_summary_to_project_categories VALUES ('fd9fee94-542e-4f33-a130-7209bfc31e11', '610831ad-de76-4279-96e5-da1e250b9d92', 'effa2daf-a715-4685-be02-ca5d61a17930', '2022-09-19 23:17:10.677+01', '2022-09-19 23:18:25.398199+01', 0);
INSERT INTO public.org_project_summary_to_project_categories VALUES ('2935d49e-af38-4407-b6b6-8ea28f077834', 'ab480fba-7f5b-4867-b2bf-a7fe40afe694', 'e9054bc2-ce6e-473e-b603-a30384b2eac0', '2022-09-19 23:20:40.72+01', '2022-09-19 23:20:40.72+01', 0);
INSERT INTO public.org_project_summary_to_project_categories VALUES ('a7b53f6b-20c7-467d-b75c-a024c8a02924', '35cbd4bd-9d59-4dec-a325-29c0168cd8f0', '421d0875-7d28-44c3-ac10-b35ff790d8de', '2022-09-19 23:23:14.197+01', '2022-09-19 23:23:14.198+01', 0);
INSERT INTO public.org_project_summary_to_project_categories VALUES ('9116452f-5739-44cd-b245-9f91dee276b3', 'cf2c420b-6b6a-40e6-b44b-d5bc0f723432', '3072c6c9-3bcc-4d0b-9e60-eea531fe4900', '2022-09-19 23:24:44.512+01', '2022-09-19 23:24:44.512+01', 0);
INSERT INTO public.org_project_summary_to_project_categories VALUES ('7b7d194d-c0b9-49ba-a6eb-614c95de481d', 'cb88706b-5269-44fc-a4f8-0fc89700412f', '3af5c17c-ec0c-47f4-99c8-679e1663accd', '2022-09-19 23:26:07.629+01', '2022-09-19 23:26:07.629+01', 0);
INSERT INTO public.org_project_summary_to_project_categories VALUES ('25e462bd-2a89-4ca2-8555-c965de9950e9', '628dce46-9228-46e8-b13a-d98711e10930', '1481b004-ac87-4a64-84cc-3c785c45bd66', '2022-09-19 23:27:14.523+01', '2022-09-19 23:27:14.523+01', 0);


--
-- TOC entry 5258 (class 0 OID 261359)
-- Dependencies: 286
-- Data for Name: org_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.org_roles VALUES ('owner', 1000);
INSERT INTO public.org_roles VALUES ('administrator', 900);
INSERT INTO public.org_roles VALUES ('standard', 800);
INSERT INTO public.org_roles VALUES ('limited', 700);
INSERT INTO public.org_roles VALUES ('disabled', 600);
INSERT INTO public.org_roles VALUES ('readonly', 650);


--
-- TOC entry 5188 (class 0 OID 260765)
-- Dependencies: 215
-- Data for Name: orgs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.orgs VALUES ('fc9df192-6313-4347-9317-8ee7b37952ba', '2021-04-22 16:42:35.65106+01', '2021-04-22 16:42:35.65106+01', 'clovis', 'best start-up in junk food', '83491918500050', '+33 6.37.38.06.47', 'dd720212-8b16-4a68-ac01-2728dc9482a4');
INSERT INTO public.orgs VALUES ('fc9df192-6313-4347-9317-8ee7b37953ba', '2021-04-22 16:42:35.65106+01', '2021-04-22 16:42:35.65106+01', 'google', 'best search engine', '83491918500051', '+33 6.37.38.06.48', '52eec533-137e-4a1e-8519-5eaaec62219e');
INSERT INTO public.orgs VALUES ('fc9df192-6313-4347-9317-8ee7b37953cb', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'Dummy corporation', 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book', '83491918500051', '+33 6.37.38.06.48', '5720f0a7-3a09-409e-bce0-b2d4359c4e4a');
INSERT INTO public.orgs VALUES ('fc9df192-6313-4347-9317-8ee7b37953cc', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'Dummy corporation 2', 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book', '83491918500052', '+33 6.37.38.06.49', '3c53c1f5-2959-4b8b-9fc5-3e095a695cbb');
INSERT INTO public.orgs VALUES ('fc9df192-6313-4347-9317-8ee7b37953cd', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'Dummy corporation 3', 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book', '83491918500053', '+33 6.37.38.06.50', 'bd0ffe82-78f6-4c92-8623-bb06c9897a93');


--
-- TOC entry 5262 (class 0 OID 261384)
-- Dependencies: 290
-- Data for Name: orgs_to_user_actions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.orgs_to_user_actions VALUES ('dfbd9954-b558-4559-b3a6-2ec90e4a4169', '2021-08-28 09:46:10.35+01', '2021-08-28 09:46:10.35+01', 'fc9df192-6313-4347-9317-8ee7b37952ba', '2cd9aa8b-e78a-4570-a4fc-a34004cc298e');


--
-- TOC entry 5259 (class 0 OID 261364)
-- Dependencies: 287
-- Data for Name: orgs_to_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.orgs_to_users VALUES ('b091eda9-e766-46b5-914f-d34940d2267e', '2021-04-22 16:47:02.681682+01', '2021-04-22 16:47:02.681682+01', 'fc9df192-6313-4347-9317-8ee7b37952ba', NULL, 'owner', NULL);
INSERT INTO public.orgs_to_users VALUES ('86c8c162-3405-457c-9724-727aea142580', '2021-04-22 18:43:54.235015+01', '2021-04-22 19:08:41.093706+01', 'fc9df192-6313-4347-9317-8ee7b37952ba', 'b091eda9-e766-46b5-914f-d34940d2267e', 'administrator', NULL);
INSERT INTO public.orgs_to_users VALUES ('033af847-bded-487c-9228-5f7c5af19ac6', '2021-04-23 15:22:58.687959+01', '2021-04-23 15:22:58.687959+01', 'fc9df192-6313-4347-9317-8ee7b37952ba', 'b091eda9-e766-46b5-914f-d34940d2267e', 'standard', NULL);
INSERT INTO public.orgs_to_users VALUES ('2c301925-1afd-461b-a5c2-d7930596845d', '2021-04-23 15:23:16.682889+01', '2021-04-23 15:23:16.682889+01', 'fc9df192-6313-4347-9317-8ee7b37952ba', 'b091eda9-e766-46b5-914f-d34940d2267e', 'limited', NULL);
INSERT INTO public.orgs_to_users VALUES ('b03640d8-a9b9-46d9-8df3-8b0ba204540f', '2021-04-23 15:23:30.792787+01', '2021-04-23 15:23:30.792787+01', 'fc9df192-6313-4347-9317-8ee7b37952ba', 'b091eda9-e766-46b5-914f-d34940d2267e', 'disabled', NULL);
INSERT INTO public.orgs_to_users VALUES ('a76a395c-7f16-45d0-b748-8f726134e492', '2021-04-23 15:23:47.350332+01', '2021-04-23 15:23:47.350332+01', 'fc9df192-6313-4347-9317-8ee7b37952ba', 'b091eda9-e766-46b5-914f-d34940d2267e', 'disabled', NULL);
INSERT INTO public.orgs_to_users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a119e', '2021-04-23 15:23:47.350332+01', '2021-04-23 15:23:47.350332+01', 'fc9df192-6313-4347-9317-8ee7b37953ba', 'b091eda9-e766-46b5-914f-d34940d2267e', 'owner', NULL);
INSERT INTO public.orgs_to_users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a120e', '2021-04-23 15:23:47.350332+01', '2021-04-23 15:23:47.350332+01', 'fc9df192-6313-4347-9317-8ee7b37953ba', 'b091eda9-e766-46b5-914f-d34940d2267e', 'owner', NULL);
INSERT INTO public.orgs_to_users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a129e', '2021-04-23 15:23:47.350332+01', '2021-04-23 15:23:47.350332+01', 'fc9df192-6313-4347-9317-8ee7b37953ba', 'b091eda9-e766-46b5-914f-d34940d2267e', 'standard', NULL);
INSERT INTO public.orgs_to_users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a639e', '2021-04-23 15:23:47.350332+01', '2021-04-23 15:23:47.350332+01', 'fc9df192-6313-4347-9317-8ee7b37953ba', 'b091eda9-e766-46b5-914f-d34940d2267e', 'limited', NULL);
INSERT INTO public.orgs_to_users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a139e', '2021-04-23 15:23:47.350332+01', '2021-04-23 15:23:47.350332+01', 'fc9df192-6313-4347-9317-8ee7b37953ba', 'b091eda9-e766-46b5-914f-d34940d2267e', 'limited', NULL);
INSERT INTO public.orgs_to_users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a149e', '2021-04-23 15:23:47.350332+01', '2021-04-23 15:23:47.350332+01', 'fc9df192-6313-4347-9317-8ee7b37953ba', 'b091eda9-e766-46b5-914f-d34940d2267e', 'disabled', NULL);
INSERT INTO public.orgs_to_users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a159e', '2021-04-23 15:23:47.350332+01', '2021-04-23 15:23:47.350332+01', 'fc9df192-6313-4347-9317-8ee7b37953ba', 'b091eda9-e766-46b5-914f-d34940d2267e', 'administrator', NULL);
INSERT INTO public.orgs_to_users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a2357', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'fc9df192-6313-4347-9317-8ee7b37953cb', NULL, 'owner', NULL);
INSERT INTO public.orgs_to_users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a2358', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'fc9df192-6313-4347-9317-8ee7b37953cc', NULL, 'owner', NULL);
INSERT INTO public.orgs_to_users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a2359', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'fc9df192-6313-4347-9317-8ee7b37953cd', NULL, 'owner', NULL);


--
-- TOC entry 5263 (class 0 OID 261390)
-- Dependencies: 291
-- Data for Name: presigned_urls; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5264 (class 0 OID 261395)
-- Dependencies: 292
-- Data for Name: project_address; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.project_address VALUES ('7b450b00-c9b5-4332-b087-46af26e8a525', '2021-06-11 09:57:07.969993+01', '2021-06-11 09:57:07.969993+01', '26 Rue des Quatre Fils', '75003', NULL, NULL, 'France', 'Paris', 48.86090720160398, 2.3584584576171697);
INSERT INTO public.project_address VALUES ('915e171c-905a-423a-9916-2aa388d6dc4b', '2021-06-11 09:57:07.969993+01', '2021-06-11 09:57:07.969993+01', '6 Parvis Notre-Dame', '75004', NULL, NULL, 'France', 'Paris', 48.85307407175399, 2.349880640407116);
INSERT INTO public.project_address VALUES ('915e171c-905a-423a-9916-2aa388d6dc5b', '2021-06-11 09:57:07.969993+01', '2021-06-11 09:57:07.969993+01', '1600 Amphitheatre Parkway', '94043', NULL, NULL, 'United-States', 'Montain View', 37.421604483704805, -122.08396516630647);
INSERT INTO public.project_address VALUES ('915e171c-905a-423a-9916-2aa388d6dc7c', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 'Pl. de la Bastille', '75004', '1 Av. du Colonel Henri Rol-Tanguy, 75014 Paris, France', '47 Rue des Couronnes, 75020 Paris, France', 'France', 'Paris', 48.8531861, 2.3691305);
INSERT INTO public.project_address VALUES ('4385e95e-cc98-4712-86cf-4cfe0e88ecfc', '2022-09-19 23:07:26.505+01', '2022-09-19 23:16:13.2335+01', NULL, NULL, NULL, NULL, NULL, NULL, 48.8463076819117, 2.357407344720448);
INSERT INTO public.project_address VALUES ('6eec8a9e-a3c4-4d75-9972-b18f4071e1fd', '2022-09-19 23:08:19.276+01', '2022-09-19 23:16:24.860504+01', NULL, NULL, NULL, NULL, NULL, NULL, 48.85556575685846, 2.365451895953363);
INSERT INTO public.project_address VALUES ('ff5160d0-036c-42b5-88da-12b55b556afb', '2022-09-19 23:19:01.5+01', '2022-09-19 23:19:01.5+01', NULL, NULL, NULL, NULL, NULL, NULL, 48.86013539339918, 2.258532096964054);
INSERT INTO public.project_address VALUES ('3d1a6331-14c4-492d-8d9b-569853accd60', '2022-09-19 23:21:20.47+01', '2022-09-19 23:21:20.47+01', NULL, NULL, NULL, NULL, NULL, NULL, 48.83121057721894, 2.300226606773386);
INSERT INTO public.project_address VALUES ('23d54a9c-2c62-4577-9752-3ffa765bba60', '2022-09-19 23:23:26.921+01', '2022-09-19 23:23:26.921+01', NULL, NULL, NULL, NULL, NULL, NULL, 48.8913384022803, 2.433511901391068);
INSERT INTO public.project_address VALUES ('13740224-b781-4e56-ae26-c1620f326701', '2022-09-19 23:24:12.131+01', '2022-09-19 23:25:33.477721+01', '', NULL, NULL, NULL, NULL, NULL, 48.79038802052885, 2.402678316842044);
INSERT INTO public.project_address VALUES ('5cff40ca-26bd-4220-b80b-346703077c93', '2022-09-19 23:26:27.028+01', '2022-09-19 23:26:27.028+01', NULL, NULL, NULL, NULL, NULL, NULL, 48.82387032690749, 2.276661301079859);
INSERT INTO public.project_address VALUES ('b4b9bc3c-105a-48c3-a33f-6ec8e1c90288', '2022-09-19 23:27:22.941+01', '2022-09-19 23:27:22.941+01', '5 Place de l''Opéra', '75009', NULL, NULL, 'France', 'Paris', 48.8709439, 2.3295493);


--
-- TOC entry 5265 (class 0 OID 261402)
-- Dependencies: 293
-- Data for Name: project_avatars; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.project_avatars VALUES ('2021-09-09 18:26:39.034496+01', '2021-09-09 18:26:39.034496+01', '7b450b00-c9b5-4332-b087-46af26e8a525', 'project_avatar.jpg', 'projectAvatar', 'image/jpeg', 'jpg', 3123);
INSERT INTO public.project_avatars VALUES ('2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', '915e171c-905a-423a-9916-2aa388d6dc7c', 'project_avatar.jpg', 'projectAvatar', 'image/jpeg', 'jpg', 3123);
INSERT INTO public.project_avatars VALUES ('2021-09-09 18:26:39.034496+01', '2021-09-09 18:26:39.034496+01', 'dd720212-8b16-4a68-ac01-2728dc9482a4', 'org_avatar.jpg', 'orgAvatar', 'image/jpeg', 'jpg', 3123);
INSERT INTO public.project_avatars VALUES ('2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '52eec533-137e-4a1e-8519-5eaaec62219e', 'org_avatar.jpg', 'orgAvatar', 'image/jpeg', 'jpg', 3123);


--
-- TOC entry 5266 (class 0 OID 261409)
-- Dependencies: 294
-- Data for Name: project_backgrounds; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.project_backgrounds VALUES ('2021-09-09 18:26:39.034496+01', '2021-09-09 18:26:39.034496+01', '7b450b00-c9b5-4332-b087-46af26e8a525', 'project_background.jpg', 'projectBackground', 'image/jpeg', 'jpg', 3123);
INSERT INTO public.project_backgrounds VALUES ('2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '915e171c-905a-423a-9916-2aa388d6dc7c', 'project_background.jpg', 'projectBackground', 'image/jpeg', 'jpg', 3123);
INSERT INTO public.project_backgrounds VALUES ('2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '52eec533-137e-4a1e-8519-5eaaec62219e', 'org_background.jpg', 'orgBackground', 'image/jpeg', 'jpg', 3123);


--
-- TOC entry 5267 (class 0 OID 261416)
-- Dependencies: 295
-- Data for Name: project_banners; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.project_banners VALUES ('2021-09-09 18:26:39.034496+01', '2021-09-09 18:26:39.034496+01', '7b450b00-c9b5-4332-b087-46af26e8a525', 'project_banner.jpg', 'projectBanner', 'image/jpeg', 'jpg', 3123);
INSERT INTO public.project_banners VALUES ('2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '915e171c-905a-423a-9916-2aa388d6dc7c', 'project_banner.jpg', 'projectBanner', 'image/jpeg', 'jpg', 3123);
INSERT INTO public.project_banners VALUES ('2021-09-09 18:26:39.034496+01', '2021-09-09 18:26:39.034496+01', 'dd720212-8b16-4a68-ac01-2728dc9482a4', 'org_background.jpg', 'orgBackground', 'image/jpeg', 'jpg', 3123);


--
-- TOC entry 5268 (class 0 OID 261423)
-- Dependencies: 296
-- Data for Name: project_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.project_categories VALUES ('3a3a03f9-262c-45a9-8626-1c9198763794', '2021-06-23 13:23:45.212496+01', '2021-06-23 13:23:45.212496+01', 'Wooden building', 'yellow', 'fc9df192-6313-4347-9317-8ee7b37952ba');
INSERT INTO public.project_categories VALUES ('3a3a03f9-262c-45a9-8626-1c9198763795', '2021-06-23 13:23:45.212496+01', '2021-06-23 13:23:45.212496+01', 'Steel building', 'red', 'fc9df192-6313-4347-9317-8ee7b37952ba');
INSERT INTO public.project_categories VALUES ('3a3a03f9-262c-45a9-8626-1c9198763796', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 'Steel building', 'emerald', 'fc9df192-6313-4347-9317-8ee7b37953cb');
INSERT INTO public.project_categories VALUES ('3a3a03f9-262c-45a9-8626-1c9198763797', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 'Downtown', 'teal', 'fc9df192-6313-4347-9317-8ee7b37953cb');
INSERT INTO public.project_categories VALUES ('3a3a03f9-262c-45a9-8626-1c9198763798', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 'Collaboration', 'dark', 'fc9df192-6313-4347-9317-8ee7b37953cc');
INSERT INTO public.project_categories VALUES ('628dce46-9228-46e8-b13a-d98711e10930', '2022-09-19 23:08:50.194+01', '2022-09-19 23:08:50.194+01', 'Tin building', 'gray', 'fc9df192-6313-4347-9317-8ee7b37952ba');
INSERT INTO public.project_categories VALUES ('cb88706b-5269-44fc-a4f8-0fc89700412f', '2022-09-19 23:10:02.327+01', '2022-09-19 23:10:02.327+01', 'Crystal work', 'cyan', 'fc9df192-6313-4347-9317-8ee7b37952ba');
INSERT INTO public.project_categories VALUES ('ab480fba-7f5b-4867-b2bf-a7fe40afe694', '2022-09-19 23:11:20.985+01', '2022-09-19 23:11:20.985+01', 'Atomic plant', 'green', 'fc9df192-6313-4347-9317-8ee7b37952ba');
INSERT INTO public.project_categories VALUES ('35cbd4bd-9d59-4dec-a325-29c0168cd8f0', '2022-09-19 23:12:18.501+01', '2022-09-19 23:12:18.501+01', 'Restauration', 'violet', 'fc9df192-6313-4347-9317-8ee7b37952ba');
INSERT INTO public.project_categories VALUES ('cf2c420b-6b6a-40e6-b44b-d5bc0f723432', '2022-09-19 23:13:55.754+01', '2022-09-19 23:14:16.649095+01', 'Factory', 'brown', 'fc9df192-6313-4347-9317-8ee7b37952ba');
INSERT INTO public.project_categories VALUES ('610831ad-de76-4279-96e5-da1e250b9d92', '2022-09-19 23:16:58.892+01', '2022-09-19 23:16:58.892+01', 'High voltage', 'amber', 'fc9df192-6313-4347-9317-8ee7b37952ba');


--
-- TOC entry 5269 (class 0 OID 261431)
-- Dependencies: 297
-- Data for Name: project_categories_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5270 (class 0 OID 261437)
-- Dependencies: 298
-- Data for Name: project_labels; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.project_labels VALUES ('3a3a03f9-262c-45a9-8626-1c9098763783', '2021-06-23 13:23:45.212496+01', '2021-06-23 13:23:45.212496+01', 'To treat in the future', 'red', '7b450b00-c9b5-4332-b087-46af26e8a525', NULL);
INSERT INTO public.project_labels VALUES ('6c5b3e37-3ae8-4d68-ad55-2d5adfa3b469', '2021-10-06 09:48:51.036856+01', '2021-10-06 09:48:51.036856+01', 'isolate', 'brown', '7b450b00-c9b5-4332-b087-46af26e8a525', NULL);
INSERT INTO public.project_labels VALUES ('0af4ecd8-c41d-4c26-84e3-34fdb4987984', '2021-10-06 09:47:38.933074+01', '2021-11-18 10:38:48.602795+00', 'electricity', 'yellow', '7b450b00-c9b5-4332-b087-46af26e8a525', NULL);
INSERT INTO public.project_labels VALUES ('0a57ca89-07f4-4372-b3a8-ed8b5ba52ba4', '2021-10-06 09:48:03.931477+01', '2021-11-18 10:39:08.478145+00', 'plumbing', 'emerald', '7b450b00-c9b5-4332-b087-46af26e8a525', NULL);
INSERT INTO public.project_labels VALUES ('ee092eaa-386f-48e7-9763-0c61f044526b', '2021-10-06 09:48:16.221699+01', '2021-11-18 10:39:31.485722+00', 'carpentry', 'sky', '7b450b00-c9b5-4332-b087-46af26e8a525', NULL);
INSERT INTO public.project_labels VALUES ('85a4e5b3-c2b0-422d-a4fd-165eba78e40c', '2021-11-18 10:43:16.138+00', '2021-11-18 10:43:16.138+00', 'apartment 1', 'purple', '7b450b00-c9b5-4332-b087-46af26e8a525', NULL);
INSERT INTO public.project_labels VALUES ('6fb1b881-8ffb-4e81-9f39-b5fa0d94b1e6', '2021-11-18 10:50:24.303+00', '2021-11-18 10:50:24.303+00', 'removal of reservations', 'dark', '7b450b00-c9b5-4332-b087-46af26e8a525', NULL);
INSERT INTO public.project_labels VALUES ('98e3a17c-4b30-4ed1-87b7-04246d812866', '2021-11-18 10:53:06.838+00', '2021-11-18 10:53:06.838+00', 'stonework', 'rose', '7b450b00-c9b5-4332-b087-46af26e8a525', NULL);
INSERT INTO public.project_labels VALUES ('98e3a17c-4b30-4ed1-87b7-04246d812870', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'electricity', 'yellow', '915e171c-905a-423a-9916-2aa388d6dc7c', 1);
INSERT INTO public.project_labels VALUES ('98e3a17c-4b30-4ed1-87b7-04246d812871', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'plumbing', 'emerald', '915e171c-905a-423a-9916-2aa388d6dc7c', 2);
INSERT INTO public.project_labels VALUES ('98e3a17c-4b30-4ed1-87b7-04246d812872', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'carpentry', 'sky', '915e171c-905a-423a-9916-2aa388d6dc7c', 3);


--
-- TOC entry 5271 (class 0 OID 261445)
-- Dependencies: 299
-- Data for Name: project_labels_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5272 (class 0 OID 261451)
-- Dependencies: 300
-- Data for Name: project_member_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5273 (class 0 OID 261457)
-- Dependencies: 301
-- Data for Name: project_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5274 (class 0 OID 261463)
-- Dependencies: 302
-- Data for Name: project_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.project_roles VALUES ('owner', 1000);
INSERT INTO public.project_roles VALUES ('administrator', 900);
INSERT INTO public.project_roles VALUES ('standard', 800);
INSERT INTO public.project_roles VALUES ('limited', 700);
INSERT INTO public.project_roles VALUES ('disabled', 600);
INSERT INTO public.project_roles VALUES ('readonly', 650);


--
-- TOC entry 5275 (class 0 OID 261468)
-- Dependencies: 303
-- Data for Name: project_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.project_templates VALUES ('fd130e34-18b4-427f-abb0-a27f4dc61f1b', '2022-12-14 16:42:13.365734+00', '2022-12-14 16:42:13.365734+00', 'b4b9bc3c-105a-48c3-a33f-6ec8e1c90288', 'generic', 'en');


--
-- TOC entry 5276 (class 0 OID 261482)
-- Dependencies: 305
-- Data for Name: project_views; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5197 (class 0 OID 260867)
-- Dependencies: 224
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.projects VALUES ('7b450b00-c9b5-4332-b087-46af26e8a525', '2021-04-28 09:55:17.146171+01', '2021-04-28 09:55:17.146171+01', 'Tour Eiffel', '{"time":1669985455227,"blocks":[{"id":"bh0V5W4n1M","type":"paragraph","data":{"text":"La tour s''inscrit dans un carré de 125 mètres de côté, selon les termes mêmes du concours de 1886. Haute de 324 mètres avec ses 116 antennes, elle est située à 33,5 mètres au-dessus du niveau de la mer."}}],"version":"2.22.2"}', false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('915e171c-905a-423a-9916-2aa388d6dc4b', '2021-04-29 10:55:17.146171+01', '2021-04-29 10:55:17.146171+01', 'Notre-Dame de Paris', NULL, false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('915e171c-905a-423a-9916-2aa388d6dc5b', '2021-04-29 10:55:17.146171+01', '2021-04-29 10:55:17.146171+01', 'Google Search Engine', NULL, false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('915e171c-905a-423a-9916-2aa388d6dc6b', '2021-04-29 10:55:17.146171+01', '2021-04-29 10:55:17.146171+01', 'Google Image Engine', NULL, false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('915e171c-905a-423a-9916-2aa388d6dc7b', '2021-04-29 10:55:17.146171+01', '2021-04-29 10:55:17.146171+01', 'Test file approval', 'Export', false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('915e171c-905a-423a-9916-2aa388d6dc7c', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 'Dummy project', '
  New project
  3 orgs
  3 teams
  3 users
  with full information and long first name and long last name
  without avatar
  with minimum information
  4 tasks
  with full information
  assignees (3 users, 3 teams, 3 org)
  location
  picture attachment
  file attachment
  chat text (3 users)
  chat image (3 users)
  chat document (3 users)
  without chat
  without chat and attachment
  with minimum information
  1 document
  located task 1 on page 1
  located task 2 on page 1
  located task 3 on page 2', false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('4385e95e-cc98-4712-86cf-4cfe0e88ecfc', '2022-09-19 23:07:04.163+01', '2022-09-19 23:16:13.228241+01', 'Empty 1', NULL, false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('6eec8a9e-a3c4-4d75-9972-b18f4071e1fd', '2022-09-19 23:07:37.583+01', '2022-09-19 23:16:24.855259+01', 'Empty 2', NULL, false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('ff5160d0-036c-42b5-88da-12b55b556afb', '2022-09-19 23:16:36.577+01', '2022-09-19 23:19:01.49554+01', 'Empty 3', NULL, false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('3d1a6331-14c4-492d-8d9b-569853accd60', '2022-09-19 23:19:34.106+01', '2022-09-19 23:21:20.465112+01', 'Empty 4', NULL, false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('23d54a9c-2c62-4577-9752-3ffa765bba60', '2022-09-19 23:22:45.612+01', '2022-09-19 23:23:26.916619+01', 'Empty 6', NULL, false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('13740224-b781-4e56-ae26-c1620f326701', '2022-09-19 23:23:55.682+01', '2022-09-19 23:25:33.474119+01', 'Empty 7', NULL, false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('5cff40ca-26bd-4220-b80b-346703077c93', '2022-09-19 23:25:42.833+01', '2022-09-19 23:26:27.022819+01', 'Empty 8', NULL, false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('b4b9bc3c-105a-48c3-a33f-6ec8e1c90288', '2022-09-19 23:26:39.651+01', '2022-09-19 23:27:22.938338+01', 'Demo project', NULL, false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('dd720212-8b16-4a68-ac01-2728dc9482a4', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'clovis', 'best start-up in junk food', false, false, NULL, 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.projects VALUES ('52eec533-137e-4a1e-8519-5eaaec62219e', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'google', 'best search engine', false, false, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a119e');
INSERT INTO public.projects VALUES ('5720f0a7-3a09-409e-bce0-b2d4359c4e4a', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'Dummy corporation', 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book', false, false, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a2357');
INSERT INTO public.projects VALUES ('3c53c1f5-2959-4b8b-9fc5-3e095a695cbb', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'Dummy corporation 2', 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book', false, false, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a2358');
INSERT INTO public.projects VALUES ('bd0ffe82-78f6-4c92-8623-bb06c9897a93', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'Dummy corporation 3', 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book', false, false, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a2359');


--
-- TOC entry 5260 (class 0 OID 261371)
-- Dependencies: 288
-- Data for Name: projects_to_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.projects_to_users VALUES ('fb87fe4a-4ff4-484b-8cdc-f8fda76a827d', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL, '7b450b00-c9b5-4332-b087-46af26e8a525', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('fb87fe4a-4ff4-484b-8cdc-f8fda76a828d', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', '86c8c162-3405-457c-9724-727aea142580', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', 'administrator', NULL);
INSERT INTO public.projects_to_users VALUES ('fb87fe4a-4ff4-484b-8cdc-f8fda76a829d', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', '033af847-bded-487c-9228-5f7c5af19ac6', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', 'standard', NULL);
INSERT INTO public.projects_to_users VALUES ('fb87fe4a-4ff4-484b-8cdc-f8fda76a82ad', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', '2c301925-1afd-461b-a5c2-d7930596845d', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', 'standard', NULL);
INSERT INTO public.projects_to_users VALUES ('fb87fe4a-4ff4-484b-8cdc-f8fda76a82bd', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', 'b03640d8-a9b9-46d9-8df3-8b0ba204540f', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', 'standard', NULL);
INSERT INTO public.projects_to_users VALUES ('fb87fe4a-4ff4-484b-8cdc-f8fda76a82cd', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', 'a76a395c-7f16-45d0-b748-8f726134e492', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', 'standard', NULL);
INSERT INTO public.projects_to_users VALUES ('fb87fe4a-4ff4-484b-8cdc-f8fda76a82dd', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', '6272c659-9cc9-4125-a91d-b32046e23101', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', 'standard', NULL);
INSERT INTO public.projects_to_users VALUES ('fb87fe4a-4ff4-484b-8cdc-f8fda76a82ed', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', 'a7e70da0-bb65-4e30-b6f5-a86f983a109e', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', 'limited', NULL);
INSERT INTO public.projects_to_users VALUES ('fb87fe4a-4ff4-484b-8cdc-f9fde76a820d', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', 'a7e70da0-bb65-4e30-b6f5-a86f983a119e', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', 'limited', NULL);
INSERT INTO public.projects_to_users VALUES ('d57969e4-c90d-4420-adea-bb5d138ed34b', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', '2c301925-1afd-461b-a5c2-d7930596845d', 'b091eda9-e766-46b5-914f-d34940d2267e', '915e171c-905a-423a-9916-2aa388d6dc4b', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('961f86d4-0c5b-4e12-9409-7513889874a5', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', 'b091eda9-e766-46b5-914f-d34940d2267e', 'b091eda9-e766-46b5-914f-d34940d2267e', '915e171c-905a-423a-9916-2aa388d6dc4b', 'limited', NULL);
INSERT INTO public.projects_to_users VALUES ('67060faf-c3bd-4580-b8dc-5fc699ffcebb', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', 'a7e70da0-bb65-4e30-b6f5-a86f983a109e', 'b091eda9-e766-46b5-914f-d34940d2267e', '915e171c-905a-423a-9916-2aa388d6dc4b', 'standard', NULL);
INSERT INTO public.projects_to_users VALUES ('67060faf-c3bd-4580-b8dc-5fc699ffceba', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', 'a7e70da0-bb65-4e30-b6f5-a86f983a120e', 'b091eda9-e766-46b5-914f-d34940d2267e', '915e171c-905a-423a-9916-2aa388d6dc5b', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('67060faf-c3bd-4580-b8dc-6fc699ffceba', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', 'a7e70da0-bb65-4e30-b6f5-a86f983a139e', 'b091eda9-e766-46b5-914f-d34940d2267e', '915e171c-905a-423a-9916-2aa388d6dc6b', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('67060faf-c3bd-4580-b8dc-6fc699ffcebb', '2021-04-28 10:02:02.567219+01', '2021-04-28 10:02:02.567219+01', 'a7e70da0-bb65-4e30-b6f5-a86f983a2346', 'b091eda9-e766-46b5-914f-d34940d2267e', '915e171c-905a-423a-9916-2aa388d6dc6b', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('16e75552-a880-484a-9703-67e4c98ff3d1', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL, '915e171c-905a-423a-9916-2aa388d6dc7b', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('6c371a02-992b-4aeb-9a27-489726661f55', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', '86c8c162-3405-457c-9724-727aea142580', 'b091eda9-e766-46b5-914f-d34940d2267e', '915e171c-905a-423a-9916-2aa388d6dc7b', 'administrator', NULL);
INSERT INTO public.projects_to_users VALUES ('3af89bbc-faa5-4d36-b1af-6fe965916e04', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', '033af847-bded-487c-9228-5f7c5af19ac6', 'b091eda9-e766-46b5-914f-d34940d2267e', '915e171c-905a-423a-9916-2aa388d6dc7b', 'standard', NULL);
INSERT INTO public.projects_to_users VALUES ('c20a4741-4e06-4718-bb0d-bc8b6400ed7a', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', '2c301925-1afd-461b-a5c2-d7930596845d', 'b091eda9-e766-46b5-914f-d34940d2267e', '915e171c-905a-423a-9916-2aa388d6dc7b', 'standard', NULL);
INSERT INTO public.projects_to_users VALUES ('ecacbf3f-20a7-4e3a-83b7-d13c8ad8e3d9', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 'b03640d8-a9b9-46d9-8df3-8b0ba204540f', 'b091eda9-e766-46b5-914f-d34940d2267e', '915e171c-905a-423a-9916-2aa388d6dc7b', 'standard', NULL);
INSERT INTO public.projects_to_users VALUES ('90cedcb9-9ff4-4cff-a5b3-63b68fe46970', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 'a76a395c-7f16-45d0-b748-8f726134e492', 'b091eda9-e766-46b5-914f-d34940d2267e', '915e171c-905a-423a-9916-2aa388d6dc7b', 'limited', NULL);
INSERT INTO public.projects_to_users VALUES ('ea55601e-7a43-44a3-83d1-3083878d423e', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', NULL, '915e171c-905a-423a-9916-2aa388d6dc7c', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('a1414ab7-9281-482c-9748-c298a846bcaa', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 'a7e70da0-bb65-4e30-b6f5-a86f983a2358', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', '915e171c-905a-423a-9916-2aa388d6dc7c', 'standard', NULL);
INSERT INTO public.projects_to_users VALUES ('bd6233bc-d9c5-42bf-9973-879fc15db8a0', '2022-09-19 23:06:13.586612+01', '2022-09-19 23:06:13.586612+01', 'a7e70da0-bb65-4e30-b6f5-a86f983a2359', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', '915e171c-905a-423a-9916-2aa388d6dc7c', 'limited', NULL);
INSERT INTO public.projects_to_users VALUES ('1c4e655a-14cd-400e-b98b-e5a10b9844fa', '2022-09-19 23:07:04.163+01', '2022-09-19 23:07:04.163+01', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL, '4385e95e-cc98-4712-86cf-4cfe0e88ecfc', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('9bcde7f0-c515-496f-80c9-8a60febe8b2b', '2022-09-19 23:07:37.584+01', '2022-09-19 23:07:37.584+01', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL, '6eec8a9e-a3c4-4d75-9972-b18f4071e1fd', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('aaa36d03-3718-4be2-aba5-45e41c14403d', '2022-09-19 23:16:36.578+01', '2022-09-19 23:16:36.578+01', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL, 'ff5160d0-036c-42b5-88da-12b55b556afb', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('8b485589-dd8e-4beb-a54b-a9be5325fef5', '2022-09-19 23:19:34.106+01', '2022-09-19 23:19:34.106+01', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL, '3d1a6331-14c4-492d-8d9b-569853accd60', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('03d0181a-7864-4a55-999e-e7a0a5495602', '2022-09-19 23:22:45.612+01', '2022-09-19 23:22:45.612+01', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL, '23d54a9c-2c62-4577-9752-3ffa765bba60', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('f69226e7-3fbe-48e4-a677-af79bc3f1a92', '2022-09-19 23:23:55.682+01', '2022-09-19 23:23:55.682+01', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL, '13740224-b781-4e56-ae26-c1620f326701', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('60052d85-8fc0-42a9-b123-ac3aaaae6fe2', '2022-09-19 23:25:42.834+01', '2022-09-19 23:25:42.834+01', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL, '5cff40ca-26bd-4220-b80b-346703077c93', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4808', '2022-09-19 23:26:39.651+01', '2022-09-19 23:26:39.651+01', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL, 'b4b9bc3c-105a-48c3-a33f-6ec8e1c90288', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4818', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL, 'dd720212-8b16-4a68-ac01-2728dc9482a4', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4828', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '86c8c162-3405-457c-9724-727aea142580', NULL, 'dd720212-8b16-4a68-ac01-2728dc9482a4', 'administrator', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4838', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '033af847-bded-487c-9228-5f7c5af19ac6', NULL, 'dd720212-8b16-4a68-ac01-2728dc9482a4', 'standard', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4848', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '2c301925-1afd-461b-a5c2-d7930596845d', NULL, 'dd720212-8b16-4a68-ac01-2728dc9482a4', 'limited', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4858', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b03640d8-a9b9-46d9-8df3-8b0ba204540f', NULL, 'dd720212-8b16-4a68-ac01-2728dc9482a4', 'disabled', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4868', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a76a395c-7f16-45d0-b748-8f726134e492', NULL, 'dd720212-8b16-4a68-ac01-2728dc9482a4', 'disabled', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4878', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a119e', NULL, '52eec533-137e-4a1e-8519-5eaaec62219e', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4888', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a120e', NULL, '52eec533-137e-4a1e-8519-5eaaec62219e', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4898', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a129e', NULL, '52eec533-137e-4a1e-8519-5eaaec62219e', 'standard', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4819', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a639e', NULL, '52eec533-137e-4a1e-8519-5eaaec62219e', 'limited', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4829', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a139e', NULL, '52eec533-137e-4a1e-8519-5eaaec62219e', 'limited', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4839', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a149e', NULL, '52eec533-137e-4a1e-8519-5eaaec62219e', 'disabled', NULL);
INSERT INTO public.projects_to_users VALUES ('d7bd78ba-8f1c-4f25-ba09-16b9798e4849', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a159e', NULL, '52eec533-137e-4a1e-8519-5eaaec62219e', 'administrator', NULL);
INSERT INTO public.projects_to_users VALUES ('6d860ad6-7aa2-49f4-8624-70c6098596b1', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', NULL, 'bd0ffe82-78f6-4c92-8623-bb06c9897a93', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('fc9df192-6313-4347-9317-8ee7b37953cc', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a2358', NULL, 'bd0ffe82-78f6-4c92-8623-bb06c9897a93', 'owner', NULL);
INSERT INTO public.projects_to_users VALUES ('bd0ffe82-78f6-4c92-8623-bb06c9897a93', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a2359', NULL, 'bd0ffe82-78f6-4c92-8623-bb06c9897a93', 'owner', NULL);


--
-- TOC entry 5278 (class 0 OID 261488)
-- Dependencies: 307
-- Data for Name: push_notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.push_notifications VALUES ('113af847-bded-417c-9228-5f7c1af19acb', '2021-04-23 15:14:42.487555+01', '2021-04-23 15:14:42.487555+01', true, true, 'b091eda9-e766-46b5-914f-d34940d2267e');


--
-- TOC entry 5279 (class 0 OID 261496)
-- Dependencies: 308
-- Data for Name: subtask_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5199 (class 0 OID 260900)
-- Dependencies: 227
-- Data for Name: t_folder_notification_badge; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5196 (class 0 OID 260857)
-- Dependencies: 223
-- Data for Name: t_folder_pwd; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5280 (class 0 OID 261502)
-- Dependencies: 309
-- Data for Name: task_assignation_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5281 (class 0 OID 261508)
-- Dependencies: 310
-- Data for Name: task_assignations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.task_assignations VALUES ('f4cb9348-7331-47ee-8874-9777312c08ca', '2021-09-16 13:57:14.046983+01', '2021-09-16 13:57:14.046983+01', 'af098e9c-0ae4-4821-9d29-bf12ce30e823');
INSERT INTO public.task_assignations VALUES ('f9d58f16-5d8f-46da-8f2e-1c735062619c', '2021-09-16 13:57:14.046983+01', '2021-09-16 13:57:14.046983+01', '357fb463-97aa-40b9-8ef3-f8ec1dc88f88');
INSERT INTO public.task_assignations VALUES ('b208fd63-43e1-4750-8e0b-f9b809c2ffcd', '2021-11-18 10:33:09.53+00', '2021-11-18 10:33:09.53+00', '9c5bf65f-df90-475c-ab01-102cf601fe88');
INSERT INTO public.task_assignations VALUES ('6cfb07c0-32d3-4e87-942b-152fcb47f40b', '2021-11-18 10:35:37.725+00', '2021-11-18 10:35:37.725+00', '81ea2714-0e88-4feb-9dcc-f485dc4f2204');
INSERT INTO public.task_assignations VALUES ('630cabc8-fee6-462c-816e-12f49a0cac1d', '2021-11-18 10:36:30.852+00', '2021-11-18 10:36:30.852+00', '09e9f972-a6d2-4966-9e18-f08b2f11ceff');
INSERT INTO public.task_assignations VALUES ('896e4c6e-4795-41c9-a0bc-efe8b4784643', '2021-11-18 10:38:40.643+00', '2021-11-18 10:38:40.643+00', '445e45a6-1019-47a5-acfa-7588c23e8cb3');
INSERT INTO public.task_assignations VALUES ('f803e583-a875-48ed-bb9b-fd5780479ac1', '2021-11-18 10:42:38.094+00', '2021-11-18 10:42:38.094+00', '49b4b571-e6c6-41d6-b31e-2115470459e6');
INSERT INTO public.task_assignations VALUES ('7f1268b9-af48-420c-bf89-15aed4c11283', '2021-11-18 10:44:39.463+00', '2021-11-18 10:44:39.463+00', 'bfd83bb4-9cc6-4212-8caf-0a224cae4d8e');
INSERT INTO public.task_assignations VALUES ('638918eb-c1a7-4609-9894-6e3d0f11b412', '2021-11-18 10:45:22.349+00', '2021-11-18 10:45:22.349+00', '67301a20-483c-4cfc-aa95-e812d2ecc827');
INSERT INTO public.task_assignations VALUES ('02ba2f85-f16f-4105-8e25-b4cf4c008439', '2021-11-18 10:46:24.328+00', '2021-11-18 10:46:24.328+00', 'bc6fe7c3-0329-4202-afda-574bacaa5b72');
INSERT INTO public.task_assignations VALUES ('c77e5e5a-7847-4f0a-9efa-f78c8c595f17', '2021-11-18 10:47:36.53+00', '2021-11-18 10:47:36.53+00', '1ddfd514-6d50-453a-83ea-47bc157d1b87');
INSERT INTO public.task_assignations VALUES ('3f2977e3-6c86-45d8-8b86-7eddd3839063', '2021-11-18 10:48:38.166+00', '2021-11-18 10:48:38.166+00', 'c360bd18-93f0-4886-a70c-8a2e4c0a0fed');
INSERT INTO public.task_assignations VALUES ('74739527-1b5e-4152-808a-6408a57bb424', '2021-11-18 10:49:28.069+00', '2021-11-18 10:49:28.069+00', 'f2d48042-973f-42ca-a6c1-ae515cb82573');
INSERT INTO public.task_assignations VALUES ('93237237-3932-4bdd-b121-448fe74b6f04', '2021-11-18 10:51:13.543+00', '2021-11-18 10:51:13.543+00', '1a674cb0-2898-433d-84f9-c3aa847339ee');
INSERT INTO public.task_assignations VALUES ('92f991d6-90d5-45d6-b6a4-3bf9bd333479', '2021-11-18 10:51:51.839+00', '2021-11-18 10:51:51.839+00', '34f0b15d-08c3-473f-87d1-3ddb4787719d');
INSERT INTO public.task_assignations VALUES ('b4124998-8900-43ce-ba56-6a514139a6e0', '2021-11-18 10:52:55.25+00', '2021-11-18 10:52:55.25+00', 'c012f49d-2b84-4e7e-aa4b-94a38b735fd8');
INSERT INTO public.task_assignations VALUES ('3e85ef1f-f0a6-4a26-a3fa-22c8b6fb17c4', '2021-11-18 10:56:25.483+00', '2021-11-18 10:56:25.483+00', '62c8177b-8f98-4d45-baa6-d1d8fc14d1fb');
INSERT INTO public.task_assignations VALUES ('e9c64f68-407f-4eae-acf1-0ce96493ea92', '2021-11-18 10:57:33.757+00', '2021-11-18 10:57:33.757+00', 'c4dd88a9-a9dd-4bc8-badb-3d8d253028cf');
INSERT INTO public.task_assignations VALUES ('379c7a2b-4f9d-4d32-a415-8b7bdc661d1e', '2021-11-18 10:58:11.451+00', '2021-11-18 10:58:11.451+00', '14b43054-c290-4c65-9efb-fb2ac3eadb5d');
INSERT INTO public.task_assignations VALUES ('1c72db39-3e2a-4a03-b316-af270d927e73', '2021-11-18 10:58:51.783+00', '2021-11-18 10:58:51.783+00', 'effaaa70-327e-4cad-9cc7-4e94a2708d47');
INSERT INTO public.task_assignations VALUES ('574019c0-c34c-4641-900e-5f8d442fa70b', '2021-11-18 10:59:28.548+00', '2021-11-18 10:59:28.548+00', '1dcf2dd7-fc7c-4d8d-9e3b-a69f500e6590');
INSERT INTO public.task_assignations VALUES ('e194c9e2-1a49-40fe-b56f-8a8391177477', '2021-11-18 11:00:00.49+00', '2021-11-18 11:00:00.49+00', '8fd3d51d-ee2d-4455-8704-7b03e795a5c4');
INSERT INTO public.task_assignations VALUES ('e194c9e2-1a49-40fe-b56f-8a8391177480', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe91');
INSERT INTO public.task_assignations VALUES ('e194c9e2-1a49-40fe-b56f-8a8391177481', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe92');
INSERT INTO public.task_assignations VALUES ('e194c9e2-1a49-40fe-b56f-8a8391177482', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe93');


--
-- TOC entry 5282 (class 0 OID 261514)
-- Dependencies: 311
-- Data for Name: task_assignations_orgs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.task_assignations_orgs VALUES ('e64ca4fc-f746-47bd-b926-8571a0fcbc10', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'f9d58f16-5d8f-46da-8f2e-1c735062619c', 'fc9df192-6313-4347-9317-8ee7b37952ba', NULL);
INSERT INTO public.task_assignations_orgs VALUES ('e64ca4fc-f746-47bd-b926-8571a0fcbc14', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'f9d58f16-5d8f-46da-8f2e-1c735062619c', 'fc9df192-6313-4347-9317-8ee7b37953ba', NULL);
INSERT INTO public.task_assignations_orgs VALUES ('ae13f67a-1682-49b2-b8a8-730a5751f6c5', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177480', 'fc9df192-6313-4347-9317-8ee7b37953cb', NULL);
INSERT INTO public.task_assignations_orgs VALUES ('8be3c1b9-0856-4ebc-a98d-65b38e79101c', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177480', 'fc9df192-6313-4347-9317-8ee7b37953cc', NULL);
INSERT INTO public.task_assignations_orgs VALUES ('b78e5bf6-ac98-4c3f-8ca3-5bf8ac16eddb', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177480', 'fc9df192-6313-4347-9317-8ee7b37953cd', NULL);
INSERT INTO public.task_assignations_orgs VALUES ('47e8ddcb-def6-4a22-a427-f3e6b936875f', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177481', 'fc9df192-6313-4347-9317-8ee7b37953cb', NULL);
INSERT INTO public.task_assignations_orgs VALUES ('1a5d25ec-d041-4b28-8f09-c5d50f4bb236', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177481', 'fc9df192-6313-4347-9317-8ee7b37953cc', NULL);
INSERT INTO public.task_assignations_orgs VALUES ('36e787ef-ecdb-4669-844b-173754eac546', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177481', 'fc9df192-6313-4347-9317-8ee7b37953cd', NULL);
INSERT INTO public.task_assignations_orgs VALUES ('1f6ae759-ca1d-4d89-b758-7b27c333051f', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177482', 'fc9df192-6313-4347-9317-8ee7b37953cb', NULL);
INSERT INTO public.task_assignations_orgs VALUES ('84e85261-5c5a-4b8c-b597-32f1e1926351', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177482', 'fc9df192-6313-4347-9317-8ee7b37953cc', NULL);
INSERT INTO public.task_assignations_orgs VALUES ('2708de60-ffa3-4406-b200-e9313966b184', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177482', 'fc9df192-6313-4347-9317-8ee7b37953cd', NULL);


--
-- TOC entry 5283 (class 0 OID 261520)
-- Dependencies: 312
-- Data for Name: task_assignations_teams; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.task_assignations_teams VALUES ('e64ca4fc-f746-47bd-b926-8571a0fcbc00', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'f9d58f16-5d8f-46da-8f2e-1c735062619c', '7f90ec6b-0cb2-413a-8157-ffc80b1b693e', NULL);
INSERT INTO public.task_assignations_teams VALUES ('e64ca4fc-f746-47bd-b926-8571a0fcbc04', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'f9d58f16-5d8f-46da-8f2e-1c735062619c', '7f90ec6b-0cb2-413a-8157-ffc80b1b693f', NULL);
INSERT INTO public.task_assignations_teams VALUES ('e64ca4fc-f746-47bd-b926-8571a0fcac07', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'f4cb9348-7331-47ee-8874-9777312c08ca', '7f90ec6b-0cb2-413a-8157-ffc80b1b693e', NULL);
INSERT INTO public.task_assignations_teams VALUES ('f9fe2d62-f78e-47c0-88f5-7d795ef967a9', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'f803e583-a875-48ed-bb9b-fd5780479ac1', '7f90ec6b-0cb2-413a-8157-ffc80b1b693e', NULL);
INSERT INTO public.task_assignations_teams VALUES ('76956e47-f92f-42d4-bfd2-3c170a6169d3', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177480', '7f90ec6b-0cb2-413a-8157-ffc80b1b6950', NULL);
INSERT INTO public.task_assignations_teams VALUES ('6e6b6876-6782-44c6-a9b9-253deceaad03', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177480', '7f90ec6b-0cb2-413a-8157-ffc80b1b6951', NULL);
INSERT INTO public.task_assignations_teams VALUES ('aa684246-7b31-4163-83bc-4cc848e54e2a', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177480', '7f90ec6b-0cb2-413a-8157-ffc80b1b6952', NULL);
INSERT INTO public.task_assignations_teams VALUES ('98a50835-5ca3-4979-a9f1-993a454394ac', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177481', '7f90ec6b-0cb2-413a-8157-ffc80b1b6950', NULL);
INSERT INTO public.task_assignations_teams VALUES ('12ec9238-2157-4eaa-8d7d-18a34ae0f13f', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177481', '7f90ec6b-0cb2-413a-8157-ffc80b1b6951', NULL);
INSERT INTO public.task_assignations_teams VALUES ('740bc3a7-a001-43e7-bb4c-526df238639a', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177481', '7f90ec6b-0cb2-413a-8157-ffc80b1b6952', NULL);
INSERT INTO public.task_assignations_teams VALUES ('7b5d65cb-397a-48cb-950c-877be534e4c5', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177482', '7f90ec6b-0cb2-413a-8157-ffc80b1b6950', NULL);
INSERT INTO public.task_assignations_teams VALUES ('a5135e85-c5fa-4e54-ba66-28da47079bf0', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177482', '7f90ec6b-0cb2-413a-8157-ffc80b1b6951', NULL);
INSERT INTO public.task_assignations_teams VALUES ('d3737210-a95b-4bb6-be4f-a7422988f948', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177482', '7f90ec6b-0cb2-413a-8157-ffc80b1b6952', NULL);


--
-- TOC entry 5284 (class 0 OID 261526)
-- Dependencies: 313
-- Data for Name: task_assignations_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.task_assignations_users VALUES ('36ddce7b-19cb-4a08-88a2-ab5cf527d20b', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'f9d58f16-5d8f-46da-8f2e-1c735062619c', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL);
INSERT INTO public.task_assignations_users VALUES ('36ddce7b-19cb-4a08-88a2-ab5cf527d21c', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'f9d58f16-5d8f-46da-8f2e-1c735062619c', '86c8c162-3405-457c-9724-727aea142580', NULL);
INSERT INTO public.task_assignations_users VALUES ('ced66933-9ac3-43cb-8a3d-9e34d600e8f5', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177477', 'b091eda9-e766-46b5-914f-d34940d2267e', NULL);
INSERT INTO public.task_assignations_users VALUES ('de6dd749-d6a0-43ab-a4a1-9f33caf6d6e7', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '1c72db39-3e2a-4a03-b316-af270d927e73', '86c8c162-3405-457c-9724-727aea142580', NULL);
INSERT INTO public.task_assignations_users VALUES ('39deb507-6bf2-485b-b599-0dfd28427668', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177480', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', NULL);
INSERT INTO public.task_assignations_users VALUES ('59c2b4c6-eba1-4d34-8a5e-b47e412ece96', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177480', 'a7e70da0-bb65-4e30-b6f5-a86f983a2358', NULL);
INSERT INTO public.task_assignations_users VALUES ('c942ac1b-dc3b-4b7b-bb60-69496b0878d9', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177480', 'a7e70da0-bb65-4e30-b6f5-a86f983a2359', NULL);
INSERT INTO public.task_assignations_users VALUES ('04e10cdc-bc12-470a-b4e8-28aac6304c7c', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177481', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', NULL);
INSERT INTO public.task_assignations_users VALUES ('36ae5b6b-2d7e-4b2c-9884-4da2934e35b0', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177481', 'a7e70da0-bb65-4e30-b6f5-a86f983a2358', NULL);
INSERT INTO public.task_assignations_users VALUES ('5512118e-b74d-458f-9ab8-147cf5760ccc', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177481', 'a7e70da0-bb65-4e30-b6f5-a86f983a2359', NULL);
INSERT INTO public.task_assignations_users VALUES ('9881a712-b3d4-40ac-aa9e-a67d8467d83b', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177482', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', NULL);
INSERT INTO public.task_assignations_users VALUES ('745e2ada-71ca-4915-bbc7-62e3c428afd4', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177482', 'a7e70da0-bb65-4e30-b6f5-a86f983a2358', NULL);
INSERT INTO public.task_assignations_users VALUES ('8b09b15c-bbf5-40c2-b1e7-47721a8e3496', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'e194c9e2-1a49-40fe-b56f-8a8391177482', 'a7e70da0-bb65-4e30-b6f5-a86f983a2359', NULL);


--
-- TOC entry 5285 (class 0 OID 261532)
-- Dependencies: 314
-- Data for Name: task_attachment_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5286 (class 0 OID 261538)
-- Dependencies: 315
-- Data for Name: task_attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.task_attachments VALUES ('f1960c82-e7b5-42d8-bd5b-e245a470d643', '2021-06-24 09:55:33.662623+01', '2021-06-24 09:55:33.662623+01', '357fb463-97aa-40b9-8ef3-f8ec1dc88f88', 'taskAttachmentImage.jpeg', 'taskAttachmentImage.jpeg', 'b091eda9-e766-46b5-914f-d34940d2267e', 'image/jpeg', 'jpeg', NULL);
INSERT INTO public.task_attachments VALUES ('f1960c82-e7b5-42d8-bd6b-e245a470d644', '2021-06-24 09:55:33.662623+01', '2021-06-24 09:55:33.662623+01', '357fb463-97aa-40b9-8ef3-f8ec1dc88f88', 'taskAttachmentBin.bin', 'taskAttachmentBin.bin', 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/macbinary', 'bin', NULL);
INSERT INTO public.task_attachments VALUES ('f1960c82-e7b5-42d8-bd6b-e245a470d645', '2021-06-24 09:55:33.662623+01', '2021-06-24 09:55:33.662623+01', '357fb463-97aa-40b9-8ef3-f8ec1dc88f88', 'task_attachment.jpg', 'task_attachment.jpg', 'b091eda9-e766-46b5-914f-d34940d2267e', 'application/jpeg', 'jpg', NULL);
INSERT INTO public.task_attachments VALUES ('ead8153c-7096-4a9f-a3ea-5bb7da106600', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe91', 'task_attachment.jpg', 'task_attachment.jpg', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', 'image/jpeg', 'jpg', NULL);
INSERT INTO public.task_attachments VALUES ('6cd8942f-1e2a-4730-8bef-5cf55658eb29', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe91', 'b755b29b-068b-468a-951a-762de405fd17', 'Screenshot 2022-02-21 at 10.44.49.png', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', 'image/png', 'png', NULL);
INSERT INTO public.task_attachments VALUES ('b733f3ed-4449-4876-82bc-90815f8de9a5', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe92', 'task_attachment.jpg', 'task_attachment.jpg', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', 'image/jpeg', 'jpg', NULL);
INSERT INTO public.task_attachments VALUES ('ef85441b-4797-4a5f-a60e-1679ae09a4fb', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe92', '65615d5a-2321-4ce2-994e-91d8472d0898', 'Screenshot 2022-02-21 at 10.44.55.png', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', 'image/png', 'png', NULL);
INSERT INTO public.task_attachments VALUES ('cbe5b360-4e64-453e-90aa-6c48f3f7a809', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe93', '3f7ee2ee-b080-4e4f-8f1d-beb4a25dc96c', 'Screenshot 2022-02-21 at 10.45.02.png', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', 'image/png', 'png', NULL);
INSERT INTO public.task_attachments VALUES ('807ab869-d435-4aef-8a15-7d8b5a03abb3', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe91', 'taskAttachmentBin.bin', 'taskAttachmentBin.bin', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', 'application/binary', 'bin', NULL);
INSERT INTO public.task_attachments VALUES ('98542bb3-cb3d-495e-81fa-4d9b167f1f1a', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe92', 'taskAttachmentBin.bin', 'taskAttachmentBin.bin', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', 'application/binary', 'bin', NULL);


--
-- TOC entry 5287 (class 0 OID 261546)
-- Dependencies: 316
-- Data for Name: task_file_version_location; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.task_file_version_location VALUES ('a7cf5b1d-046a-4ac1-b0f1-5fd80fea3111', '2021-10-14 22:09:29.038984+01', '2021-10-14 22:09:29.038984+01', 1, 0, 0);
INSERT INTO public.task_file_version_location VALUES ('a7cf5b1d-046a-4ac1-b0f1-5fd80fea3112', '2021-10-14 22:09:29.038984+01', '2021-10-14 22:09:29.038984+01', 1, 905, 0);
INSERT INTO public.task_file_version_location VALUES ('a7cf5b1d-046a-4ac1-b0f1-5fd80fea3113', '2021-10-14 22:09:29.038984+01', '2021-10-14 22:09:29.038984+01', 1, 0, 1280);
INSERT INTO public.task_file_version_location VALUES ('a7cf5b1d-046a-4ac1-b0f1-5fd80fea3114', '2021-10-14 22:09:29.038984+01', '2021-10-14 22:09:29.038984+01', 1, 905, 1280);
INSERT INTO public.task_file_version_location VALUES ('a7cf5b1d-046a-4ac1-b0f1-5fd80fea3120', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 1, 74.1, 51.33);
INSERT INTO public.task_file_version_location VALUES ('a7cf5b1d-046a-4ac1-b0f1-5fd80fea3121', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 1, 374.16, 231.07);
INSERT INTO public.task_file_version_location VALUES ('a7cf5b1d-046a-4ac1-b0f1-5fd80fea3122', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 2, 86.71, 52.11);


--
-- TOC entry 5288 (class 0 OID 261554)
-- Dependencies: 317
-- Data for Name: task_label_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5289 (class 0 OID 261560)
-- Dependencies: 318
-- Data for Name: task_locations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5290 (class 0 OID 261563)
-- Dependencies: 319
-- Data for Name: task_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5291 (class 0 OID 261569)
-- Dependencies: 320
-- Data for Name: task_subtasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.task_subtasks VALUES ('5a33440c-c1b5-4945-a999-edb80c774ab4', '2021-09-08 14:00:06.798675+01', '2021-09-08 14:00:06.798675+01', 'b091eda9-e766-46b5-914f-d34940d2267e', '357fb463-97aa-40b9-8ef3-f8ec1dc88f88', false, 'test', NULL, NULL, 1);
INSERT INTO public.task_subtasks VALUES ('03714873-da27-450c-929e-1e168e14d7ac', '2021-11-18 10:35:37.737+00', '2021-11-18 10:35:37.737+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '81ea2714-0e88-4feb-9dcc-f485dc4f2204', false, 'subtask1', NULL, NULL, 1);
INSERT INTO public.task_subtasks VALUES ('0ba5294f-1fb4-433b-aa78-e51c7c25b55c', '2021-11-18 10:35:37.738+00', '2021-11-18 10:35:37.738+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '81ea2714-0e88-4feb-9dcc-f485dc4f2204', false, 'subtask2', NULL, NULL, 2);
INSERT INTO public.task_subtasks VALUES ('700bd48f-2e00-4bd1-8e70-173d49de5ce6', '2021-11-18 10:36:30.862+00', '2021-11-18 10:36:30.863+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '09e9f972-a6d2-4966-9e18-f08b2f11ceff', false, '1', NULL, NULL, 1);
INSERT INTO public.task_subtasks VALUES ('4f2d472b-70b3-45d5-ac57-0d6545c26a9e', '2021-11-18 10:36:30.863+00', '2021-11-18 10:36:30.863+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '09e9f972-a6d2-4966-9e18-f08b2f11ceff', false, '2', NULL, NULL, 2);
INSERT INTO public.task_subtasks VALUES ('d82276e1-4d7a-47c2-9409-a9ae61cf9280', '2021-11-18 10:38:40.652+00', '2021-11-18 10:38:40.652+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '445e45a6-1019-47a5-acfa-7588c23e8cb3', false, '3', NULL, NULL, 1);
INSERT INTO public.task_subtasks VALUES ('bc4f69a9-bded-483b-b0d5-4851150fdfb8', '2021-11-18 10:38:40.652+00', '2021-11-18 10:41:04.920326+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '445e45a6-1019-47a5-acfa-7588c23e8cb3', true, '1', NULL, NULL, 2);
INSERT INTO public.task_subtasks VALUES ('aa0f1af3-8830-4e03-9938-972504aa5422', '2021-11-18 10:38:40.652+00', '2021-11-18 10:41:05.282341+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '445e45a6-1019-47a5-acfa-7588c23e8cb3', true, '2', NULL, NULL, 3);
INSERT INTO public.task_subtasks VALUES ('c80c9c4b-89ce-4e40-8de7-00ea30956be8', '2021-11-18 10:33:09.561+00', '2021-11-18 10:41:16.607877+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '9c5bf65f-df90-475c-ab01-102cf601fe88', true, 'subtask 1', NULL, NULL, 1);
INSERT INTO public.task_subtasks VALUES ('b125dc9f-4344-44a1-93de-2bfdee224ee5', '2021-11-18 10:33:10.563+00', '2021-11-18 10:41:17.241856+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '9c5bf65f-df90-475c-ab01-102cf601fe88', true, 'subtask 2', NULL, NULL, 2);
INSERT INTO public.task_subtasks VALUES ('12d96aba-d4e9-4e10-9c88-494285d180a5', '2021-11-18 10:42:39.103+00', '2021-11-18 10:42:50.986285+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '49b4b571-e6c6-41d6-b31e-2115470459e6', true, 'subtask 2', NULL, NULL, 1);
INSERT INTO public.task_subtasks VALUES ('5c31dbc8-6ab8-4ad3-b060-bfd3a4988b6c', '2021-11-18 10:42:38.103+00', '2021-11-18 10:42:52.255388+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '49b4b571-e6c6-41d6-b31e-2115470459e6', true, 'subtask 1', NULL, NULL, 2);
INSERT INTO public.task_subtasks VALUES ('299456b1-1456-4db2-b784-d12bf2d7927a', '2021-11-18 10:46:24.337+00', '2021-11-18 10:46:24.337+00', 'b091eda9-e766-46b5-914f-d34940d2267e', 'bc6fe7c3-0329-4202-afda-574bacaa5b72', false, 'check', NULL, NULL, 1);
INSERT INTO public.task_subtasks VALUES ('3f2f5d14-7298-49c1-ad77-c16e279769f3', '2021-11-18 10:46:24.337+00', '2021-11-18 10:46:24.337+00', 'b091eda9-e766-46b5-914f-d34940d2267e', 'bc6fe7c3-0329-4202-afda-574bacaa5b72', false, 'treat', NULL, NULL, 2);
INSERT INTO public.task_subtasks VALUES ('153e4a45-064c-4530-a534-ed5b9adc7d08', '2021-11-18 10:47:36.54+00', '2021-11-18 10:47:36.54+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '1ddfd514-6d50-453a-83ea-47bc157d1b87', false, 'pull cables', NULL, NULL, 1);
INSERT INTO public.task_subtasks VALUES ('709085f8-4e4b-4061-8e77-8d047c18ed99', '2021-11-18 10:48:38.172+00', '2021-11-18 10:48:38.172+00', 'b091eda9-e766-46b5-914f-d34940d2267e', 'c360bd18-93f0-4886-a70c-8a2e4c0a0fed', false, 'high voltage', NULL, NULL, 1);
INSERT INTO public.task_subtasks VALUES ('b0267980-b1a4-443d-9e60-dd832d3bddfd', '2021-11-18 10:48:38.172+00', '2021-11-18 10:48:38.172+00', 'b091eda9-e766-46b5-914f-d34940d2267e', 'c360bd18-93f0-4886-a70c-8a2e4c0a0fed', false, 'low voltage', NULL, NULL, 2);
INSERT INTO public.task_subtasks VALUES ('37d29887-1fbe-4445-bb01-e6af8e11a2aa', '2021-11-18 10:49:28.076+00', '2021-11-18 10:49:28.076+00', 'b091eda9-e766-46b5-914f-d34940d2267e', 'f2d48042-973f-42ca-a6c1-ae515cb82573', false, 'earthwork of 10M3', NULL, NULL, 1);
INSERT INTO public.task_subtasks VALUES ('53accb05-83ca-46a1-9699-c1eb04e515bf', '2021-11-18 10:49:28.076+00', '2021-11-18 10:49:28.076+00', 'b091eda9-e766-46b5-914f-d34940d2267e', 'f2d48042-973f-42ca-a6c1-ae515cb82573', false, 'earthwork of 10M3', NULL, NULL, 2);
INSERT INTO public.task_subtasks VALUES ('84b7e65a-7047-43d3-ba1a-61bc6d350cfc', '2021-11-18 10:49:28.076+00', '2021-11-18 10:49:31.887972+00', 'b091eda9-e766-46b5-914f-d34940d2267e', 'f2d48042-973f-42ca-a6c1-ae515cb82573', true, 'earthwork of 10M3', NULL, NULL, 3);
INSERT INTO public.task_subtasks VALUES ('80f6533b-300c-476f-bee4-feed9a9e3c83', '2021-11-18 10:47:36.54+00', '2021-11-18 10:49:36.096371+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '1ddfd514-6d50-453a-83ea-47bc157d1b87', true, 'installation of the panel', NULL, NULL, 2);
INSERT INTO public.task_subtasks VALUES ('8e6f0a10-b53d-4885-ad7d-eb94c1d398d5', '2021-11-18 10:52:55.258+00', '2021-11-18 10:52:55.258+00', 'b091eda9-e766-46b5-914f-d34940d2267e', 'c012f49d-2b84-4e7e-aa4b-94a38b735fd8', false, 'subtask 1', NULL, NULL, 1);
INSERT INTO public.task_subtasks VALUES ('8df50a33-cdde-49d7-b513-74a6d48de30f', '2021-11-18 10:52:56.258+00', '2021-11-18 10:52:55.258+00', 'b091eda9-e766-46b5-914f-d34940d2267e', 'c012f49d-2b84-4e7e-aa4b-94a38b735fd8', false, 'subtask 2', NULL, NULL, 2);
INSERT INTO public.task_subtasks VALUES ('1b303624-e5f1-4941-bc2c-e4c51dc059ba', '2021-11-18 10:56:25.503+00', '2021-11-18 10:56:25.503+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '62c8177b-8f98-4d45-baa6-d1d8fc14d1fb', false, 'cutting of the edges', NULL, NULL, 1);
INSERT INTO public.task_subtasks VALUES ('d8f76b9c-19d7-4dfa-90a9-6caa090466f6', '2021-11-18 10:56:25.503+00', '2021-11-18 10:56:25.503+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '62c8177b-8f98-4d45-baa6-d1d8fc14d1fb', false, 'welding', NULL, NULL, 2);
INSERT INTO public.task_subtasks VALUES ('72a43135-7c28-49f3-8ad1-c9f781a8c386', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', '9c5bf65f-df90-475c-ab01-102cf601fe91', true, 'welding', NULL, NULL, 1);
INSERT INTO public.task_subtasks VALUES ('7f7bb41c-1fc8-4108-8d24-59455e4f8c3d', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', '9c5bf65f-df90-475c-ab01-102cf601fe91', false, 'high voltage', NULL, NULL, 2);
INSERT INTO public.task_subtasks VALUES ('8a2543fb-37df-4038-a7d7-64d398e6b4e7', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', '9c5bf65f-df90-475c-ab01-102cf601fe91', false, 'check', NULL, NULL, 3);
INSERT INTO public.task_subtasks VALUES ('732c89d8-5cec-4a19-8c63-7c975cecac16', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', '9c5bf65f-df90-475c-ab01-102cf601fe92', false, 'pull cables', NULL, NULL, 1);


--
-- TOC entry 5292 (class 0 OID 261579)
-- Dependencies: 321
-- Data for Name: task_validation_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5293 (class 0 OID 261585)
-- Dependencies: 322
-- Data for Name: task_validations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.task_validations VALUES ('45d6e54b-66ec-43b1-995b-7fa4a6f32597', '2021-09-07 12:24:05.569689+01', '2021-09-07 12:24:05.569689+01', '357fb463-97aa-40b9-8ef3-f8ec1dc88f88', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.task_validations VALUES ('45d6e54b-66ec-43b1-995b-7fa4a6f32598', '2021-09-07 12:24:05.569689+01', '2021-09-07 12:24:05.569689+01', '357fb463-97aa-40b9-8ef3-f8ec1dc88f88', 'a7e70da0-bb65-4e30-b6f5-a86f983a2346');
INSERT INTO public.task_validations VALUES ('efe31afd-bfbd-4e02-b6f2-3f94d82889c8', '2021-11-18 10:41:26.465+00', '2021-11-18 10:41:26.465+00', '9c5bf65f-df90-475c-ab01-102cf601fe88', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.task_validations VALUES ('fe6cc6e4-3d81-4fa6-a3ff-f8e8c522b3b1', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe91', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357');


--
-- TOC entry 5294 (class 0 OID 261591)
-- Dependencies: 323
-- Data for Name: task_views; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.task_views VALUES (1, '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '357fb463-97aa-40b9-8ef3-f8ec1dc88f88', 'b091eda9-e766-46b5-914f-d34940d2267e');


--
-- TOC entry 5201 (class 0 OID 260924)
-- Dependencies: 229
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tasks VALUES ('357fb463-97aa-40b9-8ef3-f8ec1dc88f88', '2021-06-22 13:02:09.467468+01', '2021-06-22 13:02:09.467468+01', 1, 'build a wall (Link to Tour Eiffel project)', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2021-06-22 01:00:00+01', '2045-06-22 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('af098e9c-0ae4-4821-9d29-bf12ce30e823', '2021-06-22 13:02:24.854349+01', '2021-06-22 13:02:24.854349+01', 2, 'talk to contractor', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', NULL, NULL, NULL, false);
INSERT INTO public.tasks VALUES ('effaaa70-327e-4cad-9cc7-4e94a2708d47', '2021-11-18 10:58:51.783+00', '2021-11-18 11:00:51.228021+00', 3, 'repaint the wall in white', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-06-15 01:00:00+01', '2022-06-22 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('8fd3d51d-ee2d-4455-8704-7b03e795a5c4', '2021-11-18 11:00:00.49+00', '2021-11-18 11:00:29.539823+00', 4, 'Liquid paint booth installation', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-06-14 01:00:00+01', '2022-06-15 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('1dcf2dd7-fc7c-4d8d-9e3b-a69f500e6590', '2021-11-18 10:59:28.548+00', '2021-11-18 10:59:28.548+00', 5, 'Pass wires', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-06-11 01:00:00+01', '2022-06-18 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('14b43054-c290-4c65-9efb-fb2ac3eadb5d', '2021-11-18 10:58:11.451+00', '2021-11-18 10:58:11.451+00', 6, 'Send report', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-06-15 01:00:00+01', '2022-06-22 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('c4dd88a9-a9dd-4bc8-badb-3d8d253028cf', '2021-11-18 10:57:33.757+00', '2021-11-18 10:57:33.757+00', 7, 'Laying of the life base', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-06-23 01:00:00+01', '2022-06-30 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('62c8177b-8f98-4d45-baa6-d1d8fc14d1fb', '2021-11-18 10:56:25.483+00', '2021-11-18 10:56:25.483+00', 8, 'Stainless steel installation', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-09-29 01:00:00+01', '2022-10-06 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('c012f49d-2b84-4e7e-aa4b-94a38b735fd8', '2021-11-18 10:52:55.25+00', '2021-11-18 10:53:14.503773+00', 9, 'Breaking down the wall', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-10-02 01:00:00+01', '2022-10-09 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('34f0b15d-08c3-473f-87d1-3ddb4787719d', '2021-11-18 10:51:51.839+00', '2021-11-18 10:51:51.839+00', 10, 'Flooring on the first floor', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-10-06 01:00:00+01', '2022-10-20 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('1a674cb0-2898-433d-84f9-c3aa847339ee', '2021-11-18 10:51:13.543+00', '2021-11-18 10:51:13.543+00', 11, 'repaint the south wall', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-10-11 01:00:00+01', '2022-10-18 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('f2d48042-973f-42ca-a6c1-ae515cb82573', '2021-11-18 10:49:28.069+00', '2021-11-18 10:49:28.069+00', 12, 'earthwork of 30M3', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-10-11 01:00:00+01', '2022-10-18 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('c360bd18-93f0-4886-a70c-8a2e4c0a0fed', '2021-11-18 10:48:38.166+00', '2021-11-18 10:48:38.166+00', 13, 'Work on electricity plan', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-10-19 01:00:00+01', '2022-10-26 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('1ddfd514-6d50-453a-83ea-47bc157d1b87', '2021-11-18 10:47:36.53+00', '2021-11-18 10:47:36.53+00', 14, 'Installation of the high voltage panel', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-10-21 01:00:00+01', '2022-10-28 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('bc6fe7c3-0329-4202-afda-574bacaa5b72', '2021-11-18 10:46:24.328+00', '2021-11-18 10:46:24.328+00', 15, 'Scratch on the floor', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-10-21 01:00:00+01', '2022-10-22 01:00:00+01', NULL, false);
INSERT INTO public.tasks VALUES ('67301a20-483c-4cfc-aa95-e812d2ecc827', '2021-11-18 10:45:22.349+00', '2021-11-18 10:45:22.349+00', 16, 'Order monitors', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-10-26 01:00:00+01', '2022-11-02 00:00:00+00', NULL, false);
INSERT INTO public.tasks VALUES ('bfd83bb4-9cc6-4212-8caf-0a224cae4d8e', '2021-11-18 10:44:39.463+00', '2021-11-18 10:44:39.463+00', 17, 'Installation of the monitors', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-10-26 01:00:00+01', '2022-11-02 00:00:00+00', NULL, false);
INSERT INTO public.tasks VALUES ('49b4b571-e6c6-41d6-b31e-2115470459e6', '2021-11-18 10:42:38.094+00', '2021-11-18 10:43:54.420582+00', 18, 'Pass the conduits', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-10-29 01:00:00+01', '2022-11-05 00:00:00+00', NULL, false);
INSERT INTO public.tasks VALUES ('445e45a6-1019-47a5-acfa-7588c23e8cb3', '2021-11-18 10:38:40.643+00', '2021-11-18 10:40:58.711437+00', 19, 'Passage of the pipes', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-11-08 00:00:00+00', '2022-11-15 00:00:00+00', NULL, false);
INSERT INTO public.tasks VALUES ('09e9f972-a6d2-4966-9e18-f08b2f11ceff', '2021-11-18 10:36:30.852+00', '2021-11-18 10:36:30.852+00', 20, 'Take over the carpentry', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-11-15 00:00:00+00', '2022-11-22 00:00:00+00', NULL, false);
INSERT INTO public.tasks VALUES ('81ea2714-0e88-4feb-9dcc-f485dc4f2204', '2021-11-18 10:35:37.725+00', '2021-11-18 10:35:37.725+00', 21, 'Installation of the ventilation', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-11-16 00:00:00+00', '2022-11-23 00:00:00+00', NULL, false);
INSERT INTO public.tasks VALUES ('9c5bf65f-df90-475c-ab01-102cf601fe88', '2021-11-18 10:33:09.529+00', '2021-11-18 10:34:02.906925+00', 22, 'Install IP68 light + Plug', 'b091eda9-e766-46b5-914f-d34940d2267e', '7b450b00-c9b5-4332-b087-46af26e8a525', '2022-11-16 00:00:00+00', '2022-11-23 00:00:00+00', NULL, false);
INSERT INTO public.tasks VALUES ('9c5bf65f-df90-475c-ab01-102cf601fe91', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 1, 'Installation of the high voltage panel, passage of the pipes, pass the conduits and installation of the ventilation', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', '915e171c-905a-423a-9916-2aa388d6dc7c', '2022-11-16 00:00:00+00', '2022-11-23 00:00:00+00', NULL, false);
INSERT INTO public.tasks VALUES ('9c5bf65f-df90-475c-ab01-102cf601fe92', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 2, 'Stainless steel installation', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', '915e171c-905a-423a-9916-2aa388d6dc7c', '2022-11-16 00:00:00+00', '2022-11-23 00:00:00+00', NULL, false);
INSERT INTO public.tasks VALUES ('9c5bf65f-df90-475c-ab01-102cf601fe93', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 3, 'Send report', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', '915e171c-905a-423a-9916-2aa388d6dc7c', '2022-11-16 00:00:00+00', '2022-11-23 00:00:00+00', NULL, false);
INSERT INTO public.tasks VALUES ('9c5bf65f-df90-475c-ab01-102cf601fe94', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 4, '', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', '915e171c-905a-423a-9916-2aa388d6dc7c', NULL, NULL, NULL, false);
INSERT INTO public.tasks VALUES ('9c5bf65f-df90-475c-ab01-102cf601fe95', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 5, '', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', '915e171c-905a-423a-9916-2aa388d6dc7c', NULL, NULL, '2022-11-24 00:00:00+00', false);


--
-- TOC entry 5296 (class 0 OID 261597)
-- Dependencies: 325
-- Data for Name: tasks_file_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tasks_file_versions VALUES ('a7cf5b1d-046a-4ac9-b0f1-5fd80fea3231', '2021-10-14 22:09:29.038984+01', '2021-10-14 22:09:29.038984+01', '357fb463-97aa-40b9-8ef3-f8ec1dc88f88', '3527410b-2c83-4f78-a4c5-2ed924840051', 'a7cf5b1d-046a-4ac1-b0f1-5fd80fea3111');
INSERT INTO public.tasks_file_versions VALUES ('a7cf5b1d-046a-4ac9-b0f1-5fd80fea3232', '2021-10-14 22:09:29.038984+01', '2021-10-14 22:09:29.038984+01', 'af098e9c-0ae4-4821-9d29-bf12ce30e823', '3527410b-2c83-4f78-a4c5-2ed924840051', 'a7cf5b1d-046a-4ac1-b0f1-5fd80fea3112');
INSERT INTO public.tasks_file_versions VALUES ('a7cf5b1d-046a-4ac9-b0f1-5fd80fea3233', '2021-10-14 22:09:29.038984+01', '2021-10-14 22:09:29.038984+01', 'effaaa70-327e-4cad-9cc7-4e94a2708d47', '3527410b-2c83-4f78-a4c5-2ed924840051', 'a7cf5b1d-046a-4ac1-b0f1-5fd80fea3113');
INSERT INTO public.tasks_file_versions VALUES ('a7cf5b1d-046a-4ac9-b0f1-5fd80fea3234', '2021-10-14 22:09:29.038984+01', '2021-10-14 22:09:29.038984+01', '8fd3d51d-ee2d-4455-8704-7b03e795a5c4', '3527410b-2c83-4f78-a4c5-2ed924840051', 'a7cf5b1d-046a-4ac1-b0f1-5fd80fea3114');
INSERT INTO public.tasks_file_versions VALUES ('68d3fd7a-fe50-430a-bd14-0c9dd25ecc74', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe91', '3527410b-2c83-4f78-a4c5-2ed924840100', 'a7cf5b1d-046a-4ac1-b0f1-5fd80fea3120');
INSERT INTO public.tasks_file_versions VALUES ('1bb8eaea-ff0f-4cb0-b8f7-c9517b29a27f', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe92', '3527410b-2c83-4f78-a4c5-2ed924840100', 'a7cf5b1d-046a-4ac1-b0f1-5fd80fea3121');
INSERT INTO public.tasks_file_versions VALUES ('abebca91-9044-4b45-8077-951ebcdd38f2', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe93', '3527410b-2c83-4f78-a4c5-2ed924840100', 'a7cf5b1d-046a-4ac1-b0f1-5fd80fea3122');


--
-- TOC entry 5297 (class 0 OID 261603)
-- Dependencies: 326
-- Data for Name: tasks_to_project_labels; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tasks_to_project_labels VALUES ('66e5895d-c9ab-47cb-b49c-a6d275ad8466', '2021-06-23 13:27:42.897913+01', '2021-06-23 13:27:42.897913+01', '357fb463-97aa-40b9-8ef3-f8ec1dc88f88', '3a3a03f9-262c-45a9-8626-1c9098763783', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('efe4814a-3ef3-4616-9515-f5511b6e4a31', '2021-10-06 09:50:06.629052+01', '2021-10-06 09:50:06.629052+01', '357fb463-97aa-40b9-8ef3-f8ec1dc88f88', '0af4ecd8-c41d-4c26-84e3-34fdb4987984', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('1d23095d-6b40-48eb-971f-f812d0763f32', '2021-10-06 09:50:13.535257+01', '2021-10-06 09:50:13.535257+01', '357fb463-97aa-40b9-8ef3-f8ec1dc88f88', '0a57ca89-07f4-4372-b3a8-ed8b5ba52ba4', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('04c3bc33-68d9-4a51-9d47-98192c808e33', '2021-10-06 09:50:19.618782+01', '2021-10-06 09:50:19.618782+01', '357fb463-97aa-40b9-8ef3-f8ec1dc88f88', 'ee092eaa-386f-48e7-9763-0c61f044526b', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('a8f62abf-08ae-4e6b-8efd-b16285051b00', '2021-11-18 10:34:02.953+00', '2021-11-18 10:34:02.953+00', '9c5bf65f-df90-475c-ab01-102cf601fe88', '0af4ecd8-c41d-4c26-84e3-34fdb4987984', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('b1f1b189-eb8c-4064-a017-217deafa1c09', '2021-11-18 10:35:37.844+00', '2021-11-18 10:35:37.844+00', '81ea2714-0e88-4feb-9dcc-f485dc4f2204', '0a57ca89-07f4-4372-b3a8-ed8b5ba52ba4', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('c04a33fe-9492-45f0-8c78-aaab1298ea6f', '2021-11-18 10:36:30.879+00', '2021-11-18 10:36:30.879+00', '09e9f972-a6d2-4966-9e18-f08b2f11ceff', 'ee092eaa-386f-48e7-9763-0c61f044526b', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('f63ef7cb-39e6-4ee2-9f2b-125f52cf5fca', '2021-11-18 10:40:58.737+00', '2021-11-18 10:40:58.737+00', '445e45a6-1019-47a5-acfa-7588c23e8cb3', '0a57ca89-07f4-4372-b3a8-ed8b5ba52ba4', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('15484819-619d-40d8-9f1d-0ece4d0944f3', '2021-11-18 10:42:38.114+00', '2021-11-18 10:42:38.114+00', '49b4b571-e6c6-41d6-b31e-2115470459e6', '0af4ecd8-c41d-4c26-84e3-34fdb4987984', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('56dc6d15-c1d8-4fae-9188-7ede53a1418a', '2021-11-18 10:43:28.462+00', '2021-11-18 10:43:28.462+00', '49b4b571-e6c6-41d6-b31e-2115470459e6', '85a4e5b3-c2b0-422d-a4fd-165eba78e40c', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('c3a6f3e3-57e1-4924-83ee-bc2a1a087c47', '2021-11-18 10:44:39.474+00', '2021-11-18 10:44:39.474+00', 'bfd83bb4-9cc6-4212-8caf-0a224cae4d8e', '0af4ecd8-c41d-4c26-84e3-34fdb4987984', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('b64802e8-5ea8-4993-b124-2f7f8e9a63ba', '2021-11-18 10:46:24.347+00', '2021-11-18 10:46:24.347+00', 'bc6fe7c3-0329-4202-afda-574bacaa5b72', '85a4e5b3-c2b0-422d-a4fd-165eba78e40c', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('75c12df8-6258-43b1-9cd0-0f4820dbe9a9', '2021-11-18 10:47:36.554+00', '2021-11-18 10:47:36.554+00', '1ddfd514-6d50-453a-83ea-47bc157d1b87', '0af4ecd8-c41d-4c26-84e3-34fdb4987984', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('8c3f4a5b-49f4-4b59-b98c-f80b744735ab', '2021-11-18 10:48:38.183+00', '2021-11-18 10:48:38.183+00', 'c360bd18-93f0-4886-a70c-8a2e4c0a0fed', '0af4ecd8-c41d-4c26-84e3-34fdb4987984', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('20acff88-3186-44a5-9a00-3d8c5d0bb147', '2021-11-18 10:49:28.091+00', '2021-11-18 10:49:28.091+00', 'f2d48042-973f-42ca-a6c1-ae515cb82573', '85a4e5b3-c2b0-422d-a4fd-165eba78e40c', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('a7d85bfc-3d5e-424a-8f68-f2f80dd574c9', '2021-11-18 10:51:13.554+00', '2021-11-18 10:51:13.554+00', '1a674cb0-2898-433d-84f9-c3aa847339ee', '6fb1b881-8ffb-4e81-9f39-b5fa0d94b1e6', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('29e7d419-8bb9-43b8-a7ab-e7dbdc5b2e1d', '2021-11-18 10:53:14.515+00', '2021-11-18 10:53:14.515+00', 'c012f49d-2b84-4e7e-aa4b-94a38b735fd8', '98e3a17c-4b30-4ed1-87b7-04246d812866', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('d3066637-5be7-4dc7-bd32-f4de17d2870d', '2021-11-18 10:56:25.513+00', '2021-11-18 10:56:25.513+00', '62c8177b-8f98-4d45-baa6-d1d8fc14d1fb', 'ee092eaa-386f-48e7-9763-0c61f044526b', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('bef42dc5-78b4-4ca8-bf36-9359b487b76b', '2021-11-18 10:57:33.768+00', '2021-11-18 10:57:33.768+00', 'c4dd88a9-a9dd-4bc8-badb-3d8d253028cf', '3a3a03f9-262c-45a9-8626-1c9098763783', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('d0ee31ad-cf9c-4b6e-b670-b4533114e061', '2021-11-18 10:58:11.461+00', '2021-11-18 10:58:11.461+00', '14b43054-c290-4c65-9efb-fb2ac3eadb5d', '3a3a03f9-262c-45a9-8626-1c9098763783', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('b21ecbbe-ac4d-4c92-903b-d5170dda04a6', '2021-11-18 10:58:51.795+00', '2021-11-18 10:58:51.795+00', 'effaaa70-327e-4cad-9cc7-4e94a2708d47', '85a4e5b3-c2b0-422d-a4fd-165eba78e40c', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('bafc4695-ae52-4593-b07b-95944fd26640', '2021-11-18 10:59:28.557+00', '2021-11-18 10:59:28.557+00', '1dcf2dd7-fc7c-4d8d-9e3b-a69f500e6590', '0af4ecd8-c41d-4c26-84e3-34fdb4987984', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('c3cb3b31-2b8f-4d5d-92be-dfb9cf7be19c', '2021-11-18 11:00:00.502+00', '2021-11-18 11:00:00.502+00', '8fd3d51d-ee2d-4455-8704-7b03e795a5c4', '85a4e5b3-c2b0-422d-a4fd-165eba78e40c', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('4b32c2d0-691f-4e7d-a2b1-bf2ff965f319', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe91', '98e3a17c-4b30-4ed1-87b7-04246d812870', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('576efbd8-2e70-41b5-b6c8-93b73019e4ce', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe91', '98e3a17c-4b30-4ed1-87b7-04246d812871', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('1bca055a-afa4-4b07-b9d1-ea25fbf37e98', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe91', '98e3a17c-4b30-4ed1-87b7-04246d812872', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('3449c5a8-d3d7-4d95-91c7-bf26355861d2', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe92', '98e3a17c-4b30-4ed1-87b7-04246d812870', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('9357e8b2-12b6-4747-acfa-2575ea46c77a', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe92', '98e3a17c-4b30-4ed1-87b7-04246d812871', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('45a9142a-f4b5-4532-81b8-2cdbdaf41da0', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe92', '98e3a17c-4b30-4ed1-87b7-04246d812872', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('23f55ae1-3498-4f57-9a62-5ec6af65c27a', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe93', '98e3a17c-4b30-4ed1-87b7-04246d812870', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('5d84fbf5-965d-46c9-89a6-d55906282f0b', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe93', '98e3a17c-4b30-4ed1-87b7-04246d812871', 0);
INSERT INTO public.tasks_to_project_labels VALUES ('3199d77e-9c37-4c9e-9973-e4863e633bfc', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '9c5bf65f-df90-475c-ab01-102cf601fe93', '98e3a17c-4b30-4ed1-87b7-04246d812872', 0);


--
-- TOC entry 5298 (class 0 OID 261610)
-- Dependencies: 327
-- Data for Name: team_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5189 (class 0 OID 260774)
-- Dependencies: 216
-- Data for Name: teams; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.teams VALUES ('7f90ec6b-0cb2-413a-8157-ffc80b1b693e', '2021-06-23 17:43:50.825322+01', '2021-06-23 17:43:50.825322+01', 'Architect (gustave)', 'lime', '7b450b00-c9b5-4332-b087-46af26e8a525', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.teams VALUES ('7f90ec6b-0cb2-413a-8157-ffc80b1b693f', '2021-06-23 17:43:50.825322+01', '2021-06-23 17:43:50.825322+01', 'Builder (gustave)', 'purple', '7b450b00-c9b5-4332-b087-46af26e8a525', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.teams VALUES ('7f90ec6b-0cb2-413a-8157-ffc80b1b6940', '2021-06-23 17:43:50.825322+01', '2021-06-23 17:43:50.825322+01', 'Isolated team ()', 'rose', '7b450b00-c9b5-4332-b087-46af26e8a525', 'b091eda9-e766-46b5-914f-d34940d2267e');
INSERT INTO public.teams VALUES ('7f90ec6b-0cb2-413a-8157-ffc80b1b6950', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'Architect', 'teal', '915e171c-905a-423a-9916-2aa388d6dc7c', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357');
INSERT INTO public.teams VALUES ('7f90ec6b-0cb2-413a-8157-ffc80b1b6951', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'Builder', 'fuchsia', '915e171c-905a-423a-9916-2aa388d6dc7c', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357');
INSERT INTO public.teams VALUES ('7f90ec6b-0cb2-413a-8157-ffc80b1b6952', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'None', 'cyan', '915e171c-905a-423a-9916-2aa388d6dc7c', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357');


--
-- TOC entry 5299 (class 0 OID 261616)
-- Dependencies: 328
-- Data for Name: teams_to_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.teams_to_users VALUES ('5fcf017a-23fc-4f34-a332-7d966c4bcb52', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '7f90ec6b-0cb2-413a-8157-ffc80b1b693e');
INSERT INTO public.teams_to_users VALUES ('88a24c01-6414-4360-8bdf-fe0a1e7a14b3', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'b091eda9-e766-46b5-914f-d34940d2267e', '7f90ec6b-0cb2-413a-8157-ffc80b1b693f');
INSERT INTO public.teams_to_users VALUES ('f89abeaf-7d7c-4f0e-880e-2e6d821be822', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', '7f90ec6b-0cb2-413a-8157-ffc80b1b6950');
INSERT INTO public.teams_to_users VALUES ('cf397213-f57f-4efa-a302-1e0520971803', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', '7f90ec6b-0cb2-413a-8157-ffc80b1b6951');
INSERT INTO public.teams_to_users VALUES ('3e5dcab1-5435-4200-ab07-b48230876531', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a2358', '7f90ec6b-0cb2-413a-8157-ffc80b1b6951');


--
-- TOC entry 5300 (class 0 OID 261622)
-- Dependencies: 329
-- Data for Name: user_actions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.user_actions VALUES ('2cd9aa8b-e78a-4570-a4fc-a34004cc298e', '2021-08-28 09:46:10.349+01', '2021-08-28 09:46:10.349+01', 'b091eda9-e766-46b5-914f-d34940d2267e', '69f1c341-e83f-4bdb-9714-5a7156c8f269', 'USER_INVITED_TO_ORG', '{"org": {"id": "fc9df192-6313-4347-9317-8ee7b37952ba", "name": "clovis"}, "user": {"email": "wale@test.com", "lastName": "walo", "firstName": "wale"}}');


--
-- TOC entry 5301 (class 0 OID 261630)
-- Dependencies: 330
-- Data for Name: user_avatars; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.user_avatars VALUES ('2021-09-09 18:26:39.034496+01', '2021-09-09 18:26:39.034496+01', 'b091eda9-e766-46b5-914f-d34940d2267e', 'user_avatar.jpg', 'userAvatar', 'image/jpeg', 'jpg', 3123);
INSERT INTO public.user_avatars VALUES ('2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', 'a7e70da0-bb65-4e30-b6f5-a86f983a2357', 'user_avatar.jpg', 'userAvatar', 'image/jpeg', 'jpg', 3123);


--
-- TOC entry 5302 (class 0 OID 261637)
-- Dependencies: 331
-- Data for Name: user_connections; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.user_connections VALUES ('a7941ed9-a627-4f08-a0bd-661ae7059f5f', '2021-04-22 14:35:50.49+01', '2021-04-22 14:54:15.001204+01', 'b091eda9-e766-46b5-914f-d34940d2267e', '37.143.52.245', 'Firefox', '88.0', NULL, NULL, NULL, 'Mac OS', '10.15', 'Gecko', '88.0', NULL, NULL);
INSERT INTO public.user_connections VALUES ('d36c4af4-da6d-4ea4-904c-fecdd5d5668e', '2021-04-22 14:38:01.161+01', '2021-04-22 14:54:30.777123+01', 'b091eda9-e766-46b5-914f-d34940d2267e', '37.143.52.245', 'Firefox', '88.0', NULL, NULL, NULL, 'Mac OS', '10.15', 'Gecko', '88.0', NULL, NULL);


--
-- TOC entry 5303 (class 0 OID 261649)
-- Dependencies: 333
-- Data for Name: user_devices; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.user_devices VALUES ('84860f29-aad2-4fe2-b1c7-535fa2630421', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', '1.0.0', 'firebase_sample_token', 'Xiaomi', 'Mi 11 Lite', 'android', '11', 'android', 'Chrome/56.0.2924.87', 'Android Chrome/56.0.2924.87', 'b091eda9-e766-46b5-914f-d34940d2267e');


--
-- TOC entry 5304 (class 0 OID 261657)
-- Dependencies: 334
-- Data for Name: user_locations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.user_locations VALUES ('4773b269-fd7a-4286-8ca8-196c24f53f30', '2021-04-22 14:35:50.525+01', '2021-04-22 14:53:33.56336+01', 'b091eda9-e766-46b5-914f-d34940d2267e', 'a7941ed9-a627-4f08-a0bd-661ae7059f5f', 'FR', 'FRA', 'France', 'Maromme', 49.4762, 1.0182, 'Europe/Paris', 'EU');
INSERT INTO public.user_locations VALUES ('15843d91-65c8-48f1-9863-4efaf36f9c0e', '2021-04-22 14:38:01.196+01', '2021-04-22 14:54:02.687152+01', 'b091eda9-e766-46b5-914f-d34940d2267e', 'd36c4af4-da6d-4ea4-904c-fecdd5d5668e', 'FR', 'FRA', 'France', 'Maromme', 49.4762, 1.0182, 'Europe/Paris', 'EU');


--
-- TOC entry 5305 (class 0 OID 261665)
-- Dependencies: 335
-- Data for Name: user_metadatas; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5306 (class 0 OID 261670)
-- Dependencies: 336
-- Data for Name: user_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5307 (class 0 OID 261676)
-- Dependencies: 337
-- Data for Name: user_notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.user_notifications VALUES ('12041c0f-560d-428a-83c3-30495c0b34ac', '2021-09-04 16:11:44.817+01', '2021-09-04 16:11:44.817+01', 'a7e70da0-bb65-4e30-b6f5-a86f983a139e', 'b091eda9-e766-46b5-914f-d34940d2267e', '69f1c341-e83f-4bdb-9714-5a7156c8f269', NULL, true, 'ORG/USER_INVITED_TO_ORG', '{"org": {"id": "fc9df192-6313-4347-9317-8ee7b37952ba", "name": "clovis"}, "creator": {"email": "gustave@clovis.pro", "lastName": "eiffel", "firstName": "gustave"}, "invited": {"id": "a7e70da0-bb65-4e30-b6f5-a86f983a139e", "email": "wale@test.com", "lastName": "walo", "firstName": "wale"}}');
INSERT INTO public.user_notifications VALUES ('b075875f-34f3-4407-8c02-a469baa5791c', '2021-09-04 16:11:44.817+01', '2021-09-04 16:11:44.817+01', '86c8c162-3405-457c-9724-727aea142580', 'b091eda9-e766-46b5-914f-d34940d2267e', 'da33b272-b51e-4490-b75c-c3722ba8edb4', NULL, true, 'PROJECT/TASK/TASK_UPDATED', '{"task": {"id": "357fb463-97aa-40b9-8ef3-f8ec1dc88f88", "number": 1, "description": "build a wall (Link to Tour Eiffel project)"}, "creator": {"email": "victor@hugo.com", "lastName": "hugo", "firstName": "victor"}, "project": {"id": "7b450b00-c9b5-4332-b087-46af26e8a525", "name": "Tour Eiffel"}}');


--
-- TOC entry 5190 (class 0 OID 260783)
-- Dependencies: 217
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users VALUES ('b091eda9-e766-46b5-914f-d34940d2267e', 'auth0|620b406aa34bca001b45c48c', '2021-04-12 21:05:06.615101+01', '2023-03-05 21:06:42.565072+00', NULL, 'gustave@clovis.pro', 'gustave', 'eiffel', '+33102030405', false, 'en', true, NULL, '61824832e0dcb4152bc6a94f', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('033af847-bded-487c-9228-5f7c5af19ac6', 'auth0|60b61fc374cd72006ecfc79c', '2021-04-23 15:14:42.487555+01', '2023-03-05 21:06:42.565072+00', NULL, 'michel@test.com', 'michel', 'ancel', '+33102030405', false, 'en', false, NULL, '61824832e0dcb4152bc6a95f', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('2c301925-1afd-461b-a5c2-d7930596845d', 'auth0|60b61f9f87801b00682f07c1', '2021-04-23 15:16:28.323782+01', '2023-03-05 21:06:42.565072+00', NULL, 'thierry@test.com', 'thierry', 'henry', '+33102030405', false, 'en', false, NULL, '2c301925-1afd-461b-a5c2-d7930596845d', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('b03640d8-a9b9-46d9-8df3-8b0ba204540f', 'auth0|60b61f77f363fc006959e716', '2021-04-23 15:18:07.489513+01', '2023-03-05 21:06:42.565072+00', NULL, 'jacque@test.com', 'jacque', 'chirac', '+33102030405', false, 'en', false, NULL, 'b03640d8-a9b9-46d9-8df3-8b0ba204540f', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a76a395c-7f16-45d0-b748-8f726134e492', 'auth0|60b61f50d1c753007090ffe0', '2021-04-23 15:20:37.358105+01', '2023-03-05 21:06:42.565072+00', NULL, 'eugène@test.com', 'eugène', 'viollet-le-duc', '+33102030405', false, 'en', false, NULL, 'a76a395c-7f16-45d0-b748-8f726134e492', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('86c8c162-3405-457c-9724-727aea142580', 'auth0|60b61eeba278b7006ab1efc3', '2021-04-22 18:42:47.265775+01', '2023-03-05 21:06:42.565072+00', NULL, 'victor@hugo.com', 'victor', 'hugo', '+33102030405', false, 'en', true, NULL, '61824832e0dcb4152bc6a96f', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('6272c659-9cc9-4125-a91d-b32046e23101', 'auth0|60c34ec6882ff3006fc1af62', '2021-04-22 18:42:47.265775+01', '2023-03-05 21:06:42.565072+00', NULL, 'claire@test.com', 'claire', 'chazal', '+33102030405', false, 'en', true, NULL, '6272c659-9cc9-4125-a91d-b32046e23101', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a109e', 'auth0|60c350f46b1af90068e42c42', '2021-04-22 18:42:47.265775+01', '2023-03-05 21:06:42.565072+00', NULL, 'marie@test.com', 'marie', 'curie', '+33102030405', false, 'en', true, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a109e', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a10aa', 'auth0|6261552aba9e8a00701e5b66', '2021-04-22 18:42:47.265775+01', '2023-03-05 21:06:42.565072+00', NULL, 'isolated@test.com', 'iso', 'late', '+33102030405', false, 'en', true, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a10aa', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a119e', 'auth0|626abdc2c00f38006fabce6b', '2021-04-22 18:42:47.265775+01', '2023-03-05 21:06:42.565072+00', NULL, 'gone@test.com', 'gone', 'craf', '+33102030405', false, 'en', true, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a119e', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a129e', 'auth0|60c350f46b1af90068e42c44', '2021-04-22 18:42:47.265775+01', '2023-03-05 21:06:42.565072+00', NULL, 'alice@test.com', 'alice', 'alor', '+33102030405', false, 'en', true, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a129e', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a149e', 'auth0|60c350f46b1af90068e42c46', '2021-04-22 18:42:47.265775+01', '2023-03-05 21:06:42.565072+00', NULL, 'gere@test.com', 'gere', 'garo', '+33102030405', false, 'en', true, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a149e', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a159e', 'auth0|60c350f46b1af90068e42c47', '2021-04-22 18:42:47.265775+01', '2023-03-05 21:06:42.565072+00', NULL, 'mich@test.com', 'mich', 'loco', '+33102030405', false, 'en', true, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a159e', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a639e', 'auth0|60c350f46b1af90068e42e23', '2021-04-22 18:42:47.265775+01', '2023-03-05 21:06:42.565072+00', NULL, 'wonka@test.com', 'wonka', 'willy', '+33102030405', false, 'en', true, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a639e', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a120e', 'auth0|60c350f46b1af90068e42c48', '2021-04-22 18:42:47.265775+01', '2023-03-05 21:06:42.565072+00', NULL, 'paut@test.com', 'paut', 'craf', '+33102030405', false, 'en', true, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a120e', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a139e', 'auth0|60c350f46b1af90068e42c45', '2021-04-22 18:42:47.265775+01', '2023-03-05 21:06:42.565072+00', NULL, 'wale@test.com', 'wale', 'walo', '+33102030405', false, 'en', true, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a139e', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a2345', 'auth0|60c350f46b1af90068e42c99', '2021-04-22 18:42:47.265775+01', '2023-03-05 21:06:42.565072+00', NULL, 'jourwal@test.com', 'jourwal', 'miral', '+33102030405', false, 'en', true, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a2345', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a2346', 'auth0|60c350f46b1af90068e42c9a', '2021-04-22 18:42:47.265775+01', '2023-03-05 21:06:42.565072+00', NULL, 'withoutorg@test.com', 'no', 'org', '+33102030405', false, 'en', true, NULL, 'a7e70da0-bb65-4e30-b6f5-a86f983a2346', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a2358', 'auth0|620cf48b2446b90069eb38a1', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', NULL, 'dev+tasksreport2@clovis.pro', 'Christopher', 'Tucker', '+33102030405', false, 'en', false, NULL, '6ffc091d-c890-4410-8baa-bf168273a04e', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a2357', 'auth0|620cf44fdec63c006aeb27a2', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', NULL, 'dev+tasksreport@clovis.pro', 'Pierre-Emmanuel, Charles-Étienne, Christian-Jacques', 'Rutherford de Saint-Remy-en-Bouzemont-Saint-Genest-et-Isson', '+33102030405', false, 'en', false, NULL, 'df6654ea-36df-4bda-b86a-846fd398dbd2', false, 'Europe/Paris', false);
INSERT INTO public.users VALUES ('a7e70da0-bb65-4e30-b6f5-a86f983a2359', 'auth0|620cf4c2e7df8a006a6c8a58', '2023-03-05 21:06:42.565072+00', '2023-03-05 21:06:42.565072+00', NULL, 'dev+tasksreport3@clovis.pro', 'Joe', 'Lee', '+33102030405', false, 'en', false, NULL, 'e72402aa-ab5a-43b6-afaa-6f7b892cc47c', false, 'Europe/Paris', false);


--
-- TOC entry 5367 (class 0 OID 0)
-- Dependencies: 263
-- Name: file_views_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.file_views_id_seq', 1, false);


--
-- TOC entry 5368 (class 0 OID 0)
-- Dependencies: 276
-- Name: folder_views_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.folder_views_id_seq', 1, false);


--
-- TOC entry 5369 (class 0 OID 0)
-- Dependencies: 306
-- Name: project_views_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.project_views_id_seq', 1, false);


--
-- TOC entry 5370 (class 0 OID 0)
-- Dependencies: 324
-- Name: task_views_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.task_views_id_seq', 1, true);


--
-- TOC entry 4481 (class 2606 OID 261691)
-- Name: event_invocation_logs event_invocation_logs_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.event_invocation_logs
    ADD CONSTRAINT event_invocation_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4484 (class 2606 OID 261693)
-- Name: event_log event_log_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.event_log
    ADD CONSTRAINT event_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4487 (class 2606 OID 261695)
-- Name: hdb_action_log hdb_action_log_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_action_log
    ADD CONSTRAINT hdb_action_log_pkey PRIMARY KEY (id);


--
-- TOC entry 4490 (class 2606 OID 261697)
-- Name: hdb_cron_event_invocation_logs hdb_cron_event_invocation_logs_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_cron_event_invocation_logs
    ADD CONSTRAINT hdb_cron_event_invocation_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4493 (class 2606 OID 261699)
-- Name: hdb_cron_events hdb_cron_events_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_cron_events
    ADD CONSTRAINT hdb_cron_events_pkey PRIMARY KEY (id);


--
-- TOC entry 4496 (class 2606 OID 261701)
-- Name: hdb_metadata hdb_metadata_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_metadata
    ADD CONSTRAINT hdb_metadata_pkey PRIMARY KEY (id);


--
-- TOC entry 4498 (class 2606 OID 261703)
-- Name: hdb_metadata hdb_metadata_resource_version_key; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_metadata
    ADD CONSTRAINT hdb_metadata_resource_version_key UNIQUE (resource_version);


--
-- TOC entry 4500 (class 2606 OID 261705)
-- Name: hdb_scheduled_event_invocation_logs hdb_scheduled_event_invocation_logs_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_scheduled_event_invocation_logs
    ADD CONSTRAINT hdb_scheduled_event_invocation_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4503 (class 2606 OID 261707)
-- Name: hdb_scheduled_events hdb_scheduled_events_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_scheduled_events
    ADD CONSTRAINT hdb_scheduled_events_pkey PRIMARY KEY (id);


--
-- TOC entry 4505 (class 2606 OID 261709)
-- Name: hdb_schema_notifications hdb_schema_notifications_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_schema_notifications
    ADD CONSTRAINT hdb_schema_notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 4509 (class 2606 OID 261711)
-- Name: hdb_version hdb_version_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_version
    ADD CONSTRAINT hdb_version_pkey PRIMARY KEY (hasura_uuid);


--
-- TOC entry 4511 (class 2606 OID 261713)
-- Name: email_notifications email_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_notifications
    ADD CONSTRAINT email_notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 4513 (class 2606 OID 261715)
-- Name: email_notifications email_notifications_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_notifications
    ADD CONSTRAINT email_notifications_user_id_key UNIQUE (user_id);


--
-- TOC entry 4515 (class 2606 OID 261717)
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- TOC entry 4519 (class 2606 OID 261719)
-- Name: events_workers_status events_workers_status_event_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events_workers_status
    ADD CONSTRAINT events_workers_status_event_id_key UNIQUE (event_id);


--
-- TOC entry 4521 (class 2606 OID 261721)
-- Name: events_workers_status events_workers_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events_workers_status
    ADD CONSTRAINT events_workers_status_pkey PRIMARY KEY (id);


--
-- TOC entry 4523 (class 2606 OID 261723)
-- Name: file_access_enum file_access_enum_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_access_enum
    ADD CONSTRAINT file_access_enum_pkey PRIMARY KEY (value);


--
-- TOC entry 4465 (class 2606 OID 261725)
-- Name: file_approvals file_approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_approvals
    ADD CONSTRAINT file_approvals_pkey PRIMARY KEY (id);


--
-- TOC entry 4525 (class 2606 OID 261727)
-- Name: file_approvals_status_enum file_approvals_status_enum_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_approvals_status_enum
    ADD CONSTRAINT file_approvals_status_enum_pkey PRIMARY KEY (value);


--
-- TOC entry 4467 (class 2606 OID 261729)
-- Name: file_approvals file_approvals_user_id_file_version_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_approvals
    ADD CONSTRAINT file_approvals_user_id_file_version_id_key UNIQUE (user_id, file_version_id);


--
-- TOC entry 4527 (class 2606 OID 261731)
-- Name: file_assignation_migrations file_assignation_migrations_old_file_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignation_migrations
    ADD CONSTRAINT file_assignation_migrations_old_file_id_key UNIQUE (old_file_id);


--
-- TOC entry 4529 (class 2606 OID 261733)
-- Name: file_assignation_migrations file_assignation_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignation_migrations
    ADD CONSTRAINT file_assignation_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4409 (class 2606 OID 261735)
-- Name: file_assignations file_assignations_file_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations
    ADD CONSTRAINT file_assignations_file_id_key UNIQUE (file_id);


--
-- TOC entry 4531 (class 2606 OID 261737)
-- Name: file_assignations_orgs file_assignations_orgs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_orgs
    ADD CONSTRAINT file_assignations_orgs_pkey PRIMARY KEY (id);


--
-- TOC entry 4411 (class 2606 OID 261739)
-- Name: file_assignations file_assignations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations
    ADD CONSTRAINT file_assignations_pkey PRIMARY KEY (id);


--
-- TOC entry 4535 (class 2606 OID 261741)
-- Name: file_assignations_teams file_assignations_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_teams
    ADD CONSTRAINT file_assignations_teams_pkey PRIMARY KEY (id);


--
-- TOC entry 4539 (class 2606 OID 261743)
-- Name: file_assignations_users file_assignations_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_users
    ADD CONSTRAINT file_assignations_users_pkey PRIMARY KEY (id);


--
-- TOC entry 4543 (class 2606 OID 261745)
-- Name: file_comments file_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_comments
    ADD CONSTRAINT file_comments_pkey PRIMARY KEY (id);


--
-- TOC entry 4545 (class 2606 OID 261747)
-- Name: file_label_migrations file_label_migrations_old_label_id_old_file_id_old_project__key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_label_migrations
    ADD CONSTRAINT file_label_migrations_old_label_id_old_file_id_old_project__key UNIQUE (old_label_id, old_file_id, old_project_id);


--
-- TOC entry 4547 (class 2606 OID 261749)
-- Name: file_label_migrations file_label_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_label_migrations
    ADD CONSTRAINT file_label_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4549 (class 2606 OID 261751)
-- Name: file_migrations file_migrations_old_project_id_old_folder_id_old_file_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_migrations
    ADD CONSTRAINT file_migrations_old_project_id_old_folder_id_old_file_id_key UNIQUE (old_project_id, old_folder_id, old_file_id);


--
-- TOC entry 4551 (class 2606 OID 261753)
-- Name: file_migrations file_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_migrations
    ADD CONSTRAINT file_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4431 (class 2606 OID 261755)
-- Name: file_permissions file_permissions_file_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions
    ADD CONSTRAINT file_permissions_file_id_key UNIQUE (file_id);


--
-- TOC entry 4553 (class 2606 OID 261757)
-- Name: file_permissions_orgs file_permissions_orgs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_orgs
    ADD CONSTRAINT file_permissions_orgs_pkey PRIMARY KEY (id);


--
-- TOC entry 4433 (class 2606 OID 261759)
-- Name: file_permissions file_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions
    ADD CONSTRAINT file_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 4557 (class 2606 OID 261761)
-- Name: file_permissions_teams file_permissions_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_teams
    ADD CONSTRAINT file_permissions_teams_pkey PRIMARY KEY (id);


--
-- TOC entry 4561 (class 2606 OID 261763)
-- Name: file_permissions_users file_permissions_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_users
    ADD CONSTRAINT file_permissions_users_pkey PRIMARY KEY (id);


--
-- TOC entry 4565 (class 2606 OID 261765)
-- Name: file_signatures file_signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_signatures
    ADD CONSTRAINT file_signatures_pkey PRIMARY KEY (id);


--
-- TOC entry 4567 (class 2606 OID 261767)
-- Name: file_version_approval_migrations file_version_approval_migrati_old_project_id_old_folder_id__key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_approval_migrations
    ADD CONSTRAINT file_version_approval_migrati_old_project_id_old_folder_id__key UNIQUE (old_project_id, old_folder_id, old_file_id, old_file_version_id);


--
-- TOC entry 4569 (class 2606 OID 261769)
-- Name: file_version_approval_migrations file_version_approval_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_approval_migrations
    ADD CONSTRAINT file_version_approval_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4571 (class 2606 OID 261771)
-- Name: file_version_approval_request_users file_version_approval_request_file_version_approval_request_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_approval_request_users
    ADD CONSTRAINT file_version_approval_request_file_version_approval_request_key UNIQUE (file_version_approval_request_id, user_id);


--
-- TOC entry 4573 (class 2606 OID 261773)
-- Name: file_version_approval_request_users file_version_approval_request_users_file_approval_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_approval_request_users
    ADD CONSTRAINT file_version_approval_request_users_file_approval_id_key UNIQUE (file_approval_id);


--
-- TOC entry 4575 (class 2606 OID 261775)
-- Name: file_version_approval_request_users file_version_approval_request_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_approval_request_users
    ADD CONSTRAINT file_version_approval_request_users_pkey PRIMARY KEY (id);


--
-- TOC entry 4443 (class 2606 OID 261777)
-- Name: file_version_approval_requests file_version_approval_requests_file_version_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_approval_requests
    ADD CONSTRAINT file_version_approval_requests_file_version_id_key UNIQUE (file_version_id);


--
-- TOC entry 4445 (class 2606 OID 261779)
-- Name: file_version_approval_requests file_version_approval_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_approval_requests
    ADD CONSTRAINT file_version_approval_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 4577 (class 2606 OID 261781)
-- Name: file_version_migrations file_version_migrations_old_project_id_old_folder_id_old_fi_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_migrations
    ADD CONSTRAINT file_version_migrations_old_project_id_old_folder_id_old_fi_key UNIQUE (old_project_id, old_folder_id, old_file_id, old_file_version_id);


--
-- TOC entry 4579 (class 2606 OID 261783)
-- Name: file_version_migrations file_version_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_migrations
    ADD CONSTRAINT file_version_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4581 (class 2606 OID 261785)
-- Name: file_version_wopi file_version_wopi_file_version_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_wopi
    ADD CONSTRAINT file_version_wopi_file_version_id_key UNIQUE (file_version_id);


--
-- TOC entry 4583 (class 2606 OID 261787)
-- Name: file_version_wopi file_version_wopi_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_wopi
    ADD CONSTRAINT file_version_wopi_pkey PRIMARY KEY (id);


--
-- TOC entry 4437 (class 2606 OID 261789)
-- Name: file_versions file_versions_file_id_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_versions
    ADD CONSTRAINT file_versions_file_id_number_key UNIQUE (file_id, number);


--
-- TOC entry 4439 (class 2606 OID 261791)
-- Name: file_versions file_versions_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_versions
    ADD CONSTRAINT file_versions_key_key UNIQUE (key);


--
-- TOC entry 4441 (class 2606 OID 261793)
-- Name: file_versions file_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_versions
    ADD CONSTRAINT file_versions_pkey PRIMARY KEY (id);


--
-- TOC entry 4586 (class 2606 OID 261795)
-- Name: file_views file_views_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_views
    ADD CONSTRAINT file_views_pkey PRIMARY KEY (id);


--
-- TOC entry 4415 (class 2606 OID 261797)
-- Name: files files_name_parent_id_project_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_name_parent_id_project_id_key UNIQUE (name, parent_id, project_id);


--
-- TOC entry 4418 (class 2606 OID 261799)
-- Name: files files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- TOC entry 4588 (class 2606 OID 261801)
-- Name: files_to_project_labels files_to_project_labels_file_id_project_label_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files_to_project_labels
    ADD CONSTRAINT files_to_project_labels_file_id_project_label_id_key UNIQUE (file_id, project_label_id);


--
-- TOC entry 4590 (class 2606 OID 261803)
-- Name: files_to_project_labels files_to_project_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files_to_project_labels
    ADD CONSTRAINT files_to_project_labels_pkey PRIMARY KEY (id);


--
-- TOC entry 4592 (class 2606 OID 261805)
-- Name: folder_access_enum folder_access_enum_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_access_enum
    ADD CONSTRAINT folder_access_enum_pkey PRIMARY KEY (value);


--
-- TOC entry 4594 (class 2606 OID 261807)
-- Name: folder_assignation_migrations folder_assignation_migrations_old_folder_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignation_migrations
    ADD CONSTRAINT folder_assignation_migrations_old_folder_id_key UNIQUE (old_folder_id);


--
-- TOC entry 4596 (class 2606 OID 261809)
-- Name: folder_assignation_migrations folder_assignation_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignation_migrations
    ADD CONSTRAINT folder_assignation_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4447 (class 2606 OID 261811)
-- Name: folder_assignations folder_assignations_folder_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations
    ADD CONSTRAINT folder_assignations_folder_id_key UNIQUE (folder_id);


--
-- TOC entry 4598 (class 2606 OID 261813)
-- Name: folder_assignations_orgs folder_assignations_orgs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_orgs
    ADD CONSTRAINT folder_assignations_orgs_pkey PRIMARY KEY (id);


--
-- TOC entry 4449 (class 2606 OID 261815)
-- Name: folder_assignations folder_assignations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations
    ADD CONSTRAINT folder_assignations_pkey PRIMARY KEY (id);


--
-- TOC entry 4602 (class 2606 OID 261817)
-- Name: folder_assignations_teams folder_assignations_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_teams
    ADD CONSTRAINT folder_assignations_teams_pkey PRIMARY KEY (id);


--
-- TOC entry 4606 (class 2606 OID 261819)
-- Name: folder_assignations_users folder_assignations_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_users
    ADD CONSTRAINT folder_assignations_users_pkey PRIMARY KEY (id);


--
-- TOC entry 4610 (class 2606 OID 261821)
-- Name: folder_label_migrations folder_label_migrations_old_label_id_old_folder_id_old_proj_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_label_migrations
    ADD CONSTRAINT folder_label_migrations_old_label_id_old_folder_id_old_proj_key UNIQUE (old_label_id, old_folder_id, old_project_id);


--
-- TOC entry 4612 (class 2606 OID 261823)
-- Name: folder_label_migrations folder_label_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_label_migrations
    ADD CONSTRAINT folder_label_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4614 (class 2606 OID 261825)
-- Name: folder_migrations folder_migrations_old_project_id_old_folder_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_migrations
    ADD CONSTRAINT folder_migrations_old_project_id_old_folder_id_key UNIQUE (old_project_id, old_folder_id);


--
-- TOC entry 4616 (class 2606 OID 261827)
-- Name: folder_migrations folder_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_migrations
    ADD CONSTRAINT folder_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4403 (class 2606 OID 261829)
-- Name: folder_permissions folder_permissions_folder_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions
    ADD CONSTRAINT folder_permissions_folder_id_key UNIQUE (folder_id);


--
-- TOC entry 4618 (class 2606 OID 261831)
-- Name: folder_permissions_orgs folder_permissions_orgs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_orgs
    ADD CONSTRAINT folder_permissions_orgs_pkey PRIMARY KEY (id);


--
-- TOC entry 4405 (class 2606 OID 261833)
-- Name: folder_permissions folder_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions
    ADD CONSTRAINT folder_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 4622 (class 2606 OID 261835)
-- Name: folder_permissions_teams folder_permissions_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_teams
    ADD CONSTRAINT folder_permissions_teams_pkey PRIMARY KEY (id);


--
-- TOC entry 4626 (class 2606 OID 261837)
-- Name: folder_permissions_users folder_permissions_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_users
    ADD CONSTRAINT folder_permissions_users_pkey PRIMARY KEY (id);


--
-- TOC entry 4630 (class 2606 OID 261839)
-- Name: folder_views folder_views_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_views
    ADD CONSTRAINT folder_views_pkey PRIMARY KEY (id);


--
-- TOC entry 4455 (class 2606 OID 261841)
-- Name: folders folders_name_parent_id_project_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folders
    ADD CONSTRAINT folders_name_parent_id_project_id_key UNIQUE (name, parent_id, project_id);


--
-- TOC entry 4457 (class 2606 OID 261843)
-- Name: folders folders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folders
    ADD CONSTRAINT folders_pkey PRIMARY KEY (id);


--
-- TOC entry 4632 (class 2606 OID 261845)
-- Name: folders_to_project_labels folders_to_project_labels_folder_id_project_label_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folders_to_project_labels
    ADD CONSTRAINT folders_to_project_labels_folder_id_project_label_id_key UNIQUE (folder_id, project_label_id);


--
-- TOC entry 4634 (class 2606 OID 261847)
-- Name: folders_to_project_labels folders_to_project_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folders_to_project_labels
    ADD CONSTRAINT folders_to_project_labels_pkey PRIMARY KEY (id);


--
-- TOC entry 4636 (class 2606 OID 261849)
-- Name: org_address org_address_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_address
    ADD CONSTRAINT org_address_pkey PRIMARY KEY (org_id);


--
-- TOC entry 4638 (class 2606 OID 261851)
-- Name: org_avatars org_avatars_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_avatars
    ADD CONSTRAINT org_avatars_pkey PRIMARY KEY (org_id);


--
-- TOC entry 4640 (class 2606 OID 261853)
-- Name: org_backgrounds org_backgrounds_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_backgrounds
    ADD CONSTRAINT org_backgrounds_pkey PRIMARY KEY (org_id);


--
-- TOC entry 4642 (class 2606 OID 261855)
-- Name: org_licenses org_licenses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_licenses
    ADD CONSTRAINT org_licenses_pkey PRIMARY KEY (org_id);


--
-- TOC entry 4644 (class 2606 OID 261857)
-- Name: org_member_migrations org_member_migrations_old_user_id_old_org_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_member_migrations
    ADD CONSTRAINT org_member_migrations_old_user_id_old_org_id_key UNIQUE (old_user_id, old_org_id);


--
-- TOC entry 4646 (class 2606 OID 261859)
-- Name: org_member_migrations org_member_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_member_migrations
    ADD CONSTRAINT org_member_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4648 (class 2606 OID 261861)
-- Name: org_migrations org_migrations_new_org_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_migrations
    ADD CONSTRAINT org_migrations_new_org_id_key UNIQUE (new_org_id);


--
-- TOC entry 4650 (class 2606 OID 261863)
-- Name: org_migrations org_migrations_old_org_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_migrations
    ADD CONSTRAINT org_migrations_old_org_id_key UNIQUE (old_org_id);


--
-- TOC entry 4652 (class 2606 OID 261865)
-- Name: org_migrations org_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_migrations
    ADD CONSTRAINT org_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4654 (class 2606 OID 261867)
-- Name: org_project_summary_migrations org_project_summary_migrations_new_project_id_new_org_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_project_summary_migrations
    ADD CONSTRAINT org_project_summary_migrations_new_project_id_new_org_id_key UNIQUE (new_project_id, new_org_id);


--
-- TOC entry 4656 (class 2606 OID 261869)
-- Name: org_project_summary_migrations org_project_summary_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_project_summary_migrations
    ADD CONSTRAINT org_project_summary_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4472 (class 2606 OID 261871)
-- Name: org_project_summary org_project_summary_org_id_project_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_project_summary
    ADD CONSTRAINT org_project_summary_org_id_project_id_key UNIQUE (org_id, project_id);


--
-- TOC entry 4474 (class 2606 OID 261873)
-- Name: org_project_summary org_project_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_project_summary
    ADD CONSTRAINT org_project_summary_pkey PRIMARY KEY (id);


--
-- TOC entry 4658 (class 2606 OID 261875)
-- Name: org_project_summary_to_project_categories org_project_summary_to_project_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_project_summary_to_project_categories
    ADD CONSTRAINT org_project_summary_to_project_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 4660 (class 2606 OID 261877)
-- Name: org_roles org_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_roles
    ADD CONSTRAINT org_roles_pkey PRIMARY KEY (name);


--
-- TOC entry 4421 (class 2606 OID 261879)
-- Name: orgs orgs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgs
    ADD CONSTRAINT orgs_pkey PRIMARY KEY (id);


--
-- TOC entry 4672 (class 2606 OID 261881)
-- Name: orgs_to_user_actions orgs_to_user_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgs_to_user_actions
    ADD CONSTRAINT orgs_to_user_actions_pkey PRIMARY KEY (id);


--
-- TOC entry 4662 (class 2606 OID 261883)
-- Name: orgs_to_users orgs_to_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgs_to_users
    ADD CONSTRAINT orgs_to_users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4664 (class 2606 OID 261885)
-- Name: orgs_to_users orgs_to_users_user_id_org_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgs_to_users
    ADD CONSTRAINT orgs_to_users_user_id_org_id_key UNIQUE (user_id, org_id);


--
-- TOC entry 4675 (class 2606 OID 261887)
-- Name: presigned_urls presigned_urls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.presigned_urls
    ADD CONSTRAINT presigned_urls_pkey PRIMARY KEY (key);


--
-- TOC entry 4677 (class 2606 OID 261889)
-- Name: project_address project_address_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_address
    ADD CONSTRAINT project_address_pkey PRIMARY KEY (project_id);


--
-- TOC entry 4679 (class 2606 OID 261891)
-- Name: project_avatars project_avatars_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_avatars
    ADD CONSTRAINT project_avatars_pkey PRIMARY KEY (project_id);


--
-- TOC entry 4681 (class 2606 OID 261893)
-- Name: project_backgrounds project_backgrounds_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_backgrounds
    ADD CONSTRAINT project_backgrounds_pkey PRIMARY KEY (project_id);


--
-- TOC entry 4683 (class 2606 OID 261895)
-- Name: project_banners project_banners_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_banners
    ADD CONSTRAINT project_banners_pkey PRIMARY KEY (project_id);


--
-- TOC entry 4687 (class 2606 OID 261897)
-- Name: project_categories_migrations project_categories_migrations_new_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_categories_migrations
    ADD CONSTRAINT project_categories_migrations_new_id_key UNIQUE (new_id);


--
-- TOC entry 4689 (class 2606 OID 261899)
-- Name: project_categories_migrations project_categories_migrations_old_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_categories_migrations
    ADD CONSTRAINT project_categories_migrations_old_id_key UNIQUE (old_id);


--
-- TOC entry 4691 (class 2606 OID 261901)
-- Name: project_categories_migrations project_categories_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_categories_migrations
    ADD CONSTRAINT project_categories_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4685 (class 2606 OID 261903)
-- Name: project_categories project_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_categories
    ADD CONSTRAINT project_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 4695 (class 2606 OID 261905)
-- Name: project_labels_migrations project_labels_migrations_old_id_new_id_old_project_id_new__key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_labels_migrations
    ADD CONSTRAINT project_labels_migrations_old_id_new_id_old_project_id_new__key UNIQUE (old_id, new_id, old_project_id, new_project_id);


--
-- TOC entry 4697 (class 2606 OID 261907)
-- Name: project_labels_migrations project_labels_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_labels_migrations
    ADD CONSTRAINT project_labels_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4693 (class 2606 OID 261909)
-- Name: project_labels project_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_labels
    ADD CONSTRAINT project_labels_pkey PRIMARY KEY (id);


--
-- TOC entry 4699 (class 2606 OID 261911)
-- Name: project_member_migrations project_member_migrations_old_user_id_old_project_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_member_migrations
    ADD CONSTRAINT project_member_migrations_old_user_id_old_project_id_key UNIQUE (old_user_id, old_project_id);


--
-- TOC entry 4701 (class 2606 OID 261913)
-- Name: project_member_migrations project_member_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_member_migrations
    ADD CONSTRAINT project_member_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4703 (class 2606 OID 261915)
-- Name: project_migrations project_migrations_new_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_migrations
    ADD CONSTRAINT project_migrations_new_id_key UNIQUE (new_id);


--
-- TOC entry 4705 (class 2606 OID 261917)
-- Name: project_migrations project_migrations_old_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_migrations
    ADD CONSTRAINT project_migrations_old_id_key UNIQUE (old_id);


--
-- TOC entry 4707 (class 2606 OID 261919)
-- Name: project_migrations project_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_migrations
    ADD CONSTRAINT project_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4709 (class 2606 OID 261921)
-- Name: project_roles project_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_roles
    ADD CONSTRAINT project_roles_pkey PRIMARY KEY (name);


--
-- TOC entry 4711 (class 2606 OID 261923)
-- Name: project_templates project_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_templates
    ADD CONSTRAINT project_templates_pkey PRIMARY KEY (id);


--
-- TOC entry 4713 (class 2606 OID 261925)
-- Name: project_templates project_templates_project_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_templates
    ADD CONSTRAINT project_templates_project_id_key UNIQUE (project_id);


--
-- TOC entry 4715 (class 2606 OID 261927)
-- Name: project_templates project_templates_type_language_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_templates
    ADD CONSTRAINT project_templates_type_language_key UNIQUE (type, language);


--
-- TOC entry 4717 (class 2606 OID 261929)
-- Name: project_views project_views_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_views
    ADD CONSTRAINT project_views_pkey PRIMARY KEY (id);


--
-- TOC entry 4463 (class 2606 OID 261931)
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- TOC entry 4667 (class 2606 OID 261933)
-- Name: projects_to_users projects_to_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_to_users
    ADD CONSTRAINT projects_to_users_pkey PRIMARY KEY (id);


--
-- TOC entry 4669 (class 2606 OID 261935)
-- Name: projects_to_users projects_to_users_user_id_project_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_to_users
    ADD CONSTRAINT projects_to_users_user_id_project_id_key UNIQUE (user_id, project_id);


--
-- TOC entry 4719 (class 2606 OID 261937)
-- Name: push_notifications push_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.push_notifications
    ADD CONSTRAINT push_notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 4721 (class 2606 OID 261939)
-- Name: push_notifications push_notifications_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.push_notifications
    ADD CONSTRAINT push_notifications_user_id_key UNIQUE (user_id);


--
-- TOC entry 4723 (class 2606 OID 261941)
-- Name: subtask_migrations subtask_migrations_old_id_old_task_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subtask_migrations
    ADD CONSTRAINT subtask_migrations_old_id_old_task_id_key UNIQUE (old_id, old_task_id);


--
-- TOC entry 4725 (class 2606 OID 261943)
-- Name: subtask_migrations subtask_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subtask_migrations
    ADD CONSTRAINT subtask_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4470 (class 2606 OID 261945)
-- Name: t_folder_notification_badge t_folder_notification_badge_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_folder_notification_badge
    ADD CONSTRAINT t_folder_notification_badge_pkey PRIMARY KEY (folder_id);


--
-- TOC entry 4461 (class 2606 OID 261947)
-- Name: t_folder_pwd t_folder_pwd_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_folder_pwd
    ADD CONSTRAINT t_folder_pwd_pkey PRIMARY KEY (id);


--
-- TOC entry 4727 (class 2606 OID 261949)
-- Name: task_assignation_migrations task_assignation_migrations_old_task_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignation_migrations
    ADD CONSTRAINT task_assignation_migrations_old_task_id_key UNIQUE (old_task_id);


--
-- TOC entry 4729 (class 2606 OID 261951)
-- Name: task_assignation_migrations task_assignation_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignation_migrations
    ADD CONSTRAINT task_assignation_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4735 (class 2606 OID 261953)
-- Name: task_assignations_orgs task_assignations_orgs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations_orgs
    ADD CONSTRAINT task_assignations_orgs_pkey PRIMARY KEY (id);


--
-- TOC entry 4737 (class 2606 OID 261955)
-- Name: task_assignations_orgs task_assignations_orgs_task_assignation_id_org_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations_orgs
    ADD CONSTRAINT task_assignations_orgs_task_assignation_id_org_id_key UNIQUE (task_assignation_id, org_id);


--
-- TOC entry 4731 (class 2606 OID 261957)
-- Name: task_assignations task_assignations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations
    ADD CONSTRAINT task_assignations_pkey PRIMARY KEY (id);


--
-- TOC entry 4733 (class 2606 OID 261959)
-- Name: task_assignations task_assignations_task_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations
    ADD CONSTRAINT task_assignations_task_id_key UNIQUE (task_id);


--
-- TOC entry 4739 (class 2606 OID 261961)
-- Name: task_assignations_teams task_assignations_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations_teams
    ADD CONSTRAINT task_assignations_teams_pkey PRIMARY KEY (id);


--
-- TOC entry 4741 (class 2606 OID 261963)
-- Name: task_assignations_teams task_assignations_teams_task_assignation_id_team_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations_teams
    ADD CONSTRAINT task_assignations_teams_task_assignation_id_team_id_key UNIQUE (task_assignation_id, team_id);


--
-- TOC entry 4743 (class 2606 OID 261965)
-- Name: task_assignations_users task_assignations_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations_users
    ADD CONSTRAINT task_assignations_users_pkey PRIMARY KEY (id);


--
-- TOC entry 4745 (class 2606 OID 261967)
-- Name: task_assignations_users task_assignations_users_task_assignation_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations_users
    ADD CONSTRAINT task_assignations_users_task_assignation_id_user_id_key UNIQUE (task_assignation_id, user_id);


--
-- TOC entry 4747 (class 2606 OID 261969)
-- Name: task_attachment_migrations task_attachment_migrations_old_key_prefix_old_task_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_attachment_migrations
    ADD CONSTRAINT task_attachment_migrations_old_key_prefix_old_task_id_key UNIQUE (old_key_prefix, old_task_id);


--
-- TOC entry 4749 (class 2606 OID 261971)
-- Name: task_attachment_migrations task_attachment_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_attachment_migrations
    ADD CONSTRAINT task_attachment_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4751 (class 2606 OID 261973)
-- Name: task_attachments task_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_attachments
    ADD CONSTRAINT task_attachments_pkey PRIMARY KEY (id);


--
-- TOC entry 4753 (class 2606 OID 261975)
-- Name: task_file_version_location task_file_version_location_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_file_version_location
    ADD CONSTRAINT task_file_version_location_pkey PRIMARY KEY (id);


--
-- TOC entry 4755 (class 2606 OID 261977)
-- Name: task_label_migrations task_label_migrations_old_label_id_old_task_id_old_project__key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_label_migrations
    ADD CONSTRAINT task_label_migrations_old_label_id_old_task_id_old_project__key UNIQUE (old_label_id, old_task_id, old_project_id);


--
-- TOC entry 4757 (class 2606 OID 261979)
-- Name: task_label_migrations task_label_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_label_migrations
    ADD CONSTRAINT task_label_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4759 (class 2606 OID 261981)
-- Name: task_locations task_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_locations
    ADD CONSTRAINT task_locations_pkey PRIMARY KEY (task_id);


--
-- TOC entry 4761 (class 2606 OID 261983)
-- Name: task_migrations task_migrations_old_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_migrations
    ADD CONSTRAINT task_migrations_old_id_key UNIQUE (old_id);


--
-- TOC entry 4763 (class 2606 OID 261985)
-- Name: task_migrations task_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_migrations
    ADD CONSTRAINT task_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4765 (class 2606 OID 261987)
-- Name: task_subtasks task_subtasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_subtasks
    ADD CONSTRAINT task_subtasks_pkey PRIMARY KEY (id);


--
-- TOC entry 4767 (class 2606 OID 261989)
-- Name: task_validation_migrations task_validation_migrations_old_task_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_validation_migrations
    ADD CONSTRAINT task_validation_migrations_old_task_id_key UNIQUE (old_task_id);


--
-- TOC entry 4769 (class 2606 OID 261991)
-- Name: task_validation_migrations task_validation_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_validation_migrations
    ADD CONSTRAINT task_validation_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4771 (class 2606 OID 261993)
-- Name: task_validations task_validations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_validations
    ADD CONSTRAINT task_validations_pkey PRIMARY KEY (id);


--
-- TOC entry 4773 (class 2606 OID 261995)
-- Name: task_validations task_validations_task_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_validations
    ADD CONSTRAINT task_validations_task_id_user_id_key UNIQUE (task_id, user_id);


--
-- TOC entry 4775 (class 2606 OID 261997)
-- Name: task_views task_views_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_views
    ADD CONSTRAINT task_views_pkey PRIMARY KEY (id);


--
-- TOC entry 4777 (class 2606 OID 261999)
-- Name: tasks_file_versions tasks_file_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks_file_versions
    ADD CONSTRAINT tasks_file_versions_pkey PRIMARY KEY (id);


--
-- TOC entry 4779 (class 2606 OID 262001)
-- Name: tasks_file_versions tasks_file_versions_task_id_file_version_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks_file_versions
    ADD CONSTRAINT tasks_file_versions_task_id_file_version_id_key UNIQUE (task_id, file_version_id);


--
-- TOC entry 4476 (class 2606 OID 262003)
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- TOC entry 4478 (class 2606 OID 262005)
-- Name: tasks tasks_project_id_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_project_id_number_key UNIQUE (project_id, number);


--
-- TOC entry 4781 (class 2606 OID 262007)
-- Name: tasks_to_project_labels tasks_to_project_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks_to_project_labels
    ADD CONSTRAINT tasks_to_project_labels_pkey PRIMARY KEY (id);


--
-- TOC entry 4783 (class 2606 OID 262009)
-- Name: tasks_to_project_labels tasks_to_project_labels_task_id_project_label_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks_to_project_labels
    ADD CONSTRAINT tasks_to_project_labels_task_id_project_label_id_key UNIQUE (task_id, project_label_id);


--
-- TOC entry 4785 (class 2606 OID 262011)
-- Name: team_migrations team_migrations_old_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_migrations
    ADD CONSTRAINT team_migrations_old_id_key UNIQUE (old_id);


--
-- TOC entry 4787 (class 2606 OID 262013)
-- Name: team_migrations team_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_migrations
    ADD CONSTRAINT team_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4423 (class 2606 OID 262015)
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- TOC entry 4789 (class 2606 OID 262017)
-- Name: teams_to_users teams_to_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teams_to_users
    ADD CONSTRAINT teams_to_users_pkey PRIMARY KEY (id);


--
-- TOC entry 4791 (class 2606 OID 262019)
-- Name: teams_to_users teams_to_users_user_id_team_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teams_to_users
    ADD CONSTRAINT teams_to_users_user_id_team_id_key UNIQUE (user_id, team_id);


--
-- TOC entry 4413 (class 2606 OID 262021)
-- Name: file_assignations unique_assignation_by_file_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations
    ADD CONSTRAINT unique_assignation_by_file_id UNIQUE (file_id);


--
-- TOC entry 4451 (class 2606 OID 262023)
-- Name: folder_assignations unique_assignation_by_folder_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations
    ADD CONSTRAINT unique_assignation_by_folder_id UNIQUE (folder_id);


--
-- TOC entry 4533 (class 2606 OID 262025)
-- Name: file_assignations_orgs unique_org_by_file_assignation_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_orgs
    ADD CONSTRAINT unique_org_by_file_assignation_id UNIQUE (file_assignation_id, org_id);


--
-- TOC entry 4555 (class 2606 OID 262027)
-- Name: file_permissions_orgs unique_org_by_file_permission_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_orgs
    ADD CONSTRAINT unique_org_by_file_permission_id UNIQUE (file_permission_id, org_id);


--
-- TOC entry 4600 (class 2606 OID 262029)
-- Name: folder_assignations_orgs unique_org_by_folder_assignation_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_orgs
    ADD CONSTRAINT unique_org_by_folder_assignation_id UNIQUE (folder_assignation_id, org_id);


--
-- TOC entry 4620 (class 2606 OID 262031)
-- Name: folder_permissions_orgs unique_org_by_folder_permission_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_orgs
    ADD CONSTRAINT unique_org_by_folder_permission_id UNIQUE (folder_permission_id, org_id);


--
-- TOC entry 4435 (class 2606 OID 262033)
-- Name: file_permissions unique_permission_by_file_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions
    ADD CONSTRAINT unique_permission_by_file_id UNIQUE (file_id);


--
-- TOC entry 4407 (class 2606 OID 262035)
-- Name: folder_permissions unique_permission_by_folder_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions
    ADD CONSTRAINT unique_permission_by_folder_id UNIQUE (folder_id);


--
-- TOC entry 4537 (class 2606 OID 262037)
-- Name: file_assignations_teams unique_team_by_file_assignation_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_teams
    ADD CONSTRAINT unique_team_by_file_assignation_id UNIQUE (file_assignation_id, team_id);


--
-- TOC entry 4559 (class 2606 OID 262039)
-- Name: file_permissions_teams unique_team_by_file_permission_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_teams
    ADD CONSTRAINT unique_team_by_file_permission_id UNIQUE (file_permission_id, team_id);


--
-- TOC entry 4604 (class 2606 OID 262041)
-- Name: folder_assignations_teams unique_team_by_folder_assignation_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_teams
    ADD CONSTRAINT unique_team_by_folder_assignation_id UNIQUE (folder_assignation_id, team_id);


--
-- TOC entry 4624 (class 2606 OID 262043)
-- Name: folder_permissions_teams unique_team_by_folder_permission_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_teams
    ADD CONSTRAINT unique_team_by_folder_permission_id UNIQUE (folder_permission_id, team_id);


--
-- TOC entry 4541 (class 2606 OID 262045)
-- Name: file_assignations_users unique_user_by_file_assignation_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_users
    ADD CONSTRAINT unique_user_by_file_assignation_id UNIQUE (file_assignation_id, user_id);


--
-- TOC entry 4563 (class 2606 OID 262047)
-- Name: file_permissions_users unique_user_by_file_permission_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_users
    ADD CONSTRAINT unique_user_by_file_permission_id UNIQUE (file_permission_id, user_id);


--
-- TOC entry 4608 (class 2606 OID 262049)
-- Name: folder_assignations_users unique_user_by_folder_assignation_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_users
    ADD CONSTRAINT unique_user_by_folder_assignation_id UNIQUE (folder_assignation_id, user_id);


--
-- TOC entry 4628 (class 2606 OID 262051)
-- Name: folder_permissions_users unique_user_by_folder_permission_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_users
    ADD CONSTRAINT unique_user_by_folder_permission_id UNIQUE (folder_permission_id, user_id);


--
-- TOC entry 4793 (class 2606 OID 262053)
-- Name: user_actions user_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_actions
    ADD CONSTRAINT user_actions_pkey PRIMARY KEY (id);


--
-- TOC entry 4795 (class 2606 OID 262055)
-- Name: user_avatars user_avatars_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_avatars
    ADD CONSTRAINT user_avatars_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4797 (class 2606 OID 262057)
-- Name: user_connections user_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_connections
    ADD CONSTRAINT user_connections_pkey PRIMARY KEY (id);


--
-- TOC entry 4799 (class 2606 OID 262059)
-- Name: user_devices user_devices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_devices
    ADD CONSTRAINT user_devices_pkey PRIMARY KEY (id);


--
-- TOC entry 4801 (class 2606 OID 262061)
-- Name: user_devices user_devices_user_id_firebase_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_devices
    ADD CONSTRAINT user_devices_user_id_firebase_token_key UNIQUE (user_id, firebase_token);


--
-- TOC entry 4803 (class 2606 OID 262063)
-- Name: user_locations user_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_locations
    ADD CONSTRAINT user_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 4805 (class 2606 OID 262065)
-- Name: user_metadatas user_metadatas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_metadatas
    ADD CONSTRAINT user_metadatas_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4807 (class 2606 OID 262067)
-- Name: user_migrations user_migrations_old_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_migrations
    ADD CONSTRAINT user_migrations_old_user_id_key UNIQUE (old_user_id);


--
-- TOC entry 4809 (class 2606 OID 262069)
-- Name: user_migrations user_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_migrations
    ADD CONSTRAINT user_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4813 (class 2606 OID 262071)
-- Name: user_notifications user_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT user_notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 4425 (class 2606 OID 262073)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 4427 (class 2606 OID 262075)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4429 (class 2606 OID 262077)
-- Name: users users_stream_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_stream_user_id_key UNIQUE (stream_user_id);


--
-- TOC entry 4479 (class 1259 OID 262078)
-- Name: event_invocation_logs_event_id_idx; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE INDEX event_invocation_logs_event_id_idx ON hdb_catalog.event_invocation_logs USING btree (event_id);


--
-- TOC entry 4482 (class 1259 OID 262079)
-- Name: event_log_fetch_events; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE INDEX event_log_fetch_events ON hdb_catalog.event_log USING btree (locked NULLS FIRST, next_retry_at NULLS FIRST, created_at) WHERE ((delivered = false) AND (error = false) AND (archived = false));


--
-- TOC entry 4485 (class 1259 OID 262080)
-- Name: event_log_trigger_name_idx; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE INDEX event_log_trigger_name_idx ON hdb_catalog.event_log USING btree (trigger_name);


--
-- TOC entry 4488 (class 1259 OID 262081)
-- Name: hdb_cron_event_invocation_event_id; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE INDEX hdb_cron_event_invocation_event_id ON hdb_catalog.hdb_cron_event_invocation_logs USING btree (event_id);


--
-- TOC entry 4491 (class 1259 OID 262082)
-- Name: hdb_cron_event_status; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE INDEX hdb_cron_event_status ON hdb_catalog.hdb_cron_events USING btree (status);


--
-- TOC entry 4494 (class 1259 OID 262083)
-- Name: hdb_cron_events_unique_scheduled; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE UNIQUE INDEX hdb_cron_events_unique_scheduled ON hdb_catalog.hdb_cron_events USING btree (trigger_name, scheduled_time) WHERE (status = 'scheduled'::text);


--
-- TOC entry 4501 (class 1259 OID 262084)
-- Name: hdb_scheduled_event_status; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE INDEX hdb_scheduled_event_status ON hdb_catalog.hdb_scheduled_events USING btree (status);


--
-- TOC entry 4506 (class 1259 OID 262085)
-- Name: hdb_source_catalog_version_one_row; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE UNIQUE INDEX hdb_source_catalog_version_one_row ON hdb_catalog.hdb_source_catalog_version USING btree (((version IS NOT NULL)));


--
-- TOC entry 4507 (class 1259 OID 262086)
-- Name: hdb_version_one_row; Type: INDEX; Schema: hdb_catalog; Owner: postgres
--

CREATE UNIQUE INDEX hdb_version_one_row ON hdb_catalog.hdb_version USING btree (((version IS NOT NULL)));


--
-- TOC entry 4516 (class 1259 OID 262087)
-- Name: events_workers_status_creator_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX events_workers_status_creator_id ON public.events_workers_status USING btree (creator_id);


--
-- TOC entry 4517 (class 1259 OID 262088)
-- Name: events_workers_status_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX events_workers_status_event_id ON public.events_workers_status USING btree (event_id);


--
-- TOC entry 4584 (class 1259 OID 262089)
-- Name: file_versions_approvals_overview_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX file_versions_approvals_overview_idx ON public.file_versions_approvals_overview USING btree (file_version_id);


--
-- TOC entry 4416 (class 1259 OID 262090)
-- Name: files_parent_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX files_parent_id_idx ON public.files USING btree (parent_id);


--
-- TOC entry 4452 (class 1259 OID 262091)
-- Name: folders_idx_parent_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX folders_idx_parent_id ON public.folders USING btree (parent_id);


--
-- TOC entry 4453 (class 1259 OID 262092)
-- Name: folders_idx_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX folders_idx_project_id ON public.folders USING btree (project_id);


--
-- TOC entry 4468 (class 1259 OID 262093)
-- Name: idx_file_approvals_file_versions; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_file_approvals_file_versions ON public.file_approvals USING btree (id, file_version_id);


--
-- TOC entry 4419 (class 1259 OID 262094)
-- Name: idx_org_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_org_project_id ON public.orgs USING btree (project_id);


--
-- TOC entry 4810 (class 1259 OID 262095)
-- Name: idx_user_notifications_recipient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_notifications_recipient_id ON public.user_notifications USING btree (recipient_id);


--
-- TOC entry 4811 (class 1259 OID 262096)
-- Name: idx_user_notifications_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_notifications_type ON public.user_notifications USING btree (type);


--
-- TOC entry 4670 (class 1259 OID 262097)
-- Name: org_project_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX org_project_user_idx ON public.orgs_projects_users USING btree (project_id, user_id);


--
-- TOC entry 4673 (class 1259 OID 262098)
-- Name: presigned_urls_expires_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX presigned_urls_expires_at_idx ON public.presigned_urls USING btree (expires_at);


--
-- TOC entry 4665 (class 1259 OID 262099)
-- Name: projects_to_users_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX projects_to_users_idx ON public.projects_to_users USING btree (project_id, user_id);


--
-- TOC entry 4458 (class 1259 OID 262100)
-- Name: unique_root_bin_by_project_constraint; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unique_root_bin_by_project_constraint ON public.folders USING btree (project_id) WHERE (root_bin = true);


--
-- TOC entry 4459 (class 1259 OID 262101)
-- Name: unique_root_by_project_constraint; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unique_root_by_project_constraint ON public.folders USING btree (project_id) WHERE (root = true);


--
-- TOC entry 4968 (class 2620 OID 262102)
-- Name: file_versions copy_approvals_requests_after_insert_file_version; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER copy_approvals_requests_after_insert_file_version AFTER INSERT ON public.file_versions FOR EACH ROW EXECUTE FUNCTION public.copy_approvals_requests_after_new_version_created();


--
-- TOC entry 5371 (class 0 OID 0)
-- Dependencies: 4968
-- Name: TRIGGER copy_approvals_requests_after_insert_file_version ON file_versions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER copy_approvals_requests_after_insert_file_version ON public.file_versions IS 'trigger migrate the approvals requests to the new version of the file';


--
-- TOC entry 4965 (class 2620 OID 262103)
-- Name: users lowercase_user_email_on_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER lowercase_user_email_on_insert BEFORE INSERT OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.lowercase_user_email_on_insert();


--
-- TOC entry 4981 (class 2620 OID 262104)
-- Name: events notify_hasura_events_INSERT; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "notify_hasura_events_INSERT" AFTER INSERT ON public.events FOR EACH ROW EXECUTE FUNCTION hdb_catalog."notify_hasura_events_INSERT"();


--
-- TOC entry 5013 (class 2620 OID 262105)
-- Name: presigned_urls presigned_urls_delete_old_rows_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER presigned_urls_delete_old_rows_trigger BEFORE INSERT ON public.presigned_urls FOR EACH STATEMENT EXECUTE FUNCTION public.presigned_urls_delete_old_rows();


--
-- TOC entry 4976 (class 2620 OID 262106)
-- Name: file_approvals refresh_file_versions_approvals_overview_materialized_view; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER refresh_file_versions_approvals_overview_materialized_view AFTER INSERT OR DELETE OR UPDATE OR TRUNCATE ON public.file_approvals FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_file_versions_approvals_overview_materialized_view();


--
-- TOC entry 4992 (class 2620 OID 262107)
-- Name: file_version_approval_request_users refresh_file_versions_approvals_overview_materialized_view; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER refresh_file_versions_approvals_overview_materialized_view AFTER INSERT OR DELETE OR UPDATE OR TRUNCATE ON public.file_version_approval_request_users FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_file_versions_approvals_overview_materialized_view();


--
-- TOC entry 5008 (class 2620 OID 262108)
-- Name: orgs_to_users refresh_orgs_projects_users_materialized_view; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER refresh_orgs_projects_users_materialized_view AFTER INSERT OR DELETE OR UPDATE OR TRUNCATE ON public.orgs_to_users FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_orgs_projects_users_materialized_view();


--
-- TOC entry 5010 (class 2620 OID 262109)
-- Name: projects_to_users refresh_orgs_projects_users_materialized_view; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER refresh_orgs_projects_users_materialized_view AFTER INSERT OR DELETE OR UPDATE OR TRUNCATE ON public.projects_to_users FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_orgs_projects_users_materialized_view();


--
-- TOC entry 4973 (class 2620 OID 262110)
-- Name: folders set_permissions_after_insert_folder; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_permissions_after_insert_folder AFTER INSERT ON public.folders FOR EACH ROW EXECUTE FUNCTION public.set_permissions_after_folder_created();


--
-- TOC entry 5372 (class 0 OID 0)
-- Dependencies: 4973
-- Name: TRIGGER set_permissions_after_insert_folder ON folders; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_permissions_after_insert_folder ON public.folders IS 'trigger used to apply the proper permission on the newly created folder';


--
-- TOC entry 4982 (class 2620 OID 262111)
-- Name: events set_public_events_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_events_updated_at BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5373 (class 0 OID 0)
-- Dependencies: 4982
-- Name: TRIGGER set_public_events_updated_at ON events; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_events_updated_at ON public.events IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4983 (class 2620 OID 262112)
-- Name: events_workers_status set_public_events_workers_status_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_events_workers_status_updated_at BEFORE UPDATE ON public.events_workers_status FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5374 (class 0 OID 0)
-- Dependencies: 4983
-- Name: TRIGGER set_public_events_workers_status_updated_at ON events_workers_status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_events_workers_status_updated_at ON public.events_workers_status IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4977 (class 2620 OID 262113)
-- Name: file_approvals set_public_file_approvals_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_approvals_updated_at BEFORE UPDATE ON public.file_approvals FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5375 (class 0 OID 0)
-- Dependencies: 4977
-- Name: TRIGGER set_public_file_approvals_updated_at ON file_approvals; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_approvals_updated_at ON public.file_approvals IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4984 (class 2620 OID 262114)
-- Name: file_assignations_orgs set_public_file_assignations_orgs_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_assignations_orgs_updated_at BEFORE UPDATE ON public.file_assignations_orgs FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5376 (class 0 OID 0)
-- Dependencies: 4984
-- Name: TRIGGER set_public_file_assignations_orgs_updated_at ON file_assignations_orgs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_assignations_orgs_updated_at ON public.file_assignations_orgs IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4985 (class 2620 OID 262115)
-- Name: file_assignations_teams set_public_file_assignations_teams_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_assignations_teams_updated_at BEFORE UPDATE ON public.file_assignations_teams FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5377 (class 0 OID 0)
-- Dependencies: 4985
-- Name: TRIGGER set_public_file_assignations_teams_updated_at ON file_assignations_teams; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_assignations_teams_updated_at ON public.file_assignations_teams IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4961 (class 2620 OID 262116)
-- Name: file_assignations set_public_file_assignations_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_assignations_updated_at BEFORE UPDATE ON public.file_assignations FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5378 (class 0 OID 0)
-- Dependencies: 4961
-- Name: TRIGGER set_public_file_assignations_updated_at ON file_assignations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_assignations_updated_at ON public.file_assignations IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4986 (class 2620 OID 262117)
-- Name: file_assignations_users set_public_file_assignations_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_assignations_users_updated_at BEFORE UPDATE ON public.file_assignations_users FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5379 (class 0 OID 0)
-- Dependencies: 4986
-- Name: TRIGGER set_public_file_assignations_users_updated_at ON file_assignations_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_assignations_users_updated_at ON public.file_assignations_users IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4987 (class 2620 OID 262118)
-- Name: file_comments set_public_file_comments_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_comments_updated_at BEFORE UPDATE ON public.file_comments FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5380 (class 0 OID 0)
-- Dependencies: 4987
-- Name: TRIGGER set_public_file_comments_updated_at ON file_comments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_comments_updated_at ON public.file_comments IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4988 (class 2620 OID 262119)
-- Name: file_permissions_orgs set_public_file_permissions_orgs_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_permissions_orgs_updated_at BEFORE UPDATE ON public.file_permissions_orgs FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5381 (class 0 OID 0)
-- Dependencies: 4988
-- Name: TRIGGER set_public_file_permissions_orgs_updated_at ON file_permissions_orgs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_permissions_orgs_updated_at ON public.file_permissions_orgs IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4989 (class 2620 OID 262120)
-- Name: file_permissions_teams set_public_file_permissions_teams_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_permissions_teams_updated_at BEFORE UPDATE ON public.file_permissions_teams FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5382 (class 0 OID 0)
-- Dependencies: 4989
-- Name: TRIGGER set_public_file_permissions_teams_updated_at ON file_permissions_teams; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_permissions_teams_updated_at ON public.file_permissions_teams IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4967 (class 2620 OID 262121)
-- Name: file_permissions set_public_file_permissions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_permissions_updated_at BEFORE UPDATE ON public.file_permissions FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5383 (class 0 OID 0)
-- Dependencies: 4967
-- Name: TRIGGER set_public_file_permissions_updated_at ON file_permissions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_permissions_updated_at ON public.file_permissions IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4990 (class 2620 OID 262122)
-- Name: file_permissions_users set_public_file_permissions_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_permissions_users_updated_at BEFORE UPDATE ON public.file_permissions_users FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5384 (class 0 OID 0)
-- Dependencies: 4990
-- Name: TRIGGER set_public_file_permissions_users_updated_at ON file_permissions_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_permissions_users_updated_at ON public.file_permissions_users IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4991 (class 2620 OID 262123)
-- Name: file_signatures set_public_file_signatures_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_signatures_updated_at BEFORE UPDATE ON public.file_signatures FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5385 (class 0 OID 0)
-- Dependencies: 4991
-- Name: TRIGGER set_public_file_signatures_updated_at ON file_signatures; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_signatures_updated_at ON public.file_signatures IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4993 (class 2620 OID 262124)
-- Name: file_version_approval_request_users set_public_file_version_approval_request_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_version_approval_request_users_updated_at BEFORE UPDATE ON public.file_version_approval_request_users FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5386 (class 0 OID 0)
-- Dependencies: 4993
-- Name: TRIGGER set_public_file_version_approval_request_users_updated_at ON file_version_approval_request_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_version_approval_request_users_updated_at ON public.file_version_approval_request_users IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4971 (class 2620 OID 262125)
-- Name: file_version_approval_requests set_public_file_version_approval_requests_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_version_approval_requests_updated_at BEFORE UPDATE ON public.file_version_approval_requests FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5387 (class 0 OID 0)
-- Dependencies: 4971
-- Name: TRIGGER set_public_file_version_approval_requests_updated_at ON file_version_approval_requests; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_version_approval_requests_updated_at ON public.file_version_approval_requests IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4994 (class 2620 OID 262126)
-- Name: file_version_wopi set_public_file_version_wopi_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_version_wopi_updated_at BEFORE UPDATE ON public.file_version_wopi FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5388 (class 0 OID 0)
-- Dependencies: 4994
-- Name: TRIGGER set_public_file_version_wopi_updated_at ON file_version_wopi; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_version_wopi_updated_at ON public.file_version_wopi IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4969 (class 2620 OID 262127)
-- Name: file_versions set_public_file_versions_number; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_versions_number BEFORE INSERT ON public.file_versions FOR EACH ROW WHEN (((new.number IS NULL) OR (new.number = 0))) EXECUTE FUNCTION public.increment_file_version();


--
-- TOC entry 5389 (class 0 OID 0)
-- Dependencies: 4969
-- Name: TRIGGER set_public_file_versions_number ON file_versions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_versions_number ON public.file_versions IS 'trigger to set value of column "number" to increment version';


--
-- TOC entry 4970 (class 2620 OID 262128)
-- Name: file_versions set_public_file_versions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_versions_updated_at BEFORE UPDATE ON public.file_versions FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5390 (class 0 OID 0)
-- Dependencies: 4970
-- Name: TRIGGER set_public_file_versions_updated_at ON file_versions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_versions_updated_at ON public.file_versions IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4995 (class 2620 OID 262129)
-- Name: file_views set_public_file_views_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_file_views_updated_at BEFORE UPDATE ON public.file_views FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5391 (class 0 OID 0)
-- Dependencies: 4995
-- Name: TRIGGER set_public_file_views_updated_at ON file_views; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_file_views_updated_at ON public.file_views IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4996 (class 2620 OID 262130)
-- Name: files_to_project_labels set_public_files_to_project_labels_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_files_to_project_labels_updated_at BEFORE UPDATE ON public.files_to_project_labels FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5392 (class 0 OID 0)
-- Dependencies: 4996
-- Name: TRIGGER set_public_files_to_project_labels_updated_at ON files_to_project_labels; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_files_to_project_labels_updated_at ON public.files_to_project_labels IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4962 (class 2620 OID 262131)
-- Name: files set_public_files_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_files_updated_at BEFORE UPDATE ON public.files FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5393 (class 0 OID 0)
-- Dependencies: 4962
-- Name: TRIGGER set_public_files_updated_at ON files; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_files_updated_at ON public.files IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4997 (class 2620 OID 262132)
-- Name: folder_assignations_orgs set_public_folder_assignations_orgs_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_folder_assignations_orgs_updated_at BEFORE UPDATE ON public.folder_assignations_orgs FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5394 (class 0 OID 0)
-- Dependencies: 4997
-- Name: TRIGGER set_public_folder_assignations_orgs_updated_at ON folder_assignations_orgs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_folder_assignations_orgs_updated_at ON public.folder_assignations_orgs IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4998 (class 2620 OID 262133)
-- Name: folder_assignations_teams set_public_folder_assignations_teams_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_folder_assignations_teams_updated_at BEFORE UPDATE ON public.folder_assignations_teams FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5395 (class 0 OID 0)
-- Dependencies: 4998
-- Name: TRIGGER set_public_folder_assignations_teams_updated_at ON folder_assignations_teams; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_folder_assignations_teams_updated_at ON public.folder_assignations_teams IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4972 (class 2620 OID 262134)
-- Name: folder_assignations set_public_folder_assignations_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_folder_assignations_updated_at BEFORE UPDATE ON public.folder_assignations FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5396 (class 0 OID 0)
-- Dependencies: 4972
-- Name: TRIGGER set_public_folder_assignations_updated_at ON folder_assignations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_folder_assignations_updated_at ON public.folder_assignations IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4999 (class 2620 OID 262135)
-- Name: folder_assignations_users set_public_folder_assignations_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_folder_assignations_users_updated_at BEFORE UPDATE ON public.folder_assignations_users FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5397 (class 0 OID 0)
-- Dependencies: 4999
-- Name: TRIGGER set_public_folder_assignations_users_updated_at ON folder_assignations_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_folder_assignations_users_updated_at ON public.folder_assignations_users IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5000 (class 2620 OID 262136)
-- Name: folder_permissions_orgs set_public_folder_permissions_orgs_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_folder_permissions_orgs_updated_at BEFORE UPDATE ON public.folder_permissions_orgs FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5398 (class 0 OID 0)
-- Dependencies: 5000
-- Name: TRIGGER set_public_folder_permissions_orgs_updated_at ON folder_permissions_orgs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_folder_permissions_orgs_updated_at ON public.folder_permissions_orgs IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5001 (class 2620 OID 262137)
-- Name: folder_permissions_teams set_public_folder_permissions_teams_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_folder_permissions_teams_updated_at BEFORE UPDATE ON public.folder_permissions_teams FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5399 (class 0 OID 0)
-- Dependencies: 5001
-- Name: TRIGGER set_public_folder_permissions_teams_updated_at ON folder_permissions_teams; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_folder_permissions_teams_updated_at ON public.folder_permissions_teams IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4960 (class 2620 OID 262138)
-- Name: folder_permissions set_public_folder_permissions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_folder_permissions_updated_at BEFORE UPDATE ON public.folder_permissions FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5400 (class 0 OID 0)
-- Dependencies: 4960
-- Name: TRIGGER set_public_folder_permissions_updated_at ON folder_permissions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_folder_permissions_updated_at ON public.folder_permissions IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5002 (class 2620 OID 262139)
-- Name: folder_permissions_users set_public_folder_permissions_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_folder_permissions_users_updated_at BEFORE UPDATE ON public.folder_permissions_users FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5401 (class 0 OID 0)
-- Dependencies: 5002
-- Name: TRIGGER set_public_folder_permissions_users_updated_at ON folder_permissions_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_folder_permissions_users_updated_at ON public.folder_permissions_users IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5003 (class 2620 OID 262140)
-- Name: folder_views set_public_folder_views_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_folder_views_updated_at BEFORE UPDATE ON public.folder_views FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5402 (class 0 OID 0)
-- Dependencies: 5003
-- Name: TRIGGER set_public_folder_views_updated_at ON folder_views; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_folder_views_updated_at ON public.folder_views IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5004 (class 2620 OID 262141)
-- Name: folders_to_project_labels set_public_folders_to_project_labels_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_folders_to_project_labels_updated_at BEFORE UPDATE ON public.folders_to_project_labels FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5403 (class 0 OID 0)
-- Dependencies: 5004
-- Name: TRIGGER set_public_folders_to_project_labels_updated_at ON folders_to_project_labels; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_folders_to_project_labels_updated_at ON public.folders_to_project_labels IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4974 (class 2620 OID 262142)
-- Name: folders set_public_folders_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_folders_updated_at BEFORE UPDATE ON public.folders FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5404 (class 0 OID 0)
-- Dependencies: 4974
-- Name: TRIGGER set_public_folders_updated_at ON folders; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_folders_updated_at ON public.folders IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5005 (class 2620 OID 262143)
-- Name: org_avatars set_public_org_avatars_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_org_avatars_updated_at BEFORE UPDATE ON public.org_avatars FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5405 (class 0 OID 0)
-- Dependencies: 5005
-- Name: TRIGGER set_public_org_avatars_updated_at ON org_avatars; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_org_avatars_updated_at ON public.org_avatars IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5006 (class 2620 OID 262144)
-- Name: org_backgrounds set_public_org_backgrounds_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_org_backgrounds_updated_at BEFORE UPDATE ON public.org_backgrounds FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5406 (class 0 OID 0)
-- Dependencies: 5006
-- Name: TRIGGER set_public_org_backgrounds_updated_at ON org_backgrounds; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_org_backgrounds_updated_at ON public.org_backgrounds IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5007 (class 2620 OID 262145)
-- Name: org_project_summary_to_project_categories set_public_org_project_summary_to_project_categories_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_org_project_summary_to_project_categories_updated_at BEFORE UPDATE ON public.org_project_summary_to_project_categories FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5407 (class 0 OID 0)
-- Dependencies: 5007
-- Name: TRIGGER set_public_org_project_summary_to_project_categories_updated_at ON org_project_summary_to_project_categories; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_org_project_summary_to_project_categories_updated_at ON public.org_project_summary_to_project_categories IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4978 (class 2620 OID 262146)
-- Name: org_project_summary set_public_org_project_summary_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_org_project_summary_updated_at BEFORE UPDATE ON public.org_project_summary FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5408 (class 0 OID 0)
-- Dependencies: 4978
-- Name: TRIGGER set_public_org_project_summary_updated_at ON org_project_summary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_org_project_summary_updated_at ON public.org_project_summary IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5012 (class 2620 OID 262147)
-- Name: orgs_to_user_actions set_public_orgs_to_user_actions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_orgs_to_user_actions_updated_at BEFORE UPDATE ON public.orgs_to_user_actions FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5409 (class 0 OID 0)
-- Dependencies: 5012
-- Name: TRIGGER set_public_orgs_to_user_actions_updated_at ON orgs_to_user_actions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_orgs_to_user_actions_updated_at ON public.orgs_to_user_actions IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5009 (class 2620 OID 262148)
-- Name: orgs_to_users set_public_orgs_to_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_orgs_to_users_updated_at BEFORE UPDATE ON public.orgs_to_users FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5410 (class 0 OID 0)
-- Dependencies: 5009
-- Name: TRIGGER set_public_orgs_to_users_updated_at ON orgs_to_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_orgs_to_users_updated_at ON public.orgs_to_users IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4963 (class 2620 OID 262149)
-- Name: orgs set_public_orgs_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_orgs_updated_at BEFORE UPDATE ON public.orgs FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5411 (class 0 OID 0)
-- Dependencies: 4963
-- Name: TRIGGER set_public_orgs_updated_at ON orgs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_orgs_updated_at ON public.orgs IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5014 (class 2620 OID 262150)
-- Name: project_address set_public_project_address_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_project_address_updated_at BEFORE UPDATE ON public.project_address FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5412 (class 0 OID 0)
-- Dependencies: 5014
-- Name: TRIGGER set_public_project_address_updated_at ON project_address; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_project_address_updated_at ON public.project_address IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5015 (class 2620 OID 262151)
-- Name: project_avatars set_public_project_avatars_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_project_avatars_updated_at BEFORE UPDATE ON public.project_avatars FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5413 (class 0 OID 0)
-- Dependencies: 5015
-- Name: TRIGGER set_public_project_avatars_updated_at ON project_avatars; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_project_avatars_updated_at ON public.project_avatars IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5016 (class 2620 OID 262152)
-- Name: project_backgrounds set_public_project_backgrounds_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_project_backgrounds_updated_at BEFORE UPDATE ON public.project_backgrounds FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5414 (class 0 OID 0)
-- Dependencies: 5016
-- Name: TRIGGER set_public_project_backgrounds_updated_at ON project_backgrounds; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_project_backgrounds_updated_at ON public.project_backgrounds IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5017 (class 2620 OID 262153)
-- Name: project_banners set_public_project_banners_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_project_banners_updated_at BEFORE UPDATE ON public.project_banners FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5415 (class 0 OID 0)
-- Dependencies: 5017
-- Name: TRIGGER set_public_project_banners_updated_at ON project_banners; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_project_banners_updated_at ON public.project_banners IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5018 (class 2620 OID 262154)
-- Name: project_categories set_public_project_categories_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_project_categories_updated_at BEFORE UPDATE ON public.project_categories FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5416 (class 0 OID 0)
-- Dependencies: 5018
-- Name: TRIGGER set_public_project_categories_updated_at ON project_categories; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_project_categories_updated_at ON public.project_categories IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5019 (class 2620 OID 262155)
-- Name: project_labels set_public_project_labels_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_project_labels_updated_at BEFORE UPDATE ON public.project_labels FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5417 (class 0 OID 0)
-- Dependencies: 5019
-- Name: TRIGGER set_public_project_labels_updated_at ON project_labels; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_project_labels_updated_at ON public.project_labels IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5020 (class 2620 OID 262156)
-- Name: project_templates set_public_project_templates_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_project_templates_updated_at BEFORE UPDATE ON public.project_templates FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5418 (class 0 OID 0)
-- Dependencies: 5020
-- Name: TRIGGER set_public_project_templates_updated_at ON project_templates; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_project_templates_updated_at ON public.project_templates IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5021 (class 2620 OID 262157)
-- Name: project_views set_public_project_views_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_project_views_updated_at BEFORE UPDATE ON public.project_views FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5419 (class 0 OID 0)
-- Dependencies: 5021
-- Name: TRIGGER set_public_project_views_updated_at ON project_views; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_project_views_updated_at ON public.project_views IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5011 (class 2620 OID 262158)
-- Name: projects_to_users set_public_projects_to_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_projects_to_users_updated_at BEFORE UPDATE ON public.projects_to_users FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5420 (class 0 OID 0)
-- Dependencies: 5011
-- Name: TRIGGER set_public_projects_to_users_updated_at ON projects_to_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_projects_to_users_updated_at ON public.projects_to_users IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4975 (class 2620 OID 262159)
-- Name: projects set_public_projects_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5421 (class 0 OID 0)
-- Dependencies: 4975
-- Name: TRIGGER set_public_projects_updated_at ON projects; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_projects_updated_at ON public.projects IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5022 (class 2620 OID 262160)
-- Name: push_notifications set_public_push_notifications_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_push_notifications_updated_at BEFORE UPDATE ON public.push_notifications FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5422 (class 0 OID 0)
-- Dependencies: 5022
-- Name: TRIGGER set_public_push_notifications_updated_at ON push_notifications; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_push_notifications_updated_at ON public.push_notifications IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5029 (class 2620 OID 262161)
-- Name: task_subtasks set_public_subtasks_order; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_subtasks_order BEFORE INSERT ON public.task_subtasks FOR EACH ROW WHEN (((new."order" IS NULL) OR (new."order" = 0))) EXECUTE FUNCTION public.increment_subtask_order();


--
-- TOC entry 5423 (class 0 OID 0)
-- Dependencies: 5029
-- Name: TRIGGER set_public_subtasks_order ON task_subtasks; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_subtasks_order ON public.task_subtasks IS 'trigger to set the value of column "order"';


--
-- TOC entry 5024 (class 2620 OID 262162)
-- Name: task_assignations_orgs set_public_task_assignations_orgs_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_task_assignations_orgs_updated_at BEFORE UPDATE ON public.task_assignations_orgs FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5424 (class 0 OID 0)
-- Dependencies: 5024
-- Name: TRIGGER set_public_task_assignations_orgs_updated_at ON task_assignations_orgs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_task_assignations_orgs_updated_at ON public.task_assignations_orgs IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5025 (class 2620 OID 262163)
-- Name: task_assignations_teams set_public_task_assignations_teams_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_task_assignations_teams_updated_at BEFORE UPDATE ON public.task_assignations_teams FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5425 (class 0 OID 0)
-- Dependencies: 5025
-- Name: TRIGGER set_public_task_assignations_teams_updated_at ON task_assignations_teams; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_task_assignations_teams_updated_at ON public.task_assignations_teams IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5023 (class 2620 OID 262164)
-- Name: task_assignations set_public_task_assignations_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_task_assignations_updated_at BEFORE UPDATE ON public.task_assignations FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5426 (class 0 OID 0)
-- Dependencies: 5023
-- Name: TRIGGER set_public_task_assignations_updated_at ON task_assignations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_task_assignations_updated_at ON public.task_assignations IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5026 (class 2620 OID 262165)
-- Name: task_assignations_users set_public_task_assignations_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_task_assignations_users_updated_at BEFORE UPDATE ON public.task_assignations_users FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5427 (class 0 OID 0)
-- Dependencies: 5026
-- Name: TRIGGER set_public_task_assignations_users_updated_at ON task_assignations_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_task_assignations_users_updated_at ON public.task_assignations_users IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5027 (class 2620 OID 262166)
-- Name: task_attachments set_public_task_attachments_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_task_attachments_updated_at BEFORE UPDATE ON public.task_attachments FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5428 (class 0 OID 0)
-- Dependencies: 5027
-- Name: TRIGGER set_public_task_attachments_updated_at ON task_attachments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_task_attachments_updated_at ON public.task_attachments IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5028 (class 2620 OID 262167)
-- Name: task_file_version_location set_public_task_file_version_location_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_task_file_version_location_updated_at BEFORE UPDATE ON public.task_file_version_location FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5429 (class 0 OID 0)
-- Dependencies: 5028
-- Name: TRIGGER set_public_task_file_version_location_updated_at ON task_file_version_location; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_task_file_version_location_updated_at ON public.task_file_version_location IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5030 (class 2620 OID 262168)
-- Name: task_subtasks set_public_task_subtasks_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_task_subtasks_updated_at BEFORE UPDATE ON public.task_subtasks FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5430 (class 0 OID 0)
-- Dependencies: 5030
-- Name: TRIGGER set_public_task_subtasks_updated_at ON task_subtasks; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_task_subtasks_updated_at ON public.task_subtasks IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5031 (class 2620 OID 262169)
-- Name: task_validations set_public_task_validations_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_task_validations_updated_at BEFORE UPDATE ON public.task_validations FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5431 (class 0 OID 0)
-- Dependencies: 5031
-- Name: TRIGGER set_public_task_validations_updated_at ON task_validations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_task_validations_updated_at ON public.task_validations IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5032 (class 2620 OID 262170)
-- Name: task_views set_public_task_views_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_task_views_updated_at BEFORE UPDATE ON public.task_views FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5432 (class 0 OID 0)
-- Dependencies: 5032
-- Name: TRIGGER set_public_task_views_updated_at ON task_views; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_task_views_updated_at ON public.task_views IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5033 (class 2620 OID 262171)
-- Name: tasks_file_versions set_public_tasks_file_versions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_tasks_file_versions_updated_at BEFORE UPDATE ON public.tasks_file_versions FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5433 (class 0 OID 0)
-- Dependencies: 5033
-- Name: TRIGGER set_public_tasks_file_versions_updated_at ON tasks_file_versions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_tasks_file_versions_updated_at ON public.tasks_file_versions IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4979 (class 2620 OID 262172)
-- Name: tasks set_public_tasks_number; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_tasks_number BEFORE INSERT ON public.tasks FOR EACH ROW WHEN (((new.number IS NULL) OR (new.number = 0))) EXECUTE FUNCTION public.increment_task_number();


--
-- TOC entry 5434 (class 0 OID 0)
-- Dependencies: 4979
-- Name: TRIGGER set_public_tasks_number ON tasks; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_tasks_number ON public.tasks IS 'trigger to set value of column "number" to increment version';


--
-- TOC entry 5034 (class 2620 OID 262173)
-- Name: tasks_to_project_labels set_public_tasks_to_project_labels_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_tasks_to_project_labels_updated_at BEFORE UPDATE ON public.tasks_to_project_labels FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5435 (class 0 OID 0)
-- Dependencies: 5034
-- Name: TRIGGER set_public_tasks_to_project_labels_updated_at ON tasks_to_project_labels; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_tasks_to_project_labels_updated_at ON public.tasks_to_project_labels IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4980 (class 2620 OID 262174)
-- Name: tasks set_public_tasks_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5436 (class 0 OID 0)
-- Dependencies: 4980
-- Name: TRIGGER set_public_tasks_updated_at ON tasks; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_tasks_updated_at ON public.tasks IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5035 (class 2620 OID 262175)
-- Name: teams_to_users set_public_teams_to_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_teams_to_users_updated_at BEFORE UPDATE ON public.teams_to_users FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5437 (class 0 OID 0)
-- Dependencies: 5035
-- Name: TRIGGER set_public_teams_to_users_updated_at ON teams_to_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_teams_to_users_updated_at ON public.teams_to_users IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4964 (class 2620 OID 262176)
-- Name: teams set_public_teams_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_teams_updated_at BEFORE UPDATE ON public.teams FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5438 (class 0 OID 0)
-- Dependencies: 4964
-- Name: TRIGGER set_public_teams_updated_at ON teams; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_teams_updated_at ON public.teams IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5036 (class 2620 OID 262177)
-- Name: user_actions set_public_user_actions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_user_actions_updated_at BEFORE UPDATE ON public.user_actions FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5439 (class 0 OID 0)
-- Dependencies: 5036
-- Name: TRIGGER set_public_user_actions_updated_at ON user_actions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_user_actions_updated_at ON public.user_actions IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5037 (class 2620 OID 262178)
-- Name: user_avatars set_public_user_avatars_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_user_avatars_updated_at BEFORE UPDATE ON public.user_avatars FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5440 (class 0 OID 0)
-- Dependencies: 5037
-- Name: TRIGGER set_public_user_avatars_updated_at ON user_avatars; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_user_avatars_updated_at ON public.user_avatars IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5038 (class 2620 OID 262179)
-- Name: user_connections set_public_user_connections_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_user_connections_updated_at BEFORE UPDATE ON public.user_connections FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5441 (class 0 OID 0)
-- Dependencies: 5038
-- Name: TRIGGER set_public_user_connections_updated_at ON user_connections; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_user_connections_updated_at ON public.user_connections IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5039 (class 2620 OID 262180)
-- Name: user_locations set_public_user_locations_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_user_locations_updated_at BEFORE UPDATE ON public.user_locations FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5442 (class 0 OID 0)
-- Dependencies: 5039
-- Name: TRIGGER set_public_user_locations_updated_at ON user_locations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_user_locations_updated_at ON public.user_locations IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 5040 (class 2620 OID 262181)
-- Name: user_notifications set_public_user_notifications_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_user_notifications_updated_at BEFORE UPDATE ON public.user_notifications FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5443 (class 0 OID 0)
-- Dependencies: 5040
-- Name: TRIGGER set_public_user_notifications_updated_at ON user_notifications; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_user_notifications_updated_at ON public.user_notifications IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4966 (class 2620 OID 262182)
-- Name: users set_public_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_public_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- TOC entry 5444 (class 0 OID 0)
-- Dependencies: 4966
-- Name: TRIGGER set_public_users_updated_at ON users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER set_public_users_updated_at ON public.users IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- TOC entry 4839 (class 2606 OID 262183)
-- Name: event_invocation_logs event_invocation_logs_event_id_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.event_invocation_logs
    ADD CONSTRAINT event_invocation_logs_event_id_fkey FOREIGN KEY (event_id) REFERENCES hdb_catalog.event_log(id);


--
-- TOC entry 4840 (class 2606 OID 262188)
-- Name: hdb_cron_event_invocation_logs hdb_cron_event_invocation_logs_event_id_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_cron_event_invocation_logs
    ADD CONSTRAINT hdb_cron_event_invocation_logs_event_id_fkey FOREIGN KEY (event_id) REFERENCES hdb_catalog.hdb_cron_events(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4841 (class 2606 OID 262193)
-- Name: hdb_scheduled_event_invocation_logs hdb_scheduled_event_invocation_logs_event_id_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: postgres
--

ALTER TABLE ONLY hdb_catalog.hdb_scheduled_event_invocation_logs
    ADD CONSTRAINT hdb_scheduled_event_invocation_logs_event_id_fkey FOREIGN KEY (event_id) REFERENCES hdb_catalog.hdb_scheduled_events(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4842 (class 2606 OID 262198)
-- Name: email_notifications email_notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_notifications
    ADD CONSTRAINT email_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4843 (class 2606 OID 262203)
-- Name: events events_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4844 (class 2606 OID 262208)
-- Name: events_workers_status events_workers_status_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events_workers_status
    ADD CONSTRAINT events_workers_status_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4845 (class 2606 OID 262213)
-- Name: events_workers_status events_workers_status_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events_workers_status
    ADD CONSTRAINT events_workers_status_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4831 (class 2606 OID 262218)
-- Name: file_approvals file_approvals_file_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_approvals
    ADD CONSTRAINT file_approvals_file_version_id_fkey FOREIGN KEY (file_version_id) REFERENCES public.file_versions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4832 (class 2606 OID 262223)
-- Name: file_approvals file_approvals_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_approvals
    ADD CONSTRAINT file_approvals_status_fkey FOREIGN KEY (status) REFERENCES public.file_approvals_status_enum(value) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4833 (class 2606 OID 262228)
-- Name: file_approvals file_approvals_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_approvals
    ADD CONSTRAINT file_approvals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4816 (class 2606 OID 262233)
-- Name: file_assignations file_assignations_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations
    ADD CONSTRAINT file_assignations_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4846 (class 2606 OID 262238)
-- Name: file_assignations_orgs file_assignations_orgs_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_orgs
    ADD CONSTRAINT file_assignations_orgs_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4847 (class 2606 OID 262243)
-- Name: file_assignations_orgs file_assignations_orgs_file_assignation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_orgs
    ADD CONSTRAINT file_assignations_orgs_file_assignation_id_fkey FOREIGN KEY (file_assignation_id) REFERENCES public.file_assignations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4848 (class 2606 OID 262248)
-- Name: file_assignations_orgs file_assignations_orgs_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_orgs
    ADD CONSTRAINT file_assignations_orgs_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4849 (class 2606 OID 262253)
-- Name: file_assignations_teams file_assignations_teams_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_teams
    ADD CONSTRAINT file_assignations_teams_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4850 (class 2606 OID 262258)
-- Name: file_assignations_teams file_assignations_teams_file_assignation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_teams
    ADD CONSTRAINT file_assignations_teams_file_assignation_id_fkey FOREIGN KEY (file_assignation_id) REFERENCES public.file_assignations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4851 (class 2606 OID 262263)
-- Name: file_assignations_teams file_assignations_teams_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_teams
    ADD CONSTRAINT file_assignations_teams_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4852 (class 2606 OID 262268)
-- Name: file_assignations_users file_assignations_users_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_users
    ADD CONSTRAINT file_assignations_users_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4853 (class 2606 OID 262273)
-- Name: file_assignations_users file_assignations_users_file_assignation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_users
    ADD CONSTRAINT file_assignations_users_file_assignation_id_fkey FOREIGN KEY (file_assignation_id) REFERENCES public.file_assignations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4854 (class 2606 OID 262278)
-- Name: file_assignations_users file_assignations_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_assignations_users
    ADD CONSTRAINT file_assignations_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4855 (class 2606 OID 262283)
-- Name: file_comments file_comments_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_comments
    ADD CONSTRAINT file_comments_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4856 (class 2606 OID 262288)
-- Name: file_comments file_comments_file_approval_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_comments
    ADD CONSTRAINT file_comments_file_approval_id_fkey FOREIGN KEY (file_approval_id) REFERENCES public.file_approvals(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4857 (class 2606 OID 262293)
-- Name: file_comments file_comments_file_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_comments
    ADD CONSTRAINT file_comments_file_version_id_fkey FOREIGN KEY (file_version_id) REFERENCES public.file_versions(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4822 (class 2606 OID 262298)
-- Name: file_permissions file_permissions_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions
    ADD CONSTRAINT file_permissions_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4858 (class 2606 OID 262303)
-- Name: file_permissions_orgs file_permissions_orgs_access_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_orgs
    ADD CONSTRAINT file_permissions_orgs_access_fkey FOREIGN KEY (access) REFERENCES public.file_access_enum(value) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4859 (class 2606 OID 262308)
-- Name: file_permissions_orgs file_permissions_orgs_file_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_orgs
    ADD CONSTRAINT file_permissions_orgs_file_permission_id_fkey FOREIGN KEY (file_permission_id) REFERENCES public.file_permissions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4860 (class 2606 OID 262313)
-- Name: file_permissions_orgs file_permissions_orgs_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_orgs
    ADD CONSTRAINT file_permissions_orgs_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4861 (class 2606 OID 262318)
-- Name: file_permissions_teams file_permissions_teams_access_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_teams
    ADD CONSTRAINT file_permissions_teams_access_fkey FOREIGN KEY (access) REFERENCES public.file_access_enum(value) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4862 (class 2606 OID 262323)
-- Name: file_permissions_teams file_permissions_teams_file_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_teams
    ADD CONSTRAINT file_permissions_teams_file_permission_id_fkey FOREIGN KEY (file_permission_id) REFERENCES public.file_permissions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4863 (class 2606 OID 262328)
-- Name: file_permissions_teams file_permissions_teams_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_teams
    ADD CONSTRAINT file_permissions_teams_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4864 (class 2606 OID 262333)
-- Name: file_permissions_users file_permissions_users_access_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_users
    ADD CONSTRAINT file_permissions_users_access_fkey FOREIGN KEY (access) REFERENCES public.file_access_enum(value) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4865 (class 2606 OID 262338)
-- Name: file_permissions_users file_permissions_users_file_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_users
    ADD CONSTRAINT file_permissions_users_file_permission_id_fkey FOREIGN KEY (file_permission_id) REFERENCES public.file_permissions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4866 (class 2606 OID 262343)
-- Name: file_permissions_users file_permissions_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_permissions_users
    ADD CONSTRAINT file_permissions_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4867 (class 2606 OID 262348)
-- Name: file_signatures file_signatures_file_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_signatures
    ADD CONSTRAINT file_signatures_file_version_id_fkey FOREIGN KEY (file_version_id) REFERENCES public.file_versions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4868 (class 2606 OID 262353)
-- Name: file_signatures file_signatures_signed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_signatures
    ADD CONSTRAINT file_signatures_signed_by_fkey FOREIGN KEY (signed_by) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4869 (class 2606 OID 262358)
-- Name: file_version_approval_request_users file_version_approval_request_file_version_approval_reques_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_approval_request_users
    ADD CONSTRAINT file_version_approval_request_file_version_approval_reques_fkey FOREIGN KEY (file_version_approval_request_id) REFERENCES public.file_version_approval_requests(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4870 (class 2606 OID 262363)
-- Name: file_version_approval_request_users file_version_approval_request_users_file_approval_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_approval_request_users
    ADD CONSTRAINT file_version_approval_request_users_file_approval_id_fkey FOREIGN KEY (file_approval_id) REFERENCES public.file_approvals(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4871 (class 2606 OID 262368)
-- Name: file_version_approval_request_users file_version_approval_request_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_approval_request_users
    ADD CONSTRAINT file_version_approval_request_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4825 (class 2606 OID 262373)
-- Name: file_version_approval_requests file_version_approval_requests_file_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_approval_requests
    ADD CONSTRAINT file_version_approval_requests_file_version_id_fkey FOREIGN KEY (file_version_id) REFERENCES public.file_versions(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4872 (class 2606 OID 262378)
-- Name: file_version_wopi file_version_wopi_file_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_version_wopi
    ADD CONSTRAINT file_version_wopi_file_version_id_fkey FOREIGN KEY (file_version_id) REFERENCES public.file_versions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4823 (class 2606 OID 262383)
-- Name: file_versions file_versions_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_versions
    ADD CONSTRAINT file_versions_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4824 (class 2606 OID 262388)
-- Name: file_versions file_versions_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_versions
    ADD CONSTRAINT file_versions_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4873 (class 2606 OID 262393)
-- Name: file_views file_views_file_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_views
    ADD CONSTRAINT file_views_file_version_id_fkey FOREIGN KEY (file_version_id) REFERENCES public.file_versions(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4874 (class 2606 OID 262398)
-- Name: file_views file_views_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_views
    ADD CONSTRAINT file_views_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4817 (class 2606 OID 262403)
-- Name: files files_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.folders(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4818 (class 2606 OID 262408)
-- Name: files files_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4875 (class 2606 OID 262413)
-- Name: files_to_project_labels files_to_project_labels_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files_to_project_labels
    ADD CONSTRAINT files_to_project_labels_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4876 (class 2606 OID 262418)
-- Name: files_to_project_labels files_to_project_labels_project_label_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.files_to_project_labels
    ADD CONSTRAINT files_to_project_labels_project_label_id_fkey FOREIGN KEY (project_label_id) REFERENCES public.project_labels(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4826 (class 2606 OID 262423)
-- Name: folder_assignations folder_assignations_folder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations
    ADD CONSTRAINT folder_assignations_folder_id_fkey FOREIGN KEY (folder_id) REFERENCES public.folders(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4877 (class 2606 OID 262428)
-- Name: folder_assignations_orgs folder_assignations_orgs_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_orgs
    ADD CONSTRAINT folder_assignations_orgs_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4878 (class 2606 OID 262433)
-- Name: folder_assignations_orgs folder_assignations_orgs_folder_assignation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_orgs
    ADD CONSTRAINT folder_assignations_orgs_folder_assignation_id_fkey FOREIGN KEY (folder_assignation_id) REFERENCES public.folder_assignations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4879 (class 2606 OID 262438)
-- Name: folder_assignations_orgs folder_assignations_orgs_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_orgs
    ADD CONSTRAINT folder_assignations_orgs_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4880 (class 2606 OID 262443)
-- Name: folder_assignations_teams folder_assignations_teams_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_teams
    ADD CONSTRAINT folder_assignations_teams_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4881 (class 2606 OID 262448)
-- Name: folder_assignations_teams folder_assignations_teams_folder_assignation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_teams
    ADD CONSTRAINT folder_assignations_teams_folder_assignation_id_fkey FOREIGN KEY (folder_assignation_id) REFERENCES public.folder_assignations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4882 (class 2606 OID 262453)
-- Name: folder_assignations_teams folder_assignations_teams_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_teams
    ADD CONSTRAINT folder_assignations_teams_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4883 (class 2606 OID 262458)
-- Name: folder_assignations_users folder_assignations_users_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_users
    ADD CONSTRAINT folder_assignations_users_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4884 (class 2606 OID 262463)
-- Name: folder_assignations_users folder_assignations_users_folder_assignation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_users
    ADD CONSTRAINT folder_assignations_users_folder_assignation_id_fkey FOREIGN KEY (folder_assignation_id) REFERENCES public.folder_assignations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4885 (class 2606 OID 262468)
-- Name: folder_assignations_users folder_assignations_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_assignations_users
    ADD CONSTRAINT folder_assignations_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4814 (class 2606 OID 262473)
-- Name: folder_permissions folder_permissions_folder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions
    ADD CONSTRAINT folder_permissions_folder_id_fkey FOREIGN KEY (folder_id) REFERENCES public.folders(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4815 (class 2606 OID 262478)
-- Name: folder_permissions folder_permissions_inherited_from_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions
    ADD CONSTRAINT folder_permissions_inherited_from_fkey FOREIGN KEY (inherited_from) REFERENCES public.folders(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4886 (class 2606 OID 262483)
-- Name: folder_permissions_orgs folder_permissions_orgs_access_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_orgs
    ADD CONSTRAINT folder_permissions_orgs_access_fkey FOREIGN KEY (access) REFERENCES public.folder_access_enum(value) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4887 (class 2606 OID 262488)
-- Name: folder_permissions_orgs folder_permissions_orgs_folder_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_orgs
    ADD CONSTRAINT folder_permissions_orgs_folder_permission_id_fkey FOREIGN KEY (folder_permission_id) REFERENCES public.folder_permissions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4888 (class 2606 OID 262493)
-- Name: folder_permissions_orgs folder_permissions_orgs_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_orgs
    ADD CONSTRAINT folder_permissions_orgs_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4889 (class 2606 OID 262498)
-- Name: folder_permissions_teams folder_permissions_teams_access_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_teams
    ADD CONSTRAINT folder_permissions_teams_access_fkey FOREIGN KEY (access) REFERENCES public.folder_access_enum(value) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4890 (class 2606 OID 262503)
-- Name: folder_permissions_teams folder_permissions_teams_folder_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_teams
    ADD CONSTRAINT folder_permissions_teams_folder_permission_id_fkey FOREIGN KEY (folder_permission_id) REFERENCES public.folder_permissions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4891 (class 2606 OID 262508)
-- Name: folder_permissions_teams folder_permissions_teams_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_teams
    ADD CONSTRAINT folder_permissions_teams_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4892 (class 2606 OID 262513)
-- Name: folder_permissions_users folder_permissions_users_access_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_users
    ADD CONSTRAINT folder_permissions_users_access_fkey FOREIGN KEY (access) REFERENCES public.folder_access_enum(value) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4893 (class 2606 OID 262518)
-- Name: folder_permissions_users folder_permissions_users_folder_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_users
    ADD CONSTRAINT folder_permissions_users_folder_permission_id_fkey FOREIGN KEY (folder_permission_id) REFERENCES public.folder_permissions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4894 (class 2606 OID 262523)
-- Name: folder_permissions_users folder_permissions_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_permissions_users
    ADD CONSTRAINT folder_permissions_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4895 (class 2606 OID 262528)
-- Name: folder_views folder_views_folder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_views
    ADD CONSTRAINT folder_views_folder_id_fkey FOREIGN KEY (folder_id) REFERENCES public.folders(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4896 (class 2606 OID 262533)
-- Name: folder_views folder_views_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_views
    ADD CONSTRAINT folder_views_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4827 (class 2606 OID 262538)
-- Name: folders folders_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folders
    ADD CONSTRAINT folders_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.folders(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4828 (class 2606 OID 262543)
-- Name: folders folders_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folders
    ADD CONSTRAINT folders_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4897 (class 2606 OID 262548)
-- Name: folders_to_project_labels folders_to_project_labels_folder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folders_to_project_labels
    ADD CONSTRAINT folders_to_project_labels_folder_id_fkey FOREIGN KEY (folder_id) REFERENCES public.folders(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4898 (class 2606 OID 262553)
-- Name: folders_to_project_labels folders_to_project_labels_project_label_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folders_to_project_labels
    ADD CONSTRAINT folders_to_project_labels_project_label_id_fkey FOREIGN KEY (project_label_id) REFERENCES public.project_labels(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4899 (class 2606 OID 262558)
-- Name: org_address org_address_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_address
    ADD CONSTRAINT org_address_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4900 (class 2606 OID 262563)
-- Name: org_avatars org_avatars_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_avatars
    ADD CONSTRAINT org_avatars_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4901 (class 2606 OID 262568)
-- Name: org_backgrounds org_backgrounds_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_backgrounds
    ADD CONSTRAINT org_backgrounds_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4902 (class 2606 OID 262573)
-- Name: org_licenses org_licenses_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_licenses
    ADD CONSTRAINT org_licenses_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4835 (class 2606 OID 262578)
-- Name: org_project_summary org_project_summary_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_project_summary
    ADD CONSTRAINT org_project_summary_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4836 (class 2606 OID 262583)
-- Name: org_project_summary org_project_summary_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_project_summary
    ADD CONSTRAINT org_project_summary_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4903 (class 2606 OID 262588)
-- Name: org_project_summary_to_project_categories org_project_summary_to_project_cate_org_project_summary_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_project_summary_to_project_categories
    ADD CONSTRAINT org_project_summary_to_project_cate_org_project_summary_id_fkey FOREIGN KEY (org_project_summary_id) REFERENCES public.org_project_summary(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4904 (class 2606 OID 262593)
-- Name: org_project_summary_to_project_categories org_project_summary_to_project_categ_project_categories_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_project_summary_to_project_categories
    ADD CONSTRAINT org_project_summary_to_project_categ_project_categories_id_fkey FOREIGN KEY (project_categories_id) REFERENCES public.project_categories(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4819 (class 2606 OID 262598)
-- Name: orgs orgs_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgs
    ADD CONSTRAINT orgs_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE RESTRICT ON DELETE SET NULL;


--
-- TOC entry 4915 (class 2606 OID 262603)
-- Name: orgs_to_user_actions orgs_to_user_actions_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgs_to_user_actions
    ADD CONSTRAINT orgs_to_user_actions_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4916 (class 2606 OID 262608)
-- Name: orgs_to_user_actions orgs_to_user_actions_user_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgs_to_user_actions
    ADD CONSTRAINT orgs_to_user_actions_user_action_id_fkey FOREIGN KEY (user_action_id) REFERENCES public.user_actions(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4905 (class 2606 OID 262613)
-- Name: orgs_to_users orgs_to_users_inviter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgs_to_users
    ADD CONSTRAINT orgs_to_users_inviter_id_fkey FOREIGN KEY (inviter_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4906 (class 2606 OID 262618)
-- Name: orgs_to_users orgs_to_users_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgs_to_users
    ADD CONSTRAINT orgs_to_users_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4907 (class 2606 OID 262623)
-- Name: orgs_to_users orgs_to_users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgs_to_users
    ADD CONSTRAINT orgs_to_users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.org_roles(name) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4908 (class 2606 OID 262628)
-- Name: orgs_to_users orgs_to_users_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgs_to_users
    ADD CONSTRAINT orgs_to_users_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4909 (class 2606 OID 262633)
-- Name: orgs_to_users orgs_to_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orgs_to_users
    ADD CONSTRAINT orgs_to_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4917 (class 2606 OID 262638)
-- Name: project_address project_address_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_address
    ADD CONSTRAINT project_address_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4918 (class 2606 OID 262643)
-- Name: project_avatars project_avatars_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_avatars
    ADD CONSTRAINT project_avatars_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4919 (class 2606 OID 262648)
-- Name: project_backgrounds project_backgrounds_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_backgrounds
    ADD CONSTRAINT project_backgrounds_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4920 (class 2606 OID 262653)
-- Name: project_banners project_banners_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_banners
    ADD CONSTRAINT project_banners_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4921 (class 2606 OID 262658)
-- Name: project_categories project_categories_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_categories
    ADD CONSTRAINT project_categories_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4922 (class 2606 OID 262663)
-- Name: project_labels project_labels_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_labels
    ADD CONSTRAINT project_labels_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4923 (class 2606 OID 262668)
-- Name: project_templates project_templates_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_templates
    ADD CONSTRAINT project_templates_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4924 (class 2606 OID 262673)
-- Name: project_views project_views_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_views
    ADD CONSTRAINT project_views_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4925 (class 2606 OID 262678)
-- Name: project_views project_views_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_views
    ADD CONSTRAINT project_views_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4830 (class 2606 OID 262683)
-- Name: projects projects_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4910 (class 2606 OID 262688)
-- Name: projects_to_users projects_to_users_inviter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_to_users
    ADD CONSTRAINT projects_to_users_inviter_id_fkey FOREIGN KEY (inviter_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4911 (class 2606 OID 262693)
-- Name: projects_to_users projects_to_users_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_to_users
    ADD CONSTRAINT projects_to_users_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4912 (class 2606 OID 262698)
-- Name: projects_to_users projects_to_users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_to_users
    ADD CONSTRAINT projects_to_users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.project_roles(name) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4913 (class 2606 OID 262703)
-- Name: projects_to_users projects_to_users_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_to_users
    ADD CONSTRAINT projects_to_users_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4914 (class 2606 OID 262708)
-- Name: projects_to_users projects_to_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_to_users
    ADD CONSTRAINT projects_to_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4926 (class 2606 OID 262713)
-- Name: push_notifications push_notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.push_notifications
    ADD CONSTRAINT push_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4834 (class 2606 OID 262718)
-- Name: t_folder_notification_badge t_folder_notification_badge_folder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_folder_notification_badge
    ADD CONSTRAINT t_folder_notification_badge_folder_id_fkey FOREIGN KEY (folder_id) REFERENCES public.folders(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4829 (class 2606 OID 262723)
-- Name: t_folder_pwd t_folder_pwd_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t_folder_pwd
    ADD CONSTRAINT t_folder_pwd_id_fkey FOREIGN KEY (id) REFERENCES public.folders(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4928 (class 2606 OID 262728)
-- Name: task_assignations_orgs task_assignations_orgs_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations_orgs
    ADD CONSTRAINT task_assignations_orgs_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.orgs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4929 (class 2606 OID 262733)
-- Name: task_assignations_orgs task_assignations_orgs_task_assignation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations_orgs
    ADD CONSTRAINT task_assignations_orgs_task_assignation_id_fkey FOREIGN KEY (task_assignation_id) REFERENCES public.task_assignations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4927 (class 2606 OID 262738)
-- Name: task_assignations task_assignations_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations
    ADD CONSTRAINT task_assignations_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4930 (class 2606 OID 262743)
-- Name: task_assignations_teams task_assignations_teams_task_assignation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations_teams
    ADD CONSTRAINT task_assignations_teams_task_assignation_id_fkey FOREIGN KEY (task_assignation_id) REFERENCES public.task_assignations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4931 (class 2606 OID 262748)
-- Name: task_assignations_teams task_assignations_teams_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations_teams
    ADD CONSTRAINT task_assignations_teams_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4932 (class 2606 OID 262753)
-- Name: task_assignations_users task_assignations_users_task_assignation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations_users
    ADD CONSTRAINT task_assignations_users_task_assignation_id_fkey FOREIGN KEY (task_assignation_id) REFERENCES public.task_assignations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4933 (class 2606 OID 262758)
-- Name: task_assignations_users task_assignations_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignations_users
    ADD CONSTRAINT task_assignations_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4934 (class 2606 OID 262763)
-- Name: task_attachments task_attachments_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_attachments
    ADD CONSTRAINT task_attachments_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4935 (class 2606 OID 262768)
-- Name: task_locations task_locations_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_locations
    ADD CONSTRAINT task_locations_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4936 (class 2606 OID 262773)
-- Name: task_subtasks task_subtasks_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_subtasks
    ADD CONSTRAINT task_subtasks_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4937 (class 2606 OID 262778)
-- Name: task_subtasks task_subtasks_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_subtasks
    ADD CONSTRAINT task_subtasks_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4938 (class 2606 OID 262783)
-- Name: task_validations task_validations_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_validations
    ADD CONSTRAINT task_validations_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4939 (class 2606 OID 262788)
-- Name: task_validations task_validations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_validations
    ADD CONSTRAINT task_validations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4940 (class 2606 OID 262793)
-- Name: task_views task_views_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_views
    ADD CONSTRAINT task_views_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4941 (class 2606 OID 262798)
-- Name: task_views task_views_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_views
    ADD CONSTRAINT task_views_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4837 (class 2606 OID 262803)
-- Name: tasks tasks_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4942 (class 2606 OID 262808)
-- Name: tasks_file_versions tasks_file_versions_file_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks_file_versions
    ADD CONSTRAINT tasks_file_versions_file_version_id_fkey FOREIGN KEY (file_version_id) REFERENCES public.file_versions(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4943 (class 2606 OID 262813)
-- Name: tasks_file_versions tasks_file_versions_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks_file_versions
    ADD CONSTRAINT tasks_file_versions_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4944 (class 2606 OID 262818)
-- Name: tasks_file_versions tasks_file_versions_task_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks_file_versions
    ADD CONSTRAINT tasks_file_versions_task_location_id_fkey FOREIGN KEY (task_location_id) REFERENCES public.task_file_version_location(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4838 (class 2606 OID 262823)
-- Name: tasks tasks_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4945 (class 2606 OID 262828)
-- Name: tasks_to_project_labels tasks_to_project_labels_project_label_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks_to_project_labels
    ADD CONSTRAINT tasks_to_project_labels_project_label_id_fkey FOREIGN KEY (project_label_id) REFERENCES public.project_labels(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4946 (class 2606 OID 262833)
-- Name: tasks_to_project_labels tasks_to_project_labels_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks_to_project_labels
    ADD CONSTRAINT tasks_to_project_labels_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4820 (class 2606 OID 262838)
-- Name: teams teams_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4821 (class 2606 OID 262843)
-- Name: teams teams_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4947 (class 2606 OID 262848)
-- Name: teams_to_users teams_to_users_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teams_to_users
    ADD CONSTRAINT teams_to_users_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4948 (class 2606 OID 262853)
-- Name: teams_to_users teams_to_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teams_to_users
    ADD CONSTRAINT teams_to_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4949 (class 2606 OID 262858)
-- Name: user_actions user_actions_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_actions
    ADD CONSTRAINT user_actions_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4950 (class 2606 OID 262863)
-- Name: user_actions user_actions_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_actions
    ADD CONSTRAINT user_actions_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON UPDATE RESTRICT ON DELETE SET NULL;


--
-- TOC entry 4951 (class 2606 OID 262868)
-- Name: user_avatars user_avatars_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_avatars
    ADD CONSTRAINT user_avatars_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4952 (class 2606 OID 262873)
-- Name: user_connections user_connections_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_connections
    ADD CONSTRAINT user_connections_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4953 (class 2606 OID 262878)
-- Name: user_devices user_devices_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_devices
    ADD CONSTRAINT user_devices_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4954 (class 2606 OID 262883)
-- Name: user_locations user_locations_user_connection_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_locations
    ADD CONSTRAINT user_locations_user_connection_id_fkey FOREIGN KEY (user_connection_id) REFERENCES public.user_connections(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4955 (class 2606 OID 262888)
-- Name: user_locations user_locations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_locations
    ADD CONSTRAINT user_locations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 4956 (class 2606 OID 262893)
-- Name: user_metadatas user_metadatas_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_metadatas
    ADD CONSTRAINT user_metadatas_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE SET NULL ON DELETE SET NULL;


--
-- TOC entry 4957 (class 2606 OID 262898)
-- Name: user_notifications user_notifications_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT user_notifications_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 4958 (class 2606 OID 262903)
-- Name: user_notifications user_notifications_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT user_notifications_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON UPDATE RESTRICT ON DELETE SET NULL;


--
-- TOC entry 4959 (class 2606 OID 262908)
-- Name: user_notifications user_notifications_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT user_notifications_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 5313 (class 0 OID 0)
-- Dependencies: 7
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- TOC entry 5233 (class 0 OID 261209)
-- Dependencies: 261 5309
-- Name: file_versions_approvals_overview; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.file_versions_approvals_overview;


--
-- TOC entry 5261 (class 0 OID 261379)
-- Dependencies: 289 5309
-- Name: orgs_projects_users; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.orgs_projects_users;


-- Completed on 2023-03-05 23:38:11 WET

--
-- PostgreSQL database dump complete
--

