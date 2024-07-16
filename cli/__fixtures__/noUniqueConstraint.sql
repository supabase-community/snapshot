--
-- PostgreSQL database dump
--

-- Dumped from database version 12.8
-- Dumped by pg_dump version 13.4
-- DatabaseId: 10

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS public;


--
-- Name: AnonymousSupporterActivity; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."AnonymousSupporterActivity" AS ENUM (
    'jogger',
    'skier',
    'walker',
    'biker',
    'skater',
    'bowler',
    'curler',
    'snowboarder',
    'runner',
    'dancer',
    'cook',
    'baker',
    'boxer',
    'hiker',
    'shopper',
    'programmer',
    'builder'
);


--
-- Name: AnonymousSupporterColors; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."AnonymousSupporterColors" AS ENUM (
    'blue',
    'brown',
    'green',
    'maroon',
    'pink',
    'purple',
    'red',
    'yellow'
);


--
-- Name: DonationStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."DonationStatus" AS ENUM (
    'canceled',
    'processing',
    'requires_action',
    'requires_capture',
    'requires_confirmation',
    'requires_payment_method',
    'succeeded',
    'pending',
    'failed'
);


--
-- Name: DonationSubscriptionStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."DonationSubscriptionStatus" AS ENUM (
    'active',
    'incomplete'
);


--
-- Name: DonationType; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."DonationType" AS ENUM (
    'SINGLE',
    'MONTHLY'
);


--
-- Name: InvitationStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."InvitationStatus" AS ENUM (
    'SENT',
    'REVOKED',
    'ACCEPTED',
    'DECLINED'
);


--
-- Name: LoginProvider; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."LoginProvider" AS ENUM (
    'magic',
    'google',
    'webAuth'
);


--
-- Name: LogoSize; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."LogoSize" AS ENUM (
    'default',
    'sm',
    'md',
    'lg'
);


--
-- Name: OnboardingStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."OnboardingStatus" AS ENUM (
    'completed',
    'skipped',
    'notStarted'
);


--
-- Name: OnboardingTeamStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."OnboardingTeamStatus" AS ENUM (
    'completed',
    'skipped',
    'closed',
    'notStarted'
);


--
-- Name: TaxSchemeGBDeclarationStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."TaxSchemeGBDeclarationStatus" AS ENUM (
    'CLAIMED',
    'UNCLAIMED',
    'EXPORTED'
);


--
-- Name: TeamLogRetention; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."TeamLogRetention" AS ENUM (
    'threeDays',
    'oneWeek',
    'oneMonth',
    'infinite'
);


--
-- Name: TeamMemberLogActionTypes; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."TeamMemberLogActionTypes" AS ENUM (
    'CREATE',
    'READ',
    'UPDATE',
    'DELETE',
    'DOWNLOAD'
);


--
-- Name: TeamRBACEnum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."TeamRBACEnum" AS ENUM (
    'basic',
    'advanced',
    'customisable'
);


--
-- Name: linkType; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."linkType" AS ENUM (
    'fundraiser',
    'default'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Donation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Donation" (
    id text NOT NULL,
    "stripePaymentIntentId" text NOT NULL,
    "coverEverfundFeeAmount" integer NOT NULL,
    "coverFeeAmount" integer NOT NULL,
    "coverNonProfitReceives" integer NOT NULL,
    "coverNonProfitReceivesTaxSchemeGB" integer NOT NULL,
    "coverStripeFeeAmount" integer NOT NULL,
    "isCoveringFee" boolean DEFAULT true NOT NULL,
    "isDomesticCard" boolean DEFAULT true NOT NULL,
    "isSameCurrency" boolean DEFAULT true NOT NULL,
    "notCoverEverfundFeeAmount" integer NOT NULL,
    "notCoverFeeAmount" integer NOT NULL,
    "notCoverNonProfitReceives" integer NOT NULL,
    "notCoverNonProfitReceivesTaxSchemeGB" integer NOT NULL,
    "notCoverStripeFeeAmount" integer NOT NULL,
    "baseAmount" integer NOT NULL,
    "marketingEmail" boolean DEFAULT false NOT NULL,
    "marketingPhone" boolean DEFAULT false NOT NULL,
    "marketingPost" boolean DEFAULT false NOT NULL,
    status public."DonationStatus" NOT NULL,
    "accountId" text NOT NULL,
    "teamId" text NOT NULL,
    "linkId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "taxSchemeGBDeclarationId" text,
    "supporterId" text,
    "supporterAddressId" text,
    "countryCurrencyCode" text DEFAULT 'GBP'::text NOT NULL,
    "countryLanguageTag" text DEFAULT 'en-GB'::text NOT NULL,
    "liveMode" boolean DEFAULT true NOT NULL,
    type public."DonationType" DEFAULT 'SINGLE'::public."DonationType" NOT NULL,
    "donationSubscriptionId" text,
    "taxSchemeGBDeclarationStatus" public."TaxSchemeGBDeclarationStatus"
);


--
-- Name: DonationSubscription; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."DonationSubscription" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "stripeSubscriptionId" text NOT NULL,
    status public."DonationSubscriptionStatus" DEFAULT 'active'::public."DonationSubscriptionStatus" NOT NULL,
    "liveMode" boolean DEFAULT true NOT NULL,
    "supporterId" text NOT NULL,
    "teamId" text NOT NULL,
    "accountId" text NOT NULL,
    "linkId" text NOT NULL
);


--
-- Name: File; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."File" (
    id text NOT NULL,
    data jsonb NOT NULL,
    "teamId" text NOT NULL,
    "teamMemberId" text NOT NULL,
    "userId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Fundraiser; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Fundraiser" (
    id text NOT NULL,
    "teamId" text NOT NULL,
    "expiryDate" timestamp(3) without time zone,
    "showExpiryDate" boolean DEFAULT false NOT NULL,
    target integer NOT NULL,
    "totalEstimatedGiftAid" integer NOT NULL,
    "totalRaisedOffline" integer NOT NULL,
    "totalRaisedOnline" integer NOT NULL,
    "totalRaisedPercentageOfFundraisingTarget" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: Link; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Link" (
    id text NOT NULL,
    "shortLink" text NOT NULL,
    "accountId" text NOT NULL,
    "canCollectGiftAid" boolean DEFAULT true NOT NULL,
    "canCollectMarketingInformation" boolean DEFAULT true NOT NULL,
    "countryCurrencyCode" text DEFAULT 'GBP'::text NOT NULL,
    "countryISO" text DEFAULT 'GB'::text NOT NULL,
    "countryLanguageTag" text DEFAULT 'en-GB'::text NOT NULL,
    "domainId" text NOT NULL,
    "templateId" text,
    "fundraiserId" text,
    "teamId" text NOT NULL,
    "textStory" text NOT NULL,
    "textThankYou" text NOT NULL,
    type public."linkType" NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "liveMode" boolean DEFAULT true NOT NULL,
    archived boolean DEFAULT false NOT NULL,
    "teamOrganisationId" text
);


--
-- Name: LinkDomain; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."LinkDomain" (
    id text NOT NULL,
    domain text DEFAULT 'evr.fund'::text NOT NULL,
    free boolean DEFAULT false NOT NULL
);


--
-- Name: LinkTemplate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."LinkTemplate" (
    id text NOT NULL,
    "colorAccent" text DEFAULT '#E65F66'::text NOT NULL,
    "colorBackground" text DEFAULT '#252F3F'::text NOT NULL,
    "imageBackground" text,
    "imageLogo" text,
    "imageLogoSize" public."LogoSize",
    "imageOGImage" text,
    "showDonationGoals" boolean DEFAULT false NOT NULL,
    "showEverfundBranding" boolean DEFAULT true NOT NULL,
    "teamId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    name text NOT NULL
);


--
-- Name: LinkTemplateGoal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."LinkTemplateGoal" (
    id text NOT NULL,
    amount integer NOT NULL,
    "teamId" text NOT NULL,
    text text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: RW_DataMigration; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."RW_DataMigration" (
    version text NOT NULL,
    name text NOT NULL,
    "startedAt" timestamp(3) without time zone NOT NULL,
    "finishedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: Supporter; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Supporter" (
    id text NOT NULL,
    phone text,
    email text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "anonymousActivity" public."AnonymousSupporterActivity",
    "anonymousColors" public."AnonymousSupporterColors",
    "anonymousCode" text,
    title text,
    "firstName" text,
    "lastName" text,
    "middleName" text
);


--
-- Name: SupporterAddress; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."SupporterAddress" (
    id text NOT NULL,
    city text NOT NULL,
    country text,
    line1 text NOT NULL,
    line2 text,
    "postalCode" text NOT NULL,
    state text,
    "supporterId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: TaxSchemeGBDeclaration; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TaxSchemeGBDeclaration" (
    id text NOT NULL,
    "teamId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "supporterId" text,
    title text,
    "firstName" text,
    "lastName" text,
    "middleName" text,
    "supporterAddressId" text
);


--
-- Name: Team; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Team" (
    id text NOT NULL,
    "avatarUrl" text,
    name text NOT NULL,
    "shortName" text,
    "teamCountryCurrencyCode" text DEFAULT 'GBP'::text NOT NULL,
    "teamCountryISO" text DEFAULT 'GB'::text NOT NULL,
    "teamCountryLanguageTag" text DEFAULT 'en-GB'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "billingBillableUsers" integer DEFAULT 1 NOT NULL,
    "billingEmail" text,
    "billingPriceId" text,
    "billingCustomerId" text,
    "billingSubscriptionItemId" text,
    "onboardingHasLinks" public."OnboardingTeamStatus" DEFAULT 'notStarted'::public."OnboardingTeamStatus",
    "onboardingHasInvitedTeamMember" public."OnboardingTeamStatus" DEFAULT 'notStarted'::public."OnboardingTeamStatus",
    "onboardingCompleted" boolean DEFAULT false NOT NULL,
    "teamOrganisationId" text,
    "onboardingHasOrganisation" public."OnboardingTeamStatus" DEFAULT 'notStarted'::public."OnboardingTeamStatus",
    "onboardingHasPaymentDestination" public."OnboardingTeamStatus" DEFAULT 'notStarted'::public."OnboardingTeamStatus",
    "teamToggleId" text
);


--
-- Name: TeamInvitation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TeamInvitation" (
    id text NOT NULL,
    email text NOT NULL,
    "invitedById" text,
    "roleId" text,
    status public."InvitationStatus" DEFAULT 'SENT'::public."InvitationStatus" NOT NULL,
    "teamId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: TeamMember; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TeamMember" (
    id text NOT NULL,
    "teamId" text,
    "userId" text,
    "teamMemberFirstName" text,
    "teamMemberLastName" text,
    "preferTeamMemberName" boolean DEFAULT false NOT NULL,
    "jobTitle" text,
    phone text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "teamMemberRoleId" text,
    "donationViewSingleLastViewed" timestamp(3) without time zone,
    "donationViewRecurringLastViewed" timestamp(3) without time zone,
    "donationViewGiftAidLastViewed" timestamp(3) without time zone,
    "donationViewMarketingLastViewed" timestamp(3) without time zone
);


--
-- Name: TeamMemberLog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TeamMemberLog" (
    id text NOT NULL,
    "actionType" public."TeamMemberLogActionTypes" NOT NULL,
    description text NOT NULL,
    "extraData" jsonb,
    "ipAddress" text,
    "teamId" text NOT NULL,
    "teamMemberId" text NOT NULL,
    "userId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "expirationDate" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    action text
);


--
-- Name: TeamMemberPermission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TeamMemberPermission" (
    id text NOT NULL,
    name text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: TeamMemberRole; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TeamMemberRole" (
    id text NOT NULL,
    name text NOT NULL,
    uneditable boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: TeamOrganisation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TeamOrganisation" (
    id text NOT NULL,
    "companiesHouseName" text,
    "companiesHouseNumber" text,
    "charitiesRegisterNumber" text,
    activities text,
    "organisationWebsite" text,
    "organisationPhoneNumber" text,
    "companyAddressCity" text,
    "companyAddressCountry" text,
    "companyAddressLine1" text,
    "companyAddressLine2" text,
    "companyAddressPostalCode" text,
    "companyAddressState" text,
    "companyAddressLat" double precision,
    "companyAddressLng" double precision,
    "socialFacebook" text,
    "socialInstagram" text,
    "socialTwitter" text,
    "socialLinkedIn" text,
    "socialYoutube" text,
    "supportPhoneNumber" text,
    "supportEmail" text,
    "supportWebsite" text,
    "supportAddressCity" text,
    "supportAddressCountry" text,
    "supportAddressLine1" text,
    "supportAddressLine2" text,
    "supportAddressPostalCode" text,
    "supportAddressState" text,
    "supportAddressLat" double precision,
    "supportAddressLng" double precision,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "completedMainForm" public."OnboardingTeamStatus" DEFAULT 'notStarted'::public."OnboardingTeamStatus",
    "completedSignificantControl" public."OnboardingTeamStatus" DEFAULT 'notStarted'::public."OnboardingTeamStatus",
    "completedSupport" public."OnboardingTeamStatus" DEFAULT 'notStarted'::public."OnboardingTeamStatus"
);


--
-- Name: TeamOrganisationPerson; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TeamOrganisationPerson" (
    id text NOT NULL,
    "firstName" text NOT NULL,
    "lastName" text NOT NULL,
    "phoneNumber" text,
    email text,
    "dobDay" integer,
    "dobMonth" integer,
    "dobYear" integer,
    "jobTitle" text,
    representative boolean NOT NULL,
    director boolean NOT NULL,
    executive boolean NOT NULL,
    owner boolean NOT NULL,
    "idDocumentFrontId" text,
    "idDocumentBackId" text,
    "additionalIdDocumentFrontId" text,
    "additionalIdDocumentBackId" text,
    "addressCity" text,
    "addressCountry" text,
    "addressLine1" text,
    "addressLine2" text,
    "addressPostcode" text,
    "teamOrganisationId" text,
    "teamId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: TeamPaymentDestination; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TeamPaymentDestination" (
    id text NOT NULL,
    "teamId" text,
    "applicationFee" integer DEFAULT 3 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "accountName" text NOT NULL,
    "legacyAccount" boolean DEFAULT false NOT NULL
);


--
-- Name: TeamSupporter; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TeamSupporter" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    title text,
    "middleName" text,
    "firstName" text,
    "lastName" text,
    phone text,
    email text,
    "teamId" text NOT NULL,
    "supporterId" text NOT NULL,
    "anonymousActivity" public."AnonymousSupporterActivity",
    "anonymousColors" public."AnonymousSupporterColors",
    "anonymousCode" text,
    "addressId" text,
    "taxSchemeGBDeclarationId" text
);


--
-- Name: TeamToggle; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TeamToggle" (
    id text NOT NULL,
    "adminCreatedTeamOrgnisation" boolean DEFAULT false NOT NULL,
    "adminCreatedPaymentDestination" boolean DEFAULT false NOT NULL,
    "adminCreatedDonationLinks" boolean DEFAULT false NOT NULL,
    "adminCreatedWebsiteWidget" boolean DEFAULT false NOT NULL,
    "logRetention" public."TeamLogRetention" DEFAULT 'threeDays'::public."TeamLogRetention" NOT NULL,
    "teamRBAC" public."TeamRBACEnum" DEFAULT 'basic'::public."TeamRBACEnum" NOT NULL,
    "giftAidCollection" boolean DEFAULT false NOT NULL,
    "marketingCollection" boolean DEFAULT false NOT NULL,
    "websiteDonationSystem" boolean DEFAULT false NOT NULL,
    "donationLinksCreation" boolean DEFAULT false NOT NULL,
    "donationLinksMakeUnlimited" boolean DEFAULT false NOT NULL,
    "donationLinksGoals" boolean DEFAULT false NOT NULL,
    "donationLinksThankYouMessage" boolean DEFAULT false NOT NULL,
    "donationLinksCustomiseStyles" boolean DEFAULT false NOT NULL,
    "donationLinksAddressVerifier" boolean DEFAULT false NOT NULL,
    "donationLinksCustomOGMeta" boolean DEFAULT false NOT NULL
);


--
-- Name: User; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."User" (
    id text NOT NULL,
    "currentTeamId" text,
    "currentRoleId" text,
    email text,
    issuer text NOT NULL,
    "publicAddress" text NOT NULL,
    "firstName" text,
    "lastName" text,
    "avatarUrl" text,
    "loginProvider" public."LoginProvider" NOT NULL,
    "onboardingHasAvatar" public."OnboardingStatus" DEFAULT 'notStarted'::public."OnboardingStatus",
    "onboardingHasName" public."OnboardingStatus" DEFAULT 'notStarted'::public."OnboardingStatus",
    "onboardingHasTeam" public."OnboardingStatus" DEFAULT 'notStarted'::public."OnboardingStatus",
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "onboardingHasTermsAndConditions" public."OnboardingStatus" DEFAULT 'notStarted'::public."OnboardingStatus",
    "onboardingHasPrivacyPolicy" public."OnboardingStatus" DEFAULT 'notStarted'::public."OnboardingStatus"
);


--
-- Name: _LinkTemplateToLinkTemplateGoal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."_LinkTemplateToLinkTemplateGoal" (
    "A" text NOT NULL,
    "B" text NOT NULL
);


--
-- Name: _TeamMemberPermissionToTeamMemberRole; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."_TeamMemberPermissionToTeamMemberRole" (
    "A" text NOT NULL,
    "B" text NOT NULL
);


--
-- Name: _TeamToTeamMemberRole; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."_TeamToTeamMemberRole" (
    "A" text NOT NULL,
    "B" text NOT NULL
);


--
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
-- Name: DonationSubscription DonationSubscription_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DonationSubscription"
    ADD CONSTRAINT "DonationSubscription_pkey" PRIMARY KEY (id);


--
-- Name: File File_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."File"
    ADD CONSTRAINT "File_pkey" PRIMARY KEY (id);


--
-- Name: Fundraiser Fundraiser_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Fundraiser"
    ADD CONSTRAINT "Fundraiser_pkey" PRIMARY KEY (id);


--
-- Name: LinkDomain LinkDomain_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."LinkDomain"
    ADD CONSTRAINT "LinkDomain_pkey" PRIMARY KEY (id);


--
-- Name: LinkTemplateGoal LinkTemplateGoal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."LinkTemplateGoal"
    ADD CONSTRAINT "LinkTemplateGoal_pkey" PRIMARY KEY (id);


--
-- Name: LinkTemplate LinkTemplate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."LinkTemplate"
    ADD CONSTRAINT "LinkTemplate_pkey" PRIMARY KEY (id);


--
-- Name: Link Link_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Link"
    ADD CONSTRAINT "Link_pkey" PRIMARY KEY (id);


--
-- Name: RW_DataMigration RW_DataMigration_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RW_DataMigration"
    ADD CONSTRAINT "RW_DataMigration_pkey" PRIMARY KEY (version);


--
-- Name: Donation SinglePayment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Donation"
    ADD CONSTRAINT "SinglePayment_pkey" PRIMARY KEY (id);


--
-- Name: SupporterAddress SupporterAddress_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SupporterAddress"
    ADD CONSTRAINT "SupporterAddress_pkey" PRIMARY KEY (id);


--
-- Name: Supporter Supporter_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Supporter"
    ADD CONSTRAINT "Supporter_pkey" PRIMARY KEY (id);


--
-- Name: TaxSchemeGBDeclaration TaxSchemeGBDeclaration_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TaxSchemeGBDeclaration"
    ADD CONSTRAINT "TaxSchemeGBDeclaration_pkey" PRIMARY KEY (id);


--
-- Name: TeamInvitation TeamInvitation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamInvitation"
    ADD CONSTRAINT "TeamInvitation_pkey" PRIMARY KEY (id);


--
-- Name: TeamMemberLog TeamMemberLog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamMemberLog"
    ADD CONSTRAINT "TeamMemberLog_pkey" PRIMARY KEY (id);


--
-- Name: TeamMemberPermission TeamMemberPermission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamMemberPermission"
    ADD CONSTRAINT "TeamMemberPermission_pkey" PRIMARY KEY (id);


--
-- Name: TeamMemberRole TeamMemberRole_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamMemberRole"
    ADD CONSTRAINT "TeamMemberRole_pkey" PRIMARY KEY (id);


--
-- Name: TeamMember TeamMember_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamMember"
    ADD CONSTRAINT "TeamMember_pkey" PRIMARY KEY (id);


--
-- Name: TeamOrganisationPerson TeamOrganisationPerson_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamOrganisationPerson"
    ADD CONSTRAINT "TeamOrganisationPerson_pkey" PRIMARY KEY (id);


--
-- Name: TeamOrganisation TeamOrganisation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamOrganisation"
    ADD CONSTRAINT "TeamOrganisation_pkey" PRIMARY KEY (id);


--
-- Name: TeamPaymentDestination TeamPaymentAccount_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamPaymentDestination"
    ADD CONSTRAINT "TeamPaymentAccount_pkey" PRIMARY KEY (id);


--
-- Name: TeamSupporter TeamSupporter_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamSupporter"
    ADD CONSTRAINT "TeamSupporter_pkey" PRIMARY KEY (id);


--
-- Name: TeamToggle TeamToggle_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamToggle"
    ADD CONSTRAINT "TeamToggle_pkey" PRIMARY KEY (id);


--
-- Name: Team Team_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Team"
    ADD CONSTRAINT "Team_pkey" PRIMARY KEY (id);


--
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (id);


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: Donation.stripePaymentIntentId_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Donation.stripePaymentIntentId_unique" ON public."Donation" USING btree ("stripePaymentIntentId");


--
-- Name: DonationSubscription.stripeSubscriptionId_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "DonationSubscription.stripeSubscriptionId_unique" ON public."DonationSubscription" USING btree ("stripeSubscriptionId");


--
-- Name: Link.shortLink_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Link.shortLink_unique" ON public."Link" USING btree ("shortLink");


--
-- Name: LinkDomain.domain_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "LinkDomain.domain_unique" ON public."LinkDomain" USING btree (domain);


--
-- Name: Supporter.anonymousCode_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Supporter.anonymousCode_unique" ON public."Supporter" USING btree ("anonymousCode");


--
-- Name: Supporter.email_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Supporter.email_unique" ON public."Supporter" USING btree (email);


--
-- Name: TaxSchemeGBDeclaration_supporterAddressId_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "TaxSchemeGBDeclaration_supporterAddressId_unique" ON public."TaxSchemeGBDeclaration" USING btree ("supporterAddressId");


--
-- Name: Team.billingCustomerId_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Team.billingCustomerId_unique" ON public."Team" USING btree ("billingCustomerId");


--
-- Name: TeamMemberPermission.name_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "TeamMemberPermission.name_unique" ON public."TeamMemberPermission" USING btree (name);


--
-- Name: TeamSupporter.teamId_supporterId_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "TeamSupporter.teamId_supporterId_unique" ON public."TeamSupporter" USING btree ("teamId", "supporterId");


--
-- Name: TeamSupporter_addressId_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "TeamSupporter_addressId_unique" ON public."TeamSupporter" USING btree ("addressId");


--
-- Name: TeamSupporter_taxSchemeGBDeclarationId_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "TeamSupporter_taxSchemeGBDeclarationId_unique" ON public."TeamSupporter" USING btree ("taxSchemeGBDeclarationId");


--
-- Name: Team_teamToggleId_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Team_teamToggleId_unique" ON public."Team" USING btree ("teamToggleId");


--
-- Name: User.email_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "User.email_unique" ON public."User" USING btree (email);


--
-- Name: User.issuer_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "User.issuer_unique" ON public."User" USING btree (issuer);


--
-- Name: _LinkTemplateToLinkTemplateGoal_AB_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "_LinkTemplateToLinkTemplateGoal_AB_unique" ON public."_LinkTemplateToLinkTemplateGoal" USING btree ("A", "B");


--
-- Name: _LinkTemplateToLinkTemplateGoal_B_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "_LinkTemplateToLinkTemplateGoal_B_index" ON public."_LinkTemplateToLinkTemplateGoal" USING btree ("B");


--
-- Name: _TeamMemberPermissionToTeamMemberRole_AB_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "_TeamMemberPermissionToTeamMemberRole_AB_unique" ON public."_TeamMemberPermissionToTeamMemberRole" USING btree ("A", "B");


--
-- Name: _TeamMemberPermissionToTeamMemberRole_B_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "_TeamMemberPermissionToTeamMemberRole_B_index" ON public."_TeamMemberPermissionToTeamMemberRole" USING btree ("B");


--
-- Name: _TeamToTeamMemberRole_AB_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "_TeamToTeamMemberRole_AB_unique" ON public."_TeamToTeamMemberRole" USING btree ("A", "B");


--
-- Name: _TeamToTeamMemberRole_B_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "_TeamToTeamMemberRole_B_index" ON public."_TeamToTeamMemberRole" USING btree ("B");


--
-- Name: DonationSubscription DonationSubscription_accountId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DonationSubscription"
    ADD CONSTRAINT "DonationSubscription_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES public."TeamPaymentDestination"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: DonationSubscription DonationSubscription_linkId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DonationSubscription"
    ADD CONSTRAINT "DonationSubscription_linkId_fkey" FOREIGN KEY ("linkId") REFERENCES public."Link"("shortLink") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: DonationSubscription DonationSubscription_supporterId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DonationSubscription"
    ADD CONSTRAINT "DonationSubscription_supporterId_fkey" FOREIGN KEY ("supporterId") REFERENCES public."Supporter"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: DonationSubscription DonationSubscription_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DonationSubscription"
    ADD CONSTRAINT "DonationSubscription_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: File File_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."File"
    ADD CONSTRAINT "File_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: File File_teamMemberId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."File"
    ADD CONSTRAINT "File_teamMemberId_fkey" FOREIGN KEY ("teamMemberId") REFERENCES public."TeamMember"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: File File_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."File"
    ADD CONSTRAINT "File_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Fundraiser Fundraiser_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Fundraiser"
    ADD CONSTRAINT "Fundraiser_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: LinkTemplateGoal LinkTemplateGoal_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."LinkTemplateGoal"
    ADD CONSTRAINT "LinkTemplateGoal_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: LinkTemplate LinkTemplate_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."LinkTemplate"
    ADD CONSTRAINT "LinkTemplate_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Link Link_accountId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Link"
    ADD CONSTRAINT "Link_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES public."TeamPaymentDestination"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Link Link_domainId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Link"
    ADD CONSTRAINT "Link_domainId_fkey" FOREIGN KEY ("domainId") REFERENCES public."LinkDomain"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Link Link_fundraiserId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Link"
    ADD CONSTRAINT "Link_fundraiserId_fkey" FOREIGN KEY ("fundraiserId") REFERENCES public."Fundraiser"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Link Link_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Link"
    ADD CONSTRAINT "Link_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Link Link_teamOrganisationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Link"
    ADD CONSTRAINT "Link_teamOrganisationId_fkey" FOREIGN KEY ("teamOrganisationId") REFERENCES public."TeamOrganisation"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Link Link_templateId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Link"
    ADD CONSTRAINT "Link_templateId_fkey" FOREIGN KEY ("templateId") REFERENCES public."LinkTemplate"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Donation SinglePayment_accountId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Donation"
    ADD CONSTRAINT "SinglePayment_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES public."TeamPaymentDestination"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Donation SinglePayment_donationSubscriptionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Donation"
    ADD CONSTRAINT "SinglePayment_donationSubscriptionId_fkey" FOREIGN KEY ("donationSubscriptionId") REFERENCES public."DonationSubscription"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Donation SinglePayment_linkId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Donation"
    ADD CONSTRAINT "SinglePayment_linkId_fkey" FOREIGN KEY ("linkId") REFERENCES public."Link"("shortLink") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Donation SinglePayment_supporterAddressId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Donation"
    ADD CONSTRAINT "SinglePayment_supporterAddressId_fkey" FOREIGN KEY ("supporterAddressId") REFERENCES public."SupporterAddress"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Donation SinglePayment_supporterId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Donation"
    ADD CONSTRAINT "SinglePayment_supporterId_fkey" FOREIGN KEY ("supporterId") REFERENCES public."Supporter"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Donation SinglePayment_taxSchemeGBDeclarationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Donation"
    ADD CONSTRAINT "SinglePayment_taxSchemeGBDeclarationId_fkey" FOREIGN KEY ("taxSchemeGBDeclarationId") REFERENCES public."TaxSchemeGBDeclaration"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Donation SinglePayment_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Donation"
    ADD CONSTRAINT "SinglePayment_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: SupporterAddress SupporterAddress_supporterId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SupporterAddress"
    ADD CONSTRAINT "SupporterAddress_supporterId_fkey" FOREIGN KEY ("supporterId") REFERENCES public."Supporter"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TaxSchemeGBDeclaration TaxSchemeGBDeclaration_supporterAddressIdNEW_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TaxSchemeGBDeclaration"
    ADD CONSTRAINT "TaxSchemeGBDeclaration_supporterAddressIdNEW_fkey" FOREIGN KEY ("supporterAddressId") REFERENCES public."SupporterAddress"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TaxSchemeGBDeclaration TaxSchemeGBDeclaration_supporterId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TaxSchemeGBDeclaration"
    ADD CONSTRAINT "TaxSchemeGBDeclaration_supporterId_fkey" FOREIGN KEY ("supporterId") REFERENCES public."Supporter"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TaxSchemeGBDeclaration TaxSchemeGBDeclaration_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TaxSchemeGBDeclaration"
    ADD CONSTRAINT "TaxSchemeGBDeclaration_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TeamInvitation TeamInvitation_invitedById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamInvitation"
    ADD CONSTRAINT "TeamInvitation_invitedById_fkey" FOREIGN KEY ("invitedById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TeamInvitation TeamInvitation_roleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamInvitation"
    ADD CONSTRAINT "TeamInvitation_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES public."TeamMemberRole"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TeamInvitation TeamInvitation_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamInvitation"
    ADD CONSTRAINT "TeamInvitation_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TeamMemberLog TeamMemberLog_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamMemberLog"
    ADD CONSTRAINT "TeamMemberLog_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TeamMemberLog TeamMemberLog_teamMemberId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamMemberLog"
    ADD CONSTRAINT "TeamMemberLog_teamMemberId_fkey" FOREIGN KEY ("teamMemberId") REFERENCES public."TeamMember"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TeamMemberLog TeamMemberLog_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamMemberLog"
    ADD CONSTRAINT "TeamMemberLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TeamMember TeamMember_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamMember"
    ADD CONSTRAINT "TeamMember_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TeamMember TeamMember_teamMemberRoleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamMember"
    ADD CONSTRAINT "TeamMember_teamMemberRoleId_fkey" FOREIGN KEY ("teamMemberRoleId") REFERENCES public."TeamMemberRole"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TeamMember TeamMember_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamMember"
    ADD CONSTRAINT "TeamMember_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TeamOrganisationPerson TeamOrganisationPerson_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamOrganisationPerson"
    ADD CONSTRAINT "TeamOrganisationPerson_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TeamOrganisationPerson TeamOrganisationPerson_teamOrganisationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamOrganisationPerson"
    ADD CONSTRAINT "TeamOrganisationPerson_teamOrganisationId_fkey" FOREIGN KEY ("teamOrganisationId") REFERENCES public."TeamOrganisation"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TeamPaymentDestination TeamPaymentAccount_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamPaymentDestination"
    ADD CONSTRAINT "TeamPaymentAccount_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TeamSupporter TeamSupporter_addressId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamSupporter"
    ADD CONSTRAINT "TeamSupporter_addressId_fkey" FOREIGN KEY ("addressId") REFERENCES public."SupporterAddress"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TeamSupporter TeamSupporter_supporterId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamSupporter"
    ADD CONSTRAINT "TeamSupporter_supporterId_fkey" FOREIGN KEY ("supporterId") REFERENCES public."Supporter"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TeamSupporter TeamSupporter_taxSchemeGBDeclarationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamSupporter"
    ADD CONSTRAINT "TeamSupporter_taxSchemeGBDeclarationId_fkey" FOREIGN KEY ("taxSchemeGBDeclarationId") REFERENCES public."TaxSchemeGBDeclaration"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: TeamSupporter TeamSupporter_teamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TeamSupporter"
    ADD CONSTRAINT "TeamSupporter_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Team Team_teamOrganisationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Team"
    ADD CONSTRAINT "Team_teamOrganisationId_fkey" FOREIGN KEY ("teamOrganisationId") REFERENCES public."TeamOrganisation"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Team Team_teamToggleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Team"
    ADD CONSTRAINT "Team_teamToggleId_fkey" FOREIGN KEY ("teamToggleId") REFERENCES public."TeamToggle"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: User User_currentRoleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_currentRoleId_fkey" FOREIGN KEY ("currentRoleId") REFERENCES public."TeamMemberRole"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: User User_currentTeamId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_currentTeamId_fkey" FOREIGN KEY ("currentTeamId") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: _LinkTemplateToLinkTemplateGoal _LinkTemplateToLinkTemplateGoal_A_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."_LinkTemplateToLinkTemplateGoal"
    ADD CONSTRAINT "_LinkTemplateToLinkTemplateGoal_A_fkey" FOREIGN KEY ("A") REFERENCES public."LinkTemplate"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: _LinkTemplateToLinkTemplateGoal _LinkTemplateToLinkTemplateGoal_B_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."_LinkTemplateToLinkTemplateGoal"
    ADD CONSTRAINT "_LinkTemplateToLinkTemplateGoal_B_fkey" FOREIGN KEY ("B") REFERENCES public."LinkTemplateGoal"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: _TeamMemberPermissionToTeamMemberRole _TeamMemberPermissionToTeamMemberRole_A_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."_TeamMemberPermissionToTeamMemberRole"
    ADD CONSTRAINT "_TeamMemberPermissionToTeamMemberRole_A_fkey" FOREIGN KEY ("A") REFERENCES public."TeamMemberPermission"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: _TeamMemberPermissionToTeamMemberRole _TeamMemberPermissionToTeamMemberRole_B_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."_TeamMemberPermissionToTeamMemberRole"
    ADD CONSTRAINT "_TeamMemberPermissionToTeamMemberRole_B_fkey" FOREIGN KEY ("B") REFERENCES public."TeamMemberRole"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: _TeamToTeamMemberRole _TeamToTeamMemberRole_A_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."_TeamToTeamMemberRole"
    ADD CONSTRAINT "_TeamToTeamMemberRole_A_fkey" FOREIGN KEY ("A") REFERENCES public."Team"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: _TeamToTeamMemberRole _TeamToTeamMemberRole_B_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."_TeamToTeamMemberRole"
    ADD CONSTRAINT "_TeamToTeamMemberRole_B_fkey" FOREIGN KEY ("B") REFERENCES public."TeamMemberRole"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--
