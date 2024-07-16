-- Schema with syntax error making it unparseable
CREATE TABLE public.companies (
    id integer NOT NULL,
    "fromEmailsBlacklist" character varying(255)[]
);

XXX

CREATE SEQUENCE public.companies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;