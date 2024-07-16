 --
 -- PostgreSQL database dump
 --

 -- Dumped from database version 13.8
 -- Dumped by pg_dump version 15.2 (Ubuntu 15.2-1.pgdg22.04+1)

 -- Started on 2023-04-05 10:30:44 Africa

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
 -- TOC entry 8 (class 2615 OID 16403)
 -- Name: hangfire; Type: SCHEMA; Schema: -; Owner: -
 --

 CREATE SCHEMA IF NOT EXISTS hangfire;


 --
 -- TOC entry 7 (class 2615 OID 2200)
 -- Name: public; Type: SCHEMA; Schema: -; Owner: -
 --

 -- *not* creating schema, since initdb creates it


 --
 -- TOC entry 2 (class 3079 OID 16404)
 -- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
 --

 CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


 --
 -- TOC entry 5432 (class 0 OID 0)
 -- Dependencies: 2
 -- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
 --

 COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


 --
 -- TOC entry 3 (class 3079 OID 16405)
 -- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
 --

 CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


 --
 -- TOC entry 5433 (class 0 OID 0)
 -- Dependencies: 3
 -- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
 --

 COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


 SET default_tablespace = '';

 SET default_table_access_method = heap;

 --
 -- TOC entry 203 (class 1259 OID 340216)
 -- Name: counter; Type: TABLE; Schema: hangfire; Owner: -
 --

 CREATE TABLE hangfire.counter (
     id bigint NOT NULL,
     key text NOT NULL,
     value bigint NOT NULL,
     expireat timestamp without time zone
 );


 --
 -- TOC entry 204 (class 1259 OID 340222)
 -- Name: counter_id_seq; Type: SEQUENCE; Schema: hangfire; Owner: -
 --

 CREATE SEQUENCE hangfire.counter_id_seq
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1;


 --
 -- TOC entry 5434 (class 0 OID 0)
 -- Dependencies: 204
 -- Name: counter_id_seq; Type: SEQUENCE OWNED BY; Schema: hangfire; Owner: -
 --

 ALTER SEQUENCE hangfire.counter_id_seq OWNED BY hangfire.counter.id;


 --
 -- TOC entry 205 (class 1259 OID 340224)
 -- Name: hash; Type: TABLE; Schema: hangfire; Owner: -
 --

 CREATE TABLE hangfire.hash (
     id bigint NOT NULL,
     key text NOT NULL,
     field text NOT NULL,
     value text,
     expireat timestamp without time zone,
     updatecount integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 206 (class 1259 OID 340231)
 -- Name: hash_id_seq; Type: SEQUENCE; Schema: hangfire; Owner: -
 --

 CREATE SEQUENCE hangfire.hash_id_seq
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1;


 --
 -- TOC entry 5435 (class 0 OID 0)
 -- Dependencies: 206
 -- Name: hash_id_seq; Type: SEQUENCE OWNED BY; Schema: hangfire; Owner: -
 --

 ALTER SEQUENCE hangfire.hash_id_seq OWNED BY hangfire.hash.id;


 --
 -- TOC entry 207 (class 1259 OID 340233)
 -- Name: job; Type: TABLE; Schema: hangfire; Owner: -
 --

 CREATE TABLE hangfire.job (
     id bigint NOT NULL,
     stateid bigint,
     statename text,
     invocationdata text NOT NULL,
     arguments text NOT NULL,
     createdat timestamp without time zone NOT NULL,
     expireat timestamp without time zone,
     updatecount integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 208 (class 1259 OID 340240)
 -- Name: job_id_seq; Type: SEQUENCE; Schema: hangfire; Owner: -
 --

 CREATE SEQUENCE hangfire.job_id_seq
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1;


 --
 -- TOC entry 5436 (class 0 OID 0)
 -- Dependencies: 208
 -- Name: job_id_seq; Type: SEQUENCE OWNED BY; Schema: hangfire; Owner: -
 --

 ALTER SEQUENCE hangfire.job_id_seq OWNED BY hangfire.job.id;


 --
 -- TOC entry 209 (class 1259 OID 340242)
 -- Name: jobparameter; Type: TABLE; Schema: hangfire; Owner: -
 --

 CREATE TABLE hangfire.jobparameter (
     id bigint NOT NULL,
     jobid bigint NOT NULL,
     name text NOT NULL,
     value text,
     updatecount integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 210 (class 1259 OID 340249)
 -- Name: jobparameter_id_seq; Type: SEQUENCE; Schema: hangfire; Owner: -
 --

 CREATE SEQUENCE hangfire.jobparameter_id_seq
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1;


 --
 -- TOC entry 5437 (class 0 OID 0)
 -- Dependencies: 210
 -- Name: jobparameter_id_seq; Type: SEQUENCE OWNED BY; Schema: hangfire; Owner: -
 --

 ALTER SEQUENCE hangfire.jobparameter_id_seq OWNED BY hangfire.jobparameter.id;


 --
 -- TOC entry 211 (class 1259 OID 340251)
 -- Name: jobqueue; Type: TABLE; Schema: hangfire; Owner: -
 --

 CREATE TABLE hangfire.jobqueue (
     id bigint NOT NULL,
     jobid bigint NOT NULL,
     queue text NOT NULL,
     fetchedat timestamp without time zone,
     updatecount integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 212 (class 1259 OID 340258)
 -- Name: jobqueue_id_seq; Type: SEQUENCE; Schema: hangfire; Owner: -
 --

 CREATE SEQUENCE hangfire.jobqueue_id_seq
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1;


 --
 -- TOC entry 5438 (class 0 OID 0)
 -- Dependencies: 212
 -- Name: jobqueue_id_seq; Type: SEQUENCE OWNED BY; Schema: hangfire; Owner: -
 --

 ALTER SEQUENCE hangfire.jobqueue_id_seq OWNED BY hangfire.jobqueue.id;


 --
 -- TOC entry 213 (class 1259 OID 340260)
 -- Name: list; Type: TABLE; Schema: hangfire; Owner: -
 --

 CREATE TABLE hangfire.list (
     id bigint NOT NULL,
     key text NOT NULL,
     value text,
     expireat timestamp without time zone,
     updatecount integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 214 (class 1259 OID 340267)
 -- Name: list_id_seq; Type: SEQUENCE; Schema: hangfire; Owner: -
 --

 CREATE SEQUENCE hangfire.list_id_seq
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1;


 --
 -- TOC entry 5439 (class 0 OID 0)
 -- Dependencies: 214
 -- Name: list_id_seq; Type: SEQUENCE OWNED BY; Schema: hangfire; Owner: -
 --

 ALTER SEQUENCE hangfire.list_id_seq OWNED BY hangfire.list.id;


 --
 -- TOC entry 215 (class 1259 OID 340269)
 -- Name: lock; Type: TABLE; Schema: hangfire; Owner: -
 --

 CREATE TABLE hangfire.lock (
     resource text NOT NULL,
     updatecount integer DEFAULT 0 NOT NULL,
     acquired timestamp without time zone
 );


 --
 -- TOC entry 216 (class 1259 OID 340276)
 -- Name: schema; Type: TABLE; Schema: hangfire; Owner: -
 --

 CREATE TABLE hangfire.schema (
     version integer NOT NULL
 );


 --
 -- TOC entry 217 (class 1259 OID 340279)
 -- Name: server; Type: TABLE; Schema: hangfire; Owner: -
 --

 CREATE TABLE hangfire.server (
     id text NOT NULL,
     data text,
     lastheartbeat timestamp without time zone NOT NULL,
     updatecount integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 218 (class 1259 OID 340286)
 -- Name: set; Type: TABLE; Schema: hangfire; Owner: -
 --

 CREATE TABLE hangfire.set (
     id bigint NOT NULL,
     key text NOT NULL,
     score double precision NOT NULL,
     value text NOT NULL,
     expireat timestamp without time zone,
     updatecount integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 219 (class 1259 OID 340293)
 -- Name: set_id_seq; Type: SEQUENCE; Schema: hangfire; Owner: -
 --

 CREATE SEQUENCE hangfire.set_id_seq
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1;


 --
 -- TOC entry 5440 (class 0 OID 0)
 -- Dependencies: 219
 -- Name: set_id_seq; Type: SEQUENCE OWNED BY; Schema: hangfire; Owner: -
 --

 ALTER SEQUENCE hangfire.set_id_seq OWNED BY hangfire.set.id;


 --
 -- TOC entry 220 (class 1259 OID 340295)
 -- Name: state; Type: TABLE; Schema: hangfire; Owner: -
 --

 CREATE TABLE hangfire.state (
     id bigint NOT NULL,
     jobid bigint NOT NULL,
     name text NOT NULL,
     reason text,
     createdat timestamp without time zone NOT NULL,
     data text,
     updatecount integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 221 (class 1259 OID 340302)
 -- Name: state_id_seq; Type: SEQUENCE; Schema: hangfire; Owner: -
 --

 CREATE SEQUENCE hangfire.state_id_seq
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1;


 --
 -- TOC entry 5441 (class 0 OID 0)
 -- Dependencies: 221
 -- Name: state_id_seq; Type: SEQUENCE OWNED BY; Schema: hangfire; Owner: -
 --

 ALTER SEQUENCE hangfire.state_id_seq OWNED BY hangfire.state.id;


 --
 -- TOC entry 297 (class 1259 OID 556633)
 -- Name: MentionConnectionSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."MentionConnectionSet" (
     "Id" bigint NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "UserStorySetId" bigint,
     "AboutAccountId" integer,
     "FromAccountId" integer,
     "Discriminator" text DEFAULT ''::text NOT NULL,
     "MentionConnectionTypeEnum" integer DEFAULT 0 NOT NULL,
     "AboutServiceId" bigint,
     "UserStoryAboutServiceConnectionSet_UserStorySetId" bigint,
     "AboutServiceTypeId" integer,
     "UserStoryAboutServiceTypeConnectionSet_UserStorySetId" bigint,
     "TenantIdentifier" text
 );


 --
 -- TOC entry 296 (class 1259 OID 556631)
 -- Name: AboutAccountConnectionSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."MentionConnectionSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."AboutAccountConnectionSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 264 (class 1259 OID 361431)
 -- Name: AccountInvoiceInformationSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."AccountInvoiceInformationSet" (
     "Id" integer NOT NULL,
     "AccountId" integer NOT NULL,
     "VatNumber" text,
     "CountryCode" text,
     "State" text,
     "Street" text,
     "Building" text,
     "Apartment" text,
     "PostalCode" text,
     "IsStandard" boolean NOT NULL,
     "CreationDate" timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
     "CompanyNameOrNull" text
 );


 --
 -- TOC entry 263 (class 1259 OID 361429)
 -- Name: AccountInvoiceInformationSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."AccountInvoiceInformationSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."AccountInvoiceInformationSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 274 (class 1259 OID 508950)
 -- Name: AccountMultitenancySet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."AccountMultitenancySet" (
     "Id" integer NOT NULL,
     "AccountId" integer,
     "TenantId" integer,
     "EstablishedOn" timestamp without time zone NOT NULL,
     "TenantIdentifier" text,
     "AccountStatusTenantAwareSetId" integer,
     "ConsentGivenByUserOn" timestamp without time zone,
     "PermissionType" integer DEFAULT 1 NOT NULL
 );


 --
 -- TOC entry 273 (class 1259 OID 508948)
 -- Name: AccountMultitenancySet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."AccountMultitenancySet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."AccountMultitenancySet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 309 (class 1259 OID 572632)
 -- Name: AccountQuotaPerDaySet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."AccountQuotaPerDaySet" (
     "Id" integer NOT NULL,
     "AccountStatusSetId" integer,
     "Date" timestamp without time zone NOT NULL,
     "TextedTodayAccountIds" integer[],
     "MesagesTodayCount" integer NOT NULL
 );


 --
 -- TOC entry 308 (class 1259 OID 572630)
 -- Name: AccountQuotaPerDaySet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."AccountQuotaPerDaySet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."AccountQuotaPerDaySet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 222 (class 1259 OID 340320)
 -- Name: AccountSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."AccountSet" (
     "Id" integer NOT NULL,
     "UserTypeEnum" integer NOT NULL,
     "Username" text NOT NULL,
     "Firstname" text,
     "Lastname" text,
     "MarkedForDeletion" boolean NOT NULL,
     "CompanyNameOrNull" text,
     "LocationCodeOfCompanyOrNull" text,
     "BackgroundCheckUrlOrText" text,
     "TermsAndConditionsLatestApproval" timestamp without time zone NOT NULL,
     "ProfileImageId" integer,
     "Disabled" boolean DEFAULT false NOT NULL,
     "AccountStatusId" integer,
     "LinkedInUrlOrNull" text,
     "OwnWebsiteUrlOrNull" text,
     "TermsAndConditionsId" integer,
     "MarketingLatestApproval" timestamp without time zone,
     "TimeZoneOffsetOrNull" text,
     "TimeZoneResolvedOrNull" text,
     "CreationDateOrDefault" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "LastSavingDateOrDefault" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "SpokenLanguagesSemicolonSeparated" text,
     "ExternalTermsAndConditions" text,
     "IsExternalTermsAndConditions" boolean DEFAULT false NOT NULL,
     "AccountDescriptionsJs" jsonb,
     "AccountDescriptionsJs_value1_english" text,
     "AccountDescriptionsJs_value1_german" text,
     "AccountDescriptionsJs_value2_english" text,
     "AccountDescriptionsJs_value2_german" text,
     "AccountDescriptionsJs_value3_english" text,
     "AccountDescriptionsJs_value3_german" text,
     "SpokenLanguagesSemicolonSeparatedTs" tsvector GENERATED ALWAYS AS (to_tsvector('english'::regconfig, "SpokenLanguagesSemicolonSeparated")) STORED,
     "SsoProvider" text,
     "RevenueCutGeneralId" integer,
     "AggregatedPostedStories" integer DEFAULT 0 NOT NULL,
     "AggregatedPostedStoryAskTheComunity" integer DEFAULT 0 NOT NULL,
     "AggregatedPostedStoryRecommendations" integer DEFAULT 0 NOT NULL,
     "AggregatedPostedStorySuccessStories" integer DEFAULT 0 NOT NULL,
     "CompanyImageId" integer,
     "AccountDescriptionsJs_value4_english" text,
     "AccountDescriptionsJs_value4_german" text,
     "SearchFieldsTs_english" tsvector GENERATED ALWAYS AS (to_tsvector('english'::regconfig, ((((((((((((COALESCE("Firstname", ''::text) || ' '::text) || COALESCE("Lastname", ''::text)) || ' '::text) || COALESCE("CompanyNameOrNull", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value1_english", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value2_english", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value3_english", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value4_english", ''::text)))) STORED,
     "SearchFieldsTs_german" tsvector GENERATED ALWAYS AS (to_tsvector('german'::regconfig, ((((((((((((COALESCE("Firstname", ''::text) || ' '::text) || COALESCE("Lastname", ''::text)) || ' '::text) || COALESCE("CompanyNameOrNull", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value1_german", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value2_german", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value3_german", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value4_german", ''::text)))) STORED,
     "Phone" character varying(25),
     "DateTimeKarmaSeed" timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
     "DateTimeKarma_english" timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
     "DateTimeKarma_english_number" bigint DEFAULT 0 NOT NULL,
     "DateTimeKarma_german" timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
     "DateTimeKarma_german_number" bigint DEFAULT 0 NOT NULL,
     "KarmaCriteria" text[],
     "KarmaBoostCount_de" integer DEFAULT 0 NOT NULL,
     "KarmaBoostCount_en" integer DEFAULT 0 NOT NULL,
     "KarmaPunishCount_de" integer DEFAULT 0 NOT NULL,
     "KarmaPunishCount_en" integer DEFAULT 0 NOT NULL,
     "AudienceTypeEnum" integer DEFAULT 0 NOT NULL,
     "PromptEngineeringAiSetId" integer,
     "TenantIdentifierRegistration" text
 );


 --
 -- TOC entry 360 (class 1259 OID 2359223)
 -- Name: AccountSetConversationSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."AccountSetConversationSet" (
     "ConversationsId" integer NOT NULL,
     "ParticipantAccountsId" integer NOT NULL
 );


 --
 -- TOC entry 223 (class 1259 OID 340334)
 -- Name: AccountSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."AccountSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."AccountSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 307 (class 1259 OID 558843)
 -- Name: AccountStatsSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."AccountStatsSet" (
     "Id" integer NOT NULL,
     "AccountSetId" integer NOT NULL,
     "AggregatedPositiveRatings" integer NOT NULL,
     "AggregatedNegativeRatings" integer NOT NULL,
     "AggregatedRating" double precision NOT NULL,
     "AggregatedBookmarkedByAccounts" integer NOT NULL,
     "AggregatedRecommendations" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 306 (class 1259 OID 558841)
 -- Name: AccountStatsSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."AccountStatsSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."AccountStatsSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 224 (class 1259 OID 340336)
 -- Name: AccountStatus; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."AccountStatus" (
     "Id" integer NOT NULL,
     "IsSavingExpertServicesStartDateOrNull" timestamp without time zone,
     "ServicesLastPublishDateOrNull" timestamp without time zone,
     "IsProfileInfoCompleteDateOrNull" timestamp without time zone,
     "IsEthicsAgreementAcceptedDateOrNull" timestamp without time zone,
     "BlockedUntil" timestamp without time zone,
     "IsBlocked" timestamp without time zone,
     "CreationDateOrDefault" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "LastSavingDateAccountPersonalDetails" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "MarketingLatestApproval" timestamp without time zone,
     "PrivacyPolicyLatestApproval" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "TermsAndConditionsLatestApproval" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "IsPricingPrerequisitesDataPresentSinceDateOrNull" timestamp without time zone,
     "LastChatMessageSentOn" timestamp without time zone,
     "IsTermsAndConditionsDataPresentSinceDateOrNull" timestamp without time zone,
     "LastSavingDateAccount" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "LastSavingDateAccountCompanyDetails" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "IsCompanyImageDataPresentSinceDateOrNull" timestamp without time zone,
     "IsPricingPrerequisitesDataAcceptedToBeProvidedBySophiaOrNull" timestamp without time zone,
     "IsProfileImageDataPresentSinceDateOrNull" timestamp without time zone,
     "ServiceSettingsLastPostAdvisingStatusStash" timestamp without time zone,
     "ServiceSettingsLastPostCallDurationStash" timestamp without time zone,
     "ServiceSettingsLastPostCountriesStash" timestamp without time zone,
     "ServiceSettingsLastPostLanguagesStash" timestamp without time zone,
     "ServiceSettingsLastPostOfficeHoursStash" timestamp without time zone,
     "ServiceSettingsLastPostPricingModelStash" timestamp without time zone,
     "ServiceSettingsLastPostPublishInfoStash" timestamp without time zone,
     "ServiceSettingsLastPostServiceStash" timestamp without time zone,
     "ServiceSettingsLastPostDraftServicesStash" timestamp without time zone,
     "HasAttendedDemoMeetingToTestAdvisoryRoomOn" timestamp without time zone,
     "MeetMeServiceIntentionallyTrashed" timestamp without time zone
 );


 --
 -- TOC entry 276 (class 1259 OID 509245)
 -- Name: AccountStatusTenantAware; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."AccountStatusTenantAware" (
     "Id" integer NOT NULL,
     "IsSavingExpertServicesStartDateOrNull" timestamp without time zone,
     "IsProfileInfoCompleteDateOrNull" timestamp without time zone,
     "ServicesLastPublishDateOrNull" timestamp without time zone,
     "IsEthicsAgreementAcceptedDateOrNull" timestamp without time zone,
     "TermsAndConditionsLatestApproval" timestamp without time zone NOT NULL,
     "PrivacyPolicyLatestApproval" timestamp without time zone NOT NULL,
     "MarketingLatestApproval" timestamp without time zone,
     "CreationDateOrDefault" timestamp without time zone NOT NULL,
     "LastSavingDateAccount" timestamp without time zone NOT NULL,
     "ActivelyPreventFromListingFrom" timestamp without time zone,
     "ActivelyPreventFromListingTill" timestamp without time zone,
     "IsVerified" timestamp without time zone,
     "VerifiedUntil" timestamp without time zone,
     "IsPremium" timestamp without time zone,
     "PremiumUntil" timestamp without time zone,
     "IsPricingPrerequisitesDataPresentSinceDateOrNull" timestamp without time zone,
     "HybridAccountLastSelectedTab" integer DEFAULT 0 NOT NULL,
     "HybridAccountUpgradeOn" timestamp without time zone,
     "HybridAccountAppliedForUpgradeOn" timestamp without time zone
 );


 --
 -- TOC entry 275 (class 1259 OID 509243)
 -- Name: AccountStatusTenantAware_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."AccountStatusTenantAware" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."AccountStatusTenantAware_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 225 (class 1259 OID 340339)
 -- Name: AccountStatus_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."AccountStatus" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."AccountStatus_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 392 (class 1259 OID 3075734)
 -- Name: AccountView; Type: VIEW; Schema: public; Owner: -
 --

 CREATE VIEW public."AccountView" AS
 SELECT
     NULL::integer AS "AccountId",
     NULL::text AS "FirstName",
     NULL::text AS "LastName",
     NULL::text AS "FullName",
     NULL::text AS "CompanyNameOrNull",
     NULL::timestamp without time zone AS "SignUpDate",
     NULL::bigint AS "BookedByCount",
     NULL::bigint AS "BookingsMadeCount",
     NULL::timestamp without time zone AS "FirstBookedDate",
     NULL::timestamp without time zone AS "FirstBookingMadeDate",
     NULL::timestamp without time zone AS "LastBookedDate",
     NULL::timestamp without time zone AS "LastBookingMadeDate",
     NULL::boolean AS "MarkedForDeletion",
     NULL::integer AS "UserTypeEnum",
     NULL::text AS "ConnectedHubs",
     NULL::jsonb AS "ConnectedHubsList";


 --
 -- TOC entry 380 (class 1259 OID 2463416)
 -- Name: AnonymousUserEventTrackingPerDaySet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."AnonymousUserEventTrackingPerDaySet" (
     "Id" bigint NOT NULL,
     "CreationDay" date NOT NULL,
     "TenantIdentifier" text
 );


 --
 -- TOC entry 379 (class 1259 OID 2463414)
 -- Name: AnonymousUserEventTrackingPerDaySet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."AnonymousUserEventTrackingPerDaySet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."AnonymousUserEventTrackingPerDaySet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 378 (class 1259 OID 2463406)
 -- Name: AnonymousUserEventTrackingSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."AnonymousUserEventTrackingSet" (
     "Id" bigint NOT NULL,
     "UserEventTrackingTypeEnum" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "TenantIdentifier" text,
     "CountryCode" text,
     "ServiceId" bigint,
     "AnonymousUserEventTrackingPerDaySetId" bigint
 );


 --
 -- TOC entry 377 (class 1259 OID 2463404)
 -- Name: AnonymousUserEventTrackingSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."AnonymousUserEventTrackingSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."AnonymousUserEventTrackingSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 321 (class 1259 OID 1560295)
 -- Name: AppliedCouponConnection; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."AppliedCouponConnection" (
     "Id" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "CouponId" integer,
     "PurchaseSetId" integer
 );


 --
 -- TOC entry 320 (class 1259 OID 1560293)
 -- Name: AppliedCouponConnection_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."AppliedCouponConnection" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."AppliedCouponConnection_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 341 (class 1259 OID 1561220)
 -- Name: BookingRequestSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."BookingRequestSet" (
     "Id" bigint NOT NULL,
     "TenantIdentifier" text,
     "CreationDate" timestamp without time zone NOT NULL,
     "RequestId" uuid NOT NULL,
     "Firstname" text,
     "ServiceTypeTranslationKey" text,
     "ServiceTypeCategoryTranslationKey" text,
     "LocationCountryCode" text,
     "PreferedLanguagesLanguageCodesSemicolonSeparated" text,
     "SelectedServiceId" bigint NOT NULL,
     "SelectedExpertId" integer,
     "PaymentInformationId" integer,
     "Goal1ServiceTypeTranslationKey" text,
     "Goal2ServiceTypeTranslationKey" text,
     "Goal3ServiceTypeTranslationKey" text,
     "AppointmentSuggestion1Id" uuid,
     "AppointmentSuggestion2Id" uuid,
     "AppointmentSuggestion3Id" uuid,
     "SummaryConfirmedDate" timestamp without time zone,
     "CreatorId" integer,
     "AdditionalInformationAboutProject" text,
     "Upload1Id" integer,
     "Upload2Id" integer,
     "Upload3Id" integer,
     "UploadAdditionScreenShownToRequestor" boolean DEFAULT false NOT NULL,
     "FinishedDate" timestamp without time zone,
     "ProjectSetId" integer,
     "OneTimePurchaseMicroadvisorySessionProductId" integer,
     "AppliedCoupons" text[],
     "CustomOfferExistingServiceSetId" bigint
 );


 --
 -- TOC entry 340 (class 1259 OID 1561218)
 -- Name: BookingRequestSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."BookingRequestSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."BookingRequestSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 343 (class 1259 OID 1561296)
 -- Name: BookmarkConnectionExpertStaticSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."BookmarkConnectionExpertStaticSet" (
     "Id" bigint NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "FromAccountId" integer,
     "TenantIdentifier" text,
     "BookmarkConnectionTypeEnum" integer NOT NULL,
     "BookmarkedAccountId" integer
 );


 --
 -- TOC entry 342 (class 1259 OID 1561294)
 -- Name: BookmarkConnectionExpertStaticSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."BookmarkConnectionExpertStaticSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."BookmarkConnectionExpertStaticSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 313 (class 1259 OID 1560013)
 -- Name: BookmarkConnectionServiceStaticSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."BookmarkConnectionServiceStaticSet" (
     "Id" bigint NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "FromAccountId" integer,
     "TenantIdentifier" text,
     "BookmarkConnectionTypeEnum" integer NOT NULL,
     "BookmarkedServiceId" bigint
 );


 --
 -- TOC entry 312 (class 1259 OID 1560011)
 -- Name: BookmarkConnectionStaticBase_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."BookmarkConnectionServiceStaticSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."BookmarkConnectionStaticBase_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 315 (class 1259 OID 1560033)
 -- Name: BookmarkConnectionWithHistoryBaseSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."BookmarkConnectionWithHistoryBaseSet" (
     "Id" bigint NOT NULL,
     "TenantIdentifier" text,
     "CreationDate" timestamp without time zone NOT NULL,
     "BookmarkingAccountId" integer,
     "BookmarkConnectionTypeEnum" integer NOT NULL,
     "Discriminator" text NOT NULL,
     "BookmarkActionTypeEnum" integer,
     "BookmarkedAccountId" integer,
     "BookmarkedServiceId" bigint
 );


 --
 -- TOC entry 314 (class 1259 OID 1560031)
 -- Name: BookmarkConnectionWithHistoryBaseSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."BookmarkConnectionWithHistoryBaseSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."BookmarkConnectionWithHistoryBaseSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 396 (class 1259 OID 3075763)
 -- Name: CognitoUserIdSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."CognitoUserIdSet" (
     "CognitoUserId" text NOT NULL,
     "AccountSetId" integer
 );


 --
 -- TOC entry 398 (class 1259 OID 3075778)
 -- Name: CognitoUsernameSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."CognitoUsernameSet" (
     "Id" integer NOT NULL,
     "Username" text,
     "CognitoUserIdSetCognitoUserId" text
 );


 --
 -- TOC entry 397 (class 1259 OID 3075776)
 -- Name: CognitoUsernameSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."CognitoUsernameSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."CognitoUsernameSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 364 (class 1259 OID 2359270)
 -- Name: ConversationMessageReadByAccountSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ConversationMessageReadByAccountSet" (
     "Id" integer NOT NULL,
     "AccountId" integer NOT NULL,
     "ConversationMessageId" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL
 );


 --
 -- TOC entry 363 (class 1259 OID 2359268)
 -- Name: ConversationMessageReadByAccountSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ConversationMessageReadByAccountSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ConversationMessageReadByAccountSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 362 (class 1259 OID 2359240)
 -- Name: ConversationMessageSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ConversationMessageSet" (
     "Id" integer NOT NULL,
     "ConversationSetId" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "MessageType" integer NOT NULL,
     "IsSent" boolean NOT NULL,
     "ReplyOnMessageId" integer,
     "CreatorAccountId" integer NOT NULL,
     "Discriminator" text NOT NULL,
     "TextContent" text,
     "MeetingInformationId" integer,
     "ConversationTextMessageSet_TextContent" text,
     "IsPinned" boolean DEFAULT false NOT NULL,
     "CustomOfferExistingServiceSetId" bigint
 );


 --
 -- TOC entry 361 (class 1259 OID 2359238)
 -- Name: ConversationMessageSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ConversationMessageSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ConversationMessageSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 359 (class 1259 OID 2359210)
 -- Name: ConversationSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ConversationSet" (
     "Id" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "ShouldNotifyAccountsAboutNewMessages" boolean NOT NULL,
     "DisplayName" text,
     "LastModifiedDate" timestamp without time zone NOT NULL,
     "ProjectId" integer,
     "IsPinned" boolean DEFAULT false NOT NULL,
     "ConversationTypeEnum" integer DEFAULT 0 NOT NULL,
     "CreatorAccountId" integer,
     "ServiceSearchSetId" bigint
 );


 --
 -- TOC entry 358 (class 1259 OID 2359208)
 -- Name: ConversationSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ConversationSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ConversationSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 319 (class 1259 OID 1560285)
 -- Name: Coupon; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."Coupon" (
     "Id" integer NOT NULL,
     "Identifier" text,
     "TenantIdentifier" text,
     "Amount" numeric NOT NULL,
     "StartDate" timestamp without time zone NOT NULL,
     "ExpirationDate" timestamp without time zone,
     "Currency" text,
     "CouponType" integer NOT NULL,
     "AllowCombineIdentifier" text,
     "CanBeUsedMultipleTimes" boolean DEFAULT false NOT NULL,
     "UsedCounter" integer DEFAULT 0 NOT NULL,
     "WasUsedAtLeastOnce" boolean DEFAULT false NOT NULL
 );


 --
 -- TOC entry 376 (class 1259 OID 2360268)
 -- Name: CouponPurchaseDetailsSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."CouponPurchaseDetailsSet" (
     "AppliedToPurchaseDetailsId" integer NOT NULL,
     "CouponsId" integer NOT NULL
 );


 --
 -- TOC entry 318 (class 1259 OID 1560283)
 -- Name: Coupon_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."Coupon" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."Coupon_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 226 (class 1259 OID 340341)
 -- Name: CustomAccountLinkSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."CustomAccountLinkSet" (
     "Id" integer NOT NULL,
     "CustomLinkUrlEncoded" text,
     "AccountSetId" integer,
     "CreationDate" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "Domain" text
 );


 --
 -- TOC entry 227 (class 1259 OID 340349)
 -- Name: CustomAccountLinkSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."CustomAccountLinkSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."CustomAccountLinkSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 389 (class 1259 OID 2662856)
 -- Name: CustomOfferConnectionStaticSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."CustomOfferConnectionStaticSet" (
     "Id" bigint NOT NULL,
     "TenantIdentifier" text,
     "CreationDate" timestamp without time zone NOT NULL,
     "ForAccountSetId" integer,
     "CustomOfferConnectionTypeEnum" integer NOT NULL,
     "CustomOfferSetId" bigint
 );


 --
 -- TOC entry 388 (class 1259 OID 2662854)
 -- Name: CustomOfferConnectionStaticSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."CustomOfferConnectionStaticSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."CustomOfferConnectionStaticSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 387 (class 1259 OID 2662826)
 -- Name: CustomOfferSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."CustomOfferSet" (
     "Id" bigint NOT NULL,
     "CurrencyCode" text,
     "PriceInCurrency" numeric NOT NULL,
     "Title" text,
     "Description" text,
     "CreationDate" timestamp without time zone NOT NULL,
     "RestrictedToAccountsOrNull" integer[],
     "TenantIdentifier" text,
     "SecretKey" text NOT NULL,
     "Discriminator" text NOT NULL,
     "ServiceSearchSetId" bigint,
     "ClaimingLimit" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 386 (class 1259 OID 2662824)
 -- Name: CustomOfferSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."CustomOfferSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."CustomOfferSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 228 (class 1259 OID 340357)
 -- Name: Distinct_IndustryTypeTranslationKeys2; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."Distinct_IndustryTypeTranslationKeys2" (
     "ExpertAccountSetId" integer,
     "IndustryTypeTranslationKey" text
 );


 --
 -- TOC entry 403 (class 1259 OID 3165782)
 -- Name: ExpertView; Type: VIEW; Schema: public; Owner: -
 --

 CREATE VIEW public."ExpertView" AS
 SELECT
     NULL::integer AS "AccountId",
     NULL::bigint AS "AllBookingsCount",
     NULL::timestamp without time zone AS "FirstBookingDate",
     NULL::timestamp without time zone AS "LastBookingDate",
     NULL::boolean AS "MarkedForDeletion",
     NULL::timestamp without time zone AS "LastSavingDateAccount",
     NULL::timestamp without time zone AS "ServiceSettingsLastPostPublishInfoStash",
     NULL::timestamp without time zone AS "ServicesLastPublishDateOrNull";


 --
 -- TOC entry 278 (class 1259 OID 510144)
 -- Name: FaqCategorySet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."FaqCategorySet" (
     "Id" integer NOT NULL,
     "TranslationKey" text
 );


 --
 -- TOC entry 277 (class 1259 OID 510142)
 -- Name: FaqCategorySet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."FaqCategorySet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."FaqCategorySet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 280 (class 1259 OID 510154)
 -- Name: FaqSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."FaqSet" (
     "Id" integer NOT NULL,
     "FaqCategorySetId" integer,
     "TranslationKey" text,
     "HeadlineTranslationKey" text,
     "CategoryTranslationKey" text,
     "IsDisabled" boolean DEFAULT false NOT NULL
 );


 --
 -- TOC entry 279 (class 1259 OID 510152)
 -- Name: FaqSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."FaqSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."FaqSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 270 (class 1259 OID 431639)
 -- Name: FeaturedExpertsServiceSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."FeaturedExpertsServiceSet" (
     "Id" integer NOT NULL,
     "FeaturedExpertId" integer,
     "ServiceTypeTranslationKey" text,
     "ServiceTypeCategoryTranslationKey" text,
     "LanguageCountryCode" text
 );


 --
 -- TOC entry 269 (class 1259 OID 431637)
 -- Name: FeaturedExpertsServiceSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."FeaturedExpertsServiceSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."FeaturedExpertsServiceSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 229 (class 1259 OID 340381)
 -- Name: GeneralSettingsSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."GeneralSettingsSet" (
     "Id" integer NOT NULL,
     "FilledWithInitialData" integer NOT NULL,
     "ServiceSearchSetWasSuccessfullyMigrated" boolean DEFAULT false NOT NULL,
     "IsChatDisabled" boolean DEFAULT false NOT NULL,
     "AnyIndustryAddedToAllServicesAndAccountsMigrated" boolean DEFAULT false NOT NULL,
     "InitServiceKarmaMigrated" boolean DEFAULT false NOT NULL,
     "AccountDescriptionsMigrated" boolean DEFAULT false NOT NULL,
     "LikesToBookmarksMigrated" boolean DEFAULT false NOT NULL,
     "MigrationSettings" jsonb,
     "SearchPerPageBoostFactor" real DEFAULT 500 NOT NULL,
     "SearchPerPagePunishFactor" real DEFAULT 1 NOT NULL
 );


 --
 -- TOC entry 230 (class 1259 OID 340384)
 -- Name: GeneralSettingsSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."GeneralSettingsSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."GeneralSettingsSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 231 (class 1259 OID 340386)
 -- Name: GoalSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."GoalSet" (
     "Id" bigint NOT NULL,
     "Description" text,
     "CreationDate" timestamp without time zone NOT NULL,
     "CompletionDateOrNull" timestamp without time zone,
     "ServiceTypeTranslationKey" text,
     "ServiceTypeCategoryTranslationKey" text,
     "ServiceTypeEnumSetId" integer,
     "ProjectSetOrNullId" integer,
     "OwnerAccountSetId" integer,
     "ExpertAccountSetId" integer,
     "GoalTypeEnum" integer DEFAULT 0 NOT NULL,
     "Discriminator" text DEFAULT ''::text NOT NULL,
     "ParentGoalId" bigint
 );


 --
 -- TOC entry 232 (class 1259 OID 340394)
 -- Name: GoalSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."GoalSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."GoalSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 286 (class 1259 OID 510259)
 -- Name: HashtagConnectionSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."HashtagConnectionSet" (
     "Id" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "HashtagSetId" bigint DEFAULT 0,
     "AccountUsedItId" integer,
     "UserStorySetId" bigint DEFAULT 0,
     "Hashtag" text,
     "HashtagNormalizedLowercase" text,
     "Discriminator" text DEFAULT ''::text NOT NULL,
     "MentionConnectionTypeEnum" integer DEFAULT 0 NOT NULL,
     "TenantIdentifier" text
 );


 --
 -- TOC entry 285 (class 1259 OID 510257)
 -- Name: HashtagConnectionSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."HashtagConnectionSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."HashtagConnectionSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 282 (class 1259 OID 510218)
 -- Name: HashtagSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."HashtagSet" (
     "Id" bigint NOT NULL,
     "Hashtag" text,
     "HashtagNormalizedLowercase" text,
     "UsedInTextCounter" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "FirstCreatedById" integer,
     "UpdateDate" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL
 );


 --
 -- TOC entry 281 (class 1259 OID 510216)
 -- Name: HashtagSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."HashtagSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."HashtagSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 357 (class 1259 OID 2259129)
 -- Name: HubspotMappingSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."HubspotMappingSet" (
     "Id" integer NOT NULL,
     "HubspotId" text,
     "HalloSophiaId" text,
     "HubspotMappingTypeEnum" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "LastModifiedDate" timestamp without time zone NOT NULL,
     "NameOfTargetTableHelperField" text,
     "ObjectHash" text
 );


 --
 -- TOC entry 356 (class 1259 OID 2259127)
 -- Name: HubspotMappingSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."HubspotMappingSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."HubspotMappingSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 311 (class 1259 OID 574907)
 -- Name: InviteConnectionSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."InviteConnectionSet" (
     "Id" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "InviteConnectionTypeEnum" integer NOT NULL,
     "Discriminator" text NOT NULL,
     "MeetingInformationSetId" integer,
     "GuestJoinKey" text,
     "GuestName" text,
     "ApiResponseSecretData" jsonb,
     "IsDisabled" boolean,
     "TenantIdentifier" text,
     "AccountId" integer,
     "CompanyName" text,
     "InvitationStatus" integer DEFAULT 0 NOT NULL,
     "KycCompanyId" integer,
     "RegistrationWaitinglistEntrySetId" integer,
     "Role" integer,
     "InviterId" integer
 );


 --
 -- TOC entry 310 (class 1259 OID 574905)
 -- Name: InviteConnectionSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."InviteConnectionSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."InviteConnectionSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 355 (class 1259 OID 2243674)
 -- Name: KycCompany; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."KycCompany" (
     "Id" integer NOT NULL,
     "Name" text DEFAULT ''::text NOT NULL,
     "OwnerId" integer DEFAULT 0 NOT NULL,
     "MangopayInfoId" integer,
     "VatNumber" text
 );


 --
 -- TOC entry 400 (class 1259 OID 3075821)
 -- Name: KycCompanyConnectionAccountStaticSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."KycCompanyConnectionAccountStaticSet" (
     "Id" integer NOT NULL,
     "AccountId" integer NOT NULL,
     "KycCompanyId" integer NOT NULL,
     "TenantIdentifier" text,
     "CreationDate" timestamp without time zone NOT NULL,
     "Status" integer NOT NULL,
     "Role" integer NOT NULL,
     "CanEarn" boolean NOT NULL,
     "CanWithdraw" boolean NOT NULL,
     "CanEditUsers" boolean NOT NULL,
     "WithdrawLimit" numeric,
     "AdvisorWalletId" text
 );


 --
 -- TOC entry 399 (class 1259 OID 3075819)
 -- Name: KycCompanyConnectionAccountStaticSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."KycCompanyConnectionAccountStaticSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."KycCompanyConnectionAccountStaticSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 402 (class 1259 OID 3075841)
 -- Name: KycCompanyStashSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."KycCompanyStashSet" (
     "Id" integer NOT NULL,
     "OwnerId" integer NOT NULL,
     "PersonType" integer NOT NULL,
     "KycFlowStatus" integer NOT NULL,
     "LegalPersonType" integer NOT NULL,
     "IsRepresentative" boolean NOT NULL,
     "MangopayUserInfoJs" jsonb
 );


 --
 -- TOC entry 401 (class 1259 OID 3075839)
 -- Name: KycCompanyStashSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."KycCompanyStashSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."KycCompanyStashSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 354 (class 1259 OID 2243672)
 -- Name: KycCompany_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."KycCompany" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."KycCompany_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 347 (class 1259 OID 1648000)
 -- Name: KycDocumentSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."KycDocumentSet" (
     "Id" integer NOT NULL,
     "KycDocumentId" integer,
     "DocumentType" text,
     "AccountSetId" integer,
     "CreationDate" timestamp without time zone NOT NULL,
     "KycCompanyId" integer
 );


 --
 -- TOC entry 346 (class 1259 OID 1647998)
 -- Name: KycDocumentSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."KycDocumentSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."KycDocumentSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 384 (class 1259 OID 2477119)
 -- Name: LegalDocumentSequenceSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."LegalDocumentSequenceSet" (
     "Id" integer NOT NULL,
     "Prefix" text,
     "SequenceNumber" integer NOT NULL,
     "DocumentId" integer,
     "OverflowCount" integer DEFAULT 0 NOT NULL,
     "LegalDocumentTypeEnum" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 383 (class 1259 OID 2477117)
 -- Name: LegalDocumentSequenceSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."LegalDocumentSequenceSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."LegalDocumentSequenceSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 382 (class 1259 OID 2477097)
 -- Name: LegalDocumentSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."LegalDocumentSet" (
     "Id" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "LegalDocumentTypeEnum" integer NOT NULL,
     "CreatorAccountId" integer,
     "DocumentId" integer,
     "ProjectId" integer
 );


 --
 -- TOC entry 381 (class 1259 OID 2477095)
 -- Name: LegalDocumentSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."LegalDocumentSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."LegalDocumentSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 233 (class 1259 OID 340404)
 -- Name: LikeAndFollowExpertHistory; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."LikeAndFollowExpertHistory" (
     "Id" integer NOT NULL,
     "LikeAndFollowTypeEnum" integer NOT NULL,
     "LikerAccountId" integer,
     "LikedAccountId" integer,
     "DateOfAction" timestamp without time zone NOT NULL
 );


 --
 -- TOC entry 234 (class 1259 OID 340407)
 -- Name: LikeAndFollowExpertHistory_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."LikeAndFollowExpertHistory" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."LikeAndFollowExpertHistory_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 305 (class 1259 OID 558823)
 -- Name: MangpayInfo; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."MangpayInfo" (
     "Id" integer NOT NULL,
     "UserId" text NOT NULL,
     "BankAccountId" text,
     "WalletId" text,
     "CardId" text,
     "VATInPercent" numeric DEFAULT 0.0 NOT NULL,
     "PersonType" integer DEFAULT 0 NOT NULL,
     "KycFlowStatus" integer DEFAULT 0 NOT NULL,
     "MangopayUserInfoJs" jsonb
 );


 --
 -- TOC entry 304 (class 1259 OID 558821)
 -- Name: MangpayInfo_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."MangpayInfo" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."MangpayInfo_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 235 (class 1259 OID 340409)
 -- Name: MeetingInformationSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."MeetingInformationSet" (
     "Id" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "JoinKey" text,
     "AppointmentDateIfFinalized" timestamp without time zone,
     "AppointmentDateCurrentOrLastFinalizedDate" timestamp without time zone,
     "AppointmentStatusEnum" integer NOT NULL,
     "AlternativeVideoPlatformRoomUrl" text,
     "MeetingCreationApiResponseSecretData" text,
     "MeetingStartDate" timestamp without time zone NOT NULL,
     "MeetingEndDate" timestamp without time zone NOT NULL,
     "MeetingDurationInMinutes" integer NOT NULL,
     "CustomInviteMessageByCreator" text,
     "RoomName" text,
     "CreatorId" integer,
     "OwnMeetingLinkOrNull" text,
     "AlternativeMeetingType" integer DEFAULT 0 NOT NULL,
     "PricingTypeEnum" integer DEFAULT 0 NOT NULL,
     "PaymentInformationId" integer,
     "IcsSequence" integer DEFAULT 0 NOT NULL,
     "IcsUid" uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
     "TenantId" integer,
     "IsDemomeeting" boolean DEFAULT false NOT NULL,
     "RoomJoiningStrategyEnum" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 236 (class 1259 OID 340416)
 -- Name: MeetingInformationSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."MeetingInformationSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."MeetingInformationSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 237 (class 1259 OID 340418)
 -- Name: MeetingWhitelistAccountEntrySet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."MeetingWhitelistAccountEntrySet" (
     "Id" integer NOT NULL,
     "MeetingInformationSetId" integer,
     "AccountSetId" integer
 );


 --
 -- TOC entry 238 (class 1259 OID 340421)
 -- Name: MeetingWhitelistAccountEntrySet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."MeetingWhitelistAccountEntrySet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."MeetingWhitelistAccountEntrySet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 239 (class 1259 OID 340423)
 -- Name: MeetingWhitelistEmailEntrySet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."MeetingWhitelistEmailEntrySet" (
     "Id" integer NOT NULL,
     "MeetingInformationSetId" integer,
     "Email" text
 );


 --
 -- TOC entry 240 (class 1259 OID 340429)
 -- Name: MeetingWhitelistEmailEntrySet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."MeetingWhitelistEmailEntrySet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."MeetingWhitelistEmailEntrySet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 241 (class 1259 OID 340431)
 -- Name: MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet" (
     "Id" bigint NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "AccountRequestBelongsToOrNull" integer,
     "RequestId" uuid NOT NULL,
     "Firstname" text,
     "ServiceTypeTranslationKey" text,
     "ServiceTypeCategoryTranslationKey" text,
     "LocationCountryCode" text,
     "PreferedLanguagesLanguageCodesSemicolonSeparated" text,
     "IndustryTypeTranslationKey" text,
     "SelectedExpertId" integer,
     "AppointmentSuggestion1Id" uuid,
     "AppointmentSuggestion2Id" uuid,
     "AppointmentSuggestion3Id" uuid,
     "AccountSetId" integer,
     "Goal1ServiceTypeTranslationKey" text,
     "Goal2ServiceTypeTranslationKey" text,
     "Goal3ServiceTypeTranslationKey" text,
     "MatchingTypeEnum" integer DEFAULT 0 NOT NULL,
     "PaymentInformationId" integer,
     "CustomIndustryType" text,
     "TenantIdentifier" text,
     "SummaryConfirmedDate" timestamp without time zone,
     "SelectedServiceId" bigint DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 242 (class 1259 OID 340438)
 -- Name: MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 243 (class 1259 OID 340440)
 -- Name: NotificationSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."NotificationSet" (
     "Id" integer NOT NULL,
     "NotificationTypeEnum" integer NOT NULL,
     "ProjectId" integer,
     "AccountId" integer,
     "Message" text,
     "CreationDate" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "Discriminator" text DEFAULT ''::text NOT NULL,
     "ReadDate" timestamp without time zone,
     "MeetingInformationId" integer,
     "SenderId" integer,
     "PriorId" integer
 );


 --
 -- TOC entry 244 (class 1259 OID 340448)
 -- Name: NotificationSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."NotificationSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."NotificationSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 353 (class 1259 OID 2195996)
 -- Name: OfficeHoursBreakSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."OfficeHoursBreakSet" (
     "Id" integer NOT NULL,
     "DayOfWeek" integer NOT NULL,
     "FromTimeUtc" interval NOT NULL,
     "TillTimeUtc" interval NOT NULL,
     "ExpertAccountSetId" integer NOT NULL
 );


 --
 -- TOC entry 352 (class 1259 OID 2195994)
 -- Name: OfficeHoursBreakSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."OfficeHoursBreakSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."OfficeHoursBreakSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 245 (class 1259 OID 340450)
 -- Name: OfficeHoursSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."OfficeHoursSet" (
     "Id" integer NOT NULL,
     "MondayIsWorkday" boolean NOT NULL,
     "TuesdayIsWorkday" boolean NOT NULL,
     "WednesdayIsWorkday" boolean NOT NULL,
     "ThursdayIsWorkday" boolean NOT NULL,
     "FridayIsWorkday" boolean NOT NULL,
     "SaturdayIsWorkday" boolean NOT NULL,
     "SundayIsWorkday" boolean NOT NULL,
     "MondayFromTimeUtc" interval,
     "MondayTillTimeUtc" interval,
     "TuesdayFromTimeUtc" interval,
     "TuesdayTillTimeUtc" interval,
     "WednesdayFromTimeUtc" interval,
     "WednesdayTillTimeUtc" interval,
     "ThursdayFromTimeUtc" interval,
     "ThursdayTillTimeUtc" interval,
     "FridayFromTimeUtc" interval,
     "FridayTillTimeUtc" interval,
     "SaturdayFromTimeUtc" interval,
     "SaturdayTillTimeUtc" interval,
     "SundayFromTimeUtc" interval,
     "SundayTillTimeUtc" interval,
     "ExpertAccountSetId" integer,
     "ProfileName" text,
     "TimeZoneOffsetOrNull" text,
     "TimeZoneResolvedOrNull" text
 );


 --
 -- TOC entry 246 (class 1259 OID 340456)
 -- Name: OfficeHoursSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."OfficeHoursSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."OfficeHoursSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 406 (class 1259 OID 3281851)
 -- Name: OpenAiGeneralSettingsSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."OpenAiGeneralSettingsSet" (
     "Id" integer NOT NULL,
     "Temperature" double precision NOT NULL,
     "Frequency" double precision NOT NULL,
     "Presence" double precision NOT NULL
 );


 --
 -- TOC entry 405 (class 1259 OID 3281849)
 -- Name: OpenAiGeneralSettingsSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."OpenAiGeneralSettingsSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."OpenAiGeneralSettingsSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 391 (class 1259 OID 3075702)
 -- Name: PaymentAvailabilityInCountrySet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."PaymentAvailabilityInCountrySet" (
     "Id" integer NOT NULL,
     "CountryCode" text,
     "CreationDate" timestamp without time zone NOT NULL,
     "PayNowEnabled" boolean NOT NULL,
     "PayLaterEnabled" boolean NOT NULL,
     "LastModifiedDate" timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL
 );


 --
 -- TOC entry 390 (class 1259 OID 3075700)
 -- Name: PaymentAvailabilityInCountrySet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."PaymentAvailabilityInCountrySet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."PaymentAvailabilityInCountrySet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 266 (class 1259 OID 361446)
 -- Name: PaymentInformationSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."PaymentInformationSet" (
     "Id" integer NOT NULL,
     "VatNumber" text,
     "CountryCode" text,
     "State" text,
     "Street" text,
     "Building" text,
     "Apartment" text,
     "PostalCode" text,
     "CreationDate" timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL,
     "CompanyNameOrNull" text
 );


 --
 -- TOC entry 265 (class 1259 OID 361444)
 -- Name: PaymentInformations_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."PaymentInformationSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."PaymentInformations_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 299 (class 1259 OID 556716)
 -- Name: Product; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."Product" (
     "Id" integer NOT NULL,
     "Identifier" text NOT NULL,
     "CurrencyCode" text,
     "ProductType" integer NOT NULL,
     "NextIdentifier" text,
     "Disabled" boolean NOT NULL,
     "AssignedToId" integer,
     "Discriminator" text DEFAULT ''::text NOT NULL,
     "ServiceId" bigint,
     "YearAdvanceBenefit" integer,
     "YearlyPayments" boolean DEFAULT false NOT NULL,
     "TenantSetId" integer,
     "NetBasePrice" numeric DEFAULT 0.0 NOT NULL
 );


 --
 -- TOC entry 301 (class 1259 OID 556726)
 -- Name: ProductList; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ProductList" (
     "Id" integer NOT NULL,
     "Identifier" text
 );


 --
 -- TOC entry 300 (class 1259 OID 556724)
 -- Name: ProductList_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ProductList" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ProductList_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 303 (class 1259 OID 556761)
 -- Name: ProductToProductList; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ProductToProductList" (
     "Id" integer NOT NULL,
     "ProductId" integer,
     "ProductListId" integer
 );


 --
 -- TOC entry 302 (class 1259 OID 556759)
 -- Name: ProductToProductList_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ProductToProductList" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ProductToProductList_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 298 (class 1259 OID 556714)
 -- Name: Product_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."Product" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."Product_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 247 (class 1259 OID 340458)
 -- Name: ProjectSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ProjectSet" (
     "Id" integer NOT NULL,
     "SophiaRequestId" uuid NOT NULL,
     "LocationCountryCode" text,
     "CreationDate" timestamp without time zone NOT NULL,
     "PreferedLanguagesLanguageCodesSemicolonSeparated" text,
     "AdditionalInformationAboutProject" text,
     "DataCanBeForwardedToExternalPartyApprovedOn" timestamp without time zone NOT NULL,
     "RequestorId" integer,
     "ExpertId" integer,
     "MeetingInformationId" integer,
     "ServiceTypeTranslationKey" text,
     "ServiceTypeCategoryTranslationKey" text,
     "Upload1Id" integer,
     "Upload2Id" integer,
     "Upload3Id" integer,
     "ReasonForCancelation" text,
     "ServiceId" bigint
 );


 --
 -- TOC entry 248 (class 1259 OID 340465)
 -- Name: ProjectSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ProjectSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ProjectSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 395 (class 1259 OID 3075749)
 -- Name: PromptEngineeringAiSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."PromptEngineeringAiSet" (
     "Id" integer NOT NULL,
     "Question" text,
     "Answer" text,
     "CreationDate" timestamp without time zone NOT NULL,
     "LastModifiedDate" timestamp without time zone NOT NULL
 );


 --
 -- TOC entry 394 (class 1259 OID 3075747)
 -- Name: PromptEngineeringAiSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."PromptEngineeringAiSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."PromptEngineeringAiSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 385 (class 1259 OID 2655697)
 -- Name: Purchase; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."Purchase" (
     "Id" integer NOT NULL,
     "BuyerId" integer,
     "BeneficiaryId" integer,
     "ProductId" integer,
     "PurchasePriceInCurrency" numeric NOT NULL,
     "CurrencyCode" text,
     "OrderDate" timestamp without time zone NOT NULL,
     "TenantIdentifier" text,
     "Discriminator" text NOT NULL,
     "SubscriptionStart" timestamp without time zone,
     "SubscriptionEnd" timestamp without time zone,
     "NextBillingDate" timestamp without time zone,
     "CancelDate" timestamp without time zone,
     "CancelationReason" text,
     "Status" integer,
     "PayinId" text,
     "ProductIdentifier" text,
     "WalletId" text,
     "PurchaseStatus" integer DEFAULT 0 NOT NULL,
     "BoughtProductId" integer,
     "ProjectSetId" integer,
     "PurchaseDetailsId" integer,
     "ReleaseTransactionId" text,
     "SplitTransactionId" text
 );


 --
 -- TOC entry 375 (class 1259 OID 2360235)
 -- Name: PurchaseDetailsSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."PurchaseDetailsSet" (
     "Id" integer NOT NULL,
     "SupplierTransactionDetailsId" integer DEFAULT 0 NOT NULL,
     "IsSupplierTaxExempt" boolean NOT NULL,
     "TenantTransactionDetailsId" integer DEFAULT 0 NOT NULL,
     "MainPlatformTransactionDetailsId" integer DEFAULT 0 NOT NULL,
     "CurrencyCode" text,
     "NetBasePrice" numeric NOT NULL,
     "NetReducedPrice" numeric,
     "NetDiscount" numeric,
     "NetTotalAmount" numeric NOT NULL,
     "GrossTotalAmount" numeric NOT NULL,
     "SmartNetOrGrossAmount" numeric NOT NULL,
     "ShowGrossPrices" boolean NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "CreatorAccountId" integer NOT NULL,
     "TenantId" integer NOT NULL,
     "DescriptionsDict" jsonb,
     "Langs" text[]
 );


 --
 -- TOC entry 374 (class 1259 OID 2360233)
 -- Name: PurchaseDetailsSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."PurchaseDetailsSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."PurchaseDetailsSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 249 (class 1259 OID 340475)
 -- Name: RegistrationWaitinglist; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."RegistrationWaitinglist" (
     "Id" integer NOT NULL,
     "FutureUsername" text,
     "InvitationStatus" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 250 (class 1259 OID 340481)
 -- Name: RegistrationWaitinglist_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."RegistrationWaitinglist" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."RegistrationWaitinglist_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 393 (class 1259 OID 3075743)
 -- Name: RequestorView; Type: VIEW; Schema: public; Owner: -
 --

 CREATE VIEW public."RequestorView" AS
  SELECT "AccountView"."AccountId",
     "AccountView"."FirstName",
     "AccountView"."LastName",
     "AccountView"."FullName",
     "AccountView"."CompanyNameOrNull",
     "AccountView"."SignUpDate",
     "AccountView"."BookedByCount",
     "AccountView"."BookingsMadeCount",
     "AccountView"."FirstBookedDate",
     "AccountView"."FirstBookingMadeDate",
     "AccountView"."LastBookedDate",
     "AccountView"."LastBookingMadeDate",
     "AccountView"."MarkedForDeletion",
     "AccountView"."UserTypeEnum",
     "AccountView"."ConnectedHubs",
     "AccountView"."ConnectedHubsList"
    FROM public."AccountView"
   WHERE (("AccountView"."UserTypeEnum" & 1) = 1);


 --
 -- TOC entry 293 (class 1259 OID 556144)
 -- Name: RevenueCutGeneral; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."RevenueCutGeneral" (
     "Id" integer NOT NULL,
     "SophiaCut" numeric NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "FromAccountSet" integer DEFAULT 0 NOT NULL,
     "UntilAccountSet" integer DEFAULT 0 NOT NULL,
     "CreatedById" integer DEFAULT 0 NOT NULL,
     "DateUntil" timestamp without time zone
 );


 --
 -- TOC entry 292 (class 1259 OID 556142)
 -- Name: RevenueCutGeneral_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."RevenueCutGeneral" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."RevenueCutGeneral_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 295 (class 1259 OID 556210)
 -- Name: RevenueCutTenant; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."RevenueCutTenant" (
     "Id" integer NOT NULL,
     "SophiaCut" numeric NOT NULL,
     "TenantId" integer,
     "CreationDate" timestamp without time zone NOT NULL,
     "FromAccountSet" integer DEFAULT 0 NOT NULL,
     "UntilAccountSet" integer DEFAULT 0 NOT NULL,
     "CreatedById" integer DEFAULT 0 NOT NULL,
     "DateUntil" timestamp without time zone
 );


 --
 -- TOC entry 294 (class 1259 OID 556208)
 -- Name: RevenueCutTenant_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."RevenueCutTenant" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."RevenueCutTenant_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 268 (class 1259 OID 387075)
 -- Name: SearchTermsLog; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."SearchTermsLog" (
     "Id" integer NOT NULL,
     "PerformedSearchTerm" text,
     "ServiceTypesCount" integer NOT NULL,
     "LocationCountryCode" text,
     "LanguageCountryCode" text,
     "DateTime" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "TenantIdentifier" text,
     "DisplayedResultsCount" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 267 (class 1259 OID 387073)
 -- Name: SearchTermsLog_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."SearchTermsLog" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."SearchTermsLog_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 291 (class 1259 OID 555339)
 -- Name: ServiceRatingAfterMeetingSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceRatingAfterMeetingSet" (
     "Id" integer NOT NULL,
     "AccountThatVotedId" integer,
     "AccountToRateId" integer,
     "MeetingInformationSetId" integer,
     "VotingDate" timestamp without time zone NOT NULL,
     "StarsRating" integer NOT NULL,
     "IsAdvisorPresent" boolean NOT NULL,
     "IsWithTechnicalDifficulties" boolean NOT NULL,
     "TechnicalFeedback" text,
     "TeamFeedback" text,
     "IsSessionGoodConclusion" boolean NOT NULL,
     "IsGenerallySatisfied" boolean DEFAULT false NOT NULL
 );


 --
 -- TOC entry 290 (class 1259 OID 555337)
 -- Name: ServiceRatingAfterMeetingSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceRatingAfterMeetingSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceRatingAfterMeetingSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 262 (class 1259 OID 359681)
 -- Name: ServiceSearchSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceSearchSet" (
     "Id" bigint NOT NULL,
     "ExpertAccountSetId" integer,
     "ServiceTypeTranslationKey" text,
     "ServiceTypeCategoryTranslationKey" text,
     "ServiceTypeSynonymsJs" jsonb,
     "PriceInCurrency" numeric NOT NULL,
     "PriceInCurrencyOverride" numeric,
     "CurrencyCode" text,
     "LocationCountryCode" text,
     "LocationCountryCodeJs" jsonb,
     "LanguageCountryCode" text,
     "LanguageCountryCodeJs" jsonb,
     "ServiceDescriptionsJs" jsonb,
     "ExpertLevelTypeEnum" integer NOT NULL,
     "PricingTypeEnum" integer NOT NULL,
     "OfficeHoursJs" jsonb,
     "MeetingDurationInMinutes" integer NOT NULL,
     "MeetingDurationInMinutesOverride" integer,
     "ServiceDescriptionsJs_value1_english" text,
     "ServiceDescriptionsJs_value1_german" text,
     "ServiceDescriptionsJs_value2_english" text,
     "ServiceDescriptionsJs_value2_german" text,
     "ServiceTypeSynonymsJs_value1_english" text,
     "ServiceTypeSynonymsJs_value1_german" text,
     "ServiceDescriptionsJs_value3_english" text,
     "ServiceDescriptionsJs_value3_german" text,
     "ServiceTypeSynonymsTs_english" tsvector GENERATED ALWAYS AS (to_tsvector('english'::regconfig, "ServiceTypeSynonymsJs_value1_english")) STORED,
     "ServiceTypeSynonymsTs_german" tsvector GENERATED ALWAYS AS (to_tsvector('english'::regconfig, "ServiceTypeSynonymsJs_value1_german")) STORED,
     "LocationCountryCodeTs" tsvector GENERATED ALWAYS AS (to_tsvector('simple'::regconfig, "LocationCountryCode")) STORED,
     "LanguageCountryCodeTs" tsvector GENERATED ALWAYS AS (to_tsvector('simple'::regconfig, "LanguageCountryCode")) STORED,
     "LastModifiedDate" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "Disabled" boolean DEFAULT false NOT NULL,
     "DateTimeKarmaSeed" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "DateTimeKarma_english" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "DateTimeKarma_german" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "KarmaCriteria" text[],
     "ServiceTypeTranslationJs" jsonb,
     "ServiceTypeTranslationJs_english" tsvector,
     "ServiceTypeTranslationJs_german" tsvector,
     "ServiceTypeTranslationJs_value1_english" text,
     "ServiceTypeTranslationJs_value1_german" text,
     "DateTimeKarma_english_number" bigint DEFAULT 0 NOT NULL,
     "DateTimeKarma_german_number" bigint DEFAULT 0 NOT NULL,
     "AccountDescriptionsJs" jsonb,
     "AccountDescriptionsJs_value1_english" text,
     "AccountDescriptionsJs_value1_german" text,
     "AccountDescriptionsJs_value2_english" text,
     "AccountDescriptionsJs_value2_german" text,
     "AccountDescriptionsJs_value3_english" text,
     "AccountDescriptionsJs_value3_german" text,
     "AccountDescriptionsJs_value4_english" text,
     "AccountDescriptionsJs_value4_german" text,
     "CompanyNameOrNull" text,
     "Firstname" text,
     "Lastname" text,
     "SearchFieldsTs_english" tsvector GENERATED ALWAYS AS (((to_tsvector('english'::regconfig, ((((((((((((((((((((COALESCE("ServiceDescriptionsJs_value1_english", ''::text) || ' '::text) || COALESCE("ServiceDescriptionsJs_value2_english", ''::text)) || ' '::text) || COALESCE("ServiceDescriptionsJs_value3_english", ''::text)) || ' '::text) || COALESCE("ServiceTypeSynonymsJs_value1_english", ''::text)) || ' '::text) || COALESCE("Firstname", ''::text)) || ' '::text) || COALESCE("Lastname", ''::text)) || ' '::text) || COALESCE("CompanyNameOrNull", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value1_english", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value2_english", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value3_english", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value4_english", ''::text))) || ''::tsvector) || COALESCE("ServiceTypeTranslationJs_english", ''::tsvector))) STORED,
     "SearchFieldsTs_german" tsvector GENERATED ALWAYS AS (((to_tsvector('german'::regconfig, ((((((((((((((((((((COALESCE("ServiceDescriptionsJs_value1_german", ''::text) || ' '::text) || COALESCE("ServiceDescriptionsJs_value2_german", ''::text)) || ' '::text) || COALESCE("ServiceDescriptionsJs_value3_german", ''::text)) || ' '::text) || COALESCE("ServiceTypeSynonymsJs_value1_german", ''::text)) || ' '::text) || COALESCE("Firstname", ''::text)) || ' '::text) || COALESCE("Lastname", ''::text)) || ' '::text) || COALESCE("CompanyNameOrNull", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value1_german", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value2_german", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value3_german", ''::text)) || ' '::text) || COALESCE("AccountDescriptionsJs_value4_german", ''::text))) || ''::tsvector) || COALESCE("ServiceTypeTranslationJs_german", ''::tsvector))) STORED,
     "PrimaryLanguage" character varying(7),
     "KarmaBoostCount_de" integer DEFAULT 0 NOT NULL,
     "KarmaBoostCount_en" integer DEFAULT 0 NOT NULL,
     "KarmaPunishCount_de" integer DEFAULT 0 NOT NULL,
     "KarmaPunishCount_en" integer DEFAULT 0 NOT NULL,
     "ConsultationTypeEnum" integer DEFAULT 0 NOT NULL,
     "CreationDate" timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL
 );


 --
 -- TOC entry 261 (class 1259 OID 359679)
 -- Name: ServiceSearchSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceSearchSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceSearchSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 253 (class 1259 OID 345797)
 -- Name: ServiceTypeEnumSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceTypeEnumSet" (
     "Id" integer NOT NULL,
     "TranslationKey" text,
     "ServiceTypeCategoryTranslationKey" text,
     "IsDisabled" boolean DEFAULT false NOT NULL,
     "ServiceTypeTranslationJs" jsonb,
     "ServiceTypeTranslationJs_value1_english" text,
     "ServiceTypeTranslationJs_value1_german" text,
     "IconId" integer,
     "ImageId" integer,
     "CreationDate" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "ServiceTypeSynonymsJs" jsonb,
     "ServiceTypeSynonymsJs_value1_english" text,
     "ServiceTypeSynonymsJs_value1_german" text,
     "SearchFieldsTs_english" tsvector GENERATED ALWAYS AS (to_tsvector('english'::regconfig, ((COALESCE("ServiceTypeTranslationJs_value1_english", ''::text) || ' '::text) || COALESCE("ServiceTypeSynonymsJs_value1_english", ''::text)))) STORED,
     "SearchFieldsTs_german" tsvector GENERATED ALWAYS AS (to_tsvector('german'::regconfig, ((COALESCE("ServiceTypeTranslationJs_value1_german", ''::text) || ' '::text) || COALESCE("ServiceTypeSynonymsJs_value1_german", ''::text)))) STORED
 );


 --
 -- TOC entry 404 (class 1259 OID 3165787)
 -- Name: ServiceSearchView; Type: VIEW; Schema: public; Owner: -
 --

 CREATE VIEW public."ServiceSearchView" AS
  SELECT DISTINCT service."Id" AS serviceid,
     innerquery."ServiceTypeTranslationKey",
     innerquery."ServiceTypeCategoryTranslationKey",
     innerquery.accountid,
     innerquery."ConsultationTypeEnum",
     innerquery.locationcountrycodes,
     innerquery.languagecountrycodes,
     innerquery.accountfirstname,
     innerquery.accountlastname,
     innerquery."CompanyNameOrNull",
     innerquery."SpokenLanguagesSemicolonSeparated",
     innerquery.isblocked,
     (innerquery.premiumon)::text AS premiumon,
     (innerquery.verifiedon)::text AS verifiedon,
     (innerquery.listedon)::text AS listedon,
     (innerquery.listedon)::jsonb AS listedonlist,
     innerquery.language,
     innerquery.creationdate,
     innerquery."AggregatedRecommendations",
     innerquery."AggregatedBookmarkedByAccounts",
     innerquery."AggregatedRating",
     innerquery."AggregatedNegativeRatings",
     innerquery."AggregatedPositiveRatings",
     innerquery."LastSavingDateAccount",
     innerquery."ServiceSettingsLastPostPublishInfoStash",
     innerquery."ServicesLastPublishDateOrNull",
     ( SELECT ((innertable2.dictelements -> 'Value'::text) ->> 'value1'::text)
            FROM ( SELECT json_array_elements((innertable.innerdict)::json) AS dictelements
                    FROM ( SELECT ((serviceinner."ServiceDescriptionsJs" -> 'descriptionDict'::text) -> 'valuesDict'::text) AS innerdict
                            FROM public."ServiceSearchSet" serviceinner
                           WHERE (serviceinner."Id" = service."Id")) innertable) innertable2
           WHERE (((innertable2.dictelements -> 'Value'::text) ->> 'lang'::text) = innerquery.language)) AS title,
     ( SELECT ((innertable2.dictelements -> 'Value'::text) ->> 'value2'::text)
            FROM ( SELECT json_array_elements((innertable.innerdict)::json) AS dictelements
                    FROM ( SELECT ((serviceinner."ServiceDescriptionsJs" -> 'descriptionDict'::text) -> 'valuesDict'::text) AS innerdict
                            FROM public."ServiceSearchSet" serviceinner
                           WHERE (serviceinner."Id" = service."Id")) innertable) innertable2
           WHERE (((innertable2.dictelements -> 'Value'::text) ->> 'lang'::text) = innerquery.language)) AS description,
     ( SELECT ((innertable2.dictelements -> 'Value'::text) ->> 'value3'::text) AS synonyms
            FROM ( SELECT json_array_elements((innertable.innerdict)::json) AS dictelements
                    FROM ( SELECT ((serviceinner."ServiceDescriptionsJs" -> 'descriptionDict'::text) -> 'valuesDict'::text) AS innerdict
                            FROM public."ServiceSearchSet" serviceinner
                           WHERE (serviceinner."Id" = service."Id")) innertable) innertable2
           WHERE (((innertable2.dictelements -> 'Value'::text) ->> 'lang'::text) = innerquery.language)) AS deliverables,
     ( SELECT ((innertable2.dictelements -> 'Value'::text) ->> 'value1'::text) AS synonyms
            FROM ( SELECT json_array_elements((innertable.innerdict)::json) AS dictelements
                    FROM ( SELECT ((servicetypeinner."ServiceTypeSynonymsJs" -> 'setviceTypeSynonymsDict'::text) -> 'valuesDict'::text) AS innerdict
                            FROM (public."ServiceSearchSet" serviceinner
                              JOIN public."ServiceTypeEnumSet" servicetypeinner ON ((serviceinner."ServiceTypeTranslationKey" = servicetypeinner."TranslationKey")))
                           WHERE (serviceinner."Id" = service."Id")
                          LIMIT 1) innertable) innertable2
           WHERE (((innertable2.dictelements -> 'Value'::text) ->> 'lang'::text) = innerquery.language)) AS servicetypesynonyms,
     ( SELECT ((innertable2.dictelements -> 'Value'::text) ->> 'value1'::text) AS synonyms
            FROM ( SELECT json_array_elements((innertable.innerdict)::json) AS dictelements
                    FROM ( SELECT ((servicetypeinner."ServiceTypeTranslationJs" -> 'serviceTypeTranslationDict'::text) -> 'valuesDict'::text) AS innerdict
                            FROM (public."ServiceSearchSet" serviceinner
                              JOIN public."ServiceTypeEnumSet" servicetypeinner ON ((serviceinner."ServiceTypeTranslationKey" = servicetypeinner."TranslationKey")))
                           WHERE (serviceinner."Id" = service."Id")
                          LIMIT 1) innertable) innertable2
           WHERE (((innertable2.dictelements -> 'Value'::text) ->> 'lang'::text) = innerquery.language)) AS servicetypetranslations
    FROM (public."ServiceSearchSet" service
      JOIN ( SELECT s."Id" AS serviceid,
             s."ServiceTypeTranslationKey",
             s."ServiceTypeCategoryTranslationKey",
             s."ExpertAccountSetId" AS accountid,
             s."ConsultationTypeEnum",
                 CASE
                     WHEN (s."LocationCountryCodeJs" IS NOT NULL) THEN (s."LocationCountryCodeJs" -> 'assignedLanguageLocationCountryCodes'::text)
                     ELSE NULL::jsonb
                 END AS locationcountrycodes,
                 CASE
                     WHEN (s."LanguageCountryCodeJs" IS NOT NULL) THEN (s."LanguageCountryCodeJs" -> 'assignedLanguageCountryCodes'::text)
                     ELSE NULL::jsonb
                 END AS languagecountrycodes,
             s."CreationDate" AS creationdate,
             acc."Firstname" AS accountfirstname,
             acc."Lastname" AS accountlastname,
             acc."CompanyNameOrNull",
             acc."SpokenLanguagesSemicolonSeparated",
                 CASE
                     WHEN (((accstatus."IsBlocked" IS NOT NULL) AND (accstatus."BlockedUntil" IS NULL)) OR ((accstatus."BlockedUntil" IS NOT NULL) AND (accstatus."BlockedUntil" > now()))) THEN true
                     ELSE false
                 END AS isblocked,
             ( SELECT json_agg(innerquery_1.premiumin) AS json_agg
                    FROM ( SELECT
                                 CASE
                                     WHEN (((accstatustenantinner."IsPremium" IS NOT NULL) AND (accstatustenantinner."PremiumUntil" IS NULL)) OR ((accstatustenantinner."PremiumUntil" IS NOT NULL) AND (accstatustenantinner."PremiumUntil" > now()))) THEN accmultitenantinner."TenantIdentifier"
                                     ELSE NULL::text
                                 END AS premiumin
                            FROM (public."AccountMultitenancySet" accmultitenantinner
                              JOIN public."AccountStatusTenantAware" accstatustenantinner ON ((accstatustenantinner."Id" = accmultitenantinner."AccountStatusTenantAwareSetId")))
                           WHERE (accmultitenantinner."AccountId" = acc."Id")) innerquery_1
                   WHERE (innerquery_1.premiumin IS NOT NULL)) AS premiumon,
             ( SELECT json_agg(innerquery_1.verifiedin) AS json_agg
                    FROM ( SELECT
                                 CASE
                                     WHEN (((accstatustenantinner."IsVerified" IS NOT NULL) AND (accstatustenantinner."VerifiedUntil" IS NULL)) OR ((accstatustenantinner."VerifiedUntil" IS NOT NULL) AND (accstatustenantinner."VerifiedUntil" >= now()))) THEN accmultitenantinner."TenantIdentifier"
                                     ELSE NULL::text
                                 END AS verifiedin
                            FROM (public."AccountMultitenancySet" accmultitenantinner
                              JOIN public."AccountStatusTenantAware" accstatustenantinner ON ((accstatustenantinner."Id" = accmultitenantinner."AccountStatusTenantAwareSetId")))
                           WHERE (accmultitenantinner."AccountId" = acc."Id")) innerquery_1
                   WHERE (innerquery_1.verifiedin IS NOT NULL)) AS verifiedon,
             ( SELECT json_agg(innerquery_1.verifiedin) AS json_agg
                    FROM ( SELECT
                                 CASE
                                     WHEN (((accstatustenantinner."ActivelyPreventFromListingFrom" IS NOT NULL) AND (accstatustenantinner."ActivelyPreventFromListingTill" IS NULL)) OR ((accstatustenantinner."ActivelyPreventFromListingTill" IS NOT NULL) AND (accstatustenantinner."ActivelyPreventFromListingTill" > now()))) THEN NULL::text
                                     ELSE accmultitenantinner."TenantIdentifier"
                                 END AS verifiedin
                            FROM (public."AccountMultitenancySet" accmultitenantinner
                              JOIN public."AccountStatusTenantAware" accstatustenantinner ON ((accstatustenantinner."Id" = accmultitenantinner."AccountStatusTenantAwareSetId")))
                           WHERE (accmultitenantinner."AccountId" = acc."Id")) innerquery_1
                   WHERE (innerquery_1.verifiedin IS NOT NULL)) AS listedon,
             btrim((json_array_elements(COALESCE(((s."LanguageCountryCodeJs" -> 'assignedLanguageCountryCodes'::text))::json, (((s."ServiceDescriptionsJs" -> 'descriptionDict'::text) -> 'langs'::text))::json)))::text, '"'::text) AS language,
             accstats."AggregatedRecommendations",
             accstats."AggregatedBookmarkedByAccounts",
             accstats."AggregatedRating",
             accstats."AggregatedNegativeRatings",
             accstats."AggregatedPositiveRatings",
             accstatus."LastSavingDateAccount",
             accstatus."ServiceSettingsLastPostPublishInfoStash",
             accstatus."ServicesLastPublishDateOrNull"
            FROM ((((public."ServiceSearchSet" s
              LEFT JOIN public."AccountSet" acc ON ((s."ExpertAccountSetId" = acc."Id")))
              LEFT JOIN public."AccountStatus" accstatus ON ((acc."AccountStatusId" = accstatus."Id")))
              LEFT JOIN public."ServiceTypeEnumSet" servicetype ON ((servicetype."TranslationKey" = s."ServiceTypeTranslationKey")))
              LEFT JOIN public."AccountStatsSet" accstats ON ((acc."Id" = accstats."AccountSetId")))
           WHERE (s."Disabled" = false)) innerquery ON ((innerquery.serviceid = service."Id")))
   WHERE (service."Disabled" = false);


 --
 -- TOC entry 325 (class 1259 OID 1560626)
 -- Name: ServiceSettingsAdvisingStatusStashSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceSettingsAdvisingStatusStashSet" (
     "Id" bigint NOT NULL,
     "Version" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "Data" jsonb,
     "OwnerId" integer,
     "Revision" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 324 (class 1259 OID 1560624)
 -- Name: ServiceSettingsAdvisingStatusStashSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceSettingsAdvisingStatusStashSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceSettingsAdvisingStatusStashSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 327 (class 1259 OID 1560643)
 -- Name: ServiceSettingsCallDurationStashSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceSettingsCallDurationStashSet" (
     "Id" bigint NOT NULL,
     "Version" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "Data" jsonb,
     "OwnerId" integer,
     "Revision" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 326 (class 1259 OID 1560641)
 -- Name: ServiceSettingsCallDurationStashSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceSettingsCallDurationStashSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceSettingsCallDurationStashSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 333 (class 1259 OID 1560691)
 -- Name: ServiceSettingsCountriesStashSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceSettingsCountriesStashSet" (
     "Id" bigint NOT NULL,
     "Version" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "Data" jsonb,
     "OwnerId" integer,
     "Revision" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 332 (class 1259 OID 1560689)
 -- Name: ServiceSettingsCountriesStashSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceSettingsCountriesStashSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceSettingsCountriesStashSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 335 (class 1259 OID 1560708)
 -- Name: ServiceSettingsLanguagesStashSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceSettingsLanguagesStashSet" (
     "Id" bigint NOT NULL,
     "Version" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "Data" jsonb,
     "OwnerId" integer,
     "Revision" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 334 (class 1259 OID 1560706)
 -- Name: ServiceSettingsLanguagesStashSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceSettingsLanguagesStashSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceSettingsLanguagesStashSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 331 (class 1259 OID 1560675)
 -- Name: ServiceSettingsOfficeHoursStashSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceSettingsOfficeHoursStashSet" (
     "Id" bigint NOT NULL,
     "Version" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "Data" jsonb,
     "OwnerId" integer,
     "Revision" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 330 (class 1259 OID 1560673)
 -- Name: ServiceSettingsOfficeHoursStashSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceSettingsOfficeHoursStashSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceSettingsOfficeHoursStashSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 329 (class 1259 OID 1560658)
 -- Name: ServiceSettingsPricingModelStashSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceSettingsPricingModelStashSet" (
     "Id" bigint NOT NULL,
     "Version" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "Data" jsonb,
     "OwnerId" integer,
     "Revision" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 328 (class 1259 OID 1560656)
 -- Name: ServiceSettingsPricingModelStashSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceSettingsPricingModelStashSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceSettingsPricingModelStashSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 345 (class 1259 OID 1561348)
 -- Name: ServiceSettingsPublishDraftStashSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceSettingsPublishDraftStashSet" (
     "Id" bigint NOT NULL,
     "Version" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "Data" jsonb,
     "OwnerId" integer,
     "Revision" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 344 (class 1259 OID 1561346)
 -- Name: ServiceSettingsPublishDraftStashSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceSettingsPublishDraftStashSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceSettingsPublishDraftStashSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 337 (class 1259 OID 1560724)
 -- Name: ServiceSettingsPublishInfoStashSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceSettingsPublishInfoStashSet" (
     "Id" bigint NOT NULL,
     "Version" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "Data" jsonb,
     "OwnerId" integer,
     "Revision" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 336 (class 1259 OID 1560722)
 -- Name: ServiceSettingsPublishInfoStashSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceSettingsPublishInfoStashSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceSettingsPublishInfoStashSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 323 (class 1259 OID 1560575)
 -- Name: ServiceSettingsServicesStashSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceSettingsServicesStashSet" (
     "Id" bigint NOT NULL,
     "Version" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "OwnerId" integer,
     "Data" jsonb,
     "Revision" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 322 (class 1259 OID 1560573)
 -- Name: ServiceSettingsServicesStashSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceSettingsServicesStashSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceSettingsServicesStashSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 317 (class 1259 OID 1560057)
 -- Name: ServiceStatsSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceStatsSet" (
     "Id" integer NOT NULL,
     "ServiceSearchSetId" bigint NOT NULL,
     "AggregatedBookmarkedByAccounts" integer NOT NULL
 );


 --
 -- TOC entry 316 (class 1259 OID 1560055)
 -- Name: ServiceStatsSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceStatsSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceStatsSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 370 (class 1259 OID 2359694)
 -- Name: ServiceTypeCategoryConnectionTenantStaticSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceTypeCategoryConnectionTenantStaticSet" (
     "Id" integer NOT NULL,
     "VisibilityType" integer NOT NULL,
     "ServiceTypeCategoryEnumSetId" integer,
     "TenantSetId" integer
 );


 --
 -- TOC entry 369 (class 1259 OID 2359692)
 -- Name: ServiceTypeCategoryConnectionTenantStaticSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceTypeCategoryConnectionTenantStaticSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceTypeCategoryConnectionTenantStaticSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 251 (class 1259 OID 345789)
 -- Name: ServiceTypeCategoryEnumSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."ServiceTypeCategoryEnumSet" (
     "Id" integer NOT NULL,
     "TranslationKey" text,
     "CreationDate" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "IsDisabled" boolean DEFAULT false NOT NULL,
     "AudienceTypeEnum" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 252 (class 1259 OID 345795)
 -- Name: ServiceTypeCategoryEnumSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceTypeCategoryEnumSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceTypeCategoryEnumSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 254 (class 1259 OID 345804)
 -- Name: ServiceTypeEnumSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."ServiceTypeEnumSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."ServiceTypeEnumSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 272 (class 1259 OID 508940)
 -- Name: TenantSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."TenantSet" (
     "Id" integer NOT NULL,
     "Identifier" text,
     "ThemeDefinition" jsonb,
     "FinancialsDefinition" jsonb,
     "AdvisoryRoomHasBanners" boolean DEFAULT false NOT NULL,
     "AdvisoryRoomLeftBannerId" integer,
     "AdvisoryRoomRightBannerId" integer,
     "LogoId" integer,
     "ProductListId" integer,
     "BeneficiaryId" integer,
     "AudienceTypeEnum" integer DEFAULT 0 NOT NULL,
     "ShowGrossPrices" boolean DEFAULT false NOT NULL
 );


 --
 -- TOC entry 371 (class 1259 OID 2359712)
 -- Name: ServiceTypeTenantView; Type: VIEW; Schema: public; Owner: -
 --

 CREATE VIEW public."ServiceTypeTenantView" AS
  SELECT st."Id" AS "ServiceTypeEnumSetId",
     st."TranslationKey" AS "ServiceTypeTranslationKey",
     st."ServiceTypeCategoryTranslationKey",
     t."Identifier" AS "TenantIdentifier",
     stct."VisibilityType",
     stc."AudienceTypeEnum" AS "CategoryAudienceType",
     t."AudienceTypeEnum" AS "TenantAudienceType"
    FROM (((public."ServiceTypeEnumSet" st
      LEFT JOIN public."ServiceTypeCategoryEnumSet" stc ON ((stc."TranslationKey" = st."ServiceTypeCategoryTranslationKey")))
      LEFT JOIN public."ServiceTypeCategoryConnectionTenantStaticSet" stct ON ((stc."Id" = stct."ServiceTypeCategoryEnumSetId")))
      LEFT JOIN public."TenantSet" t ON ((stct."TenantSetId" = t."Id")))
   WHERE ((t."AudienceTypeEnum" | stc."AudienceTypeEnum") = t."AudienceTypeEnum");


 --
 -- TOC entry 351 (class 1259 OID 1785220)
 -- Name: SpamProtectionDomainSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."SpamProtectionDomainSet" (
     "Id" bigint NOT NULL,
     "Domain" character varying(255) NOT NULL,
     "Provider" character varying(255) NOT NULL,
     "FirstSeen" timestamp with time zone NOT NULL,
     "LastSeen" timestamp with time zone NOT NULL,
     "RandomSubdomain" boolean NOT NULL,
     "IsWhitelisted" boolean NOT NULL
 );


 --
 -- TOC entry 350 (class 1259 OID 1785218)
 -- Name: SpamProtectionDomainSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."SpamProtectionDomainSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."SpamProtectionDomainSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 289 (class 1259 OID 555198)
 -- Name: SsoPwSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."SsoPwSet" (
     "Id" integer NOT NULL,
     "SsoProvider" text,
     "AccountId" integer NOT NULL,
     "SsoPw" text,
     "KeyHash" text
 );


 --
 -- TOC entry 288 (class 1259 OID 555196)
 -- Name: SsoPwSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."SsoPwSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."SsoPwSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 284 (class 1259 OID 510234)
 -- Name: UserStorySet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."UserStorySet" (
     "Id" bigint NOT NULL,
     "Gif" text,
     "UserStoryJs" jsonb,
     "FromAccountId" integer,
     "UserStoryJs_value1_english" text,
     "UserStoryJs_value1_german" text,
     "UserStoryJs_value2_english" text,
     "UserStoryJs_value2_german" text,
     "Discriminator" text DEFAULT ''::text NOT NULL,
     "UserStoryTypeEnum" integer DEFAULT 0 NOT NULL,
     "CreationDate" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "RecommendationSet_Gif" text,
     "SearchFieldsTs_english" tsvector GENERATED ALWAYS AS (to_tsvector('english'::regconfig, ((COALESCE("UserStoryJs_value1_english", ''::text) || ' '::text) || COALESCE("UserStoryJs_value2_english", ''::text)))) STORED,
     "SearchFieldsTs_german" tsvector GENERATED ALWAYS AS (to_tsvector('german'::regconfig, ((COALESCE("UserStoryJs_value1_german", ''::text) || ' '::text) || COALESCE("UserStoryJs_value2_german", ''::text)))) STORED,
     "TenantIdentifier" text
 );


 --
 -- TOC entry 283 (class 1259 OID 510232)
 -- Name: SuccessStorySet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."UserStorySet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."SuccessStorySet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 368 (class 1259 OID 2359440)
 -- Name: TaxInCountrySet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."TaxInCountrySet" (
     "Id" integer NOT NULL,
     "CountryCode" text,
     "Rate" numeric NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "LastModifiedDate" timestamp without time zone NOT NULL
 );


 --
 -- TOC entry 367 (class 1259 OID 2359438)
 -- Name: TaxInCountrySet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."TaxInCountrySet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."TaxInCountrySet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 255 (class 1259 OID 345841)
 -- Name: Temp_IndustryTypeTranslationKeys2; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."Temp_IndustryTypeTranslationKeys2" (
     "ExpertAccountSetId" integer,
     industrytype_list text
 );


 --
 -- TOC entry 271 (class 1259 OID 508938)
 -- Name: TenantSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."TenantSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."TenantSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 339 (class 1259 OID 1561191)
 -- Name: TermsAndConditionSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."TermsAndConditionSet" (
     "Id" bigint NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "PreviousVersionId" bigint,
     "AccountSetId" integer NOT NULL,
     "Discriminator" text NOT NULL,
     "DocumentId" integer,
     "Url" text,
     "IsAccepted" boolean
 );


 --
 -- TOC entry 338 (class 1259 OID 1561189)
 -- Name: TermsAndConditionSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."TermsAndConditionSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."TermsAndConditionSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 373 (class 1259 OID 2360225)
 -- Name: TransactionDetailsSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."TransactionDetailsSet" (
     "Id" integer NOT NULL,
     "GrossAmount" numeric NOT NULL,
     "NetAmount" numeric NOT NULL,
     "Tax" numeric NOT NULL
 );


 --
 -- TOC entry 372 (class 1259 OID 2360223)
 -- Name: TransactionDetailsSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."TransactionDetailsSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."TransactionDetailsSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 256 (class 1259 OID 345865)
 -- Name: UploadSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."UploadSet" (
     "Id" integer NOT NULL,
     "BucketName" text,
     "ObjectName" text,
     "OriginalFileName" text,
     "CreationDate" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
     "BookingRequestSetId" bigint,
     "ProjectSetId" integer,
     "ConversationAttachmentMessageSetId" integer
 );


 --
 -- TOC entry 257 (class 1259 OID 345871)
 -- Name: UploadSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."UploadSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."UploadSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 366 (class 1259 OID 2359304)
 -- Name: UploadStashSets; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."UploadStashSets" (
     "Id" integer NOT NULL,
     "BucketName" text,
     "ObjectName" text,
     "OriginalFileName" text,
     "CreationDate" timestamp without time zone NOT NULL,
     "ExpirationDate" timestamp without time zone,
     "CreatorAccountId" integer,
     "ConversationSetId" integer
 );


 --
 -- TOC entry 365 (class 1259 OID 2359302)
 -- Name: UploadStashSets_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."UploadStashSets" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."UploadStashSets_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 349 (class 1259 OID 1785169)
 -- Name: VideoOnDemandInformationStashSet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."VideoOnDemandInformationStashSet" (
     "Id" bigint NOT NULL,
     "MeetingInformationSetId" integer,
     "VideoOnDemandPlatformProviderEnum" integer NOT NULL,
     "Version" integer NOT NULL,
     "CreationDate" timestamp without time zone NOT NULL,
     "Data" jsonb,
     "OwnerId" integer,
     "Revision" integer DEFAULT 0 NOT NULL
 );


 --
 -- TOC entry 348 (class 1259 OID 1785167)
 -- Name: VideoOnDemandInformationStashSet_Id_seq; Type: SEQUENCE; Schema: public; Owner: -
 --

 ALTER TABLE public."VideoOnDemandInformationStashSet" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
     SEQUENCE NAME public."VideoOnDemandInformationStashSet_Id_seq"
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1
 );


 --
 -- TOC entry 258 (class 1259 OID 345873)
 -- Name: VotingEntrySet; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."VotingEntrySet" (
     "Id" uuid NOT NULL,
     "UserTypeEnum" integer NOT NULL,
     "VotingDate" timestamp without time zone NOT NULL,
     "UserId" integer NOT NULL,
     "VotingTypeEnum" integer NOT NULL,
     "AppointmentDateToVoteFor" timestamp without time zone NOT NULL,
     "VotingValueEnum" integer NOT NULL,
     "Note" text,
     "MeetingInformationSetId" integer
 );


 --
 -- TOC entry 259 (class 1259 OID 345879)
 -- Name: __EFMigrationsHistory; Type: TABLE; Schema: public; Owner: -
 --

 CREATE TABLE public."__EFMigrationsHistory" (
     "MigrationId" character varying(150) NOT NULL,
     "ProductVersion" character varying(32) NOT NULL
 );


 --
 -- TOC entry 287 (class 1259 OID 541088)
 -- Name: servicesearchset; Type: SEQUENCE; Schema: public; Owner: -
 --

 CREATE SEQUENCE public.servicesearchset
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1;


 --
 -- TOC entry 260 (class 1259 OID 345884)
 -- Name: serviceset; Type: SEQUENCE; Schema: public; Owner: -
 --

 CREATE SEQUENCE public.serviceset
     START WITH 1
     INCREMENT BY 1
     NO MINVALUE
     NO MAXVALUE
     CACHE 1;


 --
 -- TOC entry 4539 (class 2604 OID 16621)
 -- Name: counter id; Type: DEFAULT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.counter ALTER COLUMN id SET DEFAULT nextval('hangfire.counter_id_seq'::regclass);


 --
 -- TOC entry 4540 (class 2604 OID 16623)
 -- Name: hash id; Type: DEFAULT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.hash ALTER COLUMN id SET DEFAULT nextval('hangfire.hash_id_seq'::regclass);


 --
 -- TOC entry 4542 (class 2604 OID 16624)
 -- Name: job id; Type: DEFAULT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.job ALTER COLUMN id SET DEFAULT nextval('hangfire.job_id_seq'::regclass);


 --
 -- TOC entry 4544 (class 2604 OID 16625)
 -- Name: jobparameter id; Type: DEFAULT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.jobparameter ALTER COLUMN id SET DEFAULT nextval('hangfire.jobparameter_id_seq'::regclass);


 --
 -- TOC entry 4546 (class 2604 OID 16626)
 -- Name: jobqueue id; Type: DEFAULT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.jobqueue ALTER COLUMN id SET DEFAULT nextval('hangfire.jobqueue_id_seq'::regclass);


 --
 -- TOC entry 4548 (class 2604 OID 16627)
 -- Name: list id; Type: DEFAULT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.list ALTER COLUMN id SET DEFAULT nextval('hangfire.list_id_seq'::regclass);


 --
 -- TOC entry 4552 (class 2604 OID 16628)
 -- Name: set id; Type: DEFAULT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.set ALTER COLUMN id SET DEFAULT nextval('hangfire.set_id_seq'::regclass);


 --
 -- TOC entry 4554 (class 2604 OID 16629)
 -- Name: state id; Type: DEFAULT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.state ALTER COLUMN id SET DEFAULT nextval('hangfire.state_id_seq'::regclass);


 --
 -- TOC entry 4697 (class 2606 OID 16630)
 -- Name: counter counter_pkey; Type: CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.counter
     ADD CONSTRAINT counter_pkey PRIMARY KEY (id);


 --
 -- TOC entry 4701 (class 2606 OID 16631)
 -- Name: hash hash_key_field_key; Type: CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.hash
     ADD CONSTRAINT hash_key_field_key UNIQUE (key, field);


 --
 -- TOC entry 4703 (class 2606 OID 16632)
 -- Name: hash hash_pkey; Type: CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.hash
     ADD CONSTRAINT hash_pkey PRIMARY KEY (id);


 --
 -- TOC entry 4708 (class 2606 OID 16633)
 -- Name: job job_pkey; Type: CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.job
     ADD CONSTRAINT job_pkey PRIMARY KEY (id);


 --
 -- TOC entry 4711 (class 2606 OID 16634)
 -- Name: jobparameter jobparameter_pkey; Type: CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.jobparameter
     ADD CONSTRAINT jobparameter_pkey PRIMARY KEY (id);


 --
 -- TOC entry 4715 (class 2606 OID 16635)
 -- Name: jobqueue jobqueue_pkey; Type: CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.jobqueue
     ADD CONSTRAINT jobqueue_pkey PRIMARY KEY (id);


 --
 -- TOC entry 4719 (class 2606 OID 16636)
 -- Name: list list_pkey; Type: CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.list
     ADD CONSTRAINT list_pkey PRIMARY KEY (id);


 --
 -- TOC entry 4721 (class 2606 OID 16637)
 -- Name: lock lock_resource_key; Type: CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.lock
     ADD CONSTRAINT lock_resource_key UNIQUE (resource);


 --
 -- TOC entry 4723 (class 2606 OID 16638)
 -- Name: schema schema_pkey; Type: CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.schema
     ADD CONSTRAINT schema_pkey PRIMARY KEY (version);


 --
 -- TOC entry 4725 (class 2606 OID 16639)
 -- Name: server server_pkey; Type: CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.server
     ADD CONSTRAINT server_pkey PRIMARY KEY (id);


 --
 -- TOC entry 4729 (class 2606 OID 16640)
 -- Name: set set_key_value_key; Type: CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.set
     ADD CONSTRAINT set_key_value_key UNIQUE (key, value);


 --
 -- TOC entry 4731 (class 2606 OID 16641)
 -- Name: set set_pkey; Type: CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.set
     ADD CONSTRAINT set_pkey PRIMARY KEY (id);


 --
 -- TOC entry 4734 (class 2606 OID 16642)
 -- Name: state state_pkey; Type: CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.state
     ADD CONSTRAINT state_pkey PRIMARY KEY (id);


 --
 -- TOC entry 4837 (class 2606 OID 16643)
 -- Name: AccountInvoiceInformationSet PK_AccountInvoiceInformationSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountInvoiceInformationSet"
     ADD CONSTRAINT "PK_AccountInvoiceInformationSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4859 (class 2606 OID 16644)
 -- Name: AccountMultitenancySet PK_AccountMultitenancySet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountMultitenancySet"
     ADD CONSTRAINT "PK_AccountMultitenancySet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4923 (class 2606 OID 16645)
 -- Name: AccountQuotaPerDaySet PK_AccountQuotaPerDaySet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountQuotaPerDaySet"
     ADD CONSTRAINT "PK_AccountQuotaPerDaySet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4743 (class 2606 OID 16646)
 -- Name: AccountSet PK_AccountSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountSet"
     ADD CONSTRAINT "PK_AccountSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5035 (class 2606 OID 2359227)
 -- Name: AccountSetConversationSet PK_AccountSetConversationSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountSetConversationSet"
     ADD CONSTRAINT "PK_AccountSetConversationSet" PRIMARY KEY ("ConversationsId", "ParticipantAccountsId");


 --
 -- TOC entry 4920 (class 2606 OID 16648)
 -- Name: AccountStatsSet PK_AccountStatsSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountStatsSet"
     ADD CONSTRAINT "PK_AccountStatsSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4745 (class 2606 OID 16649)
 -- Name: AccountStatus PK_AccountStatus; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountStatus"
     ADD CONSTRAINT "PK_AccountStatus" PRIMARY KEY ("Id");


 --
 -- TOC entry 4861 (class 2606 OID 16650)
 -- Name: AccountStatusTenantAware PK_AccountStatusTenantAware; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountStatusTenantAware"
     ADD CONSTRAINT "PK_AccountStatusTenantAware" PRIMARY KEY ("Id");


 --
 -- TOC entry 5076 (class 2606 OID 2463423)
 -- Name: AnonymousUserEventTrackingPerDaySet PK_AnonymousUserEventTrackingPerDaySet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AnonymousUserEventTrackingPerDaySet"
     ADD CONSTRAINT "PK_AnonymousUserEventTrackingPerDaySet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5072 (class 2606 OID 2463413)
 -- Name: AnonymousUserEventTrackingSet PK_AnonymousUserEventTrackingSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AnonymousUserEventTrackingSet"
     ADD CONSTRAINT "PK_AnonymousUserEventTrackingSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4950 (class 2606 OID 16651)
 -- Name: AppliedCouponConnection PK_AppliedCouponConnection; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AppliedCouponConnection"
     ADD CONSTRAINT "PK_AppliedCouponConnection" PRIMARY KEY ("Id");


 --
 -- TOC entry 4993 (class 2606 OID 16652)
 -- Name: BookingRequestSet PK_BookingRequestSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookingRequestSet"
     ADD CONSTRAINT "PK_BookingRequestSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4997 (class 2606 OID 16653)
 -- Name: BookmarkConnectionExpertStaticSet PK_BookmarkConnectionExpertStaticSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookmarkConnectionExpertStaticSet"
     ADD CONSTRAINT "PK_BookmarkConnectionExpertStaticSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4935 (class 2606 OID 16654)
 -- Name: BookmarkConnectionServiceStaticSet PK_BookmarkConnectionServiceStaticSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookmarkConnectionServiceStaticSet"
     ADD CONSTRAINT "PK_BookmarkConnectionServiceStaticSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4940 (class 2606 OID 16655)
 -- Name: BookmarkConnectionWithHistoryBaseSet PK_BookmarkConnectionWithHistoryBaseSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookmarkConnectionWithHistoryBaseSet"
     ADD CONSTRAINT "PK_BookmarkConnectionWithHistoryBaseSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5110 (class 2606 OID 3075770)
 -- Name: CognitoUserIdSet PK_CognitoUserIdSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CognitoUserIdSet"
     ADD CONSTRAINT "PK_CognitoUserIdSet" PRIMARY KEY ("CognitoUserId");


 --
 -- TOC entry 5114 (class 2606 OID 3075785)
 -- Name: CognitoUsernameSet PK_CognitoUsernameSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CognitoUsernameSet"
     ADD CONSTRAINT "PK_CognitoUsernameSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5046 (class 2606 OID 2359274)
 -- Name: ConversationMessageReadByAccountSet PK_ConversationMessageReadByAccountSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ConversationMessageReadByAccountSet"
     ADD CONSTRAINT "PK_ConversationMessageReadByAccountSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5042 (class 2606 OID 2359247)
 -- Name: ConversationMessageSet PK_ConversationMessageSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ConversationMessageSet"
     ADD CONSTRAINT "PK_ConversationMessageSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5032 (class 2606 OID 2359217)
 -- Name: ConversationSet PK_ConversationSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ConversationSet"
     ADD CONSTRAINT "PK_ConversationSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4946 (class 2606 OID 16656)
 -- Name: Coupon PK_Coupon; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."Coupon"
     ADD CONSTRAINT "PK_Coupon" PRIMARY KEY ("Id");


 --
 -- TOC entry 5069 (class 2606 OID 2360272)
 -- Name: CouponPurchaseDetailsSet PK_CouponPurchaseDetailsSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CouponPurchaseDetailsSet"
     ADD CONSTRAINT "PK_CouponPurchaseDetailsSet" PRIMARY KEY ("AppliedToPurchaseDetailsId", "CouponsId");


 --
 -- TOC entry 4749 (class 2606 OID 16657)
 -- Name: CustomAccountLinkSet PK_CustomAccountLinkSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CustomAccountLinkSet"
     ADD CONSTRAINT "PK_CustomAccountLinkSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5101 (class 2606 OID 2662863)
 -- Name: CustomOfferConnectionStaticSet PK_CustomOfferConnectionStaticSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CustomOfferConnectionStaticSet"
     ADD CONSTRAINT "PK_CustomOfferConnectionStaticSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5097 (class 2606 OID 2662833)
 -- Name: CustomOfferSet PK_CustomOfferSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CustomOfferSet"
     ADD CONSTRAINT "PK_CustomOfferSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4863 (class 2606 OID 16658)
 -- Name: FaqCategorySet PK_FaqCategorySet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."FaqCategorySet"
     ADD CONSTRAINT "PK_FaqCategorySet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4866 (class 2606 OID 16659)
 -- Name: FaqSet PK_FaqSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."FaqSet"
     ADD CONSTRAINT "PK_FaqSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4844 (class 2606 OID 16660)
 -- Name: FeaturedExpertsServiceSet PK_FeaturedExpertsServiceSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."FeaturedExpertsServiceSet"
     ADD CONSTRAINT "PK_FeaturedExpertsServiceSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4751 (class 2606 OID 16661)
 -- Name: GeneralSettingsSet PK_GeneralSettingsSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."GeneralSettingsSet"
     ADD CONSTRAINT "PK_GeneralSettingsSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4759 (class 2606 OID 16662)
 -- Name: GoalSet PK_GoalSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."GoalSet"
     ADD CONSTRAINT "PK_GoalSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4878 (class 2606 OID 16663)
 -- Name: HashtagConnectionSet PK_HashtagConnectionSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."HashtagConnectionSet"
     ADD CONSTRAINT "PK_HashtagConnectionSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4870 (class 2606 OID 16664)
 -- Name: HashtagSet PK_HashtagSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."HashtagSet"
     ADD CONSTRAINT "PK_HashtagSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5024 (class 2606 OID 16665)
 -- Name: HubspotMappingSet PK_HubspotMappingSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."HubspotMappingSet"
     ADD CONSTRAINT "PK_HubspotMappingSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4931 (class 2606 OID 16667)
 -- Name: InviteConnectionSet PK_InviteConnectionSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."InviteConnectionSet"
     ADD CONSTRAINT "PK_InviteConnectionSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5021 (class 2606 OID 16669)
 -- Name: KycCompany PK_KycCompany; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."KycCompany"
     ADD CONSTRAINT "PK_KycCompany" PRIMARY KEY ("Id");


 --
 -- TOC entry 5118 (class 2606 OID 3075828)
 -- Name: KycCompanyConnectionAccountStaticSet PK_KycCompanyConnectionAccountStaticSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."KycCompanyConnectionAccountStaticSet"
     ADD CONSTRAINT "PK_KycCompanyConnectionAccountStaticSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5121 (class 2606 OID 3075848)
 -- Name: KycCompanyStashSet PK_KycCompanyStashSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."KycCompanyStashSet"
     ADD CONSTRAINT "PK_KycCompanyStashSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5005 (class 2606 OID 16671)
 -- Name: KycDocumentSet PK_KycDocumentSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."KycDocumentSet"
     ADD CONSTRAINT "PK_KycDocumentSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5085 (class 2606 OID 2477126)
 -- Name: LegalDocumentSequenceSet PK_LegalDocumentSequenceSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."LegalDocumentSequenceSet"
     ADD CONSTRAINT "PK_LegalDocumentSequenceSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5081 (class 2606 OID 2477101)
 -- Name: LegalDocumentSet PK_LegalDocumentSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."LegalDocumentSet"
     ADD CONSTRAINT "PK_LegalDocumentSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4763 (class 2606 OID 16672)
 -- Name: LikeAndFollowExpertHistory PK_LikeAndFollowExpertHistory; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."LikeAndFollowExpertHistory"
     ADD CONSTRAINT "PK_LikeAndFollowExpertHistory" PRIMARY KEY ("Id");


 --
 -- TOC entry 4917 (class 2606 OID 16673)
 -- Name: MangpayInfo PK_MangpayInfo; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MangpayInfo"
     ADD CONSTRAINT "PK_MangpayInfo" PRIMARY KEY ("Id");


 --
 -- TOC entry 4773 (class 2606 OID 16674)
 -- Name: MeetingInformationSet PK_MeetingInformationSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MeetingInformationSet"
     ADD CONSTRAINT "PK_MeetingInformationSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4777 (class 2606 OID 16675)
 -- Name: MeetingWhitelistAccountEntrySet PK_MeetingWhitelistAccountEntrySet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MeetingWhitelistAccountEntrySet"
     ADD CONSTRAINT "PK_MeetingWhitelistAccountEntrySet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4781 (class 2606 OID 16676)
 -- Name: MeetingWhitelistEmailEntrySet PK_MeetingWhitelistEmailEntrySet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MeetingWhitelistEmailEntrySet"
     ADD CONSTRAINT "PK_MeetingWhitelistEmailEntrySet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4902 (class 2606 OID 16677)
 -- Name: MentionConnectionSet PK_MentionConnectionSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MentionConnectionSet"
     ADD CONSTRAINT "PK_MentionConnectionSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4790 (class 2606 OID 16678)
 -- Name: MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet PK_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet"
     ADD CONSTRAINT "PK_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5016 (class 2606 OID 16679)
 -- Name: OfficeHoursBreakSet PK_OfficeHoursBreakSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."OfficeHoursBreakSet"
     ADD CONSTRAINT "PK_OfficeHoursBreakSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4799 (class 2606 OID 16680)
 -- Name: OfficeHoursSet PK_OfficeHoursSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."OfficeHoursSet"
     ADD CONSTRAINT "PK_OfficeHoursSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5123 (class 2606 OID 3281855)
 -- Name: OpenAiGeneralSettingsSet PK_OpenAiGeneralSettingsSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."OpenAiGeneralSettingsSet"
     ADD CONSTRAINT "PK_OpenAiGeneralSettingsSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5104 (class 2606 OID 3075709)
 -- Name: PaymentAvailabilityInCountrySet PK_PaymentAvailabilityInCountrySet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."PaymentAvailabilityInCountrySet"
     ADD CONSTRAINT "PK_PaymentAvailabilityInCountrySet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4839 (class 2606 OID 2359828)
 -- Name: PaymentInformationSet PK_PaymentInformationSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."PaymentInformationSet"
     ADD CONSTRAINT "PK_PaymentInformationSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4908 (class 2606 OID 16682)
 -- Name: Product PK_Product; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."Product"
     ADD CONSTRAINT "PK_Product" PRIMARY KEY ("Id");


 --
 -- TOC entry 4911 (class 2606 OID 16683)
 -- Name: ProductList PK_ProductList; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ProductList"
     ADD CONSTRAINT "PK_ProductList" PRIMARY KEY ("Id");


 --
 -- TOC entry 4915 (class 2606 OID 16684)
 -- Name: ProductToProductList PK_ProductToProductList; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ProductToProductList"
     ADD CONSTRAINT "PK_ProductToProductList" PRIMARY KEY ("Id");


 --
 -- TOC entry 4808 (class 2606 OID 16685)
 -- Name: ProjectSet PK_ProjectSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ProjectSet"
     ADD CONSTRAINT "PK_ProjectSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5106 (class 2606 OID 3075756)
 -- Name: PromptEngineeringAiSet PK_PromptEngineeringAiSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."PromptEngineeringAiSet"
     ADD CONSTRAINT "PK_PromptEngineeringAiSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5093 (class 2606 OID 2655770)
 -- Name: Purchase PK_Purchase; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."Purchase"
     ADD CONSTRAINT "PK_Purchase" PRIMARY KEY ("Id");


 --
 -- TOC entry 5066 (class 2606 OID 2360242)
 -- Name: PurchaseDetailsSet PK_PurchaseDetailsSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."PurchaseDetailsSet"
     ADD CONSTRAINT "PK_PurchaseDetailsSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4811 (class 2606 OID 16687)
 -- Name: RegistrationWaitinglist PK_RegistrationWaitinglist; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."RegistrationWaitinglist"
     ADD CONSTRAINT "PK_RegistrationWaitinglist" PRIMARY KEY ("Id");


 --
 -- TOC entry 4889 (class 2606 OID 16688)
 -- Name: RevenueCutGeneral PK_RevenueCutGeneral; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."RevenueCutGeneral"
     ADD CONSTRAINT "PK_RevenueCutGeneral" PRIMARY KEY ("Id");


 --
 -- TOC entry 4893 (class 2606 OID 16689)
 -- Name: RevenueCutTenant PK_RevenueCutTenant; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."RevenueCutTenant"
     ADD CONSTRAINT "PK_RevenueCutTenant" PRIMARY KEY ("Id");


 --
 -- TOC entry 4841 (class 2606 OID 16690)
 -- Name: SearchTermsLog PK_SearchTermsLog; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."SearchTermsLog"
     ADD CONSTRAINT "PK_SearchTermsLog" PRIMARY KEY ("Id");


 --
 -- TOC entry 4886 (class 2606 OID 16691)
 -- Name: ServiceRatingAfterMeetingSet PK_ServiceRatingAfterMeetingSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceRatingAfterMeetingSet"
     ADD CONSTRAINT "PK_ServiceRatingAfterMeetingSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4834 (class 2606 OID 16692)
 -- Name: ServiceSearchSet PK_ServiceSearchSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSearchSet"
     ADD CONSTRAINT "PK_ServiceSearchSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4956 (class 2606 OID 16694)
 -- Name: ServiceSettingsAdvisingStatusStashSet PK_ServiceSettingsAdvisingStatusStashSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsAdvisingStatusStashSet"
     ADD CONSTRAINT "PK_ServiceSettingsAdvisingStatusStashSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4959 (class 2606 OID 16695)
 -- Name: ServiceSettingsCallDurationStashSet PK_ServiceSettingsCallDurationStashSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsCallDurationStashSet"
     ADD CONSTRAINT "PK_ServiceSettingsCallDurationStashSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4968 (class 2606 OID 16696)
 -- Name: ServiceSettingsCountriesStashSet PK_ServiceSettingsCountriesStashSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsCountriesStashSet"
     ADD CONSTRAINT "PK_ServiceSettingsCountriesStashSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4971 (class 2606 OID 16698)
 -- Name: ServiceSettingsLanguagesStashSet PK_ServiceSettingsLanguagesStashSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsLanguagesStashSet"
     ADD CONSTRAINT "PK_ServiceSettingsLanguagesStashSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4965 (class 2606 OID 16699)
 -- Name: ServiceSettingsOfficeHoursStashSet PK_ServiceSettingsOfficeHoursStashSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsOfficeHoursStashSet"
     ADD CONSTRAINT "PK_ServiceSettingsOfficeHoursStashSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4962 (class 2606 OID 16700)
 -- Name: ServiceSettingsPricingModelStashSet PK_ServiceSettingsPricingModelStashSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsPricingModelStashSet"
     ADD CONSTRAINT "PK_ServiceSettingsPricingModelStashSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5000 (class 2606 OID 16701)
 -- Name: ServiceSettingsPublishDraftStashSet PK_ServiceSettingsPublishDraftStashSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsPublishDraftStashSet"
     ADD CONSTRAINT "PK_ServiceSettingsPublishDraftStashSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4974 (class 2606 OID 16702)
 -- Name: ServiceSettingsPublishInfoStashSet PK_ServiceSettingsPublishInfoStashSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsPublishInfoStashSet"
     ADD CONSTRAINT "PK_ServiceSettingsPublishInfoStashSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4953 (class 2606 OID 16703)
 -- Name: ServiceSettingsServicesStashSet PK_ServiceSettingsServicesStashSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsServicesStashSet"
     ADD CONSTRAINT "PK_ServiceSettingsServicesStashSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4943 (class 2606 OID 16704)
 -- Name: ServiceStatsSet PK_ServiceStatsSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceStatsSet"
     ADD CONSTRAINT "PK_ServiceStatsSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5057 (class 2606 OID 2359698)
 -- Name: ServiceTypeCategoryConnectionTenantStaticSet PK_ServiceTypeCategoryConnectionTenantStaticSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceTypeCategoryConnectionTenantStaticSet"
     ADD CONSTRAINT "PK_ServiceTypeCategoryConnectionTenantStaticSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4814 (class 2606 OID 16705)
 -- Name: ServiceTypeCategoryEnumSet PK_ServiceTypeCategoryEnumSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceTypeCategoryEnumSet"
     ADD CONSTRAINT "PK_ServiceTypeCategoryEnumSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4819 (class 2606 OID 16706)
 -- Name: ServiceTypeEnumSet PK_ServiceTypeEnumSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceTypeEnumSet"
     ADD CONSTRAINT "PK_ServiceTypeEnumSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5013 (class 2606 OID 16707)
 -- Name: SpamProtectionDomainSet PK_SpamProtectionDomainSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."SpamProtectionDomainSet"
     ADD CONSTRAINT "PK_SpamProtectionDomainSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4881 (class 2606 OID 16708)
 -- Name: SsoPwSet PK_SsoPwSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."SsoPwSet"
     ADD CONSTRAINT "PK_SsoPwSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5053 (class 2606 OID 2359447)
 -- Name: TaxInCountrySet PK_TaxInCountrySet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."TaxInCountrySet"
     ADD CONSTRAINT "PK_TaxInCountrySet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4852 (class 2606 OID 16713)
 -- Name: TenantSet PK_TenantSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."TenantSet"
     ADD CONSTRAINT "PK_TenantSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4979 (class 2606 OID 16714)
 -- Name: TermsAndConditionSet PK_TermsAndConditionSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."TermsAndConditionSet"
     ADD CONSTRAINT "PK_TermsAndConditionSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5059 (class 2606 OID 2360232)
 -- Name: TransactionDetailsSet PK_TransactionDetailsSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."TransactionDetailsSet"
     ADD CONSTRAINT "PK_TransactionDetailsSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4824 (class 2606 OID 16715)
 -- Name: UploadSet PK_UploadSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."UploadSet"
     ADD CONSTRAINT "PK_UploadSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5050 (class 2606 OID 2359311)
 -- Name: UploadStashSets PK_UploadStashSets; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."UploadStashSets"
     ADD CONSTRAINT "PK_UploadStashSets" PRIMARY KEY ("Id");


 --
 -- TOC entry 4873 (class 2606 OID 16716)
 -- Name: UserStorySet PK_UserStorySet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."UserStorySet"
     ADD CONSTRAINT "PK_UserStorySet" PRIMARY KEY ("Id");


 --
 -- TOC entry 5009 (class 2606 OID 16717)
 -- Name: VideoOnDemandInformationStashSet PK_VideoOnDemandInformationStashSet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."VideoOnDemandInformationStashSet"
     ADD CONSTRAINT "PK_VideoOnDemandInformationStashSet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4828 (class 2606 OID 16718)
 -- Name: VotingEntrySet PK_VotingEntrySet; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."VotingEntrySet"
     ADD CONSTRAINT "PK_VotingEntrySet" PRIMARY KEY ("Id");


 --
 -- TOC entry 4830 (class 2606 OID 16719)
 -- Name: __EFMigrationsHistory PK___EFMigrationsHistory; Type: CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."__EFMigrationsHistory"
     ADD CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId");


 --
 -- TOC entry 4698 (class 1259 OID 348804)
 -- Name: ix_hangfire_counter_expireat; Type: INDEX; Schema: hangfire; Owner: -
 --

 CREATE INDEX ix_hangfire_counter_expireat ON hangfire.counter USING btree (expireat);


 --
 -- TOC entry 4699 (class 1259 OID 348805)
 -- Name: ix_hangfire_counter_key; Type: INDEX; Schema: hangfire; Owner: -
 --

 CREATE INDEX ix_hangfire_counter_key ON hangfire.counter USING btree (key);


 --
 -- TOC entry 4704 (class 1259 OID 509848)
 -- Name: ix_hangfire_hash_expireat; Type: INDEX; Schema: hangfire; Owner: -
 --

 CREATE INDEX ix_hangfire_hash_expireat ON hangfire.hash USING btree (expireat);


 --
 -- TOC entry 4705 (class 1259 OID 509845)
 -- Name: ix_hangfire_job_expireat; Type: INDEX; Schema: hangfire; Owner: -
 --

 CREATE INDEX ix_hangfire_job_expireat ON hangfire.job USING btree (expireat);


 --
 -- TOC entry 4706 (class 1259 OID 348806)
 -- Name: ix_hangfire_job_statename; Type: INDEX; Schema: hangfire; Owner: -
 --

 CREATE INDEX ix_hangfire_job_statename ON hangfire.job USING btree (statename);


 --
 -- TOC entry 4709 (class 1259 OID 348807)
 -- Name: ix_hangfire_jobparameter_jobidandname; Type: INDEX; Schema: hangfire; Owner: -
 --

 CREATE INDEX ix_hangfire_jobparameter_jobidandname ON hangfire.jobparameter USING btree (jobid, name);


 --
 -- TOC entry 4712 (class 1259 OID 348808)
 -- Name: ix_hangfire_jobqueue_jobidandqueue; Type: INDEX; Schema: hangfire; Owner: -
 --

 CREATE INDEX ix_hangfire_jobqueue_jobidandqueue ON hangfire.jobqueue USING btree (jobid, queue);


 --
 -- TOC entry 4713 (class 1259 OID 348809)
 -- Name: ix_hangfire_jobqueue_queueandfetchedat; Type: INDEX; Schema: hangfire; Owner: -
 --

 CREATE INDEX ix_hangfire_jobqueue_queueandfetchedat ON hangfire.jobqueue USING btree (queue, fetchedat);


 --
 -- TOC entry 4717 (class 1259 OID 509846)
 -- Name: ix_hangfire_list_expireat; Type: INDEX; Schema: hangfire; Owner: -
 --

 CREATE INDEX ix_hangfire_list_expireat ON hangfire.list USING btree (expireat);


 --
 -- TOC entry 4726 (class 1259 OID 509847)
 -- Name: ix_hangfire_set_expireat; Type: INDEX; Schema: hangfire; Owner: -
 --

 CREATE INDEX ix_hangfire_set_expireat ON hangfire.set USING btree (expireat);


 --
 -- TOC entry 4727 (class 1259 OID 1784850)
 -- Name: ix_hangfire_set_key_score; Type: INDEX; Schema: hangfire; Owner: -
 --

 CREATE INDEX ix_hangfire_set_key_score ON hangfire.set USING btree (key, score);


 --
 -- TOC entry 4732 (class 1259 OID 348810)
 -- Name: ix_hangfire_state_jobid; Type: INDEX; Schema: hangfire; Owner: -
 --

 CREATE INDEX ix_hangfire_state_jobid ON hangfire.state USING btree (jobid);


 --
 -- TOC entry 4716 (class 1259 OID 348811)
 -- Name: jobqueue_queue_fetchat_jobid; Type: INDEX; Schema: hangfire; Owner: -
 --

 CREATE INDEX jobqueue_queue_fetchat_jobid ON hangfire.jobqueue USING btree (queue, fetchedat, jobid);


 --
 -- TOC entry 4835 (class 1259 OID 361456)
 -- Name: IX_AccountInvoiceInformationSet_AccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AccountInvoiceInformationSet_AccountId" ON public."AccountInvoiceInformationSet" USING btree ("AccountId");


 --
 -- TOC entry 4853 (class 1259 OID 508973)
 -- Name: IX_AccountMultitenancySet_AccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AccountMultitenancySet_AccountId" ON public."AccountMultitenancySet" USING btree ("AccountId");


 --
 -- TOC entry 4854 (class 1259 OID 2388047)
 -- Name: IX_AccountMultitenancySet_AccountId_TenantId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_AccountMultitenancySet_AccountId_TenantId" ON public."AccountMultitenancySet" USING btree ("AccountId", "TenantId");


 --
 -- TOC entry 4855 (class 1259 OID 2388048)
 -- Name: IX_AccountMultitenancySet_AccountId_TenantIdentifier; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_AccountMultitenancySet_AccountId_TenantIdentifier" ON public."AccountMultitenancySet" USING btree ("AccountId", "TenantIdentifier");


 --
 -- TOC entry 4856 (class 1259 OID 509250)
 -- Name: IX_AccountMultitenancySet_AccountStatusTenantAwareSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AccountMultitenancySet_AccountStatusTenantAwareSetId" ON public."AccountMultitenancySet" USING btree ("AccountStatusTenantAwareSetId");


 --
 -- TOC entry 4857 (class 1259 OID 508975)
 -- Name: IX_AccountMultitenancySet_TenantId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AccountMultitenancySet_TenantId" ON public."AccountMultitenancySet" USING btree ("TenantId");


 --
 -- TOC entry 4921 (class 1259 OID 572645)
 -- Name: IX_AccountQuotaPerDaySet_AccountStatusSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AccountQuotaPerDaySet_AccountStatusSetId" ON public."AccountQuotaPerDaySet" USING btree ("AccountStatusSetId");


 --
 -- TOC entry 5033 (class 1259 OID 2359286)
 -- Name: IX_AccountSetConversationSet_ParticipantAccountsId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AccountSetConversationSet_ParticipantAccountsId" ON public."AccountSetConversationSet" USING btree ("ParticipantAccountsId");


 --
 -- TOC entry 4735 (class 1259 OID 348818)
 -- Name: IX_AccountSet_AccountStatusId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AccountSet_AccountStatusId" ON public."AccountSet" USING btree ("AccountStatusId");


 --
 -- TOC entry 4736 (class 1259 OID 577339)
 -- Name: IX_AccountSet_CompanyImageId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AccountSet_CompanyImageId" ON public."AccountSet" USING btree ("CompanyImageId");


 --
 -- TOC entry 4737 (class 1259 OID 348819)
 -- Name: IX_AccountSet_ProfileImageId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AccountSet_ProfileImageId" ON public."AccountSet" USING btree ("ProfileImageId");


 --
 -- TOC entry 4738 (class 1259 OID 3075757)
 -- Name: IX_AccountSet_PromptEngineeringAiSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AccountSet_PromptEngineeringAiSetId" ON public."AccountSet" USING btree ("PromptEngineeringAiSetId");


 --
 -- TOC entry 4739 (class 1259 OID 556250)
 -- Name: IX_AccountSet_RevenueCutGeneralId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AccountSet_RevenueCutGeneralId" ON public."AccountSet" USING btree ("RevenueCutGeneralId");


 --
 -- TOC entry 4740 (class 1259 OID 348820)
 -- Name: IX_AccountSet_TermsAndConditionsId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AccountSet_TermsAndConditionsId" ON public."AccountSet" USING btree ("TermsAndConditionsId");


 --
 -- TOC entry 4741 (class 1259 OID 348821)
 -- Name: IX_AccountSet_Username; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_AccountSet_Username" ON public."AccountSet" USING btree ("Username");


 --
 -- TOC entry 4918 (class 1259 OID 558853)
 -- Name: IX_AccountStatsSet_AccountSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_AccountStatsSet_AccountSetId" ON public."AccountStatsSet" USING btree ("AccountSetId");


 --
 -- TOC entry 5073 (class 1259 OID 2463430)
 -- Name: IX_AnonymousUserEventTrackingPerDaySet_CreationDay; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AnonymousUserEventTrackingPerDaySet_CreationDay" ON public."AnonymousUserEventTrackingPerDaySet" USING btree ("CreationDay");


 --
 -- TOC entry 5074 (class 1259 OID 2463431)
 -- Name: IX_AnonymousUserEventTrackingPerDaySet_CreationDay_TenantIdent~; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AnonymousUserEventTrackingPerDaySet_CreationDay_TenantIdent~" ON public."AnonymousUserEventTrackingPerDaySet" USING btree ("CreationDay", "TenantIdentifier");


 --
 -- TOC entry 5070 (class 1259 OID 2463424)
 -- Name: IX_AnonymousUserEventTrackingSet_AnonymousUserEventTrackingPer~; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AnonymousUserEventTrackingSet_AnonymousUserEventTrackingPer~" ON public."AnonymousUserEventTrackingSet" USING btree ("AnonymousUserEventTrackingPerDaySetId");


 --
 -- TOC entry 4947 (class 1259 OID 1560310)
 -- Name: IX_AppliedCouponConnection_CouponId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AppliedCouponConnection_CouponId" ON public."AppliedCouponConnection" USING btree ("CouponId");


 --
 -- TOC entry 4948 (class 1259 OID 1560311)
 -- Name: IX_AppliedCouponConnection_PurchaseSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_AppliedCouponConnection_PurchaseSetId" ON public."AppliedCouponConnection" USING btree ("PurchaseSetId");


 --
 -- TOC entry 4980 (class 1259 OID 1561255)
 -- Name: IX_BookingRequestSet_AppointmentSuggestion1Id; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookingRequestSet_AppointmentSuggestion1Id" ON public."BookingRequestSet" USING btree ("AppointmentSuggestion1Id");


 --
 -- TOC entry 4981 (class 1259 OID 1561256)
 -- Name: IX_BookingRequestSet_AppointmentSuggestion2Id; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookingRequestSet_AppointmentSuggestion2Id" ON public."BookingRequestSet" USING btree ("AppointmentSuggestion2Id");


 --
 -- TOC entry 4982 (class 1259 OID 1561257)
 -- Name: IX_BookingRequestSet_AppointmentSuggestion3Id; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookingRequestSet_AppointmentSuggestion3Id" ON public."BookingRequestSet" USING btree ("AppointmentSuggestion3Id");


 --
 -- TOC entry 4983 (class 1259 OID 1561254)
 -- Name: IX_BookingRequestSet_CreatorId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookingRequestSet_CreatorId" ON public."BookingRequestSet" USING btree ("CreatorId");


 --
 -- TOC entry 4984 (class 1259 OID 2662847)
 -- Name: IX_BookingRequestSet_CustomOfferExistingServiceSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookingRequestSet_CustomOfferExistingServiceSetId" ON public."BookingRequestSet" USING btree ("CustomOfferExistingServiceSetId");


 --
 -- TOC entry 4985 (class 1259 OID 1562042)
 -- Name: IX_BookingRequestSet_OneTimePurchaseMicroadvisorySessionProduc~; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookingRequestSet_OneTimePurchaseMicroadvisorySessionProduc~" ON public."BookingRequestSet" USING btree ("OneTimePurchaseMicroadvisorySessionProductId");


 --
 -- TOC entry 4986 (class 1259 OID 1561258)
 -- Name: IX_BookingRequestSet_PaymentInformationId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookingRequestSet_PaymentInformationId" ON public."BookingRequestSet" USING btree ("PaymentInformationId");


 --
 -- TOC entry 4987 (class 1259 OID 1561285)
 -- Name: IX_BookingRequestSet_ProjectSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookingRequestSet_ProjectSetId" ON public."BookingRequestSet" USING btree ("ProjectSetId");


 --
 -- TOC entry 4988 (class 1259 OID 1561259)
 -- Name: IX_BookingRequestSet_RequestId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookingRequestSet_RequestId" ON public."BookingRequestSet" USING btree ("RequestId");


 --
 -- TOC entry 4989 (class 1259 OID 1561267)
 -- Name: IX_BookingRequestSet_Upload1Id; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookingRequestSet_Upload1Id" ON public."BookingRequestSet" USING btree ("Upload1Id");


 --
 -- TOC entry 4990 (class 1259 OID 1561268)
 -- Name: IX_BookingRequestSet_Upload2Id; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookingRequestSet_Upload2Id" ON public."BookingRequestSet" USING btree ("Upload2Id");


 --
 -- TOC entry 4991 (class 1259 OID 1561269)
 -- Name: IX_BookingRequestSet_Upload3Id; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookingRequestSet_Upload3Id" ON public."BookingRequestSet" USING btree ("Upload3Id");


 --
 -- TOC entry 4994 (class 1259 OID 1561314)
 -- Name: IX_BookmarkConnectionExpertStaticSet_BookmarkedAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookmarkConnectionExpertStaticSet_BookmarkedAccountId" ON public."BookmarkConnectionExpertStaticSet" USING btree ("BookmarkedAccountId");


 --
 -- TOC entry 4995 (class 1259 OID 1561315)
 -- Name: IX_BookmarkConnectionExpertStaticSet_FromAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookmarkConnectionExpertStaticSet_FromAccountId" ON public."BookmarkConnectionExpertStaticSet" USING btree ("FromAccountId");


 --
 -- TOC entry 4932 (class 1259 OID 1560069)
 -- Name: IX_BookmarkConnectionServiceStaticSet_BookmarkedServiceId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookmarkConnectionServiceStaticSet_BookmarkedServiceId" ON public."BookmarkConnectionServiceStaticSet" USING btree ("BookmarkedServiceId");


 --
 -- TOC entry 4933 (class 1259 OID 1560052)
 -- Name: IX_BookmarkConnectionServiceStaticSet_FromAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookmarkConnectionServiceStaticSet_FromAccountId" ON public."BookmarkConnectionServiceStaticSet" USING btree ("FromAccountId");


 --
 -- TOC entry 4936 (class 1259 OID 1560053)
 -- Name: IX_BookmarkConnectionWithHistoryBaseSet_BookmarkedAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookmarkConnectionWithHistoryBaseSet_BookmarkedAccountId" ON public."BookmarkConnectionWithHistoryBaseSet" USING btree ("BookmarkedAccountId");


 --
 -- TOC entry 4937 (class 1259 OID 1560067)
 -- Name: IX_BookmarkConnectionWithHistoryBaseSet_BookmarkedServiceId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookmarkConnectionWithHistoryBaseSet_BookmarkedServiceId" ON public."BookmarkConnectionWithHistoryBaseSet" USING btree ("BookmarkedServiceId");


 --
 -- TOC entry 4938 (class 1259 OID 1560054)
 -- Name: IX_BookmarkConnectionWithHistoryBaseSet_BookmarkingAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_BookmarkConnectionWithHistoryBaseSet_BookmarkingAccountId" ON public."BookmarkConnectionWithHistoryBaseSet" USING btree ("BookmarkingAccountId");


 --
 -- TOC entry 5107 (class 1259 OID 3075791)
 -- Name: IX_CognitoUserIdSet_AccountSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_CognitoUserIdSet_AccountSetId" ON public."CognitoUserIdSet" USING btree ("AccountSetId");


 --
 -- TOC entry 5108 (class 1259 OID 3075792)
 -- Name: IX_CognitoUserIdSet_CognitoUserId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_CognitoUserIdSet_CognitoUserId" ON public."CognitoUserIdSet" USING btree ("CognitoUserId");


 --
 -- TOC entry 5111 (class 1259 OID 3075793)
 -- Name: IX_CognitoUsernameSet_CognitoUserIdSetCognitoUserId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_CognitoUsernameSet_CognitoUserIdSetCognitoUserId" ON public."CognitoUsernameSet" USING btree ("CognitoUserIdSetCognitoUserId");


 --
 -- TOC entry 5112 (class 1259 OID 3075794)
 -- Name: IX_CognitoUsernameSet_Username; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_CognitoUsernameSet_Username" ON public."CognitoUsernameSet" USING btree ("Username");


 --
 -- TOC entry 5043 (class 1259 OID 2359287)
 -- Name: IX_ConversationMessageReadByAccountSet_AccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ConversationMessageReadByAccountSet_AccountId" ON public."ConversationMessageReadByAccountSet" USING btree ("AccountId");


 --
 -- TOC entry 5044 (class 1259 OID 2359288)
 -- Name: IX_ConversationMessageReadByAccountSet_ConversationMessageId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ConversationMessageReadByAccountSet_ConversationMessageId" ON public."ConversationMessageReadByAccountSet" USING btree ("ConversationMessageId");


 --
 -- TOC entry 5036 (class 1259 OID 2359289)
 -- Name: IX_ConversationMessageSet_ConversationSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ConversationMessageSet_ConversationSetId" ON public."ConversationMessageSet" USING btree ("ConversationSetId");


 --
 -- TOC entry 5037 (class 1259 OID 2359290)
 -- Name: IX_ConversationMessageSet_CreatorAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ConversationMessageSet_CreatorAccountId" ON public."ConversationMessageSet" USING btree ("CreatorAccountId");


 --
 -- TOC entry 5038 (class 1259 OID 2662839)
 -- Name: IX_ConversationMessageSet_CustomOfferExistingServiceSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ConversationMessageSet_CustomOfferExistingServiceSetId" ON public."ConversationMessageSet" USING btree ("CustomOfferExistingServiceSetId");


 --
 -- TOC entry 5039 (class 1259 OID 2359291)
 -- Name: IX_ConversationMessageSet_MeetingInformationId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ConversationMessageSet_MeetingInformationId" ON public."ConversationMessageSet" USING btree ("MeetingInformationId");


 --
 -- TOC entry 5040 (class 1259 OID 2359292)
 -- Name: IX_ConversationMessageSet_ReplyOnMessageId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ConversationMessageSet_ReplyOnMessageId" ON public."ConversationMessageSet" USING btree ("ReplyOnMessageId");


 --
 -- TOC entry 5025 (class 1259 OID 3165792)
 -- Name: IX_ConversationSet_CreatorAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ConversationSet_CreatorAccountId" ON public."ConversationSet" USING btree ("CreatorAccountId");


 --
 -- TOC entry 5026 (class 1259 OID 2359403)
 -- Name: IX_ConversationSet_IsPinned; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ConversationSet_IsPinned" ON public."ConversationSet" USING btree ("IsPinned");


 --
 -- TOC entry 5027 (class 1259 OID 2359404)
 -- Name: IX_ConversationSet_IsPinned_LastModifiedDate; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ConversationSet_IsPinned_LastModifiedDate" ON public."ConversationSet" USING btree ("IsPinned", "LastModifiedDate");


 --
 -- TOC entry 5028 (class 1259 OID 2359405)
 -- Name: IX_ConversationSet_LastModifiedDate; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ConversationSet_LastModifiedDate" ON public."ConversationSet" USING btree ("LastModifiedDate");


 --
 -- TOC entry 5029 (class 1259 OID 2359301)
 -- Name: IX_ConversationSet_ProjectId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_ConversationSet_ProjectId" ON public."ConversationSet" USING btree ("ProjectId");


 --
 -- TOC entry 5030 (class 1259 OID 3165798)
 -- Name: IX_ConversationSet_ServiceSearchSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ConversationSet_ServiceSearchSetId" ON public."ConversationSet" USING btree ("ServiceSearchSetId");


 --
 -- TOC entry 5067 (class 1259 OID 2360284)
 -- Name: IX_CouponPurchaseDetailsSet_CouponsId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_CouponPurchaseDetailsSet_CouponsId" ON public."CouponPurchaseDetailsSet" USING btree ("CouponsId");


 --
 -- TOC entry 4944 (class 1259 OID 1560312)
 -- Name: IX_Coupon_Identifier; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_Coupon_Identifier" ON public."Coupon" USING btree ("Identifier");


 --
 -- TOC entry 4746 (class 1259 OID 348822)
 -- Name: IX_CustomAccountLinkSet_AccountSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_CustomAccountLinkSet_AccountSetId" ON public."CustomAccountLinkSet" USING btree ("AccountSetId");


 --
 -- TOC entry 4747 (class 1259 OID 348823)
 -- Name: IX_CustomAccountLinkSet_CustomLinkUrlEncoded; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_CustomAccountLinkSet_CustomLinkUrlEncoded" ON public."CustomAccountLinkSet" USING btree ("CustomLinkUrlEncoded");


 --
 -- TOC entry 5098 (class 1259 OID 2662874)
 -- Name: IX_CustomOfferConnectionStaticSet_CustomOfferSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_CustomOfferConnectionStaticSet_CustomOfferSetId" ON public."CustomOfferConnectionStaticSet" USING btree ("CustomOfferSetId");


 --
 -- TOC entry 5099 (class 1259 OID 2662875)
 -- Name: IX_CustomOfferConnectionStaticSet_ForAccountSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_CustomOfferConnectionStaticSet_ForAccountSetId" ON public."CustomOfferConnectionStaticSet" USING btree ("ForAccountSetId");


 --
 -- TOC entry 5094 (class 1259 OID 2662840)
 -- Name: IX_CustomOfferSet_SecretKey; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_CustomOfferSet_SecretKey" ON public."CustomOfferSet" USING btree ("SecretKey");


 --
 -- TOC entry 5095 (class 1259 OID 2662841)
 -- Name: IX_CustomOfferSet_ServiceSearchSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_CustomOfferSet_ServiceSearchSetId" ON public."CustomOfferSet" USING btree ("ServiceSearchSetId");


 --
 -- TOC entry 4864 (class 1259 OID 510167)
 -- Name: IX_FaqSet_FaqCategorySetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_FaqSet_FaqCategorySetId" ON public."FaqSet" USING btree ("FaqCategorySetId");


 --
 -- TOC entry 4842 (class 1259 OID 431653)
 -- Name: IX_FeaturedExpertsServiceSet_FeaturedExpertId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_FeaturedExpertsServiceSet_FeaturedExpertId" ON public."FeaturedExpertsServiceSet" USING btree ("FeaturedExpertId");


 --
 -- TOC entry 4752 (class 1259 OID 348824)
 -- Name: IX_GoalSet_ExpertAccountSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_GoalSet_ExpertAccountSetId" ON public."GoalSet" USING btree ("ExpertAccountSetId");


 --
 -- TOC entry 4753 (class 1259 OID 348827)
 -- Name: IX_GoalSet_OwnerAccountSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_GoalSet_OwnerAccountSetId" ON public."GoalSet" USING btree ("OwnerAccountSetId");


 --
 -- TOC entry 4754 (class 1259 OID 348828)
 -- Name: IX_GoalSet_ParentGoalId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_GoalSet_ParentGoalId" ON public."GoalSet" USING btree ("ParentGoalId");


 --
 -- TOC entry 4755 (class 1259 OID 348829)
 -- Name: IX_GoalSet_ProjectSetOrNullId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_GoalSet_ProjectSetOrNullId" ON public."GoalSet" USING btree ("ProjectSetOrNullId");


 --
 -- TOC entry 4756 (class 1259 OID 2359361)
 -- Name: IX_GoalSet_ServiceTypeCategoryTranslationKey_ServiceTypeTransl~; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_GoalSet_ServiceTypeCategoryTranslationKey_ServiceTypeTransl~" ON public."GoalSet" USING btree ("ServiceTypeCategoryTranslationKey", "ServiceTypeTranslationKey");


 --
 -- TOC entry 4757 (class 1259 OID 348830)
 -- Name: IX_GoalSet_ServiceTypeEnumSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_GoalSet_ServiceTypeEnumSetId" ON public."GoalSet" USING btree ("ServiceTypeEnumSetId");


 --
 -- TOC entry 4874 (class 1259 OID 510279)
 -- Name: IX_HashtagConnectionSet_AccountUsedItId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_HashtagConnectionSet_AccountUsedItId" ON public."HashtagConnectionSet" USING btree ("AccountUsedItId");


 --
 -- TOC entry 4875 (class 1259 OID 556517)
 -- Name: IX_HashtagConnectionSet_HashtagSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_HashtagConnectionSet_HashtagSetId" ON public."HashtagConnectionSet" USING btree ("HashtagSetId");


 --
 -- TOC entry 4876 (class 1259 OID 510281)
 -- Name: IX_HashtagConnectionSet_UserStorySetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_HashtagConnectionSet_UserStorySetId" ON public."HashtagConnectionSet" USING btree ("UserStorySetId");


 --
 -- TOC entry 4867 (class 1259 OID 510231)
 -- Name: IX_HashtagSet_FirstCreatedById; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_HashtagSet_FirstCreatedById" ON public."HashtagSet" USING btree ("FirstCreatedById");


 --
 -- TOC entry 4868 (class 1259 OID 556530)
 -- Name: IX_HashtagSet_HashtagNormalizedLowercase; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_HashtagSet_HashtagNormalizedLowercase" ON public."HashtagSet" USING btree ("HashtagNormalizedLowercase");


 --
 -- TOC entry 5022 (class 1259 OID 2259137)
 -- Name: IX_HubspotMappingSet_HubspotMappingTypeEnum_HalloSophiaId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_HubspotMappingSet_HubspotMappingTypeEnum_HalloSophiaId" ON public."HubspotMappingSet" USING btree ("HubspotMappingTypeEnum", "HalloSophiaId");


 --
 -- TOC entry 4924 (class 1259 OID 3075856)
 -- Name: IX_InviteConnectionSet_AccountId_KycCompanyId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_InviteConnectionSet_AccountId_KycCompanyId" ON public."InviteConnectionSet" USING btree ("AccountId", "KycCompanyId");


 --
 -- TOC entry 4925 (class 1259 OID 574920)
 -- Name: IX_InviteConnectionSet_GuestJoinKey; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_InviteConnectionSet_GuestJoinKey" ON public."InviteConnectionSet" USING btree ("GuestJoinKey");


 --
 -- TOC entry 4926 (class 1259 OID 3075877)
 -- Name: IX_InviteConnectionSet_InviterId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_InviteConnectionSet_InviterId" ON public."InviteConnectionSet" USING btree ("InviterId");


 --
 -- TOC entry 4927 (class 1259 OID 3075857)
 -- Name: IX_InviteConnectionSet_KycCompanyId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_InviteConnectionSet_KycCompanyId" ON public."InviteConnectionSet" USING btree ("KycCompanyId");


 --
 -- TOC entry 4928 (class 1259 OID 574921)
 -- Name: IX_InviteConnectionSet_MeetingInformationSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_InviteConnectionSet_MeetingInformationSetId" ON public."InviteConnectionSet" USING btree ("MeetingInformationSetId");


 --
 -- TOC entry 4929 (class 1259 OID 3075858)
 -- Name: IX_InviteConnectionSet_RegistrationWaitinglistEntrySetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_InviteConnectionSet_RegistrationWaitinglistEntrySetId" ON public."InviteConnectionSet" USING btree ("RegistrationWaitinglistEntrySetId");


 --
 -- TOC entry 5115 (class 1259 OID 3075859)
 -- Name: IX_KycCompanyConnectionAccountStaticSet_AccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_KycCompanyConnectionAccountStaticSet_AccountId" ON public."KycCompanyConnectionAccountStaticSet" USING btree ("AccountId");


 --
 -- TOC entry 5116 (class 1259 OID 3075860)
 -- Name: IX_KycCompanyConnectionAccountStaticSet_KycCompanyId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_KycCompanyConnectionAccountStaticSet_KycCompanyId" ON public."KycCompanyConnectionAccountStaticSet" USING btree ("KycCompanyId");


 --
 -- TOC entry 5119 (class 1259 OID 3075861)
 -- Name: IX_KycCompanyStashSet_OwnerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_KycCompanyStashSet_OwnerId" ON public."KycCompanyStashSet" USING btree ("OwnerId");


 --
 -- TOC entry 5017 (class 1259 OID 2243710)
 -- Name: IX_KycCompany_MangopayInfoId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_KycCompany_MangopayInfoId" ON public."KycCompany" USING btree ("MangopayInfoId");


 --
 -- TOC entry 5018 (class 1259 OID 3075855)
 -- Name: IX_KycCompany_Name; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_KycCompany_Name" ON public."KycCompany" USING btree ("Name");


 --
 -- TOC entry 5019 (class 1259 OID 2243711)
 -- Name: IX_KycCompany_OwnerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_KycCompany_OwnerId" ON public."KycCompany" USING btree ("OwnerId");


 --
 -- TOC entry 5001 (class 1259 OID 1648018)
 -- Name: IX_KycDocumentSet_AccountSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_KycDocumentSet_AccountSetId" ON public."KycDocumentSet" USING btree ("AccountSetId");


 --
 -- TOC entry 5002 (class 1259 OID 2243709)
 -- Name: IX_KycDocumentSet_KycCompanyId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_KycDocumentSet_KycCompanyId" ON public."KycDocumentSet" USING btree ("KycCompanyId");


 --
 -- TOC entry 5003 (class 1259 OID 1648019)
 -- Name: IX_KycDocumentSet_KycDocumentId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_KycDocumentSet_KycDocumentId" ON public."KycDocumentSet" USING btree ("KycDocumentId");


 --
 -- TOC entry 5082 (class 1259 OID 2477132)
 -- Name: IX_LegalDocumentSequenceSet_DocumentId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_LegalDocumentSequenceSet_DocumentId" ON public."LegalDocumentSequenceSet" USING btree ("DocumentId");


 --
 -- TOC entry 5083 (class 1259 OID 2477138)
 -- Name: IX_LegalDocumentSequenceSet_Prefix_SequenceNumber_OverflowCount; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_LegalDocumentSequenceSet_Prefix_SequenceNumber_OverflowCount" ON public."LegalDocumentSequenceSet" USING btree ("Prefix", "SequenceNumber", "OverflowCount");


 --
 -- TOC entry 5077 (class 1259 OID 2477134)
 -- Name: IX_LegalDocumentSet_CreatorAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_LegalDocumentSet_CreatorAccountId" ON public."LegalDocumentSet" USING btree ("CreatorAccountId");


 --
 -- TOC entry 5078 (class 1259 OID 2477135)
 -- Name: IX_LegalDocumentSet_DocumentId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_LegalDocumentSet_DocumentId" ON public."LegalDocumentSet" USING btree ("DocumentId");


 --
 -- TOC entry 5079 (class 1259 OID 2477136)
 -- Name: IX_LegalDocumentSet_ProjectId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_LegalDocumentSet_ProjectId" ON public."LegalDocumentSet" USING btree ("ProjectId");


 --
 -- TOC entry 4760 (class 1259 OID 348832)
 -- Name: IX_LikeAndFollowExpertHistory_LikedAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_LikeAndFollowExpertHistory_LikedAccountId" ON public."LikeAndFollowExpertHistory" USING btree ("LikedAccountId");


 --
 -- TOC entry 4761 (class 1259 OID 348833)
 -- Name: IX_LikeAndFollowExpertHistory_LikerAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_LikeAndFollowExpertHistory_LikerAccountId" ON public."LikeAndFollowExpertHistory" USING btree ("LikerAccountId");


 --
 -- TOC entry 4764 (class 1259 OID 1564269)
 -- Name: IX_MeetingInformationSet_AppointmentDateIfFinalized; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MeetingInformationSet_AppointmentDateIfFinalized" ON public."MeetingInformationSet" USING btree ("AppointmentDateIfFinalized");


 --
 -- TOC entry 4765 (class 1259 OID 1564270)
 -- Name: IX_MeetingInformationSet_AppointmentStatusEnum; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MeetingInformationSet_AppointmentStatusEnum" ON public."MeetingInformationSet" USING btree ("AppointmentStatusEnum");


 --
 -- TOC entry 4766 (class 1259 OID 348834)
 -- Name: IX_MeetingInformationSet_CreatorId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MeetingInformationSet_CreatorId" ON public."MeetingInformationSet" USING btree ("CreatorId");


 --
 -- TOC entry 4767 (class 1259 OID 348835)
 -- Name: IX_MeetingInformationSet_JoinKey; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MeetingInformationSet_JoinKey" ON public."MeetingInformationSet" USING btree ("JoinKey");


 --
 -- TOC entry 4768 (class 1259 OID 1564271)
 -- Name: IX_MeetingInformationSet_MeetingEndDate; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MeetingInformationSet_MeetingEndDate" ON public."MeetingInformationSet" USING btree ("MeetingEndDate");


 --
 -- TOC entry 4769 (class 1259 OID 1564272)
 -- Name: IX_MeetingInformationSet_MeetingStartDate; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MeetingInformationSet_MeetingStartDate" ON public."MeetingInformationSet" USING btree ("MeetingStartDate");


 --
 -- TOC entry 4770 (class 1259 OID 361455)
 -- Name: IX_MeetingInformationSet_PaymentInformationId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MeetingInformationSet_PaymentInformationId" ON public."MeetingInformationSet" USING btree ("PaymentInformationId");


 --
 -- TOC entry 4771 (class 1259 OID 509579)
 -- Name: IX_MeetingInformationSet_TenantId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MeetingInformationSet_TenantId" ON public."MeetingInformationSet" USING btree ("TenantId");


 --
 -- TOC entry 4774 (class 1259 OID 348836)
 -- Name: IX_MeetingWhitelistAccountEntrySet_AccountSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MeetingWhitelistAccountEntrySet_AccountSetId" ON public."MeetingWhitelistAccountEntrySet" USING btree ("AccountSetId");


 --
 -- TOC entry 4775 (class 1259 OID 348837)
 -- Name: IX_MeetingWhitelistAccountEntrySet_MeetingInformationSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MeetingWhitelistAccountEntrySet_MeetingInformationSetId" ON public."MeetingWhitelistAccountEntrySet" USING btree ("MeetingInformationSetId");


 --
 -- TOC entry 4778 (class 1259 OID 348838)
 -- Name: IX_MeetingWhitelistEmailEntrySet_Email; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MeetingWhitelistEmailEntrySet_Email" ON public."MeetingWhitelistEmailEntrySet" USING btree ("Email");


 --
 -- TOC entry 4779 (class 1259 OID 348839)
 -- Name: IX_MeetingWhitelistEmailEntrySet_MeetingInformationSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MeetingWhitelistEmailEntrySet_MeetingInformationSetId" ON public."MeetingWhitelistEmailEntrySet" USING btree ("MeetingInformationSetId");


 --
 -- TOC entry 4894 (class 1259 OID 556653)
 -- Name: IX_MentionConnectionSet_AboutAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MentionConnectionSet_AboutAccountId" ON public."MentionConnectionSet" USING btree ("AboutAccountId");


 --
 -- TOC entry 4895 (class 1259 OID 556860)
 -- Name: IX_MentionConnectionSet_AboutServiceId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MentionConnectionSet_AboutServiceId" ON public."MentionConnectionSet" USING btree ("AboutServiceId");


 --
 -- TOC entry 4896 (class 1259 OID 556874)
 -- Name: IX_MentionConnectionSet_AboutServiceTypeId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MentionConnectionSet_AboutServiceTypeId" ON public."MentionConnectionSet" USING btree ("AboutServiceTypeId");


 --
 -- TOC entry 4897 (class 1259 OID 556654)
 -- Name: IX_MentionConnectionSet_FromAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MentionConnectionSet_FromAccountId" ON public."MentionConnectionSet" USING btree ("FromAccountId");


 --
 -- TOC entry 4898 (class 1259 OID 556861)
 -- Name: IX_MentionConnectionSet_UserStoryAboutServiceConnectionSet_Use~; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MentionConnectionSet_UserStoryAboutServiceConnectionSet_Use~" ON public."MentionConnectionSet" USING btree ("UserStoryAboutServiceConnectionSet_UserStorySetId");


 --
 -- TOC entry 4899 (class 1259 OID 556875)
 -- Name: IX_MentionConnectionSet_UserStoryAboutServiceTypeConnectionSet~; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MentionConnectionSet_UserStoryAboutServiceTypeConnectionSet~" ON public."MentionConnectionSet" USING btree ("UserStoryAboutServiceTypeConnectionSet_UserStorySetId");


 --
 -- TOC entry 4900 (class 1259 OID 556655)
 -- Name: IX_MentionConnectionSet_UserStorySetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MentionConnectionSet_UserStorySetId" ON public."MentionConnectionSet" USING btree ("UserStorySetId");


 --
 -- TOC entry 4782 (class 1259 OID 348840)
 -- Name: IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Acc~; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Acc~" ON public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet" USING btree ("AccountRequestBelongsToOrNull");


 --
 -- TOC entry 4783 (class 1259 OID 348841)
 -- Name: IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Ac~1; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Ac~1" ON public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet" USING btree ("AccountSetId");


 --
 -- TOC entry 4784 (class 1259 OID 348842)
 -- Name: IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_App~; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_App~" ON public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet" USING btree ("AppointmentSuggestion1Id");


 --
 -- TOC entry 4785 (class 1259 OID 348843)
 -- Name: IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Ap~1; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Ap~1" ON public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet" USING btree ("AppointmentSuggestion2Id");


 --
 -- TOC entry 4786 (class 1259 OID 348844)
 -- Name: IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Ap~2; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Ap~2" ON public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet" USING btree ("AppointmentSuggestion3Id");


 --
 -- TOC entry 4787 (class 1259 OID 361454)
 -- Name: IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Pay~; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Pay~" ON public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet" USING btree ("PaymentInformationId");


 --
 -- TOC entry 4788 (class 1259 OID 348845)
 -- Name: IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Req~; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Req~" ON public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet" USING btree ("RequestId");


 --
 -- TOC entry 4791 (class 1259 OID 348846)
 -- Name: IX_NotificationSet_AccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_NotificationSet_AccountId" ON public."NotificationSet" USING btree ("AccountId");


 --
 -- TOC entry 4792 (class 1259 OID 348847)
 -- Name: IX_NotificationSet_MeetingInformationId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_NotificationSet_MeetingInformationId" ON public."NotificationSet" USING btree ("MeetingInformationId");


 --
 -- TOC entry 4793 (class 1259 OID 1564274)
 -- Name: IX_NotificationSet_NotificationTypeEnum; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_NotificationSet_NotificationTypeEnum" ON public."NotificationSet" USING btree ("NotificationTypeEnum");


 --
 -- TOC entry 4794 (class 1259 OID 348848)
 -- Name: IX_NotificationSet_PriorId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_NotificationSet_PriorId" ON public."NotificationSet" USING btree ("PriorId");


 --
 -- TOC entry 4795 (class 1259 OID 348849)
 -- Name: IX_NotificationSet_ProjectId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_NotificationSet_ProjectId" ON public."NotificationSet" USING btree ("ProjectId");


 --
 -- TOC entry 4796 (class 1259 OID 348850)
 -- Name: IX_NotificationSet_SenderId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_NotificationSet_SenderId" ON public."NotificationSet" USING btree ("SenderId");


 --
 -- TOC entry 5014 (class 1259 OID 2196006)
 -- Name: IX_OfficeHoursBreakSet_ExpertAccountSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_OfficeHoursBreakSet_ExpertAccountSetId" ON public."OfficeHoursBreakSet" USING btree ("ExpertAccountSetId");


 --
 -- TOC entry 4797 (class 1259 OID 348851)
 -- Name: IX_OfficeHoursSet_ExpertAccountSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_OfficeHoursSet_ExpertAccountSetId" ON public."OfficeHoursSet" USING btree ("ExpertAccountSetId");


 --
 -- TOC entry 5102 (class 1259 OID 3075710)
 -- Name: IX_PaymentAvailabilityInCountrySet_CountryCode; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_PaymentAvailabilityInCountrySet_CountryCode" ON public."PaymentAvailabilityInCountrySet" USING btree ("CountryCode");


 --
 -- TOC entry 4909 (class 1259 OID 556859)
 -- Name: IX_ProductList_Identifier; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_ProductList_Identifier" ON public."ProductList" USING btree ("Identifier");


 --
 -- TOC entry 4912 (class 1259 OID 556777)
 -- Name: IX_ProductToProductList_ProductId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ProductToProductList_ProductId" ON public."ProductToProductList" USING btree ("ProductId");


 --
 -- TOC entry 4913 (class 1259 OID 556778)
 -- Name: IX_ProductToProductList_ProductListId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ProductToProductList_ProductListId" ON public."ProductToProductList" USING btree ("ProductListId");


 --
 -- TOC entry 4903 (class 1259 OID 577313)
 -- Name: IX_Product_AssignedToId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_Product_AssignedToId" ON public."Product" USING btree ("AssignedToId");


 --
 -- TOC entry 4904 (class 1259 OID 556776)
 -- Name: IX_Product_Identifier; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_Product_Identifier" ON public."Product" USING btree ("Identifier");


 --
 -- TOC entry 4905 (class 1259 OID 577324)
 -- Name: IX_Product_ServiceId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_Product_ServiceId" ON public."Product" USING btree ("ServiceId");


 --
 -- TOC entry 4906 (class 1259 OID 2298072)
 -- Name: IX_Product_TenantSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_Product_TenantSetId" ON public."Product" USING btree ("TenantSetId");


 --
 -- TOC entry 4800 (class 1259 OID 348852)
 -- Name: IX_ProjectSet_ExpertId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ProjectSet_ExpertId" ON public."ProjectSet" USING btree ("ExpertId");


 --
 -- TOC entry 4801 (class 1259 OID 1564273)
 -- Name: IX_ProjectSet_MeetingInformationId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_ProjectSet_MeetingInformationId" ON public."ProjectSet" USING btree ("MeetingInformationId");


 --
 -- TOC entry 4802 (class 1259 OID 348855)
 -- Name: IX_ProjectSet_RequestorId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ProjectSet_RequestorId" ON public."ProjectSet" USING btree ("RequestorId");


 --
 -- TOC entry 4803 (class 1259 OID 2191536)
 -- Name: IX_ProjectSet_ServiceId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ProjectSet_ServiceId" ON public."ProjectSet" USING btree ("ServiceId");


 --
 -- TOC entry 4804 (class 1259 OID 348856)
 -- Name: IX_ProjectSet_Upload1Id; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ProjectSet_Upload1Id" ON public."ProjectSet" USING btree ("Upload1Id");


 --
 -- TOC entry 4805 (class 1259 OID 348857)
 -- Name: IX_ProjectSet_Upload2Id; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ProjectSet_Upload2Id" ON public."ProjectSet" USING btree ("Upload2Id");


 --
 -- TOC entry 4806 (class 1259 OID 348858)
 -- Name: IX_ProjectSet_Upload3Id; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ProjectSet_Upload3Id" ON public."ProjectSet" USING btree ("Upload3Id");


 --
 -- TOC entry 5060 (class 1259 OID 2360285)
 -- Name: IX_PurchaseDetailsSet_CreatorAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_PurchaseDetailsSet_CreatorAccountId" ON public."PurchaseDetailsSet" USING btree ("CreatorAccountId");


 --
 -- TOC entry 5061 (class 1259 OID 2360286)
 -- Name: IX_PurchaseDetailsSet_MainPlatformTransactionDetailsId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_PurchaseDetailsSet_MainPlatformTransactionDetailsId" ON public."PurchaseDetailsSet" USING btree ("MainPlatformTransactionDetailsId");


 --
 -- TOC entry 5062 (class 1259 OID 2360287)
 -- Name: IX_PurchaseDetailsSet_SupplierTransactionDetailsId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_PurchaseDetailsSet_SupplierTransactionDetailsId" ON public."PurchaseDetailsSet" USING btree ("SupplierTransactionDetailsId");


 --
 -- TOC entry 5063 (class 1259 OID 2360288)
 -- Name: IX_PurchaseDetailsSet_TenantId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_PurchaseDetailsSet_TenantId" ON public."PurchaseDetailsSet" USING btree ("TenantId");


 --
 -- TOC entry 5064 (class 1259 OID 2360289)
 -- Name: IX_PurchaseDetailsSet_TenantTransactionDetailsId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_PurchaseDetailsSet_TenantTransactionDetailsId" ON public."PurchaseDetailsSet" USING btree ("TenantTransactionDetailsId");


 --
 -- TOC entry 5086 (class 1259 OID 2655771)
 -- Name: IX_Purchase_BeneficiaryId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_Purchase_BeneficiaryId" ON public."Purchase" USING btree ("BeneficiaryId");


 --
 -- TOC entry 5087 (class 1259 OID 2655772)
 -- Name: IX_Purchase_BoughtProductId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_Purchase_BoughtProductId" ON public."Purchase" USING btree ("BoughtProductId");


 --
 -- TOC entry 5088 (class 1259 OID 2655773)
 -- Name: IX_Purchase_BuyerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_Purchase_BuyerId" ON public."Purchase" USING btree ("BuyerId");


 --
 -- TOC entry 5089 (class 1259 OID 2655774)
 -- Name: IX_Purchase_ProductId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_Purchase_ProductId" ON public."Purchase" USING btree ("ProductId");


 --
 -- TOC entry 5090 (class 1259 OID 2655775)
 -- Name: IX_Purchase_ProjectSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_Purchase_ProjectSetId" ON public."Purchase" USING btree ("ProjectSetId");


 --
 -- TOC entry 5091 (class 1259 OID 2655776)
 -- Name: IX_Purchase_PurchaseDetailsId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_Purchase_PurchaseDetailsId" ON public."Purchase" USING btree ("PurchaseDetailsId");


 --
 -- TOC entry 4809 (class 1259 OID 3075854)
 -- Name: IX_RegistrationWaitinglist_FutureUsername; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_RegistrationWaitinglist_FutureUsername" ON public."RegistrationWaitinglist" USING btree ("FutureUsername");


 --
 -- TOC entry 4887 (class 1259 OID 556279)
 -- Name: IX_RevenueCutGeneral_CreatedById; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_RevenueCutGeneral_CreatedById" ON public."RevenueCutGeneral" USING btree ("CreatedById");


 --
 -- TOC entry 4890 (class 1259 OID 556278)
 -- Name: IX_RevenueCutTenant_CreatedById; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_RevenueCutTenant_CreatedById" ON public."RevenueCutTenant" USING btree ("CreatedById");


 --
 -- TOC entry 4891 (class 1259 OID 556235)
 -- Name: IX_RevenueCutTenant_TenantId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_RevenueCutTenant_TenantId" ON public."RevenueCutTenant" USING btree ("TenantId");


 --
 -- TOC entry 4882 (class 1259 OID 555362)
 -- Name: IX_ServiceRatingAfterMeetingSet_AccountThatVotedId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceRatingAfterMeetingSet_AccountThatVotedId" ON public."ServiceRatingAfterMeetingSet" USING btree ("AccountThatVotedId");


 --
 -- TOC entry 4883 (class 1259 OID 555363)
 -- Name: IX_ServiceRatingAfterMeetingSet_AccountToRateId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceRatingAfterMeetingSet_AccountToRateId" ON public."ServiceRatingAfterMeetingSet" USING btree ("AccountToRateId");


 --
 -- TOC entry 4884 (class 1259 OID 555364)
 -- Name: IX_ServiceRatingAfterMeetingSet_MeetingInformationSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceRatingAfterMeetingSet_MeetingInformationSetId" ON public."ServiceRatingAfterMeetingSet" USING btree ("MeetingInformationSetId");


 --
 -- TOC entry 4831 (class 1259 OID 359694)
 -- Name: IX_ServiceSearchSet_ExpertAccountSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceSearchSet_ExpertAccountSetId" ON public."ServiceSearchSet" USING btree ("ExpertAccountSetId");


 --
 -- TOC entry 4954 (class 1259 OID 1560639)
 -- Name: IX_ServiceSettingsAdvisingStatusStashSet_OwnerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceSettingsAdvisingStatusStashSet_OwnerId" ON public."ServiceSettingsAdvisingStatusStashSet" USING btree ("OwnerId");


 --
 -- TOC entry 4957 (class 1259 OID 1560671)
 -- Name: IX_ServiceSettingsCallDurationStashSet_OwnerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceSettingsCallDurationStashSet_OwnerId" ON public."ServiceSettingsCallDurationStashSet" USING btree ("OwnerId");


 --
 -- TOC entry 4966 (class 1259 OID 1560704)
 -- Name: IX_ServiceSettingsCountriesStashSet_OwnerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceSettingsCountriesStashSet_OwnerId" ON public."ServiceSettingsCountriesStashSet" USING btree ("OwnerId");


 --
 -- TOC entry 4969 (class 1259 OID 1560721)
 -- Name: IX_ServiceSettingsLanguagesStashSet_OwnerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceSettingsLanguagesStashSet_OwnerId" ON public."ServiceSettingsLanguagesStashSet" USING btree ("OwnerId");


 --
 -- TOC entry 4963 (class 1259 OID 1560688)
 -- Name: IX_ServiceSettingsOfficeHoursStashSet_OwnerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceSettingsOfficeHoursStashSet_OwnerId" ON public."ServiceSettingsOfficeHoursStashSet" USING btree ("OwnerId");


 --
 -- TOC entry 4960 (class 1259 OID 1560672)
 -- Name: IX_ServiceSettingsPricingModelStashSet_OwnerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceSettingsPricingModelStashSet_OwnerId" ON public."ServiceSettingsPricingModelStashSet" USING btree ("OwnerId");


 --
 -- TOC entry 4998 (class 1259 OID 1561361)
 -- Name: IX_ServiceSettingsPublishDraftStashSet_OwnerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceSettingsPublishDraftStashSet_OwnerId" ON public."ServiceSettingsPublishDraftStashSet" USING btree ("OwnerId");


 --
 -- TOC entry 4972 (class 1259 OID 1560737)
 -- Name: IX_ServiceSettingsPublishInfoStashSet_OwnerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceSettingsPublishInfoStashSet_OwnerId" ON public."ServiceSettingsPublishInfoStashSet" USING btree ("OwnerId");


 --
 -- TOC entry 4951 (class 1259 OID 1560588)
 -- Name: IX_ServiceSettingsServicesStashSet_OwnerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceSettingsServicesStashSet_OwnerId" ON public."ServiceSettingsServicesStashSet" USING btree ("OwnerId");


 --
 -- TOC entry 4941 (class 1259 OID 1560070)
 -- Name: IX_ServiceStatsSet_ServiceSearchSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_ServiceStatsSet_ServiceSearchSetId" ON public."ServiceStatsSet" USING btree ("ServiceSearchSetId");


 --
 -- TOC entry 5054 (class 1259 OID 2359709)
 -- Name: IX_ServiceTypeCategoryConnectionTenantStaticSet_ServiceTypeCat~; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceTypeCategoryConnectionTenantStaticSet_ServiceTypeCat~" ON public."ServiceTypeCategoryConnectionTenantStaticSet" USING btree ("ServiceTypeCategoryEnumSetId");


 --
 -- TOC entry 5055 (class 1259 OID 2359710)
 -- Name: IX_ServiceTypeCategoryConnectionTenantStaticSet_TenantSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceTypeCategoryConnectionTenantStaticSet_TenantSetId" ON public."ServiceTypeCategoryConnectionTenantStaticSet" USING btree ("TenantSetId");


 --
 -- TOC entry 4812 (class 1259 OID 577061)
 -- Name: IX_ServiceTypeCategoryEnumSet_TranslationKey; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceTypeCategoryEnumSet_TranslationKey" ON public."ServiceTypeCategoryEnumSet" USING btree ("TranslationKey");


 --
 -- TOC entry 4815 (class 1259 OID 556436)
 -- Name: IX_ServiceTypeEnumSet_IconId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceTypeEnumSet_IconId" ON public."ServiceTypeEnumSet" USING btree ("IconId");


 --
 -- TOC entry 4816 (class 1259 OID 556437)
 -- Name: IX_ServiceTypeEnumSet_ImageId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceTypeEnumSet_ImageId" ON public."ServiceTypeEnumSet" USING btree ("ImageId");


 --
 -- TOC entry 4817 (class 1259 OID 577060)
 -- Name: IX_ServiceTypeEnumSet_TranslationKey; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceTypeEnumSet_TranslationKey" ON public."ServiceTypeEnumSet" USING btree ("TranslationKey");


 --
 -- TOC entry 4832 (class 1259 OID 364043)
 -- Name: IX_ServiceTypeTranslationKey; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_ServiceTypeTranslationKey" ON public."ServiceSearchSet" USING btree ("ServiceTypeTranslationKey");


 --
 -- TOC entry 5010 (class 1259 OID 1785228)
 -- Name: IX_SpamProtectionDomainSet_Domain; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_SpamProtectionDomainSet_Domain" ON public."SpamProtectionDomainSet" USING btree ("Domain");


 --
 -- TOC entry 5011 (class 1259 OID 2655959)
 -- Name: IX_SpamProtectionDomainSet_Domain_Provider; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_SpamProtectionDomainSet_Domain_Provider" ON public."SpamProtectionDomainSet" USING btree ("Domain", "Provider");


 --
 -- TOC entry 4879 (class 1259 OID 556268)
 -- Name: IX_SsoPwSet_AccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_SsoPwSet_AccountId" ON public."SsoPwSet" USING btree ("AccountId");


 --
 -- TOC entry 5051 (class 1259 OID 2359448)
 -- Name: IX_TaxInCountrySet_CountryCode; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_TaxInCountrySet_CountryCode" ON public."TaxInCountrySet" USING btree ("CountryCode");


 --
 -- TOC entry 4845 (class 1259 OID 556433)
 -- Name: IX_TenantSet_AdvisoryRoomLeftBannerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_TenantSet_AdvisoryRoomLeftBannerId" ON public."TenantSet" USING btree ("AdvisoryRoomLeftBannerId");


 --
 -- TOC entry 4846 (class 1259 OID 556434)
 -- Name: IX_TenantSet_AdvisoryRoomRightBannerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_TenantSet_AdvisoryRoomRightBannerId" ON public."TenantSet" USING btree ("AdvisoryRoomRightBannerId");


 --
 -- TOC entry 4847 (class 1259 OID 1561340)
 -- Name: IX_TenantSet_BeneficiaryId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_TenantSet_BeneficiaryId" ON public."TenantSet" USING btree ("BeneficiaryId");


 --
 -- TOC entry 4848 (class 1259 OID 508976)
 -- Name: IX_TenantSet_Identifier; Type: INDEX; Schema: public; Owner: -
 --

 CREATE UNIQUE INDEX "IX_TenantSet_Identifier" ON public."TenantSet" USING btree ("Identifier");


 --
 -- TOC entry 4849 (class 1259 OID 556435)
 -- Name: IX_TenantSet_LogoId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_TenantSet_LogoId" ON public."TenantSet" USING btree ("LogoId");


 --
 -- TOC entry 4850 (class 1259 OID 556847)
 -- Name: IX_TenantSet_ProductListId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_TenantSet_ProductListId" ON public."TenantSet" USING btree ("ProductListId");


 --
 -- TOC entry 4975 (class 1259 OID 1561217)
 -- Name: IX_TermsAndConditionSet_AccountSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_TermsAndConditionSet_AccountSetId" ON public."TermsAndConditionSet" USING btree ("AccountSetId");


 --
 -- TOC entry 4976 (class 1259 OID 1561215)
 -- Name: IX_TermsAndConditionSet_DocumentId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_TermsAndConditionSet_DocumentId" ON public."TermsAndConditionSet" USING btree ("DocumentId");


 --
 -- TOC entry 4977 (class 1259 OID 1561216)
 -- Name: IX_TermsAndConditionSet_PreviousVersionId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_TermsAndConditionSet_PreviousVersionId" ON public."TermsAndConditionSet" USING btree ("PreviousVersionId");


 --
 -- TOC entry 4820 (class 1259 OID 1791673)
 -- Name: IX_UploadSet_BookingRequestSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_UploadSet_BookingRequestSetId" ON public."UploadSet" USING btree ("BookingRequestSetId");


 --
 -- TOC entry 4821 (class 1259 OID 2359285)
 -- Name: IX_UploadSet_ConversationAttachmentMessageSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_UploadSet_ConversationAttachmentMessageSetId" ON public."UploadSet" USING btree ("ConversationAttachmentMessageSetId");


 --
 -- TOC entry 4822 (class 1259 OID 1791674)
 -- Name: IX_UploadSet_ProjectSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_UploadSet_ProjectSetId" ON public."UploadSet" USING btree ("ProjectSetId");


 --
 -- TOC entry 5047 (class 1259 OID 2359322)
 -- Name: IX_UploadStashSets_ConversationSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_UploadStashSets_ConversationSetId" ON public."UploadStashSets" USING btree ("ConversationSetId");


 --
 -- TOC entry 5048 (class 1259 OID 2359323)
 -- Name: IX_UploadStashSets_CreatorAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_UploadStashSets_CreatorAccountId" ON public."UploadStashSets" USING btree ("CreatorAccountId");


 --
 -- TOC entry 4871 (class 1259 OID 510283)
 -- Name: IX_UserStorySet_FromAccountId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_UserStorySet_FromAccountId" ON public."UserStorySet" USING btree ("FromAccountId");


 --
 -- TOC entry 5006 (class 1259 OID 1785187)
 -- Name: IX_VideoOnDemandInformationStashSet_MeetingInformationSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_VideoOnDemandInformationStashSet_MeetingInformationSetId" ON public."VideoOnDemandInformationStashSet" USING btree ("MeetingInformationSetId");


 --
 -- TOC entry 5007 (class 1259 OID 1785188)
 -- Name: IX_VideoOnDemandInformationStashSet_OwnerId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_VideoOnDemandInformationStashSet_OwnerId" ON public."VideoOnDemandInformationStashSet" USING btree ("OwnerId");


 --
 -- TOC entry 4825 (class 1259 OID 348876)
 -- Name: IX_VotingEntrySet_MeetingInformationSetId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_VotingEntrySet_MeetingInformationSetId" ON public."VotingEntrySet" USING btree ("MeetingInformationSetId");


 --
 -- TOC entry 4826 (class 1259 OID 1561265)
 -- Name: IX_VotingEntrySet_UserId; Type: INDEX; Schema: public; Owner: -
 --

 CREATE INDEX "IX_VotingEntrySet_UserId" ON public."VotingEntrySet" USING btree ("UserId");


 --
 -- TOC entry 5423 (class 2618 OID 3075737)
 -- Name: AccountView _RETURN; Type: RULE; Schema: public; Owner: -
 --

 CREATE OR REPLACE VIEW public."AccountView" AS
  SELECT account."Id" AS "AccountId",
     account."Firstname" AS "FirstName",
     account."Lastname" AS "LastName",
     concat(account."Firstname", ' ', account."Lastname") AS "FullName",
     account."CompanyNameOrNull",
     account."CreationDateOrDefault" AS "SignUpDate",
     count(projectexpert."Id") AS "BookedByCount",
     count(projectrequestor."Id") AS "BookingsMadeCount",
     min(projectexpert."CreationDate") AS "FirstBookedDate",
     min(projectrequestor."CreationDate") AS "FirstBookingMadeDate",
     max(projectexpert."CreationDate") AS "LastBookedDate",
     max(projectrequestor."CreationDate") AS "LastBookingMadeDate",
     account."MarkedForDeletion",
     account."UserTypeEnum",
     ( SELECT (json_agg(DISTINCT m."TenantIdentifier"))::text AS json_agg
            FROM (public."AccountMultitenancySet" m
              JOIN public."AccountSet" a ON ((m."AccountId" = a."Id")))
           WHERE (m."AccountId" = account."Id")) AS "ConnectedHubs",
     ( SELECT (json_agg(DISTINCT m."TenantIdentifier"))::jsonb AS json_agg
            FROM (public."AccountMultitenancySet" m
              JOIN public."AccountSet" a ON ((m."AccountId" = a."Id")))
           WHERE (m."AccountId" = account."Id")) AS "ConnectedHubsList"
    FROM (((public."AccountSet" account
      LEFT JOIN public."ProjectSet" projectexpert ON ((projectexpert."ExpertId" = account."Id")))
      LEFT JOIN public."ProjectSet" projectrequestor ON ((projectrequestor."RequestorId" = account."Id")))
      LEFT JOIN public."AccountStatus" status ON ((account."AccountStatusId" = status."Id")))
   GROUP BY account."Id"
   ORDER BY account."Id" DESC;


 --
 -- TOC entry 5425 (class 2618 OID 3165785)
 -- Name: ExpertView _RETURN; Type: RULE; Schema: public; Owner: -
 --

 CREATE OR REPLACE VIEW public."ExpertView" AS
  SELECT account."Id" AS "AccountId",
     count(project."Id") AS "AllBookingsCount",
     min(project."CreationDate") AS "FirstBookingDate",
     max(project."CreationDate") AS "LastBookingDate",
     account."MarkedForDeletion",
     max(accstatus."LastSavingDateAccount") AS "LastSavingDateAccount",
     max(accstatus."ServiceSettingsLastPostPublishInfoStash") AS "ServiceSettingsLastPostPublishInfoStash",
     max(accstatus."ServicesLastPublishDateOrNull") AS "ServicesLastPublishDateOrNull"
    FROM ((public."AccountSet" account
      LEFT JOIN public."ProjectSet" project ON ((project."ExpertId" = account."Id")))
      LEFT JOIN public."AccountStatus" accstatus ON ((account."AccountStatusId" = accstatus."Id")))
   WHERE ((account."UserTypeEnum" & 2) = 2)
   GROUP BY account."Id"
   ORDER BY (max(project."CreationDate")) DESC;


 --
 -- TOC entry 5124 (class 2606 OID 16720)
 -- Name: jobparameter jobparameter_jobid_fkey; Type: FK CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.jobparameter
     ADD CONSTRAINT jobparameter_jobid_fkey FOREIGN KEY (jobid) REFERENCES hangfire.job(id) ON UPDATE CASCADE ON DELETE CASCADE;


 --
 -- TOC entry 5125 (class 2606 OID 16725)
 -- Name: state state_jobid_fkey; Type: FK CONSTRAINT; Schema: hangfire; Owner: -
 --

 ALTER TABLE ONLY hangfire.state
     ADD CONSTRAINT state_jobid_fkey FOREIGN KEY (jobid) REFERENCES hangfire.job(id) ON UPDATE CASCADE ON DELETE CASCADE;


 --
 -- TOC entry 5169 (class 2606 OID 16730)
 -- Name: AccountInvoiceInformationSet FK_AccountInvoiceInformationSet_AccountSet_AccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountInvoiceInformationSet"
     ADD CONSTRAINT "FK_AccountInvoiceInformationSet_AccountSet_AccountId" FOREIGN KEY ("AccountId") REFERENCES public."AccountSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5176 (class 2606 OID 16735)
 -- Name: AccountMultitenancySet FK_AccountMultitenancySet_AccountSet_AccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountMultitenancySet"
     ADD CONSTRAINT "FK_AccountMultitenancySet_AccountSet_AccountId" FOREIGN KEY ("AccountId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5177 (class 2606 OID 16740)
 -- Name: AccountMultitenancySet FK_AccountMultitenancySet_AccountStatusTenantAware_AccountStat~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountMultitenancySet"
     ADD CONSTRAINT "FK_AccountMultitenancySet_AccountStatusTenantAware_AccountStat~" FOREIGN KEY ("AccountStatusTenantAwareSetId") REFERENCES public."AccountStatusTenantAware"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5178 (class 2606 OID 16745)
 -- Name: AccountMultitenancySet FK_AccountMultitenancySet_TenantSet_TenantId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountMultitenancySet"
     ADD CONSTRAINT "FK_AccountMultitenancySet_TenantSet_TenantId" FOREIGN KEY ("TenantId") REFERENCES public."TenantSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5204 (class 2606 OID 16750)
 -- Name: AccountQuotaPerDaySet FK_AccountQuotaPerDaySet_AccountStatus_AccountStatusSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountQuotaPerDaySet"
     ADD CONSTRAINT "FK_AccountQuotaPerDaySet_AccountStatus_AccountStatusSetId" FOREIGN KEY ("AccountStatusSetId") REFERENCES public."AccountStatus"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5253 (class 2606 OID 2359228)
 -- Name: AccountSetConversationSet FK_AccountSetConversationSet_AccountSet_ParticipantAccountsId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountSetConversationSet"
     ADD CONSTRAINT "FK_AccountSetConversationSet_AccountSet_ParticipantAccountsId" FOREIGN KEY ("ParticipantAccountsId") REFERENCES public."AccountSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5254 (class 2606 OID 2359233)
 -- Name: AccountSetConversationSet FK_AccountSetConversationSet_ConversationSet_ConversationsId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountSetConversationSet"
     ADD CONSTRAINT "FK_AccountSetConversationSet_ConversationSet_ConversationsId" FOREIGN KEY ("ConversationsId") REFERENCES public."ConversationSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5126 (class 2606 OID 16765)
 -- Name: AccountSet FK_AccountSet_AccountStatus_AccountStatusId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountSet"
     ADD CONSTRAINT "FK_AccountSet_AccountStatus_AccountStatusId" FOREIGN KEY ("AccountStatusId") REFERENCES public."AccountStatus"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5127 (class 2606 OID 3075758)
 -- Name: AccountSet FK_AccountSet_PromptEngineeringAiSet_PromptEngineeringAiSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountSet"
     ADD CONSTRAINT "FK_AccountSet_PromptEngineeringAiSet_PromptEngineeringAiSetId" FOREIGN KEY ("PromptEngineeringAiSetId") REFERENCES public."PromptEngineeringAiSet"("Id");


 --
 -- TOC entry 5128 (class 2606 OID 16770)
 -- Name: AccountSet FK_AccountSet_RevenueCutGeneral_RevenueCutGeneralId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountSet"
     ADD CONSTRAINT "FK_AccountSet_RevenueCutGeneral_RevenueCutGeneralId" FOREIGN KEY ("RevenueCutGeneralId") REFERENCES public."RevenueCutGeneral"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5129 (class 2606 OID 16775)
 -- Name: AccountSet FK_AccountSet_UploadSet_CompanyImageId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountSet"
     ADD CONSTRAINT "FK_AccountSet_UploadSet_CompanyImageId" FOREIGN KEY ("CompanyImageId") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5130 (class 2606 OID 16780)
 -- Name: AccountSet FK_AccountSet_UploadSet_ProfileImageId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountSet"
     ADD CONSTRAINT "FK_AccountSet_UploadSet_ProfileImageId" FOREIGN KEY ("ProfileImageId") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5131 (class 2606 OID 16785)
 -- Name: AccountSet FK_AccountSet_UploadSet_TermsAndConditionsId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountSet"
     ADD CONSTRAINT "FK_AccountSet_UploadSet_TermsAndConditionsId" FOREIGN KEY ("TermsAndConditionsId") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5203 (class 2606 OID 16790)
 -- Name: AccountStatsSet FK_AccountStatsSet_AccountSet_AccountSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AccountStatsSet"
     ADD CONSTRAINT "FK_AccountStatsSet_AccountSet_AccountSetId" FOREIGN KEY ("AccountSetId") REFERENCES public."AccountSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5273 (class 2606 OID 2463425)
 -- Name: AnonymousUserEventTrackingSet FK_AnonymousUserEventTrackingSet_AnonymousUserEventTrackingPer~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AnonymousUserEventTrackingSet"
     ADD CONSTRAINT "FK_AnonymousUserEventTrackingSet_AnonymousUserEventTrackingPer~" FOREIGN KEY ("AnonymousUserEventTrackingPerDaySetId") REFERENCES public."AnonymousUserEventTrackingPerDaySet"("Id");


 --
 -- TOC entry 5216 (class 2606 OID 16795)
 -- Name: AppliedCouponConnection FK_AppliedCouponConnection_Coupon_CouponId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."AppliedCouponConnection"
     ADD CONSTRAINT "FK_AppliedCouponConnection_Coupon_CouponId" FOREIGN KEY ("CouponId") REFERENCES public."Coupon"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5228 (class 2606 OID 16805)
 -- Name: BookingRequestSet FK_BookingRequestSet_AccountSet_CreatorId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookingRequestSet"
     ADD CONSTRAINT "FK_BookingRequestSet_AccountSet_CreatorId" FOREIGN KEY ("CreatorId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5229 (class 2606 OID 2662848)
 -- Name: BookingRequestSet FK_BookingRequestSet_CustomOfferSet_CustomOfferExistingService~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookingRequestSet"
     ADD CONSTRAINT "FK_BookingRequestSet_CustomOfferSet_CustomOfferExistingService~" FOREIGN KEY ("CustomOfferExistingServiceSetId") REFERENCES public."CustomOfferSet"("Id");


 --
 -- TOC entry 5230 (class 2606 OID 2359829)
 -- Name: BookingRequestSet FK_BookingRequestSet_PaymentInformationSet_PaymentInformationId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookingRequestSet"
     ADD CONSTRAINT "FK_BookingRequestSet_PaymentInformationSet_PaymentInformationId" FOREIGN KEY ("PaymentInformationId") REFERENCES public."PaymentInformationSet"("Id");


 --
 -- TOC entry 5231 (class 2606 OID 16815)
 -- Name: BookingRequestSet FK_BookingRequestSet_ProjectSet_ProjectSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookingRequestSet"
     ADD CONSTRAINT "FK_BookingRequestSet_ProjectSet_ProjectSetId" FOREIGN KEY ("ProjectSetId") REFERENCES public."ProjectSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5232 (class 2606 OID 2655777)
 -- Name: BookingRequestSet FK_BookingRequestSet_Purchase_OneTimePurchaseMicroadvisorySess~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookingRequestSet"
     ADD CONSTRAINT "FK_BookingRequestSet_Purchase_OneTimePurchaseMicroadvisorySess~" FOREIGN KEY ("OneTimePurchaseMicroadvisorySessionProductId") REFERENCES public."Purchase"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5233 (class 2606 OID 16825)
 -- Name: BookingRequestSet FK_BookingRequestSet_UploadSet_Upload1Id; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookingRequestSet"
     ADD CONSTRAINT "FK_BookingRequestSet_UploadSet_Upload1Id" FOREIGN KEY ("Upload1Id") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5234 (class 2606 OID 16830)
 -- Name: BookingRequestSet FK_BookingRequestSet_UploadSet_Upload2Id; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookingRequestSet"
     ADD CONSTRAINT "FK_BookingRequestSet_UploadSet_Upload2Id" FOREIGN KEY ("Upload2Id") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5235 (class 2606 OID 16835)
 -- Name: BookingRequestSet FK_BookingRequestSet_UploadSet_Upload3Id; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookingRequestSet"
     ADD CONSTRAINT "FK_BookingRequestSet_UploadSet_Upload3Id" FOREIGN KEY ("Upload3Id") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5236 (class 2606 OID 16840)
 -- Name: BookingRequestSet FK_BookingRequestSet_VotingEntrySet_AppointmentSuggestion1Id; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookingRequestSet"
     ADD CONSTRAINT "FK_BookingRequestSet_VotingEntrySet_AppointmentSuggestion1Id" FOREIGN KEY ("AppointmentSuggestion1Id") REFERENCES public."VotingEntrySet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5237 (class 2606 OID 16845)
 -- Name: BookingRequestSet FK_BookingRequestSet_VotingEntrySet_AppointmentSuggestion2Id; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookingRequestSet"
     ADD CONSTRAINT "FK_BookingRequestSet_VotingEntrySet_AppointmentSuggestion2Id" FOREIGN KEY ("AppointmentSuggestion2Id") REFERENCES public."VotingEntrySet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5238 (class 2606 OID 16850)
 -- Name: BookingRequestSet FK_BookingRequestSet_VotingEntrySet_AppointmentSuggestion3Id; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookingRequestSet"
     ADD CONSTRAINT "FK_BookingRequestSet_VotingEntrySet_AppointmentSuggestion3Id" FOREIGN KEY ("AppointmentSuggestion3Id") REFERENCES public."VotingEntrySet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5239 (class 2606 OID 16855)
 -- Name: BookmarkConnectionExpertStaticSet FK_BookmarkConnectionExpertStaticSet_AccountSet_BookmarkedAcco~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookmarkConnectionExpertStaticSet"
     ADD CONSTRAINT "FK_BookmarkConnectionExpertStaticSet_AccountSet_BookmarkedAcco~" FOREIGN KEY ("BookmarkedAccountId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5240 (class 2606 OID 16860)
 -- Name: BookmarkConnectionExpertStaticSet FK_BookmarkConnectionExpertStaticSet_AccountSet_FromAccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookmarkConnectionExpertStaticSet"
     ADD CONSTRAINT "FK_BookmarkConnectionExpertStaticSet_AccountSet_FromAccountId" FOREIGN KEY ("FromAccountId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5210 (class 2606 OID 16865)
 -- Name: BookmarkConnectionServiceStaticSet FK_BookmarkConnectionServiceStaticSet_AccountSet_FromAccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookmarkConnectionServiceStaticSet"
     ADD CONSTRAINT "FK_BookmarkConnectionServiceStaticSet_AccountSet_FromAccountId" FOREIGN KEY ("FromAccountId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5211 (class 2606 OID 16870)
 -- Name: BookmarkConnectionServiceStaticSet FK_BookmarkConnectionServiceStaticSet_ServiceSearchSet_Bookmar~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookmarkConnectionServiceStaticSet"
     ADD CONSTRAINT "FK_BookmarkConnectionServiceStaticSet_ServiceSearchSet_Bookmar~" FOREIGN KEY ("BookmarkedServiceId") REFERENCES public."ServiceSearchSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5212 (class 2606 OID 16875)
 -- Name: BookmarkConnectionWithHistoryBaseSet FK_BookmarkConnectionWithHistoryBaseSet_AccountSet_BookmarkedA~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookmarkConnectionWithHistoryBaseSet"
     ADD CONSTRAINT "FK_BookmarkConnectionWithHistoryBaseSet_AccountSet_BookmarkedA~" FOREIGN KEY ("BookmarkedAccountId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5213 (class 2606 OID 16880)
 -- Name: BookmarkConnectionWithHistoryBaseSet FK_BookmarkConnectionWithHistoryBaseSet_AccountSet_Bookmarking~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookmarkConnectionWithHistoryBaseSet"
     ADD CONSTRAINT "FK_BookmarkConnectionWithHistoryBaseSet_AccountSet_Bookmarking~" FOREIGN KEY ("BookmarkingAccountId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5214 (class 2606 OID 16885)
 -- Name: BookmarkConnectionWithHistoryBaseSet FK_BookmarkConnectionWithHistoryBaseSet_ServiceSearchSet_Bookm~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."BookmarkConnectionWithHistoryBaseSet"
     ADD CONSTRAINT "FK_BookmarkConnectionWithHistoryBaseSet_ServiceSearchSet_Bookm~" FOREIGN KEY ("BookmarkedServiceId") REFERENCES public."ServiceSearchSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5287 (class 2606 OID 3075771)
 -- Name: CognitoUserIdSet FK_CognitoUserIdSet_AccountSet_AccountSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CognitoUserIdSet"
     ADD CONSTRAINT "FK_CognitoUserIdSet_AccountSet_AccountSetId" FOREIGN KEY ("AccountSetId") REFERENCES public."AccountSet"("Id");


 --
 -- TOC entry 5288 (class 2606 OID 3075786)
 -- Name: CognitoUsernameSet FK_CognitoUsernameSet_CognitoUserIdSet_CognitoUserIdSetCognito~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CognitoUsernameSet"
     ADD CONSTRAINT "FK_CognitoUsernameSet_CognitoUserIdSet_CognitoUserIdSetCognito~" FOREIGN KEY ("CognitoUserIdSetCognitoUserId") REFERENCES public."CognitoUserIdSet"("CognitoUserId");


 --
 -- TOC entry 5260 (class 2606 OID 2359275)
 -- Name: ConversationMessageReadByAccountSet FK_ConversationMessageReadByAccountSet_AccountSet_AccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ConversationMessageReadByAccountSet"
     ADD CONSTRAINT "FK_ConversationMessageReadByAccountSet_AccountSet_AccountId" FOREIGN KEY ("AccountId") REFERENCES public."AccountSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5261 (class 2606 OID 2359280)
 -- Name: ConversationMessageReadByAccountSet FK_ConversationMessageReadByAccountSet_ConversationMessageSet_~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ConversationMessageReadByAccountSet"
     ADD CONSTRAINT "FK_ConversationMessageReadByAccountSet_ConversationMessageSet_~" FOREIGN KEY ("ConversationMessageId") REFERENCES public."ConversationMessageSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5255 (class 2606 OID 2359248)
 -- Name: ConversationMessageSet FK_ConversationMessageSet_AccountSet_CreatorAccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ConversationMessageSet"
     ADD CONSTRAINT "FK_ConversationMessageSet_AccountSet_CreatorAccountId" FOREIGN KEY ("CreatorAccountId") REFERENCES public."AccountSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5256 (class 2606 OID 2359253)
 -- Name: ConversationMessageSet FK_ConversationMessageSet_ConversationMessageSet_ReplyOnMessag~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ConversationMessageSet"
     ADD CONSTRAINT "FK_ConversationMessageSet_ConversationMessageSet_ReplyOnMessag~" FOREIGN KEY ("ReplyOnMessageId") REFERENCES public."ConversationMessageSet"("Id");


 --
 -- TOC entry 5257 (class 2606 OID 2359258)
 -- Name: ConversationMessageSet FK_ConversationMessageSet_ConversationSet_ConversationSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ConversationMessageSet"
     ADD CONSTRAINT "FK_ConversationMessageSet_ConversationSet_ConversationSetId" FOREIGN KEY ("ConversationSetId") REFERENCES public."ConversationSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5258 (class 2606 OID 2662842)
 -- Name: ConversationMessageSet FK_ConversationMessageSet_CustomOfferSet_CustomOfferExistingSe~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ConversationMessageSet"
     ADD CONSTRAINT "FK_ConversationMessageSet_CustomOfferSet_CustomOfferExistingSe~" FOREIGN KEY ("CustomOfferExistingServiceSetId") REFERENCES public."CustomOfferSet"("Id");


 --
 -- TOC entry 5259 (class 2606 OID 2359263)
 -- Name: ConversationMessageSet FK_ConversationMessageSet_MeetingInformationSet_MeetingInforma~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ConversationMessageSet"
     ADD CONSTRAINT "FK_ConversationMessageSet_MeetingInformationSet_MeetingInforma~" FOREIGN KEY ("MeetingInformationId") REFERENCES public."MeetingInformationSet"("Id");


 --
 -- TOC entry 5250 (class 2606 OID 3165793)
 -- Name: ConversationSet FK_ConversationSet_AccountSet_CreatorAccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ConversationSet"
     ADD CONSTRAINT "FK_ConversationSet_AccountSet_CreatorAccountId" FOREIGN KEY ("CreatorAccountId") REFERENCES public."AccountSet"("Id");


 --
 -- TOC entry 5251 (class 2606 OID 2359218)
 -- Name: ConversationSet FK_ConversationSet_ProjectSet_ProjectId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ConversationSet"
     ADD CONSTRAINT "FK_ConversationSet_ProjectSet_ProjectId" FOREIGN KEY ("ProjectId") REFERENCES public."ProjectSet"("Id");


 --
 -- TOC entry 5252 (class 2606 OID 3165799)
 -- Name: ConversationSet FK_ConversationSet_ServiceSearchSet_ServiceSearchSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ConversationSet"
     ADD CONSTRAINT "FK_ConversationSet_ServiceSearchSet_ServiceSearchSetId" FOREIGN KEY ("ServiceSearchSetId") REFERENCES public."ServiceSearchSet"("Id");


 --
 -- TOC entry 5271 (class 2606 OID 2360273)
 -- Name: CouponPurchaseDetailsSet FK_CouponPurchaseDetailsSet_Coupon_CouponsId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CouponPurchaseDetailsSet"
     ADD CONSTRAINT "FK_CouponPurchaseDetailsSet_Coupon_CouponsId" FOREIGN KEY ("CouponsId") REFERENCES public."Coupon"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5272 (class 2606 OID 2360278)
 -- Name: CouponPurchaseDetailsSet FK_CouponPurchaseDetailsSet_PurchaseDetailsSet_AppliedToPurcha~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CouponPurchaseDetailsSet"
     ADD CONSTRAINT "FK_CouponPurchaseDetailsSet_PurchaseDetailsSet_AppliedToPurcha~" FOREIGN KEY ("AppliedToPurchaseDetailsId") REFERENCES public."PurchaseDetailsSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5132 (class 2606 OID 16890)
 -- Name: CustomAccountLinkSet FK_CustomAccountLinkSet_AccountSet_AccountSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CustomAccountLinkSet"
     ADD CONSTRAINT "FK_CustomAccountLinkSet_AccountSet_AccountSetId" FOREIGN KEY ("AccountSetId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5285 (class 2606 OID 2662864)
 -- Name: CustomOfferConnectionStaticSet FK_CustomOfferConnectionStaticSet_AccountSet_ForAccountSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CustomOfferConnectionStaticSet"
     ADD CONSTRAINT "FK_CustomOfferConnectionStaticSet_AccountSet_ForAccountSetId" FOREIGN KEY ("ForAccountSetId") REFERENCES public."AccountSet"("Id");


 --
 -- TOC entry 5286 (class 2606 OID 2662869)
 -- Name: CustomOfferConnectionStaticSet FK_CustomOfferConnectionStaticSet_CustomOfferSet_CustomOfferSe~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CustomOfferConnectionStaticSet"
     ADD CONSTRAINT "FK_CustomOfferConnectionStaticSet_CustomOfferSet_CustomOfferSe~" FOREIGN KEY ("CustomOfferSetId") REFERENCES public."CustomOfferSet"("Id");


 --
 -- TOC entry 5284 (class 2606 OID 2662834)
 -- Name: CustomOfferSet FK_CustomOfferSet_ServiceSearchSet_ServiceSearchSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."CustomOfferSet"
     ADD CONSTRAINT "FK_CustomOfferSet_ServiceSearchSet_ServiceSearchSetId" FOREIGN KEY ("ServiceSearchSetId") REFERENCES public."ServiceSearchSet"("Id");


 --
 -- TOC entry 5179 (class 2606 OID 16895)
 -- Name: FaqSet FK_FaqSet_FaqCategorySet_FaqCategorySetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."FaqSet"
     ADD CONSTRAINT "FK_FaqSet_FaqCategorySet_FaqCategorySetId" FOREIGN KEY ("FaqCategorySetId") REFERENCES public."FaqCategorySet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5170 (class 2606 OID 16900)
 -- Name: FeaturedExpertsServiceSet FK_FeaturedExpertsServiceSet_AccountSet_FeaturedExpertId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."FeaturedExpertsServiceSet"
     ADD CONSTRAINT "FK_FeaturedExpertsServiceSet_AccountSet_FeaturedExpertId" FOREIGN KEY ("FeaturedExpertId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5133 (class 2606 OID 16905)
 -- Name: GoalSet FK_GoalSet_AccountSet_ExpertAccountSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."GoalSet"
     ADD CONSTRAINT "FK_GoalSet_AccountSet_ExpertAccountSetId" FOREIGN KEY ("ExpertAccountSetId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5134 (class 2606 OID 16910)
 -- Name: GoalSet FK_GoalSet_AccountSet_OwnerAccountSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."GoalSet"
     ADD CONSTRAINT "FK_GoalSet_AccountSet_OwnerAccountSetId" FOREIGN KEY ("OwnerAccountSetId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5135 (class 2606 OID 16915)
 -- Name: GoalSet FK_GoalSet_GoalSet_ParentGoalId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."GoalSet"
     ADD CONSTRAINT "FK_GoalSet_GoalSet_ParentGoalId" FOREIGN KEY ("ParentGoalId") REFERENCES public."GoalSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5136 (class 2606 OID 16925)
 -- Name: GoalSet FK_GoalSet_ProjectSet_ProjectSetOrNullId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."GoalSet"
     ADD CONSTRAINT "FK_GoalSet_ProjectSet_ProjectSetOrNullId" FOREIGN KEY ("ProjectSetOrNullId") REFERENCES public."ProjectSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5137 (class 2606 OID 16930)
 -- Name: GoalSet FK_GoalSet_ServiceTypeEnumSet_ServiceTypeEnumSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."GoalSet"
     ADD CONSTRAINT "FK_GoalSet_ServiceTypeEnumSet_ServiceTypeEnumSetId" FOREIGN KEY ("ServiceTypeEnumSetId") REFERENCES public."ServiceTypeEnumSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5182 (class 2606 OID 16935)
 -- Name: HashtagConnectionSet FK_HashtagConnectionSet_AccountSet_AccountUsedItId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."HashtagConnectionSet"
     ADD CONSTRAINT "FK_HashtagConnectionSet_AccountSet_AccountUsedItId" FOREIGN KEY ("AccountUsedItId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5183 (class 2606 OID 16940)
 -- Name: HashtagConnectionSet FK_HashtagConnectionSet_HashtagSet_HashtagSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."HashtagConnectionSet"
     ADD CONSTRAINT "FK_HashtagConnectionSet_HashtagSet_HashtagSetId" FOREIGN KEY ("HashtagSetId") REFERENCES public."HashtagSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5184 (class 2606 OID 16945)
 -- Name: HashtagConnectionSet FK_HashtagConnectionSet_UserStorySet_UserStorySetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."HashtagConnectionSet"
     ADD CONSTRAINT "FK_HashtagConnectionSet_UserStorySet_UserStorySetId" FOREIGN KEY ("UserStorySetId") REFERENCES public."UserStorySet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5180 (class 2606 OID 16950)
 -- Name: HashtagSet FK_HashtagSet_AccountSet_FirstCreatedById; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."HashtagSet"
     ADD CONSTRAINT "FK_HashtagSet_AccountSet_FirstCreatedById" FOREIGN KEY ("FirstCreatedById") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5205 (class 2606 OID 3075862)
 -- Name: InviteConnectionSet FK_InviteConnectionSet_AccountSet_AccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."InviteConnectionSet"
     ADD CONSTRAINT "FK_InviteConnectionSet_AccountSet_AccountId" FOREIGN KEY ("AccountId") REFERENCES public."AccountSet"("Id");


 --
 -- TOC entry 5206 (class 2606 OID 3075878)
 -- Name: InviteConnectionSet FK_InviteConnectionSet_AccountSet_InviterId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."InviteConnectionSet"
     ADD CONSTRAINT "FK_InviteConnectionSet_AccountSet_InviterId" FOREIGN KEY ("InviterId") REFERENCES public."AccountSet"("Id");


 --
 -- TOC entry 5207 (class 2606 OID 3075867)
 -- Name: InviteConnectionSet FK_InviteConnectionSet_KycCompany_KycCompanyId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."InviteConnectionSet"
     ADD CONSTRAINT "FK_InviteConnectionSet_KycCompany_KycCompanyId" FOREIGN KEY ("KycCompanyId") REFERENCES public."KycCompany"("Id");


 --
 -- TOC entry 5208 (class 2606 OID 16955)
 -- Name: InviteConnectionSet FK_InviteConnectionSet_MeetingInformationSet_MeetingInformatio~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."InviteConnectionSet"
     ADD CONSTRAINT "FK_InviteConnectionSet_MeetingInformationSet_MeetingInformatio~" FOREIGN KEY ("MeetingInformationSetId") REFERENCES public."MeetingInformationSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5209 (class 2606 OID 3075872)
 -- Name: InviteConnectionSet FK_InviteConnectionSet_RegistrationWaitinglist_RegistrationWai~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."InviteConnectionSet"
     ADD CONSTRAINT "FK_InviteConnectionSet_RegistrationWaitinglist_RegistrationWai~" FOREIGN KEY ("RegistrationWaitinglistEntrySetId") REFERENCES public."RegistrationWaitinglist"("Id");


 --
 -- TOC entry 5289 (class 2606 OID 3075829)
 -- Name: KycCompanyConnectionAccountStaticSet FK_KycCompanyConnectionAccountStaticSet_AccountSet_AccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."KycCompanyConnectionAccountStaticSet"
     ADD CONSTRAINT "FK_KycCompanyConnectionAccountStaticSet_AccountSet_AccountId" FOREIGN KEY ("AccountId") REFERENCES public."AccountSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5290 (class 2606 OID 3075834)
 -- Name: KycCompanyConnectionAccountStaticSet FK_KycCompanyConnectionAccountStaticSet_KycCompany_KycCompanyId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."KycCompanyConnectionAccountStaticSet"
     ADD CONSTRAINT "FK_KycCompanyConnectionAccountStaticSet_KycCompany_KycCompanyId" FOREIGN KEY ("KycCompanyId") REFERENCES public."KycCompany"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5291 (class 2606 OID 3075849)
 -- Name: KycCompanyStashSet FK_KycCompanyStashSet_AccountSet_OwnerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."KycCompanyStashSet"
     ADD CONSTRAINT "FK_KycCompanyStashSet_AccountSet_OwnerId" FOREIGN KEY ("OwnerId") REFERENCES public."AccountSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5248 (class 2606 OID 3075729)
 -- Name: KycCompany FK_KycCompany_AccountSet_OwnerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."KycCompany"
     ADD CONSTRAINT "FK_KycCompany_AccountSet_OwnerId" FOREIGN KEY ("OwnerId") REFERENCES public."AccountSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5249 (class 2606 OID 16985)
 -- Name: KycCompany FK_KycCompany_MangpayInfo_MangopayInfoId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."KycCompany"
     ADD CONSTRAINT "FK_KycCompany_MangpayInfo_MangopayInfoId" FOREIGN KEY ("MangopayInfoId") REFERENCES public."MangpayInfo"("Id");


 --
 -- TOC entry 5242 (class 2606 OID 16990)
 -- Name: KycDocumentSet FK_KycDocumentSet_AccountSet_AccountSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."KycDocumentSet"
     ADD CONSTRAINT "FK_KycDocumentSet_AccountSet_AccountSetId" FOREIGN KEY ("AccountSetId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5243 (class 2606 OID 16995)
 -- Name: KycDocumentSet FK_KycDocumentSet_KycCompany_KycCompanyId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."KycDocumentSet"
     ADD CONSTRAINT "FK_KycDocumentSet_KycCompany_KycCompanyId" FOREIGN KEY ("KycCompanyId") REFERENCES public."KycCompany"("Id");


 --
 -- TOC entry 5244 (class 2606 OID 17000)
 -- Name: KycDocumentSet FK_KycDocumentSet_UploadSet_KycDocumentId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."KycDocumentSet"
     ADD CONSTRAINT "FK_KycDocumentSet_UploadSet_KycDocumentId" FOREIGN KEY ("KycDocumentId") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5277 (class 2606 OID 2477127)
 -- Name: LegalDocumentSequenceSet FK_LegalDocumentSequenceSet_LegalDocumentSet_DocumentId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."LegalDocumentSequenceSet"
     ADD CONSTRAINT "FK_LegalDocumentSequenceSet_LegalDocumentSet_DocumentId" FOREIGN KEY ("DocumentId") REFERENCES public."LegalDocumentSet"("Id");


 --
 -- TOC entry 5274 (class 2606 OID 2477102)
 -- Name: LegalDocumentSet FK_LegalDocumentSet_AccountSet_CreatorAccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."LegalDocumentSet"
     ADD CONSTRAINT "FK_LegalDocumentSet_AccountSet_CreatorAccountId" FOREIGN KEY ("CreatorAccountId") REFERENCES public."AccountSet"("Id");


 --
 -- TOC entry 5275 (class 2606 OID 2477107)
 -- Name: LegalDocumentSet FK_LegalDocumentSet_ProjectSet_ProjectId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."LegalDocumentSet"
     ADD CONSTRAINT "FK_LegalDocumentSet_ProjectSet_ProjectId" FOREIGN KEY ("ProjectId") REFERENCES public."ProjectSet"("Id");


 --
 -- TOC entry 5276 (class 2606 OID 2477112)
 -- Name: LegalDocumentSet FK_LegalDocumentSet_UploadSet_DocumentId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."LegalDocumentSet"
     ADD CONSTRAINT "FK_LegalDocumentSet_UploadSet_DocumentId" FOREIGN KEY ("DocumentId") REFERENCES public."UploadSet"("Id");


 --
 -- TOC entry 5138 (class 2606 OID 17005)
 -- Name: LikeAndFollowExpertHistory FK_LikeAndFollowExpertHistory_AccountSet_LikedAccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."LikeAndFollowExpertHistory"
     ADD CONSTRAINT "FK_LikeAndFollowExpertHistory_AccountSet_LikedAccountId" FOREIGN KEY ("LikedAccountId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5139 (class 2606 OID 17010)
 -- Name: LikeAndFollowExpertHistory FK_LikeAndFollowExpertHistory_AccountSet_LikerAccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."LikeAndFollowExpertHistory"
     ADD CONSTRAINT "FK_LikeAndFollowExpertHistory_AccountSet_LikerAccountId" FOREIGN KEY ("LikerAccountId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5140 (class 2606 OID 17015)
 -- Name: MeetingInformationSet FK_MeetingInformationSet_AccountSet_CreatorId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MeetingInformationSet"
     ADD CONSTRAINT "FK_MeetingInformationSet_AccountSet_CreatorId" FOREIGN KEY ("CreatorId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5141 (class 2606 OID 2359834)
 -- Name: MeetingInformationSet FK_MeetingInformationSet_PaymentInformationSet_PaymentInformat~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MeetingInformationSet"
     ADD CONSTRAINT "FK_MeetingInformationSet_PaymentInformationSet_PaymentInformat~" FOREIGN KEY ("PaymentInformationId") REFERENCES public."PaymentInformationSet"("Id");


 --
 -- TOC entry 5142 (class 2606 OID 17025)
 -- Name: MeetingInformationSet FK_MeetingInformationSet_TenantSet_TenantId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MeetingInformationSet"
     ADD CONSTRAINT "FK_MeetingInformationSet_TenantSet_TenantId" FOREIGN KEY ("TenantId") REFERENCES public."TenantSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5143 (class 2606 OID 17030)
 -- Name: MeetingWhitelistAccountEntrySet FK_MeetingWhitelistAccountEntrySet_AccountSet_AccountSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MeetingWhitelistAccountEntrySet"
     ADD CONSTRAINT "FK_MeetingWhitelistAccountEntrySet_AccountSet_AccountSetId" FOREIGN KEY ("AccountSetId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5144 (class 2606 OID 17035)
 -- Name: MeetingWhitelistAccountEntrySet FK_MeetingWhitelistAccountEntrySet_MeetingInformationSet_Meeti~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MeetingWhitelistAccountEntrySet"
     ADD CONSTRAINT "FK_MeetingWhitelistAccountEntrySet_MeetingInformationSet_Meeti~" FOREIGN KEY ("MeetingInformationSetId") REFERENCES public."MeetingInformationSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5145 (class 2606 OID 17040)
 -- Name: MeetingWhitelistEmailEntrySet FK_MeetingWhitelistEmailEntrySet_MeetingInformationSet_Meeting~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MeetingWhitelistEmailEntrySet"
     ADD CONSTRAINT "FK_MeetingWhitelistEmailEntrySet_MeetingInformationSet_Meeting~" FOREIGN KEY ("MeetingInformationSetId") REFERENCES public."MeetingInformationSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5191 (class 2606 OID 17045)
 -- Name: MentionConnectionSet FK_MentionConnectionSet_AccountSet_AboutAccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MentionConnectionSet"
     ADD CONSTRAINT "FK_MentionConnectionSet_AccountSet_AboutAccountId" FOREIGN KEY ("AboutAccountId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5192 (class 2606 OID 17050)
 -- Name: MentionConnectionSet FK_MentionConnectionSet_AccountSet_FromAccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MentionConnectionSet"
     ADD CONSTRAINT "FK_MentionConnectionSet_AccountSet_FromAccountId" FOREIGN KEY ("FromAccountId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5193 (class 2606 OID 17055)
 -- Name: MentionConnectionSet FK_MentionConnectionSet_ServiceSearchSet_AboutServiceId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MentionConnectionSet"
     ADD CONSTRAINT "FK_MentionConnectionSet_ServiceSearchSet_AboutServiceId" FOREIGN KEY ("AboutServiceId") REFERENCES public."ServiceSearchSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5194 (class 2606 OID 17060)
 -- Name: MentionConnectionSet FK_MentionConnectionSet_ServiceTypeEnumSet_AboutServiceTypeId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MentionConnectionSet"
     ADD CONSTRAINT "FK_MentionConnectionSet_ServiceTypeEnumSet_AboutServiceTypeId" FOREIGN KEY ("AboutServiceTypeId") REFERENCES public."ServiceTypeEnumSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5195 (class 2606 OID 17065)
 -- Name: MentionConnectionSet FK_MentionConnectionSet_UserStorySet_UserStoryAboutServiceConn~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MentionConnectionSet"
     ADD CONSTRAINT "FK_MentionConnectionSet_UserStorySet_UserStoryAboutServiceConn~" FOREIGN KEY ("UserStoryAboutServiceConnectionSet_UserStorySetId") REFERENCES public."UserStorySet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5196 (class 2606 OID 17070)
 -- Name: MentionConnectionSet FK_MentionConnectionSet_UserStorySet_UserStoryAboutServiceType~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MentionConnectionSet"
     ADD CONSTRAINT "FK_MentionConnectionSet_UserStorySet_UserStoryAboutServiceType~" FOREIGN KEY ("UserStoryAboutServiceTypeConnectionSet_UserStorySetId") REFERENCES public."UserStorySet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5197 (class 2606 OID 17075)
 -- Name: MentionConnectionSet FK_MentionConnectionSet_UserStorySet_UserStorySetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MentionConnectionSet"
     ADD CONSTRAINT "FK_MentionConnectionSet_UserStorySet_UserStorySetId" FOREIGN KEY ("UserStorySetId") REFERENCES public."UserStorySet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5146 (class 2606 OID 17080)
 -- Name: MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet FK_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Acc~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet"
     ADD CONSTRAINT "FK_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Acc~" FOREIGN KEY ("AccountSetId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5147 (class 2606 OID 17090)
 -- Name: MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet FK_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Vot~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet"
     ADD CONSTRAINT "FK_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Vot~" FOREIGN KEY ("AppointmentSuggestion1Id") REFERENCES public."VotingEntrySet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5148 (class 2606 OID 17095)
 -- Name: MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet FK_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Vo~1; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet"
     ADD CONSTRAINT "FK_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Vo~1" FOREIGN KEY ("AppointmentSuggestion2Id") REFERENCES public."VotingEntrySet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5149 (class 2606 OID 17100)
 -- Name: MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet FK_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Vo~2; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet"
     ADD CONSTRAINT "FK_MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Vo~2" FOREIGN KEY ("AppointmentSuggestion3Id") REFERENCES public."VotingEntrySet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5150 (class 2606 OID 17105)
 -- Name: NotificationSet FK_NotificationSet_AccountSet_AccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."NotificationSet"
     ADD CONSTRAINT "FK_NotificationSet_AccountSet_AccountId" FOREIGN KEY ("AccountId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5151 (class 2606 OID 17110)
 -- Name: NotificationSet FK_NotificationSet_AccountSet_SenderId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."NotificationSet"
     ADD CONSTRAINT "FK_NotificationSet_AccountSet_SenderId" FOREIGN KEY ("SenderId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5152 (class 2606 OID 17115)
 -- Name: NotificationSet FK_NotificationSet_MeetingInformationSet_MeetingInformationId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."NotificationSet"
     ADD CONSTRAINT "FK_NotificationSet_MeetingInformationSet_MeetingInformationId" FOREIGN KEY ("MeetingInformationId") REFERENCES public."MeetingInformationSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5153 (class 2606 OID 17120)
 -- Name: NotificationSet FK_NotificationSet_ProjectSet_ProjectId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."NotificationSet"
     ADD CONSTRAINT "FK_NotificationSet_ProjectSet_ProjectId" FOREIGN KEY ("ProjectId") REFERENCES public."ProjectSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5247 (class 2606 OID 17125)
 -- Name: OfficeHoursBreakSet FK_OfficeHoursBreakSet_AccountSet_ExpertAccountSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."OfficeHoursBreakSet"
     ADD CONSTRAINT "FK_OfficeHoursBreakSet_AccountSet_ExpertAccountSetId" FOREIGN KEY ("ExpertAccountSetId") REFERENCES public."AccountSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5154 (class 2606 OID 17130)
 -- Name: OfficeHoursSet FK_OfficeHoursSet_AccountSet_ExpertAccountSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."OfficeHoursSet"
     ADD CONSTRAINT "FK_OfficeHoursSet_AccountSet_ExpertAccountSetId" FOREIGN KEY ("ExpertAccountSetId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5201 (class 2606 OID 17135)
 -- Name: ProductToProductList FK_ProductToProductList_ProductList_ProductListId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ProductToProductList"
     ADD CONSTRAINT "FK_ProductToProductList_ProductList_ProductListId" FOREIGN KEY ("ProductListId") REFERENCES public."ProductList"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5202 (class 2606 OID 17140)
 -- Name: ProductToProductList FK_ProductToProductList_Product_ProductId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ProductToProductList"
     ADD CONSTRAINT "FK_ProductToProductList_Product_ProductId" FOREIGN KEY ("ProductId") REFERENCES public."Product"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5198 (class 2606 OID 17145)
 -- Name: Product FK_Product_AccountSet_AssignedToId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."Product"
     ADD CONSTRAINT "FK_Product_AccountSet_AssignedToId" FOREIGN KEY ("AssignedToId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5199 (class 2606 OID 17150)
 -- Name: Product FK_Product_ServiceSearchSet_ServiceId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."Product"
     ADD CONSTRAINT "FK_Product_ServiceSearchSet_ServiceId" FOREIGN KEY ("ServiceId") REFERENCES public."ServiceSearchSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5200 (class 2606 OID 2298073)
 -- Name: Product FK_Product_TenantSet_TenantSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."Product"
     ADD CONSTRAINT "FK_Product_TenantSet_TenantSetId" FOREIGN KEY ("TenantSetId") REFERENCES public."TenantSet"("Id");


 --
 -- TOC entry 5155 (class 2606 OID 17155)
 -- Name: ProjectSet FK_ProjectSet_AccountSet_ExpertId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ProjectSet"
     ADD CONSTRAINT "FK_ProjectSet_AccountSet_ExpertId" FOREIGN KEY ("ExpertId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5156 (class 2606 OID 17160)
 -- Name: ProjectSet FK_ProjectSet_AccountSet_RequestorId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ProjectSet"
     ADD CONSTRAINT "FK_ProjectSet_AccountSet_RequestorId" FOREIGN KEY ("RequestorId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5157 (class 2606 OID 17170)
 -- Name: ProjectSet FK_ProjectSet_MeetingInformationSet_MeetingInformationId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ProjectSet"
     ADD CONSTRAINT "FK_ProjectSet_MeetingInformationSet_MeetingInformationId" FOREIGN KEY ("MeetingInformationId") REFERENCES public."MeetingInformationSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5158 (class 2606 OID 17175)
 -- Name: ProjectSet FK_ProjectSet_ServiceSearchSet_ServiceId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ProjectSet"
     ADD CONSTRAINT "FK_ProjectSet_ServiceSearchSet_ServiceId" FOREIGN KEY ("ServiceId") REFERENCES public."ServiceSearchSet"("Id");


 --
 -- TOC entry 5159 (class 2606 OID 17180)
 -- Name: ProjectSet FK_ProjectSet_UploadSet_Upload1Id; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ProjectSet"
     ADD CONSTRAINT "FK_ProjectSet_UploadSet_Upload1Id" FOREIGN KEY ("Upload1Id") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5160 (class 2606 OID 17185)
 -- Name: ProjectSet FK_ProjectSet_UploadSet_Upload2Id; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ProjectSet"
     ADD CONSTRAINT "FK_ProjectSet_UploadSet_Upload2Id" FOREIGN KEY ("Upload2Id") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5161 (class 2606 OID 17190)
 -- Name: ProjectSet FK_ProjectSet_UploadSet_Upload3Id; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ProjectSet"
     ADD CONSTRAINT "FK_ProjectSet_UploadSet_Upload3Id" FOREIGN KEY ("Upload3Id") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5266 (class 2606 OID 2360243)
 -- Name: PurchaseDetailsSet FK_PurchaseDetailsSet_AccountSet_CreatorAccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."PurchaseDetailsSet"
     ADD CONSTRAINT "FK_PurchaseDetailsSet_AccountSet_CreatorAccountId" FOREIGN KEY ("CreatorAccountId") REFERENCES public."AccountSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5267 (class 2606 OID 2360248)
 -- Name: PurchaseDetailsSet FK_PurchaseDetailsSet_TenantSet_TenantId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."PurchaseDetailsSet"
     ADD CONSTRAINT "FK_PurchaseDetailsSet_TenantSet_TenantId" FOREIGN KEY ("TenantId") REFERENCES public."TenantSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5268 (class 2606 OID 2360298)
 -- Name: PurchaseDetailsSet FK_PurchaseDetailsSet_TransactionDetailsSet_MainPlatformTransa~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."PurchaseDetailsSet"
     ADD CONSTRAINT "FK_PurchaseDetailsSet_TransactionDetailsSet_MainPlatformTransa~" FOREIGN KEY ("MainPlatformTransactionDetailsId") REFERENCES public."TransactionDetailsSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5269 (class 2606 OID 2360303)
 -- Name: PurchaseDetailsSet FK_PurchaseDetailsSet_TransactionDetailsSet_SupplierTransactio~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."PurchaseDetailsSet"
     ADD CONSTRAINT "FK_PurchaseDetailsSet_TransactionDetailsSet_SupplierTransactio~" FOREIGN KEY ("SupplierTransactionDetailsId") REFERENCES public."TransactionDetailsSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5270 (class 2606 OID 2360308)
 -- Name: PurchaseDetailsSet FK_PurchaseDetailsSet_TransactionDetailsSet_TenantTransactionD~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."PurchaseDetailsSet"
     ADD CONSTRAINT "FK_PurchaseDetailsSet_TransactionDetailsSet_TenantTransactionD~" FOREIGN KEY ("TenantTransactionDetailsId") REFERENCES public."TransactionDetailsSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5278 (class 2606 OID 2655782)
 -- Name: Purchase FK_Purchase_AccountSet_BeneficiaryId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."Purchase"
     ADD CONSTRAINT "FK_Purchase_AccountSet_BeneficiaryId" FOREIGN KEY ("BeneficiaryId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5279 (class 2606 OID 2655787)
 -- Name: Purchase FK_Purchase_AccountSet_BuyerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."Purchase"
     ADD CONSTRAINT "FK_Purchase_AccountSet_BuyerId" FOREIGN KEY ("BuyerId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5280 (class 2606 OID 2655792)
 -- Name: Purchase FK_Purchase_Product_BoughtProductId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."Purchase"
     ADD CONSTRAINT "FK_Purchase_Product_BoughtProductId" FOREIGN KEY ("BoughtProductId") REFERENCES public."Product"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5281 (class 2606 OID 2655797)
 -- Name: Purchase FK_Purchase_Product_ProductId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."Purchase"
     ADD CONSTRAINT "FK_Purchase_Product_ProductId" FOREIGN KEY ("ProductId") REFERENCES public."Product"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5282 (class 2606 OID 2655802)
 -- Name: Purchase FK_Purchase_ProjectSet_ProjectSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."Purchase"
     ADD CONSTRAINT "FK_Purchase_ProjectSet_ProjectSetId" FOREIGN KEY ("ProjectSetId") REFERENCES public."ProjectSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5283 (class 2606 OID 2655807)
 -- Name: Purchase FK_Purchase_PurchaseDetailsSet_PurchaseDetailsId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."Purchase"
     ADD CONSTRAINT "FK_Purchase_PurchaseDetailsSet_PurchaseDetailsId" FOREIGN KEY ("PurchaseDetailsId") REFERENCES public."PurchaseDetailsSet"("Id");


 --
 -- TOC entry 5188 (class 2606 OID 17225)
 -- Name: RevenueCutGeneral FK_RevenueCutGeneral_AccountSet_CreatedById; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."RevenueCutGeneral"
     ADD CONSTRAINT "FK_RevenueCutGeneral_AccountSet_CreatedById" FOREIGN KEY ("CreatedById") REFERENCES public."AccountSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5189 (class 2606 OID 17230)
 -- Name: RevenueCutTenant FK_RevenueCutTenant_AccountSet_CreatedById; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."RevenueCutTenant"
     ADD CONSTRAINT "FK_RevenueCutTenant_AccountSet_CreatedById" FOREIGN KEY ("CreatedById") REFERENCES public."AccountSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5190 (class 2606 OID 17235)
 -- Name: RevenueCutTenant FK_RevenueCutTenant_TenantSet_TenantId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."RevenueCutTenant"
     ADD CONSTRAINT "FK_RevenueCutTenant_TenantSet_TenantId" FOREIGN KEY ("TenantId") REFERENCES public."TenantSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5185 (class 2606 OID 17240)
 -- Name: ServiceRatingAfterMeetingSet FK_ServiceRatingAfterMeetingSet_AccountSet_AccountThatVotedId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceRatingAfterMeetingSet"
     ADD CONSTRAINT "FK_ServiceRatingAfterMeetingSet_AccountSet_AccountThatVotedId" FOREIGN KEY ("AccountThatVotedId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5186 (class 2606 OID 17245)
 -- Name: ServiceRatingAfterMeetingSet FK_ServiceRatingAfterMeetingSet_AccountSet_AccountToRateId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceRatingAfterMeetingSet"
     ADD CONSTRAINT "FK_ServiceRatingAfterMeetingSet_AccountSet_AccountToRateId" FOREIGN KEY ("AccountToRateId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5187 (class 2606 OID 17250)
 -- Name: ServiceRatingAfterMeetingSet FK_ServiceRatingAfterMeetingSet_MeetingInformationSet_MeetingI~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceRatingAfterMeetingSet"
     ADD CONSTRAINT "FK_ServiceRatingAfterMeetingSet_MeetingInformationSet_MeetingI~" FOREIGN KEY ("MeetingInformationSetId") REFERENCES public."MeetingInformationSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5168 (class 2606 OID 17255)
 -- Name: ServiceSearchSet FK_ServiceSearchSet_AccountSet_ExpertAccountSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSearchSet"
     ADD CONSTRAINT "FK_ServiceSearchSet_AccountSet_ExpertAccountSetId" FOREIGN KEY ("ExpertAccountSetId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5218 (class 2606 OID 17275)
 -- Name: ServiceSettingsAdvisingStatusStashSet FK_ServiceSettingsAdvisingStatusStashSet_AccountSet_OwnerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsAdvisingStatusStashSet"
     ADD CONSTRAINT "FK_ServiceSettingsAdvisingStatusStashSet_AccountSet_OwnerId" FOREIGN KEY ("OwnerId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5219 (class 2606 OID 17280)
 -- Name: ServiceSettingsCallDurationStashSet FK_ServiceSettingsCallDurationStashSet_AccountSet_OwnerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsCallDurationStashSet"
     ADD CONSTRAINT "FK_ServiceSettingsCallDurationStashSet_AccountSet_OwnerId" FOREIGN KEY ("OwnerId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5222 (class 2606 OID 17285)
 -- Name: ServiceSettingsCountriesStashSet FK_ServiceSettingsCountriesStashSet_AccountSet_OwnerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsCountriesStashSet"
     ADD CONSTRAINT "FK_ServiceSettingsCountriesStashSet_AccountSet_OwnerId" FOREIGN KEY ("OwnerId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5223 (class 2606 OID 17295)
 -- Name: ServiceSettingsLanguagesStashSet FK_ServiceSettingsLanguagesStashSet_AccountSet_OwnerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsLanguagesStashSet"
     ADD CONSTRAINT "FK_ServiceSettingsLanguagesStashSet_AccountSet_OwnerId" FOREIGN KEY ("OwnerId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5221 (class 2606 OID 17300)
 -- Name: ServiceSettingsOfficeHoursStashSet FK_ServiceSettingsOfficeHoursStashSet_AccountSet_OwnerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsOfficeHoursStashSet"
     ADD CONSTRAINT "FK_ServiceSettingsOfficeHoursStashSet_AccountSet_OwnerId" FOREIGN KEY ("OwnerId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5220 (class 2606 OID 17305)
 -- Name: ServiceSettingsPricingModelStashSet FK_ServiceSettingsPricingModelStashSet_AccountSet_OwnerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsPricingModelStashSet"
     ADD CONSTRAINT "FK_ServiceSettingsPricingModelStashSet_AccountSet_OwnerId" FOREIGN KEY ("OwnerId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5241 (class 2606 OID 17310)
 -- Name: ServiceSettingsPublishDraftStashSet FK_ServiceSettingsPublishDraftStashSet_AccountSet_OwnerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsPublishDraftStashSet"
     ADD CONSTRAINT "FK_ServiceSettingsPublishDraftStashSet_AccountSet_OwnerId" FOREIGN KEY ("OwnerId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5224 (class 2606 OID 17315)
 -- Name: ServiceSettingsPublishInfoStashSet FK_ServiceSettingsPublishInfoStashSet_AccountSet_OwnerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsPublishInfoStashSet"
     ADD CONSTRAINT "FK_ServiceSettingsPublishInfoStashSet_AccountSet_OwnerId" FOREIGN KEY ("OwnerId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5217 (class 2606 OID 17320)
 -- Name: ServiceSettingsServicesStashSet FK_ServiceSettingsServicesStashSet_AccountSet_OwnerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceSettingsServicesStashSet"
     ADD CONSTRAINT "FK_ServiceSettingsServicesStashSet_AccountSet_OwnerId" FOREIGN KEY ("OwnerId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5215 (class 2606 OID 17325)
 -- Name: ServiceStatsSet FK_ServiceStatsSet_ServiceSearchSet_ServiceSearchSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceStatsSet"
     ADD CONSTRAINT "FK_ServiceStatsSet_ServiceSearchSet_ServiceSearchSetId" FOREIGN KEY ("ServiceSearchSetId") REFERENCES public."ServiceSearchSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5264 (class 2606 OID 2359699)
 -- Name: ServiceTypeCategoryConnectionTenantStaticSet FK_ServiceTypeCategoryConnectionTenantStaticSet_ServiceTypeCat~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceTypeCategoryConnectionTenantStaticSet"
     ADD CONSTRAINT "FK_ServiceTypeCategoryConnectionTenantStaticSet_ServiceTypeCat~" FOREIGN KEY ("ServiceTypeCategoryEnumSetId") REFERENCES public."ServiceTypeCategoryEnumSet"("Id");


 --
 -- TOC entry 5265 (class 2606 OID 2359704)
 -- Name: ServiceTypeCategoryConnectionTenantStaticSet FK_ServiceTypeCategoryConnectionTenantStaticSet_TenantSet_Tena~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceTypeCategoryConnectionTenantStaticSet"
     ADD CONSTRAINT "FK_ServiceTypeCategoryConnectionTenantStaticSet_TenantSet_Tena~" FOREIGN KEY ("TenantSetId") REFERENCES public."TenantSet"("Id");


 --
 -- TOC entry 5162 (class 2606 OID 17330)
 -- Name: ServiceTypeEnumSet FK_ServiceTypeEnumSet_UploadSet_IconId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceTypeEnumSet"
     ADD CONSTRAINT "FK_ServiceTypeEnumSet_UploadSet_IconId" FOREIGN KEY ("IconId") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5163 (class 2606 OID 17335)
 -- Name: ServiceTypeEnumSet FK_ServiceTypeEnumSet_UploadSet_ImageId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."ServiceTypeEnumSet"
     ADD CONSTRAINT "FK_ServiceTypeEnumSet_UploadSet_ImageId" FOREIGN KEY ("ImageId") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5171 (class 2606 OID 17355)
 -- Name: TenantSet FK_TenantSet_AccountSet_BeneficiaryId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."TenantSet"
     ADD CONSTRAINT "FK_TenantSet_AccountSet_BeneficiaryId" FOREIGN KEY ("BeneficiaryId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5172 (class 2606 OID 17360)
 -- Name: TenantSet FK_TenantSet_ProductList_ProductListId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."TenantSet"
     ADD CONSTRAINT "FK_TenantSet_ProductList_ProductListId" FOREIGN KEY ("ProductListId") REFERENCES public."ProductList"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5173 (class 2606 OID 17365)
 -- Name: TenantSet FK_TenantSet_UploadSet_AdvisoryRoomLeftBannerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."TenantSet"
     ADD CONSTRAINT "FK_TenantSet_UploadSet_AdvisoryRoomLeftBannerId" FOREIGN KEY ("AdvisoryRoomLeftBannerId") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5174 (class 2606 OID 17370)
 -- Name: TenantSet FK_TenantSet_UploadSet_AdvisoryRoomRightBannerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."TenantSet"
     ADD CONSTRAINT "FK_TenantSet_UploadSet_AdvisoryRoomRightBannerId" FOREIGN KEY ("AdvisoryRoomRightBannerId") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5175 (class 2606 OID 17375)
 -- Name: TenantSet FK_TenantSet_UploadSet_LogoId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."TenantSet"
     ADD CONSTRAINT "FK_TenantSet_UploadSet_LogoId" FOREIGN KEY ("LogoId") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5225 (class 2606 OID 17380)
 -- Name: TermsAndConditionSet FK_TermsAndConditionSet_AccountSet_AccountSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."TermsAndConditionSet"
     ADD CONSTRAINT "FK_TermsAndConditionSet_AccountSet_AccountSetId" FOREIGN KEY ("AccountSetId") REFERENCES public."AccountSet"("Id") ON DELETE CASCADE;


 --
 -- TOC entry 5226 (class 2606 OID 17385)
 -- Name: TermsAndConditionSet FK_TermsAndConditionSet_TermsAndConditionSet_PreviousVersionId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."TermsAndConditionSet"
     ADD CONSTRAINT "FK_TermsAndConditionSet_TermsAndConditionSet_PreviousVersionId" FOREIGN KEY ("PreviousVersionId") REFERENCES public."TermsAndConditionSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5227 (class 2606 OID 17390)
 -- Name: TermsAndConditionSet FK_TermsAndConditionSet_UploadSet_DocumentId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."TermsAndConditionSet"
     ADD CONSTRAINT "FK_TermsAndConditionSet_UploadSet_DocumentId" FOREIGN KEY ("DocumentId") REFERENCES public."UploadSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5164 (class 2606 OID 17395)
 -- Name: UploadSet FK_UploadSet_BookingRequestSet_BookingRequestSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."UploadSet"
     ADD CONSTRAINT "FK_UploadSet_BookingRequestSet_BookingRequestSetId" FOREIGN KEY ("BookingRequestSetId") REFERENCES public."BookingRequestSet"("Id");


 --
 -- TOC entry 5165 (class 2606 OID 2359294)
 -- Name: UploadSet FK_UploadSet_ConversationMessageSet_ConversationAttachmentMess~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."UploadSet"
     ADD CONSTRAINT "FK_UploadSet_ConversationMessageSet_ConversationAttachmentMess~" FOREIGN KEY ("ConversationAttachmentMessageSetId") REFERENCES public."ConversationMessageSet"("Id");


 --
 -- TOC entry 5166 (class 2606 OID 17400)
 -- Name: UploadSet FK_UploadSet_ProjectSet_ProjectSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."UploadSet"
     ADD CONSTRAINT "FK_UploadSet_ProjectSet_ProjectSetId" FOREIGN KEY ("ProjectSetId") REFERENCES public."ProjectSet"("Id");


 --
 -- TOC entry 5262 (class 2606 OID 2359312)
 -- Name: UploadStashSets FK_UploadStashSets_AccountSet_CreatorAccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."UploadStashSets"
     ADD CONSTRAINT "FK_UploadStashSets_AccountSet_CreatorAccountId" FOREIGN KEY ("CreatorAccountId") REFERENCES public."AccountSet"("Id");


 --
 -- TOC entry 5263 (class 2606 OID 2359317)
 -- Name: UploadStashSets FK_UploadStashSets_ConversationSet_ConversationSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."UploadStashSets"
     ADD CONSTRAINT "FK_UploadStashSets_ConversationSet_ConversationSetId" FOREIGN KEY ("ConversationSetId") REFERENCES public."ConversationSet"("Id");


 --
 -- TOC entry 5181 (class 2606 OID 17405)
 -- Name: UserStorySet FK_UserStorySet_AccountSet_FromAccountId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."UserStorySet"
     ADD CONSTRAINT "FK_UserStorySet_AccountSet_FromAccountId" FOREIGN KEY ("FromAccountId") REFERENCES public."AccountSet"("Id") ON DELETE RESTRICT;


 --
 -- TOC entry 5245 (class 2606 OID 17410)
 -- Name: VideoOnDemandInformationStashSet FK_VideoOnDemandInformationStashSet_AccountSet_OwnerId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."VideoOnDemandInformationStashSet"
     ADD CONSTRAINT "FK_VideoOnDemandInformationStashSet_AccountSet_OwnerId" FOREIGN KEY ("OwnerId") REFERENCES public."AccountSet"("Id");


 --
 -- TOC entry 5246 (class 2606 OID 17415)
 -- Name: VideoOnDemandInformationStashSet FK_VideoOnDemandInformationStashSet_MeetingInformationSet_Meet~; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."VideoOnDemandInformationStashSet"
     ADD CONSTRAINT "FK_VideoOnDemandInformationStashSet_MeetingInformationSet_Meet~" FOREIGN KEY ("MeetingInformationSetId") REFERENCES public."MeetingInformationSet"("Id");


 --
 -- TOC entry 5167 (class 2606 OID 17420)
 -- Name: VotingEntrySet FK_VotingEntrySet_MeetingInformationSet_MeetingInformationSetId; Type: FK CONSTRAINT; Schema: public; Owner: -
 --

 ALTER TABLE ONLY public."VotingEntrySet"
     ADD CONSTRAINT "FK_VotingEntrySet_MeetingInformationSet_MeetingInformationSetId" FOREIGN KEY ("MeetingInformationSetId") REFERENCES public."MeetingInformationSet"("Id") ON DELETE RESTRICT;


 -- Completed on 2023-04-05 10:30:44 Africa

 --
 -- PostgreSQL database dump complete
 --


-- Insert data for bug rerproduction
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
SET session_replication_role = 'replica';

INSERT INTO public."AccountStatus" VALUES (26067, '1992-09-09 20:37:16', '2007-08-28 19:11:18', '2013-02-10 01:21:47', '1984-05-01 04:12:31', '2008-01-25 12:55:10', '1982-07-19 18:47:54', '1985-10-10 21:47:43', '1990-07-19 18:39:59', '1997-10-10 10:07:25', '2003-08-04 07:50:38', '1987-12-12 23:58:58', '2004-09-09 08:51:36', '2006-07-23 18:12:26', '1999-04-20 03:44:34', '2005-10-14 09:50:35', '1986-11-07 22:55:47', '2016-01-13 12:40:10', '1999-12-08 12:01:41', '2011-08-28 07:43:00', '2010-07-19 06:35:40', '1989-02-26 02:03:11', '2014-03-03 02:21:44', '1980-09-05 08:24:02', '2004-09-09 08:56:23', '2019-08-12 07:26:46', '2004-05-25 16:12:13', '1997-02-02 01:48:34', '1985-10-10 22:00:54', '2010-03-15 15:03:04', '1988-09-09 08:13:44');
INSERT INTO public."AccountStatus" VALUES (52996, '2009-06-22 05:30:24', '1992-01-13 12:23:10', '2006-03-27 02:34:57', '2003-08-04 07:47:01', '1981-10-06 09:36:29', '2011-08-24 07:35:35', '2002-11-19 22:38:31', '1986-03-19 14:31:33', '1989-06-18 17:33:22', '1983-04-28 03:18:23', '2013-06-10 18:03:46', '2015-12-24 11:40:10', '1981-02-10 01:03:36', '2014-07-07 19:06:00', '2003-04-24 15:16:34', '1989-02-10 01:51:57', '2005-10-14 09:51:03', '1998-03-15 02:46:24', '2018-11-03 23:10:31', '1989-10-10 09:14:17', '2010-11-23 22:24:36', '2011-04-08 15:52:10', '1991-08-04 19:44:00', '1995-04-16 15:17:42', '1999-04-16 03:44:44', '1985-02-02 13:37:16', '1985-10-06 21:54:11', '1981-10-06 09:33:13', '1989-06-02 17:44:25', '1980-09-13 08:23:49');

INSERT INTO public."PromptEngineeringAiSet" VALUES (64959, '6810028167497618', '1557839047134777', '1989-06-10 17:36:51', '1992-01-09 12:23:20');
INSERT INTO public."PromptEngineeringAiSet" VALUES (44786, '7812484406286243', '3787128185216847', '1994-03-19 14:20:29', '1997-06-26 17:25:00');

INSERT INTO public."AccountSet" VALUES (2598, 25240, 'kindhearted_fuck47381', 'Kenny', 'Schumm', true, 'Ceavitake tavinayu', 'Kihakina nomika kenorami', 'Kisohy nomichino nikoceakin', '2001-06-18 05:52:01', NULL, true, NULL, 'Yunotayo hanokicea', 'Meni yotakin', NULL, '2011-08-12 07:46:42', 'Kameni nihy kaimemuchi', 'Yoniraeki ceachina', '2016-01-25 12:46:40', '1998-07-15 18:32:07', 'Ceakira mechihake soshikekin', 'Ceayukinkai muyokinki', false, '{"Keraetamu": "Nahy kiaki"}', 'Hynoke hamitaki hyna', 'Kinchiko nomuni yushi', 'Niyu chihyshi chikekira', 'Vikai vashiko', 'Kaisoceano mayohy shimuno', 'Keva sochi viyu', DEFAULT, 'Kocea ramoniso nakinmachi', NULL, 63609, 20022, 46585, 46558, NULL, 'Raeshirae norame soshi', 'Hykaikani vakin haniva', DEFAULT, DEFAULT, '+1715983243542', '2018-11-11 23:12:52', '1990-11-07 10:10:41', 13624919, '2008-01-13 12:58:35', 11147338, '{"Chimachicea shisokiso"}', 1602, 46129, 49288, 61329, 16325, NULL, 'Rachira nakoka');
INSERT INTO public."AccountSet" VALUES (13211, 45429, 'Joshua-Howell51299', 'Jedidiah', 'Skiles', false, 'Yukin raekairake yumoka', 'Hahy kainakin', 'Shiva masoki niahyke', '1996-09-25 08:58:09', NULL, true, NULL, 'Meraeha shima sochima', 'Tayuano hayo hacea', NULL, '2018-11-23 23:09:48', 'Yuko raenoni', 'Kora nomita', '1980-05-13 16:43:28', '2013-10-26 09:42:52', 'Ceakino nomamuva', 'Noakeki chiamu', true, '{"Rayuva": "Yusoki chikekai kashiceayu"}', 'Raenovi mutamima', 'Kira vichi vahyka', 'Yunayota kakina nako', 'Kaiyo hakinma soa', 'Vakoki miraekaihy nachi', 'Tahyma kairani', DEFAULT, 'Shiso yokichiko', NULL, 41662, 49976, 9930, 62237, NULL, 'Vicea raechi morae', 'Kinokamu kaceayuta', DEFAULT, DEFAULT, '+8634138698491', '2011-12-08 23:25:00', '1992-01-01 12:28:34', 10734490, '1986-11-07 22:56:57', 11675975, '{"Shinoshi mamuta moceayua"}', 10180, 20279, 51298, 54569, 9196, NULL, 'Yokimano nachiyo');

INSERT INTO public."AccountInvoiceInformationSet" VALUES (1334, 13211, '8017834119915425', 'NF', 'Delaware', '465 Schmitt Walks', 'Vani raeviyo momu', 'Momamoki chihahyno', 'uqnsHfwfeeqBqpvnjuEctqbjhcaowCqqXfoqmyRzuw0', false, '2011-12-20 23:19:01', 'Manirani raehashike');
INSERT INTO public."AccountInvoiceInformationSet" VALUES (1664, 2598, '7698686144179913', 'AU', 'Pennsylvania', '600 Arlie Landing', 'Hakeso hykinkoyu', 'Moyu vikai raceachihy', 'pwnaTdnqvdrOchczjqZytbblvpvuyYbsAfcgpjVdwb1', false, '2011-08-12 07:41:41', 'Nayu vitani nomu');

INSERT INTO public."AccountStatusTenantAware" VALUES (40057, '2004-09-25 08:54:12', '2009-06-02 05:39:59', '2000-01-09 12:06:19', '1995-12-04 23:50:20', '1995-08-16 07:59:13', '2016-09-09 21:09:26', '1991-12-12 11:25:39', '2019-04-08 15:46:28', '1997-10-02 09:57:15', '1991-04-04 03:52:20', '2014-07-27 19:01:19', '1985-10-02 21:58:05', '1995-04-04 15:27:04', '2013-02-22 01:14:52', '2019-04-20 15:51:41', '2002-03-27 14:15:44', 33794, '2015-12-08 11:42:42', '1987-08-16 07:10:10');
INSERT INTO public."AccountStatusTenantAware" VALUES (43659, '2014-03-11 02:23:58', '2016-05-21 04:27:39', '2003-08-20 07:46:35', '1990-07-03 18:38:05', '2000-05-05 04:46:22', '2017-06-22 05:27:51', '1998-03-27 02:47:53', '2003-12-24 23:26:46', '1989-02-18 01:50:48', '1991-08-16 19:40:42', '2009-10-10 21:17:05', '1984-01-21 12:40:33', '1990-07-07 18:46:19', '1991-08-04 19:43:32', '2019-04-04 15:41:02', '1983-08-28 19:43:13', 53843, '2004-09-01 08:56:43', '2004-01-13 00:33:11');

INSERT INTO public."ServiceSearchSet" VALUES (12002930, NULL, 'Niyuta yomu', 'Kake kashiyokin', '{"Kaikotakin": "Miaceake kachinakin vika"}', 0.0011, 0.00016, 'Ceamu kaikomuso kimorae', 'Mehychi chirae', '{"Vira": "Mokaiyokai muva"}', 'Kina hashinashi makena', '{"Vaki": "Shiko kaishi raekaimu"}', '{"Haki": "Yuyokaiyu keki kaiyome"}', 40457, 38314, '{"Kinmua": "Kinshi nomichi tamenime"}', 6681, 44192, 'Kika nokinraeki', 'Kashihani kashimo mimakinchi', 'Kamu vakikayu', 'Hyvachi nino tamemashi', 'Hamuyo yushiyona', 'Chiyuchikai mukanova', 'Mihashihy hynomano', 'Shichi mokekome raki', DEFAULT, DEFAULT, DEFAULT, DEFAULT, '2011-08-20 07:38:19', false, '1985-06-22 05:19:00', '1987-12-08 23:59:43', '2019-04-12 15:40:28', '{"Kashihy vinaki kani"}', '{"Kimunishi": "Hyki nitano"}', '''Chiyomi'':1', '''Nota'':1', 'Hykin mame', 'Moshita muka virae', 14088092, 15953868, '{"Ceamome": "Kaimo kovayu kikorae"}', 'Novaso raerakona kinraenina', 'Kamekaiva meni', 'Noha mimamo somameyo', 'Ceame yuhakeno', 'Hakin nahyva', 'Kaiha kaiceako moyu', 'Tavihy rakin tami', 'Murake kachikohy mumeni', 'Ceakinvani chikota', 'Mafalda', 'Gleichner', DEFAULT, DEFAULT, 'Kianora', 25721, 49910, 9279, 20111, 65261, '2002-07-03 06:52:25');
INSERT INTO public."ServiceSearchSet" VALUES (12252083, NULL, 'Yomi yuraenaki rakinko', 'Raeso kikeyu', '{"Raemokami": "Mimamo chiraeso menakin"}', 0.005, 0.006, 'Raki nonamu menashi', 'Soshiyu soyu sokechira', '{"Raki": "Shinoraekin mashiahy micea"}', 'Sochimeni yushi', '{"Vamoma": "Tasochi kochisona"}', '{"Ceake": "Yoyukin kerami"}', 25656, 20073, '{"Ceamokimu": "Sochinamu vimo"}', 18864, 37361, 'Chikaiyo miko', 'Kona mimashi vamuyocea', 'Yokemo yonikake', 'Hymi mekamo shika', 'Soraenani hakichi', 'Koke noceakohy mamukota', 'Namonano kokaino', 'Mame tameko kinkoka', DEFAULT, DEFAULT, DEFAULT, DEFAULT, '2012-09-21 08:47:16', false, '1995-12-24 23:45:04', '2001-02-10 13:13:10', '2004-09-25 08:47:33', '{"Noka ceamurano ramiha"}', '{"Chiyoshichi": "Take shimekoki metami"}', '''Kakina'':1', '''Meko'':1', 'Mevikami raekame', 'Hymetashi nahyvako hakeka', 14690827, 10168029, '{"Somenora": "Rayushiko niyumo kamekin"}', 'Memicea kayonashi', 'Kaiso mesoniva kinsohako', 'Raceakiko moke', 'Konishichi kinke kimoyumi', 'Kamimakin kaiko ceanoahy', 'Keyo nashichikai', 'Haso kinraeka mekainashi', 'Moke vavichikai nochi', 'Yuta hyraetani rashi', 'Stanley', 'Streich', DEFAULT, DEFAULT, 'Naniray', 50852, 55255, 5751, 15135, 18764, '2007-08-28 19:13:52');

INSERT INTO public."CustomOfferSet" VALUES (6030772, 'Via kaiyuma ceashihy', 0, 'Rose Gleichner', 'Mina', '2001-10-06 21:37:18', '{39403}', 'Mochi maceamochi kainavira', 'Sovaviyo chishi ceamunoki', 'Mavino maki momakin', NULL, 62302);
INSERT INTO public."CustomOfferSet" VALUES (8237504, 'Kemachi yoki rakin', 0.08, 'Horacio Lesch', 'Kichikevi', '1990-07-27 18:37:40', '{50651}', 'Moyushihy tamema yukakema', 'Havikai yohashiha', 'Tako mehymovi mayo', NULL, 9072);

INSERT INTO public."PaymentInformationSet" VALUES (55466, '6520008783179508', 'CI', 'New Jersey', '874 Cristobal Forge', 'Vame muraeyuko', 'Kaiyoceano kiyoma yume', 'ilpeUvehaqpIckgiubpgngQpvGholluZprl6', '1982-07-11 18:43:27', 'Mukimachi hysoki');
INSERT INTO public."PaymentInformationSet" VALUES (45455, '4025091429027649', 'AO', 'Michigan', '39 Lance Plaza', 'Shihyno kamuko mochiko', 'Nayu kinmekin kohy', 'tqsuGffztizDoloztivbzvPtrYnmnqhLkmy9', '1990-03-11 02:59:58', 'Shisovavi sochi hashisota');

INSERT INTO public."BookingRequestSet" VALUES (14509220, 'Nomu raeyo', '1986-03-27 14:35:46', '5e53e795-c913-56c0-8161-9c7b75c2c480', 'Madelynn', 'Soniceaki yovakin', 'Yunochirae raeaniso nasona', 'Niyuniyu mochiyuni', 'Mikonayu machira soyua', 8360315, 40543, NULL, 'Misota kaina kaimamome', 'Kiko soraeshika nia', 'Kintanona kokinracea', NULL, NULL, NULL, '2019-12-05 00:03:43', NULL, 'Makochi niko hymuyokin', NULL, NULL, NULL, true, '2002-11-11 22:22:52', NULL, NULL, '{"Vimu hymuso"}', NULL);
INSERT INTO public."BookingRequestSet" VALUES (10611530, 'Rano momehyna', '2012-01-09 00:28:00', '02193355-a47b-5755-bbe3-548dc7cea056', 'Candido', 'Hynome mume', 'Miyume mochiyuvi', 'Moshimakin makirae raekaishi', 'Korahy vayukame kinmihyrae', 5059367, 55603, NULL, 'Tayoki shitakikai', 'Yome vakovakin munonamo', 'Motakinva komina', NULL, NULL, NULL, '2015-08-04 19:55:45', NULL, 'Hayo sokaihy kinkiraeki', NULL, NULL, NULL, false, '2011-04-12 15:54:20', NULL, NULL, '{"Yuvavi mino"}', NULL);

INSERT INTO public."ConversationMessageSet" VALUES (16083, 37887, '2004-09-17 08:44:16', 30311, false, NULL, 13211, 'Kikehy ceaniceahy', 'Mimoviso tamu momiso', NULL, 'Hyvikai noma', false, NULL);
INSERT INTO public."ConversationMessageSet" VALUES (9219, 55969, '2017-06-26 05:29:40', 52535, false, NULL, 2598, 'Moke raekai', 'Hanona mayutani', NULL, 'Ceamu kikano kamikai', true, NULL);

INSERT INTO public."MeetingInformationSet" VALUES (2781, '1986-11-23 22:53:50', 'Bhutan', '2013-06-02 17:59:40', '1983-04-16 03:09:12', 37648, 'Memohy mura nokina', 'Sokenahy yomi hykachicea', '1991-04-20 04:01:28', '2007-12-16 11:55:04', 8236, 'Kekinhano kiko', 'Hyshia vamu', NULL, 'Noke soraemaso kikoa', 41501, 29508, NULL, 32131, 'f2b584b9-a3d7-50ec-a004-9fdc7a7bec6b', NULL, false, 47959);
INSERT INTO public."MeetingInformationSet" VALUES (15988, '2002-07-07 06:42:27', 'Palau', '2019-12-21 00:03:45', '1993-02-10 13:19:55', 43068, 'Takinmiyo kaikoshi', 'Chimokemo ceaso', '1986-11-19 22:49:34', '1982-11-15 10:37:38', 20896, 'Havihycea yoyuka', 'Shiraehyni muvime meki', NULL, 'Mamu mukamu', 39605, 24586, NULL, 12243, '465b20f2-84ba-58c4-a967-91a6012b8663', NULL, true, 13539);

INSERT INTO public."ProductList" VALUES (50766, 'a1188e5d-f152-5d10-a2e7-29a2a7f48c59');
INSERT INTO public."ProductList" VALUES (34506, '1094a045-7583-5c81-9889-bb74c9fb3977');

INSERT INTO public."ProjectSet" VALUES (13251, 'e7018158-2e09-5bd2-8635-16d90b1eaa79', 'Kaikamo ceasochi kota', '2001-06-06 05:41:12', 'Viani takiano koka', 'Komumichi memikamo', '2019-08-04 07:22:12', NULL, NULL, NULL, 'Kamonihy kanina', 'Hamomimo raevime', NULL, NULL, NULL, 'Ceako ceakinsoma viyomike', NULL);
INSERT INTO public."ProjectSet" VALUES (50201, '40797c2b-ab8d-532f-8cce-6a8590a1e5b3', 'Kemaki ceamesoki kinmoka', '2011-04-16 15:58:01', 'Monime hayu', 'Vake yokamuke', '2006-03-03 02:29:25', NULL, NULL, NULL, 'Kemohykai yuki', 'Yohy shikemo', NULL, NULL, NULL, 'Nameko kaiyukai shichikamu', NULL);

INSERT INTO public."UploadSet" VALUES (51997, 'Kaihyke virahy kinta', 'Yonihy hynirae', 'Kamume kokekai kashichi', '2008-09-05 20:21:29', NULL, NULL, NULL);
INSERT INTO public."UploadSet" VALUES (45742, 'Mukichiso kinkike yuyovako', 'Moka kamoka', 'Kamokiso tamora sonikome', '2016-09-01 21:10:00', NULL, NULL, NULL);

INSERT INTO public."TenantSet" VALUES (28803, '54d12bf5-7a13-5198-9c50-66b675d43637', '{"Soraki": "Soni kokaceake ceayoki"}', '{"Mimotayu": "Hamoha kichikamo kavikaia"}', true, NULL, NULL, NULL, NULL, NULL, 7094, false);
INSERT INTO public."TenantSet" VALUES (18237, '2bdcaacf-8520-5368-8c2c-c1f05b6d4b12', '{"Yovi": "Nakona mea"}', '{"Mashiva": "Yoha hakinva"}', true, NULL, NULL, NULL, NULL, NULL, 22346, true);

INSERT INTO public."AccountMultitenancySet" VALUES (22354, NULL, NULL, '2004-01-01 00:37:46', 'Ceaki mukameni', NULL, '2016-09-01 21:03:35', 45767);
INSERT INTO public."AccountMultitenancySet" VALUES (27478, NULL, NULL, '2017-06-14 05:33:26', 'Miraemirae chivamemo', NULL, '2017-06-06 05:18:43', 46196);

INSERT INTO public."AccountQuotaPerDaySet" VALUES (58227, NULL, '2020-03-07 02:08:03', '{19648}', 42003);
INSERT INTO public."AccountQuotaPerDaySet" VALUES (7477, NULL, '2020-04-08 03:17:34', '{54790}', 63664);

INSERT INTO public."ConversationSet" VALUES (55969, '2019-12-29 00:10:39', false, 'Kaishi nashiyo kia', '2005-10-02 09:49:48', NULL, true, 2213, NULL, NULL);
INSERT INTO public."ConversationSet" VALUES (37887, '2012-09-21 08:43:04', true, 'Takin muko', '1995-08-08 08:00:22', NULL, false, 30945, NULL, NULL);

INSERT INTO public."AccountSetConversationSet" VALUES (55969, 2598);
INSERT INTO public."AccountSetConversationSet" VALUES (37887, 13211);

INSERT INTO public."AccountStatsSet" VALUES (23689, 2598, 13330, 26292, 1.41, 61854, 58925);
INSERT INTO public."AccountStatsSet" VALUES (17558, 13211, 5367, 41567, 0.68, 53400, 55200);

INSERT INTO public."AnonymousUserEventTrackingPerDaySet" VALUES (7146091, '2000-05-13', 'Takin kiyo nisoki');
INSERT INTO public."AnonymousUserEventTrackingPerDaySet" VALUES (9232168, '2017-02-22', 'Moke hynoke');

INSERT INTO public."AnonymousUserEventTrackingSet" VALUES (11450253, 2478, '2014-11-23 10:40:40', 'Yuni nivanocea', 'TM', 11118325, NULL);
INSERT INTO public."AnonymousUserEventTrackingSet" VALUES (13559213, 42272, '1993-10-10 21:42:08', 'Kiacea tayokaira', 'AO', 3997976, NULL);

INSERT INTO public."Coupon" VALUES (21567, '7bbedb02-7d21-52f6-b9ac-5d898b51271c', 'Hayukai mayukike', 0.016, '1993-10-26 21:34:49', '1998-11-11 11:14:37', 'Vahy vinamimo', 6790, 'Hyramu muchirani', true, 9748, false);
INSERT INTO public."Coupon" VALUES (64447, 'e00736cd-1fcc-5134-93c8-bf8f0075b532', 'Mamoka viyuviko', 0.004, '1991-04-28 04:06:09', '1999-12-28 12:10:04', 'Hakin nomameyo', 33435, 'Ceameyoha mamu', false, 50492, false);

INSERT INTO public."AppliedCouponConnection" VALUES (10133, '2003-04-04 15:13:40', NULL, 35246);
INSERT INTO public."AppliedCouponConnection" VALUES (273, '1992-09-21 20:39:27', NULL, 44351);

INSERT INTO public."BookmarkConnectionExpertStaticSet" VALUES (9031459, '1982-07-03 18:56:37', NULL, 'Yomita shiha nayuki', 41819, NULL);
INSERT INTO public."BookmarkConnectionExpertStaticSet" VALUES (14363348, '1996-05-17 16:30:09', NULL, 'Moame meraemoha', 31681, NULL);

INSERT INTO public."BookmarkConnectionServiceStaticSet" VALUES (3036473, '2003-12-24 23:23:23', NULL, 'Mechihya mokihy', 1388, NULL);
INSERT INTO public."BookmarkConnectionServiceStaticSet" VALUES (16237533, '1994-07-03 07:10:29', NULL, 'Kinmomeka nasoke', 36964, NULL);

INSERT INTO public."BookmarkConnectionWithHistoryBaseSet" VALUES (9169096, 'Yomu raekiyukai moniami', '1998-07-07 18:24:31', NULL, 40230, 'Noyuamo shiranoma', 50870, NULL, NULL);
INSERT INTO public."BookmarkConnectionWithHistoryBaseSet" VALUES (10381722, 'Tamo kemuno', '1985-06-14 05:14:40', NULL, 45784, 'Kaihashiko kimo', 21841, NULL, NULL);

INSERT INTO public."CognitoUserIdSet" VALUES ('Keyoceakin hayohyrae nokami', NULL);
INSERT INTO public."CognitoUserIdSet" VALUES ('Ceahycea shikevi', NULL);

INSERT INTO public."CognitoUsernameSet" VALUES (30599, 'Dayana.Schaefer435', NULL);
INSERT INTO public."CognitoUsernameSet" VALUES (37901, 'upsell.stadium75031', NULL);

INSERT INTO public."ConversationMessageReadByAccountSet" VALUES (58516, 13211, 9219, '2011-04-28 15:55:04');
INSERT INTO public."ConversationMessageReadByAccountSet" VALUES (58579, 2598, 16083, '1993-10-18 21:46:28');

INSERT INTO public."TransactionDetailsSet" VALUES (22865, 0.0001, 0.16, 0.0005);
INSERT INTO public."TransactionDetailsSet" VALUES (20612, 0.16, 0.08, 0.0015);

INSERT INTO public."PurchaseDetailsSet" VALUES (22594, 20612, false, 20612, 20612, 'Rako shimovi sokamehy', 0.0007, 0.00001, 0.015, 0, 0.016, 0.14, false, '2018-11-03 22:59:40', 13211, 18237, '{"Kairaevirae": "Kinmo kira"}', '{"Chivavicea hani sonahyno"}');
INSERT INTO public."PurchaseDetailsSet" VALUES (63841, 22865, false, 22865, 22865, 'Takin tani nashi', 0.00015, 0.05, 0.0014, 0.00004, 0.006, 0.0006, false, '2010-03-27 14:53:56', 2598, 28803, '{"Kinyutayu": "Kokena raevirae"}', '{"Meshike navino"}');

INSERT INTO public."CouponPurchaseDetailsSet" VALUES (22594, 21567);
INSERT INTO public."CouponPurchaseDetailsSet" VALUES (63841, 64447);

INSERT INTO public."CustomAccountLinkSet" VALUES (62578, 'Nisovima niyoceamu mahyko', NULL, '1998-03-27 02:41:14', 'Ryley.Lowe4308@poisonswamp.name');
INSERT INTO public."CustomAccountLinkSet" VALUES (28503, 'Vavi tashi', NULL, '1990-03-07 03:05:58', 'Delmer.Watsica2552@weary-haircut.net');

INSERT INTO public."CustomOfferConnectionStaticSet" VALUES (10777976, 'Rakimayo soshiyu mimuki', '2006-07-07 18:14:09', NULL, 801, NULL);
INSERT INTO public."CustomOfferConnectionStaticSet" VALUES (3353496, 'Miceayona chia ceamina', '1997-10-18 10:12:27', NULL, 12289, NULL);

INSERT INTO public."Distinct_IndustryTypeTranslationKeys2" VALUES (37629, 'Kia koka');
INSERT INTO public."Distinct_IndustryTypeTranslationKeys2" VALUES (19635, 'Yochime yumoracea');

INSERT INTO public."FaqCategorySet" VALUES (64352, 'Mimo yumichishi vahy');
INSERT INTO public."FaqCategorySet" VALUES (6355, 'Kinmeki kevashiha');

INSERT INTO public."FaqSet" VALUES (32599, NULL, 'Taso hyakin koshi', 'Kinchi mako', 'Raeshime tamo', true);
INSERT INTO public."FaqSet" VALUES (13375, NULL, 'Yoraeso mukayu rakinhy', 'Mikokinma raki', 'Memomuni keshi raekaikochi', false);

INSERT INTO public."FeaturedExpertsServiceSet" VALUES (48117, NULL, 'Yomike maceaso', 'Muhymavi kaikome metayorae', 'Yoracea vaniceamu muhyno');
INSERT INTO public."FeaturedExpertsServiceSet" VALUES (40491, NULL, 'Raekinmu nomumashi', 'Kakinraekai minokekin', 'Haviha ceamemu kinkekova');

INSERT INTO public."GeneralSettingsSet" VALUES (52253, 10833, true, false, true, true, true, false, '{"Muniko": "Niyurayu hymu"}', 0.013, 0.08);
INSERT INTO public."GeneralSettingsSet" VALUES (47537, 23909, false, false, true, false, true, true, '{"Raceashi": "Hykira nita rakinyu"}', 7e-05, 0.008);

INSERT INTO public."ServiceTypeEnumSet" VALUES (39607, 'Kachimu nomema', 'Kinviyo raesoraeno kaishiso', true, '{"Chimucea": "Yoceako vakeka"}', 'Hako yuhymi chika', 'Keako mohamuha koceasokai', NULL, NULL, '1980-05-09 16:52:44', '{"Sominova": "Yorae hakinma sokaikacea"}', 'Kohavia muvi', 'Nina ceavima nakomame', DEFAULT, DEFAULT);
INSERT INTO public."ServiceTypeEnumSet" VALUES (56691, 'Makemo kemu sonimu', 'Tami visokamu rayu', true, '{"Koke": "Komukinyu rayorake shitamemi"}', 'Niso visoshino chishi', 'Vika haceako', NULL, NULL, '1998-07-23 18:21:59', '{"Chiva": "Kaiyo raenisovi"}', 'Ceamemamo hasora', 'Sonike mumo', DEFAULT, DEFAULT);

INSERT INTO public."GoalSet" VALUES (12109219, 'Vishirae', '2008-09-13 20:18:56', '1998-07-07 18:28:43', 'Vanoa miranira yovakinke', 'Michihy vami', NULL, NULL, NULL, NULL, 32336, 'Virae ceavira yochi', NULL);
INSERT INTO public."GoalSet" VALUES (7176279, 'Kinshinoke', '2016-09-13 21:03:12', '2014-11-19 10:42:14', 'Hamemi rake', 'Kimacea niyuso', NULL, NULL, NULL, NULL, 22045, 'Hyasoa hyha', NULL);

INSERT INTO public."HashtagSet" VALUES (2213137, 'Vino chiko soceaki', 'Yurachi chishi yokaika', 60161, '1986-11-15 22:49:58', NULL, '2020-07-15 18:08:48');
INSERT INTO public."HashtagSet" VALUES (3291474, 'Nichi vami', 'Yokinhy kisotahy', 51088, '1989-10-06 09:22:23', NULL, '2020-10-18 21:09:45');

INSERT INTO public."UserStorySet" VALUES (14183342, 'e58c253e-a68d-5265-a868-b96a533a021d', '{"Shinorae": "Vikora shimuhako yua"}', NULL, 'Kinmo yokinrae', 'Kihymemo komeshira chinaso', 'Yukin nakima', 'Rakehakin mimuhy shiko', 'Hake munima soranoa', 42015, '2007-08-24 19:23:22', 'Shimo tanisochi mukeniva', DEFAULT, DEFAULT, 'Sokai mami');
INSERT INTO public."UserStorySet" VALUES (12307132, '303203c5-8c3b-5d32-a880-76970790e10b', '{"Raeakin": "Momitashi kachi"}', NULL, 'Vaminorae hyko', 'Shina raesoni kako', 'Miaso nomako', 'Rakiashi moki kiramo', 'Kachiketa memuhyvi nichiha', 25552, '2017-06-22 05:23:25', 'Nimeshi nirae', DEFAULT, DEFAULT, 'Nayume keni');

INSERT INTO public."HashtagConnectionSet" VALUES (15976, '2019-12-29 00:03:39', NULL, NULL, NULL, 'Makinke hyvinorae', 'Chinomu hykai raekano', 'Maviha mashikekai', 32258, 'Chirae haceakota');
INSERT INTO public."HashtagConnectionSet" VALUES (35709, '2019-12-13 00:05:15', NULL, NULL, NULL, 'Muka tamechikai kaira', 'Yokika moshitame', 'Rake visora', 35174, 'Nome mimashi');

INSERT INTO public."HubspotMappingSet" VALUES (2566, 'Mehyvi raemome vamitamo', 'Moachi tashihaso', 44052, '2013-06-26 18:06:15', '2003-12-24 23:24:26', 'Kiyoshi kavimucea', 'Vishi kochita');
INSERT INTO public."HubspotMappingSet" VALUES (40312, 'Kikachi muni tavirae', 'Nishiko sona ceanirani', 53139, '2019-12-05 00:12:21', '2016-01-25 12:43:03', 'Haceachiso chihaso nayunako', 'Memushime viraemo yumashimu');

INSERT INTO public."MangpayInfo" VALUES (24940, 'Nihyso vira', 'Kekime yuma tachishika', 'Moraeyo rayo rashino', 'Name namuma', 0.00015, 14804, 47039, '{"Noma": "Kanimacea shino kasomuno"}');
INSERT INTO public."MangpayInfo" VALUES (58339, 'Raehy kaimacea', 'Yova koshi', 'Yoraekira soni', 'Sohyrae vika', 0.0005, 55687, 49830, '{"Kemotake": "Yuki meviraemo haceachikai"}');

INSERT INTO public."KycCompany" VALUES (28876, 'Jace Crist', 13211, NULL, '3693089840384880');
INSERT INTO public."KycCompany" VALUES (51637, 'Edyth Haag', 2598, NULL, '8460628032698999');

INSERT INTO public."RegistrationWaitinglist" VALUES (45217, 'Niceakiso kairae shimeraechi', 6926);
INSERT INTO public."RegistrationWaitinglist" VALUES (33910, 'Yunashirae shicea', 14657);

INSERT INTO public."InviteConnectionSet" VALUES (34041, '1980-01-05 00:08:49', 36567, 'Machishi kokena', NULL, 'Chikai niva', 'Mumima vamo', '{"Yutachi": "Vamika nashisoha"}', true, 'Viyukame moraemichi noke', NULL, 'Kimuketa vimechishi', 24270, NULL, NULL, 27998, NULL);
INSERT INTO public."InviteConnectionSet" VALUES (39546, '1989-10-26 09:22:57', 47906, 'Kekintavi mayuso', NULL, 'Ceachimeyu kaimo mimoke', 'Monikaiyu nikoha meta', '{"Ceamokina": "Mushimacea yukoshi"}', true, 'Hamu kiraesomu koraeki', NULL, 'Yoshihy havimumi', 29578, NULL, NULL, 29978, NULL);

INSERT INTO public."KycCompanyConnectionAccountStaticSet" VALUES (48551, 2598, 51637, 'Chiso kevako', '1992-09-13 20:43:38', 35372, 46294, false, true, true, 0.0001, 'Shiyoyu nakeramu mamuva');
INSERT INTO public."KycCompanyConnectionAccountStaticSet" VALUES (46947, 13211, 28876, 'Hameni nasokin kaikavia', '1999-12-04 12:08:09', 12991, 18876, true, true, false, 0.0013, 'Mura yohyta chishihy');

INSERT INTO public."KycCompanyStashSet" VALUES (16768, 13211, 10593, 2477, 37753, false, '{"Vaso": "Yoni momeha"}');
INSERT INTO public."KycCompanyStashSet" VALUES (41347, 2598, 10936, 49357, 13603, false, '{"Meka": "Yoma kinsocea shiko"}');

INSERT INTO public."KycDocumentSet" VALUES (41943, NULL, 'Hyshi kashiyo', NULL, '1999-12-28 12:08:47', NULL);
INSERT INTO public."KycDocumentSet" VALUES (2393, NULL, 'Rakeva kinyo', NULL, '1997-06-26 17:21:51', NULL);

INSERT INTO public."LegalDocumentSet" VALUES (29624, '1988-01-17 00:51:32', 10102, NULL, NULL, NULL);
INSERT INTO public."LegalDocumentSet" VALUES (62455, '2005-02-26 01:30:19', 10747, NULL, NULL, NULL);

INSERT INTO public."LegalDocumentSequenceSet" VALUES (35561, '+29145549119710', 7147, NULL, 15408, 26799);
INSERT INTO public."LegalDocumentSequenceSet" VALUES (10328, '+89107578934571', 23852, NULL, 4564, 53637);

INSERT INTO public."LikeAndFollowExpertHistory" VALUES (1225, 8289, NULL, NULL, '2010-11-27 22:26:39');
INSERT INTO public."LikeAndFollowExpertHistory" VALUES (41641, 37555, NULL, NULL, '2017-10-18 22:05:34');

INSERT INTO public."MeetingWhitelistAccountEntrySet" VALUES (62390, NULL, NULL);
INSERT INTO public."MeetingWhitelistAccountEntrySet" VALUES (36581, NULL, NULL);

INSERT INTO public."MeetingWhitelistEmailEntrySet" VALUES (52611, NULL, 'Lew_Connelly83884@dosecorner.net');
INSERT INTO public."MeetingWhitelistEmailEntrySet" VALUES (48944, NULL, 'Ali_Wisozk60298@thick-seagull.com');

INSERT INTO public."MentionConnectionSet" VALUES (4266046, '2017-10-26 21:57:11', NULL, NULL, NULL, 'Chino meka', 21519, NULL, NULL, NULL, NULL, 'Viraceaso kinako');
INSERT INTO public."MentionConnectionSet" VALUES (1605825, '2019-04-08 15:42:51', NULL, NULL, NULL, 'Mihamu nira', 15934, NULL, NULL, NULL, NULL, 'Hykaichita vani somehyki');

INSERT INTO public."VotingEntrySet" VALUES ('49fd17b4-95ee-5420-b2c6-0bec3a5daa92', 39120, '1995-12-04 23:44:02', 41816, 46769, '2009-06-10 05:38:29', 35717, '2020-06-14T05:56:43.000Z', NULL);
INSERT INTO public."VotingEntrySet" VALUES ('b4b36c5b-65d9-5f99-be56-3530c77fbd48', 27047, '2009-02-18 13:55:35', 45683, 14872, '1996-05-05 16:29:57', 49218, '2020-08-12T19:35:16.000Z', NULL);

INSERT INTO public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet" VALUES (12495280, '2016-09-25 20:58:16', 53280, 'efc3c4fe-65d6-5b00-8079-39be4687883d', 'Jacinthe', 'Vishiyuno kime', 'Soki nonikaia yukihy', 'Kina kinso sora', 'Kinvaceano momiyo', 'Kekincea ceami kaishi', 24524, NULL, NULL, NULL, NULL, 'Raera yokaimamu mukaichina', 'Hysovachi ceamuko mimovimo', 'Raehyvi kaichiyu yuko', 29706, 3787, 'Hanomime rakemochi', 'Hyceayo yua', '2002-11-19 22:38:38', 865885);
INSERT INTO public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet" VALUES (7720659, '1995-08-04 08:00:32', 60368, 'c7ef23b4-2ba1-5540-b588-bba6f33df14b', 'Arthur', 'Hynoraemo yova', 'Vakikami noshina mumi', 'Mukamu raemu munokin', 'Nahymake hyvakin mumi', 'Rani mukin mumani', 29278, NULL, NULL, NULL, NULL, 'Nishiami hysovichi makinmu', 'Kaihayu soyume', 'Kea vanometa', 13679, 30472, 'Nahyme yomuchi hyceamocea', 'Nonishiva kaia', '2016-05-21 04:27:32', 7615003);

INSERT INTO public."NotificationSet" VALUES (50085, 37471, NULL, NULL, 'Missouri', '1980-09-21 08:33:24', 'Nishiva nanora', '2020-12-08 23:29:53', NULL, NULL, 15753);
INSERT INTO public."NotificationSet" VALUES (51710, 25962, NULL, NULL, 'Iowa', '2008-05-01 04:37:41', 'Moaniko mamo vahyrae', '2020-01-25 00:24:25', NULL, NULL, 58492);

INSERT INTO public."OfficeHoursBreakSet" VALUES (31258, 42200, '00:00:05', '00:00:10', 13211);
INSERT INTO public."OfficeHoursBreakSet" VALUES (53521, 20908, '00:00:10', '00:00:00', 2598);

INSERT INTO public."OfficeHoursSet" VALUES (59155, false, true, false, true, true, true, true, '00:00:08', '00:00:01', '00:00:01', '00:00:06', '00:00:04', '00:00:02', '00:00:05', '00:00:01', '00:00:06', '00:00:08', '00:00:02', '00:00:01', '00:00:00', '00:00:00', NULL, 'Hamina miso', 'Nimo komina', 'Nimumamu namo');
INSERT INTO public."OfficeHoursSet" VALUES (11670, true, false, true, false, false, true, false, '00:00:05', '00:00:10', '00:00:10', '00:00:04', '00:00:02', '00:00:00', '00:00:09', '00:00:08', '00:00:01', '00:00:07', '00:00:04', '00:00:07', '00:00:02', '00:00:10', NULL, 'Kiahykin vakinshino', 'Mamu nihanihy', 'Noravi hychi mitamiyo');

INSERT INTO public."OpenAiGeneralSettingsSet" VALUES (11996, 2.29, 0.0192, 0.0003);
INSERT INTO public."OpenAiGeneralSettingsSet" VALUES (6014, 1.04, 0.00013, 0.036);

INSERT INTO public."PaymentAvailabilityInCountrySet" VALUES (49148, 'LR', '2001-06-22 05:48:42', true, false, '1985-02-18 13:35:12');
INSERT INTO public."PaymentAvailabilityInCountrySet" VALUES (45509, 'SK', '1993-02-10 13:25:17', true, false, '1992-05-01 04:55:02');

INSERT INTO public."Product" VALUES (36265, '94c4b7e8-3cfc-5848-92a8-da74c5c6131a', 'Rachivayo kora memuna', 21925, 'Shitavi raekinamu komuko', false, 2598, 'Raevakin shiayu shihahycea', NULL, 49765, true, NULL, 0.0014);
INSERT INTO public."Product" VALUES (46839, '90db7347-315e-5e0e-990f-b30ac2b8bb5a', 'Kinke kaishinani mavina', 36065, 'Mumaki vamokea vakihaso', false, 13211, 'Kaiyuha kintakin vano', NULL, 30826, true, NULL, 0.00016);

INSERT INTO public."ProductToProductList" VALUES (22489, NULL, NULL);
INSERT INTO public."ProductToProductList" VALUES (8830, NULL, NULL);

INSERT INTO public."Purchase" VALUES (8888, NULL, NULL, NULL, 0.1, 'Mechiyo rachikai', '2016-05-01 04:27:05', 'Nachi soke', 'Somitami kaiyo kakomu', '1989-02-22 01:52:30', '2005-06-14 17:16:18', '1995-04-08 15:26:19', '1998-03-03 02:44:55', 'Ceavihachi nake', 61771, 'Kokinketa komekin yunomika', 'Kimumea kiva', 'Shihy nia', 699, NULL, NULL, NULL, 'Kako kikeyuke', 'Hynani hyki');
INSERT INTO public."Purchase" VALUES (9886, NULL, NULL, NULL, 0.1, 'Sokaichiha mome', '1981-06-18 17:43:16', 'Soniami makin ceasokaicea', 'Vavime miceashi vashino', '1987-08-20 07:23:04', '1983-12-20 11:31:50', '2019-12-09 00:03:05', '1993-06-22 05:55:13', 'Kohayuni ceano', 45686, 'Shiha ceasonakin', 'Nikashiva nonima', 'Ravikokin nina kaicea', 37502, NULL, NULL, NULL, 'Raerachira meyume noni', 'Nivaso miyuvahy kinvanome');

INSERT INTO public."RevenueCutGeneral" VALUES (65389, 0.0003, '1989-10-26 09:16:32', 22538, 45198, 13211, '2013-02-06 01:29:39');
INSERT INTO public."RevenueCutGeneral" VALUES (9298, 0.00009, '2010-11-27 22:21:17', 15432, 51217, 2598, '1990-07-15 18:36:39');

INSERT INTO public."RevenueCutTenant" VALUES (36947, 0.005, NULL, '1986-03-23 14:35:35', 18926, 64828, 13211, '2016-01-17 12:37:26');
INSERT INTO public."RevenueCutTenant" VALUES (24924, 0.0015, NULL, '1998-03-27 02:40:53', 15549, 49424, 2598, '2009-02-14 13:56:34');

INSERT INTO public."SearchTermsLog" VALUES (17639, 'Kano kinmura kinhasochi', 60140, 'Nokekaira kayukin chime', 'Mehyka chiha soraera', '2020-09-05 08:45:15', 'Soviyo noki', 39335);
INSERT INTO public."SearchTermsLog" VALUES (30322, 'Kainova mumovachi', 63211, 'Hykinkai chima', 'Vani mashi yukinvima', '2020-09-13 08:45:57', 'Niceamo kinmukin', 9964);

INSERT INTO public."ServiceRatingAfterMeetingSet" VALUES (3434, NULL, NULL, NULL, '1989-06-14 17:41:56', 27686, true, true, 'Ninano yomu shiyu', 'Nakin nokaceachi', false, false);
INSERT INTO public."ServiceRatingAfterMeetingSet" VALUES (25144, NULL, NULL, NULL, '2007-12-08 11:47:07', 17059, true, true, 'Kaisoyu makita mushimekin', 'Vichi yoniceavi tako', true, false);

INSERT INTO public."ServiceSettingsAdvisingStatusStashSet" VALUES (2820224, 355, '1996-05-13 16:29:30', '{"Mumishi": "Nahymu mota kakohani"}', NULL, 12351);
INSERT INTO public."ServiceSettingsAdvisingStatusStashSet" VALUES (9087869, 12182, '2000-05-05 04:48:28', '{"Shiso": "Maki kaino"}', NULL, 34855);

INSERT INTO public."ServiceSettingsCallDurationStashSet" VALUES (249772, 1524, '2008-01-01 12:48:28', '{"Kinani": "Koceame hyamu"}', NULL, 62455);
INSERT INTO public."ServiceSettingsCallDurationStashSet" VALUES (7616685, 17724, '1984-05-05 04:12:56', '{"Kaniyu": "Mavi raeyuyo"}', NULL, 42400);

INSERT INTO public."ServiceSettingsCountriesStashSet" VALUES (829731, 8602, '1992-01-25 12:19:52', '{"Kemamume": "Yuame minoni"}', NULL, 3328);
INSERT INTO public."ServiceSettingsCountriesStashSet" VALUES (14588699, 55794, '2006-03-03 02:40:09', '{"Kaikechi": "Yukintaki raeyu chimaceavi"}', NULL, 17367);

INSERT INTO public."ServiceSettingsLanguagesStashSet" VALUES (10713923, 62306, '2015-04-20 03:26:59', '{"Yushimo": "Moyu vakinhy muna"}', NULL, 24502);
INSERT INTO public."ServiceSettingsLanguagesStashSet" VALUES (8336000, 28933, '1997-06-10 17:32:05', '{"Ceamevami": "Mumorae ceahynika visoshi"}', NULL, 48385);

INSERT INTO public."ServiceSettingsOfficeHoursStashSet" VALUES (6838942, 49888, '1994-11-19 22:41:32', '{"Kaimehano": "Ceamo kekinaki moni"}', NULL, 35305);
INSERT INTO public."ServiceSettingsOfficeHoursStashSet" VALUES (12419345, 32725, '1987-04-04 15:32:04', '{"Kinmu": "Kaimea ceakemi"}', NULL, 33926);

INSERT INTO public."ServiceSettingsPricingModelStashSet" VALUES (14297633, 35032, '1984-05-01 04:15:19', '{"Vamiahy": "Vahy ceamichi"}', NULL, 36489);
INSERT INTO public."ServiceSettingsPricingModelStashSet" VALUES (1787934, 9448, '2019-08-04 07:24:39', '{"Kotachi": "Chiceako keyu"}', NULL, 1648);

INSERT INTO public."ServiceSettingsPublishDraftStashSet" VALUES (1570595, 51056, '1998-03-07 02:53:23', '{"Kikera": "Kakira hashihy"}', NULL, 35496);
INSERT INTO public."ServiceSettingsPublishDraftStashSet" VALUES (13755962, 40199, '1985-10-22 21:47:55', '{"Koashi": "Raekaino muki"}', NULL, 44406);

INSERT INTO public."ServiceSettingsPublishInfoStashSet" VALUES (3405762, 45045, '1997-06-18 17:32:41', '{"Kayura": "Ceako takinyu makia"}', NULL, 27625);
INSERT INTO public."ServiceSettingsPublishInfoStashSet" VALUES (11339582, 1505, '1999-04-20 03:41:46', '{"Kikaiaso": "Kemoka murakike"}', NULL, 21756);

INSERT INTO public."ServiceSettingsServicesStashSet" VALUES (2384521, 63824, '2010-07-23 06:35:23', NULL, '{"Tayochi": "Menomita koniha momu"}', 30832);
INSERT INTO public."ServiceSettingsServicesStashSet" VALUES (5350704, 34943, '2003-08-24 07:55:45', NULL, '{"Ceanisova": "Noka rasochi kechinoka"}', 48690);

INSERT INTO public."ServiceStatsSet" VALUES (52901, 12002930, 52452);
INSERT INTO public."ServiceStatsSet" VALUES (45366, 12252083, 19683);

INSERT INTO public."ServiceTypeCategoryEnumSet" VALUES (27828, 'Chimakiko machikorae kekaimu', '2012-09-13 08:46:54', true, 59321);
INSERT INTO public."ServiceTypeCategoryEnumSet" VALUES (2338, 'Vamuvishi konike raea', '1982-11-07 10:37:30', true, 24192);

INSERT INTO public."ServiceTypeCategoryConnectionTenantStaticSet" VALUES (28444, 11722, NULL, NULL);
INSERT INTO public."ServiceTypeCategoryConnectionTenantStaticSet" VALUES (9856, 30039, NULL, NULL);

INSERT INTO public."SpamProtectionDomainSet" VALUES (1646358, 'Monserrate_Greenfelder39150@fascinatecreditor.biz', 'Rhode Island', '2018-11-07 23:14:26+00', '2008-01-09 12:55:01+00', false, false);
INSERT INTO public."SpamProtectionDomainSet" VALUES (14886585, 'Beth.Leannon2152@nearlender.net', 'Tennessee', '1983-08-16 20:55:23+01', '1999-08-08 20:29:23+01', false, false);

INSERT INTO public."SsoPwSet" VALUES (43656, 'Mita shike', 4858, 'Hahyvaki', 'Moyuva moraeko mukovake');
INSERT INTO public."SsoPwSet" VALUES (59836, 'Nakin kincea', 21192, 'Kenoka', 'Moha chima nayokin');

INSERT INTO public."TaxInCountrySet" VALUES (24624, 'NZ', 0.001, '1996-01-13 00:44:36', '1992-09-01 20:37:15');
INSERT INTO public."TaxInCountrySet" VALUES (52758, 'FJ', 0.0008, '1999-12-12 12:08:59', '2005-06-18 17:08:33');

INSERT INTO public."Temp_IndustryTypeTranslationKeys2" VALUES (1955, 'Kekomeno chime kenakeno');
INSERT INTO public."Temp_IndustryTypeTranslationKeys2" VALUES (28501, 'Koraekani komeacea');

INSERT INTO public."TermsAndConditionSet" VALUES (15503262, '2013-06-02 17:53:15', NULL, 13211, 'Hakonamu mekai hykaimeha', NULL, '0bc3f8ee-6848-5db4-a3b4-0dc49515e391', true);
INSERT INTO public."TermsAndConditionSet" VALUES (12368022, '2006-03-07 02:39:03', NULL, 2598, 'Vahymovi nova ceame', NULL, '2c32d338-f704-54b8-a074-752e3517a5e3', false);

INSERT INTO public."UploadStashSets" VALUES (17513, 'Mimoni yuhameyu kinake', 'Tahyno ramu', 'Maceamocea kahykai hykin', '2016-09-01 20:56:07', '1986-03-03 14:33:37', NULL, NULL);
INSERT INTO public."UploadStashSets" VALUES (7162, 'Tashi miso', 'Kashi mehachika nayota', 'Hachimova ceaki', '1995-04-24 15:26:07', '1981-06-18 17:48:17', NULL, NULL);

INSERT INTO public."VideoOnDemandInformationStashSet" VALUES (59207, NULL, 58098, 39192, '2016-09-21 20:59:08', '{"Miyo": "Muvakechi kairamu nohy"}', NULL, 52212);
INSERT INTO public."VideoOnDemandInformationStashSet" VALUES (6312766, NULL, 17721, 5495, '1980-01-21 00:11:46', '{"Nomi": "Yumemo menacea nika"}', NULL, 47105);



SELECT pg_catalog.setval('hangfire.counter_id_seq', 1, false);

SELECT pg_catalog.setval('hangfire.hash_id_seq', 1, false);

SELECT pg_catalog.setval('hangfire.job_id_seq', 1, false);

SELECT pg_catalog.setval('hangfire.jobparameter_id_seq', 1, false);

SELECT pg_catalog.setval('hangfire.jobqueue_id_seq', 1, false);

SELECT pg_catalog.setval('hangfire.list_id_seq', 1, false);

SELECT pg_catalog.setval('hangfire.set_id_seq', 1, false);

SELECT pg_catalog.setval('hangfire.state_id_seq', 1, false);

SELECT pg_catalog.setval('public."AboutAccountConnectionSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."AccountInvoiceInformationSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."AccountMultitenancySet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."AccountQuotaPerDaySet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."AccountSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."AccountStatsSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."AccountStatusTenantAware_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."AccountStatus_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."AnonymousUserEventTrackingPerDaySet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."AnonymousUserEventTrackingSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."AppliedCouponConnection_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."BookingRequestSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."BookmarkConnectionExpertStaticSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."BookmarkConnectionStaticBase_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."BookmarkConnectionWithHistoryBaseSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."CognitoUsernameSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ConversationMessageReadByAccountSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ConversationMessageSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ConversationSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."Coupon_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."CustomAccountLinkSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."CustomOfferConnectionStaticSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."CustomOfferSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."FaqCategorySet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."FaqSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."FeaturedExpertsServiceSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."GeneralSettingsSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."GoalSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."HashtagConnectionSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."HashtagSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."HubspotMappingSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."InviteConnectionSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."KycCompanyConnectionAccountStaticSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."KycCompanyStashSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."KycCompany_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."KycDocumentSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."LegalDocumentSequenceSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."LegalDocumentSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."LikeAndFollowExpertHistory_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."MangpayInfo_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."MeetingInformationSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."MeetingWhitelistAccountEntrySet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."MeetingWhitelistEmailEntrySet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."MicroAdvisorySophiaRequestLeadingToAccountAndProjectSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."NotificationSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."OfficeHoursBreakSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."OfficeHoursSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."OpenAiGeneralSettingsSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."PaymentAvailabilityInCountrySet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."PaymentInformations_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ProductList_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ProductToProductList_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."Product_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ProjectSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."PromptEngineeringAiSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."PurchaseDetailsSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."RegistrationWaitinglist_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."RevenueCutGeneral_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."RevenueCutTenant_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."SearchTermsLog_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceRatingAfterMeetingSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceSearchSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceSettingsAdvisingStatusStashSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceSettingsCallDurationStashSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceSettingsCountriesStashSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceSettingsLanguagesStashSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceSettingsOfficeHoursStashSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceSettingsPricingModelStashSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceSettingsPublishDraftStashSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceSettingsPublishInfoStashSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceSettingsServicesStashSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceStatsSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceTypeCategoryConnectionTenantStaticSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceTypeCategoryEnumSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."ServiceTypeEnumSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."SpamProtectionDomainSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."SsoPwSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."SuccessStorySet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."TaxInCountrySet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."TenantSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."TermsAndConditionSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."TransactionDetailsSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."UploadSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."UploadStashSets_Id_seq"', 1, false);

SELECT pg_catalog.setval('public."VideoOnDemandInformationStashSet_Id_seq"', 1, false);

SELECT pg_catalog.setval('public.servicesearchset', 1, false);

SELECT pg_catalog.setval('public.serviceset', 1, false);
SET session_replication_role = 'origin';
