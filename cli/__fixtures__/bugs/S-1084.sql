--
-- PostgreSQL database dump
--

-- Dumped from database version 15.1
-- Dumped by pg_dump version 15.2 (Ubuntu 15.2-1.pgdg22.04+1)

-- Started on 2023-06-21 18:34:40 Africa

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
-- TOC entry 20 (class 2615 OID 16488)
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS auth;


--
-- TOC entry 28 (class 2615 OID 16387)
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS extensions;
-- CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA extensions;
-- CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA extensions;
-- CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;
-- CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA extensions;
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- TOC entry 24 (class 2615 OID 16618)
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS graphql;
-- CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA graphql;


--
-- TOC entry 23 (class 2615 OID 16607)
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS graphql_public;


--
-- TOC entry 11 (class 3079 OID 247256)
-- Name: pg_net; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;


--
-- TOC entry 5522 (class 0 OID 0)
-- Dependencies: 11
-- Name: EXTENSION pg_net; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION pg_net IS 'Async HTTP';


--
-- TOC entry 13 (class 2615 OID 16385)
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS pgbouncer;


--
-- TOC entry 14 (class 2615 OID 16643)
-- Name: pgsodium; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS pgsodium;
-- CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA pgsodium;


--
-- TOC entry 7 (class 3079 OID 16644)
-- Name: pgsodium; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS pgsodium WITH SCHEMA pgsodium;


--
-- TOC entry 5523 (class 0 OID 0)
-- Dependencies: 7
-- Name: EXTENSION pgsodium; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION pgsodium IS 'Pgsodium is a modern cryptography library for Postgres.';


--
-- TOC entry 22 (class 2615 OID 16599)
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS realtime;


--
-- TOC entry 21 (class 2615 OID 16536)
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS storage;


--
-- TOC entry 29 (class 2615 OID 247297)
-- Name: supabase_functions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS supabase_functions;


--
-- TOC entry 19 (class 2615 OID 247230)
-- Name: supabase_migrations; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS supabase_migrations;


--
-- TOC entry 16 (class 2615 OID 16946)
-- Name: vault; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS vault;
-- CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA vault;


--
-- TOC entry 6 (class 3079 OID 16633)
-- Name: pg_graphql; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS pg_graphql WITH SCHEMA graphql;


--
-- TOC entry 5524 (class 0 OID 0)
-- Dependencies: 6
-- Name: EXTENSION pg_graphql; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION pg_graphql IS 'pg_graphql: GraphQL support';


--
-- TOC entry 2 (class 3079 OID 16388)
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- TOC entry 5525 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- TOC entry 9 (class 3079 OID 28552)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 5526 (class 0 OID 0)
-- Dependencies: 9
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- TOC entry 4 (class 3079 OID 16434)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- TOC entry 5527 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 5 (class 3079 OID 16471)
-- Name: pgjwt; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS pgjwt WITH SCHEMA extensions;


--
-- TOC entry 5528 (class 0 OID 0)
-- Dependencies: 5
-- Name: EXTENSION pgjwt; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION pgjwt IS 'JSON Web Token API for Postgresql';


--
-- TOC entry 10 (class 3079 OID 28633)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 5529 (class 0 OID 0)
-- Dependencies: 10
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- TOC entry 8 (class 3079 OID 16947)
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- TOC entry 5530 (class 0 OID 0)
-- Dependencies: 8
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- TOC entry 3 (class 3079 OID 16423)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- TOC entry 5531 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 2081 (class 1247 OID 28370)
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- TOC entry 2105 (class 1247 OID 28511)
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- TOC entry 2078 (class 1247 OID 28364)
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- TOC entry 2075 (class 1247 OID 28358)
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn'
);


--
-- TOC entry 2150 (class 1247 OID 29680)
-- Name: land_registry_document_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.land_registry_document_status_enum AS ENUM (
    'complete',
    'acknowledged',
    'rejected'
);


--
-- TOC entry 2153 (class 1247 OID 29688)
-- Name: user_account_roles_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_account_roles_enum AS ENUM (
    'manage_users',
    'owner'
);


--
-- TOC entry 381 (class 1255 OID 16534)
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- TOC entry 5532 (class 0 OID 0)
-- Dependencies: 381
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- TOC entry 586 (class 1255 OID 28340)
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- TOC entry 380 (class 1255 OID 16533)
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- TOC entry 5533 (class 0 OID 0)
-- Dependencies: 380
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- TOC entry 376 (class 1255 OID 16532)
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- TOC entry 5534 (class 0 OID 0)
-- Dependencies: 376
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- TOC entry 549 (class 1255 OID 16591)
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  schema_is_cron bool;
BEGIN
  schema_is_cron = (
    SELECT n.nspname = 'cron'
    FROM pg_event_trigger_ddl_commands() AS ev
    LEFT JOIN pg_catalog.pg_namespace AS n
      ON ev.objid = n.oid
  );

  IF schema_is_cron
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;

  END IF;

END;
$$;


--
-- TOC entry 5535 (class 0 OID 0)
-- Dependencies: 549
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- TOC entry 397 (class 1255 OID 16612)
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    func_is_graphql_resolve bool;
BEGIN
    func_is_graphql_resolve = (
        SELECT n.proname = 'resolve'
        FROM pg_event_trigger_ddl_commands() AS ev
        LEFT JOIN pg_catalog.pg_proc AS n
        ON ev.objid = n.oid
    );

    IF func_is_graphql_resolve
    THEN
        -- Update public wrapper to pass all arguments through to the pg_graphql resolve func
        DROP FUNCTION IF EXISTS graphql_public.graphql;
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language sql
        as $$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $$;

        -- This hook executes when `graphql.resolve` is created. That is not necessarily the last
        -- function in the extension so we need to grant permissions on existing entities AND
        -- update default permissions to any others that are created after `graphql.resolve`
        grant usage on schema graphql to postgres, anon, authenticated, service_role;
        grant select on all tables in schema graphql to postgres, anon, authenticated, service_role;
        grant execute on all functions in schema graphql to postgres, anon, authenticated, service_role;
        grant all on all sequences in schema graphql to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on tables to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on functions to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on sequences to postgres, anon, authenticated, service_role;
    END IF;

END;
$_$;


--
-- TOC entry 5536 (class 0 OID 0)
-- Dependencies: 397
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- TOC entry 583 (class 1255 OID 16593)
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF EXISTS (
      SELECT 1
      FROM pg_event_trigger_ddl_commands() AS ev
      JOIN pg_extension AS ext
      ON ev.objid = ext.oid
      WHERE ext.extname = 'pg_net'
    )
    THEN
      GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END;
  $$;


--
-- TOC entry 5537 (class 0 OID 0)
-- Dependencies: 583
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- TOC entry 395 (class 1255 OID 16603)
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- TOC entry 396 (class 1255 OID 16604)
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- TOC entry 582 (class 1255 OID 16614)
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


--
-- TOC entry 5538 (class 0 OID 0)
-- Dependencies: 582
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- TOC entry 347 (class 1255 OID 16386)
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: -
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RAISE WARNING 'PgBouncer auth request: %', p_usename;

    RETURN QUERY
    SELECT usename::TEXT, passwd::TEXT FROM pg_catalog.pg_shadow
    WHERE usename = p_usename;
END;
$$;


--
-- TOC entry 348 (class 1255 OID 138739)
-- Name: create_auth_user_from_user_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_auth_user_from_user_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
    INSERT INTO auth.users (id) VALUES (NEW.id);
    RETURN NEW; -- in plpgsql you must return OLD, NEW, or another record of table's type
END;$$;


--
-- TOC entry 349 (class 1255 OID 138740)
-- Name: get_team_ids_for_authenticated_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_team_ids_for_authenticated_user() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    select "teamId"
    from user_account
    where id = auth.uid()
$$;


--
-- TOC entry 350 (class 1255 OID 138741)
-- Name: get_user_ids_for_authenticated_team(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_ids_for_authenticated_team() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    select id
    from user_account
    where "teamId" IN (
      select "teamId"
      from user_account
      where id = auth.uid()
    )
$$;


--
-- TOC entry 351 (class 1255 OID 138765)
-- Name: truncate_tables(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.truncate_tables(username character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    statements CURSOR FOR
        SELECT tablename FROM pg_tables
        WHERE tableowner = username AND schemaname = 'public';
BEGIN
    FOR stmt IN statements LOOP
        EXECUTE 'TRUNCATE TABLE ' || quote_ident(stmt.tablename) || ' CASCADE;';
    END LOOP;
END;
$$;


--
-- TOC entry 593 (class 1255 OID 28546)
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


--
-- TOC entry 379 (class 1255 OID 16580)
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
_filename text;
BEGIN
    select string_to_array(name, '/') into _parts;
    select _parts[array_length(_parts,1)] into _filename;
    -- @todo return the last part instead of 2
    return split_part(_filename, '.', 2);
END
$$;


--
-- TOC entry 378 (class 1255 OID 16579)
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
    select string_to_array(name, '/') into _parts;
    return _parts[array_length(_parts,1)];
END
$$;


--
-- TOC entry 377 (class 1255 OID 16578)
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
    select string_to_array(name, '/') into _parts;
    return _parts[1:array_length(_parts,1)-1];
END
$$;


--
-- TOC entry 587 (class 1255 OID 28533)
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::int) as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


--
-- TOC entry 591 (class 1255 OID 28535)
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
declare
  v_order_by text;
  v_sort_order text;
begin
  case
    when sortcolumn = 'name' then
      v_order_by = 'name';
    when sortcolumn = 'updated_at' then
      v_order_by = 'updated_at';
    when sortcolumn = 'created_at' then
      v_order_by = 'created_at';
    when sortcolumn = 'last_accessed_at' then
      v_order_by = 'last_accessed_at';
    else
      v_order_by = 'name';
  end case;

  case
    when sortorder = 'asc' then
      v_sort_order = 'asc';
    when sortorder = 'desc' then
      v_sort_order = 'desc';
    else
      v_sort_order = 'asc';
  end case;

  v_order_by = v_order_by || ' ' || v_sort_order;

  return query execute
    'with folders as (
       select path_tokens[$1] as folder
       from storage.objects
         where objects.name ilike $2 || $3 || ''%''
           and bucket_id = $4
           and array_length(regexp_split_to_array(objects.name, ''/''), 1) <> $1
       group by folder
       order by folder ' || v_sort_order || '
     )
     (select folder as "name",
            null as id,
            null as updated_at,
            null as created_at,
            null as last_accessed_at,
            null as metadata from folders)
     union all
     (select path_tokens[$1] as "name",
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
     from storage.objects
     where objects.name ilike $2 || $3 || ''%''
       and bucket_id = $4
       and array_length(regexp_split_to_array(objects.name, ''/''), 1) = $1
     order by ' || v_order_by || ')
     limit $5
     offset $6' using levels, prefix, search, bucketname, limits, offsets;
end;
$_$;


--
-- TOC entry 592 (class 1255 OID 28536)
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


--
-- TOC entry 398 (class 1255 OID 247321)
-- Name: http_request(); Type: FUNCTION; Schema: supabase_functions; Owner: -
--

CREATE FUNCTION supabase_functions.http_request() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'supabase_functions'
    AS $$
    DECLARE
      request_id bigint;
      payload jsonb;
      url text := TG_ARGV[0]::text;
      method text := TG_ARGV[1]::text;
      headers jsonb DEFAULT '{}'::jsonb;
      params jsonb DEFAULT '{}'::jsonb;
      timeout_ms integer DEFAULT 1000;
    BEGIN
      IF url IS NULL OR url = 'null' THEN
        RAISE EXCEPTION 'url argument is missing';
      END IF;

      IF method IS NULL OR method = 'null' THEN
        RAISE EXCEPTION 'method argument is missing';
      END IF;

      IF TG_ARGV[2] IS NULL OR TG_ARGV[2] = 'null' THEN
        headers = '{"Content-Type": "application/json"}'::jsonb;
      ELSE
        headers = TG_ARGV[2]::jsonb;
      END IF;

      IF TG_ARGV[3] IS NULL OR TG_ARGV[3] = 'null' THEN
        params = '{}'::jsonb;
      ELSE
        params = TG_ARGV[3]::jsonb;
      END IF;

      IF TG_ARGV[4] IS NULL OR TG_ARGV[4] = 'null' THEN
        timeout_ms = 1000;
      ELSE
        timeout_ms = TG_ARGV[4]::integer;
      END IF;

      CASE
        WHEN method = 'GET' THEN
          SELECT http_get INTO request_id FROM net.http_get(
            url,
            params,
            headers,
            timeout_ms
          );
        WHEN method = 'POST' THEN
          payload = jsonb_build_object(
            'old_record', OLD,
            'record', NEW,
            'type', TG_OP,
            'table', TG_TABLE_NAME,
            'schema', TG_TABLE_SCHEMA
          );

          SELECT http_post INTO request_id FROM net.http_post(
            url,
            payload,
            params,
            headers,
            timeout_ms
          );
        ELSE
          RAISE EXCEPTION 'method argument % is invalid', method;
      END CASE;

      INSERT INTO supabase_functions.hooks
        (hook_table_id, hook_name, request_id)
      VALUES
        (TG_RELID, TG_NAME, request_id);

      RETURN NEW;
    END
  $$;



SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 261 (class 1259 OID 16519)
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- TOC entry 5539 (class 0 OID 0)
-- Dependencies: 261
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- TOC entry 290 (class 1259 OID 28515)
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text NOT NULL,
    code_challenge_method auth.code_challenge_method NOT NULL,
    code_challenge text NOT NULL,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL
);


--
-- TOC entry 5540 (class 0 OID 0)
-- Dependencies: 290
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'stores metadata for oauth provider logins';


--
-- TOC entry 281 (class 1259 OID 28312)
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED
);


--
-- TOC entry 5541 (class 0 OID 0)
-- Dependencies: 281
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- TOC entry 5542 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- TOC entry 260 (class 1259 OID 16512)
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- TOC entry 5543 (class 0 OID 0)
-- Dependencies: 260
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- TOC entry 285 (class 1259 OID 28402)
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- TOC entry 5544 (class 0 OID 0)
-- Dependencies: 285
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- TOC entry 284 (class 1259 OID 28390)
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL
);


--
-- TOC entry 5545 (class 0 OID 0)
-- Dependencies: 284
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- TOC entry 283 (class 1259 OID 28377)
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text
);


--
-- TOC entry 5546 (class 0 OID 0)
-- Dependencies: 283
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- TOC entry 259 (class 1259 OID 16501)
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- TOC entry 5547 (class 0 OID 0)
-- Dependencies: 259
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- TOC entry 258 (class 1259 OID 16500)
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5548 (class 0 OID 0)
-- Dependencies: 258
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- TOC entry 288 (class 1259 OID 28444)
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- TOC entry 5549 (class 0 OID 0)
-- Dependencies: 288
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- TOC entry 289 (class 1259 OID 28462)
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    from_ip_address inet,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- TOC entry 5550 (class 0 OID 0)
-- Dependencies: 289
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- TOC entry 262 (class 1259 OID 16527)
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- TOC entry 5551 (class 0 OID 0)
-- Dependencies: 262
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- TOC entry 282 (class 1259 OID 28342)
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone
);


--
-- TOC entry 5552 (class 0 OID 0)
-- Dependencies: 282
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- TOC entry 5553 (class 0 OID 0)
-- Dependencies: 282
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- TOC entry 287 (class 1259 OID 28429)
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- TOC entry 5554 (class 0 OID 0)
-- Dependencies: 287
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- TOC entry 286 (class 1259 OID 28420)
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- TOC entry 5555 (class 0 OID 0)
-- Dependencies: 286
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- TOC entry 5556 (class 0 OID 0)
-- Dependencies: 286
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- TOC entry 257 (class 1259 OID 16489)
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- TOC entry 5557 (class 0 OID 0)
-- Dependencies: 257
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- TOC entry 5558 (class 0 OID 0)
-- Dependencies: 257
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- TOC entry 346 (class 1259 OID 281106)
-- Name: bulk_title_purchase; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bulk_title_purchase (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "isInitialising" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "columnIdId" uuid NOT NULL,
    "userId" uuid NOT NULL
);


--
-- TOC entry 296 (class 1259 OID 29693)
-- Name: card; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.card (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    pos double precision NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "columnId" uuid NOT NULL,
    "importId" character varying,
    description character varying,
    "archivedAt" timestamp without time zone,
    "creatorId" uuid NOT NULL,
    "lastColumnUpdatedAt" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- TOC entry 344 (class 1259 OID 270152)
-- Name: card_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.card_2 (
    id uuid,
    name character varying,
    pos double precision,
    "createdAt" timestamp without time zone,
    "updatedAt" timestamp without time zone,
    "columnId" uuid,
    "importId" character varying,
    description character varying,
    "archivedAt" timestamp without time zone,
    "creatorId" uuid
);


--
-- TOC entry 297 (class 1259 OID 29701)
-- Name: card_card_labels_card_label; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.card_card_labels_card_label (
    "cardId" uuid NOT NULL,
    "cardLabelId" uuid NOT NULL
);


--
-- TOC entry 298 (class 1259 OID 29704)
-- Name: card_comment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.card_comment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    content character varying NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "userId" uuid NOT NULL,
    "cardId" uuid NOT NULL
);


--
-- TOC entry 299 (class 1259 OID 29717)
-- Name: card_label; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.card_label (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    color character varying,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "projectId" uuid,
    "importId" character varying,
    name character varying NOT NULL,
    "creatorId" uuid
);


--
-- TOC entry 300 (class 1259 OID 29725)
-- Name: card_land_assemblies_land_assembly; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.card_land_assemblies_land_assembly (
    "cardId" uuid NOT NULL,
    "landAssemblyId" uuid NOT NULL
);


--
-- TOC entry 301 (class 1259 OID 29728)
-- Name: card_members_user_account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.card_members_user_account (
    "cardId" uuid NOT NULL,
    "userAccountId" uuid NOT NULL
);


--
-- TOC entry 302 (class 1259 OID 29731)
-- Name: card_title_attachments_saved_title; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.card_title_attachments_saved_title (
    "cardId" uuid NOT NULL,
    "savedTitleId" uuid NOT NULL
);


--
-- TOC entry 303 (class 1259 OID 29734)
-- Name: dxf_export; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dxf_export (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    geom INTEGER NOT NULL,
    "areaHectares" double precision NOT NULL,
    "exportFile" character varying,
    "airflowExecutionTime" timestamp without time zone,
    "airflowRunId" character varying,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "ownerId" uuid NOT NULL,
    "teamId" uuid NOT NULL,
    "airflowExecutionTimeString" character varying,
    "invoiceId" character varying NOT NULL
);


--
-- TOC entry 304 (class 1259 OID 29742)
-- Name: dxf_quote; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dxf_quote (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "userId" uuid NOT NULL,
    "stripeInvoiceId" character varying,
    geom INTEGER,
    hectares double precision DEFAULT 0 NOT NULL
);


--
-- TOC entry 305 (class 1259 OID 29751)
-- Name: invite; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invite (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying NOT NULL,
    name character varying NOT NULL,
    "inviteCode" character varying NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "teamId" uuid NOT NULL,
    "userId" uuid,
    owner boolean DEFAULT false NOT NULL,
    "numberOfInvitesSent" integer DEFAULT 0 NOT NULL,
    "lastEmailSent" timestamp without time zone
);


--
-- TOC entry 306 (class 1259 OID 29761)
-- Name: land_assembly; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.land_assembly (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    geom INTEGER  NOT NULL,
    "areaSize" double precision DEFAULT '0'::double precision NOT NULL,
    perimeter double precision DEFAULT '0'::double precision NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "teamId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    "primaryAddress" character varying
);


--
-- TOC entry 345 (class 1259 OID 271159)
-- Name: land_assembly_saved_titles_saved_title; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.land_assembly_saved_titles_saved_title (
    "landAssemblyId" uuid NOT NULL,
    "savedTitleId" uuid NOT NULL
);


--
-- TOC entry 307 (class 1259 OID 29771)
-- Name: land_registry_document; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.land_registry_document (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reference character varying NOT NULL,
    "extReference" character varying,
    "documentType" character varying NOT NULL,
    status public.land_registry_document_status_enum,
    "pollAt" timestamp without time zone,
    reason character varying,
    filename character varying,
    "landRegistryPricePaidPennies" integer,
    "priceToChargePennies" integer,
    charged boolean DEFAULT false NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "savedTitleId" uuid,
    "createdById" uuid,
    "pollType" character varying,
    "extractedData" jsonb,
    "extractedPricePaid" character varying,
    "extractedSaleDate" timestamp without time zone,
    "extractedEntryIndicators" character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    "bulkTitlePurchaseId" uuid
);


--
-- TOC entry 308 (class 1259 OID 29781)
-- Name: land_registry_proprietor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.land_registry_proprietor (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "firstName" character varying,
    "lastName" character varying,
    "companyName" character varying,
    "companyNumber" character varying,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "documentId" uuid NOT NULL
);


--
-- TOC entry 309 (class 1259 OID 29789)
-- Name: land_registry_proprietor_address; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.land_registry_proprietor_address (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    address character varying,
    postcode character varying,
    "addressType" character varying,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "proprietorId" uuid NOT NULL
);


--
-- TOC entry 310 (class 1259 OID 29797)
-- Name: letter_campaign; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.letter_campaign (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    description character varying,
    closed boolean DEFAULT false NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "teamId" uuid NOT NULL,
    "letterTemplateId" uuid
);


--
-- TOC entry 311 (class 1259 OID 29806)
-- Name: letter_campaign_address; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.letter_campaign_address (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    address character varying NOT NULL,
    "templateHtml" character varying NOT NULL,
    "firstName" character varying,
    "lastName" character varying,
    "addGoogleMapOutline" boolean NOT NULL,
    "propertyAddress" character varying,
    uprn bigint,
    "importId" character varying NOT NULL,
    source character varying NOT NULL,
    "pdfPath" character varying,
    "stannpId" character varying,
    cost double precision NOT NULL,
    "titleNumber" character varying NOT NULL,
    "sentDate" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "savedTitleId" uuid,
    "letterCampaignId" uuid NOT NULL
);


--
-- TOC entry 312 (class 1259 OID 29814)
-- Name: letter_credit_ledger; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.letter_credit_ledger (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    amount double precision DEFAULT '0'::double precision NOT NULL,
    "stripeSessionId" character varying,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "letterCampaignId" uuid,
    "teamId" uuid NOT NULL
);


--
-- TOC entry 313 (class 1259 OID 29823)
-- Name: letter_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.letter_template (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    "templateHtml" character varying NOT NULL,
    "addGoogleMapOutline" boolean DEFAULT false NOT NULL,
    "thumbnailPath" character varying,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "teamId" uuid NOT NULL,
    "archivedAt" timestamp without time zone,
    "colorForOutline" character varying DEFAULT '#8421B6'::character varying NOT NULL
);


--
-- TOC entry 314 (class 1259 OID 29833)
-- Name: migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    "timestamp" bigint NOT NULL,
    name character varying NOT NULL
);

--
-- TOC entry 315 (class 1259 OID 29838)
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5559 (class 0 OID 0)
-- Dependencies: 315
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- TOC entry 316 (class 1259 OID 29839)
-- Name: planning_alert; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planning_alert (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    "userId" uuid NOT NULL,
    "lastSearched" timestamp without time zone NOT NULL,
    query jsonb,
    "trackPlanningApplicationId" character varying,
    "notificationPeriod" character varying NOT NULL,
    "entityToBeNotified" character varying NOT NULL,
    "archivedAt" timestamp without time zone,
    paused boolean DEFAULT false NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "savedTitleId" uuid,
    type character varying NOT NULL
);


--
-- TOC entry 317 (class 1259 OID 29848)
-- Name: planning_alert_users_to_alert_user_account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planning_alert_users_to_alert_user_account (
    "planningAlertId" uuid NOT NULL,
    "userAccountId" uuid NOT NULL
);


--
-- TOC entry 318 (class 1259 OID 29851)
-- Name: platform_notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_notification (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type character varying NOT NULL,
    title character varying NOT NULL,
    message character varying NOT NULL,
    "emailSent" boolean DEFAULT false NOT NULL,
    "isRead" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "numberOfNewAndChangedPlanningApplications" integer,
    "userId" uuid,
    "planningAlertId" uuid,
    "changedPlanningApplicationIds" character varying[] DEFAULT '{}'::character varying[]
);


--
-- TOC entry 319 (class 1259 OID 29862)
-- Name: project; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    colour character varying NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "ownerId" uuid NOT NULL,
    "teamId" uuid NOT NULL,
    description character varying,
    "archivedAt" timestamp without time zone
);


--
-- TOC entry 320 (class 1259 OID 29870)
-- Name: project_column; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_column (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    pos double precision NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "projectId" uuid NOT NULL,
    colour character varying NOT NULL,
    "archivedAt" timestamp without time zone
);


--
-- TOC entry 321 (class 1259 OID 29878)
-- Name: project_members_user_account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_members_user_account (
    "projectId" uuid NOT NULL,
    "userAccountId" uuid NOT NULL
);


--
-- TOC entry 322 (class 1259 OID 29881)
-- Name: project_title_attachments_saved_title; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_title_attachments_saved_title (
    "projectId" uuid NOT NULL,
    "savedTitleId" uuid NOT NULL
);


--
-- TOC entry 323 (class 1259 OID 29884)
-- Name: saved_area; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.saved_area (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    area INTEGER NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "userId" uuid NOT NULL
);


--
-- TOC entry 324 (class 1259 OID 29892)
-- Name: saved_query; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.saved_query (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    description character varying,
    tool character varying NOT NULL,
    query jsonb NOT NULL,
    "archivedAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "userId" uuid NOT NULL,
    "sourceId" character varying
);


--
-- TOC entry 325 (class 1259 OID 29900)
-- Name: saved_title; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.saved_title (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "titleNo" character varying NOT NULL,
    custom boolean NOT NULL,
    area INTEGER  NOT NULL,
    "primaryAddress" character varying,
    "noAddresses" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "teamId" uuid NOT NULL,
    "createdById" uuid NOT NULL,
    "areaSize" double precision DEFAULT 0 NOT NULL,
    "isScotland" boolean DEFAULT false NOT NULL
);


--
-- TOC entry 326 (class 1259 OID 29910)
-- Name: session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.session (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    device character varying,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "userId" uuid NOT NULL,
    admin boolean DEFAULT false NOT NULL,
    "userAgent" character varying
);


--
-- TOC entry 327 (class 1259 OID 29919)
-- Name: team; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    "stripeId" character varying NOT NULL,
    "trialEnd" timestamp without time zone,
    "subscriptionId" character varying,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "currentPeriodStart" timestamp without time zone,
    "currentPeriodEnd" timestamp without time zone,
    "hasOnboarded" boolean DEFAULT true NOT NULL,
    "subscriptionStatus" character varying,
    address jsonb,
    "subscriptionCreated" timestamp without time zone,
    product jsonb,
    period character varying,
    "productAddons" jsonb DEFAULT '[]'::jsonb NOT NULL,
    color character varying,
    "logoPath" character varying,
    "hasStrategicLandBeta" boolean DEFAULT false NOT NULL,
    "autoTopupTitleCredit" integer,
    "firstTrialEnd" timestamp without time zone,
    "customColours" character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    "hubspotCustomerUrl" character varying,
    "salesDevelopmentRepresentative" character varying,
    "businessDevelopmentManager" character varying,
    "customerSuccessManager" character varying
);



--
-- TOC entry 328 (class 1259 OID 29937)
-- Name: title_credit_ledger; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.title_credit_ledger (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    amount double precision DEFAULT '0'::double precision NOT NULL,
    "stripeSessionId" character varying,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "landRegistryDocumentId" uuid,
    "teamId" uuid NOT NULL,
    "userId" uuid,
    "stripeInvoiceId" character varying,
    "stripePaymentIntent" character varying
);


--
-- TOC entry 329 (class 1259 OID 29946)
-- Name: title_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.title_report (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "fileName" character varying NOT NULL,
    "filePath" character varying NOT NULL,
    "titleNo" character varying NOT NULL,
    status character varying NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "userId" uuid NOT NULL,
    "teamId" uuid NOT NULL
);


--
-- TOC entry 330 (class 1259 OID 29954)
-- Name: usage_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usage_event (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "eventName" character varying NOT NULL,
    identifier character varying,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "teamId" uuid NOT NULL,
    custom boolean DEFAULT false NOT NULL
);


--
-- TOC entry 331 (class 1259 OID 29968)
-- Name: user_account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_account (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    email character varying NOT NULL,
    "phoneVerificationCode" integer,
    "lastPhoneVerificationSent" timestamp without time zone,
    "passwordHash" character varying,
    "phoneNumber" character varying,
    "pendingPhoneNumber" character varying,
    "phoneVerified" boolean DEFAULT false NOT NULL,
    "publicKey" character varying NOT NULL,
    roles public.user_account_roles_enum[] DEFAULT '{}'::public.user_account_roles_enum[] NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "archivedAt" timestamp without time zone,
    "teamId" uuid NOT NULL,
    "perishibleToken" character varying,
    admin boolean DEFAULT false NOT NULL,
    "googleRefreshToken" character varying,
    "loginCount" integer DEFAULT 0 NOT NULL,
    "completedWelcomeTour" boolean DEFAULT false NOT NULL,
    "initWelcomeTour" boolean DEFAULT false NOT NULL,
    "apiKey" uuid DEFAULT gen_random_uuid() NOT NULL,
    "hasCompletedNewNavigationWalkthrough" boolean DEFAULT false NOT NULL,
    "resetPhoneNumberCount" integer DEFAULT 0 NOT NULL,
    "superAdmin" boolean DEFAULT false NOT NULL,
    "employeeRoles" character varying[] DEFAULT '{}'::character varying[] NOT NULL
);


--
-- TOC entry 332 (class 1259 OID 29985)
-- Name: workspace; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workspace (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    icon character varying NOT NULL,
    colour character varying NOT NULL,
    "workspaceSettings" jsonb NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "teamId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    "archivedAt" timestamp without time zone
);


--
-- TOC entry 333 (class 1259 OID 29993)
-- Name: workspace_users_that_favourited_user_account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workspace_users_that_favourited_user_account (
    "workspaceId" uuid NOT NULL,
    "userAccountId" uuid NOT NULL
);


--
-- TOC entry 263 (class 1259 OID 16540)
-- Name: buckets; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[]
);


--
-- TOC entry 265 (class 1259 OID 16582)
-- Name: migrations; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- TOC entry 264 (class 1259 OID 16555)
-- Name: objects; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text
);


--
-- TOC entry 342 (class 1259 OID 247310)
-- Name: hooks; Type: TABLE; Schema: supabase_functions; Owner: -
--

CREATE TABLE supabase_functions.hooks (
    id bigint NOT NULL,
    hook_table_id integer NOT NULL,
    hook_name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    request_id bigint
);


--
-- TOC entry 5560 (class 0 OID 0)
-- Dependencies: 342
-- Name: TABLE hooks; Type: COMMENT; Schema: supabase_functions; Owner: -
--

COMMENT ON TABLE supabase_functions.hooks IS 'Supabase Functions Hooks: Audit trail for triggered hooks.';


--
-- TOC entry 341 (class 1259 OID 247309)
-- Name: hooks_id_seq; Type: SEQUENCE; Schema: supabase_functions; Owner: -
--

CREATE SEQUENCE supabase_functions.hooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5561 (class 0 OID 0)
-- Dependencies: 341
-- Name: hooks_id_seq; Type: SEQUENCE OWNED BY; Schema: supabase_functions; Owner: -
--

ALTER SEQUENCE supabase_functions.hooks_id_seq OWNED BY supabase_functions.hooks.id;


--
-- TOC entry 340 (class 1259 OID 247301)
-- Name: migrations; Type: TABLE; Schema: supabase_functions; Owner: -
--

CREATE TABLE supabase_functions.migrations (
    version text NOT NULL,
    inserted_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 334 (class 1259 OID 247231)
-- Name: schema_migrations; Type: TABLE; Schema: supabase_migrations; Owner: -
--

CREATE TABLE supabase_migrations.schema_migrations (
    version text NOT NULL
);

--
-- TOC entry 4766 (class 2604 OID 16504)
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- TOC entry 4845 (class 2604 OID 29996)
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- TOC entry 4914 (class 2604 OID 247313)
-- Name: hooks id; Type: DEFAULT; Schema: supabase_functions; Owner: -
--

ALTER TABLE ONLY supabase_functions.hooks ALTER COLUMN id SET DEFAULT nextval('supabase_functions.hooks_id_seq'::regclass);


--
-- TOC entry 4996 (class 2606 OID 28415)
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- TOC entry 4954 (class 2606 OID 16525)
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- TOC entry 5018 (class 2606 OID 28521)
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- TOC entry 4981 (class 2606 OID 28318)
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (provider, id);


--
-- TOC entry 4952 (class 2606 OID 16518)
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- TOC entry 4998 (class 2606 OID 28408)
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- TOC entry 4994 (class 2606 OID 28396)
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- TOC entry 4990 (class 2606 OID 28383)
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- TOC entry 4946 (class 2606 OID 16508)
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 4949 (class 2606 OID 28325)
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- TOC entry 5007 (class 2606 OID 28455)
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- TOC entry 5009 (class 2606 OID 28453)
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- TOC entry 5014 (class 2606 OID 28469)
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- TOC entry 4957 (class 2606 OID 16531)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 4985 (class 2606 OID 28346)
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 5004 (class 2606 OID 28436)
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- TOC entry 5000 (class 2606 OID 28427)
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- TOC entry 4939 (class 2606 OID 28509)
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- TOC entry 4941 (class 2606 OID 16495)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 5220 (class 2606 OID 271163)
-- Name: land_assembly_saved_titles_saved_title PK_02f71e7869ca1b02612ddbcb1ad; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_assembly_saved_titles_saved_title
    ADD CONSTRAINT "PK_02f71e7869ca1b02612ddbcb1ad" PRIMARY KEY ("landAssemblyId", "savedTitleId");


--
-- TOC entry 5129 (class 2606 OID 29998)
-- Name: planning_alert_users_to_alert_user_account PK_0faf23fd745ea5d27fc50bd6c7e; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_alert_users_to_alert_user_account
    ADD CONSTRAINT "PK_0faf23fd745ea5d27fc50bd6c7e" PRIMARY KEY ("planningAlertId", "userAccountId");


--
-- TOC entry 5056 (class 2606 OID 30000)
-- Name: card_title_attachments_saved_title PK_17da45deace81b4aaff27e83c13; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_title_attachments_saved_title
    ADD CONSTRAINT "PK_17da45deace81b4aaff27e83c13" PRIMARY KEY ("cardId", "savedTitleId");


--
-- TOC entry 5180 (class 2606 OID 30002)
-- Name: title_credit_ledger PK_1cd23621d7c35311e25348d31b5; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.title_credit_ledger
    ADD CONSTRAINT "PK_1cd23621d7c35311e25348d31b5" PRIMARY KEY (id);


--
-- TOC entry 5153 (class 2606 OID 30004)
-- Name: saved_area PK_2ae8612f6225d408d4e53c2a455; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_area
    ADD CONSTRAINT "PK_2ae8612f6225d408d4e53c2a455" PRIMARY KEY (id);


--
-- TOC entry 5097 (class 2606 OID 30006)
-- Name: land_registry_proprietor_address PK_3defdb6af410d5076bb649b4b47; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_registry_proprietor_address
    ADD CONSTRAINT "PK_3defdb6af410d5076bb649b4b47" PRIMARY KEY (id);


--
-- TOC entry 5138 (class 2606 OID 30008)
-- Name: project PK_4d68b1358bb5b766d3e78f32f57; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT "PK_4d68b1358bb5b766d3e78f32f57" PRIMARY KEY (id);


--
-- TOC entry 5224 (class 2606 OID 281114)
-- Name: bulk_title_purchase PK_4f77e102f89ae9d2bc6a2cee9bc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bulk_title_purchase
    ADD CONSTRAINT "PK_4f77e102f89ae9d2bc6a2cee9bc" PRIMARY KEY (id);


--
-- TOC entry 5115 (class 2606 OID 30010)
-- Name: letter_template PK_50c04255bee2e17cc53282772df; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letter_template
    ADD CONSTRAINT "PK_50c04255bee2e17cc53282772df" PRIMARY KEY (id);


--
-- TOC entry 5093 (class 2606 OID 30012)
-- Name: land_registry_proprietor PK_50ddee3d8c097b8c26eadc79750; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_registry_proprietor
    ADD CONSTRAINT "PK_50ddee3d8c097b8c26eadc79750" PRIMARY KEY (id);


--
-- TOC entry 5111 (class 2606 OID 30014)
-- Name: letter_credit_ledger PK_5449bc32a15ce127518618da437; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letter_credit_ledger
    ADD CONSTRAINT "PK_5449bc32a15ce127518618da437" PRIMARY KEY (id);


--
-- TOC entry 5107 (class 2606 OID 30016)
-- Name: letter_campaign_address PK_660c30c655fbddde0ebfdeb8d31; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letter_campaign_address
    ADD CONSTRAINT "PK_660c30c655fbddde0ebfdeb8d31" PRIMARY KEY (id);


--
-- TOC entry 5160 (class 2606 OID 30018)
-- Name: saved_query PK_6ed762671f186245d0287c78f21; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_query
    ADD CONSTRAINT "PK_6ed762671f186245d0287c78f21" PRIMARY KEY (id);


--
-- TOC entry 5189 (class 2606 OID 30020)
-- Name: usage_event PK_797d3f1dfd307095af5e4fd8457; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usage_event
    ADD CONSTRAINT "PK_797d3f1dfd307095af5e4fd8457" PRIMARY KEY (id);


--
-- TOC entry 5052 (class 2606 OID 30022)
-- Name: card_members_user_account PK_7a728de64d2e6febe8a6baea5e4; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_members_user_account
    ADD CONSTRAINT "PK_7a728de64d2e6febe8a6baea5e4" PRIMARY KEY ("cardId", "userAccountId");


--
-- TOC entry 5170 (class 2606 OID 30024)
-- Name: saved_title PK_8073a121dc156d75467bdc3607c; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_title
    ADD CONSTRAINT "PK_8073a121dc156d75467bdc3607c" PRIMARY KEY (id);


--
-- TOC entry 5151 (class 2606 OID 30026)
-- Name: project_title_attachments_saved_title PK_859264119fd19d6e640d61f3e92; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_title_attachments_saved_title
    ADD CONSTRAINT "PK_859264119fd19d6e640d61f3e92" PRIMARY KEY ("projectId", "savedTitleId");


--
-- TOC entry 5081 (class 2606 OID 30028)
-- Name: land_assembly PK_8ac7a196a18d7008041ff7d5cce; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_assembly
    ADD CONSTRAINT "PK_8ac7a196a18d7008041ff7d5cce" PRIMARY KEY (id);


--
-- TOC entry 5117 (class 2606 OID 30030)
-- Name: migrations PK_8c82d7f526340ab734260ea46be; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT "PK_8c82d7f526340ab734260ea46be" PRIMARY KEY (id);


--
-- TOC entry 5060 (class 2606 OID 30032)
-- Name: dxf_export PK_8c874c9277948d0b2ab1063ec05; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dxf_export
    ADD CONSTRAINT "PK_8c874c9277948d0b2ab1063ec05" PRIMARY KEY (id);


--
-- TOC entry 5208 (class 2606 OID 30034)
-- Name: workspace_users_that_favourited_user_account PK_936ce123a00db7afb5d615826c7; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_users_that_favourited_user_account
    ADD CONSTRAINT "PK_936ce123a00db7afb5d615826c7" PRIMARY KEY ("workspaceId", "userAccountId");


--
-- TOC entry 5030 (class 2606 OID 30036)
-- Name: card PK_9451069b6f1199730791a7f4ae4; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card
    ADD CONSTRAINT "PK_9451069b6f1199730791a7f4ae4" PRIMARY KEY (id);


--
-- TOC entry 5039 (class 2606 OID 30038)
-- Name: card_comment PK_a2e3a49c7dbd33e9ff1eb9812d5; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_comment
    ADD CONSTRAINT "PK_a2e3a49c7dbd33e9ff1eb9812d5" PRIMARY KEY (id);


--
-- TOC entry 5101 (class 2606 OID 30040)
-- Name: letter_campaign PK_a3233c71e8f44e3aad8638b7c8b; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letter_campaign
    ADD CONSTRAINT "PK_a3233c71e8f44e3aad8638b7c8b" PRIMARY KEY (id);


--
-- TOC entry 5143 (class 2606 OID 30042)
-- Name: project_column PK_a382f575d27f4eb89768c993186; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_column
    ADD CONSTRAINT "PK_a382f575d27f4eb89768c993186" PRIMARY KEY (id);


--
-- TOC entry 5064 (class 2606 OID 30044)
-- Name: dxf_quote PK_ba5eba5b1a6c6c1462400f7d415; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dxf_quote
    ADD CONSTRAINT "PK_ba5eba5b1a6c6c1462400f7d415" PRIMARY KEY (id);


--
-- TOC entry 5182 (class 2606 OID 30046)
-- Name: title_report PK_bde0ccfbd5939d0c02c51958ead; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.title_report
    ADD CONSTRAINT "PK_bde0ccfbd5939d0c02c51958ead" PRIMARY KEY (id);


--
-- TOC entry 5086 (class 2606 OID 30048)
-- Name: land_registry_document PK_beabbffebad9dcd1a333bd5e0f1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_registry_document
    ADD CONSTRAINT "PK_beabbffebad9dcd1a333bd5e0f1" PRIMARY KEY (id);


--
-- TOC entry 5125 (class 2606 OID 30050)
-- Name: planning_alert PK_c44f18e6c2826ab228a4e3a6c5a; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_alert
    ADD CONSTRAINT "PK_c44f18e6c2826ab228a4e3a6c5a" PRIMARY KEY (id);


--
-- TOC entry 5204 (class 2606 OID 30052)
-- Name: workspace PK_ca86b6f9b3be5fe26d307d09b49; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace
    ADD CONSTRAINT "PK_ca86b6f9b3be5fe26d307d09b49" PRIMARY KEY (id);


--
-- TOC entry 5193 (class 2606 OID 30054)
-- Name: user_account PK_cace4a159ff9f2512dd42373760; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT "PK_cace4a159ff9f2512dd42373760" PRIMARY KEY (id);


--
-- TOC entry 5147 (class 2606 OID 30056)
-- Name: project_members_user_account PK_cff1edc8e802bcffa47cc94e40b; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_members_user_account
    ADD CONSTRAINT "PK_cff1edc8e802bcffa47cc94e40b" PRIMARY KEY ("projectId", "userAccountId");


--
-- TOC entry 5035 (class 2606 OID 30058)
-- Name: card_card_labels_card_label PK_d1767b1e690c607f5c0806c22d2; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_card_labels_card_label
    ADD CONSTRAINT "PK_d1767b1e690c607f5c0806c22d2" PRIMARY KEY ("cardId", "cardLabelId");


--
-- TOC entry 5048 (class 2606 OID 30060)
-- Name: card_land_assemblies_land_assembly PK_d6b3f297e3b4a811ae21030a508; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_land_assemblies_land_assembly
    ADD CONSTRAINT "PK_d6b3f297e3b4a811ae21030a508" PRIMARY KEY ("cardId", "landAssemblyId");


--
-- TOC entry 5044 (class 2606 OID 30062)
-- Name: card_label PK_e68bcd0c8c063244533eaee92a3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_label
    ADD CONSTRAINT "PK_e68bcd0c8c063244533eaee92a3" PRIMARY KEY (id);


--
-- TOC entry 5174 (class 2606 OID 30064)
-- Name: session PK_f55da76ac1c3ac420f444d2ff11; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT "PK_f55da76ac1c3ac420f444d2ff11" PRIMARY KEY (id);


--
-- TOC entry 5176 (class 2606 OID 30066)
-- Name: team PK_f57d8293406df4af348402e4b74; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT "PK_f57d8293406df4af348402e4b74" PRIMARY KEY (id);


--
-- TOC entry 5134 (class 2606 OID 30068)
-- Name: platform_notification PK_fa4784f0bacccf35539a9ef688e; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_notification
    ADD CONSTRAINT "PK_fa4784f0bacccf35539a9ef688e" PRIMARY KEY (id);


--
-- TOC entry 5070 (class 2606 OID 30070)
-- Name: invite PK_fc9fa190e5a3c5d80604a4f63e1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite
    ADD CONSTRAINT "PK_fc9fa190e5a3c5d80604a4f63e1" PRIMARY KEY (id);


--
-- TOC entry 5072 (class 2606 OID 30072)
-- Name: invite REL_91bfeec7a9574f458e5b592472; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite
    ADD CONSTRAINT "REL_91bfeec7a9574f458e5b592472" UNIQUE ("userId");


--
-- TOC entry 5066 (class 2606 OID 30074)
-- Name: dxf_quote REL_cd4a72f8c442531a48f8641000; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dxf_quote
    ADD CONSTRAINT "REL_cd4a72f8c442531a48f8641000" UNIQUE ("userId");


--
-- TOC entry 5088 (class 2606 OID 30076)
-- Name: land_registry_document UQ_5b6b5e191df649c232b0d5489de; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_registry_document
    ADD CONSTRAINT "UQ_5b6b5e191df649c232b0d5489de" UNIQUE (reference);


--
-- TOC entry 5074 (class 2606 OID 30078)
-- Name: invite UQ_658d8246180c0345d32a100544e; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite
    ADD CONSTRAINT "UQ_658d8246180c0345d32a100544e" UNIQUE (email);


--
-- TOC entry 5195 (class 2606 OID 30080)
-- Name: user_account UQ_c0526dab5e00354769a90938f2c; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT "UQ_c0526dab5e00354769a90938f2c" UNIQUE ("perishibleToken");


--
-- TOC entry 5197 (class 2606 OID 30082)
-- Name: user_account UQ_e12875dfb3b1d92d7d7c5377e22; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT "UQ_e12875dfb3b1d92d7d7c5377e22" UNIQUE (email);


--
-- TOC entry 4960 (class 2606 OID 16548)
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- TOC entry 4966 (class 2606 OID 16589)
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- TOC entry 4968 (class 2606 OID 16587)
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4964 (class 2606 OID 16565)
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- TOC entry 5214 (class 2606 OID 247318)
-- Name: hooks hooks_pkey; Type: CONSTRAINT; Schema: supabase_functions; Owner: -
--

ALTER TABLE ONLY supabase_functions.hooks
    ADD CONSTRAINT hooks_pkey PRIMARY KEY (id);


--
-- TOC entry 5212 (class 2606 OID 247308)
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: supabase_functions; Owner: -
--

ALTER TABLE ONLY supabase_functions.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 5210 (class 2606 OID 247237)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: supabase_migrations; Owner: -
--

ALTER TABLE ONLY supabase_migrations.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 4955 (class 1259 OID 16526)
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- TOC entry 4930 (class 1259 OID 28335)
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- TOC entry 4931 (class 1259 OID 28337)
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- TOC entry 4932 (class 1259 OID 28338)
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- TOC entry 4988 (class 1259 OID 28417)
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- TOC entry 5016 (class 1259 OID 276791)
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- TOC entry 4979 (class 1259 OID 28505)
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- TOC entry 5563 (class 0 OID 0)
-- Dependencies: 4979
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- TOC entry 4982 (class 1259 OID 28332)
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- TOC entry 5019 (class 1259 OID 28522)
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- TOC entry 4992 (class 1259 OID 282177)
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- TOC entry 4991 (class 1259 OID 28389)
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- TOC entry 4933 (class 1259 OID 28339)
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- TOC entry 4934 (class 1259 OID 28336)
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- TOC entry 4942 (class 1259 OID 16509)
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- TOC entry 4943 (class 1259 OID 16510)
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- TOC entry 4944 (class 1259 OID 28331)
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- TOC entry 4947 (class 1259 OID 28419)
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- TOC entry 4950 (class 1259 OID 276790)
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- TOC entry 5010 (class 1259 OID 28461)
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- TOC entry 5011 (class 1259 OID 276792)
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- TOC entry 5012 (class 1259 OID 28476)
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- TOC entry 5015 (class 1259 OID 28475)
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- TOC entry 4983 (class 1259 OID 276793)
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- TOC entry 4986 (class 1259 OID 28418)
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- TOC entry 5002 (class 1259 OID 28443)
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- TOC entry 5005 (class 1259 OID 28442)
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- TOC entry 5001 (class 1259 OID 28428)
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- TOC entry 4987 (class 1259 OID 28416)
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- TOC entry 4935 (class 1259 OID 28496)
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- TOC entry 5564 (class 0 OID 0)
-- Dependencies: 4935
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- TOC entry 4936 (class 1259 OID 28333)
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- TOC entry 4937 (class 1259 OID 16499)
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- TOC entry 5022 (class 1259 OID 30085)
-- Name: IDX_01043dd6cb952919853187c2d3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_01043dd6cb952919853187c2d3" ON public.card USING btree ("importId");


--
-- TOC entry 5112 (class 1259 OID 30086)
-- Name: IDX_02a2a2b9174392dbf84ce7bfdf; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_02a2a2b9174392dbf84ce7bfdf" ON public.letter_template USING btree ("createdAt");


--
-- TOC entry 5161 (class 1259 OID 30087)
-- Name: IDX_0362c4b4c5b1c44a55a1aedeb8; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_0362c4b4c5b1c44a55a1aedeb8" ON public.saved_title USING btree ("titleNo", "teamId");


--
-- TOC entry 5108 (class 1259 OID 30088)
-- Name: IDX_07204a5db20a0af5d689b9ee6f; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_07204a5db20a0af5d689b9ee6f" ON public.letter_credit_ledger USING btree ("createdAt");


--
-- TOC entry 5154 (class 1259 OID 30089)
-- Name: IDX_09130460aa3f539c934d052faa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_09130460aa3f539c934d052faa" ON public.saved_query USING btree (tool);


--
-- TOC entry 5130 (class 1259 OID 30090)
-- Name: IDX_0a7078817c00ebb5ea377105f8; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_0a7078817c00ebb5ea377105f8" ON public.platform_notification USING btree ("createdAt");


--
-- TOC entry 5118 (class 1259 OID 30091)
-- Name: IDX_0c8923d878e47d4e38a257ac97; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_0c8923d878e47d4e38a257ac97" ON public.planning_alert USING btree ("trackPlanningApplicationId", "userId");


--
-- TOC entry 5094 (class 1259 OID 30092)
-- Name: IDX_0e753557db7ebf8654ffab9971; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_0e753557db7ebf8654ffab9971" ON public.land_registry_proprietor_address USING btree ("createdAt");


--
-- TOC entry 5171 (class 1259 OID 30093)
-- Name: IDX_1063954fd0fa5e655cc482fb5c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_1063954fd0fa5e655cc482fb5c" ON public.session USING btree ("createdAt");


--
-- TOC entry 5067 (class 1259 OID 30094)
-- Name: IDX_140fce9f655f2a2fcffb407efd; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_140fce9f655f2a2fcffb407efd" ON public.invite USING btree ("createdAt");


--
-- TOC entry 5183 (class 1259 OID 30095)
-- Name: IDX_1535261f35234c1d92f90c26b9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_1535261f35234c1d92f90c26b9" ON public.usage_event USING btree ("teamId");


--
-- TOC entry 5032 (class 1259 OID 30097)
-- Name: IDX_1f6705247d1b43e94cb83d8faf; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_1f6705247d1b43e94cb83d8faf" ON public.card_card_labels_card_label USING btree ("cardId");


--
-- TOC entry 5040 (class 1259 OID 30098)
-- Name: IDX_21817aea5b97f78656061f8a7e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_21817aea5b97f78656061f8a7e" ON public.card_label USING btree ("createdAt");


--
-- TOC entry 5082 (class 1259 OID 30099)
-- Name: IDX_22dc971bb0e1b7296f11fdbfd7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_22dc971bb0e1b7296f11fdbfd7" ON public.land_registry_document USING btree ("createdAt");


--
-- TOC entry 5184 (class 1259 OID 30100)
-- Name: IDX_24e1c08abdd00da02b64ade0cc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_24e1c08abdd00da02b64ade0cc" ON public.usage_event USING btree ("eventName");


--
-- TOC entry 5155 (class 1259 OID 30101)
-- Name: IDX_2e472888a5642825218d691e1c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_2e472888a5642825218d691e1c" ON public.saved_query USING btree ("createdAt");


--
-- TOC entry 5102 (class 1259 OID 30102)
-- Name: IDX_30f3dd210fb2c23bf67fd6b452; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_30f3dd210fb2c23bf67fd6b452" ON public.letter_campaign_address USING btree ("createdAt");


--
-- TOC entry 5185 (class 1259 OID 30103)
-- Name: IDX_326ce6cb8e3f4e5345025a5ef4; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_326ce6cb8e3f4e5345025a5ef4" ON public.usage_event USING btree ("updatedAt");


--
-- TOC entry 5113 (class 1259 OID 30104)
-- Name: IDX_3595fafecd4c78cabf0b7ba2a2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_3595fafecd4c78cabf0b7ba2a2" ON public.letter_template USING btree ("updatedAt");


--
-- TOC entry 5198 (class 1259 OID 30105)
-- Name: IDX_3ad731868f52d5f82de2c4c6ce; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_3ad731868f52d5f82de2c4c6ce" ON public.workspace USING btree ("createdAt");


--
-- TOC entry 5068 (class 1259 OID 30106)
-- Name: IDX_3db8e1f7d6545afac83a6aa156; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_3db8e1f7d6545afac83a6aa156" ON public.invite USING btree ("updatedAt");


--
-- TOC entry 5036 (class 1259 OID 30107)
-- Name: IDX_3db9c889cb48faf18514d42c34; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_3db9c889cb48faf18514d42c34" ON public.card_comment USING btree ("createdAt");


--
-- TOC entry 5217 (class 1259 OID 271164)
-- Name: IDX_3ed0382eddec03186824c80893; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_3ed0382eddec03186824c80893" ON public.land_assembly_saved_titles_saved_title USING btree ("landAssemblyId");


--
-- TOC entry 5139 (class 1259 OID 30108)
-- Name: IDX_43ff0d267f218f3d041b87f100; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_43ff0d267f218f3d041b87f100" ON public.project_column USING btree ("createdAt");


--
-- TOC entry 5172 (class 1259 OID 30109)
-- Name: IDX_4b1511ab37f27d6f11242b81c9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_4b1511ab37f27d6f11242b81c9" ON public.session USING btree ("updatedAt");


--
-- TOC entry 5199 (class 1259 OID 30110)
-- Name: IDX_4d1eceef7e5f8e70fe3ead745d; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_4d1eceef7e5f8e70fe3ead745d" ON public.workspace USING btree ("teamId");


--
-- TOC entry 5083 (class 1259 OID 30111)
-- Name: IDX_4f6cc27b84bca7b7eb47a3b65e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_4f6cc27b84bca7b7eb47a3b65e" ON public.land_registry_document USING btree ("updatedAt");


--
-- TOC entry 5061 (class 1259 OID 30112)
-- Name: IDX_5079672ad0a1b4c7246425fd08; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_5079672ad0a1b4c7246425fd08" ON public.dxf_quote USING btree ("updatedAt");


--
-- TOC entry 5103 (class 1259 OID 30113)
-- Name: IDX_50e6d25affa12b1195a2c4672a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_50e6d25affa12b1195a2c4672a" ON public.letter_campaign_address USING btree ("updatedAt");


--
-- TOC entry 5163 (class 1259 OID 30114)
-- Name: IDX_52af02e3080c8dd6cd695f3946; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_52af02e3080c8dd6cd695f3946" ON public.saved_title USING btree ("titleNo");


--
-- TOC entry 5084 (class 1259 OID 281118)
-- Name: IDX_52b565b7c409f2d1b6ed06ece3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_52b565b7c409f2d1b6ed06ece3" ON public.land_registry_document USING btree ("bulkTitlePurchaseId");


--
-- TOC entry 5119 (class 1259 OID 30115)
-- Name: IDX_536289a4342afbac039a1e70b7; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_536289a4342afbac039a1e70b7" ON public.planning_alert USING btree (query, "userId");


--
-- TOC entry 5098 (class 1259 OID 30116)
-- Name: IDX_553ecef4dda320282aeeac2d39; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_553ecef4dda320282aeeac2d39" ON public.letter_campaign USING btree ("createdAt");


--
-- TOC entry 5221 (class 1259 OID 281116)
-- Name: IDX_55df2b32ad427102c8cc8fea75; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_55df2b32ad427102c8cc8fea75" ON public.bulk_title_purchase USING btree ("updatedAt");


--
-- TOC entry 5023 (class 1259 OID 270174)
-- Name: IDX_592a123bd8f9add5004b2aae1f; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_592a123bd8f9add5004b2aae1f" ON public.card USING btree ("columnId");


--
-- TOC entry 5090 (class 1259 OID 30117)
-- Name: IDX_5a6e7e302db17d1683b1aa7a2f; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_5a6e7e302db17d1683b1aa7a2f" ON public.land_registry_proprietor USING btree ("createdAt");


--
-- TOC entry 5177 (class 1259 OID 30118)
-- Name: IDX_5b83143309b460d9e9690b9e69; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_5b83143309b460d9e9690b9e69" ON public.title_credit_ledger USING btree ("createdAt");


--
-- TOC entry 5045 (class 1259 OID 30119)
-- Name: IDX_5c5a8664fad5b5119ea7d69684; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_5c5a8664fad5b5119ea7d69684" ON public.card_land_assemblies_land_assembly USING btree ("cardId");


--
-- TOC entry 5033 (class 1259 OID 30120)
-- Name: IDX_62d8f0f45aa9dd84bc29c73769; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_62d8f0f45aa9dd84bc29c73769" ON public.card_card_labels_card_label USING btree ("cardLabelId");


--
-- TOC entry 5156 (class 1259 OID 30121)
-- Name: IDX_6a8361b27aba412e1ad6500764; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_6a8361b27aba412e1ad6500764" ON public.saved_query USING btree ("updatedAt");


--
-- TOC entry 5157 (class 1259 OID 30122)
-- Name: IDX_6d1c7c486816bc9b3ec2e1228e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_6d1c7c486816bc9b3ec2e1228e" ON public.saved_query USING btree ("archivedAt");


--
-- TOC entry 5131 (class 1259 OID 30123)
-- Name: IDX_6dcdcd66f845d01f6888f46bed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_6dcdcd66f845d01f6888f46bed" ON public.platform_notification USING btree ("updatedAt");


--
-- TOC entry 5222 (class 1259 OID 281115)
-- Name: IDX_7532984ee0f9b0a58af012762b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_7532984ee0f9b0a58af012762b" ON public.bulk_title_purchase USING btree ("createdAt");


--
-- TOC entry 5158 (class 1259 OID 30124)
-- Name: IDX_76dbb56b2c86fae3ebefd792aa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_76dbb56b2c86fae3ebefd792aa" ON public.saved_query USING btree ("sourceId");


--
-- TOC entry 5126 (class 1259 OID 30125)
-- Name: IDX_7c841ba3e0fd21f84d706f5705; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_7c841ba3e0fd21f84d706f5705" ON public.planning_alert_users_to_alert_user_account USING btree ("planningAlertId");


--
-- TOC entry 5140 (class 1259 OID 30126)
-- Name: IDX_8c968a01504354a7b7624a753b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_8c968a01504354a7b7624a753b" ON public.project_column USING btree ("updatedAt");


--
-- TOC entry 5120 (class 1259 OID 30127)
-- Name: IDX_8ca15edcda9d5f742c15bf6cee; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_8ca15edcda9d5f742c15bf6cee" ON public.planning_alert USING btree ("updatedAt");


--
-- TOC entry 5178 (class 1259 OID 30128)
-- Name: IDX_90c8416eb9224a3c6a25e690ad; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_90c8416eb9224a3c6a25e690ad" ON public.title_credit_ledger USING btree ("updatedAt");


--
-- TOC entry 5062 (class 1259 OID 30129)
-- Name: IDX_958af2329b75d34ac22ffade3b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_958af2329b75d34ac22ffade3b" ON public.dxf_quote USING btree ("createdAt");


--
-- TOC entry 5053 (class 1259 OID 30130)
-- Name: IDX_9a8418c2b4ea84551aee989d07; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_9a8418c2b4ea84551aee989d07" ON public.card_title_attachments_saved_title USING btree ("cardId");


--
-- TOC entry 5054 (class 1259 OID 30131)
-- Name: IDX_9b35f37638b90561a9ecad97c1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_9b35f37638b90561a9ecad97c1" ON public.card_title_attachments_saved_title USING btree ("savedTitleId");


--
-- TOC entry 5205 (class 1259 OID 30132)
-- Name: IDX_9b486a3a11a586fd68312d8e81; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_9b486a3a11a586fd68312d8e81" ON public.workspace_users_that_favourited_user_account USING btree ("workspaceId");


--
-- TOC entry 5121 (class 1259 OID 30133)
-- Name: IDX_9df1c6b364e22c96581eee251a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_9df1c6b364e22c96581eee251a" ON public.planning_alert USING btree ("createdAt");


--
-- TOC entry 5135 (class 1259 OID 30134)
-- Name: IDX_a8c9319b1f0d38e955f9c0620d; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_a8c9319b1f0d38e955f9c0620d" ON public.project USING btree ("createdAt");


--
-- TOC entry 5024 (class 1259 OID 30135)
-- Name: IDX_ab2f2a3e40c61d6317484bd1dd; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_ab2f2a3e40c61d6317484bd1dd" ON public.card USING btree (pos);


--
-- TOC entry 5190 (class 1259 OID 30136)
-- Name: IDX_afe5b3add7d92d56500b9a6647; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_afe5b3add7d92d56500b9a6647" ON public.user_account USING btree ("createdAt");


--
-- TOC entry 5049 (class 1259 OID 30137)
-- Name: IDX_b172b5c39f2c01b8e1a5c564cd; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_b172b5c39f2c01b8e1a5c564cd" ON public.card_members_user_account USING btree ("userAccountId");


--
-- TOC entry 5025 (class 1259 OID 30138)
-- Name: IDX_b2259e7cd16390d854b55b8fbd; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_b2259e7cd16390d854b55b8fbd" ON public.card USING btree ("updatedAt");


--
-- TOC entry 5200 (class 1259 OID 30139)
-- Name: IDX_b48532fc84800d41cfee110682; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_b48532fc84800d41cfee110682" ON public.workspace USING btree ("userId");


--
-- TOC entry 5075 (class 1259 OID 30140)
-- Name: IDX_b8856fa6c7f6cc17549c3733bc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_b8856fa6c7f6cc17549c3733bc" ON public.land_assembly USING btree ("createdAt");


--
-- TOC entry 5206 (class 1259 OID 30141)
-- Name: IDX_bc2b516d3e1c218907962630f4; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_bc2b516d3e1c218907962630f4" ON public.workspace_users_that_favourited_user_account USING btree ("userAccountId");


--
-- TOC entry 5144 (class 1259 OID 30142)
-- Name: IDX_c04d6b13761d6a6f672873e86e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_c04d6b13761d6a6f672873e86e" ON public.project_members_user_account USING btree ("projectId");


--
-- TOC entry 5076 (class 1259 OID 30143)
-- Name: IDX_c469b862d3bf5237f5ce594e63; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_c469b862d3bf5237f5ce594e63" ON public.land_assembly USING btree ("updatedAt");


--
-- TOC entry 5132 (class 1259 OID 30144)
-- Name: IDX_c46a266c08fef59e9970662d74; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_c46a266c08fef59e9970662d74" ON public.platform_notification USING btree (type);


--
-- TOC entry 5136 (class 1259 OID 30145)
-- Name: IDX_c514f5e5ebee230f957a440980; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_c514f5e5ebee230f957a440980" ON public.project USING btree ("updatedAt");


--
-- TOC entry 5141 (class 1259 OID 30146)
-- Name: IDX_c5d04e0e967ff1d4a5deb937e0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_c5d04e0e967ff1d4a5deb937e0" ON public.project_column USING btree ("projectId");


--
-- TOC entry 5077 (class 1259 OID 30147)
-- Name: IDX_c8aa894f6bc178b5974af8a128; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_c8aa894f6bc178b5974af8a128" ON public.land_assembly USING btree ("areaSize");


--
-- TOC entry 5057 (class 1259 OID 30148)
-- Name: IDX_caa012e754ef592d557048aa5c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_caa012e754ef592d557048aa5c" ON public.dxf_export USING btree ("updatedAt");


--
-- TOC entry 5122 (class 1259 OID 30149)
-- Name: IDX_cab40eea7ca5209c4f0f8edfe1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_cab40eea7ca5209c4f0f8edfe1" ON public.planning_alert USING btree (type);


--
-- TOC entry 5127 (class 1259 OID 30150)
-- Name: IDX_cb419ca83d6d196142f23225ce; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_cb419ca83d6d196142f23225ce" ON public.planning_alert_users_to_alert_user_account USING btree ("userAccountId");


--
-- TOC entry 5058 (class 1259 OID 30152)
-- Name: IDX_cb7bf2e493c4f92549049e1bd1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_cb7bf2e493c4f92549049e1bd1" ON public.dxf_export USING btree ("createdAt");


--
-- TOC entry 5164 (class 1259 OID 30153)
-- Name: IDX_ccc869c297eb88fa4e21a4629e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_ccc869c297eb88fa4e21a4629e" ON public.saved_title USING btree ("areaSize");


--
-- TOC entry 5041 (class 1259 OID 30154)
-- Name: IDX_cd3282507fb08e25ad1259a50b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_cd3282507fb08e25ad1259a50b" ON public.card_label USING btree ("importId");


--
-- TOC entry 5050 (class 1259 OID 30155)
-- Name: IDX_d0f903afb06fd7771aa411e3eb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_d0f903afb06fd7771aa411e3eb" ON public.card_members_user_account USING btree ("cardId");


--
-- TOC entry 5095 (class 1259 OID 30156)
-- Name: IDX_d4856742d0a5ca1d1fa3a346c7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_d4856742d0a5ca1d1fa3a346c7" ON public.land_registry_proprietor_address USING btree ("updatedAt");


--
-- TOC entry 5148 (class 1259 OID 30157)
-- Name: IDX_d6576cf9b83930ee8b30acb230; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_d6576cf9b83930ee8b30acb230" ON public.project_title_attachments_saved_title USING btree ("projectId");


--
-- TOC entry 5046 (class 1259 OID 30158)
-- Name: IDX_d714baadde9b4ef46fc06e49cb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_d714baadde9b4ef46fc06e49cb" ON public.card_land_assemblies_land_assembly USING btree ("landAssemblyId");


--
-- TOC entry 5149 (class 1259 OID 30159)
-- Name: IDX_d850f50ca61527f06d73154946; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_d850f50ca61527f06d73154946" ON public.project_title_attachments_saved_title USING btree ("savedTitleId");


--
-- TOC entry 5026 (class 1259 OID 30160)
-- Name: IDX_d892e28bd0f7031289731bfca6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_d892e28bd0f7031289731bfca6" ON public.card USING btree ("archivedAt");


--
-- TOC entry 5091 (class 1259 OID 30161)
-- Name: IDX_d94eb8b5ef65865bd6fbe2674b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_d94eb8b5ef65865bd6fbe2674b" ON public.land_registry_proprietor USING btree ("updatedAt");


--
-- TOC entry 5099 (class 1259 OID 30162)
-- Name: IDX_d962aaf732275362fb1624055c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_d962aaf732275362fb1624055c" ON public.letter_campaign USING btree ("updatedAt");


--
-- TOC entry 5218 (class 1259 OID 271165)
-- Name: IDX_da3baf5ab72779f3f95a121a72; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_da3baf5ab72779f3f95a121a72" ON public.land_assembly_saved_titles_saved_title USING btree ("savedTitleId");


--
-- TOC entry 5123 (class 1259 OID 30163)
-- Name: IDX_daa7ccf3c0bb19b7773d73f76b; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_daa7ccf3c0bb19b7773d73f76b" ON public.planning_alert USING btree ("savedTitleId", "userId");


--
-- TOC entry 5109 (class 1259 OID 30164)
-- Name: IDX_db2b4d02274c11c7ba69fd0ae1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_db2b4d02274c11c7ba69fd0ae1" ON public.letter_credit_ledger USING btree ("updatedAt");


--
-- TOC entry 5027 (class 1259 OID 30165)
-- Name: IDX_dbc3424b136bfbe9fc92d9d949; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_dbc3424b136bfbe9fc92d9d949" ON public.card USING btree ("createdAt");


--
-- TOC entry 5201 (class 1259 OID 30166)
-- Name: IDX_dd1fa3525383a0592e5d4a48b9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_dd1fa3525383a0592e5d4a48b9" ON public.workspace USING btree ("archivedAt");


--
-- TOC entry 5042 (class 1259 OID 30167)
-- Name: IDX_dd41798e7b4c8cea0e7aa3bd86; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_dd41798e7b4c8cea0e7aa3bd86" ON public.card_label USING btree ("updatedAt");


--
-- TOC entry 5079 (class 1259 OID 30168)
-- Name: IDX_df5860544cbeb980c38b906d86; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_df5860544cbeb980c38b906d86" ON public.land_assembly USING btree (perimeter);


--
-- TOC entry 5165 (class 1259 OID 30169)
-- Name: IDX_df9befc0fd79466ee242bd7a03; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_df9befc0fd79466ee242bd7a03" ON public.saved_title USING btree ("createdAt");


--
-- TOC entry 5028 (class 1259 OID 281119)
-- Name: IDX_e28821253d400cf3f471e2d017; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_e28821253d400cf3f471e2d017" ON public.card USING btree ("lastColumnUpdatedAt");


--
-- TOC entry 5166 (class 1259 OID 30170)
-- Name: IDX_e45f50d5abcc3274cac2dbe8c9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_e45f50d5abcc3274cac2dbe8c9" ON public.saved_title USING btree (custom);


--
-- TOC entry 5191 (class 1259 OID 30171)
-- Name: IDX_ea530b650b30137c95d6f32556; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_ea530b650b30137c95d6f32556" ON public.user_account USING btree ("updatedAt");


--
-- TOC entry 5104 (class 1259 OID 30172)
-- Name: IDX_ee512121303511ddd5bd5e26d6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_ee512121303511ddd5bd5e26d6" ON public.letter_campaign_address USING btree ("importId");


--
-- TOC entry 5145 (class 1259 OID 30173)
-- Name: IDX_f2fe072adee61a1693cd77765c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_f2fe072adee61a1693cd77765c" ON public.project_members_user_account USING btree ("userAccountId");


--
-- TOC entry 5186 (class 1259 OID 30174)
-- Name: IDX_f4f9f91fd3b947d7f27e12165b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_f4f9f91fd3b947d7f27e12165b" ON public.usage_event USING btree ("createdAt");


--
-- TOC entry 5105 (class 1259 OID 30175)
-- Name: IDX_f8fff0a60cc36b8d08d457f054; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_f8fff0a60cc36b8d08d457f054" ON public.letter_campaign_address USING btree (address, "letterCampaignId");


--
-- TOC entry 5037 (class 1259 OID 30176)
-- Name: IDX_f993a1c50d0593834b27c8f0eb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_f993a1c50d0593834b27c8f0eb" ON public.card_comment USING btree ("updatedAt");


--
-- TOC entry 5167 (class 1259 OID 281256)
-- Name: IDX_fc1163ef1829953859c93b44e4; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_fc1163ef1829953859c93b44e4" ON public.saved_title USING btree ("isScotland");


--
-- TOC entry 5187 (class 1259 OID 30177)
-- Name: IDX_fc796f06e64cb61c9fd4edfb5c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_fc796f06e64cb61c9fd4edfb5c" ON public.usage_event USING btree (identifier);


--
-- TOC entry 5202 (class 1259 OID 30178)
-- Name: IDX_ff62098584e18b8284c70b06b1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_ff62098584e18b8284c70b06b1" ON public.workspace USING btree ("updatedAt");


--
-- TOC entry 5168 (class 1259 OID 30179)
-- Name: IDX_ff75104c4a9ab8c07babfcae73; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_ff75104c4a9ab8c07babfcae73" ON public.saved_title USING btree ("updatedAt");

--
-- TOC entry 5089 (class 1259 OID 30181)
-- Name: type_savedTitle_unique_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "type_savedTitle_unique_index" ON public.land_registry_document USING btree ("savedTitleId", "documentType");


--
-- TOC entry 4958 (class 1259 OID 16554)
-- Name: bname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- TOC entry 4961 (class 1259 OID 16576)
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- TOC entry 4962 (class 1259 OID 16577)
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- TOC entry 5215 (class 1259 OID 247320)
-- Name: supabase_functions_hooks_h_table_id_h_name_idx; Type: INDEX; Schema: supabase_functions; Owner: -
--

CREATE INDEX supabase_functions_hooks_h_table_id_h_name_idx ON supabase_functions.hooks USING btree (hook_table_id, hook_name);


--
-- TOC entry 5216 (class 1259 OID 247319)
-- Name: supabase_functions_hooks_request_id_idx; Type: INDEX; Schema: supabase_functions; Owner: -
--

CREATE INDEX supabase_functions_hooks_request_id_idx ON supabase_functions.hooks USING btree (request_id);


--
-- TOC entry 5304 (class 2620 OID 138756)
-- Name: user_account create_user_for_user_account; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_user_for_user_account BEFORE INSERT ON public.user_account FOR EACH ROW EXECUTE FUNCTION public.create_auth_user_from_user_id();


--
-- TOC entry 5303 (class 2620 OID 28537)
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- TOC entry 5229 (class 2606 OID 28319)
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- TOC entry 5233 (class 2606 OID 28409)
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- TOC entry 5232 (class 2606 OID 28397)
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- TOC entry 5231 (class 2606 OID 28384)
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- TOC entry 5225 (class 2606 OID 28352)
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- TOC entry 5235 (class 2606 OID 28456)
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- TOC entry 5236 (class 2606 OID 28470)
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- TOC entry 5230 (class 2606 OID 28347)
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- TOC entry 5234 (class 2606 OID 28437)
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- TOC entry 5241 (class 2606 OID 30182)
-- Name: card_comment FK_129f68fc251b98adb377f02f5b4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_comment
    ADD CONSTRAINT "FK_129f68fc251b98adb377f02f5b4" FOREIGN KEY ("userId") REFERENCES public.user_account(id);


--
-- TOC entry 5293 (class 2606 OID 30187)
-- Name: usage_event FK_1535261f35234c1d92f90c26b97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usage_event
    ADD CONSTRAINT "FK_1535261f35234c1d92f90c26b97" FOREIGN KEY ("teamId") REFERENCES public.team(id);


--
-- TOC entry 5258 (class 2606 OID 30192)
-- Name: land_registry_document FK_190f6bce2c98391506ac5cb1fb4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_registry_document
    ADD CONSTRAINT "FK_190f6bce2c98391506ac5cb1fb4" FOREIGN KEY ("savedTitleId") REFERENCES public.saved_title(id);


--
-- TOC entry 5256 (class 2606 OID 30197)
-- Name: land_assembly FK_192842077d0adc54ffec5f42096; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_assembly
    ADD CONSTRAINT "FK_192842077d0adc54ffec5f42096" FOREIGN KEY ("userId") REFERENCES public.user_account(id);


--
-- TOC entry 5257 (class 2606 OID 30202)
-- Name: land_assembly FK_1e64bcb9a2ea9265b67ec439c85; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_assembly
    ADD CONSTRAINT "FK_1e64bcb9a2ea9265b67ec439c85" FOREIGN KEY ("teamId") REFERENCES public.team(id);


--
-- TOC entry 5259 (class 2606 OID 30207)
-- Name: land_registry_document FK_1f52618f2dcc734463307f05b78; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_registry_document
    ADD CONSTRAINT "FK_1f52618f2dcc734463307f05b78" FOREIGN KEY ("createdById") REFERENCES public.user_account(id);


--
-- TOC entry 5239 (class 2606 OID 30212)
-- Name: card_card_labels_card_label FK_1f6705247d1b43e94cb83d8faf7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_card_labels_card_label
    ADD CONSTRAINT "FK_1f6705247d1b43e94cb83d8faf7" FOREIGN KEY ("cardId") REFERENCES public.card(id) ON DELETE CASCADE;


--
-- TOC entry 5243 (class 2606 OID 30217)
-- Name: card_label FK_28694638e4e1f77f7cfd84e4123; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_label
    ADD CONSTRAINT "FK_28694638e4e1f77f7cfd84e4123" FOREIGN KEY ("creatorId") REFERENCES public.user_account(id);


--
-- TOC entry 5287 (class 2606 OID 30222)
-- Name: session FK_3d2f174ef04fb312fdebd0ddc53; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT "FK_3d2f174ef04fb312fdebd0ddc53" FOREIGN KEY ("userId") REFERENCES public.user_account(id);


--
-- TOC entry 5299 (class 2606 OID 271166)
-- Name: land_assembly_saved_titles_saved_title FK_3ed0382eddec03186824c808934; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_assembly_saved_titles_saved_title
    ADD CONSTRAINT "FK_3ed0382eddec03186824c808934" FOREIGN KEY ("landAssemblyId") REFERENCES public.land_assembly(id) ON DELETE CASCADE;


--
-- TOC entry 5283 (class 2606 OID 30227)
-- Name: saved_area FK_433a0e5169893c77fe1a1a71f52; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_area
    ADD CONSTRAINT "FK_433a0e5169893c77fe1a1a71f52" FOREIGN KEY ("userId") REFERENCES public.user_account(id);


--
-- TOC entry 5295 (class 2606 OID 30232)
-- Name: workspace FK_4d1eceef7e5f8e70fe3ead745d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace
    ADD CONSTRAINT "FK_4d1eceef7e5f8e70fe3ead745d9" FOREIGN KEY ("teamId") REFERENCES public.team(id);


--
-- TOC entry 5260 (class 2606 OID 281120)
-- Name: land_registry_document FK_52b565b7c409f2d1b6ed06ece3f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_registry_document
    ADD CONSTRAINT "FK_52b565b7c409f2d1b6ed06ece3f" FOREIGN KEY ("bulkTitlePurchaseId") REFERENCES public.bulk_title_purchase(id);


--
-- TOC entry 5301 (class 2606 OID 281130)
-- Name: bulk_title_purchase FK_54232b9c2a303603bfa9756a97c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bulk_title_purchase
    ADD CONSTRAINT "FK_54232b9c2a303603bfa9756a97c" FOREIGN KEY ("userId") REFERENCES public.user_account(id);


--
-- TOC entry 5237 (class 2606 OID 30237)
-- Name: card FK_592a123bd8f9add5004b2aae1fb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card
    ADD CONSTRAINT "FK_592a123bd8f9add5004b2aae1fb" FOREIGN KEY ("columnId") REFERENCES public.project_column(id) ON DELETE CASCADE;


--
-- TOC entry 5274 (class 2606 OID 30242)
-- Name: platform_notification FK_5b682beda9b58418eaeff2c9c22; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_notification
    ADD CONSTRAINT "FK_5b682beda9b58418eaeff2c9c22" FOREIGN KEY ("planningAlertId") REFERENCES public.planning_alert(id);


--
-- TOC entry 5245 (class 2606 OID 30247)
-- Name: card_land_assemblies_land_assembly FK_5c5a8664fad5b5119ea7d696846; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_land_assemblies_land_assembly
    ADD CONSTRAINT "FK_5c5a8664fad5b5119ea7d696846" FOREIGN KEY ("cardId") REFERENCES public.card(id) ON DELETE CASCADE;


--
-- TOC entry 5251 (class 2606 OID 30252)
-- Name: dxf_export FK_5e98f71f21ba57a451d12c9e1d8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dxf_export
    ADD CONSTRAINT "FK_5e98f71f21ba57a451d12c9e1d8" FOREIGN KEY ("ownerId") REFERENCES public.user_account(id);


--
-- TOC entry 5240 (class 2606 OID 30257)
-- Name: card_card_labels_card_label FK_62d8f0f45aa9dd84bc29c737692; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_card_labels_card_label
    ADD CONSTRAINT "FK_62d8f0f45aa9dd84bc29c737692" FOREIGN KEY ("cardLabelId") REFERENCES public.card_label(id) ON DELETE CASCADE;


--
-- TOC entry 5294 (class 2606 OID 30262)
-- Name: user_account FK_64d6646cbd28b24031cc4371ddc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT "FK_64d6646cbd28b24031cc4371ddc" FOREIGN KEY ("teamId") REFERENCES public.team(id);


--
-- TOC entry 5252 (class 2606 OID 30267)
-- Name: dxf_export FK_655d642cae5fe0be6252f36c183; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dxf_export
    ADD CONSTRAINT "FK_655d642cae5fe0be6252f36c183" FOREIGN KEY ("teamId") REFERENCES public.team(id);


--
-- TOC entry 5262 (class 2606 OID 30272)
-- Name: land_registry_proprietor_address FK_6d3d2c7f71aec1bf34a27862642; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_registry_proprietor_address
    ADD CONSTRAINT "FK_6d3d2c7f71aec1bf34a27862642" FOREIGN KEY ("proprietorId") REFERENCES public.land_registry_proprietor(id);


--
-- TOC entry 5263 (class 2606 OID 30277)
-- Name: letter_campaign FK_6d5c55ba1536a057f9e98dbddc6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letter_campaign
    ADD CONSTRAINT "FK_6d5c55ba1536a057f9e98dbddc6" FOREIGN KEY ("teamId") REFERENCES public.team(id);


--
-- TOC entry 5284 (class 2606 OID 30282)
-- Name: saved_query FK_74b2e985371496b6fa34e600b92; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_query
    ADD CONSTRAINT "FK_74b2e985371496b6fa34e600b92" FOREIGN KEY ("userId") REFERENCES public.user_account(id);


--
-- TOC entry 5272 (class 2606 OID 30287)
-- Name: planning_alert_users_to_alert_user_account FK_7c841ba3e0fd21f84d706f57055; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_alert_users_to_alert_user_account
    ADD CONSTRAINT "FK_7c841ba3e0fd21f84d706f57055" FOREIGN KEY ("planningAlertId") REFERENCES public.planning_alert(id) ON DELETE CASCADE;


--
-- TOC entry 5265 (class 2606 OID 30292)
-- Name: letter_campaign_address FK_85c5bac6df90f58bc0e5619003f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letter_campaign_address
    ADD CONSTRAINT "FK_85c5bac6df90f58bc0e5619003f" FOREIGN KEY ("savedTitleId") REFERENCES public.saved_title(id);


--
-- TOC entry 5285 (class 2606 OID 30297)
-- Name: saved_title FK_9125fd0ff14448b927c378363d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_title
    ADD CONSTRAINT "FK_9125fd0ff14448b927c378363d9" FOREIGN KEY ("teamId") REFERENCES public.team(id);


--
-- TOC entry 5254 (class 2606 OID 30302)
-- Name: invite FK_91bfeec7a9574f458e5b592472d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite
    ADD CONSTRAINT "FK_91bfeec7a9574f458e5b592472d" FOREIGN KEY ("userId") REFERENCES public.user_account(id) ON DELETE CASCADE;


--
-- TOC entry 5266 (class 2606 OID 30307)
-- Name: letter_campaign_address FK_9219f2993a0b03eec89a29f0f7b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letter_campaign_address
    ADD CONSTRAINT "FK_9219f2993a0b03eec89a29f0f7b" FOREIGN KEY ("letterCampaignId") REFERENCES public.letter_campaign(id);


--
-- TOC entry 5270 (class 2606 OID 30312)
-- Name: planning_alert FK_95f4ba5e38fbd12c22f9ffe8616; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_alert
    ADD CONSTRAINT "FK_95f4ba5e38fbd12c22f9ffe8616" FOREIGN KEY ("userId") REFERENCES public.user_account(id);


--
-- TOC entry 5276 (class 2606 OID 30317)
-- Name: project FK_9884b2ee80eb70b7db4f12e8aed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT "FK_9884b2ee80eb70b7db4f12e8aed" FOREIGN KEY ("ownerId") REFERENCES public.user_account(id);


--
-- TOC entry 5249 (class 2606 OID 30322)
-- Name: card_title_attachments_saved_title FK_9a8418c2b4ea84551aee989d075; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_title_attachments_saved_title
    ADD CONSTRAINT "FK_9a8418c2b4ea84551aee989d075" FOREIGN KEY ("cardId") REFERENCES public.card(id) ON DELETE CASCADE;


--
-- TOC entry 5250 (class 2606 OID 30327)
-- Name: card_title_attachments_saved_title FK_9b35f37638b90561a9ecad97c1f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_title_attachments_saved_title
    ADD CONSTRAINT "FK_9b35f37638b90561a9ecad97c1f" FOREIGN KEY ("savedTitleId") REFERENCES public.saved_title(id) ON DELETE CASCADE;


--
-- TOC entry 5297 (class 2606 OID 30332)
-- Name: workspace_users_that_favourited_user_account FK_9b486a3a11a586fd68312d8e810; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_users_that_favourited_user_account
    ADD CONSTRAINT "FK_9b486a3a11a586fd68312d8e810" FOREIGN KEY ("workspaceId") REFERENCES public.workspace(id) ON DELETE CASCADE;


--
-- TOC entry 5255 (class 2606 OID 30337)
-- Name: invite FK_a1af15adb0da760faca840263c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invite
    ADD CONSTRAINT "FK_a1af15adb0da760faca840263c1" FOREIGN KEY ("teamId") REFERENCES public.team(id);


--
-- TOC entry 5269 (class 2606 OID 30342)
-- Name: letter_template FK_a2a20e76318ac9edd99797f5728; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letter_template
    ADD CONSTRAINT "FK_a2a20e76318ac9edd99797f5728" FOREIGN KEY ("teamId") REFERENCES public.team(id);


--
-- TOC entry 5286 (class 2606 OID 30347)
-- Name: saved_title FK_ae54e022292f5bad50e74cd56bb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_title
    ADD CONSTRAINT "FK_ae54e022292f5bad50e74cd56bb" FOREIGN KEY ("createdById") REFERENCES public.user_account(id);


--
-- TOC entry 5267 (class 2606 OID 30352)
-- Name: letter_credit_ledger FK_b136866497508ddd61079493d6b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letter_credit_ledger
    ADD CONSTRAINT "FK_b136866497508ddd61079493d6b" FOREIGN KEY ("letterCampaignId") REFERENCES public.letter_campaign(id);


--
-- TOC entry 5247 (class 2606 OID 30357)
-- Name: card_members_user_account FK_b172b5c39f2c01b8e1a5c564cd5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_members_user_account
    ADD CONSTRAINT "FK_b172b5c39f2c01b8e1a5c564cd5" FOREIGN KEY ("userAccountId") REFERENCES public.user_account(id) ON DELETE CASCADE;


--
-- TOC entry 5296 (class 2606 OID 30362)
-- Name: workspace FK_b48532fc84800d41cfee110682c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace
    ADD CONSTRAINT "FK_b48532fc84800d41cfee110682c" FOREIGN KEY ("userId") REFERENCES public.user_account(id);


--
-- TOC entry 5302 (class 2606 OID 281125)
-- Name: bulk_title_purchase FK_b88ce84802d1abc3661b6dd0058; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bulk_title_purchase
    ADD CONSTRAINT "FK_b88ce84802d1abc3661b6dd0058" FOREIGN KEY ("columnIdId") REFERENCES public.project_column(id);


--
-- TOC entry 5298 (class 2606 OID 30367)
-- Name: workspace_users_that_favourited_user_account FK_bc2b516d3e1c218907962630f4d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_users_that_favourited_user_account
    ADD CONSTRAINT "FK_bc2b516d3e1c218907962630f4d" FOREIGN KEY ("userAccountId") REFERENCES public.user_account(id) ON DELETE CASCADE;


--
-- TOC entry 5279 (class 2606 OID 30372)
-- Name: project_members_user_account FK_c04d6b13761d6a6f672873e86e4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_members_user_account
    ADD CONSTRAINT "FK_c04d6b13761d6a6f672873e86e4" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- TOC entry 5288 (class 2606 OID 30377)
-- Name: title_credit_ledger FK_c3af12ca49978032669c8ac461f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.title_credit_ledger
    ADD CONSTRAINT "FK_c3af12ca49978032669c8ac461f" FOREIGN KEY ("teamId") REFERENCES public.team(id);


--
-- TOC entry 5278 (class 2606 OID 30382)
-- Name: project_column FK_c5d04e0e967ff1d4a5deb937e05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_column
    ADD CONSTRAINT "FK_c5d04e0e967ff1d4a5deb937e05" FOREIGN KEY ("projectId") REFERENCES public.project(id);


--
-- TOC entry 5273 (class 2606 OID 30387)
-- Name: planning_alert_users_to_alert_user_account FK_cb419ca83d6d196142f23225ce6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_alert_users_to_alert_user_account
    ADD CONSTRAINT "FK_cb419ca83d6d196142f23225ce6" FOREIGN KEY ("userAccountId") REFERENCES public.user_account(id) ON DELETE CASCADE;


--
-- TOC entry 5253 (class 2606 OID 30392)
-- Name: dxf_quote FK_cd4a72f8c442531a48f86410002; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dxf_quote
    ADD CONSTRAINT "FK_cd4a72f8c442531a48f86410002" FOREIGN KEY ("userId") REFERENCES public.user_account(id);


--
-- TOC entry 5291 (class 2606 OID 30397)
-- Name: title_report FK_cd6ab2b5b78900465155b3fa790; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.title_report
    ADD CONSTRAINT "FK_cd6ab2b5b78900465155b3fa790" FOREIGN KEY ("teamId") REFERENCES public.team(id);


--
-- TOC entry 5275 (class 2606 OID 30402)
-- Name: platform_notification FK_ce7b611cb40df86ba6014778dfb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_notification
    ADD CONSTRAINT "FK_ce7b611cb40df86ba6014778dfb" FOREIGN KEY ("userId") REFERENCES public.user_account(id);


--
-- TOC entry 5268 (class 2606 OID 30407)
-- Name: letter_credit_ledger FK_d03448f212ce9456fa437a1f227; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letter_credit_ledger
    ADD CONSTRAINT "FK_d03448f212ce9456fa437a1f227" FOREIGN KEY ("teamId") REFERENCES public.team(id);


--
-- TOC entry 5277 (class 2606 OID 30412)
-- Name: project FK_d0474b642dc0ae63660dd8e2ac0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT "FK_d0474b642dc0ae63660dd8e2ac0" FOREIGN KEY ("teamId") REFERENCES public.team(id);


--
-- TOC entry 5248 (class 2606 OID 30417)
-- Name: card_members_user_account FK_d0f903afb06fd7771aa411e3eba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_members_user_account
    ADD CONSTRAINT "FK_d0f903afb06fd7771aa411e3eba" FOREIGN KEY ("cardId") REFERENCES public.card(id) ON DELETE CASCADE;


--
-- TOC entry 5289 (class 2606 OID 30422)
-- Name: title_credit_ledger FK_d4aff8edfb74f4a85685b2c4d28; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.title_credit_ledger
    ADD CONSTRAINT "FK_d4aff8edfb74f4a85685b2c4d28" FOREIGN KEY ("landRegistryDocumentId") REFERENCES public.land_registry_document(id);


--
-- TOC entry 5281 (class 2606 OID 30427)
-- Name: project_title_attachments_saved_title FK_d6576cf9b83930ee8b30acb2302; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_title_attachments_saved_title
    ADD CONSTRAINT "FK_d6576cf9b83930ee8b30acb2302" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- TOC entry 5271 (class 2606 OID 30432)
-- Name: planning_alert FK_d6999d15e99a87756fa6f726fe4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_alert
    ADD CONSTRAINT "FK_d6999d15e99a87756fa6f726fe4" FOREIGN KEY ("savedTitleId") REFERENCES public.saved_title(id);


--
-- TOC entry 5246 (class 2606 OID 30437)
-- Name: card_land_assemblies_land_assembly FK_d714baadde9b4ef46fc06e49cb5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_land_assemblies_land_assembly
    ADD CONSTRAINT "FK_d714baadde9b4ef46fc06e49cb5" FOREIGN KEY ("landAssemblyId") REFERENCES public.land_assembly(id) ON DELETE CASCADE;


--
-- TOC entry 5282 (class 2606 OID 30442)
-- Name: project_title_attachments_saved_title FK_d850f50ca61527f06d731549466; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_title_attachments_saved_title
    ADD CONSTRAINT "FK_d850f50ca61527f06d731549466" FOREIGN KEY ("savedTitleId") REFERENCES public.saved_title(id) ON DELETE CASCADE;


--
-- TOC entry 5300 (class 2606 OID 271171)
-- Name: land_assembly_saved_titles_saved_title FK_da3baf5ab72779f3f95a121a72b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_assembly_saved_titles_saved_title
    ADD CONSTRAINT "FK_da3baf5ab72779f3f95a121a72b" FOREIGN KEY ("savedTitleId") REFERENCES public.saved_title(id) ON DELETE CASCADE;


--
-- TOC entry 5242 (class 2606 OID 30447)
-- Name: card_comment FK_dd3294c8f3d73255982046bc388; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_comment
    ADD CONSTRAINT "FK_dd3294c8f3d73255982046bc388" FOREIGN KEY ("cardId") REFERENCES public.card(id);


--
-- TOC entry 5264 (class 2606 OID 30452)
-- Name: letter_campaign FK_edbb3f82945ae7c4843bca494cd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letter_campaign
    ADD CONSTRAINT "FK_edbb3f82945ae7c4843bca494cd" FOREIGN KEY ("letterTemplateId") REFERENCES public.letter_template(id);


--
-- TOC entry 5244 (class 2606 OID 30457)
-- Name: card_label FK_f24e4823755d1386b16cd184ae8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_label
    ADD CONSTRAINT "FK_f24e4823755d1386b16cd184ae8" FOREIGN KEY ("projectId") REFERENCES public.project(id);


--
-- TOC entry 5238 (class 2606 OID 30462)
-- Name: card FK_f2ea75a6729b657d16f6dde6a6c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card
    ADD CONSTRAINT "FK_f2ea75a6729b657d16f6dde6a6c" FOREIGN KEY ("creatorId") REFERENCES public.user_account(id);


--
-- TOC entry 5280 (class 2606 OID 30467)
-- Name: project_members_user_account FK_f2fe072adee61a1693cd77765cc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_members_user_account
    ADD CONSTRAINT "FK_f2fe072adee61a1693cd77765cc" FOREIGN KEY ("userAccountId") REFERENCES public.user_account(id) ON DELETE CASCADE;


--
-- TOC entry 5261 (class 2606 OID 30472)
-- Name: land_registry_proprietor FK_f440208326ca4acf0c1155c13fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.land_registry_proprietor
    ADD CONSTRAINT "FK_f440208326ca4acf0c1155c13fd" FOREIGN KEY ("documentId") REFERENCES public.land_registry_document(id);


--
-- TOC entry 5290 (class 2606 OID 30477)
-- Name: title_credit_ledger FK_f5ccc661a2edec57aaae233497e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.title_credit_ledger
    ADD CONSTRAINT "FK_f5ccc661a2edec57aaae233497e" FOREIGN KEY ("userId") REFERENCES public.user_account(id);


--
-- TOC entry 5292 (class 2606 OID 30482)
-- Name: title_report FK_ff154002db7b5a0f4652294121c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.title_report
    ADD CONSTRAINT "FK_ff154002db7b5a0f4652294121c" FOREIGN KEY ("userId") REFERENCES public.user_account(id);


--
-- TOC entry 5226 (class 2606 OID 16549)
-- Name: buckets buckets_owner_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_owner_fkey FOREIGN KEY (owner) REFERENCES auth.users(id);


--
-- TOC entry 5227 (class 2606 OID 16566)
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- TOC entry 5228 (class 2606 OID 16571)
-- Name: objects objects_owner_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_owner_fkey FOREIGN KEY (owner) REFERENCES auth.users(id);


--
-- TOC entry 5515 (class 3256 OID 139014)
-- Name: session Anyone can create a session; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can create a session" ON public.session USING (("userId" = auth.uid()));


--
-- TOC entry 5496 (class 3256 OID 138748)
-- Name: project_column Only people with access to the project; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only people with access to the project" ON public.project_column USING ((EXISTS ( SELECT 1
   FROM public.project
  WHERE (project.id = project_column."projectId"))));


--
-- TOC entry 5504 (class 3256 OID 138757)
-- Name: dxf_quote Only view teams DXF Quote; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only view teams DXF Quote" ON public.dxf_quote USING (("userId" IN ( SELECT public.get_user_ids_for_authenticated_team() AS get_user_ids_for_authenticated_team)));


--
-- TOC entry 5506 (class 3256 OID 138759)
-- Name: card_comment Only view teams card comments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only view teams card comments" ON public.card_comment USING ((EXISTS ( SELECT 1
   FROM public.card
  WHERE (card.id = card_comment."cardId"))));


--
-- TOC entry 5507 (class 3256 OID 138760)
-- Name: card_label Only view teams card labels; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only view teams card labels" ON public.card_label USING ((EXISTS ( SELECT 1
   FROM public.project
  WHERE (project.id = card_label."projectId"))));


--
-- TOC entry 5505 (class 3256 OID 138758)
-- Name: card Only view teams cards; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only view teams cards" ON public.card USING ((EXISTS ( SELECT 1
   FROM public.project_column
  WHERE (card."columnId" = project_column.id))));


--
-- TOC entry 5508 (class 3256 OID 138761)
-- Name: invite Only view teams invites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only view teams invites" ON public.invite USING (("teamId" IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5509 (class 3256 OID 138762)
-- Name: land_registry_document Only view teams land registry documents; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only view teams land registry documents" ON public.land_registry_document USING ((EXISTS ( SELECT 1
   FROM public.user_account
  WHERE (user_account.id = land_registry_document."createdById"))));


--
-- TOC entry 5510 (class 3256 OID 138763)
-- Name: land_registry_proprietor Only view teams land registry proprietor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only view teams land registry proprietor" ON public.land_registry_proprietor USING ((EXISTS ( SELECT 1
   FROM public.land_registry_document
  WHERE (land_registry_document.id = land_registry_proprietor."documentId"))));


--
-- TOC entry 5511 (class 3256 OID 138764)
-- Name: land_registry_proprietor_address Only view teams land registry proprietor addresses; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only view teams land registry proprietor addresses" ON public.land_registry_proprietor_address USING ((EXISTS ( SELECT 1
   FROM public.land_registry_proprietor
  WHERE (land_registry_proprietor.id = land_registry_proprietor_address."proprietorId"))));


--
-- TOC entry 5512 (class 3256 OID 139011)
-- Name: letter_campaign_address Only view teams letter campaign addresses; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only view teams letter campaign addresses" ON public.letter_campaign_address USING ((EXISTS ( SELECT 1
   FROM public.letter_campaign
  WHERE (letter_campaign.id = letter_campaign_address."letterCampaignId"))));


--
-- TOC entry 5514 (class 3256 OID 139013)
-- Name: planning_alert Only view teams planning alerts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only view teams planning alerts" ON public.planning_alert USING ((EXISTS ( SELECT 1
   FROM public.user_account
  WHERE (user_account.id = planning_alert."userId"))));


--
-- TOC entry 5513 (class 3256 OID 139012)
-- Name: platform_notification Only view your notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only view your notifications" ON public.platform_notification USING (("userId" = auth.uid()));


--
-- TOC entry 5502 (class 3256 OID 138754)
-- Name: user_account Team members can access user accounts in team; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Team members can access user accounts in team" ON public.user_account USING (("teamId" IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5490 (class 3256 OID 138742)
-- Name: dxf_export Team members only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Team members only" ON public.dxf_export USING (("teamId" IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5491 (class 3256 OID 138743)
-- Name: land_assembly Team members only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Team members only" ON public.land_assembly USING (("teamId" IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5492 (class 3256 OID 138744)
-- Name: letter_campaign Team members only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Team members only" ON public.letter_campaign USING (("teamId" IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5493 (class 3256 OID 138745)
-- Name: letter_credit_ledger Team members only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Team members only" ON public.letter_credit_ledger USING (("teamId" IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5494 (class 3256 OID 138746)
-- Name: letter_template Team members only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Team members only" ON public.letter_template USING (("teamId" IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5495 (class 3256 OID 138747)
-- Name: project Team members only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Team members only" ON public.project USING (("teamId" IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5497 (class 3256 OID 138749)
-- Name: saved_title Team members only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Team members only" ON public.saved_title USING (("teamId" IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5498 (class 3256 OID 138750)
-- Name: team Team members only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Team members only" ON public.team USING ((id IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5499 (class 3256 OID 138751)
-- Name: title_credit_ledger Team members only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Team members only" ON public.title_credit_ledger USING (("teamId" IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5500 (class 3256 OID 138752)
-- Name: title_report Team members only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Team members only" ON public.title_report USING (("teamId" IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5501 (class 3256 OID 138753)
-- Name: usage_event Team members only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Team members only" ON public.usage_event USING (("teamId" IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5503 (class 3256 OID 138755)
-- Name: workspace Team members only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Team members only" ON public.workspace USING (("teamId" IN ( SELECT public.get_team_ids_for_authenticated_user() AS get_team_ids_for_authenticated_user)));


--
-- TOC entry 5462 (class 0 OID 29693)
-- Dependencies: 296
-- Name: card; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.card ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5463 (class 0 OID 29704)
-- Dependencies: 298
-- Name: card_comment; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.card_comment ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5464 (class 0 OID 29717)
-- Dependencies: 299
-- Name: card_label; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.card_label ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5465 (class 0 OID 29734)
-- Dependencies: 303
-- Name: dxf_export; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.dxf_export ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5466 (class 0 OID 29742)
-- Dependencies: 304
-- Name: dxf_quote; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.dxf_quote ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5467 (class 0 OID 29751)
-- Dependencies: 305
-- Name: invite; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.invite ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5468 (class 0 OID 29761)
-- Dependencies: 306
-- Name: land_assembly; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.land_assembly ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5469 (class 0 OID 29771)
-- Dependencies: 307
-- Name: land_registry_document; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.land_registry_document ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5470 (class 0 OID 29781)
-- Dependencies: 308
-- Name: land_registry_proprietor; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.land_registry_proprietor ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5471 (class 0 OID 29789)
-- Dependencies: 309
-- Name: land_registry_proprietor_address; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.land_registry_proprietor_address ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5472 (class 0 OID 29797)
-- Dependencies: 310
-- Name: letter_campaign; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.letter_campaign ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5473 (class 0 OID 29806)
-- Dependencies: 311
-- Name: letter_campaign_address; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.letter_campaign_address ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5474 (class 0 OID 29814)
-- Dependencies: 312
-- Name: letter_credit_ledger; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.letter_credit_ledger ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5475 (class 0 OID 29823)
-- Dependencies: 313
-- Name: letter_template; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.letter_template ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5476 (class 0 OID 29839)
-- Dependencies: 316
-- Name: planning_alert; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.planning_alert ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5477 (class 0 OID 29851)
-- Dependencies: 318
-- Name: platform_notification; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.platform_notification ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5478 (class 0 OID 29862)
-- Dependencies: 319
-- Name: project; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.project ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5479 (class 0 OID 29870)
-- Dependencies: 320
-- Name: project_column; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.project_column ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5480 (class 0 OID 29884)
-- Dependencies: 323
-- Name: saved_area; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.saved_area ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5481 (class 0 OID 29892)
-- Dependencies: 324
-- Name: saved_query; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.saved_query ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5482 (class 0 OID 29900)
-- Dependencies: 325
-- Name: saved_title; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.saved_title ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5483 (class 0 OID 29910)
-- Dependencies: 326
-- Name: session; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.session ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5484 (class 0 OID 29919)
-- Dependencies: 327
-- Name: team; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.team ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5485 (class 0 OID 29937)
-- Dependencies: 328
-- Name: title_credit_ledger; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.title_credit_ledger ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5486 (class 0 OID 29946)
-- Dependencies: 329
-- Name: title_report; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.title_report ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5487 (class 0 OID 29954)
-- Dependencies: 330
-- Name: usage_event; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.usage_event ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5488 (class 0 OID 29968)
-- Dependencies: 331
-- Name: user_account; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_account ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5489 (class 0 OID 29985)
-- Dependencies: 332
-- Name: workspace; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workspace ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5459 (class 0 OID 16540)
-- Dependencies: 263
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5461 (class 0 OID 16582)
-- Dependencies: 265
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5460 (class 0 OID 16555)
-- Dependencies: 264
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5516 (class 6104 OID 16419)
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


--
-- TOC entry 4748 (class 3466 OID 16615)
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


--
-- TOC entry 4745 (class 3466 OID 16592)
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE SCHEMA')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


--
-- TOC entry 4747 (class 3466 OID 16613)
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE FUNCTION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


--
-- TOC entry 4746 (class 3466 OID 16594)
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


--
-- TOC entry 4749 (class 3466 OID 16616)
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


--
-- TOC entry 4750 (class 3466 OID 16617)
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


-- Completed on 2023-06-21 18:35:00 Africa

--
-- PostgreSQL database dump complete
--
