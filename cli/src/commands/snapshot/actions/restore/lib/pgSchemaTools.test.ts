import { isComment, splitSchema } from './pgSchemaTools.js'

const SCHEMA = `--
-- PostgreSQL database dump
--

SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;

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
-- TOC entry 4064 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 656 (class 1247 OID 39068)
-- Name: AccessTokenType; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."AccessTokenType" AS ENUM (
    'CLI',
    'WORKER'
);


SET default_tablespace = '';

--
-- TOC entry 2899 (class 1255 OID 115348)
-- Name: attribute_abn_on_account(); Type: PROCEDURE; Schema: _index; Owner: -
--

CREATE PROCEDURE _index.attribute_abn_on_account()
    LANGUAGE plpgsql
    AS $$
BEGIN

    INSERT INTO _index.attribute_abn_on_account AS i
    SELECT * from _reduce.attribute_abn_on_account
    ON CONFLICT (account_id) do update
            set abn = excluded.abn,
                offset_id = excluded.offset_id,
                assigned_date = excluded.assigned_date,
                by_user = excluded.by_user
    WHERE excluded.offset_id > i.offset_id;

END;
$$;

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
-- TOC entry 4066 (class 0 OID 0)
-- Dependencies: 213
-- Name: Member_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Member_id_seq" OWNED BY public."Member".id;

--
-- TOC entry 3858 (class 2604 OID 60717)
-- Name: DatabaseProvider id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DatabaseProvider" ALTER COLUMN id SET DEFAULT nextval('public."DatabaseProvider_id_seq"'::regclass);

--
-- TOC entry 3874 (class 2606 OID 18182)
-- Name: AccessToken AccessToken_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AccessToken"
    ADD CONSTRAINT "AccessToken_pkey" PRIMARY KEY (id);

--
-- TOC entry 3875 (class 1259 OID 18231)
-- Name: AccessToken_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "AccessToken_userId_idx" ON public."AccessToken" USING btree ("userId");

--
-- TOC entry 3906 (class 1259 OID 60723)
-- Name: DatabaseProvider_domain_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "DatabaseProvider_domain_key" ON public."DatabaseProvider" USING btree (domain);

--
-- TOC entry 3917 (class 2606 OID 58991)
-- Name: AccessToken AccessToken_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AccessToken"
    ADD CONSTRAINT "AccessToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;

-- Completed on 2023-02-07 06:11:43 Africa

--
-- PostgreSQL database dump complete
--
`

test('split statements from schemas.sql', () => {
  expect(splitSchema(SCHEMA)).toMatchInlineSnapshot(`
    [
      "SET standard_conforming_strings = on;
    SELECT pg_catalog.set_config('search_path', '', false);
    SET check_function_bodies = false;",
      "CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;",
      "COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';",
      "CREATE TYPE public.\\"AccessTokenType\\" AS ENUM (
    'CLI',
    'WORKER'
    );
    SET default_tablespace = '';",
      "CREATE PROCEDURE _index.attribute_abn_on_account()
    LANGUAGE plpgsql
    AS $$
    BEGIN
    INSERT INTO _index.attribute_abn_on_account AS i
    SELECT * from _reduce.attribute_abn_on_account
    ON CONFLICT (account_id) do update
    set abn = excluded.abn,
    offset_id = excluded.offset_id,
    assigned_date = excluded.assigned_date,
    by_user = excluded.by_user
    WHERE excluded.offset_id > i.offset_id;
    END;
    $$;",
      "CREATE TABLE public.\\"AccessToken\\" (
    id text NOT NULL,
    \\"updatedAt\\" timestamp(3) without time zone NOT NULL,
    \\"createdAt\\" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    \\"userId\\" text NOT NULL,
    \\"userAgent\\" text,
    type public.\\"AccessTokenType\\" DEFAULT 'CLI'::public.\\"AccessTokenType\\" NOT NULL,
    name text
    );",
      "CREATE SEQUENCE public.\\"Member_id_seq\\"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;",
      "ALTER SEQUENCE public.\\"Member_id_seq\\" OWNED BY public.\\"Member\\".id;",
      "ALTER TABLE ONLY public.\\"DatabaseProvider\\" ALTER COLUMN id SET DEFAULT nextval('public.\\"DatabaseProvider_id_seq\\"'::regclass);",
      "ALTER TABLE ONLY public.\\"AccessToken\\"
    ADD CONSTRAINT \\"AccessToken_pkey\\" PRIMARY KEY (id);",
      "CREATE INDEX \\"AccessToken_userId_idx\\" ON public.\\"AccessToken\\" USING btree (\\"userId\\");",
      "CREATE UNIQUE INDEX \\"DatabaseProvider_domain_key\\" ON public.\\"DatabaseProvider\\" USING btree (domain);",
      "ALTER TABLE ONLY public.\\"AccessToken\\"
    ADD CONSTRAINT \\"AccessToken_userId_fkey\\" FOREIGN KEY (\\"userId\\") REFERENCES public.\\"User\\"(id) ON UPDATE CASCADE ON DELETE RESTRICT;",
    ]
  `)
})

test('finds SQL comments', () => {
  expect(isComment('-- pew pew pew')).toEqual(true)
  expect(isComment('CREATE TABLE public.city')).toEqual(false)
})
