--
-- PostgreSQL database dump
--

-- Dumped from database version 14.7 (Homebrew)
-- Dumped by pg_dump version 15.1

-- Started on 2023-03-06 13:02:59 SAST

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
-- TOC entry 9 (class 2615 OID 2148297)
-- Name: heroku_ext; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA heroku_ext;


ALTER SCHEMA heroku_ext OWNER TO postgres;

--
-- TOC entry 8 (class 2615 OID 2148296)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 4278 (class 0 OID 0)
-- Dependencies: 8
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


--
-- TOC entry 2 (class 3079 OID 2148298)
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- TOC entry 4280 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


--
-- TOC entry 3 (class 3079 OID 2148734)
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- TOC entry 4281 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- TOC entry 4 (class 3079 OID 2148759)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA heroku_ext;


--
-- TOC entry 4282 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 983 (class 1247 OID 2148771)
-- Name: DepositMode; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."DepositMode" AS ENUM (
    'LOCKERS',
    'COUNTER'
);


ALTER TYPE public."DepositMode" OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 215 (class 1259 OID 2148775)
-- Name: Address; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Address" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "deletedAt" timestamp(3) without time zone,
    "firstName" text,
    "lastName" text,
    "companyName" text,
    nif text,
    line1 text,
    line2 text,
    "phoneNumber" text,
    "userId" text,
    country text,
    city text,
    province text,
    "parroquiaName" text,
    town text
);


ALTER TABLE public."Address" OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 2148781)
-- Name: CartItem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CartItem" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "purchasedAt" timestamp(3) without time zone,
    "deletedAt" timestamp(3) without time zone,
    quantity integer DEFAULT 1 NOT NULL,
    "userId" text NOT NULL,
    "productId" text NOT NULL,
    comments text,
    "blacklistedCategoriesIds" text[],
    "blacklistedCategoriesNames" text[],
    "blacklistedKeywords" text[],
    "businessMerchantName" text,
    "businessOfferId" text,
    "businessPrice" integer,
    "businessShippingPrice" integer,
    "categoriesIds" text[],
    "categoriesNames" text[],
    color text,
    "deliveryInformation" text,
    description text,
    dimensions text,
    "exportTitle" text,
    features text[],
    "fetchedAt" timestamp(3) without time zone,
    images text[],
    "isAvailable" boolean,
    "isBlacklisted" boolean,
    "isOfferSelectionRequired" boolean,
    "isPrime" boolean,
    "isSecondHand" boolean,
    "maxQuantity" integer,
    "minQuantity" integer,
    "offerListingId" text,
    price integer,
    "priceSlashed" integer,
    "sellerId" text,
    "sellerName" text,
    "shippingPrice" integer,
    title text,
    "variationsItems" jsonb[],
    "variationsSummary" jsonb,
    weight text
);


ALTER TABLE public."CartItem" OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 2148788)
-- Name: CashFlow; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CashFlow" (
    id text NOT NULL,
    concept text DEFAULT ''::text NOT NULL,
    date timestamp(3) without time zone NOT NULL,
    type text DEFAULT 'inflow'::text NOT NULL,
    amount integer NOT NULL,
    "fileHash" text,
    balance integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "deletedAt" timestamp(3) without time zone,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    bank text DEFAULT 'BSE'::text NOT NULL
);


ALTER TABLE public."CashFlow" OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 2148797)
-- Name: CorreosList; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CorreosList" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "sentAt" timestamp(3) without time zone,
    "listName" text NOT NULL,
    "correosLabels" text[],
    "isDelivered" boolean DEFAULT false
);


ALTER TABLE public."CorreosList" OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 2148804)
-- Name: DeliveryAttempt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."DeliveryAttempt" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "parcelId" text NOT NULL,
    "carrierId" text
);


ALTER TABLE public."DeliveryAttempt" OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 2148810)
-- Name: Deposit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Deposit" (
    id text NOT NULL,
    "pickupCode" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "deletedAt" timestamp(3) without time zone,
    "pickedUpAt" timestamp(3) without time zone,
    "codeExpiresAt" timestamp(3) without time zone,
    "depositedById" text,
    "userId" text,
    "cancelledAt" timestamp(3) without time zone,
    "cancelledById" text,
    mode public."DepositMode" NOT NULL,
    "pickupPointId" text NOT NULL,
    "customerNotifiedAt" timestamp(3) without time zone,
    "repsolDiscountClaimedAt" timestamp(3) without time zone
);


ALTER TABLE public."Deposit" OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 2148816)
-- Name: Export; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Export" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    name text NOT NULL,
    "destinationCountry" text,
    "originCountry" text
);


ALTER TABLE public."Export" OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 2148822)
-- Name: Incident; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Incident" (
    id text NOT NULL,
    number text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "completedAt" timestamp(3) without time zone,
    "deletedAt" timestamp(3) without time zone,
    title text,
    description text,
    "dueDate" timestamp(3) without time zone,
    "orderId" text,
    "typeId" text NOT NULL,
    "incidentStatusId" text NOT NULL,
    "assigneeId" text,
    "affectedUserId" text,
    "completedById" text,
    "createdById" text,
    "invoiceId" text,
    "cashFlowId" text,
    "parcelId" text
);


ALTER TABLE public."Incident" OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 2148828)
-- Name: IncidentStatus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."IncidentStatus" (
    id text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."IncidentStatus" OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 2148833)
-- Name: IncidentType; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."IncidentType" (
    id text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."IncidentType" OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 2148838)
-- Name: Invoice; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Invoice" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "billomatId" text,
    number text,
    "orderId" text,
    "typeId" text NOT NULL,
    "group" text,
    "issuedAt" timestamp(3) without time zone,
    "issuerNif" text,
    total integer,
    url text,
    "invoiceReportId" text,
    "issuerName" text,
    "taxAmount1" integer,
    "taxAmount2" integer,
    "taxAmount3" integer,
    "taxBase1" integer,
    "taxBase2" integer,
    "taxBase3" integer,
    "taxRate1" double precision,
    "taxRate2" double precision,
    "taxRate3" double precision,
    "deletedAt" timestamp(3) without time zone,
    completed boolean,
    "vehicleLicensePlate" text,
    "exportId" text,
    "completedAt" timestamp(3) without time zone,
    "primeUserId" text,
    "discountAmount" integer,
    "discountBase" integer,
    "discountRate" double precision,
    "invoiceFileHash" text,
    "invoiceStatusId" text,
    "missingCashflowsReason" text,
    "missingOrderItemsReason" text,
    "validatedById" text,
    "poNumber" text,
    "platformOrderId" text,
    "validatedAt" timestamp(3) without time zone,
    "isAmazon" boolean,
    "rejectReason" text,
    "rejectedAt" timestamp(3) without time zone,
    "pendingClaim" boolean,
    "lockNumber" boolean,
    "claimedAt" timestamp(3) without time zone,
    "mailAttachmentId" text,
    "purchasedByEmail" text
);


ALTER TABLE public."Invoice" OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 2148844)
-- Name: InvoiceReport; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."InvoiceReport" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "invoiceTypeId" text NOT NULL
);


ALTER TABLE public."InvoiceReport" OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 2148850)
-- Name: InvoiceStatus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."InvoiceStatus" (
    id text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."InvoiceStatus" OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 2148855)
-- Name: InvoiceType; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."InvoiceType" (
    id text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."InvoiceType" OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 2148860)
-- Name: Locker; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Locker" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "pickupPointId" text NOT NULL,
    "megablokLockerId" integer,
    height integer NOT NULL,
    width integer NOT NULL,
    "isAvailable" boolean DEFAULT true NOT NULL,
    "megablokLockerNumber" integer NOT NULL,
    size text NOT NULL
);


ALTER TABLE public."Locker" OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 2148867)
-- Name: LockerEvent; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LockerEvent" (
    id text NOT NULL,
    type text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "lockerId" text NOT NULL,
    "userId" text,
    "pickupPointEventId" text,
    "depositId" text
);


ALTER TABLE public."LockerEvent" OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 2148873)
-- Name: MailAttachment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."MailAttachment" (
    id text NOT NULL,
    name text NOT NULL,
    type text NOT NULL,
    "fileHash" text NOT NULL,
    url text NOT NULL,
    "mailEventId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "deletedAt" timestamp(3) without time zone,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    category text DEFAULT 'unset'::text NOT NULL,
    "rejectedAt" timestamp(3) without time zone,
    "s3Key" text
);


ALTER TABLE public."MailAttachment" OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 2148880)
-- Name: MailEvent; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."MailEvent" (
    id text NOT NULL,
    event text NOT NULL,
    ts integer NOT NULL,
    subject text NOT NULL,
    from_email text NOT NULL,
    to_email text[],
    body_html text,
    body_raw text,
    body_text text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "deletedAt" timestamp(3) without time zone,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


ALTER TABLE public."MailEvent" OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 2148886)
-- Name: ManageReturn; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ManageReturn" (
    id text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."ManageReturn" OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 2148891)
-- Name: Message; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Message" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    content text NOT NULL,
    "sentById" text,
    "orderItemId" text,
    "orderId" text,
    "incidentId" text,
    attachments text[]
);


ALTER TABLE public."Message" OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 2148897)
-- Name: Order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Order" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "pickupFirstName" text,
    "pickupLastName" text,
    "pickupPhoneNumber" text,
    "pickupPointId" text,
    "userId" text NOT NULL,
    po integer NOT NULL,
    "orderStatusId" text NOT NULL,
    "rapidandFee" integer,
    "customerInvoiceBillomatId" text,
    igi integer,
    "totalPrice" integer,
    "platformPrice" integer,
    "rapidandShipping" integer,
    "billingFirstName" text,
    "billingLastName" text,
    "billingCompanyName" text,
    "billingNif" text,
    "billingAddressLine1" text,
    "billingAddressLine2" text,
    "billingPhoneNumber" text,
    "isHomeDelivery" boolean DEFAULT false NOT NULL,
    "deliveryFirstName" text,
    "deliveryLastName" text,
    "deliveryAddressLine1" text,
    "deliveryAddressLine2" text,
    "deliveryPhoneNumber" text,
    "paymentCardId" text,
    "redsysTransactionId" text,
    "redsysErrorCode" text,
    "redsysResponse" text,
    "redsysResponseMessage" text,
    "redsysTransactionDate" text,
    "redsysTransactionHour" text,
    "redsysTransactionTimestamp" timestamp(3) without time zone,
    "billingAddressCountry" text,
    "billingAddressCity" text,
    "billingAddressProvince" text,
    "platformShipping" integer,
    "quotedAt" timestamp(3) without time zone,
    "paidAt" timestamp(3) without time zone,
    "processedAt" timestamp(3) without time zone,
    "platformOrderId" text,
    paylink text,
    comments text,
    "deliveryParroquiaName" text,
    "billingAddressParroquiaName" text,
    "platformId" text,
    "poAlphabetic" text,
    "billingAddressTown" text,
    "deliveryTown" text,
    "assigneeId" text,
    "validatedAt" timestamp(3) without time zone,
    "smallOrderFee" integer,
    "isPrime" boolean,
    "cancelledAt" timestamp(3) without time zone,
    "paymentFailedAt" timestamp(3) without time zone,
    "pendingValidationAt" timestamp(3) without time zone,
    "isBuying" boolean,
    "totalReturnSurcharge" integer,
    "customerEditedAt" timestamp(3) without time zone,
    "cancelledById" text,
    "maxDeliveryDate" timestamp(3) without time zone,
    "maxPrice" integer,
    "totalSupplierReturnSurcharge" integer,
    "amazonDirectOrderingSubmittedAt" timestamp(3) without time zone,
    "amazonDirectOrderingCommentsContent" text,
    "amazonDirectOrderingCommentsType" text,
    "amazonDirectOrderingConfirmId" text,
    "amazonDirectOrderingNoticeDate" timestamp(3) without time zone,
    "amazonDirectOrderingShipping" integer,
    "amazonDirectOrderingTax" integer,
    "amazonDirectOrderingTotal" integer,
    "outstandingPrice" integer,
    "markedPaidById" text,
    "assemblyStatus" text,
    "assemblyPrice" integer,
    "bankTransferReceipt" text,
    "paidByBankTransferAt" timestamp(3) without time zone,
    "amazonDirectOrderingHistory" jsonb[]
);


ALTER TABLE public."Order" OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 2148904)
-- Name: OrderItem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."OrderItem" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    "orderId" text NOT NULL,
    "orderItemStatusId" text NOT NULL,
    "platformOrderId" text,
    "hsCode" text,
    "exportInvoiceBillomatId" text,
    "vendorInvoiceReportId" text,
    "rejectReasonId" text,
    "quantityWanted" integer,
    comments text,
    "platformTrackingNumber" text,
    "parcelId" text,
    "invoiceClaimedAt" timestamp(3) without time zone,
    "receivedAt" timestamp(3) without time zone,
    "exportInvoiceId" text,
    "splitFromId" text,
    "deliveredAt" timestamp(3) without time zone,
    "deliveredById" text,
    "cancelledAt" timestamp(3) without time zone,
    "processedAt" timestamp(3) without time zone,
    "quotedAt" timestamp(3) without time zone,
    "rejectedAt" timestamp(3) without time zone,
    "amountToReturn" integer,
    "returnComment" text,
    "returnInitiatedAt" timestamp(3) without time zone,
    "returnLabelUrl" text,
    "returnMethodId" text,
    "returnPhotos" text[],
    "returnReasonId" text,
    "returnRejectedAt" timestamp(3) without time zone,
    "returnRequestedAt" timestamp(3) without time zone,
    "returnRequestedByAdminOrCustomer" text,
    "returnSurcharge" integer,
    "returnedAt" timestamp(3) without time zone,
    "cancelledById" text,
    "isIndispensable" boolean,
    "replacementOfId" text,
    "inTransitAt" timestamp(3) without time zone,
    "readyForPickupAt" timestamp(3) without time zone,
    "previousReturnStatus" text,
    "returnRequestedById" text,
    "isReturnPhotosRequired" boolean,
    "returnCancelledAt" timestamp(3) without time zone,
    "isProviderResponse" boolean,
    "isRapidandToCorreos" boolean,
    "correosListId" text,
    "exportBackInvoiceId" text,
    "exportPrice" integer,
    "isExportToSpain" boolean,
    "isExportToSpainAt" timestamp(3) without time zone,
    "isRapidandToCorreosAt" timestamp(3) without time zone,
    "manageReturnId" text,
    "platformShippingRefund" integer,
    "rapidandShippingRefund" integer,
    "returnExportedAt" timestamp(3) without time zone,
    "smallOrderFeeRefund" integer,
    "supplierReturnSurcharge" integer,
    "correosMaxDate" timestamp(3) without time zone,
    "correosReceipt" text[],
    "amazonDirectOrderingCarrier" text,
    "amazonDirectOrderingLineNumber" integer,
    "amazonDirectOrderingShipmentId" text,
    "amazonDirectOrderingShipmentIdentifier" text,
    "amazonDirectOrderingDeliveryDate" timestamp(3) without time zone,
    "amazonDirectOrderingShipNoticeDate" timestamp(3) without time zone,
    "amazonDirectOrderingShipmentDate" timestamp(3) without time zone,
    "amazonDirectOrderingShipmentType" text,
    "returnRejectFile" text,
    "readyForPickupById" text,
    "warehouseById" text,
    "exportLabelUrl" text,
    "estimatedDeliveryDateEnd" timestamp(3) without time zone,
    "estimatedDeliveryDateStart" timestamp(3) without time zone,
    "packageHeight" text,
    "packageLength" text,
    "packageWeight" text,
    "packageWidth" text,
    "returnQR" text,
    "returnProcessedAt" timestamp(3) without time zone,
    "returnPickedupAt" timestamp(3) without time zone,
    "returnDeliveredCorreosClientAt" timestamp(3) without time zone,
    "returnPendingCorreosAt" timestamp(3) without time zone,
    "returnPendingDeliveryAt" timestamp(3) without time zone,
    "returnPendingPickupAt" timestamp(3) without time zone,
    "blacklistedCategoriesIds" text[],
    "blacklistedCategoriesNames" text[],
    "blacklistedKeywords" text[],
    "businessMerchantName" text,
    "businessOfferId" text,
    "businessPrice" integer,
    "businessShippingPrice" integer,
    "categoriesIds" text[],
    "categoriesNames" text[],
    color text,
    "deliveryInformation" text,
    description text,
    dimensions text,
    "exportTitle" text,
    features text[],
    "fetchedAt" timestamp(3) without time zone,
    images text[],
    "isAvailable" boolean,
    "isBlacklisted" boolean,
    "isOfferSelectionRequired" boolean,
    "isPrime" boolean,
    "isSecondHand" boolean,
    "maxQuantity" integer,
    "minQuantity" integer,
    "offerListingId" text,
    price integer,
    "priceSlashed" integer,
    "productId" text NOT NULL,
    "sellerId" text,
    "sellerName" text,
    "shippingPrice" integer,
    title text,
    "variationsItems" jsonb[],
    "variationsSummary" jsonb,
    weight text,
    "ikeaParts" jsonb[],
    "replacementRequested" boolean,
    "earlyExportBackRefund" boolean,
    "suggestedHsCode" text,
    "autofilledHsCode" text
);


ALTER TABLE public."OrderItem" OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 2148911)
-- Name: OrderItemStatus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."OrderItemStatus" (
    id text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."OrderItemStatus" OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 2148916)
-- Name: OrderItemsOnInvoices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."OrderItemsOnInvoices" (
    "orderItemId" text NOT NULL,
    "invoiceId" text NOT NULL,
    "assignedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    quantity integer NOT NULL
);


ALTER TABLE public."OrderItemsOnInvoices" OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 2148922)
-- Name: OrderStatus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."OrderStatus" (
    id text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."OrderStatus" OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 2148927)
-- Name: Order_po_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Order_po_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Order_po_seq" OWNER TO postgres;

--
-- TOC entry 4283 (class 0 OID 0)
-- Dependencies: 240
-- Name: Order_po_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Order_po_seq" OWNED BY public."Order".po;


--
-- TOC entry 241 (class 1259 OID 2148928)
-- Name: Parcel; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Parcel" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    parts integer DEFAULT 1 NOT NULL,
    "needsAppointment" boolean DEFAULT false NOT NULL,
    "doorParts" integer DEFAULT 0 NOT NULL,
    "largeLetterParts" integer DEFAULT 0 NOT NULL,
    "pictureParts" integer DEFAULT 0 NOT NULL,
    "smallBoxParts" integer DEFAULT 0 NOT NULL,
    "trackingNumber" text NOT NULL,
    "trackingLabelUrl" text,
    "largeBoxParts" integer DEFAULT 0 NOT NULL,
    "smallLetterParts" integer DEFAULT 0 NOT NULL,
    "mediumBoxParts" integer DEFAULT 0 NOT NULL,
    "originalTrackingNumber" text
);


ALTER TABLE public."Parcel" OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 2148943)
-- Name: ParcelContainer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ParcelContainer" (
    id text NOT NULL,
    name text NOT NULL,
    "routeCode" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "deletedAt" timestamp(3) without time zone,
    "pickupPointId" text
);


ALTER TABLE public."ParcelContainer" OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 2148949)
-- Name: ParcelLocationEvent; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ParcelLocationEvent" (
    id text NOT NULL,
    type text NOT NULL,
    lat double precision,
    long double precision,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "nextEventId" text,
    "containerId" text,
    "parcelId" text NOT NULL,
    "createdById" text NOT NULL,
    "withoutScan" boolean DEFAULT false NOT NULL
);


ALTER TABLE public."ParcelLocationEvent" OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 2148956)
-- Name: PaymentCard; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PaymentCard" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "deletedAt" timestamp(3) without time zone,
    "userId" text,
    "expiryMonth" text,
    "expiryYear" text,
    "expiryDate" text,
    "redsysIdentifier" text NOT NULL,
    country text,
    brand text,
    number text,
    "redsysCofTxnId" text,
    name text
);


ALTER TABLE public."PaymentCard" OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 2148962)
-- Name: PaymentTransaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PaymentTransaction" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "redsysOrder" text,
    "redsysDate" text,
    "redsysHour" text,
    "redsysResponse" text,
    "redsysAmount" text,
    "redsysCurrency" text,
    "redsysSecurePayment" text,
    "redsysMerchantIdentifier" text,
    "redsysMerchantCode" text,
    "redsysTerminal" text,
    "redsysTransactionType" text,
    "redsysCardCountry" text,
    "redsysCardBrand" text,
    "redsysExpiryDate" text,
    "redsysConsumerLanguage" text,
    "redsysAuthorisationCode" text,
    "redsysMerchantCofTxnId" text,
    "redsysProcessedPayMethod" text,
    "redsysMerchantData" jsonb,
    "orderId" text,
    "paymentCardId" text,
    "invoiceId" text,
    "primeUserId" text,
    "transactionType" text,
    "redsysErrorCode" text,
    amount integer
);


ALTER TABLE public."PaymentTransaction" OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 2148968)
-- Name: PickupPoint; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PickupPoint" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "deletedAt" timestamp(3) without time zone,
    name text NOT NULL,
    "addressId" text NOT NULL,
    "openingHours" text,
    enabled boolean DEFAULT true,
    "shortName" text,
    "pickupFee" integer,
    "megablokInstallationId" integer
);


ALTER TABLE public."PickupPoint" OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 2148975)
-- Name: PickupPointEvent; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PickupPointEvent" (
    id text NOT NULL,
    type text NOT NULL,
    data text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "pickupPointId" text NOT NULL,
    "userId" text
);


ALTER TABLE public."PickupPointEvent" OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 2148981)
-- Name: Platform; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Platform" (
    id text NOT NULL,
    name text NOT NULL,
    awinmid text,
    "discountAmount" double precision,
    "discountType" text
);


ALTER TABLE public."Platform" OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 2148986)
-- Name: Product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Product" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    ean text NOT NULL,
    asin text,
    "platformId" text NOT NULL,
    "platformSellerId" text DEFAULT 'default'::text NOT NULL,
    url text,
    ref text
);


ALTER TABLE public."Product" OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 2148993)
-- Name: ProductSnapshot; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ProductSnapshot" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    title text,
    "sellerName" text,
    images text[],
    description text,
    features text[],
    price integer,
    "isAvailable" boolean,
    "isPrime" boolean,
    "shippingPrice" integer,
    "userId" text,
    "snapshotReasonId" text NOT NULL,
    "productId" text NOT NULL,
    "categoriesNames" text[],
    "categoriesIds" text[],
    color text,
    "isBlacklisted" boolean,
    "blacklistedKeywords" text[],
    weight text,
    dimensions text,
    "sellerId" text,
    "blacklistedCategoriesNames" text[],
    "blacklistedCategoriesIds" text[],
    "offerListingId" text,
    "maxQuantity" integer,
    "isOfferSelectionRequired" boolean,
    "exportTitle" text,
    "isSecondHand" boolean,
    "variationsItems" jsonb[],
    "variationsSummary" jsonb,
    "priceSlashed" integer,
    "deliveryInformation" text,
    "minQuantity" integer,
    "businessOfferId" text,
    "businessPrice" integer,
    "businessShippingPrice" integer,
    "businessMerchantName" text
);


ALTER TABLE public."ProductSnapshot" OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 2148999)
-- Name: ProductSnapshotLog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ProductSnapshotLog" (
    id text NOT NULL,
    retried integer DEFAULT 0 NOT NULL,
    version text NOT NULL,
    reason text NOT NULL,
    asin text,
    smid text,
    "userId" text,
    "elapsedSinceLastSnapshot" integer,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."ProductSnapshotLog" OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 2149006)
-- Name: ProductSnapshotReason; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ProductSnapshotReason" (
    id text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."ProductSnapshotReason" OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 2149011)
-- Name: RejectReason; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."RejectReason" (
    id text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."RejectReason" OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 2149016)
-- Name: ReturnMethod; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ReturnMethod" (
    id text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."ReturnMethod" OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 2149021)
-- Name: ReturnReason; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ReturnReason" (
    id text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."ReturnReason" OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 2149026)
-- Name: User; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."User" (
    id text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "deletedAt" timestamp(3) without time zone,
    email text NOT NULL,
    "firstName" text NOT NULL,
    "lastName" text NOT NULL,
    password text NOT NULL,
    "isVerified" boolean DEFAULT false NOT NULL,
    "verificationToken" text,
    "passwordResetToken" text,
    "defaultPickupFirstName" text,
    "defaultPickupLastName" text,
    "defaultPickupPhoneNumber" text,
    "defaultPickupPointId" text,
    "defaultBillingAddressId" text,
    "defaultPaymentCardId" text,
    language text,
    "defaultIsHomeDelivery" boolean DEFAULT false NOT NULL,
    "defaultDeliveryAddressId" text,
    "isPrimeSubscriptionActive" boolean DEFAULT false,
    "primeActiveUntil" timestamp(3) without time zone,
    "primeBillingAddressId" text,
    "primeBillingCycle" text,
    "primePaymentCardId" text,
    "worksAtPickupPointId" text
);


ALTER TABLE public."User" OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 2149035)
-- Name: UserRole; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."UserRole" (
    id text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."UserRole" OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 2149040)
-- Name: Vendor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Vendor" (
    id text NOT NULL,
    name text NOT NULL,
    nif text NOT NULL
);


ALTER TABLE public."Vendor" OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 2149045)
-- Name: _CashFlowToInvoice; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."_CashFlowToInvoice" (
    "A" text NOT NULL,
    "B" text NOT NULL
);


ALTER TABLE public."_CashFlowToInvoice" OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 2149050)
-- Name: _DepositToLocker; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."_DepositToLocker" (
    "A" text NOT NULL,
    "B" text NOT NULL
);


ALTER TABLE public."_DepositToLocker" OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 2149055)
-- Name: _DepositToParcel; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."_DepositToParcel" (
    "A" text NOT NULL,
    "B" text NOT NULL
);


ALTER TABLE public."_DepositToParcel" OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 2149060)
-- Name: _IncidentToOrderItem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."_IncidentToOrderItem" (
    "A" text NOT NULL,
    "B" text NOT NULL
);


ALTER TABLE public."_IncidentToOrderItem" OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 2149065)
-- Name: _UserToUserRole; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."_UserToUserRole" (
    "A" text NOT NULL,
    "B" text NOT NULL
);


ALTER TABLE public."_UserToUserRole" OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 2149070)
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public._prisma_migrations OWNER TO postgres;

--
-- TOC entry 3819 (class 2604 OID 2149077)
-- Name: Order po; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order" ALTER COLUMN po SET DEFAULT nextval('public."Order_po_seq"'::regclass);


--
-- TOC entry 4223 (class 0 OID 2148775)
-- Dependencies: 215
-- Data for Name: Address; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4224 (class 0 OID 2148781)
-- Dependencies: 216
-- Data for Name: CartItem; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."CartItem" VALUES ('cd97b44f-2266-5cd9-932d-49393bd12464', '2022-09-29 15:06:53.141', '2020-07-03 06:27:29', '2008-09-05 20:18:20', '1982-11-27 10:28:02', 6774, '5185357c-a790-5fc2-8e81-1e3bf79f63d6', '01332422-a7de-5489-9332-57dd77d397d5', 'Vikorako', '{"Soako misoviko"}', '{"Mira koaso"}', '{"Viayu raso"}', 'Koviyu visorayu soyu', 'Yuko yuayuvi soyukomi', 17039, 32614, '{"Viavi visora mira"}', '{"Viraviyu viso"}', 'Miyumiko', 'Rasomira ramiyu miyu', 'Soa', 'Vira kovirayu', 'Somi mirayu yuako', '{"Visora koviami kovi"}', '1992-01-05 12:22:34', '{"Miko miayu"}', false, false, false, false, false, 21605, 2411, 'Soa yuayua virakomi', 34421, 39356, 'Koasomi rayu', 'Yuso yusorayu', 12318, 'Rico Labadie', '{}', '{"Viko": "Viaviyu sovikovi ravi"}', 'Viko');
INSERT INTO public."CartItem" VALUES ('943b13c7-9a46-5bbf-a587-826c16b42d37', '2022-09-29 15:06:53.141', '2020-08-28 07:56:30', '1982-03-11 02:04:58', '1989-10-22 09:24:17', 20788, '7aea35aa-5a77-5acf-8161-2fe91b29d3a2', '0ffedd83-34d2-5de4-a8cc-f06304a9f7ec', 'Korakoyu', '{"Yuso rasomiso yuviyu"}', '{"Miyu misoako viyurayu"}', '{"Koavi mirakoa"}', 'Yuso mirasoa', 'Sovirayu komi', 38954, 21384, '{"Yumira miyuviso"}', '{"Koyu korayu"}', 'Yuaso', 'Soamiko rako rayura', 'Miyumi', 'Rako yuako soyuso', 'Rasoyu sorasomi koa', '{"Miako koyuvi ramiako"}', '1990-11-03 10:26:01', '{"Koviravi komiko koraviso"}', false, false, false, false, false, 52102, 27892, 'Vira kovirayu rako', 48032, 64916, 'Viamiko sorako', 'Sovi miyurako', 59967, 'Chanel Renner', '{}', '{"Soyu": "Rasomi yukoa"}', 'Ramiayu');
INSERT INTO public."CartItem" VALUES ('ee71560a-2538-5748-9da0-576ef4bfd461', '2022-09-29 15:06:53.141', '2020-06-26 05:26:45', '2016-01-09 12:36:57', '2001-10-06 21:31:49', 48829, '5444f259-27c2-5313-bf11-7237b395a1c7', '5a06c0f9-863e-5d11-9be9-c5319750dfde', 'Soasora', '{"Yuavi raviyuvi soraso"}', '{"Yumiko viko"}', '{"Yuso rasoa"}', 'Komi koviyu mia', 'Komira koa', 4792, 6606, '{"Yusoako kora somiyu"}', '{"Yumiso miyuvia"}', 'Viyu', 'Virako yuso', 'Yumiso', 'Koyuayu raso', 'Misomia korami ravi', '{"Rakoayu koyumi koayu"}', '2004-05-05 16:11:46', '{"Via koviyu"}', false, false, false, false, false, 10619, 31629, 'Raviso somi', 44967, 45223, 'Viaso koramiko', 'Korayua rayukovi', 8666, 'Aaron Swaniawski', '{}', '{"Kovisovi": "Soyukovi sovira rasoa"}', 'Komi');
INSERT INTO public."CartItem" VALUES ('59f81f53-9a3e-5b5f-867c-04657b1b886c', '2022-09-29 15:06:53.141', '2020-12-20 23:49:12', '2011-04-08 15:54:23', '2001-06-26 05:55:11', 40097, '4348530a-32bd-511d-95d3-bcb54f401b9f', 'ebe23927-b75b-511e-8a6b-827d564bfa74', 'Mikomira', '{"Yuviako visomi soviami"}', '{"Sovi miayu koviyuso"}', '{"Koyu komiyu somiyua"}', 'Rayu mia', 'Miko sovira soravia', 26438, 31964, '{"Miakovi visomiko yuvi"}', '{"Raviyu via korakomi"}', 'Soyusoa', 'Sorako koyu korayu', 'Yumisoyu', 'Yua sora', 'Komira miyukora yuvia', '{"Yukora yuso viyuso"}', '2001-06-18 05:47:07', '{"Visoravi ramiako koyuvira"}', false, false, false, false, false, 4130, 63926, 'Miraviso soyuaso', 25702, 30227, 'Rayua koyumi yuso', 'Koviyu kora', 617, 'Scot Mueller', '{}', '{"Ravia": "Rayusoyu virako"}', 'Viyumira');
INSERT INTO public."CartItem" VALUES ('49484621-de12-502d-9ec5-5520117fe6b9', '2022-09-29 15:06:53.141', '2020-07-03 18:18:24', '1982-03-07 02:04:40', '1993-02-22 13:21:03', 53469, '73d964ac-98dd-523e-b9de-b4ca4c879ed2', 'a338a623-365c-5773-9f38-13e2c35c138c', 'Viakovi', '{"Koyu miyuviso vikoa"}', '{"Yumiso visoa sora"}', '{"Koyumia koa"}', 'Komiyu misoviyu', 'Visoyura viyuko', 12005, 48055, '{"Vikomi via"}', '{"Yumiyuso yurako yuso"}', 'Yura', 'Rakoa soviyumi kora', 'Raviso', 'Koaviso sorayu', 'Ravi miami', '{"Soviko rami yumiami"}', '2017-06-06 05:19:32', '{"Yumi rayura"}', false, false, false, false, false, 39000, 62384, 'Sora korayuvi yuso', 62599, 57017, 'Koviyu yusomiso rako', 'Somi koramia rasoyura', 26624, 'Eliseo Gibson', '{}', '{"Miyusovi": "Virasomi mira yuayuvi"}', 'Komisoyu');
INSERT INTO public."CartItem" VALUES ('8f148a12-4110-5dc6-8fc3-bcd7abc545e2', '2022-09-29 15:06:53.141', '2020-02-10 01:23:04', '2005-06-14 17:13:51', '2008-09-17 20:13:52', 6790, 'bbb936a3-337d-5c4b-b7d3-c0af0978209a', 'c24182ee-91e9-5eb1-99a5-b9cc92ef38ad', 'Mikovia', '{"Rasoyuko kora"}', '{"Yurayua misoa koviso"}', '{"Yurayumi soa"}', 'Korasoa yumiso yuami', 'Yukoyua soyu miyuvi', 19178, 17340, '{"Soviyu soyu"}', '{"Mikoayu yua"}', 'Miyuviko', 'Yukoyuvi viyu', 'Yukomiyu', 'Mirasoyu rako', 'Koa yukora mikomiko', '{"Ravia rako"}', '2014-07-23 19:07:47', '{"Koraso miami koyuvi"}', false, false, false, false, false, 53822, 57108, 'Somiyuvi mirami', 5270, 37482, 'Somiko koamiko kovikomi', 'Ravi mikomiko', 51794, 'Maurine Sipes', '{}', '{"Ravi": "Viamiso rami"}', 'Mia');
INSERT INTO public."CartItem" VALUES ('b83630e5-3cd2-5022-8021-dfb100bdbe15', '2022-09-29 15:06:53.141', '2020-10-06 21:14:27', '1992-05-21 05:04:56', '1980-09-21 08:21:23', 46928, '65e024a7-66e9-5650-bdff-7d2f9838b76a', '899d114b-edd8-5d58-bac6-923e65a6b399', 'Komiso', '{"Mia yuvisomi"}', '{"Yuviyu raviyua"}', '{"Koviyu miyu viraso"}', 'Korayu yuayu', 'Viyumiko rami somiyua', 13200, 36173, '{"Yukoayu yuso"}', '{"Raviko mira rayumiso"}', 'Komi', 'Ravira koyu', 'Vikora', 'Viso via sorayu', 'Vikoviyu ravi', '{"Mikora yuvi rakomi"}', '2012-01-05 00:15:27', '{"Yukoyuvi miyu"}', false, false, false, false, false, 40731, 35276, 'Kora yuayu', 33615, 6252, 'Rasora kora viyuayu', 'Ramirayu yuasora kovi', 41601, 'Donna Christiansen', '{}', '{"Miyuso": "Ramiko miyu ramiko"}', 'Mikovia');
INSERT INTO public."CartItem" VALUES ('2fa7970d-6beb-5568-a7ac-ae65aa11a2fc', '2022-09-29 15:06:53.141', '2020-12-24 23:57:11', '1994-11-27 22:41:33', '2005-02-06 01:31:37', 13719, 'f66355af-0ba5-5130-a19e-9b3fb66b7971', '87bfa391-6900-54e5-84d9-a103ab39d112', 'Yuvira', '{"Misoviso rakora"}', '{"Koyu koa yusoaso"}', '{"Yumi mikomi rayuvia"}', 'Miyusomi soakovi sovi', 'Soako soyusomi soyumia', 14140, 62058, '{"Ravisoyu yuramia"}', '{"Vira misoviko"}', 'Miasoa', 'Miravi viyua rasoyu', 'Ramiso', 'Rayu yumiso', 'Yumi koaso', '{"Miramira yua koviyuso"}', '1995-12-04 23:51:02', '{"Yuvi raviaso"}', false, false, false, false, false, 50296, 40135, 'Viraso koyuviyu koyuko', 20231, 6572, 'Yuasomi yuvi yusoyu', 'Kora somiso', 8742, 'Jodie Welch', '{}', '{"Sovia": "Korayu miyua yusomi"}', 'Koa');
INSERT INTO public."CartItem" VALUES ('8c014807-50a1-5833-8e80-a2cb971fda82', '2022-09-29 15:06:53.141', '2020-09-17 08:59:39', '1992-09-25 20:39:10', '1998-07-27 18:30:34', 30046, 'e5941561-c4b9-5933-89cf-48fb7d6d2e60', '907b8d2b-f42a-56d0-a988-50905ed6028e', 'Mirayu', '{"Soa rakoyu rami"}', '{"Rasomiko yuravi"}', '{"Soa korami rayua"}', 'Somikoyu komi', 'Yumiyuko kora', 56981, 25171, '{"Miyura yurakora virami"}', '{"Korasoa ravi miyuko"}', 'Viyumiko', 'Yurayuvi sora', 'Komiaso', 'Korako yuso', 'Yuayura soyusomi', '{"Miko yusoyuko"}', '1980-01-21 00:13:03', '{"Viami yukovi"}', false, false, false, false, false, 18101, 62956, 'Viso koa yuvi', 658, 39538, 'Viko miamia miaso', 'Koyu viayu', 41755, 'Israel Kuhic', '{}', '{"Soyuvi": "Yura sovira"}', 'Sora');
INSERT INTO public."CartItem" VALUES ('34c23823-a429-515d-85f3-1a6f89265b52', '2022-09-29 15:06:53.141', '2020-02-22 01:29:13', '2013-06-22 18:07:14', '1987-12-28 23:48:58', 21972, 'bcca18c3-5e46-56cb-b58b-c74cf16609b1', '4db578b9-d017-51b8-8d62-eea88d6dae3c', 'Miavi', '{"Miko soaso"}', '{"Yuko virayu"}', '{"Sovi miyusovi"}', 'Mirayura miasoa komi', 'Miasoa ravirayu', 24081, 4258, '{"Yumira viako visora"}', '{"Viso raviako"}', 'Soakora', 'Sorakoyu soasoyu sovia', 'Rasoyu', 'Rasomira komia korasora', 'Viyu sovia', '{"Sora koayu miso"}', '2015-04-28 03:25:36', '{"Somiayu ravi"}', false, false, false, false, false, 9650, 54966, 'Miami miso', 63371, 35479, 'Kovikoyu via viso', 'Komiravi viso koviko', 30730, 'Alan Zboncak', '{}', '{"Raviyu": "Vikomiso korako"}', 'Visoviyu');
INSERT INTO public."CartItem" VALUES ('06355d15-24b4-52f4-adc4-60a6f8d93f2a', '2022-09-29 15:06:53.141', '2020-01-25 12:24:39', '2012-01-25 00:21:58', '1993-10-14 21:46:45', 40597, '5185357c-a790-5fc2-8e81-1e3bf79f63d6', '01332422-a7de-5489-9332-57dd77d397d5', 'Yuvira', '{"Miamira koviyu"}', '{"Ravi kovisomi miayu"}', '{"Komi somirako"}', 'Vikorako miko', 'Yura miamiko sorakora', 9857, 40588, '{"Via korasora kora"}', '{"Mikovi ravi"}', 'Kovisomi', 'Rasovi koyumira', 'Soyu', 'Yurakovi mikomi viko', 'Kora mikovi rako', '{"Ramiko miravia rakora"}', '2016-09-13 21:05:11', '{"Sorayuko kovi mia"}', false, false, false, false, false, 16749, 28695, 'Kora vikomi soyu', 7045, 52030, 'Misovi ravi', 'Vira rasomiyu', 26822, 'Jaqueline Bosco', '{}', '{"Yuvira": "Viako vikomiko"}', 'Visoa');
INSERT INTO public."CartItem" VALUES ('48ffcb47-b5da-5953-a853-701462bac2b9', '2022-09-29 15:06:53.141', '2020-09-01 20:20:42', '1986-07-11 06:19:21', '1986-11-27 22:48:11', 55823, '5444f259-27c2-5313-bf11-7237b395a1c7', '5a06c0f9-863e-5d11-9be9-c5319750dfde', 'Viyu', '{"Koyu raviyuvi"}', '{"Koamira yuvi soako"}', '{"Vira raviyumi"}', 'Mikomia visomi', 'Koakovi yuviyura sovi', 50289, 55267, '{"Rasoyuvi yuso yumiyu"}', '{"Yusorayu viko yua"}', 'Kovirayu', 'Ramirayu yuravi somia', 'Rakoyumi', 'Sovi visoyuko', 'Koyumira viako yuvi', '{"Somi misoami koamia"}', '2014-11-11 10:44:19', '{"Visoyuko yukoami miko"}', false, false, false, false, false, 3455, 23666, 'Viyura yura ramia', 26569, 34848, 'Rasoyuko miami miyuko', 'Soa miakora', 1133, 'Cassandre Padberg', '{}', '{"Koa": "Ramiyuso yusora"}', 'Yurasoa');
INSERT INTO public."CartItem" VALUES ('9fa1a372-4e75-5c9f-9535-68164509d262', '2022-09-29 15:06:53.141', '2020-07-11 19:06:32', '1998-07-23 18:33:04', '2007-12-24 12:00:48', 15810, '7aea35aa-5a77-5acf-8161-2fe91b29d3a2', '0ffedd83-34d2-5de4-a8cc-f06304a9f7ec', 'Somiraso', '{"Sorasomi misoa"}', '{"Rakoviso rakomi viaso"}', '{"Rasoyu miayumi"}', 'Mia rayu', 'Yuraviso viaviso ramia', 49109, 440, '{"Miraviko visoyu"}', '{"Yuayuko ramisovi yusoa"}', 'Miko', 'Yuviyu soasovi kovia', 'Vira', 'Raviso yuvi', 'Rami soasoa yuvi', '{"Sora misomi mira"}', '2011-12-24 23:18:16', '{"Viko sorami mikoa"}', false, false, false, false, false, 2427, 55397, 'Yusoa soavia', 30040, 57031, 'Rakoami kovia', 'Raviami raviyuso', 42436, 'Lesly Tromp', '{}', '{"Via": "Somiyuvi koraso"}', 'Yumikoyu');
INSERT INTO public."CartItem" VALUES ('93681c05-3466-5fc6-9756-a3d5d9b6c423', '2022-09-29 15:06:53.141', '2020-02-18 01:44:38', '2019-04-08 15:40:24', '1992-05-21 05:06:13', 61739, 'f66355af-0ba5-5130-a19e-9b3fb66b7971', '87bfa391-6900-54e5-84d9-a103ab39d112', 'Sorakoa', '{"Yuvi ramiyura yuravi"}', '{"Komi koravi rayu"}', '{"Yuvisora komiko"}', 'Sovisoa mira sorasomi', 'Rako miaso', 27982, 50077, '{"Kovia miso yusoavi"}', '{"Komi miyumia"}', 'Vira', 'Somi viraso', 'Viyuso', 'Raso yurako koasoyu', 'Virayuko soa', '{"Miso koramira"}', '2014-07-03 19:10:15', '{"Yuviyuvi misoami misora"}', false, false, false, false, false, 52689, 48019, 'Viyuviso miravi mira', 24410, 5763, 'Sora koviavi', 'Rasoaso rako soasomi', 54852, 'Cathrine Barton', '{}', '{"Raviyuko": "Yuayu miyu mirayumi"}', 'Koyurako');
INSERT INTO public."CartItem" VALUES ('ada47c3a-6893-57a6-aa7e-676542210e1a', '2022-09-29 15:06:53.141', '2020-08-08 08:06:05', '2005-02-18 01:30:25', '2010-11-07 22:15:28', 64068, 'bcca18c3-5e46-56cb-b58b-c74cf16609b1', '4db578b9-d017-51b8-8d62-eea88d6dae3c', 'Yurakovi', '{"Sora somiso yumi"}', '{"Miavi rami koyuko"}', '{"Soyu soyuaso"}', 'Via koasoa', 'Yukovia visoyuko', 50590, 52090, '{"Virayura sovi soraso"}', '{"Rako koa"}', 'Rami', 'Sora korako', 'Sorayumi', 'Mirako mira', 'Virami rayurako miko', '{"Rako sovisoyu"}', '1983-04-04 03:19:37', '{"Vira soayura"}', false, false, false, false, false, 61, 62071, 'Yua somi koakora', 39863, 29135, 'Sovia soakoyu koyuvi', 'Yumiko soasora yumi', 1938, 'Misty Jenkins', '{}', '{"Komia": "Soyu viravi virakovi"}', 'Yua');
INSERT INTO public."CartItem" VALUES ('14d8521f-a696-58b3-9add-f46fed01cb3c', '2022-09-29 15:06:53.141', '2020-06-14 05:54:10', '2009-06-18 05:35:35', '1984-01-09 12:39:32', 64569, '5185357c-a790-5fc2-8e81-1e3bf79f63d6', '01332422-a7de-5489-9332-57dd77d397d5', 'Yuvi', '{"Virami via ravikomi"}', '{"Yuvikoa somiyumi"}', '{"Yusoyua sorayu viayu"}', 'Mia mirako yukoami', 'Rayuaso yuvi', 20094, 47429, '{"Mikomi miyu koa"}', '{"Kora soyua"}', 'Ramiayu', 'Viko sorasoa soyuviyu', 'Ramisomi', 'Visomi vikoviyu yua', 'Miyumi viako mira', '{"Koyu soasomi yuayu"}', '1983-04-08 03:16:46', '{"Mira miyuko sovi"}', false, false, false, false, false, 51187, 36387, 'Miasora yura misoyu', 64282, 58194, 'Komira somiaso mira', 'Vikoyu mikoa rayu', 18208, 'Chadrick Hagenes', '{}', '{"Mikovi": "Miyu koa"}', 'Yuviami');
INSERT INTO public."CartItem" VALUES ('e789a517-669c-5132-82ed-97d05d71392a', '2022-09-29 15:06:53.141', '2020-06-26 05:56:28', '1981-06-02 17:44:17', '2011-08-16 07:37:12', 52215, 'f66355af-0ba5-5130-a19e-9b3fb66b7971', '87bfa391-6900-54e5-84d9-a103ab39d112', 'Rasoami', '{"Viko sovisomi miavi"}', '{"Miaviko koyurako rayu"}', '{"Komia yuvira"}', 'Miramiyu rasoa rayu', 'Miyu rayuso', 37731, 18267, '{"Koyu soako"}', '{"Virami ramirayu"}', 'Rakomia', 'Rakomiyu miakomi', 'Yuko', 'Sovi somiso', 'Sorayua viraso miayu', '{"Korayumi soyu"}', '2001-02-18 13:12:01', '{"Misoviso korako"}', false, false, false, false, false, 63114, 17116, 'Soa soyumi', 30326, 34751, 'Kora soyuso', 'Yumi yukoyu', 23659, 'Marshall O''Reilly', '{}', '{"Visoa": "Vira yumiavi"}', 'Viso');


--
-- TOC entry 4225 (class 0 OID 2148788)
-- Dependencies: 217
-- Data for Name: CashFlow; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4226 (class 0 OID 2148797)
-- Dependencies: 218
-- Data for Name: CorreosList; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."CorreosList" VALUES ('0da87bfe-6089-53c0-af62-109ddeed0e5e', '2022-09-29 15:06:52.922', '2020-02-14 01:07:59', '2002-11-03 22:37:54', 'Schmidt', '{"Miyu viamia yuvikomi"}', false);
INSERT INTO public."CorreosList" VALUES ('c36ae70f-c22e-5336-a3ef-4c059c434761', '2022-09-29 15:06:52.922', '2020-06-22 17:40:12', '2012-05-05 16:54:45', 'Armstrong', '{"Rayuvia mira"}', false);
INSERT INTO public."CorreosList" VALUES ('9d5fed50-615e-5704-920d-0f9a5a0dab35', '2022-09-29 15:06:52.922', '2020-05-05 04:08:09', '1985-02-02 13:25:22', 'Weissnat', '{"Koako mira"}', false);
INSERT INTO public."CorreosList" VALUES ('19dcd2c4-480d-56a6-8172-cc14cc0b8662', '2022-09-29 15:06:52.922', '2020-10-10 21:59:15', '2002-03-15 14:06:26', 'Schuppe', '{"Viyu yukoavi"}', false);
INSERT INTO public."CorreosList" VALUES ('29a7b608-f13c-5d92-ba66-bb129da3e1d8', '2022-09-29 15:06:52.922', '2020-04-20 03:42:43', '2001-10-22 21:30:55', 'Langworth', '{"Virami sovi yusoa"}', false);
INSERT INTO public."CorreosList" VALUES ('291fc254-ae7b-5fd8-8707-84b2934cabf6', '2022-09-29 15:06:52.922', '2020-12-21 00:04:06', '2013-02-10 01:16:18', 'Gutkowski', '{"Mia vikomi mia"}', false);
INSERT INTO public."CorreosList" VALUES ('eb6bebbc-18b0-581f-9228-75270dc42da1', '2022-09-29 15:06:52.922', '2020-12-16 11:38:52', '2014-11-03 10:48:16', 'Lemke', '{"Viako koa vira"}', false);
INSERT INTO public."CorreosList" VALUES ('23e2ed73-81b0-5c0c-a937-57b952c3a439', '2022-09-29 15:06:52.922', '2020-11-19 10:51:54', '1991-12-20 11:17:09', 'Parisian', '{"Yusora yumisovi"}', false);
INSERT INTO public."CorreosList" VALUES ('f6b9a035-b106-503f-9dbc-ff8cf4cc2dc5', '2022-09-29 15:06:52.922', '2020-04-28 04:07:19', '2015-12-12 11:38:34', 'Schaefer', '{"Raviyu sora"}', false);
INSERT INTO public."CorreosList" VALUES ('d54990a9-66b9-57d6-b5ce-7bdc28fa51d5', '2022-09-29 15:06:52.922', '2020-12-24 23:23:59', '2003-08-20 07:52:39', 'Kihn', '{"Rako visora mia"}', false);
INSERT INTO public."CorreosList" VALUES ('22055678-0f11-5eb7-a68d-53a1a83b1554', '2022-09-29 15:06:52.922', '2020-04-12 15:33:50', '1981-02-02 01:04:10', 'Windler', '{"Koa raviso raso"}', false);
INSERT INTO public."CorreosList" VALUES ('a638af97-3ebf-55c5-b1f6-d43e83fa70a6', '2022-09-29 15:06:52.922', '2020-09-01 20:36:26', '1989-10-14 09:20:04', 'Kreiger', '{"Yuvirayu komira"}', false);
INSERT INTO public."CorreosList" VALUES ('cda4ef76-b6fb-5bb6-a300-a0d7f11a3cdc', '2022-09-29 15:06:52.922', '2020-07-19 18:51:52', '1997-02-22 01:37:00', 'Collier', '{"Koyu via rasoyumi"}', false);
INSERT INTO public."CorreosList" VALUES ('d105ebfd-20fc-5ff1-851f-104ce48ed863', '2022-09-29 15:06:52.922', '2020-04-16 15:17:15', '1982-11-19 10:28:29', 'O''Connell', '{"Koyumi yumisoa sora"}', false);
INSERT INTO public."CorreosList" VALUES ('aba231f8-900a-50e0-b0c5-afa9488878a4', '2022-09-29 15:06:52.922', '2020-05-01 04:20:47', '2017-10-10 21:58:19', 'Hoppe', '{"Kovikora komi"}', false);
INSERT INTO public."CorreosList" VALUES ('fd23355c-44a0-5bae-939b-f810b8fbbdeb', '2022-09-29 15:06:52.922', '2020-07-07 06:43:58', '1989-02-14 01:55:45', 'Bayer', '{"Viyu mikora"}', false);
INSERT INTO public."CorreosList" VALUES ('a4c4ebef-00d9-51c6-a2b7-c999d6118100', '2022-09-29 15:06:52.922', '2020-09-13 20:46:32', '1994-11-27 22:49:15', 'Walker', '{"Mirami viramiso rami"}', false);
INSERT INTO public."CorreosList" VALUES ('42ba60c8-0b81-5e86-ba2b-cdf82086ea74', '2022-09-29 15:06:52.922', '2020-02-18 01:17:36', '2011-08-04 07:37:28', 'Willms', '{"Viyuvira korasoa"}', false);
INSERT INTO public."CorreosList" VALUES ('3f4fff25-97ad-5497-9125-635fa831288c', '2022-09-29 15:06:52.922', '2020-06-26 05:55:24', '1997-10-18 10:04:31', 'Jaskolski', '{"Ramiyuko komi rakora"}', false);
INSERT INTO public."CorreosList" VALUES ('0a554158-8941-5c0f-8e8a-65b3d8492a73', '2022-09-29 15:06:52.922', '2020-09-09 08:32:23', '1983-12-24 11:23:44', 'Crooks', '{"Koako koa soyu"}', false);
INSERT INTO public."CorreosList" VALUES ('57f6a7da-e410-5665-884f-3427b43352bd', '2022-09-29 15:06:52.922', '2020-05-17 04:47:58', '1997-10-06 10:09:13', 'Kirlin', '{"Koyumi yuraviso yuko"}', false);
INSERT INTO public."CorreosList" VALUES ('b8c05162-ccbc-54e0-805c-6bf6e8f1c56b', '2022-09-29 15:06:52.922', '2020-04-20 03:23:29', '2011-04-20 16:03:41', 'Hagenes', '{"Yuso yua yukoa"}', false);
INSERT INTO public."CorreosList" VALUES ('8b8bb15f-a6b7-566f-9467-932aba426edc', '2022-09-29 15:06:52.922', '2020-11-27 22:37:50', '2015-04-04 03:21:49', 'Huel', '{"Raviako ravisora"}', false);
INSERT INTO public."CorreosList" VALUES ('62aa0f3e-f6d8-5c4e-b7d9-da159a8f1dc8', '2022-09-29 15:06:52.922', '2020-10-26 10:12:14', '1996-01-17 00:39:25', 'Pagac', '{"Viami raviyu soyusora"}', false);
INSERT INTO public."CorreosList" VALUES ('64858c5a-9e5a-52ac-8247-26fe4d34c75e', '2022-09-29 15:06:52.922', '2020-05-05 04:06:52', '1994-03-23 14:26:51', 'McClure', '{"Viyu ramiyumi viravi"}', false);
INSERT INTO public."CorreosList" VALUES ('3184939d-8d16-5390-9b61-58edf0dedb40', '2022-09-29 15:06:52.922', '2020-07-07 18:43:30', '2012-05-13 17:08:39', 'Heidenreich', '{"Yumisoa viyusovi"}', false);
INSERT INTO public."CorreosList" VALUES ('ff124d91-faa1-5b10-b3bd-1e519951d037', '2022-09-29 15:06:52.922', '2020-10-10 09:14:10', '1990-07-19 18:44:11', 'Nitzsche', '{"Koviko miso"}', false);
INSERT INTO public."CorreosList" VALUES ('75e12777-6fea-57c2-b583-056281dd7d8c', '2022-09-29 15:06:52.922', '2020-04-28 15:15:35', '2017-10-14 22:09:35', 'Renner', '{"Somiso miyu"}', false);
INSERT INTO public."CorreosList" VALUES ('6975d07e-0afb-5221-a4ee-589a919e5a71', '2022-09-29 15:06:52.922', '2020-02-06 13:02:57', '2013-02-14 01:20:13', 'Yost', '{"Koviravi somi soviso"}', false);
INSERT INTO public."CorreosList" VALUES ('c8fdff0d-36ff-57f4-837a-4a12d402b035', '2022-09-29 15:06:52.922', '2020-03-03 14:18:15', '2013-10-06 09:48:36', 'Schowalter', '{"Virakovi korami"}', false);
INSERT INTO public."CorreosList" VALUES ('49cc8431-10a9-5a60-b5d9-523cf18fc29b', '2022-09-29 15:06:52.922', '2020-12-24 11:36:12', '1994-03-19 14:16:52', 'Ritchie', '{"Rayuvi yumi"}', false);
INSERT INTO public."CorreosList" VALUES ('118fd1fc-1b0d-576a-9d5b-ac2669a6f34d', '2022-09-29 15:06:52.922', '2020-06-06 05:42:15', '2002-03-27 14:08:09', 'Emmerich', '{"Sorako mira koyumiso"}', false);
INSERT INTO public."CorreosList" VALUES ('7b948ed0-280a-5d77-90d0-004d1b2a307c', '2022-09-29 15:06:52.922', '2020-01-17 13:00:24', '1986-03-11 14:39:07', 'Goyette', '{"Viyusora miaviko"}', false);
INSERT INTO public."CorreosList" VALUES ('02d69720-7153-580b-a5a6-957411f3e052', '2022-09-29 15:06:52.922', '2020-04-16 15:16:12', '2012-05-05 16:58:08', 'Lowe', '{"Rako yumiko somikoa"}', false);
INSERT INTO public."CorreosList" VALUES ('5ae4fd52-d3d5-56e4-a9fe-e0a3a5f8dab3', '2022-09-29 15:06:52.922', '2020-06-18 05:05:10', '1988-01-05 00:58:34', 'Kautzer', '{"Mikoami komi yuami"}', false);
INSERT INTO public."CorreosList" VALUES ('4830dc56-0b0a-568a-adaf-0d35d8b78b95', '2022-09-29 15:06:52.922', '2020-05-13 04:32:45', '1987-08-20 07:22:29', 'Turcotte', '{"Soayuko virami"}', false);
INSERT INTO public."CorreosList" VALUES ('fa4e7fc5-7434-5209-90f1-7c2d4a9403d6', '2022-09-29 15:06:52.922', '2020-12-04 11:50:13', '2016-05-05 04:27:37', 'Lockman', '{"Miso misoa sora"}', false);
INSERT INTO public."CorreosList" VALUES ('93887bc6-2ab9-557c-8ef3-04bf7b51b766', '2022-09-29 15:06:52.922', '2020-01-25 12:45:44', '1992-01-25 12:21:51', 'Abernathy', '{"Yuamiko soyuviko rami"}', false);
INSERT INTO public."CorreosList" VALUES ('6213ce52-9a27-580c-93dd-3b2b679f8055', '2022-09-29 15:06:52.922', '2020-12-16 12:04:02', '2003-04-24 15:14:49', 'O''Conner', '{"Soyusomi misoavi viako"}', false);
INSERT INTO public."CorreosList" VALUES ('f048237c-6d5a-5533-81f2-dae65d548bc1', '2022-09-29 15:06:52.922', '2020-04-28 16:04:10', '2005-02-18 01:34:58', 'Labadie', '{"Mira koyua ramiami"}', false);
INSERT INTO public."CorreosList" VALUES ('e8eea5ae-369f-5d2a-a38e-ce9a540f0e45', '2022-09-29 15:06:52.922', '2020-10-18 09:43:12', '1990-11-15 10:10:00', 'Senger', '{"Rasomiko miyumi miso"}', false);
INSERT INTO public."CorreosList" VALUES ('7a28e97b-64b1-50b5-8d85-7ae85be7b05b', '2022-09-29 15:06:52.922', '2020-10-18 21:40:03', '1981-06-06 17:48:47', 'Steuber', '{"Soyu kovia soyu"}', false);
INSERT INTO public."CorreosList" VALUES ('e00c1f2c-804f-5f69-863e-b02504ed6bbf', '2022-09-29 15:06:52.922', '2020-03-15 02:03:10', '1997-10-06 10:09:27', 'McGlynn', '{"Rakora mikoavi"}', false);
INSERT INTO public."CorreosList" VALUES ('8614a25b-ef37-5230-ad34-01d9133e01a5', '2022-09-29 15:06:52.922', '2020-08-16 19:32:33', '2016-01-09 12:38:35', 'Jakubowski', '{"Komi viavi"}', false);
INSERT INTO public."CorreosList" VALUES ('4cedc7d3-b677-5d60-b506-ad1e28ccaa30', '2022-09-29 15:06:52.922', '2020-03-27 14:27:51', '1992-09-01 20:37:29', 'Rowe', '{"Yusomi sora sorasovi"}', false);
INSERT INTO public."CorreosList" VALUES ('e055b82a-d323-5dfa-abf3-8ab751c2725d', '2022-09-29 15:06:52.922', '2020-07-07 18:40:29', '1996-01-17 00:39:25', 'Gulgowski', '{"Miravi soraviso soaviso"}', false);
INSERT INTO public."CorreosList" VALUES ('ae08658f-56ef-5ec5-b00b-ea3573716843', '2022-09-29 15:06:52.922', '2020-04-12 15:49:27', '2009-10-18 21:19:40', 'Oberbrunner', '{"Yuso soako"}', false);
INSERT INTO public."CorreosList" VALUES ('c10044b6-4910-51b8-a093-f9ae70bbc5d1', '2022-09-29 15:06:52.922', '2020-12-08 12:06:28', '1995-04-24 15:15:51', 'Carter', '{"Miavi kovi soaviso"}', false);
INSERT INTO public."CorreosList" VALUES ('1e033850-d77a-5ca1-9ddc-485a1c11f7e8', '2022-09-29 15:06:52.922', '2020-07-15 06:19:25', '2001-10-18 21:36:13', 'Mann', '{"Raviavi ramiko"}', false);
INSERT INTO public."CorreosList" VALUES ('922937b5-b321-5b07-9d55-a3ca0501d188', '2022-09-29 15:06:52.922', '2020-06-02 05:28:48', '2010-03-03 14:54:07', 'Kautzer', '{"Koyu sorakora soyuvi"}', false);
INSERT INTO public."CorreosList" VALUES ('b00971dc-f988-5fd9-a50a-b348e5f2849f', '2022-09-29 15:06:52.922', '2020-10-22 21:10:17', '1996-09-21 09:01:42', 'Gerhold', '{"Miyu raviko"}', false);
INSERT INTO public."CorreosList" VALUES ('8b940ff9-e903-5d56-94dd-0c5ab77ad5d0', '2022-09-29 15:06:52.922', '2020-11-15 22:50:06', '2006-11-27 10:49:49', 'Franecki', '{"Misovi mira mirayua"}', false);
INSERT INTO public."CorreosList" VALUES ('522c30c2-b68f-5682-8a31-65d4f0c3d962', '2022-09-29 15:06:52.922', '2020-01-13 13:03:57', '1997-10-22 10:07:09', 'Kiehn', '{"Yuvikoa rami"}', false);
INSERT INTO public."CorreosList" VALUES ('af6f4bde-edb9-53f0-b57f-112acd1d9bc5', '2022-09-29 15:06:52.922', '2020-05-13 04:08:31', '1996-01-01 00:36:00', 'Davis', '{"Yumia somi"}', false);
INSERT INTO public."CorreosList" VALUES ('cd513383-4216-5a62-a536-ff7457c222d7', '2022-09-29 15:06:52.922', '2020-12-04 23:41:00', '2012-05-09 17:04:51', 'Wyman', '{"Rakoravi yuayumi"}', false);
INSERT INTO public."CorreosList" VALUES ('5ce4c445-4be4-5b32-9308-57320d592261', '2022-09-29 15:06:52.922', '2020-03-19 14:23:10', '1990-07-07 18:30:27', 'O''Reilly', '{"Korasomi mikovia yuko"}', false);
INSERT INTO public."CorreosList" VALUES ('f5068469-9cdd-546a-b8dc-6174800a86ce', '2022-09-29 15:06:52.922', '2020-02-18 13:19:56', '1995-04-04 15:30:13', 'Leuschke', '{"Mirayu koamira"}', false);
INSERT INTO public."CorreosList" VALUES ('7c407a19-1911-5bb7-a10c-9ae9afb5c117', '2022-09-29 15:06:52.922', '2020-08-12 19:23:30', '1992-05-05 04:56:51', 'Kub', '{"Yukomia somi soaso"}', false);
INSERT INTO public."CorreosList" VALUES ('dcb0db10-1d5a-5424-ab15-d2b25c38a73a', '2022-09-29 15:06:52.922', '2020-10-18 10:01:01', '2017-06-26 05:22:12', 'Volkman', '{"Viraviko koyu raviyu"}', false);
INSERT INTO public."CorreosList" VALUES ('e3bf2ecd-75df-5010-b424-d820c729e114', '2022-09-29 15:06:52.922', '2020-08-28 07:07:27', '2000-05-05 04:44:09', 'Schoen', '{"Komirayu koyua yurakoa"}', false);
INSERT INTO public."CorreosList" VALUES ('31d6777f-0d26-5b60-9a41-3a35c71676d7', '2022-09-29 15:06:52.922', '2020-08-20 19:45:26', '1980-05-05 16:45:54', 'Reilly', '{"Rakoyura mikora yuavi"}', false);
INSERT INTO public."CorreosList" VALUES ('287f8ec0-9590-590a-aa46-4c881da3cc56', '2022-09-29 15:06:52.922', '2020-01-13 00:27:43', '2004-09-05 08:53:24', 'Bode', '{"Miyumi ramisoyu"}', false);
INSERT INTO public."CorreosList" VALUES ('bf1bf26a-75a1-5aae-ab0f-dbe6f0f58a63', '2022-09-29 15:06:52.922', '2020-02-14 13:11:15', '2005-02-22 01:29:47', 'Gulgowski', '{"Yura yukomira"}', false);
INSERT INTO public."CorreosList" VALUES ('80e8d7ba-a7fb-59b7-9245-6e7de19a2c13', '2022-09-29 15:06:52.922', '2020-10-02 21:33:08', '2015-12-16 11:47:02', 'Hartmann', '{"Kovia ramiravi"}', false);
INSERT INTO public."CorreosList" VALUES ('8c24d552-1c79-5223-b41e-5fe8225aefc9', '2022-09-29 15:06:52.922', '2020-10-14 10:09:14', '2009-06-06 05:42:58', 'Durgan', '{"Raviyu rakomiko ravi"}', false);
INSERT INTO public."CorreosList" VALUES ('e737a689-75a2-55fa-98f0-41866cb8229c', '2022-09-29 15:06:52.922', '2020-08-20 19:40:18', '1985-10-22 21:57:29', 'Reynolds', '{"Soyu soa"}', false);
INSERT INTO public."CorreosList" VALUES ('9dbe6dbc-2ad4-5901-bb1f-2e13ae4684f6', '2022-09-29 15:06:52.922', '2020-10-26 21:36:49', '2015-04-24 03:27:31', 'Weissnat', '{"Soaso vikovi visoviko"}', false);
INSERT INTO public."CorreosList" VALUES ('235b5b30-5f31-5a93-b8fa-36aeca10ce2d', '2022-09-29 15:06:52.922', '2020-09-21 20:25:21', '2015-08-08 20:07:15', 'Aufderhar', '{"Visovi rasoyua ramiyu"}', false);
INSERT INTO public."CorreosList" VALUES ('884f269e-810e-5374-9b91-d61fdd71ab19', '2022-09-29 15:06:52.922', '2020-05-13 16:24:01', '2012-01-01 00:25:25', 'Heidenreich', '{"Miaviko viyu somiako"}', false);
INSERT INTO public."CorreosList" VALUES ('95b69ed0-9193-5162-ac46-02f6d730c4ef', '2022-09-29 15:06:52.922', '2020-09-01 20:35:23', '2001-02-14 13:14:03', 'Macejkovic', '{"Soyumi vira kovira"}', false);
INSERT INTO public."CorreosList" VALUES ('432210d6-709c-5a44-9a0f-9c183fdf08dd', '2022-09-29 15:06:52.922', '2020-07-23 06:25:15', '1991-04-28 03:53:54', 'Lang', '{"Mirasora yusoami"}', false);
INSERT INTO public."CorreosList" VALUES ('501bbb73-0ef0-5276-8dd4-d8c33e6f81af', '2022-09-29 15:06:52.922', '2020-04-08 15:39:07', '2014-11-11 10:41:52', 'Funk', '{"Koayuso rayu"}', false);
INSERT INTO public."CorreosList" VALUES ('5883ed40-1c04-5235-8373-94bbd41b8172', '2022-09-29 15:06:52.922', '2020-10-22 09:34:46', '2005-02-22 01:37:01', 'Ortiz', '{"Mirasora mira"}', false);
INSERT INTO public."CorreosList" VALUES ('409b5dbd-f435-556f-a6c6-337781453e0b', '2022-09-29 15:06:52.922', '2020-10-02 21:15:47', '2013-10-14 09:36:50', 'Conn', '{"Ramiyu koravia yukovi"}', false);
INSERT INTO public."CorreosList" VALUES ('ea2d74b9-1d2b-53b0-a0ec-dc89ce59bd56', '2022-09-29 15:06:52.922', '2020-05-09 16:54:08', '1981-02-14 01:12:32', 'Torphy', '{"Sovi visovi koyusovi"}', false);
INSERT INTO public."CorreosList" VALUES ('6c5f4f2b-95c2-55e8-a9cb-e0411872e914', '2022-09-29 15:06:52.922', '2020-11-03 11:10:17', '2000-09-25 20:29:23', 'Blick', '{"Soviko yusoa"}', false);
INSERT INTO public."CorreosList" VALUES ('878202e1-456d-5222-8bf1-68358c522dda', '2022-09-29 15:06:52.922', '2020-09-13 21:10:47', '1996-05-05 16:21:05', 'Murray', '{"Rami komiyuvi mikomi"}', false);
INSERT INTO public."CorreosList" VALUES ('57a5a394-8cce-5021-b52e-c5732d04358e', '2022-09-29 15:06:52.922', '2020-10-22 22:07:44', '1980-05-13 16:54:05', 'Wiza', '{"Mirasoa mirayura"}', false);
INSERT INTO public."CorreosList" VALUES ('23c1d4ba-f12c-5ac1-81db-5d8d8dc5312b', '2022-09-29 15:06:52.922', '2020-01-25 00:22:05', '2016-01-13 12:49:23', 'Rowe', '{"Visoraso viso"}', false);
INSERT INTO public."CorreosList" VALUES ('3fbf5f68-48db-5723-9a5a-8526b6b646ec', '2022-09-29 15:06:52.922', '2020-06-26 05:35:15', '1992-09-05 20:41:38', 'Gerhold', '{"Soamiyu soyu yurami"}', false);
INSERT INTO public."CorreosList" VALUES ('d8dd83a6-6994-5e04-8a27-649cf34cbda1', '2022-09-29 15:06:52.922', '2020-11-03 10:51:52', '1994-03-11 14:19:25', 'Ruecker', '{"Yumikora yuviyu viyua"}', false);
INSERT INTO public."CorreosList" VALUES ('325b2daa-ee7e-50d0-bce1-9c281b4bc480', '2022-09-29 15:06:52.922', '2020-01-13 00:53:13', '1984-05-01 04:04:14', 'Abernathy', '{"Koaviso rami"}', false);
INSERT INTO public."CorreosList" VALUES ('2d6f3834-9153-53ab-a161-ee2e1b7c00b9', '2022-09-29 15:06:52.922', '2020-05-17 16:07:11', '1980-01-17 00:11:07', 'Koelpin', '{"Rakoyuso komi raviyu"}', false);
INSERT INTO public."CorreosList" VALUES ('b296cc76-4fa2-5a23-b7e9-ee74981a182b', '2022-09-29 15:06:52.922', '2020-10-22 21:46:45', '2012-09-05 08:34:24', 'Schneider', '{"Soyumira koviso viako"}', false);
INSERT INTO public."CorreosList" VALUES ('df2c98d2-9b56-5846-a623-c5d16d6afbac', '2022-09-29 15:06:52.922', '2020-04-08 03:23:59', '1993-02-06 13:13:33', 'Rowe', '{"Ramiyuvi raviso raso"}', false);
INSERT INTO public."CorreosList" VALUES ('366022a3-ccea-53f2-a41c-18e07dce125a', '2022-09-29 15:06:52.922', '2020-11-03 10:13:11', '1992-05-17 04:55:11', 'Dibbert', '{"Via ramiyu"}', false);
INSERT INTO public."CorreosList" VALUES ('444aba22-6e74-5861-8a44-3146d52fa499', '2022-09-29 15:06:52.922', '2020-07-11 18:53:57', '2004-01-21 00:28:11', 'Macejkovic', '{"Rami soamiso"}', false);
INSERT INTO public."CorreosList" VALUES ('d6ee8ba4-2dea-5392-9a14-0bb433cfde3d', '2022-09-29 15:06:52.922', '2020-08-28 08:07:00', '1986-07-15 06:16:09', 'Rutherford', '{"Soa kora"}', false);
INSERT INTO public."CorreosList" VALUES ('676ba4bf-aaca-5482-b157-efced490c331', '2022-09-29 15:06:52.922', '2020-06-26 17:10:54', '2012-01-13 00:12:47', 'Goyette', '{"Raso vikoyu viko"}', false);
INSERT INTO public."CorreosList" VALUES ('169837cd-8d02-5a76-ad12-6f46b6b81aca', '2022-09-29 15:06:52.922', '2020-02-18 01:41:43', '2001-06-18 05:53:18', 'Purdy', '{"Miayuko rayu"}', false);
INSERT INTO public."CorreosList" VALUES ('2690bb87-c7b8-5d44-bd83-1038c014a0ef', '2022-09-29 15:06:52.922', '2020-02-10 14:02:41', '1991-12-16 11:24:19', 'McGlynn', '{"Viyura kovikora yumiso"}', false);
INSERT INTO public."CorreosList" VALUES ('9f63df0a-32af-574a-b276-8effb28807af', '2022-09-29 15:06:52.922', '2020-04-08 15:39:29', '1998-07-19 18:20:52', 'Kreiger', '{"Sorako vikorami"}', false);
INSERT INTO public."CorreosList" VALUES ('c1d846c2-f5a0-51ec-8b62-e5985710f85c', '2022-09-29 15:06:52.922', '2020-08-12 19:55:11', '2014-11-03 10:50:29', 'Heathcote', '{"Raso mirami yumikovi"}', false);
INSERT INTO public."CorreosList" VALUES ('0a6bb397-d1b4-5782-8a07-ee529f151193', '2022-09-29 15:06:52.922', '2020-08-08 07:15:03', '1984-01-17 12:27:39', 'Herzog', '{"Raso soaso"}', false);
INSERT INTO public."CorreosList" VALUES ('91e8b4f3-556e-59ff-a067-41ee99fc237f', '2022-09-29 15:06:52.922', '2020-11-11 23:07:30', '2006-07-03 18:18:45', 'Legros', '{"Somi miasoa"}', false);
INSERT INTO public."CorreosList" VALUES ('bdf7009c-3d9d-52da-82dd-113533fbedea', '2022-09-29 15:06:52.922', '2020-07-23 18:10:34', '2002-07-19 06:51:03', 'Macejkovic', '{"Visovira visoa"}', false);
INSERT INTO public."CorreosList" VALUES ('bdfec415-d383-5486-b460-1494883f2a21', '2022-09-29 15:06:52.922', '2020-01-25 12:50:45', '1988-01-17 00:48:37', 'Lesch', '{"Yukomiko rayuvi"}', false);
INSERT INTO public."CorreosList" VALUES ('cd614820-893c-505d-a748-cd775160f9a5', '2022-09-29 15:06:52.922', '2020-01-17 12:58:32', '1989-10-10 09:19:04', 'Hessel', '{"Mikovi sovikoa"}', false);
INSERT INTO public."CorreosList" VALUES ('6f733e79-6197-534c-a392-047ae7ca431b', '2022-09-29 15:06:52.922', '2020-05-05 16:26:06', '2011-12-12 23:25:32', 'Keeling', '{"Yuviavi vikomira"}', false);
INSERT INTO public."CorreosList" VALUES ('d346dae4-1bb8-5026-a555-ecf8c794a2bf', '2022-09-29 15:06:52.922', '2020-03-03 02:28:16', '1986-03-03 14:33:09', 'Schuppe', '{"Ravi misoa"}', false);


--
-- TOC entry 4227 (class 0 OID 2148804)
-- Dependencies: 219
-- Data for Name: DeliveryAttempt; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4228 (class 0 OID 2148810)
-- Dependencies: 220
-- Data for Name: Deposit; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4229 (class 0 OID 2148816)
-- Dependencies: 221
-- Data for Name: Export; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."Export" VALUES ('6f9a0a22-f9a1-5993-9289-4d285680b825', '2022-09-29 15:06:50.902', 'Godfrey Reinger', 'Viakomi rasomi yuko', 'Ramia mikovia');
INSERT INTO public."Export" VALUES ('613e2025-87d9-52b3-bfb9-e8a2b1b65632', '2022-09-29 15:06:50.902', 'Aisha Prosacco', 'Miakora miso', 'Rako yusovia');
INSERT INTO public."Export" VALUES ('3dfe00c0-897e-54c8-8b02-bc1cfc63fcb2', '2022-09-29 15:06:50.902', 'Esta Gutmann', 'Yumi miakora', 'Soa koami yua');
INSERT INTO public."Export" VALUES ('e4d6be15-02aa-5906-9aa9-dcb62d2421fb', '2022-09-29 15:06:50.902', 'Alvah Dare', 'Rasovi yumisora', 'Sora yusora');
INSERT INTO public."Export" VALUES ('ed458fa5-16b2-5b36-9851-2f083fe6a77c', '2022-09-29 15:06:50.902', 'Bertha Paucek', 'Yumiko soviravi koraso', 'Yuso soyuavi');
INSERT INTO public."Export" VALUES ('5a615485-fbb7-5858-81ee-015631f0fcac', '2022-09-29 15:06:50.902', 'Evan Reynolds', 'Komi soaso visora', 'Komiaso viso');
INSERT INTO public."Export" VALUES ('f87ceaf9-2c5c-5fe7-98ba-bcbc42d3cd74', '2022-09-29 15:06:50.902', 'Ardella Pfeffer', 'Visoami rami somira', 'Koyuvia yuko');
INSERT INTO public."Export" VALUES ('503c8a54-edcc-5a03-a908-05ba9a9926e4', '2022-09-29 15:06:50.902', 'Gwen Connelly', 'Koyumi yumiraso rayumi', 'Rako koviaso');
INSERT INTO public."Export" VALUES ('9d3d27e8-64e8-5b6d-ab3a-b65b5061909f', '2022-09-29 15:06:50.902', 'Eleonore Runolfsson', 'Soyurami soa rakoyuko', 'Ramiyumi viyuavi rakomiyu');
INSERT INTO public."Export" VALUES ('6b14c764-68c9-5cb7-93f2-6fd7d784eed4', '2022-09-29 15:06:50.902', 'Bette Volkman', 'Viko vikoyuko', 'Rayuvi mirakomi');
INSERT INTO public."Export" VALUES ('5b235f19-6756-524d-a2a6-972f0f567a31', '2022-09-29 15:06:50.902', 'Everardo Kessler', 'Yukoviso yuami miso', 'Mikoyu soaviko sovi');
INSERT INTO public."Export" VALUES ('e9240dac-9009-52fe-b4f4-b73e8d5c1eba', '2022-09-29 15:06:50.902', 'Mara Herman', 'Viyuko soyusoa', 'Mia koraviko yua');
INSERT INTO public."Export" VALUES ('ea2867e4-7fd0-5754-990f-2db7cf68e67e', '2022-09-29 15:06:50.902', 'Mariano Price', 'Yuvisomi viko', 'Koramia koviko rako');
INSERT INTO public."Export" VALUES ('fd15d363-e839-5f14-a351-bea0f71feb5a', '2022-09-29 15:06:50.902', 'Carolina Mayer', 'Miyua sorami', 'Ravikoyu koviso');
INSERT INTO public."Export" VALUES ('f567d598-f5db-5aff-9c2c-a10ccddee6a1', '2022-09-29 15:06:50.902', 'Melba Abbott', 'Raso rayumia vikora', 'Miyu yukoavi yukora');
INSERT INTO public."Export" VALUES ('01d7b6e5-ac39-5d1a-a4c8-373c3c0d397d', '2022-09-29 15:06:50.902', 'Alejandrin Conroy', 'Viyuavi sorakovi', 'Viyuvi kora yusoavi');
INSERT INTO public."Export" VALUES ('c48fc51c-8b11-5820-a65a-0bda7a265799', '2022-09-29 15:06:50.902', 'Reece Bashirian', 'Sora yusoyu miayuso', 'Yuvirami miako');
INSERT INTO public."Export" VALUES ('a2862deb-d4ec-5ec9-abd8-72daf1fe025a', '2022-09-29 15:06:50.902', 'Tyrique Auer', 'Yurako viasoyu somi', 'Soasoyu soramiko');
INSERT INTO public."Export" VALUES ('c42775ea-7250-5843-b22c-b497862f7c8f', '2022-09-29 15:06:50.902', 'Nick Aufderhar', 'Koyukoa yuvi', 'Komi yuvikovi');
INSERT INTO public."Export" VALUES ('27865d68-a659-50ac-9f65-29d9704c58d0', '2022-09-29 15:06:50.902', 'Greyson Kirlin', 'Soramia kovi viako', 'Rayu ramiko');
INSERT INTO public."Export" VALUES ('27456edd-9661-586b-ba98-98107c695ca7', '2022-09-29 15:06:50.902', 'Irwin Hand', 'Miyu vikomiyu yukora', 'Yuvira rakoa vikovi');
INSERT INTO public."Export" VALUES ('749497c4-9ab6-58f5-959d-b150214ab771', '2022-09-29 15:06:50.902', 'Wendy Frami', 'Yukora yurasovi rakoa', 'Mirami miyuako koa');
INSERT INTO public."Export" VALUES ('6d7a0f2f-bde7-59c7-ac24-f96655d5ffc1', '2022-09-29 15:06:50.902', 'Kristian White', 'Mirasomi koravia', 'Ramira miko');
INSERT INTO public."Export" VALUES ('ff287734-80dd-5299-98cd-786a31b25367', '2022-09-29 15:06:50.902', 'Grayson O''Connell', 'Koviko rayukoa yuavi', 'Soramiko koa rami');
INSERT INTO public."Export" VALUES ('2b2fa917-26e0-5f56-b2da-25fef7424ed1', '2022-09-29 15:06:50.902', 'Leslie Williamson', 'Mia sora', 'Misorako viravi komia');
INSERT INTO public."Export" VALUES ('6675a5a3-c080-5b96-8b87-7f4307046daa', '2022-09-29 15:06:50.902', 'Reta Frami', 'Viayu somiyua viyumiko', 'Vikora mirayuko miko');
INSERT INTO public."Export" VALUES ('1cc6a1d7-3adb-56bd-a712-71b096b5fd11', '2022-09-29 15:06:50.902', 'Freida Gaylord', 'Koviyumi mira', 'Yuvi koviravi');
INSERT INTO public."Export" VALUES ('ff95dc7e-d7d0-5419-ad60-dfdeb8ea25b5', '2022-09-29 15:06:50.902', 'Edna King', 'Koviyu ravi yurakora', 'Yusomi yua');
INSERT INTO public."Export" VALUES ('c6b3dcb3-830e-5b11-be0c-221a1aaca0bb', '2022-09-29 15:06:50.902', 'Wilton Jacobi', 'Soyu miraso', 'Raso vikoyu soami');
INSERT INTO public."Export" VALUES ('d2c9ba19-15f2-5a5c-9cd3-b9d1b7cca9fd', '2022-09-29 15:06:50.902', 'Khalil Sawayn', 'Miso koyuso', 'Miraso vikoavi mia');
INSERT INTO public."Export" VALUES ('758caeb7-8e20-52c7-9a50-303532ff5312', '2022-09-29 15:06:50.902', 'Alyce Mertz', 'Yura miako', 'Komiami mia koayu');
INSERT INTO public."Export" VALUES ('cfc080de-6ec4-53d6-bdf6-00de21af182b', '2022-09-29 15:06:50.902', 'Jerome Nienow', 'Misomiyu vira somiko', 'Sovi rakomira');
INSERT INTO public."Export" VALUES ('3722959b-b737-5a71-ac20-fe65cec6e680', '2022-09-29 15:06:50.902', 'Florencio Dickinson', 'Viyuso viyu', 'Korami viko miayu');
INSERT INTO public."Export" VALUES ('a683992a-5cac-52e8-89e8-dafe626dbd24', '2022-09-29 15:06:50.902', 'Glennie Jacobi', 'Via somi soa', 'Soravi yusoa');
INSERT INTO public."Export" VALUES ('1fd384c7-f1f4-5efe-9bff-7b22ef6e9a09', '2022-09-29 15:06:50.902', 'Hildegard Goyette', 'Miyu soraso sovi', 'Miyu viyumi');
INSERT INTO public."Export" VALUES ('7b1b0034-c8ec-5470-a449-d2911fcc93f1', '2022-09-29 15:06:50.902', 'Mohamed Kertzmann', 'Viaso viyu', 'Koyusovi yuramia mirasomi');
INSERT INTO public."Export" VALUES ('df3c4131-5110-5727-8fc6-9705a96d0e9f', '2022-09-29 15:06:50.902', 'Keon Kuphal', 'Komia yusovi', 'Kora somirami koviyu');
INSERT INTO public."Export" VALUES ('639bd3a9-df8b-53f7-bc48-457aa5ba3f8a', '2022-09-29 15:06:50.902', 'Leon Dicki', 'Via viyumi', 'Yura sorako');
INSERT INTO public."Export" VALUES ('e266c8fd-e870-5802-91da-e163237be686', '2022-09-29 15:06:50.902', 'Cydney Thiel', 'Kovia viyu', 'Yua mikoami viyusomi');
INSERT INTO public."Export" VALUES ('f4b53d68-ed08-5a62-ba44-03e35368599a', '2022-09-29 15:06:50.902', 'Timmothy Funk', 'Sorayu kora soaviso', 'Viyuvira koyuvi');
INSERT INTO public."Export" VALUES ('c1583409-ba66-5fbe-8f92-1a3e9fbc6682', '2022-09-29 15:06:50.902', 'Joanne Beier', 'Koavi miyu', 'Vira yumia rami');
INSERT INTO public."Export" VALUES ('292b77ea-51ca-56af-8099-43782c6f8e82', '2022-09-29 15:06:50.902', 'Jaqueline Herman', 'Viyuami miami koyuko', 'Via rayukoa');
INSERT INTO public."Export" VALUES ('33eb9d15-55ac-597d-abee-7b9c2a9d8025', '2022-09-29 15:06:50.902', 'Renee Rau', 'Soyumiyu yuvia vira', 'Viyusora yuvi');
INSERT INTO public."Export" VALUES ('55897fd0-62f8-5653-badc-2f1fd8771c3c', '2022-09-29 15:06:50.902', 'Gerda Dooley', 'Viyuako misoa', 'Koramiso vikovi misorako');
INSERT INTO public."Export" VALUES ('d213a435-4cb8-5ada-917a-85f392ae4f30', '2022-09-29 15:06:50.902', 'Kendra Crona', 'Komiavi yuako', 'Koramia yurami');
INSERT INTO public."Export" VALUES ('12c2907c-3e07-508c-9a9c-741167bb405f', '2022-09-29 15:06:50.902', 'Immanuel Pollich', 'Kovia rayu yusomia', 'Kora yurayu raviyuko');
INSERT INTO public."Export" VALUES ('2c393fe1-122d-5790-a81f-6fa79bb8f45c', '2022-09-29 15:06:50.902', 'Jeffry Jacobi', 'Viyumi viami miko', 'Rayu mikomi komisovi');
INSERT INTO public."Export" VALUES ('6db450ff-9784-5cb4-b7ff-c55edf9588e6', '2022-09-29 15:06:50.902', 'Kaya Kris', 'Soyuko mia mirayuvi', 'Rakorayu yua virayu');
INSERT INTO public."Export" VALUES ('d5a71830-5e27-5eaa-85b0-4d1714cc4975', '2022-09-29 15:06:50.902', 'Laron Bogan', 'Ramia soyu virako', 'Sorako rayuravi');
INSERT INTO public."Export" VALUES ('d19942e3-2a63-5bdc-ba80-ad4fbf4d8318', '2022-09-29 15:06:50.902', 'Brenda Osinski', 'Vikoyura korako rakoravi', 'Korami sorayura');
INSERT INTO public."Export" VALUES ('f3fd02df-359e-508a-810f-9df1daa11f76', '2022-09-29 15:06:50.902', 'Darlene Nicolas', 'Vira rayuviko', 'Yuvi mirakoa virakora');
INSERT INTO public."Export" VALUES ('d42c348d-71fe-5fef-bbb3-39d9a034f2f4', '2022-09-29 15:06:50.902', 'Lucius Boyle', 'Vikoavi rayu', 'Koyuvi soavira');
INSERT INTO public."Export" VALUES ('13704786-6489-5613-8111-d1177488793f', '2022-09-29 15:06:50.902', 'Vernon Schneider', 'Mirami rami', 'Mikoviko rako');
INSERT INTO public."Export" VALUES ('041df351-cc93-5f12-afd0-189554dd199a', '2022-09-29 15:06:50.902', 'Therese Hand', 'Yusoa yumiyumi soyua', 'Soyura koami');
INSERT INTO public."Export" VALUES ('5ca9c2cc-2c91-5a91-9f4c-74ec9d49e76f', '2022-09-29 15:06:50.902', 'Cameron Legros', 'Mikoravi yumira', 'Vikomi sora yuviami');
INSERT INTO public."Export" VALUES ('4ceb8cc0-7075-5d07-996b-067d44db7816', '2022-09-29 15:06:50.902', 'Adolph Zboncak', 'Raviyu kovi', 'Mikoa rami');
INSERT INTO public."Export" VALUES ('46bf8962-c58d-571c-8141-9747551983ec', '2022-09-29 15:06:50.902', 'Unique Hamill', 'Mia virami miraviko', 'Yukoyu yuaso');
INSERT INTO public."Export" VALUES ('90590abc-8a56-549d-ad8b-161c3f66eaaf', '2022-09-29 15:06:50.902', 'Richie Kulas', 'Rami somiyu', 'Yuso mirayura koa');
INSERT INTO public."Export" VALUES ('5eae1bd5-3dff-5d12-adf5-bdd88fb0c414', '2022-09-29 15:06:50.902', 'Raquel Swaniawski', 'Yumikoyu viso viasomi', 'Ravi vikoyu yura');
INSERT INTO public."Export" VALUES ('4e7bbf09-a3c7-5bb6-9b55-6ee2790f06cd', '2022-09-29 15:06:50.902', 'Kory Considine', 'Vira somiyua', 'Rayu yukovira');
INSERT INTO public."Export" VALUES ('8ba80165-41d7-5242-ba1c-9036d0c2be24', '2022-09-29 15:06:50.902', 'Arvel Hilll', 'Rasoa mirayu', 'Miyu yusoa');
INSERT INTO public."Export" VALUES ('889754d2-36e8-55bd-bd43-7c921dd60949', '2022-09-29 15:06:50.902', 'Thelma Schiller', 'Somiravi koravi', 'Ramiko yura komikomi');
INSERT INTO public."Export" VALUES ('1fea5e71-1744-514a-a407-0767407f81fb', '2022-09-29 15:06:50.902', 'Dell Jacobs', 'Mia vikoyua', 'Viravi via');
INSERT INTO public."Export" VALUES ('36053e65-b4d3-5b9a-a90e-e21d1b5b908e', '2022-09-29 15:06:50.902', 'Sheila Grant', 'Mia yuko soyuko', 'Komi soyura');
INSERT INTO public."Export" VALUES ('0378163c-2204-5c1c-8e36-1f517f77b35f', '2022-09-29 15:06:50.902', 'Jairo Walsh', 'Yuvira yuvirayu', 'Yurami viko viami');
INSERT INTO public."Export" VALUES ('1d049c8c-cfa1-564e-9d45-1f052550c8a7', '2022-09-29 15:06:50.902', 'Bianka Runolfsdottir', 'Raviso koa somirami', 'Vira soaviyu');
INSERT INTO public."Export" VALUES ('462b7def-d2a5-5ce7-b854-6ad63480cdb2', '2022-09-29 15:06:50.902', 'Henriette Krajcik', 'Ravirayu mirami sora', 'Visorami yua misoyumi');
INSERT INTO public."Export" VALUES ('b8440238-614a-5ec9-8d9f-7a4f1695d6c3', '2022-09-29 15:06:50.902', 'Tristin Kovacek', 'Yumiso ravi rayuso', 'Yumiso vira');
INSERT INTO public."Export" VALUES ('afb17244-a52c-511e-8c59-23edbad53469', '2022-09-29 15:06:50.902', 'Drew Bode', 'Yukomi yumikora soyuaso', 'Viyu miyuso');
INSERT INTO public."Export" VALUES ('0ec200a3-c857-5968-b4bb-28456cb6d559', '2022-09-29 15:06:50.902', 'Ruby Mueller', 'Soayuko raviko', 'Yumi yurayuso miko');
INSERT INTO public."Export" VALUES ('7b35a3ef-7506-5e74-a476-9c35b1c74e96', '2022-09-29 15:06:50.902', 'Holden Prohaska', 'Koyu viyuako viko', 'Ravi soako via');
INSERT INTO public."Export" VALUES ('9a4cf936-169f-5ec5-bb25-32fe0115a402', '2022-09-29 15:06:50.902', 'Jonathan Crooks', 'Viakoyu soyukoyu komikoa', 'Yuraviso mirayu virasoyu');
INSERT INTO public."Export" VALUES ('e97ed02c-0283-508f-8737-2c3bd9007f5c', '2022-09-29 15:06:50.902', 'Kendrick Johnston', 'Yura yuamiso yukoviko', 'Mikorami miyuso');
INSERT INTO public."Export" VALUES ('2b088f23-d3c2-5eaf-b9ac-8d62a2b6e060', '2022-09-29 15:06:50.902', 'Lizeth Pouros', 'Raso via viamiso', 'Komiso mia yuavira');
INSERT INTO public."Export" VALUES ('7a6914e9-7fd5-58a6-bedd-f8c94d5ba261', '2022-09-29 15:06:50.902', 'Myra Jones', 'Sorasomi viaviyu', 'Rako mikora ravi');
INSERT INTO public."Export" VALUES ('e4af3c46-c5fc-50c4-b385-44609e6ca652', '2022-09-29 15:06:50.902', 'Sarah Schaefer', 'Yuavi rakoyua', 'Vikoa misovi mia');
INSERT INTO public."Export" VALUES ('50027619-c67c-5c98-9f33-b9a75b435c2f', '2022-09-29 15:06:50.902', 'Faustino Yundt', 'Yuramiko vikoyu kovikoyu', 'Sorayu viakomi');
INSERT INTO public."Export" VALUES ('5d32804d-d2f6-5d30-9502-cc0a2f905594', '2022-09-29 15:06:50.902', 'Mazie Bednar', 'Mirakoyu vikora sorakomi', 'Virami yuviyua viyumira');
INSERT INTO public."Export" VALUES ('9c958f0b-1206-54ae-b697-c514af961be7', '2022-09-29 15:06:50.902', 'Gwendolyn Kunde', 'Yura vikoviyu viyuavi', 'Yusorako soyuko');
INSERT INTO public."Export" VALUES ('f4b67a21-bf9e-5ae0-b272-031da39e6b68', '2022-09-29 15:06:50.902', 'Velva Boyer', 'Sorayu sora', 'Yusoa mirayumi mikora');
INSERT INTO public."Export" VALUES ('1cfcdfce-76ac-51e4-8757-cee7397dbf9c', '2022-09-29 15:06:50.902', 'Consuelo Denesik', 'Yumiyu miako miyumiko', 'Miyukomi yumikoa komirami');
INSERT INTO public."Export" VALUES ('392e67f2-eaba-53c6-8b8d-68c3d6c36c53', '2022-09-29 15:06:50.902', 'Jarvis Fisher', 'Via soavi', 'Mikoami vikoravi rayu');
INSERT INTO public."Export" VALUES ('4b218f64-033a-5ca1-a2e4-c6e516a935fd', '2022-09-29 15:06:50.902', 'Delilah Davis', 'Yurasomi rasovia', 'Ramiyuvi virayu mikorako');
INSERT INTO public."Export" VALUES ('ba4d1625-d027-5ecd-83d3-7e9a64930d75', '2022-09-29 15:06:50.902', 'Vaughn Hoppe', 'Ravikoyu koakoyu virayura', 'Viko viako');
INSERT INTO public."Export" VALUES ('d8e7c432-ebbb-53d6-9010-e105e765a02b', '2022-09-29 15:06:50.902', 'Myrtis Bogisich', 'Koa mira soraso', 'Koaso misora miyuviyu');
INSERT INTO public."Export" VALUES ('9922d540-6846-5ef9-bb62-79500a8ea229', '2022-09-29 15:06:50.902', 'Graciela Crona', 'Mikomi koa', 'Miayu komiyu');
INSERT INTO public."Export" VALUES ('aa9e939d-60f1-5560-9e8c-c8b709a27054', '2022-09-29 15:06:50.902', 'Keely Marvin', 'Viko soa', 'Miko koyukoyu');
INSERT INTO public."Export" VALUES ('9bb7af34-55d1-581f-8e5c-a438405870dc', '2022-09-29 15:06:50.902', 'Rod Gusikowski', 'Vira visoyuso', 'Yuko sorakoa');
INSERT INTO public."Export" VALUES ('6a888fca-fea5-5df5-b722-4d58a722408b', '2022-09-29 15:06:50.902', 'Junior Pacocha', 'Koviyu miso', 'Miasoa yumi soyusoyu');
INSERT INTO public."Export" VALUES ('d7dcf4f3-5ec2-5a75-8cb4-3b19b321a576', '2022-09-29 15:06:50.902', 'Rocky Corkery', 'Miavia soyumiko viakora', 'Yua viyu');
INSERT INTO public."Export" VALUES ('8d519035-2777-5be8-a233-18ee160a398b', '2022-09-29 15:06:50.902', 'Wilson White', 'Koasovi soami rayumi', 'Miaso yuravia mirayu');
INSERT INTO public."Export" VALUES ('a745b09c-e6e4-5147-bf12-681c39c76d05', '2022-09-29 15:06:50.902', 'Margarette Marquardt', 'Viavi yua', 'Rasoa soa kovi');
INSERT INTO public."Export" VALUES ('38b501be-4c4d-5165-90fc-8674c2d2df4e', '2022-09-29 15:06:50.902', 'Lexus Larkin', 'Rakoyuko yumi', 'Soyu yurasomi');
INSERT INTO public."Export" VALUES ('97549edc-0104-5fac-a16d-9ed15b84ec12', '2022-09-29 15:06:50.902', 'Cathryn Williamson', 'Misoyuko rayu', 'Sorami soa yuso');
INSERT INTO public."Export" VALUES ('dab652c8-9654-5ea8-8bb0-b00c508a6b01', '2022-09-29 15:06:50.902', 'Michelle Crooks', 'Visorako mia', 'Soviyu sovi');
INSERT INTO public."Export" VALUES ('244e9bf0-9e94-50e8-8d89-7b28567af565', '2022-09-29 15:06:50.902', 'Cassandre Swaniawski', 'Yuviyu miako ravira', 'Miasomi mikovi kovia');
INSERT INTO public."Export" VALUES ('9ee5d4a0-db3d-5c52-a6f0-c44bb771742c', '2022-09-29 15:06:50.902', 'Karen Becker', 'Rayua raviko yumia', 'Soyu korayu');
INSERT INTO public."Export" VALUES ('7e0facd2-1afe-5ead-83a3-8e2e8ea0236b', '2022-09-29 15:06:50.902', 'Donna Wilkinson', 'Yuamiso rasoviko yuavia', 'Rakoavi virayuso');
INSERT INTO public."Export" VALUES ('76206ec0-03af-5a02-9f91-acbc08fd621d', '2022-09-29 15:06:50.902', 'Colleen Kris', 'Raviyura koraso koyu', 'Viyumi koavira rayu');
INSERT INTO public."Export" VALUES ('69f8e45b-497f-5011-800b-116dbb1ce8db', '2022-09-29 15:06:50.902', 'Kurtis Mosciski', 'Rayumi somisovi', 'Mirako soyu via');


--
-- TOC entry 4230 (class 0 OID 2148822)
-- Dependencies: 222
-- Data for Name: Incident; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."Incident" VALUES ('6bd5d518-3060-5d1c-9bbd-93be52b44bc5', '1340399664102305', '2022-09-29 15:06:48.497', '2020-08-12 08:00:26', '2007-12-12 11:54:32', '1997-02-10 01:47:11', 'Antonio Kling', 'Yuvisora', '2020-01-05 12:52:03', NULL, '09537223-4728-5695-907b-d7dcce5b3c69', 'cae9e630-7637-5218-a20b-652d81ec19e7', NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--
-- TOC entry 4231 (class 0 OID 2148828)
-- Dependencies: 223
-- Data for Name: IncidentStatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."IncidentStatus" VALUES ('cae9e630-7637-5218-a20b-652d81ec19e7', 'Florencio Lockman');


--
-- TOC entry 4232 (class 0 OID 2148833)
-- Dependencies: 224
-- Data for Name: IncidentType; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."IncidentType" VALUES ('09537223-4728-5695-907b-d7dcce5b3c69', 'Larue Jacobi');


--
-- TOC entry 4233 (class 0 OID 2148838)
-- Dependencies: 225
-- Data for Name: Invoice; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."Invoice" VALUES ('2ec300d0-09a7-5c1f-b359-bf4319f3c86b', '2022-09-29 15:06:35.767', '2020-01-13 12:48:33', 'Viako rakoviyu ramia', '6790476670775496', NULL, 'd8a64e32-4db7-5626-89aa-5a12c877c9d3', '1983422946307726', '1993-10-14 21:37:18', 'Komi viyuko rasorami', 13340, '8765af90-e5c9-566f-b47f-5fb723cc24c7', NULL, 'Candida.VonRueden165@gmail.com', 55692, 40057, 14567, 54083, 21058, 4631, 80, 233, 187, '1989-06-22 17:29:28', false, 'Yusoraso kovira', NULL, '2018-11-03 23:05:51', NULL, 27949, 1456, 28, 'Sovi korasoa', NULL, 'Rakoviyu mira', 'Visoa miavira', NULL, '1336291084270640', 'Soyuami koyumira somiko', '1996-01-21 00:48:07', false, 'Soravi sora rayumi', '1987-12-28 23:53:59', false, false, '2015-08-04 19:56:48', NULL, 'Somiyuso rayuvi');
INSERT INTO public."Invoice" VALUES ('c43aa383-9051-54e3-8d05-fa3ab91896da', '2022-09-29 15:06:35.767', '2020-09-21 09:06:15', 'Via mirako', '3891894920585500', NULL, '919caa1f-be4d-5335-a835-601ce5b75a65', '237578105923686', '2016-05-17 04:21:38', 'Sovi koviavi viyu', 6154, '063dd410-7a3d-50cf-a361-55ece110d986', NULL, 'Sonya_Deckow808@yahoo.com', 55062, 9120, 51122, 57252, 65412, 7639, 212, 223, 119, '2005-02-22 01:30:15', false, 'Miyuso komi', NULL, '1985-06-10 05:10:17', NULL, 29397, 1190, 157, 'Yumiko viyu', NULL, 'Soyu vikoa', 'Yura mikomi', NULL, '4675933635467554', 'Ramiso korayura', '1987-04-28 15:41:34', false, 'Virakora sora yuavi', '2006-03-23 02:38:02', false, false, '1987-04-28 15:42:16', NULL, 'Yuviko soa rasoviyu');
INSERT INTO public."Invoice" VALUES ('dca0921f-e17f-5bff-a978-da487e791fec', '2022-09-29 15:06:35.767', '2020-04-12 03:21:29', 'Sovikovi koyuko viyu', '3600876049912157', NULL, 'c3665bb0-9b4e-5736-a61f-ba203226afd2', '2045214374188720', '1998-03-07 02:39:51', 'Yuko yuviyu', 64605, 'f3a2ebf5-a265-5e30-a0e8-746cac8d2163', NULL, 'Jovanny.Becker437@hotmail.com', 44547, 5352, 21704, 5709, 57488, 35299, 24, 245, 67, '1984-09-05 20:48:51', false, 'Yurayu viramiko', NULL, '1989-10-26 09:18:31', NULL, 8143, 40919, 22, 'Mia koasoyu koyumiso', NULL, 'Mia soyuayu viavi', 'Viyuko raso rayumira', NULL, '3144203125631235', 'Koyu yusoviso', '2008-09-05 20:24:24', false, 'Yua viyusoa yuvirami', '2001-10-02 21:32:13', false, false, '1987-08-08 07:10:51', NULL, 'Soa raviko');
INSERT INTO public."Invoice" VALUES ('0a63b2bb-a149-5d79-a56a-7e77306a426a', '2022-09-29 15:06:35.767', '2020-10-26 09:31:55', 'Ramiyu misoaso viyuviso', '1264462202772987', NULL, 'd69aaf00-10f9-5d41-989c-a03aaffc2dc4', '5717800716657493', '1981-10-10 09:35:51', 'Koramia rayuvi rako', 43233, '98655e2f-f478-577d-b5ed-19d574a19fc4', NULL, 'Alda_Olson383@hotmail.com', 18311, 62947, 10264, 2899, 61244, 23278, 101, 103, 122, '1993-02-02 13:28:53', false, 'Miyuviyu soavi', NULL, '1984-09-09 20:44:01', NULL, 23839, 52382, 170, 'Mirayu yusorami', NULL, 'Soa yumira viyumiko', 'Sovi ramiso koako', NULL, '8532737898731683', 'Yusomi komiyuko', '2001-06-10 05:56:19', false, 'Sorayuko viyua yura', '2000-05-17 04:52:10', false, false, '1999-08-28 19:28:33', NULL, 'Koyu koayu yuko');
INSERT INTO public."Invoice" VALUES ('15a146d0-e461-5036-bd11-a49a5b4e2bb5', '2022-09-29 15:06:35.767', '2020-07-27 18:21:56', 'Kora mia yumia', '3029951057659735', NULL, 'b4103acb-fd50-540e-95cf-c019ca508829', '7034483496061592', '1988-09-13 08:24:32', 'Rasoa yuko', 44989, '867e7a20-68fc-5834-a3fe-1aa61724abb7', NULL, 'Trisha.Kertzmann670@hotmail.com', 60091, 41932, 39484, 50648, 11595, 29824, 84, 141, 71, '2018-03-27 14:47:53', false, 'Soyuako koyu', NULL, '1999-04-20 03:45:09', NULL, 23936, 24481, 72, 'Virasora rami', NULL, 'Viyu koako komisomi', 'Rami rakora rasoyua', NULL, '4528890694959759', 'Mikoviyu raviso', '2008-09-25 20:10:58', false, 'Ramiko soyu yuami', '1981-06-18 17:51:12', false, false, '2000-01-01 12:15:10', NULL, 'Rayumi yura via');
INSERT INTO public."Invoice" VALUES ('2fe1c7b6-3ead-53ec-89b1-a8d68135e182', '2022-09-29 15:06:35.767', '2020-03-27 14:32:02', 'Rayumi viko koyuso', '2089250279626078', NULL, '68fd2ec8-ecdc-5ec3-a206-9ea83f162d36', '7573077762650790', '2004-01-01 00:36:29', 'Vikovi kora soyuvi', 1113, 'bab7a2c7-e705-500a-b796-74b6becf2437', NULL, 'Adah_Mayert670@yahoo.com', 32890, 31737, 3537, 25036, 64819, 39216, 60, 206, 191, '2015-12-16 11:37:42', false, 'Koayuko soramira yukora', NULL, '1998-03-23 02:50:58', NULL, 33890, 47820, 113, 'Via rakomiyu rayuaso', NULL, 'Somi korami visomiko', 'Kovi visomiko koakovi', NULL, '991536262764326', 'Virami vikoraso', '2018-11-07 22:58:55', false, 'Miavi ravisomi rako', '1999-12-24 12:08:57', false, false, '1999-04-16 03:55:35', NULL, 'Korayu rako');
INSERT INTO public."Invoice" VALUES ('d1f38c5d-cb16-5e86-92b3-b3e87a06fb58', '2022-09-29 15:06:35.767', '2020-09-21 20:25:42', 'Misoviko yusoa', '2190640993982647', NULL, '2380e136-3e08-5b30-9640-6d74af75fa99', '3946257505579074', '1990-03-03 03:01:00', 'Soraso rakoviko rako', 22965, 'f44de9c1-d178-5bea-b486-bd889404857f', NULL, 'Pinkie_Lehner67@hotmail.com', 58741, 17459, 41685, 8426, 9795, 62817, 31, 37, 132, '2017-02-10 13:46:22', false, 'Via ramia', NULL, '2000-09-13 20:28:29', NULL, 6583, 18258, 3, 'Mikora somiyuko', NULL, 'Visorayu miyuavi yuko', 'Yua misomia soyu', NULL, '5521493929297132', 'Mia koamiko', '1999-12-24 12:04:52', false, 'Sovia koyu', '1999-04-24 03:43:21', false, false, '1991-04-28 04:06:09', NULL, 'Yusoami sora');
INSERT INTO public."Invoice" VALUES ('5a3ac07c-cd5a-5cf2-b5f1-e9fa280f0a08', '2022-09-29 15:06:35.767', '2020-10-10 09:50:59', 'Kovi rasomira soa', '3960274891446094', NULL, '760bc561-2082-528c-9268-826f49fd8c6e', '274353810875926', '2008-05-13 04:36:22', 'Visoyu koyuvira kora', 65064, 'aa827bc5-610b-5843-933e-b7ac96e3c206', NULL, 'Jaiden.Wisozk47@hotmail.com', 13046, 36556, 47568, 39941, 41003, 8248, 195, 202, 30, '1982-03-27 02:16:40', false, 'Kovi miakomi', NULL, '1994-07-11 06:59:39', NULL, 47836, 19049, 36, 'Miami yumi', NULL, 'Viravi yukomiko', 'Raso miako soyu', NULL, '6870687411593687', 'Miyuko koa yusomi', '2012-05-21 16:53:09', false, 'Sora koramiyu', '1988-05-21 16:41:52', false, false, '2002-07-07 06:56:13', NULL, 'Visoyu somi miasora');


--
-- TOC entry 4234 (class 0 OID 2148844)
-- Dependencies: 226
-- Data for Name: InvoiceReport; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4235 (class 0 OID 2148850)
-- Dependencies: 227
-- Data for Name: InvoiceStatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."InvoiceStatus" VALUES ('481dfdf8-e863-5802-a229-8d7f2cb3e01a', 'Georgette Rutherford');
INSERT INTO public."InvoiceStatus" VALUES ('f0e6bed4-83a8-5b4e-84fc-5f79578de797', 'Jed Schroeder');
INSERT INTO public."InvoiceStatus" VALUES ('a637d329-073c-5812-9f76-5cbfcb3e8bb8', 'Lily O''Hara');
INSERT INTO public."InvoiceStatus" VALUES ('3ba336c3-5ad7-5a58-a421-b81a4dec6878', 'Lucie Trantow');
INSERT INTO public."InvoiceStatus" VALUES ('12bd9aef-366f-536c-9a2b-482b69069f9e', 'Savanna Powlowski');
INSERT INTO public."InvoiceStatus" VALUES ('acc11d6d-ceea-5f9f-83c4-681f4662d78b', 'Melany Schmidt');
INSERT INTO public."InvoiceStatus" VALUES ('c5f066fd-d29d-58c1-88c2-9743424fee8c', 'Kaela Spinka');
INSERT INTO public."InvoiceStatus" VALUES ('06d3e8c4-b7bd-5a51-84b8-841159edf6a0', 'Camryn Hilpert');
INSERT INTO public."InvoiceStatus" VALUES ('4d81d1d8-d639-5c05-b500-9ff497ea8770', 'Quinten Leuschke');
INSERT INTO public."InvoiceStatus" VALUES ('349ba946-5824-5fa4-83be-0eedc7873735', 'Vergie Bradtke');
INSERT INTO public."InvoiceStatus" VALUES ('f7813092-b27b-58b8-b753-41603f333ff8', 'Adonis Herzog');
INSERT INTO public."InvoiceStatus" VALUES ('b5f06cdd-ec67-5922-aec8-076a22351bc4', 'Faye Gulgowski');
INSERT INTO public."InvoiceStatus" VALUES ('dc52540f-8530-5adc-b575-7e14b0bb8b13', 'Lemuel Murphy');
INSERT INTO public."InvoiceStatus" VALUES ('752f62c4-f8f1-5a7a-8a27-44f596cab930', 'Merritt Lang');
INSERT INTO public."InvoiceStatus" VALUES ('472bc529-e90f-50c4-9d39-6690c9487d5a', 'Domingo Murphy');
INSERT INTO public."InvoiceStatus" VALUES ('959e6589-a029-57ca-ba5e-7edce1cb476f', 'Marguerite Ebert');
INSERT INTO public."InvoiceStatus" VALUES ('2e93e5a2-5de8-5e90-af74-816bd3f54869', 'Isaac Heaney');
INSERT INTO public."InvoiceStatus" VALUES ('cf9731d8-5395-55a9-980f-3d0823507b58', 'Melyna Grant');
INSERT INTO public."InvoiceStatus" VALUES ('130851c6-0ff7-570d-97a1-1f0516083ff5', 'Tyrique Turcotte');
INSERT INTO public."InvoiceStatus" VALUES ('6d3f64e4-51d0-56d9-880a-acffb8431ec8', 'Kane Treutel');
INSERT INTO public."InvoiceStatus" VALUES ('ce6fd9b2-c909-5a9b-943d-e1e4e12e9252', 'Alaina Veum');
INSERT INTO public."InvoiceStatus" VALUES ('475ac32f-01cd-5e1b-b190-a73c2f87ff2c', 'Ludwig Lesch');
INSERT INTO public."InvoiceStatus" VALUES ('2bdc6055-589d-509e-8497-5a5155bc246d', 'Kelton Okuneva');
INSERT INTO public."InvoiceStatus" VALUES ('6e45bee5-93bd-558d-bada-27b218f78889', 'Bryon Bradtke');
INSERT INTO public."InvoiceStatus" VALUES ('8e026ac3-bb74-5899-89f4-1649840aa9c5', 'Liza Heathcote');
INSERT INTO public."InvoiceStatus" VALUES ('4f8dbc90-99c8-55ed-af9f-3fe5a9c5c0d4', 'Damien Gleason');
INSERT INTO public."InvoiceStatus" VALUES ('e87a7674-e610-5690-b8cb-c35f86097945', 'Alisha Gleichner');
INSERT INTO public."InvoiceStatus" VALUES ('16e0ab0f-117b-5041-8627-4e3a5d3ffd24', 'Tabitha Kerluke');
INSERT INTO public."InvoiceStatus" VALUES ('c833d7c4-465c-58cd-bf2c-a658c3779930', 'Cassidy Wilderman');
INSERT INTO public."InvoiceStatus" VALUES ('335ab8ee-56f0-5bda-975c-337619f3e04b', 'Tristin Bergnaum');
INSERT INTO public."InvoiceStatus" VALUES ('6d93faad-6d34-5d57-a47a-abd6d90a57e4', 'Keanu Kerluke');
INSERT INTO public."InvoiceStatus" VALUES ('d3110d60-6d49-5f5a-b974-e1add1bb2f5a', 'Alice Schulist');
INSERT INTO public."InvoiceStatus" VALUES ('dd1376ae-37aa-5888-9352-74490e69429c', 'Krystina Ernser');
INSERT INTO public."InvoiceStatus" VALUES ('221e8dc7-e755-5332-924f-9bd69a459f11', 'Georgiana Buckridge');
INSERT INTO public."InvoiceStatus" VALUES ('33198840-aa97-5e95-a067-473d6473f42d', 'Virgie Nicolas');
INSERT INTO public."InvoiceStatus" VALUES ('31cbfaf8-5ffb-5cc6-8ed1-519abfdb0dee', 'Leilani Botsford');
INSERT INTO public."InvoiceStatus" VALUES ('734d21f2-98c6-5943-8764-9cd46694eb26', 'Brendan Purdy');
INSERT INTO public."InvoiceStatus" VALUES ('a44bd2f1-5815-5d09-a7a9-8c081016816d', 'Devyn Dickens');
INSERT INTO public."InvoiceStatus" VALUES ('b8e8c233-6714-51e4-8c7f-0a0f90bbd581', 'Franz Crist');
INSERT INTO public."InvoiceStatus" VALUES ('6e9a368e-5b6a-57ef-85e4-ae7f04a1a689', 'Emma Bergnaum');
INSERT INTO public."InvoiceStatus" VALUES ('043c0db1-9492-5ddc-afa0-49f88658fc92', 'Emmie Reilly');
INSERT INTO public."InvoiceStatus" VALUES ('88bd1d4f-8750-5f2e-94ab-027d80d09946', 'Rashawn Stoltenberg');
INSERT INTO public."InvoiceStatus" VALUES ('b1ec4439-2d64-561c-9ed6-55d7b78d4293', 'Imogene Brown');
INSERT INTO public."InvoiceStatus" VALUES ('72507e94-b5d0-5e83-acdd-f238a6b71eb4', 'Harry Roob');
INSERT INTO public."InvoiceStatus" VALUES ('f6b9be58-b392-5cfb-b735-44eb000891f1', 'Bulah Sporer');
INSERT INTO public."InvoiceStatus" VALUES ('2423fad6-6195-5f15-b487-59c7d4d300be', 'Elenora Yundt');
INSERT INTO public."InvoiceStatus" VALUES ('b0dde9c0-69c4-5163-ae66-dde59fe530ae', 'Abigail Haley');
INSERT INTO public."InvoiceStatus" VALUES ('661fa7a9-bc01-523b-a77a-483d2fa61488', 'Etha McLaughlin');
INSERT INTO public."InvoiceStatus" VALUES ('d68f6deb-a1a9-5ac0-8ba1-9a647b9adbe5', 'Roger Rogahn');
INSERT INTO public."InvoiceStatus" VALUES ('51d0d2fd-5ffb-5f17-88ea-a32488c49aae', 'Clementina Reinger');
INSERT INTO public."InvoiceStatus" VALUES ('33308aed-70aa-50b1-bfa9-15bfd484e84e', 'Gertrude Ondricka');
INSERT INTO public."InvoiceStatus" VALUES ('7038db53-4091-5728-aa10-c2297d72e65d', 'Vincenzo Grant');
INSERT INTO public."InvoiceStatus" VALUES ('ed844701-69aa-5169-9089-e4836e3073ff', 'Zack Keeling');
INSERT INTO public."InvoiceStatus" VALUES ('40fbd89e-e15a-5250-b247-a47de5624fa4', 'Jorge Breitenberg');
INSERT INTO public."InvoiceStatus" VALUES ('cbf8ca5e-625e-5311-bf9c-44c9468bf915', 'Perry Witting');
INSERT INTO public."InvoiceStatus" VALUES ('59f15cf8-0010-5f56-90d3-96133548de73', 'Miles Goyette');
INSERT INTO public."InvoiceStatus" VALUES ('e07ccc01-c586-552e-9ae0-eb2e502a6ee4', 'Anita Stehr');
INSERT INTO public."InvoiceStatus" VALUES ('696f50d5-dc22-5533-b16c-b1cb209549a2', 'Orval Carter');
INSERT INTO public."InvoiceStatus" VALUES ('94c47c29-165f-5a5e-a330-38c6baf6f574', 'Estel Wolf');
INSERT INTO public."InvoiceStatus" VALUES ('6ed97a6f-a11e-59b2-b5bf-1bb0d370914a', 'Bobby Schuster');
INSERT INTO public."InvoiceStatus" VALUES ('77fb52ad-09c9-5c55-9ac1-1b52b2fcf2f4', 'Mariam Lesch');
INSERT INTO public."InvoiceStatus" VALUES ('d5138f03-9ac5-5622-a322-46a1787c7b01', 'Brent Schulist');
INSERT INTO public."InvoiceStatus" VALUES ('2a65569a-1d55-5344-870a-b19e25aa282e', 'Samanta Kunze');
INSERT INTO public."InvoiceStatus" VALUES ('e87bccc0-c090-56f8-80e8-a205ff1e63ab', 'Lilian Auer');
INSERT INTO public."InvoiceStatus" VALUES ('9c943ae4-da66-5185-8e24-0137acca43d1', 'Elissa Blick');
INSERT INTO public."InvoiceStatus" VALUES ('acb59451-0b3a-51c7-90bc-6292bdd607b3', 'Kianna Mante');
INSERT INTO public."InvoiceStatus" VALUES ('7e7f1811-74c4-5d08-943c-483bf52907d4', 'Judy O''Keefe');
INSERT INTO public."InvoiceStatus" VALUES ('d78d0862-44d7-578b-94b1-932642faf4f2', 'Thea Zieme');
INSERT INTO public."InvoiceStatus" VALUES ('72576540-8005-596a-b4c5-8d7dec32df79', 'Oceane Connelly');
INSERT INTO public."InvoiceStatus" VALUES ('5da05a65-3d16-5c52-a307-ac374def2ede', 'Rosemarie Reynolds');
INSERT INTO public."InvoiceStatus" VALUES ('8e1472c3-8809-58c7-bd19-e237cd98c249', 'Ashley Rau');
INSERT INTO public."InvoiceStatus" VALUES ('869bf749-fb7f-59cb-8351-a70b44a45e05', 'Victor Abshire');
INSERT INTO public."InvoiceStatus" VALUES ('6583b364-c73b-5157-b8ab-e85761f671ec', 'Addison Moen');
INSERT INTO public."InvoiceStatus" VALUES ('3797b9df-d0ef-5caf-95e6-2ee40ddf1e56', 'Lila Zulauf');
INSERT INTO public."InvoiceStatus" VALUES ('82ac512d-3ce1-575c-8529-5eab1303bd19', 'Ludie Carter');
INSERT INTO public."InvoiceStatus" VALUES ('d4474383-5e2b-5a76-9959-aef4c14ea31f', 'Brad Ferry');
INSERT INTO public."InvoiceStatus" VALUES ('3c9c1d48-4382-5a9c-9fc8-ef7a2dffef75', 'Ramiro Yundt');
INSERT INTO public."InvoiceStatus" VALUES ('3f26f3d6-d185-553f-a644-ea3f7d93955f', 'Abby Murray');
INSERT INTO public."InvoiceStatus" VALUES ('567336cc-b1ff-567d-88fa-bac3ed04c97c', 'Lelah Predovic');
INSERT INTO public."InvoiceStatus" VALUES ('a3db8946-4812-58be-b66b-8fe06b6f1ea9', 'Fiona Littel');
INSERT INTO public."InvoiceStatus" VALUES ('3d70aba8-7a1f-5215-81dc-47de761b9dff', 'Frankie Spinka');
INSERT INTO public."InvoiceStatus" VALUES ('14ee0773-4647-52d0-9c73-7072a3d637ed', 'Bo Smith');
INSERT INTO public."InvoiceStatus" VALUES ('ac1adbc8-0b5f-5223-a44c-e33fdf1decfe', 'Jackson Gulgowski');
INSERT INTO public."InvoiceStatus" VALUES ('57877cb2-266b-5b3f-b311-732830727e1b', 'Nicola Baumbach');
INSERT INTO public."InvoiceStatus" VALUES ('fe19bd75-c574-5cf1-b307-c66b83c04fa2', 'Angela Pfannerstill');
INSERT INTO public."InvoiceStatus" VALUES ('f5d018f2-a225-5a84-bdc2-238db780c834', 'Dustin Zieme');
INSERT INTO public."InvoiceStatus" VALUES ('ab8a7a2e-9cbd-5c6b-a07c-115f99d0f65a', 'Althea Stokes');
INSERT INTO public."InvoiceStatus" VALUES ('d4ec15ff-4fcc-5850-9646-31226b72b663', 'Lesley Kris');
INSERT INTO public."InvoiceStatus" VALUES ('4233ca78-4097-5cd3-9ab6-a737b2711e45', 'Carol Medhurst');
INSERT INTO public."InvoiceStatus" VALUES ('c88b0a2a-75b6-5535-a97c-0a12b371ec57', 'Alessandra Dibbert');
INSERT INTO public."InvoiceStatus" VALUES ('35ca2f56-7e1e-52f3-a4a6-05fe7ab2e849', 'Alden Bauch');
INSERT INTO public."InvoiceStatus" VALUES ('362eff21-4af8-506c-aabe-697192a66a83', 'Bettie McGlynn');
INSERT INTO public."InvoiceStatus" VALUES ('fe2d9572-c852-5051-9cef-3ef924153397', 'Shanna Stanton');
INSERT INTO public."InvoiceStatus" VALUES ('fbb7817c-4153-5e77-ac6f-780be833a603', 'Lily Barrows');
INSERT INTO public."InvoiceStatus" VALUES ('eb47f5b0-b0e4-55d2-b40c-a13034bb408b', 'Jace Senger');
INSERT INTO public."InvoiceStatus" VALUES ('77dc2613-894b-56ad-a27e-85e3922609f7', 'Deontae Miller');
INSERT INTO public."InvoiceStatus" VALUES ('76d7c27f-938c-50bd-85cf-97918f709c8b', 'Samara Purdy');
INSERT INTO public."InvoiceStatus" VALUES ('0f68bb51-085f-5543-8c5e-2b7b2e4dad82', 'Katelynn Connelly');
INSERT INTO public."InvoiceStatus" VALUES ('d874e5ba-2da4-5f58-b56b-40babc6311d8', 'Stevie Miller');
INSERT INTO public."InvoiceStatus" VALUES ('9f7086f5-72ae-5709-9b10-68134b151991', 'Maxime Bogan');


--
-- TOC entry 4236 (class 0 OID 2148855)
-- Dependencies: 228
-- Data for Name: InvoiceType; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."InvoiceType" VALUES ('c3665bb0-9b4e-5736-a61f-ba203226afd2', 'Lyric Shields');
INSERT INTO public."InvoiceType" VALUES ('2380e136-3e08-5b30-9640-6d74af75fa99', 'Kasey Doyle');
INSERT INTO public."InvoiceType" VALUES ('760bc561-2082-528c-9268-826f49fd8c6e', 'Garry Douglas');
INSERT INTO public."InvoiceType" VALUES ('919caa1f-be4d-5335-a835-601ce5b75a65', 'Brooklyn Homenick');
INSERT INTO public."InvoiceType" VALUES ('68fd2ec8-ecdc-5ec3-a206-9ea83f162d36', 'Talon Moen');
INSERT INTO public."InvoiceType" VALUES ('d69aaf00-10f9-5d41-989c-a03aaffc2dc4', 'Candice Heathcote');
INSERT INTO public."InvoiceType" VALUES ('b4103acb-fd50-540e-95cf-c019ca508829', 'Grayce Ferry');
INSERT INTO public."InvoiceType" VALUES ('d8a64e32-4db7-5626-89aa-5a12c877c9d3', 'Alyson Welch');


--
-- TOC entry 4237 (class 0 OID 2148860)
-- Dependencies: 229
-- Data for Name: Locker; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4238 (class 0 OID 2148867)
-- Dependencies: 230
-- Data for Name: LockerEvent; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4239 (class 0 OID 2148873)
-- Dependencies: 231
-- Data for Name: MailAttachment; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."MailAttachment" VALUES ('a6939617-ae0d-5f47-a4e9-f028d9665710', 'Emerson McDermott', '2020-10-06T21:27:30.000Z', 'Sovi sorako', '9ee2646c-5094-5b6c-ba4d-f902d1fdbe79', NULL, '2022-09-29 15:06:44.663', '1982-03-03 02:18:01', '2020-06-14 05:38:33', 'Soavi viso', '1992-09-21 20:39:27', 'Johnnie Ryan');
INSERT INTO public."MailAttachment" VALUES ('44f69bec-bd39-5943-841e-553334dc1098', 'Deborah Johns', '2020-09-17T08:35:54.000Z', 'Rasovia yumisoyu', 'e6e0ff8a-3dd7-50b4-a8f8-e91682529dad', NULL, '2022-09-29 15:06:44.663', '1994-03-07 14:15:30', '2020-09-25 08:35:40', 'Viraviso yuviko miso', '1993-10-18 21:34:20', 'Jazmin Zulauf');
INSERT INTO public."MailAttachment" VALUES ('2f406748-95e3-5768-95e2-f28d54822eba', 'Oda Quitzon', '2020-02-02T13:57:25.000Z', 'Yurayu koyu', '50b94de0-7666-5d9b-b9a0-399fd97489c4', NULL, '2022-09-29 15:06:44.663', '1995-08-04 07:59:22', '2020-10-18 10:04:24', 'Viso raviavi somia', '2012-01-17 00:20:05', 'Dawson Brakus');
INSERT INTO public."MailAttachment" VALUES ('cce9c668-0eb0-511d-9416-f9628a843a42', 'Erna Franecki', '2020-09-25T20:36:37.000Z', 'Ramiko miko sorakovi', '9ab4057d-67d8-5ef1-91f2-d7dfb90723b7', NULL, '2022-09-29 15:06:44.663', '1994-07-15 06:54:14', '2020-05-21 16:16:41', 'Kora rakora', '2008-09-13 20:20:06', 'Sandy Metz');
INSERT INTO public."MailAttachment" VALUES ('0fdb7150-c954-5f18-8732-b0ffe1d6e47a', 'Irma Crist', '2020-02-10T01:16:26.000Z', 'Visomi somirayu soravi', '719cb794-c63f-5b03-8323-de3ffb39816a', NULL, '2022-09-29 15:06:44.663', '1991-04-04 04:03:39', '2020-05-01 16:41:45', 'Soyu koakora', '2009-06-06 05:37:57', 'Ashton Schulist');
INSERT INTO public."MailAttachment" VALUES ('6b443a19-0cb8-562b-9427-08bfed9e97d3', 'Cristian Hoppe', '2020-03-03T02:16:01.000Z', 'Raso mikomi', '2eab6eb7-51f4-57fc-b76e-fd31cc088459', NULL, '2022-09-29 15:06:44.663', '2007-08-28 19:09:26', '2020-03-27 14:14:48', 'Viso soyuko', '1986-03-15 14:34:38', 'Raphael Bahringer');
INSERT INTO public."MailAttachment" VALUES ('dc5b722a-67a0-5f4d-91fd-309016a65dba', 'Michel Koelpin', '2020-09-25T09:06:26.000Z', 'Korasoyu yuvira mia', '99894cff-13f3-522b-9d64-e4b13016f262', NULL, '2022-09-29 15:06:44.663', '1996-01-21 00:36:06', '2020-04-28 15:56:21', 'Sorako yumi vikoyua', '1999-04-28 03:54:02', 'Wilfrid Klein');
INSERT INTO public."MailAttachment" VALUES ('b4d772f5-bbef-5dc3-b2b7-8004e65f56d9', 'Cierra Pacocha', '2020-12-12T11:55:14.000Z', 'Sora visoyuko rami', '25023ab7-cb5d-5380-a5db-06cf430801bf', NULL, '2022-09-29 15:06:44.663', '1993-02-18 13:23:19', '2020-08-28 19:49:59', 'Vikovira yuvi soyuvira', '2009-02-02 13:52:17', 'Fletcher Hackett');
INSERT INTO public."MailAttachment" VALUES ('9c6b5ebc-5bd0-53d0-992c-64c303c8db2b', 'Ethan Stark', '2020-04-12T15:14:44.000Z', 'Koyukomi viyu', 'cf98874a-15a7-527f-a63f-e70f98e63d0e', NULL, '2022-09-29 15:06:44.663', '2012-01-25 00:25:49', '2020-09-01 20:46:06', 'Yukomi yua viayu', '1984-05-25 04:17:14', 'Stefan Muller');
INSERT INTO public."MailAttachment" VALUES ('554ddf3f-25bf-56aa-9b1d-2bd3eee83c23', 'Jillian Stamm', '2020-06-02T05:57:00.000Z', 'Sorakoyu somiko', 'b6a89c96-3460-5fb7-92ad-9979f0ff6c71', NULL, '2022-09-29 15:06:44.663', '1988-09-01 08:16:31', '2020-11-15 10:34:42', 'Koayu yumi ramia', '2015-08-08 20:08:18', 'Laurie Cartwright');
INSERT INTO public."MailAttachment" VALUES ('0b501bfa-d142-558e-8149-4baf6d349576', 'Chad Kunde', '2020-05-21T16:07:43.000Z', 'Miso soyuvi somi', '09d9f60a-957f-5d4f-a0fe-23732bb68121', NULL, '2022-09-29 15:06:44.663', '1992-09-21 20:37:14', '2020-05-13 04:11:05', 'Yusomiyu sovi', '2012-01-05 00:14:03', 'Amber Ortiz');
INSERT INTO public."MailAttachment" VALUES ('a2ed68b2-88a7-5808-b21b-dcbcac3d70b8', 'Chloe Gaylord', '2020-01-21T12:02:19.000Z', 'Yuviso somiyumi somisoa', '0af97eb0-6018-5520-9528-d5b0c222408b', NULL, '2022-09-29 15:06:44.663', '2015-04-16 03:21:12', '2020-03-27 14:05:42', 'Ramikovi koyumi', '1994-07-23 06:55:32', 'Shannon Bechtelar');
INSERT INTO public."MailAttachment" VALUES ('12c6ee29-f48f-5143-913e-5ffdefb5c596', 'Melany Little', '2020-11-11T11:13:55.000Z', 'Yukoa somiraso koviko', '085007e9-cada-5187-99a2-4af12ca1b64b', NULL, '2022-09-29 15:06:44.663', '1988-09-05 08:08:46', '2020-07-27 18:19:02', 'Sora koakomi raviyu', '1984-01-05 12:38:32', 'Nels Crist');
INSERT INTO public."MailAttachment" VALUES ('edabb7e1-5e96-553b-b790-69a96e675886', 'Mariano Hessel', '2020-01-25T12:08:55.000Z', 'Komiyuko viko visoavi', 'fc85f28d-0125-59a6-8980-92b9b7c5f2b9', NULL, '2022-09-29 15:06:44.663', '1984-09-17 20:47:04', '2020-09-17 20:16:40', 'Miyua viyuvi raviyumi', '2000-01-17 12:02:08', 'Myles Ratke');
INSERT INTO public."MailAttachment" VALUES ('db70bada-07b1-5643-aa4f-ae75a3520ad0', 'Shyanne Carter', '2020-09-13T20:32:40.000Z', 'Misoviko yuramia', 'ff6500df-6a2e-59c7-87d8-5919ecbc2d89', NULL, '2022-09-29 15:06:44.663', '1989-06-10 17:35:06', '2020-09-09 08:19:41', 'Viyu koyuko miyu', '1996-05-25 16:18:23', 'Jonatan Mohr');
INSERT INTO public."MailAttachment" VALUES ('432a5667-bf94-5fff-b0f3-f408242f7b1f', 'Carmine Olson', '2020-11-27T10:11:15.000Z', 'Visoyu rasoako', 'd56f5a53-372f-546a-9238-1c8b16b4a45b', NULL, '2022-09-29 15:06:44.663', '1993-06-06 06:08:43', '2020-05-05 04:42:25', 'Miramiso koasoa korakoa', '1980-01-17 00:08:05', 'Enrique Cole');
INSERT INTO public."MailAttachment" VALUES ('48376088-758a-5e09-814a-697fb5600552', 'Claudia Wunsch', '2020-09-09T08:56:23.000Z', 'Rasoviko soa yusomiyu', '42382b2a-23a5-5ad5-a485-13d44a9bc460', NULL, '2022-09-29 15:06:44.663', '1982-11-19 10:33:30', '2020-09-05 20:24:03', 'Koa mikomiso', '1981-06-02 17:48:57', 'Johnny Shields');
INSERT INTO public."MailAttachment" VALUES ('0bb21bd3-d512-55a6-b042-ea5acc57b8de', 'Catharine Harvey', '2020-02-26T13:11:20.000Z', 'Yuravi komirako', '1651cfba-413a-5783-9436-6b439aeff33f', NULL, '2022-09-29 15:06:44.663', '1982-11-27 10:33:17', '2020-06-18 17:29:31', 'Komiso vira', '2007-08-28 19:07:13', 'Josianne Nitzsche');
INSERT INTO public."MailAttachment" VALUES ('560b9196-3cbf-5173-a792-139b21623b12', 'Tremayne Hamill', '2020-02-02T14:02:47.000Z', 'Soavi soyu', 'd5cc0e7f-aec6-5adb-9fe0-026a138c7179', NULL, '2022-09-29 15:06:44.663', '1989-06-26 17:32:48', '2020-09-09 20:17:21', 'Somiaso somikovi', '1993-10-06 21:34:29', 'Eliane Waelchi');
INSERT INTO public."MailAttachment" VALUES ('b6431ce9-5eab-56b2-bfb5-993fef1ef699', 'Estevan Mraz', '2020-09-25T21:00:30.000Z', 'Miyu mikoa', '9a4e8777-2c03-53b7-a252-a9466985d44e', NULL, '2022-09-29 15:06:44.663', '2003-12-20 23:34:24', '2020-07-03 18:36:06', 'Kora yumisora', '2017-10-06 22:00:14', 'Krystina Botsford');
INSERT INTO public."MailAttachment" VALUES ('4a79a564-93c0-5252-8fdb-5dc5cd210cf0', 'Dax Maggio', '2020-05-09T16:18:22.000Z', 'Soa miraviyu', '8f45dd79-62c8-5ef1-b86c-2be9f6cbdb03', NULL, '2022-09-29 15:06:44.663', '2017-02-02 13:46:21', '2020-06-18 05:41:45', 'Sovi visoavi', '1996-05-17 16:23:16', 'Stevie Cormier');
INSERT INTO public."MailAttachment" VALUES ('a255e84f-a827-59e4-acbd-622bd4e15cfe', 'Buck Swift', '2020-11-19T22:47:36.000Z', 'Yuso miaviko kora', '57d4229b-9f89-5e6c-9824-9fdca645cac6', NULL, '2022-09-29 15:06:44.663', '2008-09-21 20:23:09', '2020-02-22 01:02:31', 'Miyusoa miyumi', '1989-10-18 09:11:23', 'Laura Schroeder');
INSERT INTO public."MailAttachment" VALUES ('be036646-f5a9-5ff6-a644-8ac4bfb0e9e4', 'Bailey Schimmel', '2020-12-08T11:18:42.000Z', 'Visorayu soyuso', '457cd54d-5e1f-5eeb-86bd-3470ab74fbea', NULL, '2022-09-29 15:06:44.663', '2006-11-19 10:58:12', '2020-01-01 00:51:16', 'Mirami yua raviko', '2001-06-10 05:50:43', 'Darius Mitchell');
INSERT INTO public."MailAttachment" VALUES ('890b2135-e44b-5ad5-b950-cf053e4e2b8d', 'Javon D''Amore', '2020-11-27T11:01:42.000Z', 'Viso soyuso', '108e5cb5-22cd-57b0-966b-54258cc53a3f', NULL, '2022-09-29 15:06:44.663', '1991-04-24 03:58:44', '2020-08-04 20:07:53', 'Rako soakomi miyu', '2008-01-09 12:51:03', 'Hyman Haag');
INSERT INTO public."MailAttachment" VALUES ('255df4bc-a27a-5352-aa07-ed87570112f6', 'Kaycee Franecki', '2020-11-11T10:40:56.000Z', 'Yuso miyumiso', 'ee2f7063-9932-579c-81ed-20aca16ef9f6', NULL, '2022-09-29 15:06:44.663', '1992-05-25 04:52:59', '2020-01-09 00:26:35', 'Yuravira yukomi yuko', '2001-06-22 05:54:32', 'Jovani Mertz');
INSERT INTO public."MailAttachment" VALUES ('488d4659-0b20-5f41-ba7d-3f175f486464', 'Nicklaus Kling', '2020-07-03T06:37:37.000Z', 'Visovi yura', 'f92b8d04-959c-5735-842f-9ceb9655c1ac', NULL, '2022-09-29 15:06:44.663', '2008-09-13 20:13:55', '2020-11-23 22:41:15', 'Yukoyu miko koviako', '2004-09-21 08:52:02', 'Samir Morar');
INSERT INTO public."MailAttachment" VALUES ('2f6c310e-fc41-588b-872f-c84fda18be9c', 'Myrtice Gutkowski', '2020-11-03T23:01:33.000Z', 'Korakovi koraso vira', '16e8a149-f550-5db2-8b33-5d502a4cd4a1', NULL, '2022-09-29 15:06:44.663', '1980-05-17 16:41:12', '2020-08-28 08:07:21', 'Komiyu yurasoyu viso', '1986-07-03 06:10:00', 'Elton Gutmann');
INSERT INTO public."MailAttachment" VALUES ('268d932d-4e4b-509b-92e6-e0dc640368b5', 'Ethyl Bergstrom', '2020-05-05T16:35:18.000Z', 'Vira yumira viayuvi', '6c390c40-0c13-5378-80c0-6a7b8f7edc21', NULL, '2022-09-29 15:06:44.663', '2008-09-01 20:10:13', '2020-04-24 15:09:06', 'Koasovi komiyu visoraso', '1981-06-06 17:45:52', 'Loy Gusikowski');
INSERT INTO public."MailAttachment" VALUES ('c7233c7c-a01c-545e-b09b-531c9820fcf0', 'Richmond Glover', '2020-06-10T17:23:20.000Z', 'Sovikoyu kora', '946c23e5-be51-5585-8520-31315ffa5937', NULL, '2022-09-29 15:06:44.663', '2018-07-19 06:26:56', '2020-07-07 07:09:23', 'Rayu yuvia', '2012-09-05 08:34:17', 'Robin Zieme');
INSERT INTO public."MailAttachment" VALUES ('eedbd66c-911d-5030-bb1d-1624c38cc179', 'Elfrieda Hintz', '2020-01-13T12:06:51.000Z', 'Soviko raso koviraso', '384b43b1-fd80-5c29-93e5-7d6cf37f5ea2', NULL, '2022-09-29 15:06:44.663', '2001-10-26 21:23:59', '2020-06-14 05:09:04', 'Koami vira', '2005-10-22 09:52:07', 'Dianna Muller');
INSERT INTO public."MailAttachment" VALUES ('9d73da82-02ad-58b9-98bb-12437e7ce8aa', 'Nicole Murphy', '2020-09-17T20:56:59.000Z', 'Misomi raso', 'b772995e-049b-53aa-8211-4b4d5b460572', NULL, '2022-09-29 15:06:44.663', '2010-07-27 06:44:33', '2020-12-24 23:41:48', 'Kovi yuami', '2001-02-06 13:04:42', 'Hilario Hayes');
INSERT INTO public."MailAttachment" VALUES ('b1790107-a0fe-50be-a871-bb5d443fc23b', 'Garrett Collier', '2020-03-23T14:22:32.000Z', 'Viaso rayu', '2f8978fc-8c47-5861-b9e2-a00ac15f9d59', NULL, '2022-09-29 15:06:44.663', '1990-11-07 10:10:34', '2020-02-18 13:23:40', 'Yurayu yusorako', '2001-10-18 21:28:38', 'Alena Kassulke');
INSERT INTO public."MailAttachment" VALUES ('5c4df830-1017-564a-aaa6-cc9e2036fda1', 'Elna Muller', '2020-06-26T05:43:10.000Z', 'Virayu visomiyu', '8d547814-42c3-56e5-8997-41dd4242dcf2', NULL, '2022-09-29 15:06:44.663', '2014-11-03 10:40:20', '2020-08-16 07:29:38', 'Mikoravi koviami mia', '1982-11-07 10:31:05', 'Mason Hoeger');
INSERT INTO public."MailAttachment" VALUES ('a83cd227-77e7-5362-8d65-bccfb690c532', 'Neva Kiehn', '2020-12-24T23:24:47.000Z', 'Viaso miyumia', '7b29a9d4-1cf3-5922-8dbf-f83a4c8f6b62', NULL, '2022-09-29 15:06:44.663', '1998-03-19 02:53:07', '2020-11-19 22:19:10', 'Yuayuso misoviyu', '1988-09-01 08:12:54', 'Mohammad Nienow');
INSERT INTO public."MailAttachment" VALUES ('efd4a4f0-1ec2-5391-b300-949942b3a07e', 'Shemar Keebler', '2020-07-15T06:59:43.000Z', 'Rasoyuko komi', '4a504503-ade8-5272-97cf-0eebf4a7c1df', NULL, '2022-09-29 15:06:44.663', '1988-01-09 00:50:35', '2020-01-25 12:38:30', 'Kovira yuso', '1998-11-19 11:03:47', 'Veda Jacobs');
INSERT INTO public."MailAttachment" VALUES ('cc4c47a9-c2f7-5d05-b700-bc3ad969d420', 'Glenda Boehm', '2020-01-17T12:07:58.000Z', 'Koyu yusoyuvi', '83ff5e1d-3ccf-5ca3-9019-c1c8d1e4f25b', NULL, '2022-09-29 15:06:44.663', '2014-03-11 02:20:07', '2020-03-19 02:26:53', 'Kora yukoa', '1983-12-20 11:28:55', 'Elsa Sauer');
INSERT INTO public."MailAttachment" VALUES ('657bc7da-b3cc-5fbd-9121-9473cf45e8ce', 'Robin Beer', '2020-03-27T14:33:05.000Z', 'Vikovia koravira mikoa', 'f4ae534b-a04d-5837-99c3-46e60e6e01b4', NULL, '2022-09-29 15:06:44.663', '1994-07-19 07:02:49', '2020-10-06 21:31:14', 'Koami rasovi koyu', '2016-09-21 20:58:47', 'Karine Sawayn');
INSERT INTO public."MailAttachment" VALUES ('6029aed8-cdf7-591b-84b0-875eb728deb6', 'Cathrine Daugherty', '2020-12-04T11:39:50.000Z', 'Raviko koami', 'fb9f2572-806b-5320-9fc9-677c21976872', NULL, '2022-09-29 15:06:44.663', '2007-12-28 11:57:22', '2020-07-23 18:19:05', 'Kovikoyu yua', '1990-11-11 10:22:18', 'Jakob Spencer');
INSERT INTO public."MailAttachment" VALUES ('f33c85ee-788b-5a26-924a-b6ddb5a3209f', 'Chaz Leannon', '2020-02-26T01:25:25.000Z', 'Yukoa sora', 'e16d4441-51dd-5ac3-8aae-b8cb9a12ada6', NULL, '2022-09-29 15:06:44.663', '1980-09-01 08:31:47', '2020-05-13 04:37:18', 'Vikoyu yumi', '2011-04-20 15:55:38', 'Asia Ward');
INSERT INTO public."MailAttachment" VALUES ('b4ec8736-3b1b-5392-bc9f-578b4fd784cf', 'Anastacio Klein', '2020-01-01T12:54:18.000Z', 'Yumiyuko rami', '5cb414f4-ffe5-5b1e-8e2b-9e5160016730', NULL, '2022-09-29 15:06:44.663', '1985-02-02 13:40:25', '2020-03-11 02:03:41', 'Komia yuso', '2003-12-16 23:34:27', 'Marjolaine Lynch');
INSERT INTO public."MailAttachment" VALUES ('9435f2e8-dc1e-522c-ae4c-af3feebb3166', 'Mozell O''Conner', '2020-02-22T13:17:05.000Z', 'Via korasoa', '3ba7daec-f35d-5953-807c-c38471fb3361', NULL, '2022-09-29 15:06:44.663', '2001-06-06 05:42:15', '2020-02-26 13:03:24', 'Mirako viko misoyua', '1989-06-18 17:43:45', 'Mary Thiel');
INSERT INTO public."MailAttachment" VALUES ('46fac714-c756-5ce9-a536-c8ff9c3325b7', 'Kayley Olson', '2020-01-13T12:42:44.000Z', 'Ravira visoyuvi', '3f8295a9-9489-57e4-b095-3170c646e6a8', NULL, '2022-09-29 15:06:44.663', '2019-12-29 00:05:52', '2020-07-07 06:06:27', 'Viako soa raviso', '1993-02-02 13:22:07', 'Aron Cummerata');
INSERT INTO public."MailAttachment" VALUES ('adb594f2-7c82-529d-b2e8-73ab07069221', 'Yvette Douglas', '2020-12-25T00:00:13.000Z', 'Mirako yuko koayu', '067d1468-e93d-585e-83ff-55938aca5a4b', NULL, '2022-09-29 15:06:44.663', '2010-07-23 06:33:24', '2020-08-28 07:14:34', 'Sorayu rayuaso', '1985-06-10 05:16:00', 'Lina Bashirian');
INSERT INTO public."MailAttachment" VALUES ('bc7c147e-0fcc-5b95-8ebc-0a54fd5cc01f', 'Susanna Emard', '2020-02-14T01:39:55.000Z', 'Koviyu yua', '0db962d7-3bf5-5e42-84f5-8121f1f15869', NULL, '2022-09-29 15:06:44.663', '2001-02-02 13:06:09', '2020-05-13 16:56:11', 'Soyura raso yuayu', '2010-11-15 22:25:10', 'Marcella Jaskolski');
INSERT INTO public."MailAttachment" VALUES ('55f1fb10-8710-5b63-88b1-1ebb30254640', 'Van Kessler', '2020-09-25T08:58:10.000Z', 'Rako soakoa', '49e7428f-9b5b-596e-bf24-9f82f74b3db3', NULL, '2022-09-29 15:06:44.663', '1990-03-23 03:02:37', '2020-04-28 03:29:47', 'Viko yumiso rami', '1985-10-02 21:45:57', 'Meagan Lockman');
INSERT INTO public."MailAttachment" VALUES ('1cab70eb-dfc1-51c9-9c05-6ce8a1591e65', 'Amelie Jakubowski', '2020-08-20T19:27:50.000Z', 'Mira viakomi', '2a65786c-e198-5883-8ca7-3da376a6d48d', NULL, '2022-09-29 15:06:44.663', '2016-09-21 20:56:27', '2020-06-10 17:23:34', 'Koyukovi somiso viayu', '2016-09-21 21:05:19', 'Kirsten Schulist');
INSERT INTO public."MailAttachment" VALUES ('fc93911c-a4e2-5295-8ed6-90e6ab99a51e', 'Domenick Auer', '2020-09-09T20:58:42.000Z', 'Koviso koami koyuso', '37715b10-4932-54de-966b-e38c819a8629', NULL, '2022-09-29 15:06:44.663', '2003-12-04 23:35:53', '2020-12-12 23:35:39', 'Komiko soyu', '2019-04-12 15:41:52', 'Toy Quitzon');
INSERT INTO public."MailAttachment" VALUES ('0c9bb86f-3cb2-5b91-a02e-e03945890e5a', 'Cathryn Brakus', '2020-03-07T15:04:20.000Z', 'Yua yura', '8c24e360-ca2e-547e-a192-5b0926800726', NULL, '2022-09-29 15:06:44.663', '1990-03-27 02:53:21', '2020-04-04 15:26:57', 'Vikoa komisora', '1994-03-19 14:15:49', 'Jennifer Mertz');
INSERT INTO public."MailAttachment" VALUES ('40b532c9-0935-5061-8e8b-f1563f690ce0', 'Flossie Hauck', '2020-04-12T03:56:05.000Z', 'Yuvisora visovi', '71cc1dc7-4fdd-5981-9714-1fa739ca6f50', NULL, '2022-09-29 15:06:44.663', '2014-03-19 02:16:45', '2020-09-17 08:18:53', 'Viakovi rayuko', '1984-01-13 12:37:51', 'Carmella Kilback');
INSERT INTO public."MailAttachment" VALUES ('73958d4c-cd7f-5246-9282-4ceabad9fe52', 'Raegan Crooks', '2020-04-04T15:41:58.000Z', 'Koa yumiyu via', '05f1387f-a3c5-5de3-8b2b-b783f876444f', NULL, '2022-09-29 15:06:44.663', '2014-03-11 02:18:29', '2020-03-19 02:47:59', 'Viyumiso vikora', '1984-09-17 20:47:39', 'Bret Spinka');
INSERT INTO public."MailAttachment" VALUES ('f1143dcb-c7ac-540c-ae6c-b9d8441a938b', 'Vito Stiedemann', '2020-03-03T14:05:04.000Z', 'Sovi yuakovi viko', '82a287d1-d8c6-58e3-a00e-72adec930f63', NULL, '2022-09-29 15:06:44.663', '2007-04-08 03:42:24', '2020-11-23 22:46:37', 'Viyura viravira', '1982-11-11 10:30:41', 'Aurelie Ratke');
INSERT INTO public."MailAttachment" VALUES ('ddbd6606-90d6-5e41-997c-20b2063f5a02', 'Eldred Boyer', '2020-05-25T16:05:48.000Z', 'Rami visoa viyu', '19cee7c8-ccf3-5a8b-9411-18a54e12d47c', NULL, '2022-09-29 15:06:44.663', '1991-08-28 19:40:40', '2020-06-14 05:59:52', 'Yusoyua viko', '1989-06-06 17:45:25', 'Lawson Ratke');
INSERT INTO public."MailAttachment" VALUES ('b4ea0c1e-27f9-58f8-8a29-2f6943cf4db1', 'Deja Lind', '2020-10-02T09:10:18.000Z', 'Koviami sovia yusoyura', '14fd52af-7c0a-5a2d-be0b-6ddc20697d78', NULL, '2022-09-29 15:06:44.663', '2004-09-01 08:53:06', '2020-04-12 03:12:38', 'Somiayu yuvira', '1997-10-06 10:12:01', 'Alene Douglas');
INSERT INTO public."MailAttachment" VALUES ('4592f9bf-52e1-5a1c-a83d-3ef844caea77', 'Amya Brakus', '2020-10-26T09:57:19.000Z', 'Vikomira komiko', 'd41b5ad0-430e-5043-acbc-a8b3b904df57', NULL, '2022-09-29 15:06:44.663', '1986-03-15 14:31:15', '2020-02-18 13:34:44', 'Yuvi misoa', '2017-06-14 05:20:43', 'Clotilde Altenwerth');
INSERT INTO public."MailAttachment" VALUES ('3277c964-fe51-5794-8c51-3785ebf4abc6', 'Miguel Purdy', '2020-02-22T13:24:40.000Z', 'Komiyu soako', '7e20f5f8-db38-5ec7-a07c-a454a72fb727', NULL, '2022-09-29 15:06:44.663', '2010-07-23 06:44:50', '2020-07-19 06:51:52', 'Via soyuvia soyuviko', '1982-11-07 10:27:00', 'Simone Mann');
INSERT INTO public."MailAttachment" VALUES ('300ceac7-445c-59a0-a7b0-c980d0990467', 'Kaden Quitzon', '2020-12-12T23:35:33.000Z', 'Raviko yumi', '6f1771b0-10b0-51fd-920b-aa31e4e04336', NULL, '2022-09-29 15:06:44.663', '1990-03-19 03:05:42', '2020-07-15 18:49:21', 'Yura koviko soyu', '1992-05-25 05:03:50', 'Jaiden Kassulke');
INSERT INTO public."MailAttachment" VALUES ('7405ec2b-5ce8-5eb6-a2be-0cf547d4b0ae', 'Ronny Murazik', '2020-01-09T12:48:58.000Z', 'Raso yukoraso raso', '431db2c6-89ab-5e63-83ec-28194d3d625e', NULL, '2022-09-29 15:06:44.663', '1980-09-21 08:21:37', '2020-02-22 01:49:08', 'Yura miyusoyu yua', '1991-08-04 19:42:15', 'Deion Kerluke');
INSERT INTO public."MailAttachment" VALUES ('510fac7e-0f68-59c4-a94b-ac8b65587aa9', 'Wiley Upton', '2020-07-03T19:08:51.000Z', 'Raso yumiyuvi yuso', '577a003a-c568-51e6-b469-11235b4a432d', NULL, '2022-09-29 15:06:44.663', '1991-12-12 11:22:16', '2020-10-14 21:22:03', 'Yuso misora', '1986-03-11 14:35:51', 'Wilson Heaney');
INSERT INTO public."MailAttachment" VALUES ('f14d5007-20ee-57c0-a175-2af8d5073588', 'Eleazar Zboncak', '2020-09-25T08:55:36.000Z', 'Miravia koayu soyu', '2448ccf3-9c2d-5c6c-a1bd-f6cb0175b3a8', NULL, '2022-09-29 15:06:44.663', '1997-02-10 01:46:50', '2020-12-16 23:59:51', 'Mia yukoa', '1989-06-22 17:40:47', 'Evalyn Davis');
INSERT INTO public."MailAttachment" VALUES ('bfcf2b0c-9a37-5f9c-a583-04c7d41b5cc4', 'Gregoria Trantow', '2020-12-08T23:37:56.000Z', 'Raviraso yumi', '039d109a-3bde-5274-a8da-8d78493fa453', NULL, '2022-09-29 15:06:44.663', '2008-01-09 12:52:55', '2020-12-28 23:57:36', 'Miavia via rasoyuvi', '2000-05-05 04:49:17', 'Cynthia Crona');
INSERT INTO public."MailAttachment" VALUES ('a6f76c31-c23d-5396-9ac9-0b891edd8a9c', 'Tiara Douglas', '2020-02-14T13:35:43.000Z', 'Viko visorayu yuayura', '7bb901cc-6861-5723-82ab-906b19bba595', NULL, '2022-09-29 15:06:44.663', '1995-12-16 23:35:08', '2020-09-25 20:46:10', 'Misoavi rayumira', '2018-07-15 06:26:24', 'Jace Pfannerstill');
INSERT INTO public."MailAttachment" VALUES ('50a69664-6e2b-5c6c-ba80-f2ec09d7ba96', 'Asha Labadie', '2020-06-02T17:24:22.000Z', 'Rayuayu rayuko koayu', 'd508bf8b-94ae-5c89-8a66-047fb18bdbfd', NULL, '2022-09-29 15:06:44.663', '2017-02-10 13:48:07', '2020-10-18 09:11:44', 'Rakoviyu yuvi', '1984-01-05 12:30:50', 'Roma Ziemann');
INSERT INTO public."MailAttachment" VALUES ('a8899262-82a1-595d-910d-99c6440822b8', 'Shana Lakin', '2020-11-23T23:02:48.000Z', 'Miako mikomi', '6ebc81be-72fb-5b3a-abed-cffb552244d8', NULL, '2022-09-29 15:06:44.663', '2004-01-01 00:38:28', '2020-07-23 18:28:45', 'Komiaso rakomi kora', '2002-11-03 22:26:28', 'Abdul Collier');
INSERT INTO public."MailAttachment" VALUES ('61411242-e198-5a03-8082-949741d2c3aa', 'Casandra Runolfsdottir', '2020-10-18T21:24:47.000Z', 'Kovi yumiyu mikoravi', '97f75a1a-264a-525d-ad89-03e4fa053f2e', NULL, '2022-09-29 15:06:44.663', '1993-02-18 13:14:20', '2020-05-05 04:06:24', 'Yua rasoviso misomia', '1993-10-02 21:43:59', 'Orville Hoeger');
INSERT INTO public."MailAttachment" VALUES ('2631e490-6a84-5ca6-97bc-5f249fd4c7ae', 'Reymundo Hamill', '2020-10-06T09:55:49.000Z', 'Miyuvi yua', 'a797a8fb-5788-5c43-9d54-aad4b9dacfea', NULL, '2022-09-29 15:06:44.663', '2017-02-14 13:52:02', '2020-11-23 10:28:05', 'Yusorayu rayuvia yusovi', '2015-04-04 03:26:29', 'Tiana Jerde');
INSERT INTO public."MailAttachment" VALUES ('073563b8-31e7-56c9-8357-490eee9f07ac', 'Maryse Boyer', '2020-09-25T08:38:14.000Z', 'Vira soviso virakoa', '2436d429-a984-5a92-8d8a-2f39d7cb8d1a', NULL, '2022-09-29 15:06:44.663', '2012-09-13 08:48:25', '2020-06-18 17:50:23', 'Rayuvi viso', '2002-07-07 06:49:13', 'Shanie Schultz');
INSERT INTO public."MailAttachment" VALUES ('21871d69-1e0e-5677-8150-c7fee9f6edaf', 'Easton Swift', '2020-04-04T03:31:01.000Z', 'Komiami raso via', '116c9def-1245-5f17-ab5f-8287c47cc87a', NULL, '2022-09-29 15:06:44.663', '2009-06-10 05:44:26', '2020-07-15 18:16:51', 'Visora yuakomi yuravi', '1997-02-02 01:43:33', 'Janice Douglas');
INSERT INTO public."MailAttachment" VALUES ('f4e3db2c-dbc9-5d7d-bdb0-2cf53e102f7c', 'Roberto Koelpin', '2020-02-10T13:30:03.000Z', 'Yuraviyu ramiako', '197f84ee-4a4b-5bd5-959f-542082f2c345', NULL, '2022-09-29 15:06:44.663', '1987-04-20 15:33:58', '2020-04-12 03:34:46', 'Yuravi kovi', '1986-11-23 22:53:22', 'Casimer Bayer');
INSERT INTO public."MailAttachment" VALUES ('1777c98b-735e-53b9-a61a-61068e46e44f', 'Marilyne Schinner', '2020-01-21T00:25:51.000Z', 'Yumisovi rako raviso', '1f7c7015-10fc-543d-8d6c-ae0556ac4bb5', NULL, '2022-09-29 15:06:44.663', '1984-01-13 12:32:22', '2020-10-02 09:47:01', 'Rako misomi', '2016-05-25 04:21:32', 'Micaela Bailey');
INSERT INTO public."MailAttachment" VALUES ('98fc6b9b-d3b7-5cd3-8fcb-5d9c876f5aae', 'Tressie Boyer', '2020-11-07T22:27:49.000Z', 'Yuviso somi rayuraso', 'f0377acc-2dbb-5ce5-ac58-5f9e4967c6a6', NULL, '2022-09-29 15:06:44.663', '2000-09-25 20:21:06', '2020-01-21 00:37:17', 'Soyu rasovi soramiso', '1994-03-07 14:15:09', 'Keanu Nienow');
INSERT INTO public."MailAttachment" VALUES ('4d932cdf-1d84-55e5-8b6e-7c25df0e79fb', 'Ruthe Luettgen', '2020-09-09T20:15:57.000Z', 'Somia viaviso', 'a16d92f7-0984-5b21-9557-a76f5514463b', NULL, '2022-09-29 15:06:44.663', '1982-11-15 10:35:39', '2020-04-28 15:27:42', 'Rakora yuvirami miko', '1988-09-25 08:12:01', 'Angela Thiel');
INSERT INTO public."MailAttachment" VALUES ('7056f44a-e18e-58d4-a47e-6a1b350f7ab0', 'Deshaun Rolfson', '2020-01-01T00:47:33.000Z', 'Soasoa mirayura miaso', '77711cf6-f839-5774-810f-77042ebee6eb', NULL, '2022-09-29 15:06:44.663', '1995-08-04 08:06:22', '2020-08-16 08:05:10', 'Miko koraso misomiso', '1994-07-19 07:09:14', 'Jack Kiehn');
INSERT INTO public."MailAttachment" VALUES ('c68722f4-66e0-5eaf-bc84-db5764e9dd35', 'Imani Mohr', '2020-10-10T09:48:18.000Z', 'Misomiyu via', '631b1b11-020a-5ef0-a840-fd916d8d85a0', NULL, '2022-09-29 15:06:44.663', '2008-01-01 12:58:30', '2020-11-15 22:48:34', 'Koami koyuko', '2019-04-28 15:44:14', 'Camilla Sipes');
INSERT INTO public."MailAttachment" VALUES ('d6afa6e1-2421-5ce2-8558-5e736adf3363', 'Marian Douglas', '2020-02-06T01:56:12.000Z', 'Miyura vikomiyu', '4af3d75e-318c-5f91-baa8-6bdd3c7adf54', NULL, '2022-09-29 15:06:44.663', '1986-11-03 22:48:08', '2020-08-16 19:22:53', 'Sora ravia', '1982-11-27 10:29:47', 'Rita Runolfsdottir');
INSERT INTO public."MailAttachment" VALUES ('1bd369f7-002e-5a36-ae95-9e9100d132f1', 'Felix Bernhard', '2020-03-27T14:29:56.000Z', 'Raviyu miso koravi', '0955ad5a-aac2-548e-8151-62f3852792a6', NULL, '2022-09-29 15:06:44.663', '1989-10-06 09:14:34', '2020-09-09 08:32:43', 'Sora yua yumiko', '2003-08-12 07:47:16', 'Liza Schultz');
INSERT INTO public."MailAttachment" VALUES ('13d14431-3fb0-558e-9657-590383a95036', 'Maria Bauch', '2020-03-03T02:44:55.000Z', 'Ramisovi viayu miravia', '96840519-4d3e-5f23-bc83-749b16bfcd70', NULL, '2022-09-29 15:06:44.663', '2014-03-23 02:28:01', '2020-02-06 13:21:57', 'Soyua misora', '2000-01-25 12:11:01', 'Lydia Jerde');
INSERT INTO public."MailAttachment" VALUES ('ab915223-06c0-528a-97ea-586c5270bd6b', 'Ardella Anderson', '2020-12-08T23:49:49.000Z', 'Ramiayu rayu', '91eecf3c-498d-5aee-b32e-69c48fa10f33', NULL, '2022-09-29 15:06:44.663', '2005-10-18 09:50:25', '2020-08-24 19:45:16', 'Miso visoa', '2019-08-08 07:29:44', 'Melyna Kiehn');
INSERT INTO public."MailAttachment" VALUES ('65f049d5-db68-50db-a4a4-3c7fc6f36b8c', 'Cydney Anderson', '2020-06-10T05:48:37.000Z', 'Koa viko', '50903137-c795-5bb3-9191-a5f832f21bba', NULL, '2022-09-29 15:06:44.663', '2002-11-15 22:29:35', '2020-06-10 17:13:12', 'Viayu viso', '1980-01-17 00:04:56', 'Shirley O''Keefe');
INSERT INTO public."MailAttachment" VALUES ('f5339422-167a-5917-b73b-34b9f14d0a1c', 'Virgil Hoeger', '2020-02-22T13:13:28.000Z', 'Mikora viaviyu', 'bd03b751-0a0e-51dc-8846-a4de6fe930b7', NULL, '2022-09-29 15:06:44.663', '1998-03-11 02:46:27', '2020-06-10 05:33:00', 'Soyu rayurako rami', '2002-07-27 06:42:05', 'Hugh Upton');
INSERT INTO public."MailAttachment" VALUES ('eb22b838-9057-5322-8fe6-4600a2edca38', 'Ross Bruen', '2020-03-23T14:34:18.000Z', 'Koyua soa', '0ef59fd8-fe9c-5516-8a99-67a7127b0152', NULL, '2022-09-29 15:06:44.663', '2009-10-22 21:22:46', '2020-07-23 18:31:11', 'Rayua vikoyua mira', '1987-12-08 23:54:35', 'Jarvis Kuhn');
INSERT INTO public."MailAttachment" VALUES ('911a6aae-05d6-572f-8654-d772aa905597', 'Herman Hauck', '2020-09-13T20:35:00.000Z', 'Miso rayura koviraso', '2e313a10-1ec9-5958-92ae-bdc728f8119e', NULL, '2022-09-29 15:06:44.663', '2005-06-06 17:18:44', '2020-06-14 05:21:05', 'Rayusora miso mirayu', '1999-12-24 12:03:14', 'Alberto Kemmer');
INSERT INTO public."MailAttachment" VALUES ('dca52823-8280-57af-81dc-b9e30b94ed34', 'Eliza Pouros', '2020-06-02T05:49:18.000Z', 'Viyuso yuvi soyukoyu', '4449c503-0946-5bc4-8afd-96ac1507b73f', NULL, '2022-09-29 15:06:44.663', '2018-03-27 14:46:29', '2020-12-08 23:35:36', 'Miko miakoa', '2015-08-28 20:03:09', 'Valentin Russel');
INSERT INTO public."MailAttachment" VALUES ('5fc52654-14ce-5bee-95bd-a6983f61ff25', 'Gwen Franecki', '2020-02-14T01:45:44.000Z', 'Viavi yuvi', '6749c45d-b3ca-583c-8334-0bca6d290761', NULL, '2022-09-29 15:06:44.663', '2011-08-24 07:42:00', '2020-04-08 03:33:25', 'Virako ravi visovi', '1990-11-15 10:11:52', 'Derick Connelly');
INSERT INTO public."MailAttachment" VALUES ('f816df01-2918-5f66-a825-3a309e6eedb8', 'Jadon Vandervort', '2020-03-07T02:40:55.000Z', 'Raso somiso miyu', '73f51296-3c87-5d4b-b5d9-68ce975cd751', NULL, '2022-09-29 15:06:44.663', '1993-06-14 06:06:31', '2020-01-25 00:16:57', 'Koasomi viyurako', '2011-12-24 23:21:11', 'Imelda Treutel');
INSERT INTO public."MailAttachment" VALUES ('ead49368-9e9f-5260-a4c0-bdb3f1a8fa71', 'Marguerite Thiel', '2020-09-25T20:52:27.000Z', 'Somiyu yuko', '8cad5f5a-acd5-571c-9fee-cec9987a8f4b', NULL, '2022-09-29 15:06:44.663', '1988-01-13 00:53:41', '2020-07-07 18:59:21', 'Ravikoyu visoayu', '1997-06-22 17:17:35', 'Kirk Murazik');
INSERT INTO public."MailAttachment" VALUES ('e8501ca9-6041-5c24-839f-bdbb02e775ca', 'Orrin Altenwerth', '2020-03-07T02:35:40.000Z', 'Sorayura soyu miyuko', 'e29d091f-f15a-51bf-b51e-08e1af00c2a3', NULL, '2022-09-29 15:06:44.663', '2018-11-15 23:05:35', '2020-01-17 00:16:22', 'Miavia koviyura raviso', '2013-02-02 01:22:07', 'Elyssa Wilderman');
INSERT INTO public."MailAttachment" VALUES ('d5a51376-3458-5020-8afd-93d962d585d8', 'Heber Spencer', '2020-03-07T14:32:52.000Z', 'Soami soyuavi visora', '92007fa1-f868-5a75-9a97-a563511bf982', NULL, '2022-09-29 15:06:44.663', '1996-09-01 09:00:12', '2020-01-05 12:01:21', 'Ramiso yumisomi virako', '2013-10-14 09:47:34', 'Kendall Dooley');
INSERT INTO public."MailAttachment" VALUES ('22417f49-ede1-5633-9bd2-b428ebdf91a0', 'Ignatius Klocko', '2020-01-13T12:52:45.000Z', 'Rakovi koami', '6c8c9290-efcf-57b0-8e08-9c717a115bac', NULL, '2022-09-29 15:06:44.663', '1991-12-04 11:18:52', '2020-09-09 08:39:29', 'Somiko miaviso', '1982-11-27 10:35:09', 'Korey Lueilwitz');
INSERT INTO public."MailAttachment" VALUES ('6b2384e9-429d-56f6-ab41-23203bb35104', 'Andreane Windler', '2020-01-21T00:36:07.000Z', 'Vira misovia rayumira', 'e4bf70f7-ffaa-521d-92fc-37d481f96650', NULL, '2022-09-29 15:06:44.663', '1998-11-03 10:59:47', '2020-02-14 01:25:56', 'Kovira yuvi', '1995-04-12 15:28:22', 'Percy Harber');
INSERT INTO public."MailAttachment" VALUES ('4b1c9155-9df9-57a8-8a39-ab9c35e7035b', 'Leone Durgan', '2020-10-26T10:00:42.000Z', 'Ravi somirako', '4b212ce4-a566-57f9-a405-742f190de099', NULL, '2022-09-29 15:06:44.663', '2007-04-16 03:37:59', '2020-06-26 17:16:30', 'Kovisoyu mia', '2012-09-09 08:47:04', 'Jorge King');
INSERT INTO public."MailAttachment" VALUES ('76e00146-3b96-5a37-8445-0d510dcc0443', 'Katarina Bailey', '2020-04-08T03:39:50.000Z', 'Koavia miso', '891d15c4-a336-5e4e-ba84-f16a5bfb7bb6', NULL, '2022-09-29 15:06:44.663', '1985-10-26 21:51:15', '2020-09-17 20:58:50', 'Virayura miavia', '2010-07-03 06:44:09', 'Rogelio Friesen');
INSERT INTO public."MailAttachment" VALUES ('2b21203f-b4ca-5768-b2b1-95e955b050cc', 'Etha Reilly', '2020-08-28T07:43:13.000Z', 'Mikoviyu mia soyura', '60ae371f-0b02-5386-8460-9bf69fcef72a', NULL, '2022-09-29 15:06:44.663', '1995-08-12 08:08:50', '2020-09-05 08:18:20', 'Miyu vikovi yua', '1988-09-25 08:20:32', 'Dorian Roob');
INSERT INTO public."MailAttachment" VALUES ('cd66e05b-c77b-5ded-85a6-d31a4cdee626', 'Kelsie Ledner', '2020-04-24T15:34:37.000Z', 'Soyu yua komira', '28fde27f-ab0c-5b8d-879a-c5e3f653ecca', NULL, '2022-09-29 15:06:44.663', '1987-08-28 07:18:25', '2020-02-18 13:25:18', 'Yurasovi yura', '1980-05-13 16:53:58', 'Bradley Fadel');
INSERT INTO public."MailAttachment" VALUES ('862c9d09-f7ea-5b5c-be75-30dc7c2cb3c4', 'Jace Haag', '2020-04-08T03:51:49.000Z', 'Yumiami mikoa', '7dcac74b-19e6-54ff-80a3-1b4c4b299c5e', NULL, '2022-09-29 15:06:44.663', '2004-05-01 16:18:49', '2020-02-10 13:52:18', 'Vikoyu rayu', '2015-12-08 11:47:50', 'Benedict Keebler');
INSERT INTO public."MailAttachment" VALUES ('ab84c0df-ab32-5181-91fc-6f58004907d1', 'Fabian Kessler', '2020-04-24T03:11:19.000Z', 'Raviami misoviko miyuso', 'f9b5ae9e-f3db-5875-a088-f1d94067c376', NULL, '2022-09-29 15:06:44.663', '2003-08-12 07:52:38', '2020-11-23 23:01:11', 'Ravi viraso', '2012-09-09 08:48:00', 'Germaine Johnson');
INSERT INTO public."MailAttachment" VALUES ('9e5e1008-b486-501f-a1f2-871dac30559d', 'Fidel Bogisich', '2020-01-13T12:36:33.000Z', 'Kora soa', 'f5cd0e04-1c13-5d55-b1c4-65c7c5413a03', NULL, '2022-09-29 15:06:44.663', '1990-07-27 18:32:39', '2020-08-08 19:41:44', 'Koviso miko', '1987-04-04 15:37:33', 'Brendon Renner');
INSERT INTO public."MailAttachment" VALUES ('0533ef11-0d90-5181-ba81-3c009e380c0f', 'Elenora Stokes', '2020-10-26T10:07:41.000Z', 'Miamiso miso', '1da9e9a3-1968-58fd-af67-8180e0d30e2a', NULL, '2022-09-29 15:06:44.663', '2016-09-17 21:08:59', '2020-12-16 23:50:17', 'Rami viaso', '1994-07-19 07:07:43', 'Orval Reichert');
INSERT INTO public."MailAttachment" VALUES ('04ce94ff-0c32-5552-b450-01fc28ae8120', 'Oswald Kling', '2020-07-23T06:54:36.000Z', 'Miramiko koyu', '855d66df-b262-57f3-b838-23e716bdd08e', NULL, '2022-09-29 15:06:44.663', '1982-03-23 02:11:35', '2020-08-20 20:01:02', 'Mirasomi yuvi', '2012-01-01 00:25:46', 'Jade Hoeger');
INSERT INTO public."MailAttachment" VALUES ('46cb1c64-c151-56df-8089-d159095dc602', 'Elinore Nader', '2020-04-28T03:04:44.000Z', 'Viyu yurayu', 'e8b5008a-712b-5e9b-8d40-27f744a7362f', NULL, '2022-09-29 15:06:44.663', '1982-07-11 18:50:27', '2020-05-21 04:30:34', 'Ramisomi yuaso sovisoyu', '2000-01-13 12:03:21', 'Turner Robel');
INSERT INTO public."MailAttachment" VALUES ('4ba99539-834a-516a-b958-ac096626a176', 'Buford Lang', '2020-10-14T09:14:28.000Z', 'Yuayu viso', '7fe04e5e-997b-5d3c-adb8-77457b9af7bf', NULL, '2022-09-29 15:06:44.663', '1983-12-20 11:23:05', '2020-03-07 14:17:51', 'Viyukora yukora', '1984-09-01 20:45:03', 'Brandt Hyatt');


--
-- TOC entry 4240 (class 0 OID 2148880)
-- Dependencies: 232
-- Data for Name: MailEvent; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."MailEvent" VALUES ('1d94f4f7-941c-5658-8b36-52c579cdd679', 'Komi', 45788, '44 Sage Lodge', 'Rasora miramira ravia', '{"Visoayu yuko"}', 'Miko koako', 'Koakovi', 'Yuso ravirayu yumiso', '2022-09-29 15:06:44.503', '2012-05-25 17:01:09', '2020-05-09 16:18:43');
INSERT INTO public."MailEvent" VALUES ('3e4dfb9a-7265-5605-b841-fffea4f3ef09', 'Koyu', 24260, '808 Dina Plaza', 'Vikomi koyu', '{"Koyu koavia somi"}', 'Ramira vikoa', 'Raso', 'Yua mikoako', '2022-09-29 15:06:44.503', '2011-12-16 23:11:01', '2020-10-06 21:46:16');
INSERT INTO public."MailEvent" VALUES ('5cfa495d-189a-5a0f-8d78-067a9e4190a1', 'Yuviyu', 32577, '564 Stan Plaza', 'Somikovi soyuvi soaviyu', '{"Komikora rako koa"}', 'Ramia soravi', 'Sovi', 'Somiso yurakoyu raso', '2022-09-29 15:06:44.503', '1995-04-08 15:25:30', '2020-01-09 12:37:12');
INSERT INTO public."MailEvent" VALUES ('a3c81a1f-f9de-5e34-9b29-0327c6c1ec42', 'Soyuso', 29702, '396 Ondricka Mountains', 'Rakoyua rasoa komiyuvi', '{"Kora soa yurayuko"}', 'Ravi soavia', 'Ramiso', 'Mirayura rasoaso komira', '2022-09-29 15:06:44.503', '1980-01-25 00:15:20', '2020-05-25 04:59:38');
INSERT INTO public."MailEvent" VALUES ('500a674c-d151-5272-85b9-344abc442c40', 'Miyu', 59874, '953 Roselyn Well', 'Viayumi yuso viakovi', '{"Yuviami yuvia"}', 'Ravi kovira yuviavi', 'Somi', 'Viakovi yuvia koyu', '2022-09-29 15:06:44.503', '2010-07-23 06:34:55', '2020-10-26 09:30:38');
INSERT INTO public."MailEvent" VALUES ('908ccf8f-5974-50c1-bb83-0b1650b9d81d', 'Vikomia', 20552, '68 Jeffry Groves', 'Viayu visovi rayukomi', '{"Rakoyu komi somirayu"}', 'Yuso korakora', 'Miyura', 'Yura vikoayu ravi', '2022-09-29 15:06:44.503', '1995-04-24 15:25:32', '2020-10-10 21:20:21');
INSERT INTO public."MailEvent" VALUES ('f8c64b4c-ac8c-558e-968f-c81f54c17d9e', 'Rakovi', 524, '59 Champlin Springs', 'Kovia yuko mikoviyu', '{"Rasoa viso komikora"}', 'Visoyuso kora', 'Koviso', 'Mikoviyu mia', '2022-09-29 15:06:44.503', '2012-09-21 08:37:49', '2020-05-25 16:16:45');
INSERT INTO public."MailEvent" VALUES ('0a6e3238-ab8e-585e-886e-b8a59d1225ab', 'Koayu', 13907, '108 Leola Canyon', 'Miko vikomi yuvi', '{"Yuviyu viramiko koyu"}', 'Mikoyuko vikomi viyusoyu', 'Yumiko', 'Yuko ramiyua mikovi', '2022-09-29 15:06:44.503', '1990-03-07 03:05:09', '2020-09-09 08:29:21');
INSERT INTO public."MailEvent" VALUES ('6c447a5d-3409-5926-af8e-5de34ed276c0', 'Miyu', 34172, '362 Hirthe Underpass', 'Yurami rakovira', '{"Yuko miyurako sorami"}', 'Miyuso soyu', 'Rako', 'Soa koravi ramia', '2022-09-29 15:06:44.503', '1984-05-01 04:17:11', '2020-03-07 02:18:40');
INSERT INTO public."MailEvent" VALUES ('204d9bcd-2d48-52dc-80e5-f943fa6e75d0', 'Soviso', 27194, '836 Jacobi Causeway', 'Raso koa koayu', '{"Yurako yusorami"}', 'Viko raviyuso viyukoa', 'Soviavi', 'Rayu somiyu viko', '2022-09-29 15:06:44.503', '1987-12-13 00:00:43', '2020-08-08 07:20:39');
INSERT INTO public."MailEvent" VALUES ('06fe0534-28d4-543c-b6ae-1fa29cd9af6c', 'Viyuayu', 5240, '98 Koss Mission', 'Soa yuviyu', '{"Yusoa ramiko"}', 'Komi rakorako', 'Komiayu', 'Viayumi miami soaviko', '2022-09-29 15:06:44.503', '1999-04-16 03:48:14', '2020-02-22 01:16:30');
INSERT INTO public."MailEvent" VALUES ('363f360c-2edc-5bdd-aa3e-022f354fdd34', 'Koaviyu', 55154, '464 Crystel Ports', 'Yuavi soyuavi', '{"Rasoyuvi miso miayu"}', 'Vira misovira miko', 'Mikomira', 'Viami miyura rayu', '2022-09-29 15:06:44.503', '2007-12-04 11:48:13', '2020-05-21 04:56:11');
INSERT INTO public."MailEvent" VALUES ('aaa90a24-7347-554f-a8bb-b06a39f57252', 'Yukovia', 7219, '533 Olson Stream', 'Viaso miko korami', '{"Viyuvi ravi"}', 'Mira viami', 'Soviyu', 'Koavi mikora', '2022-09-29 15:06:44.503', '1990-07-27 18:39:39', '2020-09-01 20:10:34');
INSERT INTO public."MailEvent" VALUES ('facdd248-8360-5ac9-a36a-43c3b59b5f68', 'Viyua', 33788, '34 Armstrong Lane', 'Rayumi yukoyua', '{"Yumi ramia yuso"}', 'Yumiaso korayumi', 'Vikoyu', 'Yuvi raviako', '2022-09-29 15:06:44.503', '2003-12-04 23:24:27', '2020-04-08 15:14:26');
INSERT INTO public."MailEvent" VALUES ('5c2cf700-c229-5bd3-b22e-d5d59087aaa3', 'Soamiyu', 42070, '646 Athena Bypass', 'Soyuvi soyuravi', '{"Rayuviko soaso komiyura"}', 'Viyuvi soraviko ramia', 'Viaso', 'Soyu komiyuvi', '2022-09-29 15:06:44.503', '2007-12-28 11:47:34', '2020-02-10 01:44:58');
INSERT INTO public."MailEvent" VALUES ('6889ad81-195b-5c76-b8b9-48139412503f', 'Miyuako', 63267, '248 Sipes Roads', 'Vikoyua viko koasoyu', '{"Via viyuvi"}', 'Kovi koa somi', 'Koamiso', 'Rayumi yumia virayu', '2022-09-29 15:06:44.503', '1996-01-13 00:45:53', '2020-07-11 06:22:37');
INSERT INTO public."MailEvent" VALUES ('d876b1ab-3e9b-587c-9d9f-fdbf2f235648', 'Koviko', 35653, '635 Valentina Crossing', 'Viyu soramiyu', '{"Sorako miayura yumi"}', 'Viamira misoa koyuvi', 'Yuako', 'Ravira viramiyu', '2022-09-29 15:06:44.503', '2002-11-03 22:27:10', '2020-04-24 03:54:19');
INSERT INTO public."MailEvent" VALUES ('ff53459b-710c-5bba-8115-6344a095ae7a', 'Koyu', 30797, '24 Block Motorway', 'Viko ravisovi raso', '{"Misoviko sovi visora"}', 'Viyuko rayu komiko', 'Miramiso', 'Mikoako mirasora soyuko', '2022-09-29 15:06:44.503', '1983-08-04 19:58:27', '2020-09-05 08:37:40');
INSERT INTO public."MailEvent" VALUES ('a637872d-33f0-5d38-a963-53e058f234f9', 'Rakomiko', 36592, '496 Alford Lodge', 'Yuko sovira komia', '{"Koviyuso viyu yuviso"}', 'Misomi yua', 'Yumiyuso', 'Korami yuayu yura', '2022-09-29 15:06:44.503', '2006-03-19 02:35:45', '2020-07-19 07:02:49');
INSERT INTO public."MailEvent" VALUES ('da866738-3530-503c-b12e-92d7b9f47e26', 'Misoyu', 50242, '534 Kelsie Shoals', 'Koamiko rayu', '{"Ramiyu visomia yurakoyu"}', 'Viyu yusoravi', 'Viko', 'Viraso yuko rasoaso', '2022-09-29 15:06:44.503', '2016-01-25 12:46:12', '2020-06-02 06:00:01');
INSERT INTO public."MailEvent" VALUES ('95eac53c-e93c-5cd9-bf38-9c49d0c8b90e', 'Yumikora', 9206, '67 Kadin Garden', 'Vira viasovi', '{"Miyuko koyu koviyumi"}', 'Viravi sovikoyu viko', 'Vikomi', 'Viyuvi mira rayuviso', '2022-09-29 15:06:44.503', '2001-10-14 21:33:35', '2020-12-12 23:27:58');
INSERT INTO public."MailEvent" VALUES ('993c07e7-5047-524a-823a-f7ee03326167', 'Yukoyumi', 28820, '703 Keeling Gateway', 'Mirakomi misoa yukoravi', '{"Mikoa miyumi"}', 'Mirayua sorayu yuvi', 'Rakovia', 'Sovi koraviso', '2022-09-29 15:06:44.503', '2016-09-01 21:00:19', '2020-12-12 23:46:16');
INSERT INTO public."MailEvent" VALUES ('5cd22581-92ef-5cfb-8122-726106731830', 'Yumira', 51285, '422 Devan Row', 'Viko raviyu', '{"Rakoyu yuko"}', 'Korayu miako ramiyuso', 'Miaviko', 'Koravira miraso', '2022-09-29 15:06:44.503', '1990-03-11 03:03:56', '2020-08-24 19:08:47');
INSERT INTO public."MailEvent" VALUES ('91fda3fb-2777-592d-9e91-d82cb982faea', 'Yuvi', 53502, '380 Hickle Wells', 'Koyumira korakoa somira', '{"Komiso viso"}', 'Yuko raviravi yuko', 'Somiravi', 'Koa sovi miravi', '2022-09-29 15:06:44.503', '2000-09-05 20:27:39', '2020-07-19 19:02:49');
INSERT INTO public."MailEvent" VALUES ('41611433-4526-536e-8d07-e6f2c9792f89', 'Sovi', 37906, '364 Rosemarie Drive', 'Viako sorayuko', '{"Kovi virasora"}', 'Kovi mirakoyu', 'Yuviso', 'Yukoa yukoravi', '2022-09-29 15:06:44.503', '2019-04-04 15:47:55', '2020-08-04 19:28:09');
INSERT INTO public."MailEvent" VALUES ('906a48db-3614-5e6a-8177-e7f83daac18a', 'Yusoayu', 28868, '990 Nader Junction', 'Ramirami sovira komia', '{"Yuviko soako yura"}', 'Rayu miyumiso rayu', 'Yuavia', 'Visora koraviko', '2022-09-29 15:06:44.503', '1985-10-22 22:00:45', '2020-03-07 02:34:09');
INSERT INTO public."MailEvent" VALUES ('74da0b5e-6667-5354-a6ce-dd76ea69a73e', 'Rakoyura', 51728, '968 O''Keefe Tunnel', 'Korayuko soa', '{"Vira somiraso"}', 'Koyumia yuami sovi', 'Miramira', 'Yua rayu', '2022-09-29 15:06:44.503', '2005-02-18 01:41:16', '2020-08-28 07:56:45');
INSERT INTO public."MailEvent" VALUES ('81effb3e-c121-5980-9c07-c93936cdc9ca', 'Sovi', 21316, '733 Oswaldo Island', 'Soraviko visora', '{"Rayusora soviako"}', 'Korayuso koviko', 'Soviso', 'Koyuso mia', '2022-09-29 15:06:44.503', '2015-12-28 11:48:03', '2020-01-01 12:58:16');
INSERT INTO public."MailEvent" VALUES ('ce02b3f2-09ee-5b26-aba0-933540a7d200', 'Soa', 3362, '629 Gilda Mill', 'Yurami misorami', '{"Raviyuvi vira viyura"}', 'Koraso virasoyu miayuko', 'Rayua', 'Komiraso mira yuaviko', '2022-09-29 15:06:44.503', '2000-05-21 04:53:52', '2020-08-24 19:14:02');
INSERT INTO public."MailEvent" VALUES ('98dd1d71-ace5-5405-92ca-b264702839a5', 'Yurako', 37282, '267 Andy Ports', 'Miko mikoa', '{"Misora soamiko"}', 'Virayu rakoviyu mikovi', 'Yurayu', 'Miyu mirako', '2022-09-29 15:06:44.503', '1982-11-27 10:32:35', '2020-02-14 13:50:45');
INSERT INTO public."MailEvent" VALUES ('60bd59c5-db7c-540a-a3da-68bb3518714f', 'Koyuviyu', 21961, '8 Asia Radial', 'Koviyua yumi ravirako', '{"Yuvisoa mia kora"}', 'Viravi rayurami', 'Miso', 'Yuami yumira somiyuvi', '2022-09-29 15:06:44.503', '2019-08-12 07:31:26', '2020-07-03 06:18:10');
INSERT INTO public."MailEvent" VALUES ('309c7263-5da7-561b-8a2b-fb01bd1063c9', 'Raso', 51637, '911 Josie Avenue', 'Viyu komiravi soamira', '{"Korako rayumia"}', 'Mira mirasoyu', 'Mikomi', 'Viamiso koramiko yusoami', '2022-09-29 15:06:44.503', '2017-10-10 22:11:09', '2020-02-06 01:56:33');
INSERT INTO public."MailEvent" VALUES ('926f22a7-ed1a-5fea-8226-448d9e94f84c', 'Yuaviso', 8908, '174 Nader Loop', 'Yuravi vira yuamira', '{"Yura ramikora visoyu"}', 'Mirakora yuviavi', 'Soami', 'Rami rayusomi mia', '2022-09-29 15:06:44.503', '1988-05-09 16:31:17', '2020-09-17 20:51:44');
INSERT INTO public."MailEvent" VALUES ('8120b1bd-a8c4-588a-a301-82cd4e588a21', 'Yusomiko', 28747, '951 Donnelly Fords', 'Yurami rami sovikoa', '{"Viyu vikomi"}', 'Soa miko', 'Miyumia', 'Soayu viko', '2022-09-29 15:06:44.503', '1995-08-24 08:05:53', '2020-04-20 03:10:47');
INSERT INTO public."MailEvent" VALUES ('19a3c222-4e27-5b81-973f-a7d45c7213cc', 'Soaviso', 48201, '883 Aylin Ranch', 'Sora yuasovi', '{"Viaso koamiko koyu"}', 'Yua soviso ramikoa', 'Soa', 'Miamia soasora', '2022-09-29 15:06:44.503', '1984-05-13 04:08:59', '2020-05-21 16:45:00');
INSERT INTO public."MailEvent" VALUES ('709af6fc-21fc-5042-a8b3-a0b4d4b748ee', 'Miyu', 30607, '76 Megane Flat', 'Soayuvi mia koavi', '{"Mikoavi kovira"}', 'Somiko miko', 'Yukora', 'Koamiso yuvi', '2022-09-29 15:06:44.503', '2002-07-27 06:48:16', '2020-02-26 13:31:22');
INSERT INTO public."MailEvent" VALUES ('cdccc0d3-0b55-5926-845c-d10e8d2360b5', 'Koyua', 32547, '423 Wehner Isle', 'Rasoaso yura', '{"Yuvikoa raviso mia"}', 'Miko koviraso rakora', 'Vikoyu', 'Yusoa kora kovirako', '2022-09-29 15:06:44.503', '1981-02-22 01:09:10', '2020-06-22 05:26:13');
INSERT INTO public."MailEvent" VALUES ('152c0ec5-ef06-5079-afc6-2d226825fa2f', 'Sovi', 60939, '319 Lupe Canyon', 'Yurakoa yukoyura', '{"Yumiko yuraviko"}', 'Yumi koyuko korakora', 'Yuko', 'Yuviso yumiavi', '2022-09-29 15:06:44.503', '1989-06-06 17:36:05', '2020-06-26 17:52:51');
INSERT INTO public."MailEvent" VALUES ('e6ccc4bb-fc8c-5069-913b-af9e8c9fa341', 'Yuayu', 37439, '812 Mckayla Knoll', 'Somisovi miyu', '{"Somi koako misovi"}', 'Viaso miyuvi miasoyu', 'Miko', 'Koami koaviko', '2022-09-29 15:06:44.503', '1997-10-22 10:03:46', '2020-09-17 20:21:20');
INSERT INTO public."MailEvent" VALUES ('2158fe85-8422-5fec-80fc-f7b5f7b94b39', 'Soviaso', 48978, '517 Grayson Ranch', 'Komiyu rayu', '{"Soyu miravira"}', 'Korasovi kovia yumi', 'Ramisomi', 'Sovirayu soa', '2022-09-29 15:06:44.503', '1997-10-26 10:04:46', '2020-06-14 17:14:40');
INSERT INTO public."MailEvent" VALUES ('1999a975-abe6-551d-b132-a0a610d2ec9b', 'Via', 10657, '351 Elvie Junction', 'Sorasoyu koa', '{"Mirasovi yuko"}', 'Rayuravi rasora vira', 'Sorayu', 'Soyumira komi yusoviyu', '2022-09-29 15:06:44.503', '2008-05-13 04:40:41', '2020-10-14 21:23:20');
INSERT INTO public."MailEvent" VALUES ('30fbdba7-6010-5b52-9031-7b1814d280da', 'Yumiyuvi', 53860, '244 Neoma Junction', 'Komi yumiso rayusoa', '{"Vikoyuso vikoyu koyuviko"}', 'Soyua vikoaso kovikomi', 'Yuraso', 'Viyurami miyuko ravisoyu', '2022-09-29 15:06:44.503', '1986-03-19 14:30:02', '2020-12-24 12:12:48');
INSERT INTO public."MailEvent" VALUES ('bffcd500-c716-503e-98cc-4a0c3706fb71', 'Viyu', 51618, '810 Jacinto Mount', 'Kora sorakora yuko', '{"Miami kovisora"}', 'Viamiso ramia kovira', 'Soyuvi', 'Rakora viyu kovira', '2022-09-29 15:06:44.503', '1994-07-03 07:06:52', '2020-08-08 07:48:22');
INSERT INTO public."MailEvent" VALUES ('74d86798-b8b1-5754-867c-a716a31c9b54', 'Sovia', 23943, '850 Gibson Mountains', 'Yukovia rami', '{"Mia sora kovikovi"}', 'Miyusoyu ravia', 'Ramikovi', 'Rayusomi koayura', '2022-09-29 15:06:44.503', '2004-01-09 00:27:38', '2020-07-07 19:04:01');
INSERT INTO public."MailEvent" VALUES ('29986ad1-ebc4-5e06-b229-edf1effa42c3', 'Somikoa', 43680, '319 Glover Point', 'Viyuami mira', '{"Rayu soyuko"}', 'Komi koami somiyu', 'Visoa', 'Ravira mirasora', '2022-09-29 15:06:44.503', '2015-08-28 20:03:58', '2020-12-24 23:36:13');
INSERT INTO public."MailEvent" VALUES ('e9d81f20-3324-5530-a05b-28cee82aa856', 'Yukovi', 62682, '490 Daugherty Locks', 'Somira koyu viakovi', '{"Miyuvi mira yuraso"}', 'Sorako miyuvira raso', 'Kovirako', 'Visoa mia yumi', '2022-09-29 15:06:44.503', '1990-11-15 10:24:56', '2020-01-17 12:51:40');
INSERT INTO public."MailEvent" VALUES ('480d8f04-a681-5bda-b1e2-ad980f1e97c1', 'Koyuvi', 62924, '155 Blaise Well', 'Soami soviayu', '{"Rayu sovirayu"}', 'Visoyu komisovi', 'Vikoyu', 'Yua soyu', '2022-09-29 15:06:44.503', '1985-06-26 05:05:39', '2020-10-06 09:53:15');
INSERT INTO public."MailEvent" VALUES ('ba339d7a-595c-52f2-b9f4-4fbec845618e', 'Visomi', 61572, '811 Hand Meadows', 'Rakoa koyuviyu miso', '{"Raviko soaso rakora"}', 'Viyurayu rayumia mira', 'Soyuso', 'Komisovi koviako', '2022-09-29 15:06:44.503', '1993-06-14 05:54:16', '2020-08-28 07:59:39');
INSERT INTO public."MailEvent" VALUES ('9b8559e4-5c63-5309-a70f-734108b40230', 'Visora', 51570, '779 Ferry Lodge', 'Kovisora rakoyu', '{"Yuko koayu soa"}', 'Yuako komira raso', 'Koravira', 'Yuakomi soyuvira', '2022-09-29 15:06:44.503', '1983-08-08 19:46:37', '2020-02-26 13:49:39');
INSERT INTO public."MailEvent" VALUES ('81c2e228-2791-53c5-84c5-33057285a1e4', 'Kovi', 12889, '942 Cronin Expressway', 'Rasoviso yumisoa', '{"Mirayu rasoviko soyuko"}', 'Miyu sovia', 'Misoviyu', 'Rakomira koyu raviso', '2022-09-29 15:06:44.503', '2003-08-08 07:53:09', '2020-08-24 19:34:46');
INSERT INTO public."MailEvent" VALUES ('956be805-123c-549d-abc4-851e369c492c', 'Yua', 57769, '765 Mohr Manor', 'Soa ravikoyu mikovi', '{"Soyu rakoyuvi viayu"}', 'Somi koyua kovi', 'Raso', 'Soa vira soasomi', '2022-09-29 15:06:44.503', '2016-05-01 04:31:59', '2020-08-16 07:38:29');
INSERT INTO public."MailEvent" VALUES ('5f993321-4cdc-572e-8b2b-f9d7789716b6', 'Yuvi', 53561, '945 Romaguera Squares', 'Yuso rasomi', '{"Miravia yumirako"}', 'Sora komiyu', 'Korayuko', 'Somi miaviko', '2022-09-29 15:06:44.503', '2019-08-16 07:25:47', '2020-11-03 22:38:21');
INSERT INTO public."MailEvent" VALUES ('ec85c4f2-fb8e-5885-be82-9709df77a7b8', 'Koyua', 3872, '148 Kay Manor', 'Miko rasovira soyura', '{"Miayu yuviravi miraso"}', 'Soyukora miyu', 'Sorakoyu', 'Yumira koraviko', '2022-09-29 15:06:44.503', '1982-11-19 10:28:15', '2020-08-20 19:58:49');
INSERT INTO public."MailEvent" VALUES ('fa08024d-cc04-53f3-9d2b-873ce58c9c5f', 'Rayu', 16701, '11 Magdalena Parkways', 'Koa rayumia vikora', '{"Soayu yuayura raso"}', 'Viyuko kora', 'Rakoyu', 'Viyurami koravia soaso', '2022-09-29 15:06:44.503', '1987-12-12 23:56:38', '2020-01-17 12:52:00');
INSERT INTO public."MailEvent" VALUES ('d3750d57-3596-5a68-b74c-6f6749e88af9', 'Viyuvi', 12863, '963 Will Fields', 'Mikovi vikorami', '{"Mikoviko yuko soyukoyu"}', 'Misomiyu soyu', 'Yuso', 'Koraso rayuraso koyu', '2022-09-29 15:06:44.503', '1994-11-27 22:42:43', '2020-07-11 18:25:17');
INSERT INTO public."MailEvent" VALUES ('c3baf53f-b07b-5c36-81a8-0f9a09474ddf', 'Vikora', 23133, '868 Angelo Circles', 'Miyu viyusoa viyuvi', '{"Korasovi miyuaso misora"}', 'Yuamiso yuayua rasomia', 'Visoviso', 'Rayuvi viyukomi somiayu', '2022-09-29 15:06:44.503', '2006-07-23 18:22:35', '2020-09-09 20:30:10');
INSERT INTO public."MailEvent" VALUES ('f283e0ea-ef67-5002-ae76-2dc1e248e059', 'Misora', 31292, '58 Amir Summit', 'Yukora rasomiko', '{"Rasora rayukora miayu"}', 'Yuako ramiyuko mira', 'Yuami', 'Koa koviso', '2022-09-29 15:06:44.503', '1997-06-02 17:18:25', '2020-12-28 12:03:39');
INSERT INTO public."MailEvent" VALUES ('fe91c676-ad0c-51b2-89e5-a4c8e352a747', 'Yuvia', 2178, '901 Macejkovic Mills', 'Mira rasovi soyumiyu', '{"Miravi sorayuvi"}', 'Yuvia sovi', 'Rasomiyu', 'Somi koviravi', '2022-09-29 15:06:44.503', '2015-08-16 20:10:04', '2020-06-10 05:53:17');
INSERT INTO public."MailEvent" VALUES ('140891d4-0dd7-5c4c-acfb-c8b19e4eb965', 'Koviso', 48949, '399 Merl Ville', 'Vikovia mikora', '{"Sovi yuviko"}', 'Yuso virami', 'Yurasoyu', 'Soako koakovi', '2022-09-29 15:06:44.503', '2018-03-03 14:39:33', '2020-07-27 18:39:25');
INSERT INTO public."MailEvent" VALUES ('f106a1e0-a9ef-5300-97d9-ef2aef31c11f', 'Soviyu', 65397, '708 Wehner Fork', 'Soyura ramiami', '{"Rayuavi viko"}', 'Misoyu soyu', 'Kovi', 'Viyukomi koyu korami', '2022-09-29 15:06:44.503', '2004-09-05 08:55:30', '2020-05-13 04:23:19');
INSERT INTO public."MailEvent" VALUES ('a4a7ec64-9583-50a0-bfff-6513a989f96c', 'Mia', 3834, '834 Krajcik Keys', 'Yua yuavi', '{"Rakovia ravi"}', 'Koyu ramia yurakomi', 'Soyu', 'Misovira komira', '2022-09-29 15:06:44.503', '2016-05-17 04:27:35', '2020-09-21 21:11:44');
INSERT INTO public."MailEvent" VALUES ('13d61191-d799-5102-944c-072e13725244', 'Sora', 30919, '64 Mayert Estate', 'Soaviyu rayu', '{"Yuako yuvira somikoa"}', 'Kora sovira mirayumi', 'Yusomiyu', 'Miyu mikoviyu rayuso', '2022-09-29 15:06:44.503', '2003-04-28 15:15:00', '2020-08-20 07:21:18');
INSERT INTO public."MailEvent" VALUES ('05490d45-03d8-52e6-9392-31d88517b736', 'Rami', 6460, '668 Willms Ranch', 'Yuako rakoviko mira', '{"Ravia sovi"}', 'Kora mikoyu miaviso', 'Komiyu', 'Miyumia sorayu', '2022-09-29 15:06:44.503', '1985-02-18 13:31:00', '2020-06-06 18:03:07');
INSERT INTO public."MailEvent" VALUES ('e2b13563-506c-599f-9b43-84a66ef66c90', 'Via', 30534, '339 DuBuque Drive', 'Vira viakovi soyua', '{"Sovia miamira yumiyu"}', 'Yuso vikomi', 'Yuasoa', 'Koravi yuko', '2022-09-29 15:06:44.503', '2010-11-11 22:11:41', '2020-07-27 06:15:32');
INSERT INTO public."MailEvent" VALUES ('4c112dd3-8a27-515a-8a65-736ca6c6ae2f', 'Soyura', 20699, '693 Alba Rest', 'Yusoyu somi ravikoyu', '{"Yua miyusoa soviko"}', 'Miyuvi sovi', 'Visomi', 'Miyumi viyuviso misoaso', '2022-09-29 15:06:44.503', '2018-07-27 06:22:17', '2020-08-08 07:55:22');
INSERT INTO public."MailEvent" VALUES ('b8ad6420-7d02-5171-baf8-669ea76bf1f4', 'Sora', 33784, '58 Lehner Gardens', 'Rayua yuramiko', '{"Yurayura somia"}', 'Raviyura yumiyu vikovia', 'Koyu', 'Koa viakoyu visora', '2022-09-29 15:06:44.503', '1980-09-17 08:26:27', '2020-08-12 19:20:50');
INSERT INTO public."MailEvent" VALUES ('4d8e8799-7248-51ad-b84d-415cc4a75c16', 'Vikomi', 59546, '357 Oberbrunner Loop', 'Miso viyuso vikoa', '{"Rakoyura miasoa viramiso"}', 'Koyumi yua', 'Yura', 'Vikoyu misoayu', '2022-09-29 15:06:44.503', '1996-01-05 00:47:30', '2020-02-22 13:13:35');
INSERT INTO public."MailEvent" VALUES ('1825321c-136d-5ca7-8aef-5496e5878272', 'Yukorami', 40326, '971 Koch Grove', 'Koviyua sovi', '{"Komi rakovi komia"}', 'Somikoyu yuso koa', 'Rayu', 'Kora yumiaso', '2022-09-29 15:06:44.503', '1998-07-07 18:29:32', '2020-03-11 14:17:41');
INSERT INTO public."MailEvent" VALUES ('8b3cfccd-ec76-5128-9278-07ecdd54d0e4', 'Ramirako', 29792, '511 Cruz Islands', 'Viavi miyuso', '{"Somia miyuaso"}', 'Rayuso miyua', 'Soaso', 'Rakomi kora yuvira', '2022-09-29 15:06:44.503', '1985-06-26 05:05:04', '2020-08-20 19:58:07');
INSERT INTO public."MailEvent" VALUES ('c3d31c69-1171-5b73-b600-9ca25b92905e', 'Vira', 11453, '914 Sanford Shoal', 'Koayuko raviyu', '{"Soyuraso viko"}', 'Raviso kovi komiyu', 'Koraviko', 'Komiko mira', '2022-09-29 15:06:44.503', '2014-03-15 02:26:50', '2020-04-12 03:45:22');
INSERT INTO public."MailEvent" VALUES ('7ed1256a-5d99-576c-ab0b-860a12cbade9', 'Ramikovi', 62525, '767 America Trafficway', 'Koa rasoviko', '{"Mira misora"}', 'Rasoravi miso rakomi', 'Koviyu', 'Komi koyumi', '2022-09-29 15:06:44.503', '2016-05-21 04:29:38', '2020-09-21 21:10:34');
INSERT INTO public."MailEvent" VALUES ('263791e4-2715-5bc0-893a-82f5dca83796', 'Miko', 56802, '12 Schumm Rapids', 'Visoravi yua', '{"Koyu soavira"}', 'Miso rakoako', 'Soyu', 'Miayu vikoyuko', '2022-09-29 15:06:44.503', '1989-10-10 09:21:03', '2020-03-19 02:52:46');
INSERT INTO public."MailEvent" VALUES ('00c351ea-f320-543d-86d6-06ac75dd6106', 'Soyu', 3410, '115 Rolfson Ranch', 'Mikoaso miso misovi', '{"Sovi yukoyura soaso"}', 'Mikovia somi', 'Yua', 'Mia miraso ravi', '2022-09-29 15:06:44.503', '2009-02-10 14:00:56', '2020-07-15 18:57:59');
INSERT INTO public."MailEvent" VALUES ('f9794e5f-c916-5db6-b8a6-f52409f600d9', 'Yumia', 35350, '440 Christopher Manor', 'Yusorayu soyuvia kora', '{"Yua sovira"}', 'Viyurako viamira yuko', 'Rako', 'Soviso yuko soa', '2022-09-29 15:06:44.503', '1989-02-26 01:53:23', '2020-02-02 01:02:11');
INSERT INTO public."MailEvent" VALUES ('4a484bc5-1140-5e62-a40f-c45d6e6ee09c', 'Ramiyura', 44783, '889 Schiller Corners', 'Visomi yumiyuvi', '{"Viko kovikovi miami"}', 'Yuayuso sovi', 'Mikomi', 'Viso soavira ravi', '2022-09-29 15:06:44.503', '1983-12-28 11:34:39', '2020-01-05 00:32:35');
INSERT INTO public."MailEvent" VALUES ('8c32ab94-3b94-5d10-af89-fdc3f7ce279b', 'Koa', 33135, '170 Breitenberg Fields', 'Misoyura miami', '{"Mikoyumi mia kovi"}', 'Somi koasora', 'Virakoa', 'Yurasovi mia yuviraso', '2022-09-29 15:06:44.503', '1996-09-01 09:04:03', '2020-06-18 05:45:01');
INSERT INTO public."MailEvent" VALUES ('321f319b-f51c-5e5b-9dcb-32f897b1d4e5', 'Yuvi', 7496, '194 Breitenberg Underpass', 'Koyuako raviko mirayuvi', '{"Yukorami misovi"}', 'Mirayuvi yuso', 'Koaso', 'Kora koviko viravia', '2022-09-29 15:06:44.503', '1989-10-02 09:22:12', '2020-04-16 03:53:50');
INSERT INTO public."MailEvent" VALUES ('9201546e-eb63-5654-a2b5-a1e451b986ed', 'Rakoako', 18338, '552 Orin Roads', 'Miso mikoa', '{"Yuayuko viayua"}', 'Rakora raso rakovia', 'Komi', 'Soravi ramisoa koviko', '2022-09-29 15:06:44.503', '1980-09-13 08:22:39', '2020-09-01 20:59:58');
INSERT INTO public."MailEvent" VALUES ('baff4f50-3a93-5344-b025-fe939cd85d73', 'Raso', 10086, '205 Greenfelder Vista', 'Soyuko mikovira', '{"Koa koyu"}', 'Yuviyumi komiko komiraso', 'Somi', 'Sora yuramiyu', '2022-09-29 15:06:44.503', '1983-08-08 19:55:57', '2020-10-10 22:03:55');
INSERT INTO public."MailEvent" VALUES ('dcc16e71-a7dc-5af5-8efd-9fb64daf76df', 'Yuko', 13343, '977 Rebecca Shore', 'Yurami mira mia', '{"Viayu koa"}', 'Miraviyu miravi mira', 'Soa', 'Kora rayuvira komi', '2022-09-29 15:06:44.503', '2001-02-02 13:14:40', '2020-07-15 06:43:45');
INSERT INTO public."MailEvent" VALUES ('83b7c41b-8c1e-52db-a222-a00a1b64653f', 'Kora', 42766, '111 Harris Station', 'Mirami kora', '{"Yuviko yuso"}', 'Sora via yuvi', 'Rayu', 'Yusoyu kovikora somi', '2022-09-29 15:06:44.503', '1996-01-21 00:48:28', '2020-05-01 16:47:35');
INSERT INTO public."MailEvent" VALUES ('80e92845-9297-5343-82b8-4448459a9410', 'Yura', 30870, '967 Jared Valleys', 'Rakovi viyu', '{"Rayu yuayu"}', 'Yumiyu koa komira', 'Miavi', 'Raso raviavi soa', '2022-09-29 15:06:44.503', '1996-09-09 09:07:06', '2020-02-18 01:13:38');
INSERT INTO public."MailEvent" VALUES ('3db1ed66-2d74-5bf6-850d-64f22c92fd41', 'Koyumia', 29411, '144 Will Ridges', 'Viyu koamiyu korayu', '{"Rayu yuviyura"}', 'Yumikomi kora', 'Yumirako', 'Yuvikomi somi', '2022-09-29 15:06:44.503', '2009-02-02 14:04:04', '2020-12-24 12:02:33');
INSERT INTO public."MailEvent" VALUES ('07f4dfa5-bec4-5271-8774-5c70d31d1e8b', 'Miako', 40883, '214 Schroeder Keys', 'Kovi yuviyu', '{"Viso somiraso"}', 'Miayu rami miyuso', 'Yuso', 'Komiso raviyua', '2022-09-29 15:06:44.503', '1996-09-21 09:01:07', '2020-01-25 00:14:38');
INSERT INTO public."MailEvent" VALUES ('98eb80e0-e5b2-523e-b2b2-487a5c78c649', 'Koviko', 60741, '186 Gisselle Ridge', 'Korami yurakoa', '{"Korayumi komira"}', 'Koa komi', 'Miramira', 'Viyu koraso virakoa', '2022-09-29 15:06:44.503', '2015-12-28 11:37:12', '2020-11-07 11:00:19');
INSERT INTO public."MailEvent" VALUES ('3f2bc22c-ed50-57f3-8dff-392ed569ccb1', 'Via', 16333, '724 Collins Shoal', 'Miyu miako', '{"Miyurayu viso soraso"}', 'Yuraso korasovi', 'Sora', 'Koyura vikoyua', '2022-09-29 15:06:44.503', '1993-06-06 06:02:04', '2020-12-16 11:26:04');
INSERT INTO public."MailEvent" VALUES ('26c7cfc7-411b-5c5a-b72f-51aaa02bc46c', 'Yumi', 39579, '718 Triston Lodge', 'Mira raviso viko', '{"Vikoavi rayu"}', 'Komi soavi', 'Visomi', 'Vikoyuso viyumi', '2022-09-29 15:06:44.503', '1994-11-11 22:45:01', '2020-05-13 04:20:25');
INSERT INTO public."MailEvent" VALUES ('ff026638-bc62-5e4c-bc86-dfa184a6f6e0', 'Koviso', 46861, '761 Peter Mountains', 'Miso mia', '{"Sorasomi koako"}', 'Rakora rako', 'Ravia', 'Via miraso koviaso', '2022-09-29 15:06:44.503', '1987-04-20 15:36:25', '2020-04-20 15:51:34');
INSERT INTO public."MailEvent" VALUES ('0c439b5f-fc52-5cb7-bfcf-8e2ca6e3fac7', 'Kovisovi', 3501, '614 Marlen Ports', 'Miasoa koyu', '{"Miko mirasoyu"}', 'Koasoa soyuavi', 'Mikoa', 'Koyu viayu viyuviso', '2022-09-29 15:06:44.503', '1983-04-24 03:06:11', '2020-01-05 00:55:32');
INSERT INTO public."MailEvent" VALUES ('eb1d6a08-1aae-58dd-805b-86c17f551c55', 'Yukoviko', 41799, '866 Breitenberg River', 'Rayuko somia miko', '{"Kovi miasomi"}', 'Ravikovi mikoa', 'Komi', 'Misomiyu koakora', '2022-09-29 15:06:44.503', '2012-09-13 08:40:50', '2020-11-19 10:25:49');
INSERT INTO public."MailEvent" VALUES ('8f2c57f9-1074-573d-8064-64f35dd3a82b', 'Vikomi', 32138, '964 Frami Rapids', 'Mia yusomi visovia', '{"Soyura yuviravi"}', 'Somiaso rakoraso mikoyua', 'Viyu', 'Koyuso yusoavi', '2022-09-29 15:06:44.503', '1981-02-06 01:07:44', '2020-10-26 21:47:32');
INSERT INTO public."MailEvent" VALUES ('be94ef85-a631-545b-a37d-054f6555e591', 'Mirakomi', 19685, '551 Kuphal Brook', 'Soavi raso', '{"Mikoami visorami miyu"}', 'Rasoa soyuko mikorako', 'Kovia', 'Miko virayu koyurayu', '2022-09-29 15:06:44.503', '1981-10-22 09:35:21', '2020-01-01 00:39:03');
INSERT INTO public."MailEvent" VALUES ('c94e92fb-ee53-5be6-9af2-043e9269abfa', 'Sorayu', 17202, '626 McClure Junction', 'Miyu yukoa raviavi', '{"Komisoa viso"}', 'Soyura komia', 'Koyuvi', 'Sora mikomi', '2022-09-29 15:06:44.503', '2014-11-03 10:43:15', '2020-04-08 03:19:06');
INSERT INTO public."MailEvent" VALUES ('257674dd-2497-5935-8d9f-8241f4c7a9a4', 'Komira', 19, '997 Leonardo Islands', 'Sovira viso sorayuso', '{"Mikoa rako koviso"}', 'Mirayu yura', 'Miavi', 'Rayumi miyu', '2022-09-29 15:06:44.503', '2004-01-09 00:31:29', '2020-04-24 03:36:50');
INSERT INTO public."MailEvent" VALUES ('692da7d3-6ee0-51f1-8341-c6bc4e6727db', 'Yurami', 25765, '721 Mertz Greens', 'Viyumira visovi', '{"Miramira viayuso soyuso"}', 'Kovira viavi', 'Koyukovi', 'Somiso rami', '2022-09-29 15:06:44.503', '2008-05-05 04:33:33', '2020-11-11 22:42:34');
INSERT INTO public."MailEvent" VALUES ('163b4966-4379-55b7-818a-f327cdabc2f0', 'Vira', 21294, '649 O''Conner Landing', 'Koavi mirasora', '{"Mikomi ramiavi"}', 'Viyuko koyu', 'Misoyuko', 'Yusoyua yuravi', '2022-09-29 15:06:44.503', '1999-08-08 19:28:55', '2020-02-22 13:11:09');
INSERT INTO public."MailEvent" VALUES ('12da783d-d660-5420-8a60-2dde5d00e5e5', 'Soyurako', 24841, '830 Yazmin Meadows', 'Yura somisovi', '{"Yuviso soyu"}', 'Sorakoyu yumi', 'Rakoviso', 'Yuravi raso', '2022-09-29 15:06:44.503', '1996-05-01 16:28:22', '2020-04-24 16:06:47');
INSERT INTO public."MailEvent" VALUES ('1289dde7-b1cb-5975-8d80-f3d36195f51f', 'Yumi', 59305, '457 Jonas Island', 'Sovisoa raviyura', '{"Somi kovisoyu virami"}', 'Viyuako soyuko yuso', 'Yuvi', 'Virami via viyurako', '2022-09-29 15:06:44.503', '2014-11-03 10:37:25', '2020-12-04 23:52:11');
INSERT INTO public."MailEvent" VALUES ('a81b19d3-531c-571f-a62c-c7152141b042', 'Visomiso', 7747, '51 Gislason Lodge', 'Vira virayu sorayuko', '{"Viakora virako"}', 'Rakovi kovisomi', 'Virakovi', 'Viami korayu soayu', '2022-09-29 15:06:44.503', '2004-09-21 08:54:29', '2020-01-13 12:51:01');
INSERT INTO public."MailEvent" VALUES ('cfdcee76-d829-5260-af58-56de553c429f', 'Miko', 47144, '695 Janie Circle', 'Soramiyu virayu raso', '{"Koa mirako"}', 'Rasorako mira sorayu', 'Koayu', 'Koasoa sovi', '2022-09-29 15:06:44.503', '2004-05-05 16:10:22', '2020-01-17 13:03:12');


--
-- TOC entry 4241 (class 0 OID 2148886)
-- Dependencies: 233
-- Data for Name: ManageReturn; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."ManageReturn" VALUES ('132840a9-fc71-54d9-8b0c-c2bbb180a0ce', 'Nova Davis');
INSERT INTO public."ManageReturn" VALUES ('435af974-e73b-54c1-8876-f49488d02423', 'Edwina Weber');
INSERT INTO public."ManageReturn" VALUES ('4ba0a592-0006-5370-b5ac-a3dc4781febc', 'Benny Schultz');
INSERT INTO public."ManageReturn" VALUES ('47201058-7156-595d-9b58-e449fcb5ce11', 'Daron Harvey');
INSERT INTO public."ManageReturn" VALUES ('833de7f1-e38d-509e-9caf-bc91a34d81ca', 'Vada Towne');
INSERT INTO public."ManageReturn" VALUES ('d22bf5bd-c31f-5f2c-badd-21acff578857', 'Lydia Bradtke');
INSERT INTO public."ManageReturn" VALUES ('31fcd652-4b01-5335-92ac-eddfa70142d7', 'Margaret Marquardt');
INSERT INTO public."ManageReturn" VALUES ('ea8d829b-c1b8-5cd8-b215-637841dc5257', 'Javon Jacobi');
INSERT INTO public."ManageReturn" VALUES ('4cb3c597-fad7-5e17-8dff-7904bd837167', 'August Schultz');
INSERT INTO public."ManageReturn" VALUES ('402d2b73-4d23-519d-9997-960accd41ed6', 'Myra Sipes');
INSERT INTO public."ManageReturn" VALUES ('9cd4e6cc-073f-57c5-a191-c56baf66b3a8', 'Aaliyah Boyle');
INSERT INTO public."ManageReturn" VALUES ('95732736-8017-5b20-98f4-1dac665d8d4f', 'Cali Cronin');
INSERT INTO public."ManageReturn" VALUES ('ff82ed68-3157-5db4-84ee-a1b932563fce', 'Amaya Hane');
INSERT INTO public."ManageReturn" VALUES ('c1af6024-604d-596b-ba8a-4456df75da6d', 'Jamir Roob');
INSERT INTO public."ManageReturn" VALUES ('09f80040-2896-5b6a-a3b3-9a578645d8c2', 'Jamir Zulauf');
INSERT INTO public."ManageReturn" VALUES ('a0ba3745-4e72-50e0-8835-b333dab5df69', 'Agustin Kuhlman');
INSERT INTO public."ManageReturn" VALUES ('8f596c2a-8be5-5164-ab2b-ce5596f37188', 'Armani Lesch');
INSERT INTO public."ManageReturn" VALUES ('8f9814e3-1323-5216-97b2-a6204b6f67e6', 'Irving Schimmel');
INSERT INTO public."ManageReturn" VALUES ('95ab7663-a4a9-5727-afa3-fe100b577df2', 'Danika Harvey');
INSERT INTO public."ManageReturn" VALUES ('179ee8d5-f40c-5056-8ea5-eafc01f785fa', 'Ruthe Zieme');
INSERT INTO public."ManageReturn" VALUES ('32c1ec59-8ec2-5c71-a6c5-12593cdad66c', 'Ada Klein');
INSERT INTO public."ManageReturn" VALUES ('5ec1d964-bbb7-5fc2-9d7f-6f03c769b037', 'Precious Koelpin');
INSERT INTO public."ManageReturn" VALUES ('08a1f0d0-2d6e-5b2f-b95c-222f31598f02', 'Rodolfo Kutch');
INSERT INTO public."ManageReturn" VALUES ('3a32cb28-e2c6-560a-a062-d577c144ecd4', 'Arturo Kling');
INSERT INTO public."ManageReturn" VALUES ('00f05981-26fd-5eb0-adb5-8083bcdadedf', 'Wilson Runolfsdottir');
INSERT INTO public."ManageReturn" VALUES ('f15a5beb-ad12-5be8-81f2-d5b69a7b1ded', 'Betsy Torphy');
INSERT INTO public."ManageReturn" VALUES ('fe3536e0-ace5-553c-ad4a-cbff5c38fce4', 'Chase Mueller');
INSERT INTO public."ManageReturn" VALUES ('da2378b9-369e-54f0-b530-6e71999d1137', 'Isadore Greenholt');
INSERT INTO public."ManageReturn" VALUES ('0ec0c0c8-f6fc-5559-b4fb-67173b6b171f', 'Harry Wyman');
INSERT INTO public."ManageReturn" VALUES ('71235491-8ecb-5b6f-a1f3-f950ad4e2b3f', 'Annabel Batz');
INSERT INTO public."ManageReturn" VALUES ('79ae5c1b-5df9-5235-a1cf-122fe478dfe1', 'Cary Kihn');
INSERT INTO public."ManageReturn" VALUES ('954f7964-7bac-5eaa-b1f0-3c91db76656f', 'Crawford Haley');
INSERT INTO public."ManageReturn" VALUES ('8a48e2fa-4bd5-596a-b113-defb684900a5', 'Elyse Dooley');
INSERT INTO public."ManageReturn" VALUES ('26d7997b-3ff9-533b-80c1-f8e924fd5e93', 'Tessie Gulgowski');
INSERT INTO public."ManageReturn" VALUES ('87c43ccc-27f8-5069-b202-1c0ae2ed5a94', 'Vicky Mayert');
INSERT INTO public."ManageReturn" VALUES ('79b766c7-ed6a-5112-a7d2-4d519dd16250', 'Nakia Zieme');
INSERT INTO public."ManageReturn" VALUES ('f25a9aeb-ade3-50b3-bec8-cec8577b3ab2', 'Jed Runte');
INSERT INTO public."ManageReturn" VALUES ('c1ffc96f-efd5-566c-a2f6-f55af8bcdbb5', 'Electa Ryan');
INSERT INTO public."ManageReturn" VALUES ('fba0d48b-178a-5acd-adee-e159475d411a', 'Braden Prohaska');
INSERT INTO public."ManageReturn" VALUES ('35c2f416-a5b7-5163-95a5-ca3f0e8e2bc4', 'Leland O''Kon');
INSERT INTO public."ManageReturn" VALUES ('ae0c8a90-d49b-5083-9b6f-e434b3502f97', 'Norma Hauck');
INSERT INTO public."ManageReturn" VALUES ('f4ee165b-4897-54cb-a80c-180bf4481710', 'Rex Cremin');
INSERT INTO public."ManageReturn" VALUES ('2e0ce746-0120-5642-8a5f-f8f588e4d3bb', 'Toby Schneider');
INSERT INTO public."ManageReturn" VALUES ('5e79f6da-0d0f-5375-9f0d-a27293fe2f8a', 'Viola Doyle');
INSERT INTO public."ManageReturn" VALUES ('5ceee340-45c1-5e0c-b4d1-93a87c34d5e4', 'Hollis Schulist');
INSERT INTO public."ManageReturn" VALUES ('9636e997-834e-517b-a349-851afc15617b', 'Jody Wiegand');
INSERT INTO public."ManageReturn" VALUES ('84397e98-f023-5fea-bd9f-1a5bc332e7d7', 'Jillian Jones');
INSERT INTO public."ManageReturn" VALUES ('7045dc59-77b1-5a22-a3e8-af8e9170b581', 'Candida Prosacco');
INSERT INTO public."ManageReturn" VALUES ('c04e5353-0cba-5cec-bf6e-d6b232b0b088', 'Krista Klein');
INSERT INTO public."ManageReturn" VALUES ('4bd0780d-a392-50d5-a738-edccf01ee3d2', 'Amina Waelchi');
INSERT INTO public."ManageReturn" VALUES ('68b29c4d-1272-541e-a239-132c081a3e38', 'Skyla Bergstrom');
INSERT INTO public."ManageReturn" VALUES ('b9b941ea-b25f-5669-83b5-4c6e512aea7c', 'Nasir Prohaska');
INSERT INTO public."ManageReturn" VALUES ('beb011e0-0ce2-540a-9b16-07449989986b', 'Waylon Little');
INSERT INTO public."ManageReturn" VALUES ('f9205826-2abb-56e5-896f-d46990b4be3e', 'Gaetano Labadie');
INSERT INTO public."ManageReturn" VALUES ('3397d970-3c7d-541d-a86f-7fca947f3305', 'Daron D''Amore');
INSERT INTO public."ManageReturn" VALUES ('a7a319f4-40e6-59cc-9172-e4a01f9a90ea', 'Baron Wiza');
INSERT INTO public."ManageReturn" VALUES ('d3d819d8-822e-5b5c-a566-c041dbf80b84', 'Rosa Jenkins');
INSERT INTO public."ManageReturn" VALUES ('fa17471c-9b50-5dff-a12b-7b4f4573eaa3', 'Walton Pfannerstill');
INSERT INTO public."ManageReturn" VALUES ('d64f5ba9-783d-59bd-b6b3-c0aa4d953763', 'Melvin Cummerata');
INSERT INTO public."ManageReturn" VALUES ('57a89f09-6a8d-5e55-8b99-842a94fea79e', 'Reynold Adams');
INSERT INTO public."ManageReturn" VALUES ('03dccb80-f795-5257-91c1-6a6693f5acd3', 'Arvel Leuschke');
INSERT INTO public."ManageReturn" VALUES ('7ec02398-db98-519a-8430-5ced432076ec', 'Maye Hintz');
INSERT INTO public."ManageReturn" VALUES ('b1418b83-cd4e-5adb-b49a-d884e52ad0fc', 'Malcolm Stamm');
INSERT INTO public."ManageReturn" VALUES ('14a5d1ad-45ef-5352-914b-678d1f3d8677', 'Kristina Hyatt');
INSERT INTO public."ManageReturn" VALUES ('f8e045dd-c78e-53c9-8240-9533a202a280', 'Jarrell Becker');
INSERT INTO public."ManageReturn" VALUES ('8e415301-09ae-5308-9db1-3d930f8654f1', 'Friedrich Emmerich');
INSERT INTO public."ManageReturn" VALUES ('b70fbcb8-b3b0-5f65-846f-772b590cd583', 'Uriah Okuneva');
INSERT INTO public."ManageReturn" VALUES ('6fde2a0b-cdc3-5676-97f2-6db9ad9c4547', 'Gabrielle Crooks');
INSERT INTO public."ManageReturn" VALUES ('6ec984c9-f50e-5c81-84ca-4e02b288499b', 'Jermaine Runolfsdottir');
INSERT INTO public."ManageReturn" VALUES ('9028c25a-d760-50bc-8228-8d6c3c9a1351', 'Jayne Schroeder');
INSERT INTO public."ManageReturn" VALUES ('63df4bd0-7fe6-5b8d-b7fb-87f96c05962c', 'Salvatore Stanton');
INSERT INTO public."ManageReturn" VALUES ('432819b7-86d3-59d1-b779-617d3f697cdb', 'Emilio Zemlak');
INSERT INTO public."ManageReturn" VALUES ('409f453e-3317-57ef-bfe3-2529e35dd5e6', 'Lizzie Becker');
INSERT INTO public."ManageReturn" VALUES ('d69375a9-1632-51d7-8eb2-815e86a18574', 'Veronica O''Hara');
INSERT INTO public."ManageReturn" VALUES ('63fa8249-f1d3-5ff6-b34b-688e8c76da1f', 'Julianne Pacocha');
INSERT INTO public."ManageReturn" VALUES ('201768d8-0c22-51ba-84c1-e706b2bce57d', 'Sabryna Wilderman');
INSERT INTO public."ManageReturn" VALUES ('825d48a1-e886-5730-8d24-0aaa10f9ec31', 'Deanna Jacobi');
INSERT INTO public."ManageReturn" VALUES ('e4dd3a25-c4d8-5938-96d8-5d461746127e', 'Clifford Hintz');
INSERT INTO public."ManageReturn" VALUES ('a6570dd4-c397-5904-a73d-ee1dbff504cb', 'Armand Hyatt');
INSERT INTO public."ManageReturn" VALUES ('898ac794-2aa3-5cf0-a7ae-7686b163d18a', 'Connor Heller');
INSERT INTO public."ManageReturn" VALUES ('4fb12ea7-d0e9-55c2-959c-424eef025725', 'Justus Zemlak');
INSERT INTO public."ManageReturn" VALUES ('1587f6e7-1fe3-53c0-b2cd-476bd796c8a8', 'Ashton Lubowitz');
INSERT INTO public."ManageReturn" VALUES ('78ef1410-3fb4-5b23-857b-22511be3f3a2', 'Lindsay Johnson');
INSERT INTO public."ManageReturn" VALUES ('082f2069-28f7-5bcf-9815-46e86907910f', 'Jarvis Boyer');
INSERT INTO public."ManageReturn" VALUES ('20c3e38a-bc9e-57de-a3dc-3ed4e51776a4', 'Eden Schmidt');
INSERT INTO public."ManageReturn" VALUES ('78fe1caf-9ae0-5b86-a900-e25b49475abd', 'Carey Hodkiewicz');
INSERT INTO public."ManageReturn" VALUES ('02c207d7-ed6d-51d6-847f-4e8ab8937125', 'Jan Schaden');
INSERT INTO public."ManageReturn" VALUES ('bc3a38e4-723c-5281-aba0-5d3a8b22ba90', 'Dominic Koelpin');
INSERT INTO public."ManageReturn" VALUES ('ca9a0a0d-be91-54c5-b750-64a5094b2019', 'Skye Thiel');
INSERT INTO public."ManageReturn" VALUES ('9d9605d4-9047-5cc9-b037-17d9b6bb6697', 'Clarabelle Dach');
INSERT INTO public."ManageReturn" VALUES ('45f656ab-2260-5691-a2d6-4dd8475e848f', 'Javier Okuneva');
INSERT INTO public."ManageReturn" VALUES ('4666ec94-86a2-5718-9594-c0649a26ff87', 'Alicia Herman');
INSERT INTO public."ManageReturn" VALUES ('5334bb64-d353-53d4-a4e9-4fa2ae6d3ad1', 'Maggie Quigley');
INSERT INTO public."ManageReturn" VALUES ('b325a522-50e3-574a-9a08-8e7e051de48f', 'Donna Skiles');
INSERT INTO public."ManageReturn" VALUES ('526e853e-7c69-5997-acd4-596cc31799e8', 'Annabelle Von');
INSERT INTO public."ManageReturn" VALUES ('2dd32bbe-c639-5220-9b38-e0b97b1319fc', 'Melany Schuster');
INSERT INTO public."ManageReturn" VALUES ('b0e9894e-f269-5f69-a2fb-e38369b0e96c', 'Jamar Bogisich');
INSERT INTO public."ManageReturn" VALUES ('bc19de2a-1b47-50bc-97d4-d045f43a2fee', 'Ramon Block');
INSERT INTO public."ManageReturn" VALUES ('843d08b9-1e02-543b-a887-b53dd81f61ac', 'Marge Mohr');
INSERT INTO public."ManageReturn" VALUES ('0106e08d-1f74-56e0-96cf-d460102e756e', 'Imelda Ebert');


--
-- TOC entry 4242 (class 0 OID 2148891)
-- Dependencies: 234
-- Data for Name: Message; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."Message" VALUES ('38159845-9dff-5395-b74b-4f484b700a9a', '2022-09-29 15:06:44.375', 'Rako', NULL, NULL, NULL, NULL, '{"Koa yuko"}');
INSERT INTO public."Message" VALUES ('6615c66e-644f-5602-8d73-41c471673f43', '2022-09-29 15:06:44.375', 'Miyumiso', NULL, NULL, NULL, NULL, '{"Misomi miso"}');
INSERT INTO public."Message" VALUES ('e130a7b6-7fc3-5718-9a3a-98eb0b0fdbaa', '2022-09-29 15:06:44.375', 'Soviyu', NULL, NULL, NULL, NULL, '{"Soraso rasoyumi"}');
INSERT INTO public."Message" VALUES ('39b40653-b6b5-55d0-888e-4302b5112c03', '2022-09-29 15:06:44.375', 'Rakorayu', NULL, NULL, NULL, NULL, '{"Rakorami yuavi ramiyumi"}');
INSERT INTO public."Message" VALUES ('3dd60d30-478e-52de-8f1a-339dc8d66fc9', '2022-09-29 15:06:44.375', 'Yusoviso', NULL, NULL, NULL, NULL, '{"Rako somisoa"}');
INSERT INTO public."Message" VALUES ('a706b4ea-3ab0-5f81-b9a0-7065ddf98285', '2022-09-29 15:06:44.375', 'Miyuvi', NULL, NULL, NULL, NULL, '{"Sovikora rasoaso koa"}');
INSERT INTO public."Message" VALUES ('42fc9c7a-e5ca-5d5f-a0c2-75f00ef32c1e', '2022-09-29 15:06:44.375', 'Rakoyura', NULL, NULL, NULL, NULL, '{"Komira soyusovi"}');
INSERT INTO public."Message" VALUES ('0768abc8-e16b-5106-b78c-03e6a1d6777c', '2022-09-29 15:06:44.375', 'Koyuvi', NULL, NULL, NULL, NULL, '{"Ravikora yusoyu yuvi"}');
INSERT INTO public."Message" VALUES ('d3d71418-b3c2-5fd9-aa54-0a461986c600', '2022-09-29 15:06:44.375', 'Miyu', NULL, NULL, NULL, NULL, '{"Mira virami"}');
INSERT INTO public."Message" VALUES ('80e3b77b-5456-5293-82ec-6a49434b9151', '2022-09-29 15:06:44.375', 'Rayu', NULL, NULL, NULL, NULL, '{"Komiraso virami"}');
INSERT INTO public."Message" VALUES ('10733446-f1b1-5c34-809b-3e42ddbc207a', '2022-09-29 15:06:44.375', 'Mirami', NULL, NULL, NULL, NULL, '{"Rayurayu yukoyu"}');
INSERT INTO public."Message" VALUES ('df99573b-750a-5403-8e99-4cf5824e7906', '2022-09-29 15:06:44.375', 'Korakora', NULL, NULL, NULL, NULL, '{"Kora yukovi"}');
INSERT INTO public."Message" VALUES ('1358dc3e-4796-5b69-ba9d-5d8aca19fe71', '2022-09-29 15:06:44.375', 'Mirako', NULL, NULL, NULL, NULL, '{"Soyu miami yusoyu"}');
INSERT INTO public."Message" VALUES ('be20d122-75bd-5c09-bed8-605d10500962', '2022-09-29 15:06:44.375', 'Korasoyu', NULL, NULL, NULL, NULL, '{"Miyu korami komiyuvi"}');
INSERT INTO public."Message" VALUES ('8aa18ade-4ce1-5c80-b637-6df503a0a469', '2022-09-29 15:06:44.375', 'Koyuvi', NULL, NULL, NULL, NULL, '{"Rasovia vikovi"}');
INSERT INTO public."Message" VALUES ('924c63c9-3fb3-5d7f-8548-d91b5f43f8a6', '2022-09-29 15:06:44.375', 'Sora', NULL, NULL, NULL, NULL, '{"Soyusoyu mia kovisomi"}');
INSERT INTO public."Message" VALUES ('84f4cb6e-b391-5109-9cf2-80ab925c1326', '2022-09-29 15:06:44.375', 'Koasomi', NULL, NULL, NULL, NULL, '{"Viyuso korakora"}');
INSERT INTO public."Message" VALUES ('f3e183bf-dc03-5532-9b03-b33cf8dbac84', '2022-09-29 15:06:44.375', 'Miamia', NULL, NULL, NULL, NULL, '{"Miyuvi yuvisoa visora"}');
INSERT INTO public."Message" VALUES ('0a188e62-d829-5d53-a68b-4dbb6674a314', '2022-09-29 15:06:44.375', 'Koyuayu', NULL, NULL, NULL, NULL, '{"Viayu sora rakorami"}');
INSERT INTO public."Message" VALUES ('6029f7c0-7b5d-51de-941c-3814a5c31b89', '2022-09-29 15:06:44.375', 'Korako', NULL, NULL, NULL, NULL, '{"Miso komira"}');
INSERT INTO public."Message" VALUES ('d40711b0-344c-5074-b53a-481009f00761', '2022-09-29 15:06:44.375', 'Soviyu', NULL, NULL, NULL, NULL, '{"Rayu miraviyu soami"}');
INSERT INTO public."Message" VALUES ('27fde34a-5d19-5957-b9b5-10aa598d0794', '2022-09-29 15:06:44.375', 'Koakomi', NULL, NULL, NULL, NULL, '{"Misoami misorayu"}');
INSERT INTO public."Message" VALUES ('a3d53c34-7d03-5bcf-beb0-f2c1727e67fd', '2022-09-29 15:06:44.375', 'Somi', NULL, NULL, NULL, NULL, '{"Ramiako sora"}');
INSERT INTO public."Message" VALUES ('0bf3665f-f543-50ac-9aa7-bf8f8114db44', '2022-09-29 15:06:44.375', 'Yumiyu', NULL, NULL, NULL, NULL, '{"Koa visomiko rasoyua"}');
INSERT INTO public."Message" VALUES ('123f5ba3-753c-5f81-87bd-b8c7a5fc823d', '2022-09-29 15:06:44.375', 'Miyu', NULL, NULL, NULL, NULL, '{"Raso yua"}');
INSERT INTO public."Message" VALUES ('c34f9b2e-7620-5832-bc6b-98db16c01ea5', '2022-09-29 15:06:44.375', 'Mikorako', NULL, NULL, NULL, NULL, '{"Misoyu yumi"}');
INSERT INTO public."Message" VALUES ('00d3b240-555a-5323-a9b9-5bd260bb5b08', '2022-09-29 15:06:44.375', 'Ravi', NULL, NULL, NULL, NULL, '{"Soviyua rayurako"}');
INSERT INTO public."Message" VALUES ('af0ec892-e727-5b16-b2eb-f619066a0013', '2022-09-29 15:06:44.375', 'Yua', NULL, NULL, NULL, NULL, '{"Soyuayu yukora"}');
INSERT INTO public."Message" VALUES ('25da5cdf-29e9-5926-b7ef-68c3999a2078', '2022-09-29 15:06:44.375', 'Rakoavi', NULL, NULL, NULL, NULL, '{"Rakoaso visora"}');
INSERT INTO public."Message" VALUES ('e5ceb970-37a4-534f-aa70-44b4495d99a0', '2022-09-29 15:06:44.375', 'Vira', NULL, NULL, NULL, NULL, '{"Misomi yusoyuso yusoako"}');
INSERT INTO public."Message" VALUES ('42867acc-c321-574d-999c-464b36873531', '2022-09-29 15:06:44.375', 'Rayua', NULL, NULL, NULL, NULL, '{"Ravi yumiyu koamiko"}');
INSERT INTO public."Message" VALUES ('d4189adf-34e0-550c-b0d6-817e9da68d24', '2022-09-29 15:06:44.375', 'Viso', NULL, NULL, NULL, NULL, '{"Viraso viayura"}');
INSERT INTO public."Message" VALUES ('24fe1101-ef4b-5c73-b606-0c56f530c1c0', '2022-09-29 15:06:44.375', 'Yua', NULL, NULL, NULL, NULL, '{"Yuravi vikoyuvi"}');
INSERT INTO public."Message" VALUES ('0628b84d-2b8c-5ffc-8b9c-e05de7fdec8d', '2022-09-29 15:06:44.375', 'Rasoa', NULL, NULL, NULL, NULL, '{"Ravia miraviso mirakoa"}');
INSERT INTO public."Message" VALUES ('db612876-cda9-5dda-82b0-4b491355b5a3', '2022-09-29 15:06:44.375', 'Yusomiko', NULL, NULL, NULL, NULL, '{"Sorako koyu"}');
INSERT INTO public."Message" VALUES ('b9cd7d68-a5f6-5002-901a-bb3957529a43', '2022-09-29 15:06:44.375', 'Komiyu', NULL, NULL, NULL, NULL, '{"Ramiyumi miyumi via"}');
INSERT INTO public."Message" VALUES ('72ab7222-3330-586c-b501-21916d96785b', '2022-09-29 15:06:44.375', 'Somi', NULL, NULL, NULL, NULL, '{"Vikovi yuaviso"}');
INSERT INTO public."Message" VALUES ('a6dc7f7b-edfb-5302-8d81-a9dfae92c8b0', '2022-09-29 15:06:44.375', 'Mikomi', NULL, NULL, NULL, NULL, '{"Sorako visomiko virami"}');
INSERT INTO public."Message" VALUES ('f556549e-b369-5ad6-91e7-e8812944c138', '2022-09-29 15:06:44.375', 'Soyurami', NULL, NULL, NULL, NULL, '{"Rasoyu yumisomi"}');
INSERT INTO public."Message" VALUES ('716d9d27-fa15-54ca-9450-a91b7de8fda5', '2022-09-29 15:06:44.375', 'Ramiaso', NULL, NULL, NULL, NULL, '{"Raviavi sovi"}');
INSERT INTO public."Message" VALUES ('c2045277-b802-5f18-96cc-72f6d666c82c', '2022-09-29 15:06:44.375', 'Rako', NULL, NULL, NULL, NULL, '{"Soyuviso yurami rami"}');
INSERT INTO public."Message" VALUES ('28bcaa40-190f-552b-9049-9c73d486976b', '2022-09-29 15:06:44.375', 'Visoviso', NULL, NULL, NULL, NULL, '{"Rami ravikora yuviayu"}');
INSERT INTO public."Message" VALUES ('44cbc9b6-a67e-5f3c-b6d6-27c9de5c76c1', '2022-09-29 15:06:44.375', 'Rakoavi', NULL, NULL, NULL, NULL, '{"Yua yusoravi"}');
INSERT INTO public."Message" VALUES ('c71b8316-5546-5bc0-97d3-d929b35f7f07', '2022-09-29 15:06:44.375', 'Miyua', NULL, NULL, NULL, NULL, '{"Visoyu miami"}');
INSERT INTO public."Message" VALUES ('a26d393c-fc7a-51de-b1ee-c9ad3f29661f', '2022-09-29 15:06:44.375', 'Miko', NULL, NULL, NULL, NULL, '{"Miyu yuasomi"}');
INSERT INTO public."Message" VALUES ('577f54d1-2a93-581b-9ba8-dae50febc4b7', '2022-09-29 15:06:44.375', 'Visoyu', NULL, NULL, NULL, NULL, '{"Rako yusoviko"}');
INSERT INTO public."Message" VALUES ('4bf8f413-7fbf-5776-bce7-bb048ff77cef', '2022-09-29 15:06:44.375', 'Mikoviko', NULL, NULL, NULL, NULL, '{"Miakovi soyu soaviyu"}');
INSERT INTO public."Message" VALUES ('8748313d-1734-5a2b-90e9-31b855288923', '2022-09-29 15:06:44.375', 'Rasorayu', NULL, NULL, NULL, NULL, '{"Koyuko miso kovikovi"}');
INSERT INTO public."Message" VALUES ('2cfc5f9e-a584-51ff-a225-f3c105cc0c35', '2022-09-29 15:06:44.375', 'Miramira', NULL, NULL, NULL, NULL, '{"Kovi mikovi"}');
INSERT INTO public."Message" VALUES ('4047ff75-2005-5d68-81a7-0ed7db9b67a4', '2022-09-29 15:06:44.375', 'Viramiyu', NULL, NULL, NULL, NULL, '{"Yua yumi soyuso"}');
INSERT INTO public."Message" VALUES ('ae5852c9-687e-51e4-a56c-a8ecfad218f7', '2022-09-29 15:06:44.375', 'Yuraviko', NULL, NULL, NULL, NULL, '{"Rako viyuayu"}');
INSERT INTO public."Message" VALUES ('2056b40b-c738-5cc8-ae70-c2ac3b9b1972', '2022-09-29 15:06:44.375', 'Rayu', NULL, NULL, NULL, NULL, '{"Viyuravi yumia mirami"}');
INSERT INTO public."Message" VALUES ('4b9914ef-64e8-5dd2-bffe-98d0a2a83075', '2022-09-29 15:06:44.375', 'Kovikomi', NULL, NULL, NULL, NULL, '{"Ravi yumikoa rayumi"}');
INSERT INTO public."Message" VALUES ('86c5766c-0ee7-5626-8b89-f7243098c462', '2022-09-29 15:06:44.375', 'Yuvi', NULL, NULL, NULL, NULL, '{"Koviaso vikovi rasoami"}');
INSERT INTO public."Message" VALUES ('1b049d5d-a915-5e08-be0a-77492190d556', '2022-09-29 15:06:44.375', 'Viraviso', NULL, NULL, NULL, NULL, '{"Viami miyuvia miso"}');
INSERT INTO public."Message" VALUES ('be0d896e-c5c9-56d2-96fe-4f486be233b6', '2022-09-29 15:06:44.375', 'Miavira', NULL, NULL, NULL, NULL, '{"Raviko koa"}');
INSERT INTO public."Message" VALUES ('1aad848a-c317-5a3a-a960-72f058e63abc', '2022-09-29 15:06:44.375', 'Yuso', NULL, NULL, NULL, NULL, '{"Koa koavi vikoyua"}');
INSERT INTO public."Message" VALUES ('86a9cd6f-3baf-530b-ae16-0fe8195c998d', '2022-09-29 15:06:44.375', 'Vikovi', NULL, NULL, NULL, NULL, '{"Rakomia sovisomi koviso"}');
INSERT INTO public."Message" VALUES ('172c0211-3381-5a5c-87b0-b5212611f03b', '2022-09-29 15:06:44.375', 'Viravira', NULL, NULL, NULL, NULL, '{"Miyura rasorami soviayu"}');
INSERT INTO public."Message" VALUES ('e040db68-bfcc-5b48-b020-87327f3ebc58', '2022-09-29 15:06:44.375', 'Yumia', NULL, NULL, NULL, NULL, '{"Korasoa yumikovi"}');
INSERT INTO public."Message" VALUES ('bd885db6-01eb-54dc-b8d2-70c39ac61203', '2022-09-29 15:06:44.375', 'Koyusoa', NULL, NULL, NULL, NULL, '{"Sorayu miko"}');
INSERT INTO public."Message" VALUES ('6cee2d7e-b2ae-56f8-98c2-2a2595f0086a', '2022-09-29 15:06:44.375', 'Korakovi', NULL, NULL, NULL, NULL, '{"Vira korasoa"}');
INSERT INTO public."Message" VALUES ('4a7495e1-7476-550c-82af-1d669d569be1', '2022-09-29 15:06:44.375', 'Yuviami', NULL, NULL, NULL, NULL, '{"Komiko soyu raviyu"}');
INSERT INTO public."Message" VALUES ('419c7f78-f43e-5795-939b-c043628a5b78', '2022-09-29 15:06:44.375', 'Ramia', NULL, NULL, NULL, NULL, '{"Raso ravira"}');
INSERT INTO public."Message" VALUES ('5cfe9cbf-1203-5449-9d5f-d3306e4bdff3', '2022-09-29 15:06:44.375', 'Soakora', NULL, NULL, NULL, NULL, '{"Via miyuvi"}');
INSERT INTO public."Message" VALUES ('e45d79b3-8c52-5c86-97d7-2c13adf2c485', '2022-09-29 15:06:44.375', 'Yura', NULL, NULL, NULL, NULL, '{"Sorasovi yumiami viko"}');
INSERT INTO public."Message" VALUES ('14e7f3f4-f315-504b-bda3-901be07f9339', '2022-09-29 15:06:44.375', 'Yuvi', NULL, NULL, NULL, NULL, '{"Yua miamiko yuvi"}');
INSERT INTO public."Message" VALUES ('470ba4ec-2029-5bd3-b532-7767cc789c12', '2022-09-29 15:06:44.375', 'Vikorami', NULL, NULL, NULL, NULL, '{"Yura mirakoyu"}');
INSERT INTO public."Message" VALUES ('5291f834-cb11-5770-8cd4-759dd0b9e6e0', '2022-09-29 15:06:44.375', 'Miso', NULL, NULL, NULL, NULL, '{"Yusora yuvi"}');
INSERT INTO public."Message" VALUES ('aa6412a8-58c7-5cca-bd63-634939e813c8', '2022-09-29 15:06:44.375', 'Yuavi', NULL, NULL, NULL, NULL, '{"Miyuko kovi viaso"}');
INSERT INTO public."Message" VALUES ('9acb73fd-34ad-5ff2-9895-7b838998050a', '2022-09-29 15:06:44.375', 'Ravisovi', NULL, NULL, NULL, NULL, '{"Miyuko miso yusomi"}');
INSERT INTO public."Message" VALUES ('d4fb0462-5917-51ae-9105-2beee9f5937e', '2022-09-29 15:06:44.375', 'Sovi', NULL, NULL, NULL, NULL, '{"Koyuvi ramisoa rayu"}');
INSERT INTO public."Message" VALUES ('e8e87952-ea37-574a-8d7d-92e30c75f0bf', '2022-09-29 15:06:44.375', 'Soa', NULL, NULL, NULL, NULL, '{"Kora somiaso koyukomi"}');
INSERT INTO public."Message" VALUES ('4f5da7b5-6b30-5a3b-9c1f-7c3c598fc193', '2022-09-29 15:06:44.375', 'Viyu', NULL, NULL, NULL, NULL, '{"Koyu rakomi"}');
INSERT INTO public."Message" VALUES ('d1e09d53-b81b-5073-b745-2a33ddae1131', '2022-09-29 15:06:44.375', 'Soyu', NULL, NULL, NULL, NULL, '{"Raso virayuso"}');
INSERT INTO public."Message" VALUES ('b2835897-9933-5538-bbb4-c00820149e6a', '2022-09-29 15:06:44.375', 'Ravisoa', NULL, NULL, NULL, NULL, '{"Mira vikomia"}');
INSERT INTO public."Message" VALUES ('dc662ff4-698e-574f-91fa-eb429dacc986', '2022-09-29 15:06:44.375', 'Rasoyura', NULL, NULL, NULL, NULL, '{"Yuvira mikoyuko visoavi"}');
INSERT INTO public."Message" VALUES ('acb81bb0-124d-5f2d-aabc-d56f618e1eb1', '2022-09-29 15:06:44.375', 'Ravi', NULL, NULL, NULL, NULL, '{"Viso somirami soyu"}');
INSERT INTO public."Message" VALUES ('a196b0cf-e33e-5ba3-9a8c-3787cf65d541', '2022-09-29 15:06:44.375', 'Kovi', NULL, NULL, NULL, NULL, '{"Soyumira viraso yura"}');
INSERT INTO public."Message" VALUES ('7a2edd9d-1ac1-5a52-a207-a13c6e9a9dc7', '2022-09-29 15:06:44.375', 'Vikovi', NULL, NULL, NULL, NULL, '{"Ramira sovi rakora"}');
INSERT INTO public."Message" VALUES ('eb604902-bc99-51f2-9b3a-bd644fd048f6', '2022-09-29 15:06:44.375', 'Rako', NULL, NULL, NULL, NULL, '{"Mikomiko soyu"}');
INSERT INTO public."Message" VALUES ('03387393-d037-5ab1-8f5a-d6f6e3554224', '2022-09-29 15:06:44.375', 'Koyuavi', NULL, NULL, NULL, NULL, '{"Mirayua soyuvi komiaso"}');
INSERT INTO public."Message" VALUES ('35514b18-3abd-51f5-b694-9009da912826', '2022-09-29 15:06:44.375', 'Mira', NULL, NULL, NULL, NULL, '{"Yurami yukoyuko"}');
INSERT INTO public."Message" VALUES ('66513709-3737-530d-99fd-c38689800ed6', '2022-09-29 15:06:44.375', 'Miyumi', NULL, NULL, NULL, NULL, '{"Yua viyuviko"}');
INSERT INTO public."Message" VALUES ('c50f47a3-6677-5c9e-8b77-3fddcab881c7', '2022-09-29 15:06:44.375', 'Miyu', NULL, NULL, NULL, NULL, '{"Virayu komi yuavi"}');
INSERT INTO public."Message" VALUES ('408ee602-aca7-5fb0-8916-90ea9af61b24', '2022-09-29 15:06:44.375', 'Miyuso', NULL, NULL, NULL, NULL, '{"Soravi yuko"}');
INSERT INTO public."Message" VALUES ('a32db822-9a4e-5740-80a6-2ca76ee99398', '2022-09-29 15:06:44.375', 'Kovi', NULL, NULL, NULL, NULL, '{"Somi yuviso"}');
INSERT INTO public."Message" VALUES ('e148ef17-01e0-5d4e-95d4-f80e44c22bc2', '2022-09-29 15:06:44.375', 'Yuko', NULL, NULL, NULL, NULL, '{"Ravi yuvisoa"}');
INSERT INTO public."Message" VALUES ('6c85405f-bd31-5702-a8bf-4d30243193da', '2022-09-29 15:06:44.375', 'Sorami', NULL, NULL, NULL, NULL, '{"Korako kovikora vira"}');
INSERT INTO public."Message" VALUES ('9d8bbd82-fd87-56c8-b653-4f4f08b115ae', '2022-09-29 15:06:44.375', 'Koyu', NULL, NULL, NULL, NULL, '{"Koyua vira koraviso"}');
INSERT INTO public."Message" VALUES ('4722ea7e-276d-51b6-8688-5bbbaba80306', '2022-09-29 15:06:44.375', 'Soyuami', NULL, NULL, NULL, NULL, '{"Sora komikomi koyua"}');
INSERT INTO public."Message" VALUES ('f4fab7a6-d06b-5d39-8d46-008a1075719e', '2022-09-29 15:06:44.375', 'Soyu', NULL, NULL, NULL, NULL, '{"Mikomiso via vikora"}');
INSERT INTO public."Message" VALUES ('dfc18dac-64ac-5e42-81eb-b4d9ab123214', '2022-09-29 15:06:44.375', 'Mia', NULL, NULL, NULL, NULL, '{"Rayuvi yumi"}');
INSERT INTO public."Message" VALUES ('ba8117ed-59d9-5bfe-89f7-b2654cad06f8', '2022-09-29 15:06:44.375', 'Yuso', NULL, NULL, NULL, NULL, '{"Koviso komia rakovira"}');
INSERT INTO public."Message" VALUES ('d07d47c8-65c1-5f4f-b572-dc2ecc8064c8', '2022-09-29 15:06:44.375', 'Raviso', NULL, NULL, NULL, NULL, '{"Kovi ramiaso soaso"}');
INSERT INTO public."Message" VALUES ('af83c935-20b0-5af3-bf2e-712c5434816e', '2022-09-29 15:06:44.375', 'Miyu', NULL, NULL, NULL, NULL, '{"Mira somikoa"}');
INSERT INTO public."Message" VALUES ('4a10dfc7-92f6-5946-85cf-443797d58c01', '2022-09-29 15:06:44.375', 'Miyu', NULL, NULL, NULL, NULL, '{"Soviso visomiko yuravi"}');
INSERT INTO public."Message" VALUES ('b1443b19-7afe-512d-bc80-fcc1ebe6dd26', '2022-09-29 15:06:44.375', 'Yuvi', NULL, NULL, NULL, NULL, '{"Yuvira yumikoa"}');
INSERT INTO public."Message" VALUES ('8a8d6a3a-39f9-5327-8881-faaedadb4f91', '2022-09-29 15:06:44.375', 'Soayumi', NULL, NULL, NULL, NULL, '{"Rakovira vikovi"}');
INSERT INTO public."Message" VALUES ('891a961d-ae87-52ed-b4cb-d865fa67274b', '2022-09-29 15:06:44.375', 'Yua', NULL, NULL, NULL, NULL, '{"Vikoviyu viraso"}');


--
-- TOC entry 4243 (class 0 OID 2148897)
-- Dependencies: 235
-- Data for Name: Order; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."Order" VALUES ('1941807b-4d57-576f-90b2-754180189dee', '2022-09-29 15:06:36.89', '2020-06-22 05:41:35', 'Miso sorako', 'Viko yukoa', 'Yuamira somi', NULL, '5185357c-a790-5fc2-8e81-1e3bf79f63d6', 1, '0c624a8f-a202-5353-af27-e0537b1cb8d9', 47877, 'Viravi komi yusoa', 18199, 46779, 36742, 8076, 'Yuvirami rakovi miavi', 'Yusoako yukomi', 'Mira koa', 'Yumiyura viso', 'Soyua soakora vikoyu', 'Soakoa koami yuko', 'Sovi miako visomia', false, 'Rasoa yurayu sovirayu', 'Ravira rako', 'Mikorayu yuso', 'Kora virasoyu', 'Yurayua viko', NULL, 'Soyura miyu', 'Viso mia koaso', 'Rami kovia', 'Viyu yuviayu', 'Yumi komiyu sorakovi', 'Rayumiso soayua', '1985-10-14 21:58:45', 'Yukoviyu miayua', 'Komi yukoyu', 'Somi yurasovi miyu', 9841, '1988-09-01 08:10:20', '1987-04-28 15:35:23', '2003-04-04 15:10:31', 'Misomi mia sovikoyu', 'Yusorami yuraso koami', 'Mirayu', 'Soravi mirasoyu', 'Soravia rayu', NULL, 'Koyumi sora yukoyuso', 'Komi soavi', 'Koyura yuso', NULL, '1984-01-09 12:25:53', 43449, false, '1984-09-01 20:45:59', '1996-09-01 09:07:47', '1992-05-05 04:54:03', false, 41016, '1982-07-27 18:51:32', NULL, '1994-07-27 07:04:14', 18843, 40668, '2014-03-03 02:22:26', 'Yukora ravi soyuvira', 'Viamiyu koyuko', 'Miyu misovi', '2013-06-26 18:02:03', 11358, 320, 39489, 4977, NULL, 'Soraso soviyuso rayumi', 32010, 'Koaso soamiso', '1985-06-18 05:11:28', '{}');
INSERT INTO public."Order" VALUES ('192b76dd-86f0-5c4a-bb30-8c6d94aa0f72', '2022-09-29 15:06:36.89', '2020-07-23 18:19:39', 'Yura viramira', 'Sovi koyuviyu koami', 'Kovira yura', NULL, '7aea35aa-5a77-5acf-8161-2fe91b29d3a2', 2, 'da74a0d6-81d8-5f28-944d-861c1ddc36b0', 39536, 'Mirakoa miso korayua', 5959, 33932, 31829, 40897, 'Yuso mikomi yukovira', 'Kovia viso yuakoyu', 'Ravi viyuavi yumisomi', 'Yusovi viaso yusoyumi', 'Soa rayuvi', 'Viso yuvira', 'Ravi miravia', false, 'Soasovi soviso', 'Sovi mikoa', 'Visoviko yuaso', 'Komiayu yuko', 'Mia soyuso yuso', NULL, 'Korami rakoraso', 'Rakomi viko soa', 'Yukovi soa viyurako', 'Viyuavi miyuso soa', 'Miso yusomiko mirako', 'Miyu sovira', '2000-05-09 04:45:51', 'Rayuso rako', 'Koyuvi viyu', 'Mirako soami kovikora', 30435, '1998-03-15 02:41:37', '1984-09-17 20:58:02', '1998-07-23 18:23:02', 'Yumirayu yukoyu yurayua', 'Rami miyukomi', 'Miyu', 'Soyu koaso', 'Mia soraviso soavira', NULL, 'Viakoa ravi', 'Sora viyusoyu miso', 'Miyumira viko', NULL, '2010-03-27 15:06:11', 55945, false, '1987-04-12 15:31:37', '2016-09-01 21:12:27', '1986-03-19 14:27:42', false, 61923, '1984-05-05 04:18:18', NULL, '1981-10-18 09:26:18', 47722, 28112, '1998-07-15 18:25:28', 'Komi soviko', 'Viko misovi', 'Visomi somi yusoyu', '2012-09-01 08:37:57', 16331, 15499, 10413, 57392, NULL, 'Soaviyu yuraviso soavi', 41615, 'Komiso yukoyua koraviyu', '1985-10-22 21:50:15', '{}');
INSERT INTO public."Order" VALUES ('7a44fea2-4748-564f-bb19-ed522ac41168', '2022-09-29 15:06:36.89', '2020-10-06 21:45:12', 'Ravi yua rayuvi', 'Yurakoa yuvia soramiyu', 'Ramira koyu', NULL, '5444f259-27c2-5313-bf11-7237b395a1c7', 3, 'fce00bf3-4259-555e-9c5e-19d215ee0b50', 22171, 'Soyumi komikoyu yuamiso', 2372, 8987, 20860, 20000, 'Viso viyua', 'Miyu rasovi miramiko', 'Komi misoyu yuvi', 'Yuavi yuso', 'Somirako mira', 'Yuravi miyu', 'Yuvikoa yumi', false, 'Ravi rasomi', 'Misora rayua visoami', 'Viyu koviyu rami', 'Miraso soyumira soamiso', 'Yumia ravi', NULL, 'Virami rami', 'Miyu mia', 'Ravikoyu rakoa', 'Mira koyuami', 'Yusovia miraviyu', 'Koa soyu koviso', '2002-11-07 22:38:26', 'Ramiayu via viyu', 'Yuso kovira viso', 'Koako mikomi ravi', 54081, '2018-03-23 14:53:25', '2017-10-10 22:04:51', '1992-09-17 20:33:54', 'Viami rayu', 'Yukora yuvisomi', 'Yuko', 'Rayuravi koyu', 'Rasovi somi ramiyuvi', NULL, 'Viso ramiraso', 'Vira soasomi somiso', 'Viso koayu komisovi', NULL, '2015-04-24 03:24:50', 61312, false, '2004-01-17 00:27:46', '2017-10-14 22:02:07', '2018-03-07 14:44:38', false, 13020, '2019-12-21 00:00:50', NULL, '2013-10-22 09:33:00', 46819, 62888, '1980-05-25 16:46:28', 'Yuvira soayuvi miayu', 'Viyurayu vikovi', 'Rayuvi rami ravisovi', '2016-09-01 21:11:17', 40067, 56858, 25592, 5853, NULL, 'Koyuko yuvi', 10821, 'Raso virami', '1980-09-17 08:36:01', '{}');
INSERT INTO public."Order" VALUES ('cd67cd28-d749-5858-83bc-be2f27f69918', '2022-09-29 15:06:36.89', '2020-07-11 07:05:50', 'Misoyu sovi soa', 'Soyukoa rako', 'Rasomira mia mikoa', NULL, '4348530a-32bd-511d-95d3-bcb54f401b9f', 4, 'e6f1cec6-6c43-5a5e-a4d2-36bc4a4cb081', 50248, 'Kovikovi koaso koayuko', 29828, 46838, 24175, 19294, 'Mirako yuso via', 'Soa kora', 'Yuvira soako', 'Raso mirakomi raviso', 'Soyuraso miko', 'Mikomi viyu', 'Mirakoa yua', false, 'Somiako virayu mira', 'Mikovi misoa visovi', 'Viko miaso', 'Rasovi rami', 'Rayumi koramia yuso', NULL, 'Koviyu rayumiyu', 'Viyuvia somi', 'Yuramiyu koaso', 'Yurayu kovi koa', 'Somikora yuviyu sovi', 'Yukomia miyumi miko', '2013-06-02 17:58:09', 'Komikoyu yuviso soaso', 'Korasoa sovi kovikora', 'Rami mikoaso soramira', 17979, '2011-12-28 23:20:40', '1994-07-27 07:05:10', '2005-10-22 09:50:29', 'Sorako misomira', 'Viyuvi yua', 'Yurako', 'Yua virami', 'Koviyu misoravi', NULL, 'Rakora koyuvira', 'Raviko miso', 'Sora soyuviyu', NULL, '2005-10-18 09:59:03', 55206, false, '1982-07-07 18:47:28', '1984-01-13 12:40:32', '1992-09-17 20:43:28', false, 20636, '1988-09-25 08:19:01', NULL, '1989-10-10 09:10:12', 60312, 9521, '1981-06-14 17:43:05', 'Kovi miyurami', 'Virayu koyumia soravi', 'Yukoyua rayu', '1992-05-25 04:58:42', 32124, 2323, 2918, 24897, NULL, 'Viyumi yuayu yukoyumi', 2572, 'Miyu rakovi', '1993-06-26 06:03:20', '{}');
INSERT INTO public."Order" VALUES ('4d0dd818-560c-5b2a-b46d-50c9d5087013', '2022-09-29 15:06:36.89', '2020-01-13 00:31:54', 'Koasoa somi', 'Somi misoviso', 'Ravi yuraso', NULL, '73d964ac-98dd-523e-b9de-b4ca4c879ed2', 5, '6a8d204f-46d9-59f4-a79b-705c63a34586', 64758, 'Rasoyumi rayuami miyu', 29639, 38213, 12480, 38579, 'Kovi koamia soayuso', 'Sovi somiami viyura', 'Virasora viyu koyuraso', 'Visoa misora', 'Yukoviyu viso', 'Miko soakomi miko', 'Miavi virayura miravi', false, 'Mikoyu soa', 'Yukoaso sovikora miravia', 'Vira soyua', 'Virakoyu yusomi', 'Yuaso mirako', NULL, 'Yurakora soavia', 'Koviraso yurako', 'Yusomi soviravi', 'Miko misoa rayu', 'Rayumi somisora', 'Vikovi yukomiyu rayuso', '1982-03-15 02:18:06', 'Somiyu soavi', 'Sora virami', 'Yusomira komi yusoyumi', 50290, '2007-08-24 19:20:20', '2001-06-26 05:50:38', '2007-12-12 11:57:06', 'Raviyuso viyu', 'Rayu vikoyu', 'Koravi', 'Raviraso yurako', 'Yuvirayu soayu miko', NULL, 'Yumi vikoayu', 'Yusoa miyuviyu', 'Mirayuko korayu ramirako', NULL, '1999-04-08 03:45:11', 54775, false, '1990-07-03 18:33:04', '2012-05-09 16:53:18', '1995-04-16 15:27:58', false, 47439, '2001-06-06 05:49:15', NULL, '2007-04-16 03:33:33', 61976, 7667, '2001-06-26 05:49:28', 'Yumiravi koamiyu koavi', 'Rami mirasomi', 'Vikoyu miramira koyua', '1986-11-03 22:54:54', 58540, 25887, 5858, 59863, NULL, 'Miami yusoyuvi', 7791, 'Mikora kovi', '1983-04-08 03:05:27', '{}');
INSERT INTO public."Order" VALUES ('6d548d0d-3cb7-5e04-a352-0a3186ef08bf', '2022-09-29 15:06:36.89', '2020-08-20 19:30:31', 'Yuko soraso ramirami', 'Soviavi komira rako', 'Kora yuviyuso', NULL, 'bbb936a3-337d-5c4b-b7d3-c0af0978209a', 6, '8ec31d84-dc80-51cf-aeab-8131275bc81a', 60345, 'Miso yuraviyu', 48729, 4310, 13492, 62065, 'Rayuvia vira koravira', 'Rakoviyu miyu koviko', 'Yumiavi visomiso soravi', 'Komi raviyu koyusoyu', 'Somia visoayu', 'Koyu ramikoa', 'Viravi rakoaso', false, 'Koa soaso yuraviyu', 'Koyumiko yuraso', 'Rayu rayuvi yuravira', 'Sora yuravi mia', 'Visoa koyu yuayu', NULL, 'Rakoyumi via', 'Yuvi somira yura', 'Mia yuvi rasoyu', 'Visora rakoaso', 'Rayua yusoyu', 'Miraso miami miayura', '2006-11-03 10:56:53', 'Vikoami ramiyu viso', 'Soyu soako rayukoyu', 'Miyu misovi', 54716, '1992-09-25 20:32:38', '1987-08-24 07:18:14', '1983-04-04 03:17:38', 'Raso misoviko', 'Yusovi miavi kora', 'Koviyu', 'Rayu koa viso', 'Yumirayu soyu viako', NULL, 'Somiyu yusoa yusora', 'Vikomi soavi raviami', 'Somikoyu vikoyu', NULL, '2009-02-26 14:00:37', 39531, false, '1985-10-14 21:57:21', '2008-09-17 20:11:25', '2012-09-21 08:35:29', false, 31189, '1996-05-25 16:18:02', NULL, '2011-08-16 07:33:14', 13765, 49802, '1983-12-08 11:25:55', 'Vikoa soyuso', 'Rasomiyu koyu', 'Yuako soramira yuvi', '2016-05-21 04:19:22', 43089, 962, 56176, 28007, NULL, 'Ravia yumiko sovi', 11497, 'Viyua miyuviyu soyu', '2008-09-25 20:09:34', '{}');
INSERT INTO public."Order" VALUES ('14bb0d12-84c8-5778-9f68-729d45f0148b', '2022-09-29 15:06:36.89', '2020-03-27 14:20:58', 'Viso rakomi', 'Soyumira vikomi kora', 'Ramiyumi miayuvi', NULL, '65e024a7-66e9-5650-bdff-7d2f9838b76a', 7, 'f5a656a2-309a-5844-b73a-38dac5041614', 60456, 'Koyuvi soyumiko koravi', 55912, 32334, 4773, 4809, 'Yukora kora', 'Miyua raso yurami', 'Yuvikomi miyu koavi', 'Mia kovirayu', 'Kora soviavi miyuvi', 'Yukora soaso', 'Miyua yumiayu', false, 'Koyumira mikoyua', 'Komiso misoa raso', 'Mikora viraviko koyumi', 'Misora mira', 'Sovi rayumi misovira', NULL, 'Rako rayuravi', 'Yuraso koravira', 'Yuvi yumiaso', 'Sovi visomiyu', 'Komi yuakora', 'Komi yusoyu', '2019-04-12 15:47:35', 'Koayuvi miyumi', 'Visomiko korako', 'Vira ramiako sovi', 43230, '1995-12-20 23:49:40', '1989-06-10 17:29:02', '1982-03-19 02:03:21', 'Miko yusora', 'Virayuso viako miraviyu', 'Yura', 'Miyuko soyumiyu', 'Miasoyu kora', NULL, 'Somikora rakora rako', 'Viavi soavia virasora', 'Yumisoyu koavi yurayuso', NULL, '1996-01-21 00:52:26', 9182, false, '1985-10-10 21:50:17', '1993-10-22 21:48:31', '1999-08-16 19:21:56', false, 3749, '2011-08-16 07:44:40', NULL, '1982-07-27 18:58:11', 15026, 893, '1988-09-09 08:10:14', 'Miyukomi viraso', 'Kovisora via', 'Koyu yurakomi komiayu', '1990-07-19 18:37:39', 49430, 55707, 16816, 15510, NULL, 'Sora yurayu', 40532, 'Sora ramiyu', '1987-08-16 07:07:36', '{}');
INSERT INTO public."Order" VALUES ('81b02964-6714-59c0-81c0-f669c8c61534', '2022-09-29 15:06:36.89', '2020-08-04 08:01:00', 'Ravira rayu', 'Yuviyu vira', 'Soayu raviyu', NULL, 'f66355af-0ba5-5130-a19e-9b3fb66b7971', 8, 'de2cdf6e-71ac-524e-934b-cf40717f38fa', 32784, 'Soayu yuasoa', 53410, 12360, 6401, 53489, 'Ramia mikoyu yura', 'Somiyu viamiso raviyuso', 'Soyu mia kora', 'Yumi koviko', 'Koa rayuayu', 'Ramia koravira', 'Yusoravi koami rakoako', false, 'Yukorayu rayuvi koraviso', 'Viso somirami', 'Visoyura soyuko', 'Koviso viaso', 'Yuraso vira miyumi', NULL, 'Viyu kovia rakoami', 'Yurasovi soa', 'Soyuvira viyuko yuviayu', 'Rami vikora yuako', 'Soyuviko yura viayu', 'Miyu koramiso yusoa', '2010-07-19 06:33:20', 'Somiso viramira rayumia', 'Via yukorayu koviyua', 'Komiami sora misomi', 33171, '2015-12-08 11:46:47', '1988-05-05 16:38:48', '2004-01-01 00:29:15', 'Yuraso yua', 'Soyu mikoami rayu', 'Koa', 'Mirakovi yukoaso yumiravi', 'Somiko koramira somi', NULL, 'Yua mikoyu', 'Ramiso koviyuso', 'Koayuso yura', NULL, '1985-10-22 21:52:35', 19234, false, '2005-06-22 17:13:24', '1995-08-12 08:07:26', '2006-07-07 18:07:09', false, 37511, '1985-06-22 05:09:19', NULL, '2019-12-09 00:08:13', 56133, 8944, '1994-07-03 07:00:20', 'Koyuviko miko', 'Yuraso yuviayu miso', 'Rakoyumi viami', '2010-07-19 06:36:01', 13028, 6191, 22747, 47004, NULL, 'Koravi korayua', 24011, 'Rasora yurakovi', '1985-02-14 13:31:10', '{}');
INSERT INTO public."Order" VALUES ('bcf08cc7-9db9-5480-886e-c0d7b74cc002', '2022-09-29 15:06:36.89', '2020-04-16 15:07:06', 'Yuavi rakorayu', 'Rayuviso soamiso', 'Yura viraviyu rami', NULL, 'e5941561-c4b9-5933-89cf-48fb7d6d2e60', 9, 'e5dc5adf-45fc-5744-a970-b80df61a6142', 26088, 'Koa koyu korasoyu', 12472, 19301, 27771, 34370, 'Viyuvira soa misoa', 'Soayu mia', 'Via viso', 'Sorami mira', 'Kovikomi komi', 'Soviyuko yumia ravikoa', 'Visoviko yuso', false, 'Rayura virakomi miaviyu', 'Mikoavi sorayu', 'Soa yuviyuvi kovi', 'Koyuraso kora', 'Koviyua rakomira komikoa', NULL, 'Raviaso korayura miavia', 'Virasovi viako', 'Rasoviko raviyu misoa', 'Yuayu rasovi yuami', 'Miyumi raviyuvi', 'Raviso soyua', '2018-03-19 14:38:04', 'Soyuvi kovisora', 'Rami ramiyuso', 'Miyusoa koviko', 23518, '2019-12-25 00:13:44', '2012-05-05 16:53:56', '2000-05-05 04:56:17', 'Koayu miraso koyukovi', 'Virako koramia', 'Yumira', 'Miso korayu', 'Rakoayu koaso', NULL, 'Ramisora yuasovi mira', 'Ravira somi', 'Raso komiyua', NULL, '2017-10-02 22:05:46', 32590, false, '1983-08-16 19:46:31', '1985-10-02 21:58:54', '1996-05-09 16:16:43', false, 13958, '1991-12-20 11:20:53', NULL, '1980-09-25 08:33:56', 55528, 29362, '2017-10-18 21:58:41', 'Sovi mikomiyu', 'Miraso rami viyuavi', 'Somia sovira', '1985-02-26 13:37:19', 15923, 25490, 58544, 12818, NULL, 'Sora miamiyu', 50469, 'Rayumi vira kovisoyu', '1988-09-17 08:08:23', '{}');
INSERT INTO public."Order" VALUES ('fd8ea77f-0654-5320-ab52-461e2b443a15', '2022-09-29 15:06:36.89', '2020-12-04 11:25:52', 'Koa koyua', 'Komiayu korakora', 'Mira koviko yura', NULL, 'bcca18c3-5e46-56cb-b58b-c74cf16609b1', 10, '9e8edc7b-ab8d-52aa-a40d-11edb7c182ae', 5196, 'Soyura somisora kovi', 43519, 53519, 57373, 18173, 'Mirako soamiso', 'Rayu soyuko viso', 'Somi ramia kora', 'Mikora rakoviyu', 'Koraso ravi via', 'Koyuraso miso', 'Viyusoyu miko soyura', false, 'Mirasovi raso vikoyu', 'Somi misoaso', 'Yuvi yukoviyu somi', 'Viaso yura', 'Viso ramisora soaviko', NULL, 'Yuviako sora', 'Viyukora koyu komiyu', 'Miako somiso', 'Raso yuavia', 'Rayumiko yura', 'Yuaso miamiyu viso', '2012-05-05 17:01:31', 'Virayuvi rasoyua koamia', 'Viyura korayumi', 'Rayura yukoviso mira', 50333, '1995-04-04 15:16:55', '2015-04-08 03:17:20', '2001-06-18 05:46:04', 'Vira mia soayu', 'Koraviso koayu', 'Yuko', 'Mia vikoviyu vikomi', 'Koyu yuviyuso koakovi', NULL, 'Viyumiyu rayumi yuviyuvi', 'Viyumia rami koaviyu', 'Sorami viramiso', NULL, '1998-07-27 18:24:30', 21591, false, '2001-10-02 21:36:25', '2000-01-25 12:00:10', '2002-11-23 22:36:43', false, 31605, '2001-06-22 05:53:01', NULL, '2010-11-03 22:13:39', 56254, 22285, '2019-04-20 15:50:59', 'Miayu yurako', 'Sorako rasoviko mikoako', 'Soyuso komia misoyu', '2011-12-04 23:18:52', 41899, 50588, 46857, 16090, NULL, 'Viso ravira yuko', 15259, 'Yumiyumi misomi', '1986-11-07 22:58:21', '{}');


--
-- TOC entry 4244 (class 0 OID 2148904)
-- Dependencies: 236
-- Data for Name: OrderItem; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."OrderItem" VALUES ('b3941a80-6e5a-5ad0-ae85-8212736de06b', '2022-09-29 15:06:39.328', '2020-05-25 16:56:16', 51002, 'bcf08cc7-9db9-5480-886e-c0d7b74cc002', '16f362dc-5c04-5585-a777-582c857c1b73', 'Ravikomi yuso korakoyu', 'Soaviso', 'Rakoayu mikoyu vikoayu', NULL, NULL, 16292, 'Yukovi', 'Rasoami visoa', NULL, '1989-06-18 17:37:55', '1990-07-23 18:40:03', NULL, NULL, '2016-05-05 04:30:32', NULL, '1995-12-04 23:48:07', '2009-10-10 21:16:44', '1983-12-24 11:34:35', '1982-07-23 18:47:30', 18626, 'Ravirami yuko yukorako', '2015-04-16 03:19:55', 'Viyumiko komi yukoayu', NULL, '{"Ramirako rako koavira"}', NULL, '1998-03-03 02:52:23', '2008-05-17 04:43:05', 'Raso viamia', 30151, '2010-07-11 06:38:20', NULL, false, NULL, '1993-02-18 13:29:09', '2002-11-11 22:27:04', 'Yumi mikoyu ramia', NULL, false, '1991-08-20 19:40:25', false, false, NULL, NULL, 18160, false, '1996-05-21 16:18:47', '1997-02-18 01:52:34', NULL, 3925, 49790, '2009-06-18 05:32:12', 38469, 11778, '2014-07-15 19:04:51', '{"Sora misoraso yua"}', 'Soa soayu sovikovi', 3418, 'Via soraso', 'Somia rasora', '1999-08-24 19:24:17', '1994-11-15 22:35:59', '1985-06-02 05:20:11', 'Viso rasomi', 'Koavi rami', NULL, NULL, 'Rasoyura miayu korasora', '2017-06-02 05:31:43', '1988-01-09 00:50:21', 'Virasomi yura yuvira', 'Yuayuvi yuvi yuravia', 'Koako rakoyuso', 'Yuravi soyu', 'Miravi viko', '2002-07-19 06:56:39', '2008-05-09 04:28:01', '2003-12-16 23:23:15', '2003-12-24 23:35:59', '1987-12-16 23:49:49', '1981-10-14 09:36:09', '{"Visovira soyu"}', '{"Viko viyukomi"}', '{"Miso yusovi"}', 'Korakoyu rasoa sovira', 'Soyumia viyu', 19107, 1809, '{"Yuramiso yumiso ravi"}', '{"Kovia viko"}', 'Yumi', 'Yurasoyu sora visora', 'Vikovi', 'Yurami rakomiyu', 'Somira soyu', '{"Soayu rami miyukora"}', '2016-05-13 04:29:58', '{"Koako yuvi via"}', false, false, false, false, false, 27404, 13857, 'Misomi viso', 35608, 18038, 'ebe23927-b75b-511e-8a6b-827d564bfa74', 'Yura rasoami rayu', 'Viyu soayuso koraso', 22891, 'Cruz Wisoky', '{}', '{"Yukoa": "Virayu koayu"}', 'Korakoa', '{}', false, false, 'Miyu yurako rako', 'Mirayu koaviso koa');
INSERT INTO public."OrderItem" VALUES ('f94e4f51-dffe-536b-a6ed-72496c6759a5', '2022-09-29 15:06:39.328', '2020-02-14 14:02:52', 48428, '4d0dd818-560c-5b2a-b46d-50c9d5087013', '18c87a37-f557-562c-9adc-17a2609a8135', 'Kovikoa virami', 'Yuraso', 'Ramia rasoayu', NULL, NULL, 35326, 'Komiyuko', 'Soviyu yusoyumi', NULL, '2000-01-05 12:02:52', '1986-03-19 14:34:00', NULL, NULL, '2019-04-12 15:47:35', NULL, '1980-01-21 00:15:02', '1991-12-28 11:23:07', '2003-04-08 15:17:35', '2008-01-21 12:49:16', 15482, 'Yura mikoyu yuakora', '2013-02-22 01:18:08', 'Koakoa yuraviko viavia', NULL, '{"Komiyu miso"}', NULL, '1989-06-14 17:38:19', '2017-06-26 05:33:10', 'Soa yura', 12516, '2006-07-23 18:13:01', NULL, false, NULL, '2006-03-07 02:36:29', '1996-05-13 16:29:02', 'Soa yumi', NULL, false, '1991-04-28 04:00:05', false, false, NULL, NULL, 16359, false, '1998-11-11 11:08:33', '1988-01-17 01:00:03', NULL, 22367, 21930, '1996-09-09 08:57:39', 12719, 26819, '1993-06-14 06:03:08', '{"Rami rayumiyu komiaso"}', 'Miyu viakora', 37503, 'Koviko soyu komirayu', 'Komi rayumi sora', '1999-04-28 03:42:15', '1991-08-28 19:47:40', '1984-09-25 20:45:20', 'Yukoviko viaviyu ravirako', 'Miraso raso', NULL, NULL, 'Mira koyumi yuavi', '1990-11-03 10:17:37', '2018-07-23 06:31:26', 'Soakoa mia vikoyu', 'Soako mikoyumi komi', 'Viyusoa kora rasomi', 'Viyukoa vikomi vira', 'Vikora mia viyu', '2010-07-23 06:35:30', '2011-12-12 23:18:32', '2014-11-03 10:34:02', '2008-05-13 04:39:31', '1990-07-07 18:36:03', '2011-04-24 15:54:53', '{"Somiko ramia mia"}', '{"Koyuvira yumira viyu"}', '{"Ramisoa yuaso yukoviyu"}', 'Vira somiaso', 'Ravi koami rayuvia', 20088, 52866, '{"Somira koako"}', '{"Rakomi miyu"}', 'Vikovi', 'Soviyu yua sora', 'Yua', 'Koayu soyumiko somi', 'Miramiyu soyu', '{"Rasoayu yusoa yumikomi"}', '2018-11-19 23:06:14', '{"Viyu miayu miko"}', false, false, false, false, false, 21070, 27842, 'Yumiaso mirayu soyu', 1730, 2864, 'c24182ee-91e9-5eb1-99a5-b9cc92ef38ad', 'Mirasoa soa', 'Somia viso komira', 2510, 'Damien Windler', '{}', '{"Yuayu": "Koa sorami"}', 'Mia', '{}', false, false, 'Misoraso rako', 'Miyura yumiyua');
INSERT INTO public."OrderItem" VALUES ('935b61d3-e9fc-56f1-be5d-46f2964d466a', '2022-09-29 15:06:39.328', '2020-02-18 01:43:07', 26837, '1941807b-4d57-576f-90b2-754180189dee', 'dcc3fef3-3f7d-5e58-bd52-27dbcee73cd2', 'Yusovi viyu somia', 'Raviko', 'Yua mikomi koyukora', NULL, NULL, 52472, 'Yusovi', 'Miayumi viso visovi', NULL, '2018-07-19 06:31:22', '1985-06-02 05:18:47', NULL, NULL, '2001-06-26 05:42:21', NULL, '2000-05-25 04:42:51', '2011-08-24 07:32:05', '2010-07-27 06:46:25', '2001-10-26 21:29:35', 61860, 'Kora koviko', '2017-06-06 05:21:10', 'Kovira vikoraso viyuko', NULL, '{"Somisoa vikoyu"}', NULL, '1981-06-02 17:55:50', '2006-07-15 18:16:37', 'Rayu mikomia koyukoyu', 19734, '1989-06-18 17:38:16', NULL, false, NULL, '2002-11-11 22:31:44', '1997-02-26 01:43:57', 'Soaso yuvi', NULL, false, '1992-01-21 12:17:42', false, false, NULL, NULL, 33771, false, '2017-10-06 21:58:15', '2005-02-10 01:33:12', NULL, 49762, 65154, '1994-11-03 22:39:52', 31546, 15158, '2007-12-04 11:47:38', '{"Vira yukoa miko"}', 'Soa miako yuviyu', 39731, 'Somikoa raviyu raviyuso', 'Yuko soyukoa visoyuko', '2005-06-10 17:07:36', '1986-11-23 22:55:56', '1985-02-02 13:32:22', 'Komiko yusomira korayu', 'Ravia ramira sora', NULL, NULL, 'Mira yumikoyu yuami', '1986-03-19 14:41:21', '2002-07-23 06:49:08', 'Soyukovi yuviyu', 'Somia yukomi rako', 'Soyu virakoyu raso', 'Yura ravira', 'Viko vikorako vikomi', '1993-06-06 05:53:47', '1983-04-08 03:14:26', '1994-03-15 14:30:27', '1994-11-23 22:42:04', '1994-07-03 06:57:46', '1986-11-27 22:58:20', '{"Vikoyu rakoavi"}', '{"Soami koyuko yumia"}', '{"Miko rasoviko rakoyu"}', 'Yuviayu mia yumisora', 'Rami vikovi', 37504, 47797, '{"Soyu misora ravi"}', '{"Sora soravi"}', 'Virakoyu', 'Miyukoyu viravi koayu', 'Yusora', 'Vira ramia mia', 'Visomiso mikomia viyurami', '{"Rayusomi viayu"}', '1980-01-01 00:09:20', '{"Miavi sovi yuvira"}', false, false, false, false, false, 34525, 42688, 'Rako via soyura', 59237, 21570, '899d114b-edd8-5d58-bac6-923e65a6b399', 'Miaso koakoa soviyuso', 'Rakoviko viko miyumira', 33555, 'Uriel Doyle', '{}', '{"Yuviko": "Viyukoyu viyuayu"}', 'Virayu', '{}', false, false, 'Yuasovi viyuvi somi', 'Mikoa viko');
INSERT INTO public."OrderItem" VALUES ('92e9426b-2cff-5d40-9f0b-5bc29652dea8', '2022-09-29 15:06:39.328', '2020-03-23 14:24:03', 46000, '14bb0d12-84c8-5778-9f68-729d45f0148b', '8601e2b0-65eb-5839-b443-db555bf08059', 'Misoa ramiyua yusoyuso', 'Kovisoa', 'Soraviyu yukoa', NULL, NULL, 7873, 'Koakoyu', 'Korakoa viko', NULL, '2019-12-25 00:08:43', '1987-12-12 23:56:38', NULL, NULL, '1985-10-06 21:45:54', NULL, '2009-06-10 05:37:19', '2013-10-26 09:41:49', '2003-08-12 07:44:14', '1992-05-13 04:52:54', 39105, 'Soaso viasora viyuvi', '2013-06-22 18:03:51', 'Misoavi soviko', NULL, '{"Viyuvi soa ramira"}', NULL, '1999-04-28 03:52:38', '1991-04-20 04:06:43', 'Viso soa', 55112, '2011-08-24 07:43:24', NULL, false, NULL, '1996-05-01 16:31:31', '1994-07-03 07:01:16', 'Koyu raviaso', NULL, false, '2014-03-03 02:29:40', false, false, NULL, NULL, 27088, false, '1990-11-15 10:18:52', '1993-06-06 05:57:24', NULL, 52126, 14474, '1994-07-07 07:06:56', 30241, 43963, '2005-06-10 17:05:09', '{"Yusomiso somia"}', 'Miasoyu viyu viyuviso', 64452, 'Miso rakovi', 'Yurasovi sovi koravia', '1997-06-14 17:32:02', '2016-05-25 04:16:31', '1992-05-05 04:52:46', 'Soyu soyua misoyu', 'Mikoraso viko somia', NULL, NULL, 'Mikomi sora', '1982-03-03 02:02:09', '1989-02-26 01:56:53', 'Korayu yuvi', 'Koa mira yuayumi', 'Misora rakoaso', 'Viyu somiko komi', 'Mirako soyusoa', '2005-06-02 17:09:55', '1985-06-22 05:06:24', '1987-12-12 23:49:45', '2017-10-06 22:06:46', '1993-02-02 13:21:46', '2014-03-03 02:18:28', '{"Komi yuvia soviso"}', '{"Vikomi miamiso yua"}', '{"Rasoyuko soa"}', 'Soravi koavi yurayuko', 'Vikoyu mira komiso', 63328, 52654, '{"Vikomi yuayuko rami"}', '{"Miramiso yukovi vira"}', 'Koraso', 'Koviso yuso mirakoa', 'Raso', 'Rayumia yuvirami', 'Koravi sora virasora', '{"Koaso korami yukorayu"}', '2011-04-08 15:56:22', '{"Yurakoyu miso"}', false, false, false, false, false, 65495, 12236, 'Rami miyuavi', 17691, 4193, '3e9a9315-f0b2-5838-aa49-ad0747bd361f', 'Yua koviso miyu', 'Miyumia rakoa', 24412, 'Henry Jacobs', '{}', '{"Soyusomi": "Soviyua mira"}', 'Yusoa', '{}', false, false, 'Miyu mia', 'Soyukovi yumiyu mirayuvi');
INSERT INTO public."OrderItem" VALUES ('ba590762-4089-58da-b07e-01ca832aa54f', '2022-09-29 15:06:39.328', '2020-04-20 15:39:26', 57150, '81b02964-6714-59c0-81c0-f669c8c61534', '8122a2a6-800d-538d-8a70-11273a3e06e9', 'Koviavi yuko', 'Raso', 'Viso rayusovi miyu', NULL, NULL, 19181, 'Soviso', 'Misoviyu miyuvi viako', NULL, '1998-11-11 11:04:49', '1990-11-07 10:10:41', NULL, NULL, '2016-01-09 12:36:08', NULL, '2007-08-20 19:19:48', '2019-08-24 07:32:13', '2017-10-22 22:11:14', '2012-01-09 00:20:39', 48388, 'Rayu viyukoa', '1993-02-06 13:27:54', 'Yuvira sovia yurami', NULL, '{"Ramiko yuso viamia"}', NULL, '2017-10-06 22:13:04', '1985-06-14 05:15:15', 'Viso yuvia', 61419, '1984-01-13 12:35:59', NULL, false, NULL, '2004-09-25 08:56:32', '2009-10-02 21:22:26', 'Koyurayu somi sovikoa', NULL, false, '2005-06-26 17:19:11', false, false, NULL, NULL, 37326, false, '1990-07-07 18:44:06', '2019-12-29 00:01:12', NULL, 34788, 43185, '2008-05-17 04:36:05', 64315, 46783, '2018-03-07 14:41:15', '{"Yumi komiavi mikovi"}', 'Koviyu koyu', 46970, 'Viamiso viyu yukoviso', 'Miasoyu koa vira', '1999-08-16 19:22:03', '2006-07-15 18:20:14', '2015-04-08 03:29:00', 'Mira ramiyu', 'Viso misoyu', NULL, NULL, 'Mikoa soyumiso', '1992-01-25 12:22:19', '2011-08-16 07:32:18', 'Miko rayura', 'Soavi ravi', 'Rakoyura soviko soako', 'Raviko sovirako', 'Miko koaso', '1980-01-09 00:02:00', '1983-08-08 19:48:15', '2015-04-28 03:20:56', '2008-05-17 04:36:12', '1986-07-23 06:07:18', '2012-09-09 08:43:13', '{"Ramikomi rasoaso"}', '{"Soayu rayuvi"}', '{"Yukoyu miyusora"}', 'Ramisomi komi', 'Koa miyu sovia', 43957, 11144, '{"Korami mia korako"}', '{"Ramikomi miayu"}', 'Koaviko', 'Yuramiyu ramiyu yusoa', 'Viko', 'Rayura misomiyu', 'Kora miyuviko', '{"Koa miko rasoyuvi"}', '1980-09-21 08:21:51', '{"Rakomiso yuvi"}', false, false, false, false, false, 20999, 37167, 'Miravi rasomiyu miami', 47618, 24416, '9bd7f899-12cf-5938-adbf-1da9b61d3a23', 'Kovi viramiko', 'Miso yumia soaviso', 42196, 'Larue Zulauf', '{}', '{"Mirami": "Somi sovikomi"}', 'Sovi', '{}', false, false, 'Vikora vira ravia', 'Miamiso korako');
INSERT INTO public."OrderItem" VALUES ('24ff8ae5-363f-5939-b7d3-ff2a1d55f1eb', '2022-09-29 15:06:39.328', '2020-12-16 23:26:59', 14573, '6d548d0d-3cb7-5e04-a352-0a3186ef08bf', '0b59dd48-bdf0-5a03-a4d7-58a85502f65d', 'Visoyuvi miyu', 'Misoayu', 'Miavia soa soramira', NULL, NULL, 18624, 'Sorami', 'Viyuviyu via yumi', NULL, '2011-12-28 23:13:54', '2018-03-23 14:44:19', NULL, NULL, '1996-01-25 00:44:34', NULL, '1994-07-11 07:00:42', '2007-04-28 03:33:45', '1999-12-24 12:08:22', '2006-03-15 02:42:20', 47334, 'Sorako soyua yukora', '1993-10-26 21:35:45', 'Rami mia mira', NULL, '{"Koraviso virako miso"}', NULL, '1990-03-19 02:50:04', '2012-05-17 16:59:30', 'Soyu soa', 64017, '1992-01-09 12:16:27', NULL, false, NULL, '1981-06-02 17:42:25', '1993-02-18 13:16:40', 'Soviyura vikovi', NULL, false, '1981-02-22 01:15:14', false, false, NULL, NULL, 63131, false, '2015-08-24 20:02:51', '1980-01-17 00:03:39', NULL, 13776, 49774, '1993-02-10 13:17:07', 8145, 59267, '2018-11-23 23:02:06', '{"Miraviso ramiko vira"}', 'Miako soasoa', 36609, 'Soyu soravi koyu', 'Yuviko yumirayu', '1981-10-22 09:28:56', '2003-08-20 07:43:54', '2002-03-11 14:13:50', 'Yurako soyuviso', 'Viyukoa rasoyuso', NULL, NULL, 'Ramira yukorako soayua', '1990-07-19 18:35:26', '2019-04-08 15:50:40', 'Yuso miayu', 'Soami rayuviko mia', 'Viyua rako', 'Mirayu mirayumi soyu', 'Yuayuvi vira', '2003-08-12 07:51:35', '1988-09-01 08:08:14', '1993-06-02 06:03:31', '2013-10-02 09:37:06', '2007-08-12 19:19:54', '2019-04-16 15:43:48', '{"Yuaso yuamia visoviko"}', '{"Via raso miamiso"}', '{"Yurayu sora yumiko"}', 'Soyu misora', 'Sovisora rayuko', 49576, 8355, '{"Mia koyuso rami"}', '{"Yurami yuvia viravia"}', 'Sovi', 'Somiayu miso', 'Somi', 'Somiyuko koravi', 'Yuko ramiso', '{"Miko soavi rakorako"}', '2011-04-28 15:52:44', '{"Sora yuraso"}', false, false, false, false, false, 41871, 34906, 'Koako yumiyua', 39846, 45288, '37f9c208-0d5c-54fb-a558-c61ab9243520', 'Yuko mikovi misomiko', 'Viko koravira koamiso', 4344, 'Eleazar Runolfsdottir', '{}', '{"Rami": "Rako soyua koyuvira"}', 'Vikomira', '{}', false, false, 'Virami yusomiso koamiso', 'Vikoraso rayua rayuso');
INSERT INTO public."OrderItem" VALUES ('79ede451-ebd9-5ada-9d66-3b15d2c20b6f', '2022-09-29 15:06:39.328', '2020-05-25 16:20:22', 53486, '192b76dd-86f0-5c4a-bb30-8c6d94aa0f72', '149bca0f-38d5-57d6-bc56-9a6d0ed92651', 'Mirayuko miyuvi', 'Korami', 'Vira mia', NULL, NULL, 4398, 'Kovi', 'Soviayu miyu', NULL, '2015-04-24 03:29:51', '1980-01-13 00:11:52', NULL, NULL, '1981-02-10 01:15:09', NULL, '1983-04-12 03:06:34', '2007-12-20 11:54:19', '2004-01-09 00:36:44', '2006-03-27 02:29:42', 11051, 'Soayu via sovisovi', '1990-07-19 18:45:21', 'Visomia rayu', NULL, '{"Koramira virayu"}', NULL, '2007-04-12 03:41:46', '1997-10-14 10:00:57', 'Miakomi miaso', 55563, '2006-07-03 18:10:42', NULL, false, NULL, '2018-03-07 14:45:06', '2006-07-19 18:19:01', 'Yusovi viso yukorami', NULL, false, '2008-09-13 20:16:29', false, false, NULL, NULL, 19886, false, '1991-04-16 03:56:44', '1982-11-19 10:36:11', NULL, 31653, 54588, '1999-12-16 12:14:25', 45560, 60346, '1989-10-22 09:12:09', '{"Koavi yurakora"}', 'Ramiso sora miaviko', 19872, 'Soviavi rayuviko', 'Visorayu koyu visora', '2016-09-13 20:56:26', '2015-04-28 03:28:10', '1998-03-15 02:43:29', 'Korami kora', 'Rako rakomi', NULL, NULL, 'Rasovia ravi', '1999-08-16 19:28:49', '2016-01-13 12:38:25', 'Raviso misomiko', 'Miyu raviko ramiyuso', 'Yuso koravia', 'Yuvira miyua', 'Ravira koyua', '2004-01-21 00:25:44', '1987-12-04 23:55:34', '2016-05-17 04:27:42', '2012-09-17 08:43:21', '2010-07-27 06:35:06', '2017-02-26 13:44:39', '{"Miami soa"}', '{"Visoyu ravirami komiyu"}', '{"Miyu soyua visoyu"}', 'Soyura miyua mikoravi', 'Soyusomi viaviso', 55755, 31362, '{"Kovi soyuvira"}', '{"Soavi miyu"}', 'Yuso', 'Yuramira yumiyu', 'Yukoyu', 'Mikovi viaso', 'Yurasoa koyumi', '{"Soyumira yuaviyu soyuso"}', '1997-02-22 01:37:28', '{"Ramisoyu sora soyura"}', false, false, false, false, false, 47283, 55529, 'Yukoyu yuvisoyu misoa', 59411, 4979, '7990700d-16be-5f39-adb6-0db5c0346552', 'Somiavi korakoyu mira', 'Yura via misora', 11031, 'Ryan Parker', '{}', '{"Viyuvi": "Sorami ramirako"}', 'Vikoako', '{}', false, false, 'Miso mirayuvi', 'Komiso koa yumiso');
INSERT INTO public."OrderItem" VALUES ('e5404071-d1d1-52f8-a2d6-9ac99c2004d6', '2022-09-29 15:06:39.328', '2020-05-13 16:04:05', 57849, '7a44fea2-4748-564f-bb19-ed522ac41168', '8e49deb5-401d-54e0-8467-897de40816d0', 'Yuvi rasora', 'Viramia', 'Yuravi kovi rakorami', NULL, NULL, 28403, 'Sorayu', 'Soyu sorayu viavi', NULL, '2007-12-12 11:58:16', '1998-03-19 02:47:31', NULL, NULL, '1989-02-18 01:54:53', NULL, '1997-02-06 01:40:00', '2019-04-28 15:42:15', '2018-07-27 06:28:56', '2000-09-05 20:33:29', 65091, 'Somiko visoyua mirako', '2005-02-22 01:29:26', 'Rayuvira viako virakoa', NULL, '{"Ravirako rasovi viyukomi"}', NULL, '1990-11-19 10:18:28', '2008-05-13 04:31:35', 'Vira soraso', 40030, '1991-08-08 19:32:10', NULL, false, NULL, '2010-07-03 06:31:47', '1990-11-15 10:19:41', 'Ramiko vikorami', NULL, false, '1999-08-08 19:23:54', false, false, NULL, NULL, 32992, false, '1987-08-08 07:22:45', '2009-02-18 14:00:01', NULL, 17700, 23815, '2003-08-28 07:43:55', 32022, 44288, '1985-06-10 05:13:47', '{"Sovisomi ravi"}', 'Rako mirayua', 42479, 'Soyu rasoa', 'Mia mira', '2004-09-21 08:48:18', '2016-01-05 12:47:23', '1994-03-23 14:25:34', 'Viraviko somiako vikorako', 'Visomi yura', NULL, NULL, 'Koravi viyuayu', '2016-01-13 12:36:47', '2004-09-09 08:55:41', 'Koramia ramira', 'Soavi ramiayu', 'Ramisovi soavi', 'Raso rayukoyu', 'Viakoa koa', '1984-09-05 20:47:20', '2005-10-22 09:51:32', '2015-12-12 11:43:49', '1992-01-01 12:26:49', '2016-09-17 21:08:59', '2004-09-25 08:45:55', '{"Viyura komi miami"}', '{"Rasovira virayu kora"}', '{"Korami via"}', 'Komiami mira koraso', 'Soviyu koravia', 48346, 62734, '{"Ramiyuvi viyuvia"}', '{"Miko visoviso miakoyu"}', 'Soa', 'Rakomiso soako rayurami', 'Soa', 'Virami sorayuso', 'Yuaso visomia', '{"Koyuvi korayuko"}', '1990-03-27 03:01:38', '{"Via yuamia"}', false, false, false, false, false, 25002, 21541, 'Rasovia kovikoyu', 64324, 61625, 'cdcb05a7-2739-5514-9395-78fd441bd549', 'Rakora mikoako', 'Soavia kovi', 61651, 'Emmy Reilly', '{}', '{"Viko": "Yura komiyu yura"}', 'Miyu', '{}', false, false, 'Rako soyua', 'Komi vikoaso rayuvi');


--
-- TOC entry 4245 (class 0 OID 2148911)
-- Dependencies: 237
-- Data for Name: OrderItemStatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."OrderItemStatus" VALUES ('dcc3fef3-3f7d-5e58-bd52-27dbcee73cd2', 'Morgan Treutel');
INSERT INTO public."OrderItemStatus" VALUES ('149bca0f-38d5-57d6-bc56-9a6d0ed92651', 'Guido Jaskolski');
INSERT INTO public."OrderItemStatus" VALUES ('8e49deb5-401d-54e0-8467-897de40816d0', 'Paolo Skiles');
INSERT INTO public."OrderItemStatus" VALUES ('18c87a37-f557-562c-9adc-17a2609a8135', 'Johann Kautzer');
INSERT INTO public."OrderItemStatus" VALUES ('0b59dd48-bdf0-5a03-a4d7-58a85502f65d', 'Violette Johns');
INSERT INTO public."OrderItemStatus" VALUES ('8601e2b0-65eb-5839-b443-db555bf08059', 'Liana Tromp');
INSERT INTO public."OrderItemStatus" VALUES ('8122a2a6-800d-538d-8a70-11273a3e06e9', 'Lilyan McLaughlin');
INSERT INTO public."OrderItemStatus" VALUES ('16f362dc-5c04-5585-a777-582c857c1b73', 'Hyman Carter');


--
-- TOC entry 4246 (class 0 OID 2148916)
-- Dependencies: 238
-- Data for Name: OrderItemsOnInvoices; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."OrderItemsOnInvoices" VALUES ('b3941a80-6e5a-5ad0-ae85-8212736de06b', '2ec300d0-09a7-5c1f-b359-bf4319f3c86b', '2022-09-29 15:06:42.292', 30476);
INSERT INTO public."OrderItemsOnInvoices" VALUES ('f94e4f51-dffe-536b-a6ed-72496c6759a5', 'c43aa383-9051-54e3-8d05-fa3ab91896da', '2022-09-29 15:06:42.292', 46120);
INSERT INTO public."OrderItemsOnInvoices" VALUES ('935b61d3-e9fc-56f1-be5d-46f2964d466a', 'dca0921f-e17f-5bff-a978-da487e791fec', '2022-09-29 15:06:42.292', 661);
INSERT INTO public."OrderItemsOnInvoices" VALUES ('92e9426b-2cff-5d40-9f0b-5bc29652dea8', '0a63b2bb-a149-5d79-a56a-7e77306a426a', '2022-09-29 15:06:42.292', 25031);
INSERT INTO public."OrderItemsOnInvoices" VALUES ('ba590762-4089-58da-b07e-01ca832aa54f', '15a146d0-e461-5036-bd11-a49a5b4e2bb5', '2022-09-29 15:06:42.292', 46141);
INSERT INTO public."OrderItemsOnInvoices" VALUES ('24ff8ae5-363f-5939-b7d3-ff2a1d55f1eb', '2fe1c7b6-3ead-53ec-89b1-a8d68135e182', '2022-09-29 15:06:42.292', 27433);
INSERT INTO public."OrderItemsOnInvoices" VALUES ('79ede451-ebd9-5ada-9d66-3b15d2c20b6f', 'd1f38c5d-cb16-5e86-92b3-b3e87a06fb58', '2022-09-29 15:06:42.292', 41194);
INSERT INTO public."OrderItemsOnInvoices" VALUES ('e5404071-d1d1-52f8-a2d6-9ac99c2004d6', '5a3ac07c-cd5a-5cf2-b5f1-e9fa280f0a08', '2022-09-29 15:06:42.292', 23503);


--
-- TOC entry 4247 (class 0 OID 2148922)
-- Dependencies: 239
-- Data for Name: OrderStatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."OrderStatus" VALUES ('f5a656a2-309a-5844-b73a-38dac5041614', 'Eladio Kunde');
INSERT INTO public."OrderStatus" VALUES ('8ec31d84-dc80-51cf-aeab-8131275bc81a', 'Cayla Hegmann');
INSERT INTO public."OrderStatus" VALUES ('e6f1cec6-6c43-5a5e-a4d2-36bc4a4cb081', 'Woodrow Medhurst');
INSERT INTO public."OrderStatus" VALUES ('9e8edc7b-ab8d-52aa-a40d-11edb7c182ae', 'Odell D''Amore');
INSERT INTO public."OrderStatus" VALUES ('da74a0d6-81d8-5f28-944d-861c1ddc36b0', 'Cyrus Kertzmann');
INSERT INTO public."OrderStatus" VALUES ('6a8d204f-46d9-59f4-a79b-705c63a34586', 'Wilbert White');
INSERT INTO public."OrderStatus" VALUES ('fce00bf3-4259-555e-9c5e-19d215ee0b50', 'Leonora Murazik');
INSERT INTO public."OrderStatus" VALUES ('0c624a8f-a202-5353-af27-e0537b1cb8d9', 'Destiny Block');
INSERT INTO public."OrderStatus" VALUES ('de2cdf6e-71ac-524e-934b-cf40717f38fa', 'Paige Kassulke');
INSERT INTO public."OrderStatus" VALUES ('e5dc5adf-45fc-5744-a970-b80df61a6142', 'Floyd Schimmel');


--
-- TOC entry 4249 (class 0 OID 2148928)
-- Dependencies: 241
-- Data for Name: Parcel; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."Parcel" VALUES ('2caacd0f-d7b3-5887-bf98-37ed46388291', '2022-09-29 15:06:34.107', '2020-08-28 19:59:33', 13798, false, 27166, 4171, 58724, 21275, 'Visora kora yukoviko', 'Ramikoa vira', 60456, 19518, 33005, 'Viso viyua');
INSERT INTO public."Parcel" VALUES ('c3f41e2c-1159-5be1-98da-f4e0b3992ccb', '2022-09-29 15:06:34.107', '2020-10-02 22:06:42', 60344, false, 53191, 46023, 9952, 1501, 'Mia kovi rasomia', 'Yusoyu sovia', 20889, 8780, 25960, 'Rayu komiko');
INSERT INTO public."Parcel" VALUES ('0e977467-ff7d-5e98-8681-ce0400c44157', '2022-09-29 15:06:34.107', '2020-11-27 10:26:38', 64611, false, 31336, 17971, 194, 62224, 'Yuviyu viko', 'Viko koaso rasora', 28528, 13324, 18374, 'Vikovi miasoyu yumi');
INSERT INTO public."Parcel" VALUES ('b34a1bf1-f2bf-5a3c-af15-48ed1964c99f', '2022-09-29 15:06:34.107', '2020-06-26 05:06:07', 9228, false, 12558, 5525, 62730, 4895, 'Rami yuviso', 'Rayuayu yuayua', 60096, 13800, 19517, 'Miyu mikomi');
INSERT INTO public."Parcel" VALUES ('8d80a76e-8f93-507f-a816-3e1d9478ea70', '2022-09-29 15:06:34.107', '2020-04-28 15:27:14', 15777, false, 3039, 15089, 14095, 16376, 'Sora viyua soa', 'Yusomiso miyuso rayu', 39858, 41729, 13542, 'Kovirako koa');
INSERT INTO public."Parcel" VALUES ('a800e85a-3119-5423-86b6-e8bed6996ca6', '2022-09-29 15:06:34.107', '2020-09-13 20:34:11', 52658, false, 7814, 49574, 24553, 63185, 'Sovia miraviko', 'Yuakora yukora koaso', 37799, 19426, 63303, 'Raso koviyuso virako');
INSERT INTO public."Parcel" VALUES ('8e3c985f-282d-5739-b778-585109e06db2', '2022-09-29 15:06:34.107', '2020-01-21 00:00:27', 21684, false, 3759, 49699, 32590, 55039, 'Somi komisora', 'Viyusora rasoavi', 37611, 63169, 2299, 'Miso misora');
INSERT INTO public."Parcel" VALUES ('f4ae089d-1d7e-5a3c-906d-420cae7023c9', '2022-09-29 15:06:34.107', '2020-01-13 00:27:08', 23297, false, 17935, 10902, 12084, 26878, 'Viyuvi yuko', 'Korayuvi vikomi', 16831, 14825, 63964, 'Mirami soyu');
INSERT INTO public."Parcel" VALUES ('b5d64f9d-f105-56ca-84df-4f92aac041ba', '2022-09-29 15:06:34.107', '2020-08-04 19:40:02', 14432, false, 63891, 38441, 4135, 58715, 'Sora miyukomi virayu', 'Yuso raviyu', 36304, 41374, 42275, 'Raviso rayu');
INSERT INTO public."Parcel" VALUES ('2032bb51-97fc-5574-8f2f-e231d8a26d61', '2022-09-29 15:06:34.107', '2020-01-17 12:12:09', 13289, false, 52206, 26198, 50158, 18761, 'Yusoaso somi yusora', 'Rasoviso komi', 9436, 58515, 4412, 'Sovira sora');


--
-- TOC entry 4250 (class 0 OID 2148943)
-- Dependencies: 242
-- Data for Name: ParcelContainer; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."ParcelContainer" VALUES ('61a26115-e0ea-550d-8aa1-c12691225f5d', 'Angelina Prohaska', 'Rami soa', '2022-09-29 15:06:35.538', '2020-06-18 05:44:48', '1982-11-19 10:27:05', NULL);
INSERT INTO public."ParcelContainer" VALUES ('024ccd32-7353-5293-a027-d386afec5135', 'Kaley Hettinger', 'Mikoavi miyumiso', '2022-09-29 15:06:35.538', '2020-11-15 22:50:54', '1993-02-06 13:27:12', NULL);
INSERT INTO public."ParcelContainer" VALUES ('6718c13c-bcf6-5061-804c-f7499606902a', 'Twila Turcotte', 'Koyukoa komiyuso', '2022-09-29 15:06:35.538', '2020-10-26 21:23:11', '2016-09-01 20:57:24', NULL);
INSERT INTO public."ParcelContainer" VALUES ('2c3d0ce9-b59b-5523-bf69-c6cad4482887', 'Lloyd Jaskolski', 'Visomiso raviko', '2022-09-29 15:06:35.538', '2020-12-16 11:43:53', '2013-06-10 17:55:01', NULL);
INSERT INTO public."ParcelContainer" VALUES ('0a5d58e1-9baa-556d-a5cd-95d50b6f8036', 'Polly McClure', 'Miko yusomi miyu', '2022-09-29 15:06:35.538', '2020-09-01 08:49:08', '1990-11-23 10:24:29', NULL);
INSERT INTO public."ParcelContainer" VALUES ('756fd655-8984-5e1a-9aa7-761af5c0ee9a', 'Ross Gibson', 'Viso soravi komiraso', '2022-09-29 15:06:35.538', '2020-02-14 01:49:00', '1996-09-21 09:00:18', NULL);
INSERT INTO public."ParcelContainer" VALUES ('c2a70fcd-3e64-5eeb-8a94-f9537ef4e3e8', 'Natalia Robel', 'Yuvi viyuami', '2022-09-29 15:06:35.538', '2020-07-27 06:31:44', '1985-10-22 21:47:20', NULL);
INSERT INTO public."ParcelContainer" VALUES ('829b754e-70eb-53c4-a338-5800cde3d094', 'Lorine Metz', 'Yuvisovi mikovi koa', '2022-09-29 15:06:35.538', '2020-10-10 21:37:22', '2008-09-21 20:16:16', NULL);
INSERT INTO public."ParcelContainer" VALUES ('f8f10c66-5467-53fe-a24c-640a78290474', 'Jenifer Daugherty', 'Somi soviraso visoa', '2022-09-29 15:06:35.538', '2020-06-14 05:42:24', '1996-01-17 00:42:48', NULL);
INSERT INTO public."ParcelContainer" VALUES ('a3ea3362-502d-5332-b022-48aa30b20994', 'Neha Lindgren', 'Sovi visoviyu', '2022-09-29 15:06:35.538', '2020-01-05 00:51:14', '2017-10-22 22:09:15', NULL);
INSERT INTO public."ParcelContainer" VALUES ('67d70816-c407-5c5b-841a-f6c287a1ad2a', 'Kenny Spinka', 'Soviyu yuko', '2022-09-29 15:06:35.538', '2020-03-07 14:06:04', '2009-10-10 21:17:40', NULL);
INSERT INTO public."ParcelContainer" VALUES ('36c92c12-0128-59d7-a817-ad1dec0ffa33', 'Destiny Nolan', 'Viko ramiyu yuso', '2022-09-29 15:06:35.538', '2020-10-26 22:04:53', '1995-04-16 15:24:56', NULL);
INSERT INTO public."ParcelContainer" VALUES ('8c7f7dc0-9877-543a-a4db-79069581a904', 'Frida Prosacco', 'Koyumiyu rayuami', '2022-09-29 15:06:35.538', '2020-01-09 12:33:42', '1987-04-24 15:38:07', NULL);
INSERT INTO public."ParcelContainer" VALUES ('a58153cc-fc53-5cef-93d5-f20b0f6f12d7', 'Viva Dickinson', 'Rasoravi mikomia', '2022-09-29 15:06:35.538', '2020-01-17 00:12:16', '2006-03-15 02:26:56', NULL);
INSERT INTO public."ParcelContainer" VALUES ('c1aef344-20a3-5855-8a2e-e48ee6dda7d2', 'Grace Cummings', 'Yuviyu soami kovi', '2022-09-29 15:06:35.538', '2020-09-01 08:41:13', '2019-12-13 00:04:19', NULL);
INSERT INTO public."ParcelContainer" VALUES ('72cb64c1-d378-5bc6-8ad4-ab93d013fed0', 'Lawson Koss', 'Misoa miso vikomi', '2022-09-29 15:06:35.538', '2020-11-07 10:54:37', '2016-09-05 21:12:03', NULL);
INSERT INTO public."ParcelContainer" VALUES ('3ce79023-452a-5d03-a8f4-e56c000adde9', 'Marion Abbott', 'Miravi koviraso viyu', '2022-09-29 15:06:35.538', '2020-02-18 13:09:13', '2001-02-18 13:05:36', NULL);
INSERT INTO public."ParcelContainer" VALUES ('45419165-f989-52a5-9fb9-2c98612087d4', 'Gerardo Lowe', 'Visorami yuso', '2022-09-29 15:06:35.538', '2020-04-12 15:19:37', '1991-08-28 19:42:39', NULL);
INSERT INTO public."ParcelContainer" VALUES ('0f32e359-da2f-5810-a39a-64181b47f880', 'Briana Quigley', 'Ravi misoraso', '2022-09-29 15:06:35.538', '2020-11-03 10:44:53', '2019-12-05 00:02:40', NULL);
INSERT INTO public."ParcelContainer" VALUES ('eb998445-522e-5f3c-97d9-ed414c16baea', 'Elfrieda Thompson', 'Soyukomi miko', '2022-09-29 15:06:35.538', '2020-10-22 09:46:59', '1995-04-16 15:30:18', NULL);
INSERT INTO public."ParcelContainer" VALUES ('e903741c-d627-5fc7-9237-95afd8e254f5', 'Steve Murazik', 'Miso visovira rako', '2022-09-29 15:06:35.538', '2020-04-28 15:37:36', '2006-03-07 02:28:40', NULL);
INSERT INTO public."ParcelContainer" VALUES ('6a50de73-bf23-54d4-b00a-f3c5a22ad1fb', 'Tyson Yost', 'Virasoyu somi', '2022-09-29 15:06:35.538', '2020-01-01 00:40:20', '1983-08-08 19:57:00', NULL);
INSERT INTO public."ParcelContainer" VALUES ('b8e6a5c0-3057-594e-ae09-6692320e6708', 'Jaunita Cassin', 'Yuko soamia', '2022-09-29 15:06:35.538', '2020-04-04 04:03:11', '2012-01-21 00:14:12', NULL);
INSERT INTO public."ParcelContainer" VALUES ('26271427-b3c4-58ac-ae58-bc0fed612e27', 'Sebastian West', 'Ravia somiko', '2022-09-29 15:06:35.538', '2020-10-14 10:01:32', '1989-10-18 09:10:20', NULL);
INSERT INTO public."ParcelContainer" VALUES ('da726e54-8133-5ce8-a81b-fe27a74b314e', 'Myles Kris', 'Ravi viraso', '2022-09-29 15:06:35.538', '2020-01-01 00:26:35', '2003-08-28 07:46:29', NULL);
INSERT INTO public."ParcelContainer" VALUES ('7712d93c-251e-5a42-8baf-e9e2dbe344b1', 'Callie Kuhic', 'Koayura mira visoyua', '2022-09-29 15:06:35.538', '2020-04-12 03:20:54', '2010-07-07 06:41:18', NULL);
INSERT INTO public."ParcelContainer" VALUES ('8bf36b03-fb2a-520b-b25a-e3d2efb5a809', 'Damion Senger', 'Soavi miko', '2022-09-29 15:06:35.538', '2020-01-17 12:38:50', '2006-11-11 10:52:07', NULL);
INSERT INTO public."ParcelContainer" VALUES ('f8bff7ec-8ae5-5b79-88a2-2649857e4d0d', 'Sheridan Abbott', 'Miakoa viako somi', '2022-09-29 15:06:35.538', '2020-05-25 04:29:48', '1987-12-08 23:55:03', NULL);
INSERT INTO public."ParcelContainer" VALUES ('86597651-fde0-582d-be06-851041e194fe', 'Bernadette Runolfsdottir', 'Koyumia miso rakoyu', '2022-09-29 15:06:35.538', '2020-12-28 11:59:00', '1989-10-14 09:22:38', NULL);
INSERT INTO public."ParcelContainer" VALUES ('a3f81f13-577d-5ccd-b8f8-f29c14bca4e5', 'Kamren Rolfson', 'Koyu koviko', '2022-09-29 15:06:35.538', '2020-04-16 15:29:42', '2012-05-17 16:53:40', NULL);
INSERT INTO public."ParcelContainer" VALUES ('732aa38c-5606-50c1-a55b-8e4604862798', 'Elfrieda Gutmann', 'Virayu ramiraso kora', '2022-09-29 15:06:35.538', '2020-09-09 20:48:41', '1996-09-21 09:03:27', NULL);
INSERT INTO public."ParcelContainer" VALUES ('3210d868-d13d-5cf4-9203-7602ec182d88', 'Monica Koelpin', 'Komi vikoayu yura', '2022-09-29 15:06:35.538', '2020-12-12 23:48:14', '1994-11-07 22:41:27', NULL);
INSERT INTO public."ParcelContainer" VALUES ('55d00923-bec4-5f67-89f8-cf5032d6cb8d', 'Deonte Schmitt', 'Yusoraso visomi', '2022-09-29 15:06:35.538', '2020-03-07 02:48:36', '1989-06-14 17:32:01', NULL);
INSERT INTO public."ParcelContainer" VALUES ('199f6b80-faf4-5397-9127-7180f28e44b1', 'Gay Effertz', 'Soyua viyuso sovikora', '2022-09-29 15:06:35.538', '2020-04-16 15:15:15', '2014-11-11 10:41:45', NULL);
INSERT INTO public."ParcelContainer" VALUES ('35c7718c-969f-54b6-83c0-4a6afe89da90', 'Mia McCullough', 'Miaviyu rami', '2022-09-29 15:06:35.538', '2020-06-26 17:54:29', '2015-08-24 19:55:16', NULL);
INSERT INTO public."ParcelContainer" VALUES ('c9045d91-157f-559b-abc0-4bfad28c23ad', 'Joanie O''Kon', 'Rako rakovira komi', '2022-09-29 15:06:35.538', '2020-11-27 22:50:25', '1995-12-28 23:35:20', NULL);
INSERT INTO public."ParcelContainer" VALUES ('88a00204-179e-504f-8d21-02c3e0ff805d', 'Cletus Dietrich', 'Yumiyumi miyua viyuravi', '2022-09-29 15:06:35.538', '2020-05-05 16:27:44', '2019-12-09 00:05:11', NULL);
INSERT INTO public."ParcelContainer" VALUES ('fbb43610-e00f-56de-9304-045116d8ab05', 'Kendrick Hartmann', 'Soyumi viyua', '2022-09-29 15:06:35.538', '2020-12-16 23:36:54', '2017-02-02 13:39:49', NULL);
INSERT INTO public."ParcelContainer" VALUES ('6870511b-cefd-59af-b5fc-ca168610ad40', 'Jena Yost', 'Visoayu yukoraso', '2022-09-29 15:06:35.538', '2020-06-14 17:22:07', '2007-12-04 12:01:45', NULL);
INSERT INTO public."ParcelContainer" VALUES ('dd4d587f-47b0-5bef-adca-6c2e991cf52c', 'Alycia Hessel', 'Koa somi kovia', '2022-09-29 15:06:35.538', '2020-03-07 14:41:23', '1991-04-24 03:54:32', NULL);
INSERT INTO public."ParcelContainer" VALUES ('d8e43255-41e4-5e43-b94b-8c0b86d8bdfc', 'Unique Turcotte', 'Miyurako soasora yusovi', '2022-09-29 15:06:35.538', '2020-09-01 20:58:07', '1984-05-21 04:07:15', NULL);
INSERT INTO public."ParcelContainer" VALUES ('f52af647-f235-5f6d-8901-005cc2b9b71a', 'Mabel Wehner', 'Yumiyua somiso', '2022-09-29 15:06:35.538', '2020-11-07 22:47:03', '1999-04-12 03:45:01', NULL);
INSERT INTO public."ParcelContainer" VALUES ('91bcc150-3132-505c-9796-ebd0c840a434', 'Josh Jaskolski', 'Komi komikoa', '2022-09-29 15:06:35.538', '2020-02-06 13:25:54', '1999-04-24 03:49:32', NULL);
INSERT INTO public."ParcelContainer" VALUES ('0667a6d4-98d7-5c72-8483-1f5e1ee2d803', 'Marjorie Harris', 'Somiyura koyumi', '2022-09-29 15:06:35.538', '2020-07-15 07:04:16', '1997-10-14 10:07:43', NULL);
INSERT INTO public."ParcelContainer" VALUES ('88cebb9a-843b-5da0-a043-23a52893e791', 'Edwina Conn', 'Via yura', '2022-09-29 15:06:35.538', '2020-05-09 16:07:10', '2019-08-24 07:20:40', NULL);
INSERT INTO public."ParcelContainer" VALUES ('ff5d48fa-0e86-5678-be32-d145b6d105d6', 'Alejandra Steuber', 'Virami rami', '2022-09-29 15:06:35.538', '2020-01-25 12:06:21', '2017-06-06 05:17:47', NULL);
INSERT INTO public."ParcelContainer" VALUES ('5beded26-18d4-5ac0-8740-8b8f0721f000', 'Elaina Greenfelder', 'Somi mikoa', '2022-09-29 15:06:35.538', '2020-04-20 03:15:06', '1984-09-05 20:58:39', NULL);
INSERT INTO public."ParcelContainer" VALUES ('96a51582-4b1e-50ee-84d5-3a1f62fa2ef2', 'Delmer Metz', 'Yuami viyu', '2022-09-29 15:06:35.538', '2020-02-22 01:52:44', '1994-07-15 07:06:43', NULL);
INSERT INTO public."ParcelContainer" VALUES ('1e634d12-ae2c-5359-b70b-d9fc21d24c1e', 'Maverick Hamill', 'Koviavi yumi kovira', '2022-09-29 15:06:35.538', '2020-02-14 13:59:22', '1985-10-14 21:50:56', NULL);
INSERT INTO public."ParcelContainer" VALUES ('989cc40b-7b23-5f3d-943f-0d04be98a263', 'Tito Watsica', 'Soyusomi viraso ramiayu', '2022-09-29 15:06:35.538', '2020-02-22 02:03:14', '1995-08-16 07:55:57', NULL);
INSERT INTO public."ParcelContainer" VALUES ('eead9600-bb6c-51fc-9e0f-8e1756b41386', 'Milton Russel', 'Vira viakoyu koviso', '2022-09-29 15:06:35.538', '2020-11-03 22:24:30', '2006-11-23 10:56:24', NULL);
INSERT INTO public."ParcelContainer" VALUES ('4a038065-28ee-5b62-9c63-81f00f71d7ab', 'Melyna Yundt', 'Koyu miyukomi somi', '2022-09-29 15:06:35.538', '2020-08-12 19:46:07', '1983-08-04 19:52:44', NULL);
INSERT INTO public."ParcelContainer" VALUES ('937b5be6-f478-5d0a-966a-3f67b3f16304', 'Shanie Hills', 'Miravia yusomiyu', '2022-09-29 15:06:35.538', '2020-12-20 11:19:36', '1981-06-02 17:44:31', NULL);
INSERT INTO public."ParcelContainer" VALUES ('5bcf07ba-86e8-5b41-9a80-381b872e0f7a', 'Noel Zulauf', 'Viyua vikoyu', '2022-09-29 15:06:35.538', '2020-07-03 06:25:37', '2016-09-21 20:56:06', NULL);
INSERT INTO public."ParcelContainer" VALUES ('0ea2cc03-4765-5280-83d3-4a23cd1ae484', 'Rosalia Block', 'Rasomiko viso', '2022-09-29 15:06:35.538', '2020-01-01 12:24:15', '1991-08-12 19:35:23', NULL);
INSERT INTO public."ParcelContainer" VALUES ('6f39edf8-e379-536a-a05f-0a44ed90f344', 'Christop Jacobson', 'Komikoa ramirami koviavi', '2022-09-29 15:06:35.538', '2020-03-27 14:51:51', '1993-06-10 05:53:58', NULL);
INSERT INTO public."ParcelContainer" VALUES ('29842cdf-8352-56d5-bd02-41829a3d9d0c', 'Rosario Funk', 'Somi vikoa yusovi', '2022-09-29 15:06:35.538', '2020-04-20 15:17:32', '1982-11-03 10:29:44', NULL);
INSERT INTO public."ParcelContainer" VALUES ('ec15188f-3eb9-50ad-b015-8ad6d98a4cf4', 'Lillie Rice', 'Koa yuravi soamiko', '2022-09-29 15:06:35.538', '2020-12-20 23:36:57', '2000-09-17 20:20:09', NULL);
INSERT INTO public."ParcelContainer" VALUES ('c30cbc70-2725-5553-9d5a-73c4f22aa18c', 'Alverta Maggio', 'Koviyu misoyura', '2022-09-29 15:06:35.538', '2020-04-24 15:31:14', '1992-09-17 20:40:12', NULL);
INSERT INTO public."ParcelContainer" VALUES ('26f65fb7-618a-54fb-95ca-37733ddbc4e5', 'Julie Murray', 'Ramiko kovikoa sovikomi', '2022-09-29 15:06:35.538', '2020-04-04 03:20:25', '2011-08-08 07:35:05', NULL);
INSERT INTO public."ParcelContainer" VALUES ('8a8d1947-ffa9-55a7-9978-3d9e377d2957', 'Lee Thompson', 'Yukorami rakoyu vikovira', '2022-09-29 15:06:35.538', '2020-05-25 16:16:52', '2004-05-17 16:08:07', NULL);
INSERT INTO public."ParcelContainer" VALUES ('b78dde19-0c2d-5ea3-a2ca-bf05018d8166', 'Cleveland Herman', 'Miaso miso', '2022-09-29 15:06:35.538', '2020-08-12 19:58:41', '1989-06-10 17:33:00', NULL);
INSERT INTO public."ParcelContainer" VALUES ('725c2bae-9545-5d1a-84de-557d4025e157', 'Everette Kiehn', 'Kora yumiako viso', '2022-09-29 15:06:35.538', '2020-02-14 13:39:34', '2010-07-03 06:31:26', NULL);
INSERT INTO public."ParcelContainer" VALUES ('50d5e8e5-4a2e-5d24-8b13-3f8569f12aaf', 'Gracie Koch', 'Soviso kovia viko', '2022-09-29 15:06:35.538', '2020-08-24 08:03:40', '1983-12-28 11:38:16', NULL);
INSERT INTO public."ParcelContainer" VALUES ('bebd7542-94c9-5649-8a11-99ad60de95ad', 'Noemi Heaney', 'Koyumi yuvisomi rami', '2022-09-29 15:06:35.538', '2020-12-08 11:52:01', '2000-09-25 20:26:28', NULL);
INSERT INTO public."ParcelContainer" VALUES ('e8019f38-dec4-5e96-a39d-6f61514de51c', 'Ricardo Brekke', 'Sovi korakoa', '2022-09-29 15:06:35.538', '2020-04-24 15:19:49', '2003-12-08 23:36:53', NULL);
INSERT INTO public."ParcelContainer" VALUES ('616bb1da-a05c-50d9-8557-19d925ec561e', 'Lynn Wiegand', 'Mikovira yusoyu soyusovi', '2022-09-29 15:06:35.538', '2020-01-13 00:18:44', '2000-05-21 04:55:30', NULL);
INSERT INTO public."ParcelContainer" VALUES ('6f47a304-14f1-52ab-a63c-a045c58845e4', 'Sarina Heathcote', 'Soayuvi sovi miamia', '2022-09-29 15:06:35.538', '2020-08-24 19:23:14', '1988-01-25 00:55:38', NULL);
INSERT INTO public."ParcelContainer" VALUES ('41c30c15-d6a2-5c23-b910-a41d801ee215', 'Josh Lubowitz', 'Misoviyu kora rayuso', '2022-09-29 15:06:35.538', '2020-10-06 21:59:26', '2005-02-18 01:28:05', NULL);
INSERT INTO public."ParcelContainer" VALUES ('9e096368-6102-56cc-8084-04674b3bbfa1', 'Roxanne Kertzmann', 'Soa mikoyu', '2022-09-29 15:06:35.538', '2020-05-17 16:13:29', '1996-09-21 09:03:06', NULL);
INSERT INTO public."ParcelContainer" VALUES ('ca9654b8-b5d7-5880-8ebb-c0d9f7f9bcf8', 'Geovany Pouros', 'Miramira ravi', '2022-09-29 15:06:35.538', '2020-01-13 12:16:17', '2002-07-03 06:50:26', NULL);
INSERT INTO public."ParcelContainer" VALUES ('fb45a113-3643-5453-986e-276816529993', 'Jaron Buckridge', 'Koa soviko mira', '2022-09-29 15:06:35.538', '2020-10-18 21:22:55', '2014-11-03 10:50:15', NULL);
INSERT INTO public."ParcelContainer" VALUES ('056b536e-df8a-5494-b908-b5ca13e27ddc', 'Scot Hickle', 'Koyu visoyu yuko', '2022-09-29 15:06:35.538', '2020-05-09 05:04:09', '1996-09-01 08:59:02', NULL);
INSERT INTO public."ParcelContainer" VALUES ('7fac56cf-4db8-58d0-8c49-3759bcceb79c', 'Susanna Lubowitz', 'Soyuvi sora viayuko', '2022-09-29 15:06:35.538', '2020-11-03 23:03:52', '1980-05-01 16:45:01', NULL);
INSERT INTO public."ParcelContainer" VALUES ('7c80302b-5127-588c-9835-2b68271a9f32', 'Trever Kub', 'Viko mirasovi miakora', '2022-09-29 15:06:35.538', '2020-07-19 06:27:24', '2006-11-07 11:01:58', NULL);
INSERT INTO public."ParcelContainer" VALUES ('7d6a44c7-fa5b-5845-bafc-1e9c9c17a1c4', 'Katelyn Schumm', 'Koyukovi viso raviko', '2022-09-29 15:06:35.538', '2020-07-07 06:49:06', '1982-11-03 10:23:40', NULL);
INSERT INTO public."ParcelContainer" VALUES ('652a39f2-3e02-55f1-b702-4a99da0882f9', 'Janae DuBuque', 'Sovi vikomiko miami', '2022-09-29 15:06:35.538', '2020-06-02 05:16:06', '1992-09-13 20:38:09', NULL);
INSERT INTO public."ParcelContainer" VALUES ('812d034c-d986-5861-8813-5ca09aabbfe7', 'Jacynthe Jakubowski', 'Somiyu raso', '2022-09-29 15:06:35.538', '2020-09-01 20:24:20', '1992-05-01 05:02:02', NULL);
INSERT INTO public."ParcelContainer" VALUES ('20de885d-df35-5cb1-91d3-0172a0ce3c6b', 'Jannie Walsh', 'Koyu misomiyu rasovi', '2022-09-29 15:06:35.538', '2020-05-13 04:57:27', '2008-05-09 04:29:46', NULL);
INSERT INTO public."ParcelContainer" VALUES ('70537ec5-5302-5a96-af36-03b6fb74c179', 'Cooper Goldner', 'Soviaso miyu somisomi', '2022-09-29 15:06:35.538', '2020-11-23 23:00:43', '2004-05-25 16:05:20', NULL);
INSERT INTO public."ParcelContainer" VALUES ('298816f7-8baa-53f0-a50e-db2fa9c59cb4', 'Micheal Jakubowski', 'Soyuvi viami sora', '2022-09-29 15:06:35.538', '2020-01-01 13:04:20', '2001-06-26 05:53:33', NULL);
INSERT INTO public."ParcelContainer" VALUES ('460f484d-cf0a-563d-9c45-245edb67cc2a', 'Wendy Marks', 'Visovira rayumi', '2022-09-29 15:06:35.538', '2020-12-12 12:12:57', '1982-03-03 02:13:00', NULL);
INSERT INTO public."ParcelContainer" VALUES ('876c3c44-998b-5ff0-8aa0-c5527157a0fd', 'Brandon Dietrich', 'Yura viravia miyu', '2022-09-29 15:06:35.538', '2020-06-22 05:53:08', '1982-11-15 10:31:41', NULL);
INSERT INTO public."ParcelContainer" VALUES ('fb0cdb8a-71ec-5bd7-8cc2-40726a152d0e', 'Stan Baumbach', 'Visoyuko somiami mia', '2022-09-29 15:06:35.538', '2020-02-22 01:23:30', '1982-03-23 02:05:24', NULL);
INSERT INTO public."ParcelContainer" VALUES ('cc99d23f-6c70-5bcf-9386-81d33bfea927', 'Isaiah Hodkiewicz', 'Rayuavi miso', '2022-09-29 15:06:35.538', '2020-05-09 04:05:46', '1983-12-12 11:34:37', NULL);
INSERT INTO public."ParcelContainer" VALUES ('198e1571-6f40-5167-be96-132c111210c3', 'Darron McClure', 'Soayuko mirayura', '2022-09-29 15:06:35.538', '2020-04-20 15:05:53', '2007-12-16 11:48:53', NULL);
INSERT INTO public."ParcelContainer" VALUES ('942c309f-300b-54f9-960d-37259246783f', 'Keon Berge', 'Vikorako rako yumikoa', '2022-09-29 15:06:35.538', '2020-12-28 23:33:57', '1996-01-01 00:37:45', NULL);
INSERT INTO public."ParcelContainer" VALUES ('d3c9d495-6fad-5ad2-9087-f2257bd3c3d3', 'Martine Casper', 'Yumi rakoyua yura', '2022-09-29 15:06:35.538', '2020-10-18 09:24:19', '2006-07-27 18:17:38', NULL);
INSERT INTO public."ParcelContainer" VALUES ('33a8553d-45de-504c-92a9-c4a94ec5cc0d', 'Claudia Gerhold', 'Yuko rasovi visorayu', '2022-09-29 15:06:35.538', '2020-05-09 04:32:28', '1989-02-06 02:00:45', NULL);
INSERT INTO public."ParcelContainer" VALUES ('7bbb36d7-d5f8-56c7-b569-99ee73474716', 'Chase Hegmann', 'Vikoyuvi yurako visoviso', '2022-09-29 15:06:35.538', '2020-12-28 12:05:45', '1982-03-27 02:12:14', NULL);
INSERT INTO public."ParcelContainer" VALUES ('13c60058-1186-5188-bdcd-3bcc67232343', 'Enrique Conroy', 'Komiso kora', '2022-09-29 15:06:35.538', '2020-02-26 13:37:25', '1987-08-16 07:10:17', NULL);
INSERT INTO public."ParcelContainer" VALUES ('edac637c-d302-532f-b2a4-eca007c3e0d5', 'Nelson Mitchell', 'Ramikoyu somiko', '2022-09-29 15:06:35.538', '2020-12-16 23:47:02', '2002-07-27 06:49:19', NULL);
INSERT INTO public."ParcelContainer" VALUES ('3a01b6ab-d94f-53b9-91cb-86687d06e60b', 'Dakota Nader', 'Koavi kovi viyusoyu', '2022-09-29 15:06:35.538', '2020-05-09 16:53:53', '1991-12-08 11:19:52', NULL);
INSERT INTO public."ParcelContainer" VALUES ('c0e6f9a1-0f1d-5aa4-b1fd-d8f7324bd0f7', 'Jasper Senger', 'Rakovi mira', '2022-09-29 15:06:35.538', '2020-10-18 09:23:16', '1980-01-17 00:00:44', NULL);
INSERT INTO public."ParcelContainer" VALUES ('da9dc07c-827f-5516-8c7e-9789d8bb1dfa', 'Madie Langosh', 'Yuvia miko', '2022-09-29 15:06:35.538', '2020-08-04 19:10:19', '1985-06-02 05:15:59', NULL);
INSERT INTO public."ParcelContainer" VALUES ('0339d7d2-051b-59ed-b771-cf18929a6765', 'Adalberto Lynch', 'Soravira ramia', '2022-09-29 15:06:35.538', '2020-06-14 05:32:43', '2019-12-21 00:07:15', NULL);
INSERT INTO public."ParcelContainer" VALUES ('945aa1e7-c5b2-574a-b128-b5ab48423669', 'Ted Lesch', 'Sorayu miyuviso', '2022-09-29 15:06:35.538', '2020-08-24 07:21:44', '2002-07-07 06:57:09', NULL);
INSERT INTO public."ParcelContainer" VALUES ('73426b33-f8df-508b-90b4-3374c31678c3', 'Cecilia McKenzie', 'Misoravi koyu', '2022-09-29 15:06:35.538', '2020-02-22 13:50:17', '2011-12-08 23:14:09', NULL);
INSERT INTO public."ParcelContainer" VALUES ('57a728e0-a9c9-501d-9a30-b85a1adbdcc9', 'Caterina Welch', 'Koayumi yuso yumiyu', '2022-09-29 15:06:35.538', '2020-09-25 09:07:57', '2007-04-16 03:38:55', NULL);
INSERT INTO public."ParcelContainer" VALUES ('fd44b26d-0d90-5ab6-9a78-8dede00da031', 'Sam Huels', 'Somiyuvi sovi', '2022-09-29 15:06:35.538', '2020-12-04 23:44:30', '2007-08-16 19:23:35', NULL);


--
-- TOC entry 4251 (class 0 OID 2148949)
-- Dependencies: 243
-- Data for Name: ParcelLocationEvent; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."ParcelLocationEvent" VALUES ('b5053dcd-b6eb-5a6c-a075-0fa2e3c87596', '2020-01-17T00:53:03.000Z', 195, 148, '2022-09-29 15:06:34.216', '2020-09-21 08:28:30', NULL, NULL, 'f4ae089d-1d7e-5a3c-906d-420cae7023c9', '5185357c-a790-5fc2-8e81-1e3bf79f63d6', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('29a78f13-be9d-55b2-9571-8feaba7445f3', '2020-07-23T18:41:41.000Z', 234, 233, '2022-09-29 15:06:34.216', '2020-08-16 19:50:22', NULL, NULL, '8d80a76e-8f93-507f-a816-3e1d9478ea70', '7aea35aa-5a77-5acf-8161-2fe91b29d3a2', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('a65d0a2b-b9a5-5206-87b2-55e12946a4b5', '2020-10-22T09:32:19.000Z', 36, 155, '2022-09-29 15:06:34.216', '2020-02-22 14:03:21', NULL, NULL, '8e3c985f-282d-5739-b778-585109e06db2', '5444f259-27c2-5313-bf11-7237b395a1c7', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('26f3b017-f94e-5265-a901-1dcaa3191446', '2020-11-07T22:37:36.000Z', 0, 250, '2022-09-29 15:06:34.216', '2020-01-01 00:51:23', NULL, NULL, '0e977467-ff7d-5e98-8681-ce0400c44157', '4348530a-32bd-511d-95d3-bcb54f401b9f', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('ad9b9c69-93c7-5c9c-ae92-6daa395f8074', '2020-09-13T20:21:36.000Z', 82, 206, '2022-09-29 15:06:34.216', '2020-05-09 16:05:46', NULL, NULL, 'a800e85a-3119-5423-86b6-e8bed6996ca6', '73d964ac-98dd-523e-b9de-b4ca4c879ed2', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('0b7734f4-ca13-54a0-b30a-5bc22970385d', '2020-03-23T02:06:34.000Z', 77, 1, '2022-09-29 15:06:34.216', '2020-03-11 02:50:38', NULL, NULL, 'c3f41e2c-1159-5be1-98da-f4e0b3992ccb', 'bbb936a3-337d-5c4b-b7d3-c0af0978209a', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('12101c9b-6ea5-5bd7-a67e-1fe7cc9984c8', '2020-05-09T04:59:08.000Z', 30, 129, '2022-09-29 15:06:34.216', '2020-09-13 08:51:19', NULL, NULL, '2caacd0f-d7b3-5887-bf98-37ed46388291', '65e024a7-66e9-5650-bdff-7d2f9838b76a', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('ba98f49e-a46c-55d7-9768-c0c4ba4207e4', '2020-06-14T05:25:09.000Z', 193, 174, '2022-09-29 15:06:34.216', '2020-10-10 09:14:38', NULL, NULL, 'b5d64f9d-f105-56ca-84df-4f92aac041ba', 'f66355af-0ba5-5130-a19e-9b3fb66b7971', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('b555b9ee-ccf7-5a8f-837c-fc6d0e87fa7e', '2020-04-24T15:39:17.000Z', 73, 220, '2022-09-29 15:06:34.216', '2020-03-19 02:43:12', NULL, NULL, '2032bb51-97fc-5574-8f2f-e231d8a26d61', 'e5941561-c4b9-5933-89cf-48fb7d6d2e60', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('76a37a98-2ed7-5c42-b995-357fb7b94fbb', '2020-06-18T05:19:45.000Z', 190, 39, '2022-09-29 15:06:34.216', '2020-02-06 02:03:40', NULL, NULL, 'b34a1bf1-f2bf-5a3c-af15-48ed1964c99f', 'bcca18c3-5e46-56cb-b58b-c74cf16609b1', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('d9c362bb-20ba-5d4f-8018-b67e37e7146c', '2020-08-28T19:19:28.000Z', 204, 75, '2022-09-29 15:06:34.216', '2020-04-20 15:29:47', NULL, NULL, 'f4ae089d-1d7e-5a3c-906d-420cae7023c9', '5185357c-a790-5fc2-8e81-1e3bf79f63d6', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('1347b748-0b88-5370-bd6b-7e50af295868', '2020-03-11T14:44:14.000Z', 73, 66, '2022-09-29 15:06:34.216', '2020-07-23 06:25:22', NULL, NULL, '8e3c985f-282d-5739-b778-585109e06db2', '5444f259-27c2-5313-bf11-7237b395a1c7', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('ae4e44bf-370b-5299-a205-3fe6225b1956', '2020-01-05T00:59:23.000Z', 235, 163, '2022-09-29 15:06:34.216', '2020-03-07 02:08:24', NULL, NULL, '8d80a76e-8f93-507f-a816-3e1d9478ea70', '7aea35aa-5a77-5acf-8161-2fe91b29d3a2', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('db6789ca-d82b-5650-bd00-ee75d9faba9f', '2020-09-09T08:19:34.000Z', 134, 76, '2022-09-29 15:06:34.216', '2020-02-06 13:37:19', NULL, NULL, 'b5d64f9d-f105-56ca-84df-4f92aac041ba', 'f66355af-0ba5-5130-a19e-9b3fb66b7971', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('d8e004e6-927e-5f74-93b9-1897ce15df69', '2020-02-02T13:10:42.000Z', 193, 23, '2022-09-29 15:06:34.216', '2020-12-04 11:51:37', NULL, NULL, 'b34a1bf1-f2bf-5a3c-af15-48ed1964c99f', 'bcca18c3-5e46-56cb-b58b-c74cf16609b1', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('3b28a717-29f4-5c58-bc2e-b45ec8e0168d', '2020-12-08T23:38:51.000Z', 214, 217, '2022-09-29 15:06:34.216', '2020-07-07 18:46:12', NULL, NULL, 'f4ae089d-1d7e-5a3c-906d-420cae7023c9', '5185357c-a790-5fc2-8e81-1e3bf79f63d6', false);
INSERT INTO public."ParcelLocationEvent" VALUES ('b07367a8-b50c-5acd-bb2b-31de0c5e7946', '2020-03-27T02:46:15.000Z', 151, 127, '2022-09-29 15:06:34.216', '2020-10-18 09:45:59', NULL, NULL, 'b5d64f9d-f105-56ca-84df-4f92aac041ba', 'f66355af-0ba5-5130-a19e-9b3fb66b7971', false);


--
-- TOC entry 4252 (class 0 OID 2148956)
-- Dependencies: 244
-- Data for Name: PaymentCard; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."PaymentCard" VALUES ('8d818720-447e-5020-9c78-3b68f7724bd3', '2022-09-29 15:06:33.953', '2020-04-12 03:32:40', '1982-03-15 02:17:10', NULL, '2020-01-05T00:07:04.000Z', '2020-06-26T17:27:48.000Z', '2020-10-14T09:21:55.000Z', 'Soviso rayu', 'Monaco', '50874249-0fa1-5c80-aea9-3b87a5bce568', '5535016176232023', 'Viyusora viyura vikorayu', 'Jenifer Medhurst');
INSERT INTO public."PaymentCard" VALUES ('2041d35d-baff-5f4e-b262-013d847e08c0', '2022-09-29 15:06:33.953', '2020-03-03 02:42:01', '1989-02-22 01:50:38', NULL, '2020-02-14T13:01:20.000Z', '2020-08-12T19:34:55.000Z', '2020-11-15T23:00:42.000Z', 'Via koasovi yua', 'Angola', 'a50a7b36-9fea-58e3-a02a-53f9c50a944f', '2155689647888858', 'Yua vikoviyu soyu', 'Cortez Wolff');
INSERT INTO public."PaymentCard" VALUES ('fc45dea7-cf74-5a89-b2d3-699aa1c21161', '2022-09-29 15:06:33.953', '2020-03-15 14:29:38', '1981-10-14 09:24:43', NULL, '2020-02-22T13:49:43.000Z', '2020-11-11T22:57:01.000Z', '2020-06-22T05:31:28.000Z', 'Miyuayu viyua yuvira', 'Greenland', '033533ca-aff2-5ffa-aacf-291f0756b241', '6054521827679682', 'Vira soyua rayumiko', 'Delphine Weber');
INSERT INTO public."PaymentCard" VALUES ('379e48bb-3cbe-5840-800c-e5b2f34013e8', '2022-09-29 15:06:33.953', '2020-03-07 02:06:04', '1993-06-22 06:09:06', NULL, '2020-03-03T02:19:45.000Z', '2020-05-13T04:57:06.000Z', '2020-10-22T21:10:38.000Z', 'Kovisoyu raso', 'Antarctica (the territory South of 60 deg S)', 'ad3c51fd-225c-5a9b-ae90-df5693f5da41', '8533448494759837', 'Miaso koyumira', 'Elody Daugherty');
INSERT INTO public."PaymentCard" VALUES ('7530f3a7-e25d-5bb6-b897-21d39b1e8c51', '2022-09-29 15:06:33.953', '2020-06-18 17:30:28', '1997-02-06 01:38:43', NULL, '2020-07-27T19:01:26.000Z', '2020-09-25T08:08:03.000Z', '2020-01-17T12:13:26.000Z', 'Somi viyua soramiko', 'Angola', '6c769e74-f65c-5637-8921-c3f4fc3eb13a', '7970826057206101', 'Virako yumiraso', 'Neva Fisher');
INSERT INTO public."PaymentCard" VALUES ('0cb687dc-a9ef-5030-b05f-263a7a10d6b3', '2022-09-29 15:06:33.953', '2020-01-17 12:31:51', '2010-11-15 22:10:14', NULL, '2020-05-25T04:35:31.000Z', '2020-01-17T12:18:27.000Z', '2020-05-09T04:56:28.000Z', 'Soakomi somisovi miso', 'Angola', '6f1cf50a-a9bf-55b2-b17a-518cae59a591', '2631027140937928', 'Somiso vikoyura miayura', 'Frida Walker');
INSERT INTO public."PaymentCard" VALUES ('ba258121-9ac8-5310-b788-710723c966a7', '2022-09-29 15:06:33.953', '2020-03-03 14:34:40', '1992-01-21 12:27:37', NULL, '2020-08-04T07:58:19.000Z', '2020-05-01T04:19:02.000Z', '2020-01-05T12:28:37.000Z', 'Koraso yuso', 'French Guiana', '8edce74d-6eca-515f-8b41-ab7eb3b42016', '4549242169027182', 'Virami korasora', 'Mia Beatty');
INSERT INTO public."PaymentCard" VALUES ('d90c937d-4aa0-5912-b504-16177c7ed5f9', '2022-09-29 15:06:33.953', '2020-02-18 13:52:54', '1983-08-20 19:51:08', NULL, '2020-02-26T01:17:44.000Z', '2020-11-19T22:38:09.000Z', '2020-03-19T03:05:42.000Z', 'Soviyu koa raviyu', 'Malta', '31fccc7b-c865-5874-a952-0891831f51ab', '2611057594056826', 'Miko rasora', 'Jedidiah O''Kon');
INSERT INTO public."PaymentCard" VALUES ('8f70772f-6720-5ea9-b355-19ceec61b3a3', '2022-09-29 15:06:33.953', '2020-07-03 06:08:50', '1983-08-16 19:58:32', NULL, '2020-08-28T08:03:51.000Z', '2020-06-14T05:21:39.000Z', '2020-08-04T07:34:27.000Z', 'Kovi ramia mira', 'Taiwan', '93dd8e8b-213d-5214-8ad0-6a09f6e30762', '7842182639265628', 'Miyua yusovi', 'Dejuan Hermiston');
INSERT INTO public."PaymentCard" VALUES ('c51a666e-a559-58af-9c4c-a0344f8ed5aa', '2022-09-29 15:06:33.953', '2020-04-28 04:01:57', '2004-09-05 08:48:09', NULL, '2020-10-10T21:57:03.000Z', '2020-10-06T10:01:31.000Z', '2020-05-09T04:18:56.000Z', 'Misoyu yumiami koyukoyu', 'Palestinian Territory', '366ec623-de72-5760-af05-7523f60ae685', '6391716246479722', 'Mira mikovi viavi', 'Theresa Konopelski');
INSERT INTO public."PaymentCard" VALUES ('454ec363-f127-5143-adcf-f64ffb0d0407', '2022-09-29 15:06:33.953', '2020-09-01 20:58:42', '2008-01-05 13:00:05', NULL, '2020-08-24T19:33:36.000Z', '2020-01-05T12:45:31.000Z', '2020-03-11T14:26:38.000Z', 'Miakoa vikoviso yusoyua', 'Djibouti', 'df01c7e8-e3c5-571f-a1f2-ffa24547a981', '1424240558271636', 'Rasorayu yumi', 'Walker Balistreri');
INSERT INTO public."PaymentCard" VALUES ('13d5021e-6bc4-57ea-8170-25dc0aa6fd9f', '2022-09-29 15:06:33.953', '2020-10-10 09:21:09', '1985-10-06 21:56:17', NULL, '2020-03-15T02:18:26.000Z', '2020-11-03T22:55:50.000Z', '2020-10-02T21:24:39.000Z', 'Yurayu soa', 'Bahrain', '8e1e3cdc-8745-580b-9386-e055ea5dfcc0', '5580665494113347', 'Soako vikomi', 'Camren Brakus');
INSERT INTO public."PaymentCard" VALUES ('562a1adf-1766-5d10-afb3-1c1da985f9fe', '2022-09-29 15:06:33.953', '2020-03-15 03:05:17', '2014-11-19 10:48:25', NULL, '2020-04-28T04:03:21.000Z', '2020-09-13T21:08:48.000Z', '2020-07-19T18:47:26.000Z', 'Korayura mirako koami', 'Slovakia (Slovak Republic)', 'ad8f968c-22c7-515e-ba32-4a72a506b6bd', '4152492059760888', 'Yusoravi viamia viramiko', 'Anissa Kilback');
INSERT INTO public."PaymentCard" VALUES ('6982b615-0b5d-5349-bdf3-3a7b9b74f9ef', '2022-09-29 15:06:33.953', '2020-10-02 09:36:03', '1989-02-22 02:01:36', NULL, '2020-03-23T14:40:35.000Z', '2020-11-27T22:23:44.000Z', '2020-10-22T21:25:34.000Z', 'Soamiko soyu', 'South Africa', 'b9647ff8-5969-5343-a39e-aaabb01c4a46', '7486272290968501', 'Soyusomi koayu', 'Keyshawn Hackett');
INSERT INTO public."PaymentCard" VALUES ('14e33df6-3b82-5378-ae27-4612d9c0f434', '2022-09-29 15:06:33.953', '2020-05-01 16:31:37', '1980-09-13 08:20:05', NULL, '2020-08-28T08:02:13.000Z', '2020-08-16T08:07:51.000Z', '2020-12-08T11:26:38.000Z', 'Misomi koavi', 'Bhutan', '76b09cad-dd23-5db3-86e3-2b05909be16b', '3726993665946632', 'Vikomiko koyuvi', 'Junius Littel');
INSERT INTO public."PaymentCard" VALUES ('fdc1a57c-a6fd-5ba5-819a-ca580ef7cfc9', '2022-09-29 15:06:33.953', '2020-12-12 23:53:36', '2015-08-20 19:55:33', NULL, '2020-12-16T23:48:46.000Z', '2020-06-18T17:56:40.000Z', '2020-05-21T04:05:16.000Z', 'Mia sovi', 'Algeria', '54386220-64fc-5a03-b67a-674fe3607e47', '8383776708339204', 'Mirayu koavi', 'Nelda Willms');
INSERT INTO public."PaymentCard" VALUES ('35b7d2aa-46c9-507f-bfcc-547e9b6a8368', '2022-09-29 15:06:33.953', '2020-12-12 23:33:27', '2004-05-05 16:13:17', NULL, '2020-01-09T00:19:29.000Z', '2020-03-11T02:56:21.000Z', '2020-07-19T06:32:03.000Z', 'Yuviaso sora yukoraso', 'Svalbard & Jan Mayen Islands', '8d84b501-84f2-5fb0-bf3f-b1ca7f3b2645', '1775615256505444', 'Virako soyukoyu koa', 'Celestine Ankunding');
INSERT INTO public."PaymentCard" VALUES ('e509ca39-5d6c-5525-a319-f6d4d58dde13', '2022-09-29 15:06:33.953', '2020-07-15 18:58:54', '2019-08-16 07:23:55', NULL, '2020-04-28T03:54:02.000Z', '2020-02-18T13:50:35.000Z', '2020-06-14T05:41:41.000Z', 'Somira viyu', 'Madagascar', 'd3aef716-28eb-597f-829e-f1b08bd9987c', '1691505438244896', 'Sorakoa misoyu', 'Nicolette Jakubowski');
INSERT INTO public."PaymentCard" VALUES ('3341a08e-a738-5f30-9b3e-0308916e96ad', '2022-09-29 15:06:33.953', '2020-12-24 12:07:47', '2019-12-04 23:59:52', NULL, '2020-05-01T04:56:34.000Z', '2020-01-21T12:54:03.000Z', '2020-11-07T10:12:12.000Z', 'Viyumi soamira yua', 'Zambia', 'fbafc6da-f60b-570f-ade9-a088daa58dc9', '7205790623088776', 'Yusoa yumi', 'Johnnie Green');
INSERT INTO public."PaymentCard" VALUES ('4d6e30d5-57d7-5c08-8ca4-b097d37f9d2f', '2022-09-29 15:06:33.953', '2020-09-09 20:20:08', '2015-04-12 03:29:04', NULL, '2020-01-09T00:40:21.000Z', '2020-03-23T15:03:54.000Z', '2020-02-02T01:03:28.000Z', 'Viyuvi yukorako raso', 'Morocco', '2bbf641d-6ab4-56cc-ab55-9b1c327220c8', '4172683566709728', 'Koako ramisoa', 'Camilla Kris');
INSERT INTO public."PaymentCard" VALUES ('422cafb4-f770-5a58-a4a7-b4398e2046a0', '2022-09-29 15:06:33.953', '2020-06-22 05:55:41', '2010-11-11 22:16:28', NULL, '2020-01-13T12:13:01.000Z', '2020-11-11T23:03:53.000Z', '2020-11-23T10:10:50.000Z', 'Rakoyu rayuviko kovi', 'Bolivia', '204e5a88-7872-51bc-a246-3f19954113ad', '623637940845750', 'Miyumiso soakovi rakorako', 'Lamar Kertzmann');
INSERT INTO public."PaymentCard" VALUES ('5e57cec1-18c9-521d-829d-5f9e944b0d5c', '2022-09-29 15:06:33.953', '2020-08-04 19:55:24', '2006-03-07 02:40:06', NULL, '2020-05-05T17:03:23.000Z', '2020-02-10T13:47:39.000Z', '2020-07-15T18:54:07.000Z', 'Misovia koyu', 'Hungary', '1119b5d2-e30f-5665-ac5e-8be1e8bea2a7', '6123509448961118', 'Sovi raviyu', 'Garret Rolfson');
INSERT INTO public."PaymentCard" VALUES ('b62c6742-62aa-567a-b57e-2bd1a9c11b6d', '2022-09-29 15:06:33.953', '2020-12-20 11:46:52', '2003-08-16 07:51:18', NULL, '2020-08-08T07:27:31.000Z', '2020-03-07T02:50:13.000Z', '2020-10-18T09:39:35.000Z', 'Miyuraso rasoa', 'Republic of Korea', '6fa1a4eb-baaa-526d-acb6-2ef1b7270c0b', '281101439115597', 'Koa somira', 'Lila Borer');
INSERT INTO public."PaymentCard" VALUES ('4743df0c-7a48-5b3b-abe0-0004fec290a8', '2022-09-29 15:06:33.953', '2020-08-20 07:22:42', '2000-05-01 04:52:29', NULL, '2020-01-17T12:18:55.000Z', '2020-04-24T15:55:01.000Z', '2020-04-04T03:14:50.000Z', 'Via sorasoyu', 'Rwanda', '0b4964e1-9610-5a27-adc3-e602c87a1de1', '1492629105364300', 'Mikoyu via', 'Rudy Stanton');
INSERT INTO public."PaymentCard" VALUES ('8294fed5-675f-5cf4-88a1-55a764e01ead', '2022-09-29 15:06:33.953', '2020-04-24 03:51:58', '1981-06-18 17:55:59', NULL, '2020-07-27T19:04:00.000Z', '2020-10-18T21:42:30.000Z', '2020-03-15T14:41:59.000Z', 'Yumi koravira raso', 'Wallis and Futuna', 'e71564f3-95d0-5e4d-9eca-42d7f9647486', '217802498860780', 'Rami raviso', 'Roselyn Bartell');
INSERT INTO public."PaymentCard" VALUES ('5842040b-8cb7-5cee-b750-60b0b2331b0c', '2022-09-29 15:06:33.953', '2020-02-22 01:52:23', '1988-01-01 00:58:58', NULL, '2020-01-05T12:33:38.000Z', '2020-07-23T18:28:10.000Z', '2020-04-20T03:41:25.000Z', 'Virayu kora rakovi', 'Kuwait', 'fd3eead1-94cd-5be6-98e7-f9208a6ca386', '4591873427212574', 'Somisora miavi', 'Parker Ernser');
INSERT INTO public."PaymentCard" VALUES ('e9e40159-4e9c-5688-963d-a0e64abef4bf', '2022-09-29 15:06:33.953', '2020-07-19 18:55:36', '1993-06-06 06:01:50', NULL, '2020-09-01T20:09:38.000Z', '2020-01-01T12:22:23.000Z', '2020-02-14T01:01:13.000Z', 'Kora soyuviso miyu', 'Marshall Islands', '81be9a2d-865e-5229-ac90-ad8d4f31484e', '8724911918211323', 'Misomi ravikovi', 'Horace Walsh');
INSERT INTO public."PaymentCard" VALUES ('2541e7a6-957a-5bb0-803e-5be15c523631', '2022-09-29 15:06:33.953', '2020-10-22 21:31:16', '1989-10-26 09:15:01', NULL, '2020-09-13T20:57:15.000Z', '2020-08-16T07:14:43.000Z', '2020-07-27T06:47:13.000Z', 'Koa miyu', 'South Africa', 'a892a104-3d85-52f8-b5d1-5f14d100de79', '427129163296291', 'Viravi soyusomi', 'Brendon Nicolas');
INSERT INTO public."PaymentCard" VALUES ('afda028f-370f-55fb-a9d3-46f8a2c38b59', '2022-09-29 15:06:33.953', '2020-03-11 02:52:59', '1996-01-25 00:41:18', NULL, '2020-05-13T04:39:45.000Z', '2020-08-04T19:58:48.000Z', '2020-03-07T14:05:36.000Z', 'Mikoa viyuso', 'Virgin Islands, British', '4c456e4f-028d-5d2b-ad31-8fb768e6bb38', '8354856750580924', 'Soviavi ramiso viyusovi', 'Angela Dickens');
INSERT INTO public."PaymentCard" VALUES ('47d6341e-5db9-5b99-97d7-917c4d2702e6', '2022-09-29 15:06:33.953', '2020-01-21 12:50:54', '1995-12-24 23:45:53', NULL, '2020-04-04T03:22:03.000Z', '2020-02-10T01:03:15.000Z', '2020-08-20T19:30:24.000Z', 'Miyuko mia', 'China', 'baa507d8-79ac-51b0-800e-3a8a8394ca06', '7333002940090016', 'Rasomi sora yusora', 'Enrique Shields');
INSERT INTO public."PaymentCard" VALUES ('6762e9b4-bf75-5bd1-989e-95d889bad665', '2022-09-29 15:06:33.953', '2020-12-20 12:00:23', '1982-11-27 10:32:28', NULL, '2020-06-18T17:56:47.000Z', '2020-11-11T22:34:52.000Z', '2020-04-28T03:52:38.000Z', 'Soyu viayuko via', 'Micronesia', 'e3686415-4430-57b7-9abc-8b4b00f1f11f', '2365612488135505', 'Visoa visovi miso', 'Francis Crona');
INSERT INTO public."PaymentCard" VALUES ('6b6b047e-b798-5dba-94b2-0209a4f50109', '2022-09-29 15:06:33.953', '2020-10-10 09:22:55', '1998-03-11 02:47:02', NULL, '2020-11-23T23:13:53.000Z', '2020-03-03T02:38:24.000Z', '2020-08-12T07:32:43.000Z', 'Viko yuraviso miko', 'Antigua and Barbuda', 'b36fc0dc-103b-5c68-98b6-c1949a3e79c7', '5695848199247403', 'Yusoaso kovikovi', 'Jovanny Blick');
INSERT INTO public."PaymentCard" VALUES ('5ce9b202-5433-5304-9d01-c75539b723ba', '2022-09-29 15:06:33.953', '2020-02-26 13:42:47', '1982-07-07 18:42:41', NULL, '2020-04-08T03:29:00.000Z', '2020-03-07T14:51:23.000Z', '2020-07-19T06:57:56.000Z', 'Miamiko raso', 'Martinique', '39c9aa10-ea50-5987-97c0-c096b2a4d0d2', '3065996131586204', 'Yusovi somi yurayuko', 'Queen O''Kon');
INSERT INTO public."PaymentCard" VALUES ('6a27a36e-a320-5dec-a754-9404e0ac3e1f', '2022-09-29 15:06:33.953', '2020-11-19 10:27:19', '2015-12-24 11:39:14', NULL, '2020-10-10T21:36:19.000Z', '2020-11-07T23:03:28.000Z', '2020-01-21T12:50:33.000Z', 'Misoyu ramisovi rakomi', 'San Marino', 'aefa74dd-eb7d-574e-964f-c9d0eb28bb81', '4965125864990942', 'Mirako mikorayu mira', 'Filiberto Zboncak');
INSERT INTO public."PaymentCard" VALUES ('561d96f9-905a-5996-8aae-5df330ebb2ce', '2022-09-29 15:06:33.953', '2020-09-09 08:26:33', '2005-02-26 01:38:57', NULL, '2020-08-12T08:10:07.000Z', '2020-07-19T06:36:15.000Z', '2020-12-08T12:05:46.000Z', 'Mikovi sovisovi', 'Ghana', '16f6bab7-df5e-535e-87c1-a47e408aeebd', '6500325684338869', 'Somiko koa virakovi', 'Anderson Hintz');
INSERT INTO public."PaymentCard" VALUES ('5c01f0d4-3400-505c-964a-18a444f5e3e1', '2022-09-29 15:06:33.953', '2020-08-28 19:57:33', '1981-06-02 17:45:48', NULL, '2020-12-24T23:39:49.000Z', '2020-11-19T23:09:30.000Z', '2020-10-06T09:58:58.000Z', 'Koa viko sovisovi', 'Maldives', 'e08a941a-b675-56ac-ae0f-0f0fdfea2443', '480536190764945', 'Yumi via vikorayu', 'Gregg Champlin');
INSERT INTO public."PaymentCard" VALUES ('afc1ae07-d858-5bd9-b9e7-9fb67c25e29f', '2022-09-29 15:06:33.953', '2020-06-22 05:24:35', '1988-05-05 16:40:54', NULL, '2020-03-07T14:44:31.000Z', '2020-05-13T16:52:20.000Z', '2020-10-26T09:36:21.000Z', 'Yusoviko korayu miamiso', 'Bhutan', '92d5cee0-0b94-522d-aad3-fb4cbef58ae6', '3667113989529709', 'Miyura misoa', 'Claudia Fay');
INSERT INTO public."PaymentCard" VALUES ('fb91a49c-6391-5808-972c-cfb9ac4b5456', '2022-09-29 15:06:33.953', '2020-11-07 23:12:48', '2013-02-10 01:19:34', NULL, '2020-07-15T06:15:20.000Z', '2020-10-22T22:05:31.000Z', '2020-06-26T17:54:00.000Z', 'Mirayura visovi', 'Poland', 'e083b712-12c4-5d61-b723-a74953e2b953', '6040743744597263', 'Mikovi miyuviyu', 'Timmy Crona');
INSERT INTO public."PaymentCard" VALUES ('7767314d-4c4a-5cf2-8b14-a26b4ba95100', '2022-09-29 15:06:33.953', '2020-10-10 10:03:20', '1999-12-24 12:12:55', NULL, '2020-09-21T08:08:13.000Z', '2020-07-27T07:08:54.000Z', '2020-11-15T22:23:03.000Z', 'Mikora soa miso', 'Andorra', '12203f04-003c-5006-b00d-dcd353310378', '1979254048902613', 'Vira yusomira miami', 'Nash Gibson');
INSERT INTO public."PaymentCard" VALUES ('a6ec159f-71a6-5b1f-abd1-b465716bca16', '2022-09-29 15:06:33.953', '2020-01-01 00:14:28', '1998-03-03 02:50:38', NULL, '2020-02-26T13:52:48.000Z', '2020-06-26T05:18:07.000Z', '2020-03-19T02:38:39.000Z', 'Visoavi koa', 'Mauritius', 'eaa08505-0bd2-5164-ad4f-5be23ad91fc3', '3116903574705717', 'Rakoyua ravi mia', 'Kadin Morar');
INSERT INTO public."PaymentCard" VALUES ('4987e826-2450-54f0-97ea-7b7f1daa0c79', '2022-09-29 15:06:33.953', '2020-09-25 20:29:30', '1984-09-05 20:51:04', NULL, '2020-01-01T12:40:34.000Z', '2020-03-15T02:35:27.000Z', '2020-10-22T21:51:04.000Z', 'Rami viyumi', 'Bouvet Island (Bouvetoya)', '8f8daa2d-eaa3-566a-bc3b-2e5036e6084a', '7568882344726001', 'Soako virasoa rasomiso', 'Pamela Gislason');
INSERT INTO public."PaymentCard" VALUES ('7ea2d636-568e-5dd5-a806-a880c64c7ee5', '2022-09-29 15:06:33.953', '2020-01-05 01:01:22', '2004-01-17 00:36:31', NULL, '2020-01-13T12:14:39.000Z', '2020-11-23T10:32:38.000Z', '2020-11-19T22:11:49.000Z', 'Yumia rakoyu somisovi', 'Estonia', 'c11cab0f-0f9e-5a12-ab70-887238df2712', '1856176516030509', 'Miyu soviyu viso', 'Arjun Schroeder');
INSERT INTO public."PaymentCard" VALUES ('2df52ac5-7455-56d2-bb13-7ce878a6924f', '2022-09-29 15:06:33.953', '2020-06-06 17:30:37', '2003-08-20 07:50:33', NULL, '2020-12-04T23:26:06.000Z', '2020-11-07T22:12:26.000Z', '2020-08-04T07:44:07.000Z', 'Miko soa', 'Gabon', '4ae5a37e-ba8a-5229-8ce9-f06078144540', '7465012394648940', 'Yuviko yuamira', 'Theodore Kuphal');
INSERT INTO public."PaymentCard" VALUES ('100d4749-4427-5f6c-9285-dbfb4f905217', '2022-09-29 15:06:33.953', '2020-07-11 18:36:00', '2005-02-10 01:31:41', NULL, '2020-09-21T21:07:53.000Z', '2020-06-18T17:44:20.000Z', '2020-07-11T18:37:31.000Z', 'Yumira soa', 'Lao People''s Democratic Republic', '62d251b8-29c7-572f-913e-91f68befe13c', '3966372609291558', 'Koviravi rayu rasovi', 'Clemens Rippin');
INSERT INTO public."PaymentCard" VALUES ('44efadc0-d157-5171-8127-bfa81e9cc990', '2022-09-29 15:06:33.953', '2020-05-01 04:30:48', '2009-10-06 21:10:43', NULL, '2020-10-06T09:21:40.000Z', '2020-05-09T04:26:17.000Z', '2020-12-04T12:03:43.000Z', 'Yurako komikoyu', 'Madagascar', 'a90f1917-64d2-5daf-865c-b4f3a4e67933', '6792345975735157', 'Soviso yuramiso', 'Jude Gerhold');
INSERT INTO public."PaymentCard" VALUES ('dd19f8ed-e536-5064-83c6-8d5785eaf285', '2022-09-29 15:06:33.953', '2020-02-02 13:28:24', '2004-09-17 08:58:30', NULL, '2020-05-25T16:41:27.000Z', '2020-04-28T03:32:00.000Z', '2020-12-16T12:10:06.000Z', 'Koyura rako', 'Cayman Islands', 'ae860cf1-ddf3-5403-bb9e-28a8d97a2df1', '8236829227821333', 'Miso miraviyu raviyua', 'Rick Berge');
INSERT INTO public."PaymentCard" VALUES ('c488d96b-2ad3-5cf9-9ce9-65dff9d97d72', '2022-09-29 15:06:33.953', '2020-01-09 00:56:18', '2015-08-24 20:10:33', NULL, '2020-01-05T12:25:07.000Z', '2020-04-08T15:44:57.000Z', '2020-03-23T02:05:38.000Z', 'Soyuvi viko soaso', 'Iceland', '09c2a1ea-7fe8-521b-a536-cb28032eb281', '7793237496814520', 'Soyura yusoraso viso', 'Evelyn Flatley');
INSERT INTO public."PaymentCard" VALUES ('29e6a6c5-23dc-5e39-99a8-b9801f3b2e57', '2022-09-29 15:06:33.953', '2020-05-17 16:14:46', '1990-07-27 18:44:26', NULL, '2020-05-25T16:57:39.000Z', '2020-02-02T01:58:14.000Z', '2020-07-15T06:56:07.000Z', 'Yuvirayu kovia', 'Sudan', '7f6cfb0f-8045-5ff0-b352-87781cfdbe6a', '3024956760391821', 'Mirako korasovi vira', 'Jeff Jaskolski');
INSERT INTO public."PaymentCard" VALUES ('aa9b585b-f512-514f-80f5-1b0ac9741e8f', '2022-09-29 15:06:33.953', '2020-03-27 14:12:56', '2007-12-20 11:48:36', NULL, '2020-03-23T02:50:01.000Z', '2020-12-08T23:36:53.000Z', '2020-09-09T09:11:46.000Z', 'Mia yura rayua', 'Gabon', '837f3a47-886e-5d67-8317-a1efc7b28c8a', '8751616698546402', 'Via yumiko', 'Maximo Bernhard');
INSERT INTO public."PaymentCard" VALUES ('9857cb45-fd1e-5962-9cd2-af4e1cd4a736', '2022-09-29 15:06:33.953', '2020-07-07 18:42:06', '2013-02-14 01:29:19', NULL, '2020-05-21T16:20:32.000Z', '2020-11-19T22:42:21.000Z', '2020-06-06T17:18:43.000Z', 'Sovia viravia', 'Anguilla', '5389310f-bc83-5704-a0a9-002ad2dee3bf', '5111932350085141', 'Koyumira yuso misomira', 'Nedra Becker');
INSERT INTO public."PaymentCard" VALUES ('233e6399-62d0-5bdc-8f1c-9724f88d95c8', '2022-09-29 15:06:33.953', '2020-04-24 03:16:47', '1991-08-28 19:32:44', NULL, '2020-05-01T16:31:52.000Z', '2020-04-04T03:15:10.000Z', '2020-11-07T10:23:44.000Z', 'Viyuso koviako', 'Mauritius', 'fa45aa84-080e-5dd7-9d27-3e8f9caa515e', '3787959378369665', 'Viayuko miko yurami', 'Rickie Rau');
INSERT INTO public."PaymentCard" VALUES ('01ef690f-2f4f-59d7-bfef-8268e243a474', '2022-09-29 15:06:33.953', '2020-12-12 23:55:07', '1984-05-01 04:14:37', NULL, '2020-07-15T06:07:03.000Z', '2020-02-02T13:15:57.000Z', '2020-04-24T03:06:04.000Z', 'Ravira miko', 'Guatemala', 'fe30c4cc-e5d1-56e2-8ae9-82b1f0afa55a', '6659093835953960', 'Soyuaso rako koyukoa', 'Amara Bartoletti');
INSERT INTO public."PaymentCard" VALUES ('5be7b5e8-b484-5158-b77d-48e5971b44c7', '2022-09-29 15:06:33.953', '2020-08-12 19:43:19', '1996-01-05 00:44:14', NULL, '2020-01-01T00:27:16.000Z', '2020-06-22T17:24:49.000Z', '2020-07-23T06:16:59.000Z', 'Yuako miko mia', 'Turkey', '7fff1460-e962-5c43-bbe7-85cae0cf1010', '8741059639606415', 'Rasoa yukomi', 'Delia Willms');
INSERT INTO public."PaymentCard" VALUES ('8bb4467f-b29c-5728-a5ec-c7cb986ddff5', '2022-09-29 15:06:33.953', '2020-08-08 07:12:15', '1981-06-06 17:54:37', NULL, '2020-08-08T08:03:59.000Z', '2020-08-24T19:14:23.000Z', '2020-12-16T23:50:11.000Z', 'Yukora komia', 'Bhutan', '88b97a00-7e83-59d8-89f9-e6e701a6cf21', '115086241586454', 'Soviko raviako', 'Waldo Barrows');
INSERT INTO public."PaymentCard" VALUES ('b041b550-9f29-5112-abef-c10edec06d0f', '2022-09-29 15:06:33.953', '2020-02-06 01:57:15', '2011-04-16 16:04:12', NULL, '2020-11-03T11:11:34.000Z', '2020-06-02T17:40:06.000Z', '2020-09-09T20:24:41.000Z', 'Viyuami soyuvi somirayu', 'French Polynesia', '375915a6-74aa-564e-a501-84a94c8cbea3', '6014070650695073', 'Misoraso sovi', 'Genoveva Roob');
INSERT INTO public."PaymentCard" VALUES ('cfa59029-e730-5dac-aa05-adabdce3fe20', '2022-09-29 15:06:33.953', '2020-07-15 18:30:57', '1998-03-11 02:50:53', NULL, '2020-09-17T20:10:01.000Z', '2020-04-24T03:56:52.000Z', '2020-12-16T12:07:25.000Z', 'Viakoa via', 'Montenegro', '6166e67c-6ff5-596e-b5b5-52d8224f4578', '3038134752784650', 'Mirayuko mirami', 'Santino Goldner');
INSERT INTO public."PaymentCard" VALUES ('b75d0199-dc9f-5425-b27e-55c5e96f0f2e', '2022-09-29 15:06:33.953', '2020-09-25 09:00:02', '1991-08-08 19:33:27', NULL, '2020-01-13T00:00:33.000Z', '2020-01-17T00:08:26.000Z', '2020-04-04T15:30:06.000Z', 'Kovirayu yumira', 'French Guiana', '13322598-ecbb-51c4-bfbc-265f7d83d361', '5849703147069773', 'Soa koyu miayuvi', 'Lola Paucek');
INSERT INTO public."PaymentCard" VALUES ('a957d3a1-f884-5203-b0e1-4100041f1e6b', '2022-09-29 15:06:33.953', '2020-07-15 18:55:25', '1998-07-23 18:28:45', NULL, '2020-11-07T22:57:39.000Z', '2020-04-12T03:34:18.000Z', '2020-02-10T02:01:10.000Z', 'Koviso rami', 'Netherlands', '007c1af8-50e3-5fcd-bdac-685fb0891a72', '3527915302546912', 'Soavi rayuviso', 'Annamarie Metz');
INSERT INTO public."PaymentCard" VALUES ('9b641439-ad73-5dee-9bee-a5d94ad39cc0', '2022-09-29 15:06:33.953', '2020-06-22 17:47:32', '1992-09-17 20:36:21', NULL, '2020-01-21T00:36:14.000Z', '2020-07-07T18:18:55.000Z', '2020-03-23T02:53:18.000Z', 'Ramiso miyua somiyu', 'Maldives', '62251f70-6cd9-5fb8-a06a-a896d171b95f', '1492137519991384', 'Yua rami', 'Justina Renner');
INSERT INTO public."PaymentCard" VALUES ('659d770c-e7da-5601-a891-e01dd475ceef', '2022-09-29 15:06:33.953', '2020-08-08 07:34:17', '1984-01-05 12:33:17', NULL, '2020-09-21T09:11:30.000Z', '2020-03-23T02:27:39.000Z', '2020-12-20T11:58:59.000Z', 'Soaso soyu koviaso', 'Jordan', '00d4d6e5-9fbc-55ee-84c6-1fe0b189584f', '498637050421632', 'Koaviso rayu', 'Melba Kshlerin');
INSERT INTO public."PaymentCard" VALUES ('b00ac263-d498-5ff1-96be-c7aba0bc5f72', '2022-09-29 15:06:33.953', '2020-04-20 15:36:53', '2019-08-08 07:26:21', NULL, '2020-09-05T20:44:25.000Z', '2020-07-27T06:29:17.000Z', '2020-03-19T02:05:13.000Z', 'Rako viyusoyu', 'Albania', '009071cb-bc93-530f-bcc5-4d1d33d368db', '550128269509035', 'Miso rasorako koravia', 'Francesco Thompson');
INSERT INTO public."PaymentCard" VALUES ('20429e1c-c971-55c0-a6ef-70724fb1e7ea', '2022-09-29 15:06:33.953', '2020-01-13 12:23:38', '2015-04-12 03:21:08', NULL, '2020-09-09T20:23:04.000Z', '2020-06-14T18:01:58.000Z', '2020-11-03T10:51:52.000Z', 'Rasoyu mira mikoa', 'Greenland', '9f3ce743-c74b-5f0d-b38f-aa0f02b78068', '1128844855064541', 'Ramikomi viko', 'Keara Upton');
INSERT INTO public."PaymentCard" VALUES ('8ba2f71c-9e84-5c9d-a8d4-c003c9654889', '2022-09-29 15:06:33.953', '2020-09-21 21:06:08', '1994-07-15 07:01:28', NULL, '2020-06-18T05:44:47.000Z', '2020-01-17T12:38:51.000Z', '2020-05-21T16:38:29.000Z', 'Ravi korako soyu', 'Congo', '0b160527-bf01-5668-83aa-26e07126b799', '6115875680764663', 'Vira soviaso somiyu', 'Jasper Kutch');
INSERT INTO public."PaymentCard" VALUES ('5b107ac2-3d42-5b02-a69a-c70d7d86f3c7', '2022-09-29 15:06:33.953', '2020-10-10 09:37:01', '2018-03-19 14:39:56', NULL, '2020-12-04T23:49:16.000Z', '2020-11-11T22:41:52.000Z', '2020-03-11T14:28:03.000Z', 'Miko mirami miso', 'Saint Barthelemy', '036c8b7f-5eb1-5c09-a881-f4432a5ac8f0', '465763509997199', 'Vira raviyu', 'Lesley Upton');
INSERT INTO public."PaymentCard" VALUES ('141855d9-4111-5da5-83c7-ac5ced784d77', '2022-09-29 15:06:33.953', '2020-01-05 12:49:43', '2014-07-03 19:06:38', NULL, '2020-08-12T07:32:15.000Z', '2020-09-21T08:54:01.000Z', '2020-12-16T23:56:28.000Z', 'Yuavira misomiyu raso', 'South Africa', '9e7013e4-664d-530d-a06a-51beb5d514bc', '3477738277620857', 'Misorami somiyu', 'Deondre Waters');
INSERT INTO public."PaymentCard" VALUES ('fcf7907b-6290-5dac-9586-7202373e87d3', '2022-09-29 15:06:33.953', '2020-09-05 08:23:13', '2010-11-19 22:16:43', NULL, '2020-03-27T02:25:59.000Z', '2020-02-06T01:08:26.000Z', '2020-06-22T17:42:52.000Z', 'Yuvi rayumi miso', 'Solomon Islands', '9431d4c0-bda0-5dd5-b852-32bf379255d5', '4542534689411506', 'Soyu koravi', 'Ashlee Schaden');
INSERT INTO public."PaymentCard" VALUES ('26fd2de1-4c4a-539a-b6c2-93ecf2bba761', '2022-09-29 15:06:33.953', '2020-05-25 16:28:03', '1989-02-02 01:58:42', NULL, '2020-03-27T14:46:36.000Z', '2020-03-19T02:16:24.000Z', '2020-11-19T10:56:34.000Z', 'Viaso miyura', 'Jamaica', '8d344866-c2a5-55bc-8035-60c84538b9da', '8945799712961911', 'Viyua koa yuso', 'Charlie Gleichner');
INSERT INTO public."PaymentCard" VALUES ('53e5e20c-386a-5bf8-9e2e-af32868bedce', '2022-09-29 15:06:33.953', '2020-06-02 17:29:30', '2013-10-18 09:40:24', NULL, '2020-10-02T10:10:19.000Z', '2020-10-26T09:42:38.000Z', '2020-09-09T08:57:47.000Z', 'Viaso miamira yumiyu', 'Gambia', '38a09612-ebf2-54df-ba64-55eb39c42f7e', '8617720538667793', 'Korako rasovira', 'Florencio Grimes');
INSERT INTO public."PaymentCard" VALUES ('ca4c5936-ceed-5a71-80b1-fc5d87683bf4', '2022-09-29 15:06:33.953', '2020-06-02 05:30:12', '2002-07-03 06:54:45', NULL, '2020-03-03T02:23:36.000Z', '2020-03-19T14:48:27.000Z', '2020-04-12T15:53:25.000Z', 'Sorami sorasora', 'Spain', 'c43a020a-ea13-5882-b2cf-80561e94a998', '754887020727383', 'Raso rasovi virakovi', 'Ervin Volkman');
INSERT INTO public."PaymentCard" VALUES ('64e082b5-c489-5a62-a32f-72256ae56ce3', '2022-09-29 15:06:33.953', '2020-10-26 09:36:28', '2019-08-20 07:28:11', NULL, '2020-10-10T21:50:52.000Z', '2020-02-26T13:10:24.000Z', '2020-08-04T07:56:00.000Z', 'Kora misomi yuso', 'Togo', 'fb1dfee5-a4f5-550e-91bb-ad4741b67b14', '7098667027173099', 'Kovisoyu vikomi yumia', 'Colleen Satterfield');
INSERT INTO public."PaymentCard" VALUES ('be3180b7-63e4-52c0-8df2-26e12b420ed3', '2022-09-29 15:06:33.953', '2020-09-17 20:27:16', '1995-04-24 15:26:42', NULL, '2020-02-26T13:59:41.000Z', '2020-01-17T12:27:40.000Z', '2020-05-01T16:09:43.000Z', 'Sorayu miyurako', 'Georgia', 'dc291c09-1332-5a9a-a6a3-d9753c1fe28c', '5943340458800102', 'Misomiso sovi', 'Aron Lind');
INSERT INTO public."PaymentCard" VALUES ('79fdd62c-f960-5a31-8a16-f064baec0c8c', '2022-09-29 15:06:33.953', '2020-11-07 22:54:37', '2007-04-16 03:43:28', NULL, '2020-04-08T03:45:32.000Z', '2020-12-04T23:18:45.000Z', '2020-11-23T10:10:50.000Z', 'Mia soamia rasoa', 'Kyrgyz Republic', 'aaab8514-f4c3-5136-b90b-33924df69095', '5722805188598425', 'Yurami soako', 'Ben Hermann');
INSERT INTO public."PaymentCard" VALUES ('093c6516-9f59-50c3-9a4e-dedc9a7433bb', '2022-09-29 15:06:33.953', '2020-06-18 17:57:22', '2013-10-22 09:36:23', NULL, '2020-03-11T02:09:45.000Z', '2020-12-04T23:17:00.000Z', '2020-06-10T05:48:37.000Z', 'Raviavi koyura', 'Samoa', '60ae0ca1-a760-55b3-9729-944e3addc358', '1381946745061707', 'Koyuvira koami rami', 'Ena Hettinger');
INSERT INTO public."PaymentCard" VALUES ('c4ce138b-7ac3-544b-b1d9-58f3e3097525', '2022-09-29 15:06:33.953', '2020-04-08 15:41:21', '2004-01-05 00:36:19', NULL, '2020-05-25T16:58:21.000Z', '2020-09-25T20:11:12.000Z', '2020-05-05T16:35:04.000Z', 'Rayumia sovira kora', 'Algeria', 'f91bd7c2-bd2c-5cae-9048-c6960d5c64fd', '8219317840166086', 'Koramiko sora', 'Syble Collins');
INSERT INTO public."PaymentCard" VALUES ('84b5d1aa-d422-5444-9d72-20e7cc12f274', '2022-09-29 15:06:33.953', '2020-03-11 02:57:45', '2005-06-02 17:12:15', NULL, '2020-08-16T07:19:58.000Z', '2020-07-15T06:25:35.000Z', '2020-09-17T09:00:14.000Z', 'Misoa miayumi', 'Bahamas', '4c5be787-039e-51fd-8467-3a91ea254637', '4242111815836556', 'Ramiyuvi soravi soyurami', 'Wilfredo Abbott');
INSERT INTO public."PaymentCard" VALUES ('f9ca2453-b6bd-54a9-b13a-f6f3741c5135', '2022-09-29 15:06:33.953', '2020-03-23 02:41:03', '2002-07-27 06:57:57', NULL, '2020-08-24T08:10:19.000Z', '2020-05-25T05:02:05.000Z', '2020-01-09T12:17:51.000Z', 'Somiaso sorakomi', 'American Samoa', 'c0701a3c-17e8-55a1-8e98-f9bc3e30fea4', '2094758528559509', 'Soyuko soyu', 'Rudy Vandervort');
INSERT INTO public."PaymentCard" VALUES ('108f9b7b-83f5-5f6e-a09b-843720001b7b', '2022-09-29 15:06:33.953', '2020-11-23 11:03:58', '1984-01-21 12:40:05', NULL, '2020-12-04T23:49:52.000Z', '2020-05-25T04:41:34.000Z', '2020-12-08T23:24:46.000Z', 'Mia rasovia via', 'Cocos (Keeling) Islands', '85c1d0be-bbae-52a4-8542-05eeddcfea49', '7109103686978881', 'Komiami mirami rasoravi', 'Narciso Denesik');
INSERT INTO public."PaymentCard" VALUES ('000590c4-0ba5-59a8-a970-7ce9809b1644', '2022-09-29 15:06:33.953', '2020-08-20 19:35:38', '1992-01-05 12:19:18', NULL, '2020-11-07T23:11:38.000Z', '2020-07-19T18:38:14.000Z', '2020-08-04T19:58:40.000Z', 'Vikoraso soyuavi', 'Democratic People''s Republic of Korea', 'b4f2b87a-d3e7-56d3-b5aa-601e58fbe465', '790513925673536', 'Mirayu ramisovi', 'Noemi Berge');
INSERT INTO public."PaymentCard" VALUES ('238dd0ba-6dcb-54a4-a4e1-3895ff293e39', '2022-09-29 15:06:33.953', '2020-10-22 21:21:57', '1994-07-27 06:57:28', NULL, '2020-10-02T22:09:16.000Z', '2020-04-08T03:57:04.000Z', '2020-07-23T18:32:56.000Z', 'Viyura yuvisovi miyuso', 'Turkey', 'bdc2a440-41e4-5278-93ca-552f7cfffb3d', '3010762672211019', 'Soa viaviko sora', 'Clint Krajcik');
INSERT INTO public."PaymentCard" VALUES ('8b91636e-0c0b-5bac-951a-47b34c739b15', '2022-09-29 15:06:33.953', '2020-09-21 08:21:38', '2008-09-21 20:13:21', NULL, '2020-07-27T18:34:10.000Z', '2020-07-27T06:57:01.000Z', '2020-04-28T15:17:12.000Z', 'Rasoa sovi', 'Malaysia', '8f743748-55a5-54d9-8d25-a73bb7437aba', '4602729614251448', 'Ravirami soa', 'Frieda Mosciski');
INSERT INTO public."PaymentCard" VALUES ('e223af73-9c35-513d-a94b-336c554a7254', '2022-09-29 15:06:33.953', '2020-06-18 05:21:02', '2007-04-24 03:33:34', NULL, '2020-04-20T15:39:54.000Z', '2020-07-19T06:18:46.000Z', '2020-10-06T21:27:30.000Z', 'Viako ramikora mia', 'Wallis and Futuna', '9d9a0298-b406-56da-8f29-b713fc443f53', '3596788784800198', 'Ramira kovi visoyuso', 'Berniece Graham');
INSERT INTO public."PaymentCard" VALUES ('540df9e7-8cf4-5113-8ffa-5c549846dd00', '2022-09-29 15:06:33.953', '2020-04-04 15:53:16', '1981-02-02 01:09:32', NULL, '2020-01-17T12:50:29.000Z', '2020-06-02T17:25:46.000Z', '2020-04-04T15:47:20.000Z', 'Soa viko koviso', 'Colombia', '18900aaa-fcfb-5ac6-9653-06aea924b1ec', '6930977996141817', 'Vira soaso miyuvi', 'Randall Volkman');
INSERT INTO public."PaymentCard" VALUES ('26d04b1c-77fb-531e-af19-297645038f3d', '2022-09-29 15:06:33.953', '2020-08-24 19:56:54', '2008-01-13 12:52:59', NULL, '2020-04-08T03:27:36.000Z', '2020-10-18T09:17:48.000Z', '2020-10-10T10:00:04.000Z', 'Yuvi yukora koaviso', 'Hong Kong', '5c877895-1dec-5236-a1b1-c328dd6ec94e', '8137838059577967', 'Yumiyuko rami', 'Madilyn Wilderman');
INSERT INTO public."PaymentCard" VALUES ('bd44ea12-b358-589c-93c8-24fa6f37d7da', '2022-09-29 15:06:33.953', '2020-11-23 11:08:10', '1986-07-15 06:08:20', NULL, '2020-05-21T04:57:14.000Z', '2020-05-13T16:28:41.000Z', '2020-04-20T15:39:12.000Z', 'Virakovi sovi yurayua', 'Brazil', '04bb2ac8-d78d-5cc5-8cea-b65d42a1218d', '7854100946375194', 'Soaso virayua', 'Dario Balistreri');
INSERT INTO public."PaymentCard" VALUES ('cd585b06-9490-574f-9f21-466029f8e0d4', '2022-09-29 15:06:33.953', '2020-06-02 18:03:52', '1994-11-03 22:35:33', NULL, '2020-02-10T01:20:02.000Z', '2020-05-09T04:44:13.000Z', '2020-03-07T02:43:07.000Z', 'Viraviko miyu rakoyu', 'Guernsey', '80ff150a-8cb6-541a-9b57-9e3c299597c5', '652985600668318', 'Sorami koyurami', 'Bethel Heaney');
INSERT INTO public."PaymentCard" VALUES ('04fd7fea-0d89-5c6a-96f5-fa0bc31e7caf', '2022-09-29 15:06:33.953', '2020-10-02 09:19:59', '1988-09-05 08:19:37', NULL, '2020-05-21T16:52:14.000Z', '2020-09-21T20:31:25.000Z', '2020-02-26T01:09:49.000Z', 'Soa ravirayu', 'Republic of Korea', '7aa65960-21dc-5019-a8aa-67b702a62029', '5424171295216630', 'Somi yukoyu koyua', 'Godfrey Schulist');
INSERT INTO public."PaymentCard" VALUES ('ace6ba05-40d8-5175-a471-2f7f10d84d20', '2022-09-29 15:06:33.953', '2020-10-02 09:13:41', '1984-01-21 12:24:55', NULL, '2020-07-23T18:21:52.000Z', '2020-02-26T01:19:57.000Z', '2020-01-25T00:12:32.000Z', 'Yusoa rami', 'Gibraltar', '79a1823c-50f0-5bd2-9d7f-4cfc05233f4d', '2523030317650640', 'Komiyuko yuayu', 'Wilfredo Daniel');
INSERT INTO public."PaymentCard" VALUES ('f8aed76e-7f8f-5eda-9aa7-9f5116b01bd9', '2022-09-29 15:06:33.953', '2020-09-25 08:48:02', '1982-11-19 10:24:38', NULL, '2020-10-02T09:29:32.000Z', '2020-07-19T06:27:45.000Z', '2020-03-19T02:18:16.000Z', 'Yuviyu miko mirakoa', 'Saudi Arabia', '424b90cb-c5a7-5c99-99f4-24ee04b2347f', '1811472505389363', 'Koyuavi sovikoyu', 'Amparo Powlowski');
INSERT INTO public."PaymentCard" VALUES ('05cd4860-4e0e-5a06-8360-4de6351b0503', '2022-09-29 15:06:33.953', '2020-08-12 07:59:02', '1999-08-16 19:30:55', NULL, '2020-02-22T13:08:35.000Z', '2020-10-22T22:04:21.000Z', '2020-10-10T09:58:05.000Z', 'Miyu misoyu', 'Iran', '3546e73c-7e15-5806-984c-d714f4b9432d', '5964360150542748', 'Mia rayu viyumira', 'Cordia Thiel');
INSERT INTO public."PaymentCard" VALUES ('cd69db4a-b909-5d44-a6f8-376e3906ca8b', '2022-09-29 15:06:33.953', '2020-02-14 13:32:41', '1985-06-02 05:19:15', NULL, '2020-11-11T10:48:10.000Z', '2020-02-02T01:12:48.000Z', '2020-11-03T11:07:08.000Z', 'Via yumia virasomi', 'Portugal', '85af9392-f3e5-59c0-89ee-8a9d2fb09f47', '5709990895815266', 'Soaso rami', 'Danika Purdy');
INSERT INTO public."PaymentCard" VALUES ('b3194edd-f4fc-5c42-b540-0e700a408bd8', '2022-09-29 15:06:33.953', '2020-06-10 05:51:32', '2010-07-11 06:40:05', NULL, '2020-10-06T09:23:05.000Z', '2020-01-05T12:16:03.000Z', '2020-03-15T02:29:30.000Z', 'Raviso mira', 'American Samoa', '96f1013f-41c7-5ec5-bcc4-7eead9a55176', '7943281327291817', 'Soyuviso misovi', 'Reanna Spinka');
INSERT INTO public."PaymentCard" VALUES ('51d2de9b-9e60-5160-a391-9ccaa6f2392a', '2022-09-29 15:06:33.953', '2020-06-06 17:53:20', '2017-06-22 05:21:40', NULL, '2020-07-11T06:57:33.000Z', '2020-10-10T09:43:18.000Z', '2020-04-24T03:41:22.000Z', 'Yukoayu rami', 'Montserrat', '7f477b08-6c12-5e90-a5ef-bdcc1c9b702d', '3954007604922193', 'Miyura soyu', 'Vita McCullough');
INSERT INTO public."PaymentCard" VALUES ('6bb54e3f-7d2c-5879-8476-662a8c962292', '2022-09-29 15:06:33.953', '2020-12-08 23:55:03', '1984-01-25 12:32:06', NULL, '2020-09-05T21:09:57.000Z', '2020-11-11T11:11:35.000Z', '2020-03-07T14:42:39.000Z', 'Mikomiko yuvi korayuso', 'Saudi Arabia', '7f2696c2-2770-5a11-96ad-3fca7adb892d', '586499767591128', 'Yumiko koramiyu mikoa', 'Rudy Heller');
INSERT INTO public."PaymentCard" VALUES ('e6c09841-5aa2-5f44-8e5f-613a83097d27', '2022-09-29 15:06:33.953', '2020-09-17 20:42:39', '1983-12-08 11:30:21', NULL, '2020-04-12T15:40:57.000Z', '2020-11-19T22:29:18.000Z', '2020-07-07T18:31:38.000Z', 'Vira korakora', 'Northern Mariana Islands', '9ec847b0-d6ca-544f-8d46-38b25ee7439a', '343001449440938', 'Rayusora koa', 'Clarabelle Spencer');
INSERT INTO public."PaymentCard" VALUES ('feb7e6bf-025a-5187-a0c3-4df1de9b30d1', '2022-09-29 15:06:33.953', '2020-12-24 11:39:14', '1999-04-12 03:50:51', NULL, '2020-05-05T16:55:20.000Z', '2020-04-04T04:06:06.000Z', '2020-05-25T16:19:05.000Z', 'Koyu rayura', 'Guyana', '3e7a79ad-8152-5fd4-8e90-91a24d6b27ce', '126031629136708', 'Soyuko viyuravi koaso', 'Eudora Ritchie');
INSERT INTO public."PaymentCard" VALUES ('34a08fa8-e767-5fde-a776-3187b2ca8a5a', '2022-09-29 15:06:33.953', '2020-04-20 03:07:59', '1991-04-16 03:54:38', NULL, '2020-06-18T17:29:46.000Z', '2020-06-22T17:53:57.000Z', '2020-11-19T10:19:59.000Z', 'Rasoa sovi', 'Romania', '3b9e49e0-ce20-5482-b343-8be82246092f', '7247720720653738', 'Raviaso mikora', 'Kendrick Hauck');
INSERT INTO public."PaymentCard" VALUES ('7dcd164f-f73a-55fc-bdf3-33cc3f0a4d8d', '2022-09-29 15:06:33.953', '2020-12-20 12:11:27', '1989-10-02 09:25:21', NULL, '2020-06-06T05:52:52.000Z', '2020-04-24T03:34:23.000Z', '2020-07-19T06:48:01.000Z', 'Soviyu viso soviko', 'Botswana', 'a38833a2-82b4-5ab1-8fb3-5b9b83632ea4', '1142380167119627', 'Yuami koa', 'Ricardo Lockman');
INSERT INTO public."PaymentCard" VALUES ('2b6b71c9-3ca1-5592-a05a-0a937e7e0100', '2022-09-29 15:06:33.953', '2020-11-15 10:54:10', '1990-11-27 10:24:40', NULL, '2020-05-25T16:43:41.000Z', '2020-08-12T07:17:06.000Z', '2020-04-08T03:47:17.000Z', 'Yuamia soyurako', 'Madagascar', '39d93f14-ce2b-5dbe-b401-a298b2c4fa2c', '7042982199490107', 'Viyumi miyuraso koaso', 'Hailie Batz');
INSERT INTO public."PaymentCard" VALUES ('fc14a664-e6ee-5d7b-a902-ef6c469ccae2', '2022-09-29 15:06:33.953', '2020-11-15 22:37:30', '1987-12-24 23:58:00', NULL, '2020-05-01T05:02:23.000Z', '2020-07-27T06:34:31.000Z', '2020-05-01T16:25:20.000Z', 'Koviyu yura', 'Moldova', 'f322bb83-81a3-5979-b5f7-cb464853acdc', '4978029793729540', 'Viyurayu miavi yuko', 'Cristopher Block');
INSERT INTO public."PaymentCard" VALUES ('d5d39fb7-30ae-5bb0-b3b0-7fd79aaae7a2', '2022-09-29 15:06:33.953', '2020-01-09 00:13:12', '1981-02-02 01:07:54', NULL, '2020-06-18T05:22:04.000Z', '2020-08-04T19:37:21.000Z', '2020-04-24T15:43:07.000Z', 'Yumiaso rako yumiyuvi', 'Tuvalu', '769c22c5-5403-52fd-aa38-f59a8316d11d', '2286336021376076', 'Vikovi viayumi', 'Alysa Ward');


--
-- TOC entry 4253 (class 0 OID 2148962)
-- Dependencies: 245
-- Data for Name: PaymentTransaction; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."PaymentTransaction" VALUES ('1ffe32d5-c3c0-51d7-a418-940467139702', '2022-09-29 15:06:33.453', '2020-02-14 01:23:36', 'Soasora kovi visoviyu', 'Virako soako', 'Yuako yumiso', 'Rakoyu somia rayu', 'Sovi yusomiko viko', 'Yukoyuso virami', 'Ramira viso yuaso', 'Yura koayura', 'Misoayu koyu ravikoa', 'Somia koa', 'Soa somia', 'Miavira kovia', 'Viaso rakomi', 'Viko yuramia', 'Miayuko koyurayu', 'Yuako mikora mia', 'Vira yumiyua', 'Vikoyuvi yura', '{"Yuko": "Vikoyu koramira"}', NULL, NULL, NULL, NULL, 'Ravi koavi yuviko', 'Viami koyu miyukomi', 22334);
INSERT INTO public."PaymentTransaction" VALUES ('3b4bc2eb-adde-5c0f-bb97-f0094dbbf8e7', '2022-09-29 15:06:33.453', '2020-10-02 09:58:39', 'Soyu koyuko rakovia', 'Miyukomi rakoyu rayu', 'Mira yumiko', 'Rasora koayu ravisomi', 'Ravi yukorako', 'Somi rasoako raviyuso', 'Ravisora ravi', 'Ravikoyu soyuaso miami', 'Somia koa', 'Misoako soyu', 'Mirakovi mia', 'Yuvia yuvi viyusomi', 'Rayumira misoyu', 'Yurako viso', 'Viraso viso viako', 'Rako misora', 'Raso koaso mikoyuso', 'Yumi soviyu viayuvi', '{"Rami": "Ravi yukoyu"}', NULL, NULL, NULL, NULL, 'Mikorako rakomi koavi', 'Miayu soyu yukoyu', 27479);
INSERT INTO public."PaymentTransaction" VALUES ('d6a1d275-05d5-51e4-8da5-f6857751cf75', '2022-09-29 15:06:33.453', '2020-04-20 15:08:55', 'Vikoami ramiyuvi', 'Viyu soviso', 'Mikoa korako', 'Raviko yukoavi', 'Miko soyuso mira', 'Sora somiavi', 'Yusoavi miso', 'Sovi viayura', 'Sora soyusomi soasoa', 'Koamia rasoyuso', 'Rayu mikoraso', 'Ramiko rami', 'Yuraso soramira', 'Yuravia vikoa', 'Yuso mikoravi soviyu', 'Viko via rako', 'Korayura ravi', 'Komi sorami', '{"Soravia": "Raviko rayuaso via"}', NULL, NULL, NULL, NULL, 'Visoyuvi yuvi komisovi', 'Sorayu koviravi rakoa', 45588);
INSERT INTO public."PaymentTransaction" VALUES ('e71efb81-8d8d-5d23-9b88-a5a1ee80b08e', '2022-09-29 15:06:33.453', '2020-12-20 23:24:08', 'Koavi mirakoa koyu', 'Korami rami somikoa', 'Ramiko visoviko yukoyu', 'Via miravi', 'Rami yuaso yumiyuvi', 'Mia rako ravirako', 'Via yusovi ravi', 'Misoaso koviko', 'Soyurako koa misoa', 'Rasoyura sovisoa', 'Sovisoa soyura rayu', 'Yuayuko rayurayu', 'Soyua kora', 'Mikora miyu', 'Mirami miaso rayusoa', 'Yuramiyu yurasoa mikoviso', 'Misoviko koyu ravikovi', 'Kovia yumi miavira', '{"Rami": "Yuso yua"}', NULL, NULL, NULL, NULL, 'Vira viaso', 'Visoa miyu soasoa', 16049);
INSERT INTO public."PaymentTransaction" VALUES ('2a26bda1-c993-53c4-9bc8-741319476c95', '2022-09-29 15:06:33.453', '2020-11-11 10:46:03', 'Rako visora', 'Soyuso miso komisora', 'Kora sovisora soako', 'Vikoa somiso', 'Soa yusorami', 'Koyuvi yuako sovira', 'Virami via yukoami', 'Ravisomi kora mia', 'Koa mirayu', 'Viamiyu ravisora soa', 'Raviavi yuvia', 'Miyura soyumiso somi', 'Yumiko ravi soviyu', 'Raviavi viyukoyu yuso', 'Viraso sora ramikora', 'Miso sorako somiako', 'Viyua yukoako kora', 'Kora yumirayu', '{"Yuviraso": "Koaso mira soaviso"}', NULL, NULL, NULL, NULL, 'Ravi rayuviso', 'Miso mikomi', 54609);
INSERT INTO public."PaymentTransaction" VALUES ('18d4036a-9779-5721-b80c-713754044efe', '2022-09-29 15:06:33.453', '2020-12-20 11:24:29', 'Koami rakomi viyu', 'Ramiso rayu yukoyua', 'Yuavi rayura viayu', 'Yusovi yusoa miyurayu', 'Soyu viyurami rayuami', 'Miaso vikoyu', 'Yukora misoami rami', 'Yukoviyu yura', 'Vikomi viko rayuso', 'Yumiyua misora', 'Yukovi rayuaso', 'Vikoami rakoa yumiyumi', 'Rami soasomi viyuvi', 'Somi soramira yuako', 'Yuaviso sora', 'Rami miyuviyu sorako', 'Kovi via', 'Ramiyuvi komi', '{"Vikovi": "Miaviso yuavia"}', NULL, NULL, NULL, NULL, 'Miko raviso', 'Yuso ramiso', 37859);
INSERT INTO public."PaymentTransaction" VALUES ('a94b4d4e-5d2d-5c69-9d6a-163d952ec8c7', '2022-09-29 15:06:33.453', '2020-09-21 20:42:29', 'Rako ramiyu kora', 'Miyukoa komira', 'Visoyu ravi koraviyu', 'Ravi mikomi ravikoyu', 'Kovi soa ramia', 'Komira ramisovi', 'Ravi koasomi', 'Soa somia viyumi', 'Soyurayu miyu', 'Mira yuami misoyu', 'Yuvisora somi koyuso', 'Ramia rami', 'Vikovi soayuvi', 'Yukorayu rakomi', 'Mirayuko miko', 'Sovi soa', 'Rami soami rako', 'Kovi somiayu', '{"Koami": "Korami korakovi kora"}', NULL, NULL, NULL, NULL, 'Vira ramira virasoa', 'Viavira komiso', 8899);
INSERT INTO public."PaymentTransaction" VALUES ('59518413-3219-5d17-a972-6b2afd31e6b2', '2022-09-29 15:06:33.453', '2020-01-05 12:01:07', 'Soayu misoyu soako', 'Viaso rakovi', 'Yuvia visomi ravi', 'Yura yuako', 'Raso misovi rami', 'Yuviso soayuso', 'Miko soavi yuko', 'Miyusoyu somiaso', 'Rayua mikoyua koavia', 'Sovi koyura', 'Viyuraso sorayu', 'Miyumi ramisovi', 'Yuso yumiyu via', 'Miyuviso ramiavi', 'Yua rako yusorami', 'Yumi kovira yuko', 'Mirasoa via viso', 'Yumia via yuami', '{"Koyu": "Kora yuvia yumira"}', NULL, NULL, NULL, NULL, 'Viraviko raviyu', 'Virayumi rasoako rako', 21477);
INSERT INTO public."PaymentTransaction" VALUES ('fadfe6a1-76b1-54f6-812f-3d04e7dd9ade', '2022-09-29 15:06:33.453', '2020-06-18 17:47:21', 'Rayuvi kovi raviso', 'Soviso kovi', 'Komi somiyuko', 'Mira rayuvi soayumi', 'Kovi sovia mira', 'Miyuami koyura', 'Yuko viraso', 'Mia korakoyu vikora', 'Rako soramia', 'Misora virakoyu yua', 'Korami virasora', 'Vikomi rayuako', 'Yuvia visomiso miso', 'Yura somiso komiyuko', 'Yuvi yusoviko', 'Ramisora rami viamiko', 'Yuviyuko yura', 'Soyu sorakora', '{"Yurasoa": "Mira miyua mira"}', NULL, NULL, NULL, NULL, 'Viamiko miyukora mia', 'Viami ravi vikomi', 20325);
INSERT INTO public."PaymentTransaction" VALUES ('bf06b7ae-9ffd-5ddb-8fef-7f515bad9d12', '2022-09-29 15:06:33.453', '2020-09-09 20:20:01', 'Sovi koayuko rasomiso', 'Rayu koa', 'Rami viyumiso', 'Sora somikoyu komiko', 'Somia somisoa', 'Koviyu visoa', 'Koviso soami', 'Miayuvi soviko', 'Soviavi mirami yura', 'Yuvi ramiso', 'Vikoviso miko', 'Yuakoyu yukoraso', 'Viso koakora sovi', 'Miravi soyuvira yumiaso', 'Koramira yumikoa', 'Misovi komisovi miako', 'Ramisomi koyu', 'Korasomi yurako', '{"Soamiso": "Soyu visomira"}', NULL, NULL, NULL, NULL, 'Kora somiyu vikoyuso', 'Ravikora koyu', 58523);
INSERT INTO public."PaymentTransaction" VALUES ('182f92d1-bff1-50ed-9a89-271ec8cd624b', '2022-09-29 15:06:33.453', '2020-08-12 07:23:31', 'Koyukomi ramia sovira', 'Sorasoa ravi soa', 'Komirayu yuviami soviko', 'Soa rakoyu vira', 'Rakoami viramiyu mira', 'Yuakovi rayu mikoyuvi', 'Yuko yuviami', 'Yumi rakoayu via', 'Komi mia korakovi', 'Viasora mikoviso miyua', 'Miko soa', 'Mira miyumira', 'Viyua yura', 'Somikomi yuako via', 'Komiyura yukoa', 'Mia viyu', 'Yukoviso raso yukoaso', 'Yusoyu rayurayu viyu', '{"Rasoyuvi": "Yumi rakora"}', NULL, NULL, NULL, NULL, 'Yuraviso sorako', 'Miso raviko', 14894);
INSERT INTO public."PaymentTransaction" VALUES ('f8c3d777-2db1-505c-9703-4669e2786aaf', '2022-09-29 15:06:33.453', '2020-07-15 18:50:38', 'Soyukora yuvi korako', 'Raviso rasoyuko', 'Vikoyuko koravi', 'Rakoraso soviso', 'Raso koviso', 'Rako yumirayu koyuko', 'Yuviko via', 'Mikoyu yukomiso', 'Mia yura ramira', 'Visomia korayu', 'Somi sorayu komi', 'Via kora mia', 'Yura rasoyuvi', 'Mikorami soyu', 'Yumikoyu yuasoyu misovira', 'Rasomira rakoami', 'Mia viyu', 'Kovi koakoyu ravisoyu', '{"Yura": "Mikora yuso"}', NULL, NULL, NULL, NULL, 'Yuakoa soaso', 'Komia yuaviso soviso', 55853);
INSERT INTO public."PaymentTransaction" VALUES ('6ddd6102-ff01-5c7b-9278-d15ef2b046eb', '2022-09-29 15:06:33.453', '2020-03-23 02:40:50', 'Yumi soamia rakomia', 'Yuayu visoyu yukoayu', 'Visoavi miyumi soyuavi', 'Viyurayu miko', 'Raso somikoyu mira', 'Yumisoyu korayu mikoaso', 'Viamiyu virayumi rayu', 'Sovirayu koasovi', 'Vikoayu sora visomira', 'Visovi koa', 'Komikora miyuso kovi', 'Yurakoyu miavi', 'Ramira sora misomi', 'Rayura raviaso', 'Miso mia rasovia', 'Yuaviso kovi soaso', 'Yumia yukovi misoviyu', 'Soravi viamiko', '{"Rami": "Miamiyu ravikovi"}', NULL, NULL, NULL, NULL, 'Kovira koyu', 'Viramira koa soviyu', 24388);
INSERT INTO public."PaymentTransaction" VALUES ('c2be4494-4036-5257-9c14-e4c0ccf49ca4', '2022-09-29 15:06:33.453', '2020-02-14 01:38:10', 'Rayumiyu sovi viravi', 'Soyumi soviavi miayu', 'Viyu viyua', 'Koyumiyu ravira yuvikovi', 'Rasoa koramira', 'Koasomi soyura', 'Koayu yurakoyu', 'Yumiko koyuraso vikoa', 'Rasoviko ravi', 'Rayu soviayu', 'Somiko kora sorasora', 'Koakomi miravi', 'Koyukora yusomi', 'Virayura kora', 'Misorami miso', 'Miyusovi soako', 'Yumia rako', 'Viraviso somiko koviravi', '{"Koyurami": "Kovi korami rakoyuso"}', NULL, NULL, NULL, NULL, 'Rakovi soyuraso', 'Koyua sora', 2073);
INSERT INTO public."PaymentTransaction" VALUES ('18ba737a-8889-501c-be5b-3cbde8f8b3c8', '2022-09-29 15:06:33.453', '2020-03-19 02:25:37', 'Miyuviko soyuso sorayura', 'Soakora rasora soa', 'Raviso kovikomi kovira', 'Korami soa rasora', 'Ravisovi miso', 'Soayua yukoa', 'Komia yuayuso', 'Kovia yurakovi miyura', 'Komiso yuvi', 'Vira rasoa', 'Kovirayu koyu mikoa', 'Yurasora miavia koyuravi', 'Virayura sovi', 'Yusoa korasoyu viyu', 'Miyuviko mira raviyuvi', 'Ravira sora rayusora', 'Visorako viasomi soako', 'Yusoyu visoravi', '{"Vira": "Viaso mikovi"}', NULL, NULL, NULL, NULL, 'Yumisoyu miyu', 'Miramiyu yuasoyu', 63531);
INSERT INTO public."PaymentTransaction" VALUES ('02b0bd62-940b-5d68-8984-09fb9b017a23', '2022-09-29 15:06:33.453', '2020-04-12 03:36:24', 'Somikoyu ravi', 'Rasoyua yua', 'Visoyumi yua koyuviko', 'Soravira yua mira', 'Yumisoyu komi ramirako', 'Koyuso soyua', 'Yumiyu yuako kovi', 'Kovi somira koramia', 'Soyu kovisoyu yuso', 'Mia soayu', 'Rako koviko', 'Soyuviso yura', 'Vira korako', 'Yusovi somia koa', 'Koa vikoa rayu', 'Yusoa mikoavi', 'Koavia somisomi', 'Yuaso yusovi mira', '{"Korayuvi": "Viyuvi yuavira soviyu"}', NULL, NULL, NULL, NULL, 'Rami miyua', 'Vikovi rayu misoyuko', 54981);
INSERT INTO public."PaymentTransaction" VALUES ('7001e79c-01ee-514d-b011-6b5ecb56d71d', '2022-09-29 15:06:33.453', '2020-11-07 11:07:12', 'Rayu mikovia rakomiko', 'Vira rasoayu', 'Sovi yumisora', 'Viakoa miso', 'Miyu rasoyua', 'Viasomi viayu miso', 'Vikoa vira rayukora', 'Yuviyu viavi yuviyu', 'Kora komiravi koa', 'Visoyumi komira yukoyumi', 'Yurayu ravi', 'Koravia yukoviyu', 'Vikomiso rakomi', 'Vikoa yura viraso', 'Rayu miyumia', 'Miko visoyuso sora', 'Mia rakovi yuvi', 'Yurayu ramiyura', '{"Yuviko": "Koyura miyukovi virayu"}', NULL, NULL, NULL, NULL, 'Viso viyuviyu', 'Koyukoa soyukomi', 26425);
INSERT INTO public."PaymentTransaction" VALUES ('d0907e39-f9c0-5af3-86f6-64eded4337ec', '2022-09-29 15:06:33.453', '2020-01-13 00:28:24', 'Koa yukoviso rayuaso', 'Miyua somi', 'Soyu komikora viso', 'Komiraso mirayu somiayu', 'Yukoami sora miyua', 'Viso soyuvi soayuko', 'Misoviyu miamiko', 'Viayu yura', 'Kovi yuravia vira', 'Komikoyu soaso', 'Raviso viso soviko', 'Soasora viso koavi', 'Koviko vikomiso', 'Via koraso misoa', 'Soamira viyuso', 'Koyurayu vira', 'Rami rayua', 'Somi ramisovi', '{"Vikoyua": "Sora komiyumi"}', NULL, NULL, NULL, NULL, 'Komi mirayu mikoyura', 'Miaso yumikomi koramia', 5002);
INSERT INTO public."PaymentTransaction" VALUES ('a7fb05e3-ced2-511f-a2d9-a299102279e2', '2022-09-29 15:06:33.453', '2020-07-03 06:14:33', 'Mia viso', 'Soa vira', 'Soayu kora', 'Koraviso ravi', 'Sora soasovi', 'Rako misomiko', 'Kovi soyusoa viso', 'Miko mikoyura sovisoa', 'Kovisomi somiko rayu', 'Komi visoyu rayumiso', 'Yusoa soramia', 'Miyuviso sora', 'Vikovi viamiyu', 'Somiso soa viaviyu', 'Viyu korami vira', 'Soavi somi miyua', 'Yuviyu koyusoyu somiavi', 'Miravi yuvi viyumiko', '{"Somi": "Vikora vikoa visomira"}', NULL, NULL, NULL, NULL, 'Miyura soa yurako', 'Yuayura yuvi', 27284);
INSERT INTO public."PaymentTransaction" VALUES ('fa224fa5-41cd-5a64-a03c-c9d1d08689dd', '2022-09-29 15:06:33.453', '2020-04-08 15:14:40', 'Misoako sovi', 'Rayusomi soayura soyukora', 'Yuvira viaso kovi', 'Koayura vira rayuvi', 'Koraso yuko', 'Viamiyu yurasoyu', 'Soa viyu', 'Virayura miyu yuravi', 'Soyu rasoyu', 'Komiyuso yusomia rasomi', 'Viko rasomia sovirami', 'Sora viraso vikomiyu', 'Yuso soa soyuko', 'Viko vikorako', 'Yuko sorasoa miaso', 'Mikomiso soavira miravi', 'Korayuso sovia', 'Koraso koa', '{"Somira": "Yuayu koyu via"}', NULL, NULL, NULL, NULL, 'Ravia korayu', 'Yukovi sorakoyu kora', 50722);
INSERT INTO public."PaymentTransaction" VALUES ('5afe5081-c51e-58bc-853e-01c05608e1dc', '2022-09-29 15:06:33.453', '2020-08-28 07:53:43', 'Soayuvi miyura viko', 'Soyura soavi', 'Miyusovi viyu', 'Yukoyua viso koaso', 'Vikora miso yua', 'Somi vikorayu', 'Soa rasoyu miko', 'Raso misora vikoviyu', 'Mikoa somi rakoa', 'Koraviyu viravi soyu', 'Yuvi komiko', 'Koa koyuvi sora', 'Koviyuso yukoyu yuraviko', 'Koaso yuviyu koviyua', 'Vikora mia raviami', 'Miko viyua', 'Kora miako viko', 'Rami via rasorami', '{"Sovira": "Kovi miakovi"}', NULL, NULL, NULL, NULL, 'Miavi yurayumi', 'Yuravira komi', 55923);
INSERT INTO public."PaymentTransaction" VALUES ('240c6809-9dca-5313-8218-b5000854fabc', '2022-09-29 15:06:33.453', '2020-03-27 14:05:14', 'Mia soviko', 'Misoyu koami', 'Yukoa mikovi soyusoa', 'Soyumiyu miko', 'Komiako vira korasora', 'Kora vikoavi', 'Rako yusoa', 'Soraso yurakoyu', 'Yukoa sovisora vikovia', 'Soyu viyuko', 'Raso sorayu', 'Viasora soramiyu viaso', 'Rasoyuso yusoyua', 'Soyuvi rayuviko', 'Rayumira ravikoa yurayuso', 'Soyua yukoyuso', 'Mikorayu yumiayu viso', 'Yuvirayu viso yurasovi', '{"Rayumiso": "Miami ramiavi misoyu"}', NULL, NULL, NULL, NULL, 'Rami mirakomi', 'Rakovi soyuviko mia', 2432);
INSERT INTO public."PaymentTransaction" VALUES ('2177d2bf-3414-58f0-8cb8-6c8c5abb050d', '2022-09-29 15:06:33.453', '2020-12-08 11:32:34', 'Soviyu rayu rakoyuso', 'Yuko via miaviso', 'Vikoviyu viamiyu rayurayu', 'Raviyua kovi ramiyu', 'Soviavi vikoyu', 'Rakomi mira komikoa', 'Viyu soa', 'Miko viyumira yukoa', 'Yumiyu rayumia', 'Soviyua visoa', 'Miyu yukorami mirayu', 'Soaso yuasora', 'Yurayu visoami vira', 'Miyuviyu koami', 'Komia viyuraso ramiyu', 'Yuko yuaso mia', 'Koyura ravikoyu', 'Rakoviko komira yuso', '{"Misoa": "Soaso somi ramiravi"}', NULL, NULL, NULL, NULL, 'Soyukoyu somiko', 'Yuvirami koa vikora', 40721);
INSERT INTO public."PaymentTransaction" VALUES ('e6e44ad6-6196-50f2-b43c-81b95298477d', '2022-09-29 15:06:33.453', '2020-12-29 00:01:34', 'Miso ramia mia', 'Koyua miko', 'Koyumi sovisoyu', 'Virasoyu kovi', 'Soyura kovi', 'Mirayuko koami', 'Soyuraso viasoa soyu', 'Kora yukora ramisora', 'Korayu rasomiso', 'Yusovi yuso', 'Miraso yumi yuviso', 'Viko viyukora ravira', 'Viavi ravikoa', 'Kovi yuvira', 'Koaviyu mira', 'Yumi misoyumi yura', 'Mikoa yusomiyu sora', 'Koamiso koakoa komi', '{"Vira": "Sovi yusoako"}', NULL, NULL, NULL, NULL, 'Misoyua yuso yurakovi', 'Mira yuviyuko', 62807);
INSERT INTO public."PaymentTransaction" VALUES ('c11052b6-ed23-5684-8dad-8719bacf2654', '2022-09-29 15:06:33.453', '2020-11-15 10:34:57', 'Yuko rayuko', 'Rako mirami via', 'Miso rayuravi', 'Visomi korasora', 'Rasovi rami koa', 'Misovi yusoraso ravi', 'Koayumi kovi miyuso', 'Mira soyuravi yumi', 'Viso rayumi', 'Komira soaviyu koamia', 'Ravisoa somiso', 'Yuramiso via', 'Visoami miyuso', 'Misoviko ramiako yurasovi', 'Soa vikomiyu', 'Sovira ravi koami', 'Koakovi komirami vira', 'Yuko yua kora', '{"Mirasovi": "Soyu miyukovi misovi"}', NULL, NULL, NULL, NULL, 'Viayu yumira', 'Kovia rakoami raviyu', 3219);
INSERT INTO public."PaymentTransaction" VALUES ('d3e601e1-5dd2-50d5-adca-74a14a2ddbac', '2022-09-29 15:06:33.453', '2020-11-15 10:35:17', 'Yurako yukoraso vira', 'Viko rayuvi soa', 'Soavi mikoyura', 'Via kovira', 'Somia sovisovi viyuvi', 'Rayuko koayuko', 'Koa rakoviyu', 'Mikoyuso sovia', 'Korakoyu komi korako', 'Rako komiso', 'Soyuso komi', 'Rayuso yukoviso yumi', 'Viyuviko kora', 'Miko koviyuso', 'Yuko koyura yura', 'Mikoyuko kovi miyumi', 'Miyu yukovi soako', 'Komikoa yumiyu yumirako', '{"Mira": "Vikomi miyusoa"}', NULL, NULL, NULL, NULL, 'Raso raviravi', 'Soyumiko mia', 40731);
INSERT INTO public."PaymentTransaction" VALUES ('e056d397-eb40-5c6a-bce1-bb9399c361fa', '2022-09-29 15:06:33.453', '2020-01-21 00:43:48', 'Ravi somikovi', 'Soami yuso ravira', 'Koavi yuvikoyu', 'Virayura mikoa rami', 'Yura vikovi', 'Korayumi miaviso kora', 'Rayu rakomi yuayu', 'Raso vikoyuso', 'Koviraso viaviyu ravi', 'Yuvia yukovi mikoavi', 'Somiso soyumiko', 'Mikora koravira yua', 'Soviso koyuravi', 'Ravikoyu miso mirasora', 'Viyuvi visoa yumi', 'Miyu koyuaso', 'Somiko rayusomi', 'Sovira kovi', '{"Soayu": "Miko mikorami mira"}', NULL, NULL, NULL, NULL, 'Rayuayu ravira', 'Mirako rayurayu', 56878);
INSERT INTO public."PaymentTransaction" VALUES ('d46a9338-2561-5ce8-9764-0165254622e0', '2022-09-29 15:06:33.453', '2020-09-13 08:36:59', 'Yumiso yuso', 'Soavi komira', 'Mikora somikora', 'Viavi viayumi', 'Sora yurasovi', 'Koviko mia', 'Virasora soyuvi sovi', 'Soravira yurakoa mirakora', 'Miko yukoavi soayua', 'Rayua ravirayu', 'Somiyumi vira', 'Komiyu miyumia via', 'Soviavi virami yuso', 'Viavi koyumiyu', 'Rako yuvikomi', 'Miyumi soyumia soyumi', 'Soamiko soyurayu', 'Kora koyuvira visora', '{"Koyuko": "Somisomi rayura"}', NULL, NULL, NULL, NULL, 'Kovi koyumiso', 'Soaso raso', 61128);
INSERT INTO public."PaymentTransaction" VALUES ('d906a1e5-4561-5407-8451-271849eb01e1', '2022-09-29 15:06:33.453', '2020-08-08 08:02:07', 'Miyurami yuaso miyumira', 'Raviko viso soavi', 'Yuaso kovira viso', 'Viyuvia virako komisovi', 'Somiyu yusoavi rakora', 'Visorako viayu', 'Miso yua yumiko', 'Yukomira yukovi', 'Yurayu koyua', 'Viakovi soyusora', 'Yua yuvirami', 'Misomia visora', 'Virakomi komiayu', 'Yurakomi soaso', 'Ramiko koviraso miko', 'Viami komiyuso koami', 'Yuvira rasoa', 'Miayu koramiyu miayua', '{"Mia": "Yurako koraviso"}', NULL, NULL, NULL, NULL, 'Soaviyu rayu', 'Viavi misovi yuvia', 36522);
INSERT INTO public."PaymentTransaction" VALUES ('a3889143-16ac-5c68-9855-30d5c681569d', '2022-09-29 15:06:33.453', '2020-12-08 23:28:57', 'Soakomi soraso', 'Sorako viyuviyu', 'Mikomi vikomiyu', 'Mirami miso soyuko', 'Miayu viyu miyuko', 'Ravi ramirami kovi', 'Koyurayu yua soyusoyu', 'Yusorami viko rakora', 'Soraviyu soravi', 'Ravira yuko', 'Viavi misorayu', 'Yukoviko rayuayu rakora', 'Vikomiyu raso komira', 'Rakoyuko komira yua', 'Sovikora vikoaso yurakora', 'Misoyu rayu', 'Mikovira koviyu', 'Koako soravira misora', '{"Yurakoyu": "Miraviso komiako"}', NULL, NULL, NULL, NULL, 'Viyu miyuso miamiyu', 'Virasoyu koyu', 54681);
INSERT INTO public."PaymentTransaction" VALUES ('72392322-2710-5f14-91c6-b5d6ec4bee64', '2022-09-29 15:06:33.453', '2020-03-03 14:14:37', 'Viyu mirayu viyu', 'Kovi rasoyu koa', 'Sorakora rako', 'Miyu miamiko', 'Soamiyu yumisoyu koavia', 'Rayu misora', 'Miko rakoa yuko', 'Yusoavi miyuso', 'Yuso yukomi', 'Komia raso vikomi', 'Ramira yusoayu', 'Rasoayu somiso rayukoyu', 'Yuramiso ramia', 'Viyuvira raviyu ravia', 'Koaviso vikoyuko', 'Yumiko yuramiyu yukovi', 'Somia viyumiyu', 'Somiko yukoayu', '{"Yuko": "Sora yumia ravi"}', NULL, NULL, NULL, NULL, 'Koyu koravi viko', 'Miyumia miramiso somia', 16121);
INSERT INTO public."PaymentTransaction" VALUES ('0e49a2c3-0b04-5452-bb5b-0ebfee51cbd2', '2022-09-29 15:06:33.453', '2020-04-04 15:52:41', 'Korako yuvikoyu yura', 'Yukoayu viso', 'Miso somia mirayumi', 'Koyuavi soa viyu', 'Soyu vikorami', 'Yukoa rayuko', 'Yuviyura koviako', 'Yumi yuvirako', 'Yuvikoyu rakoyu koraviyu', 'Viravia koyura', 'Miko rakomiko', 'Ravia komiyu', 'Sorayu yuko miayu', 'Yurakovi rako', 'Soasomi yua', 'Rayukora yumiko visorami', 'Viraviso kora', 'Viaso yukorayu komira', '{"Yuso": "Yuko vikomi mikoraso"}', NULL, NULL, NULL, NULL, 'Miyu soa komiyuvi', 'Yuvi koyusomi rayuvi', 25952);
INSERT INTO public."PaymentTransaction" VALUES ('dc972550-45a8-59d7-b439-99df40fecb2a', '2022-09-29 15:06:33.453', '2020-10-06 09:48:01', 'Komi somiko yura', 'Somiko yumisora', 'Kovi sorasoa viyusoyu', 'Ravi ramiako mia', 'Rako rakoa', 'Viyuviso vira', 'Koa yuvia yuvi', 'Yumiyua miavi', 'Viavi raviyu vira', 'Viravi rako', 'Visora yusoyuvi viso', 'Yumi somira koyusora', 'Sorakomi rasoyu yumi', 'Komia yura mikoyu', 'Soyuvi ravi', 'Koyu yurako miraviyu', 'Rayu soa', 'Virayu kora', '{"Miami": "Via kovikomi miko"}', NULL, NULL, NULL, NULL, 'Rayu ramiavi viako', 'Yuko koami korayuvi', 46607);
INSERT INTO public."PaymentTransaction" VALUES ('0e57dde4-657f-5427-9a44-186c85c2901d', '2022-09-29 15:06:33.453', '2020-02-06 01:16:42', 'Koyumi somiyuko rami', 'Miyumiso viko', 'Somirayu raso', 'Mira rayuvi', 'Vikorami vikomi', 'Via miyu kovia', 'Mira ravikoyu koasoyu', 'Sovira rami', 'Miako rasoyu viamiso', 'Miyumia rakoviyu', 'Rasovi mira', 'Koyu viyuvira', 'Yuvi kovirako', 'Viako yusoyu soyurayu', 'Mia rakorayu', 'Korakoyu yusoa koyumi', 'Somi ramiyu rami', 'Viraso mia', '{"Misora": "Viso rasoa"}', NULL, NULL, NULL, NULL, 'Korayumi koamiko', 'Soramiso visomia', 7916);
INSERT INTO public."PaymentTransaction" VALUES ('43fc1848-3ea8-5bfa-84fd-b1cd88213adb', '2022-09-29 15:06:33.453', '2020-09-01 08:20:08', 'Koyu miyura', 'Koaviso mikoviyu', 'Vira mikoa mirami', 'Komiako visoyuvi', 'Raso viamiso', 'Yukovi somia', 'Komi somikoyu', 'Yumi viyura rako', 'Koako rami viyuso', 'Yuaviyu sovikora', 'Soa viavira', 'Mira koyuraso', 'Komiavi somiraso viasoa', 'Viyumiko via', 'Viyuami mira', 'Yuako korayumi soyu', 'Rakomi koyu ravira', 'Soa yukoviso', '{"Soyumi": "Miami koyu"}', NULL, NULL, NULL, NULL, 'Virami koasovi somia', 'Soyura viko via', 54652);
INSERT INTO public."PaymentTransaction" VALUES ('948cc4a3-d033-585d-8403-7f4cf732f2df', '2022-09-29 15:06:33.453', '2020-09-17 20:32:38', 'Koyu sovia', 'Somikovi sovikoa koaso', 'Via yusomiyu', 'Miyu misovi', 'Miko ramiso', 'Soa komi viravira', 'Vira viyukoa', 'Sora rayuvia', 'Rayu rakora mia', 'Somisovi viso mia', 'Rayu rakoa', 'Yua komi', 'Koyuravi kovira', 'Rakovi kovisoa', 'Mira viaviko', 'Korako miyuraso miami', 'Miyuviko yua', 'Korayu koa', '{"Miko": "Yumira viako viso"}', NULL, NULL, NULL, NULL, 'Yura virayu', 'Koviyu koyu', 17170);
INSERT INTO public."PaymentTransaction" VALUES ('186a8b44-89d6-5ef4-8da1-2485086c89df', '2022-09-29 15:06:33.453', '2020-04-08 03:07:33', 'Koyu miavi yuayua', 'Mirayu viyurako', 'Rayura yuayuvi rakoa', 'Koa koyu', 'Raviko yumi vikoa', 'Yurami rayuraso', 'Komi mirayu', 'Sora yurasoa', 'Koviami yukomi rasomiko', 'Ramikomi yuko komiso', 'Miako mirakoyu', 'Vikoyu soa soviyu', 'Soyumiko misoa', 'Viako kovisoa viayu', 'Kora mikora koayu', 'Yumi viayu soyuso', 'Yukoyu viko miyua', 'Misoviyu koami misovi', '{"Virami": "Rako misovi"}', NULL, NULL, NULL, NULL, 'Soviso yuvi koavi', 'Viyuso misoyuko rakoa', 56383);
INSERT INTO public."PaymentTransaction" VALUES ('b8596017-2359-5a7c-aa23-2e95e1733ca8', '2022-09-29 15:06:33.453', '2020-11-15 22:25:45', 'Mira somiko soamiso', 'Koako miyu raviyura', 'Ramiko miasoyu', 'Koyu sorayu', 'Yumisoyu kovi', 'Ramira komi mikomi', 'Soyuvi yuvikoa yua', 'Korami komi koako', 'Yukoyu misorami ramira', 'Koyua koaviko', 'Yurako yuvi', 'Kovikora mirako', 'Via viyu', 'Miko rayua', 'Sovisoyu sorayu miso', 'Yumiso rasoa ravi', 'Yuko koami rako', 'Yumiyu rasoa', '{"Komi": "Soyuko miavi"}', NULL, NULL, NULL, NULL, 'Mia koayumi', 'Soyu yusomiso yura', 62337);
INSERT INTO public."PaymentTransaction" VALUES ('39f53867-bba4-5a23-9f9f-577fa2cd0df3', '2022-09-29 15:06:33.453', '2020-12-29 00:00:17', 'Ramirami sovi', 'Vikoyuso ramia kora', 'Rakorayu miyu', 'Viami kora', 'Mirako rasoa', 'Soraviso yumia', 'Soa rasoviyu', 'Yuaso somiyumi', 'Viyuso somia', 'Rayusoa koavi', 'Yuviso yuvia', 'Soayumi soakoa', 'Via kovi vikomi', 'Yurako rako', 'Vira soaviyu', 'Viko viayua visoa', 'Komiso sorayua', 'Yurami soyu', '{"Ramiso": "Soakoyu soviyu virasomi"}', NULL, NULL, NULL, NULL, 'Yusomi yuko', 'Miravi mira yuaso', 61944);
INSERT INTO public."PaymentTransaction" VALUES ('9b863726-d7b6-57cb-b141-8d7acb38af5e', '2022-09-29 15:06:33.453', '2020-02-22 01:41:13', 'Mira mikoraso', 'Sorasora ramira yukovia', 'Virako yuvikoyu yuavi', 'Viyu viavira misora', 'Misoyu yusoa', 'Koyuviyu viayuvi', 'Yua yumiravi miavira', 'Vikovi yuvia yuviraso', 'Raviyumi komia viamia', 'Yumikora rayu sorakovi', 'Kovi misoami', 'Viyu koa', 'Viyu mikovi sovi', 'Miyu visora', 'Somiami ramia viso', 'Miyua miyumi', 'Kovisoyu koyu', 'Miami somi yuvisoyu', '{"Vikovi": "Soyu soavi miyu"}', NULL, NULL, NULL, NULL, 'Mia misoviyu', 'Rayuko yuso yuraviko', 26707);
INSERT INTO public."PaymentTransaction" VALUES ('f0ea8eea-1109-526c-99b8-108a7909a8dc', '2022-09-29 15:06:33.453', '2020-08-16 08:02:57', 'Yuraso viso', 'Miso sorakovi komi', 'Sovi via vira', 'Koa miko', 'Yuko yukovira', 'Soraso rasomiko raso', 'Miraso viko koviko', 'Komiko ravi vikoviko', 'Ramiko raso', 'Viyuako rasovi', 'Viyu miasoyu', 'Visorami viyu soyura', 'Rako yuako korasora', 'Soa ramiyuvi viayuko', 'Mikomiko miavi yurayu', 'Yuvi koaviyu somiyu', 'Raviyu miko rayumia', 'Yurayua koyurako', '{"Yukomiko": "Rayurako yumia"}', NULL, NULL, NULL, NULL, 'Miyuviko miako via', 'Yuko sovira', 27394);
INSERT INTO public."PaymentTransaction" VALUES ('0bd5fa3b-13e0-5294-ada5-8e1095f90da3', '2022-09-29 15:06:33.453', '2020-01-17 12:07:09', 'Soako visoviso', 'Koyuvia koravi yura', 'Yurako yuso komiso', 'Korami yukovira somisoa', 'Vikoyu visomiyu', 'Yumi somiko', 'Raso miyuko viso', 'Miravi yuayumi', 'Yukovi kora', 'Kora raviayu', 'Koakora yurayu yumi', 'Viraso ramiami yuaso', 'Ramia viyumi', 'Koviyu sorasovi soyu', 'Kovi soyua viko', 'Via visovi', 'Soviraso mira rasomi', 'Miko miyuko komi', '{"Rami": "Miso yumiyumi"}', NULL, NULL, NULL, NULL, 'Koamiso miakoa', 'Soayua yukovia sovi', 51758);
INSERT INTO public."PaymentTransaction" VALUES ('4aa05f23-7a65-5849-8941-a34a20a71127', '2022-09-29 15:06:33.453', '2020-01-21 01:03:58', 'Soyurami mira yukoyuko', 'Rakoa vira yumiayu', 'Viso soasoyu', 'Komiso ravikomi', 'Visoviso kovi', 'Viamiyu ravikoyu koyuko', 'Mira virayu', 'Viaso soyuviso yumi', 'Vikomi yua ramiravi', 'Somiyu yua', 'Yuravi yusoraso', 'Rasomia ramia yukomi', 'Viko koayuko', 'Visora mirasovi', 'Viaviyu korayu miyua', 'Yusovia soviyura', 'Somiyua viso koayu', 'Miyumi soyuviyu koyua', '{"Misoyu": "Yuvikoa komi misomia"}', NULL, NULL, NULL, NULL, 'Misomi koavi', 'Soyuvia koyura korayumi', 39122);
INSERT INTO public."PaymentTransaction" VALUES ('6ca488a5-303e-5dca-8b78-b9541f7ad716', '2022-09-29 15:06:33.453', '2020-09-09 20:50:12', 'Miravia mikoyumi rami', 'Yusoviko misoa', 'Rayumiko soyu yukoako', 'Viayuko koa', 'Soyusomi misomi', 'Komiami kovisovi', 'Vikoayu viso', 'Miyuko soavi rasomiko', 'Mikoako mira viraso', 'Yumi kovikoa soyu', 'Yuko viyuvia misorayu', 'Yuvi yumiso', 'Ramia soviyuso rako', 'Koyuso miko koraso', 'Rayukoa viyura soravia', 'Mia miyumiko yuaso', 'Raviraso kovira ramia', 'Ravikora viko', '{"Visorako": "Ravira via miyumira"}', NULL, NULL, NULL, NULL, 'Yuviako rayukovi', 'Yuko miaviso', 63603);
INSERT INTO public."PaymentTransaction" VALUES ('5448fd68-cfaf-5730-b92d-b0f7f1a4fbad', '2022-09-29 15:06:33.453', '2020-02-10 13:07:41', 'Miko yusomi', 'Somira yua rayu', 'Miraso yuvi', 'Viyukoyu miko yumikoa', 'Viyuaso vira rakomi', 'Miso mikovi koyu', 'Visorako rayu', 'Soyumi ravi', 'Yumiko kovi rakomiyu', 'Koviso mira', 'Vikoa yurasora rami', 'Somiyura viyua', 'Mirako yurakomi mirami', 'Yumiso mirakoa', 'Ravikora miyumi soyua', 'Mia misoyu', 'Kora koviso ramisovi', 'Miyu yuviso koa', '{"Vikoami": "Koravia miayu"}', NULL, NULL, NULL, NULL, 'Miako visoviso', 'Yuviko mirasora yumi', 28029);
INSERT INTO public."PaymentTransaction" VALUES ('159d9889-a80a-5a66-a4e1-1f6f9f5f2ed3', '2022-09-29 15:06:33.453', '2020-12-16 23:37:28', 'Mira yukorako miyu', 'Somiko soyua', 'Misoviyu soaso rayuviko', 'Soraso komiraso yuasoa', 'Koami somiyu', 'Viyuso miyuayu', 'Mikora yuvi viyuko', 'Vikoa yuasomi yuraviso', 'Soa soyu yuvira', 'Raviami somia', 'Yuaviyu rayuvi', 'Soa somi', 'Soyuko kovikoa miraso', 'Komikoyu viasoa', 'Yuso komiyura rasoa', 'Soaso miyu', 'Koyua miso rakoyu', 'Mirayuko kovi', '{"Kovi": "Rayura via ravi"}', NULL, NULL, NULL, NULL, 'Somia kovi', 'Yuasovi komikovi viso', 60719);
INSERT INTO public."PaymentTransaction" VALUES ('8a899908-6e60-5f2c-9510-cef5ac827fd5', '2022-09-29 15:06:33.453', '2020-03-27 02:56:30', 'Yurako viaso', 'Somiyu miyusoyu rayuko', 'Rayuviyu misovi', 'Koaso yuviyu', 'Miko somikomi yukora', 'Viavi mirasora', 'Rakoa viyumi somi', 'Koa virakovi koviko', 'Kovira yuakoyu', 'Sovia komi komira', 'Soyura komia', 'Miyu mirayu yuvi', 'Rami virako koviako', 'Koyuviko visomi', 'Yusoyuso viraso kovi', 'Viko yuramiko misoa', 'Mia rayu rasoyu', 'Koyuso soyu ramiyu', '{"Rami": "Miyuko ramikoa"}', NULL, NULL, NULL, NULL, 'Virami sovia', 'Vikoyu sora', 19342);
INSERT INTO public."PaymentTransaction" VALUES ('48e682bb-80b8-5e28-b210-ca820edcb3db', '2022-09-29 15:06:33.453', '2020-11-11 22:17:38', 'Misomi rayukora miyukoa', 'Komi raviso koyua', 'Mikoyu koyumia ravikovi', 'Koviso rayu', 'Koayu yumira', 'Viko koyuvira virayu', 'Visoyu komi', 'Sora mikoyu', 'Mirayu rako', 'Soramia kora', 'Koyu yuravi soyu', 'Yukomia rasoyu', 'Koviako rayua', 'Via raso yukomi', 'Ramisoyu rako soa', 'Viyu komiavi', 'Soavia sovirako rasovi', 'Yuravi koyua', '{"Mia": "Virayu viso virakoyu"}', NULL, NULL, NULL, NULL, 'Mikoami via kora', 'Sorayu sovisomi somia', 22707);
INSERT INTO public."PaymentTransaction" VALUES ('ee1991d9-8c03-5cdb-8f0f-c003966b9192', '2022-09-29 15:06:33.453', '2020-11-11 11:02:16', 'Ramiyumi yuamiko', 'Miko somiaso viyua', 'Viyura yukoyuko', 'Yusoavi yura', 'Soviami rayu', 'Yusoa rakomi mia', 'Kovira komi via', 'Yuvisomi yuaviyu yura', 'Miko kovia yuvikomi', 'Miko soaviso miayu', 'Rakomi komi koyuviso', 'Mikoami yusomi', 'Kovi visoako koyu', 'Komikomi raso', 'Soyu somia ramira', 'Soavia virakovi', 'Korakoyu koyu', 'Kovi raviami viyuko', '{"Rakovia": "Viso sorayua vikomira"}', NULL, NULL, NULL, NULL, 'Yuso yusomira', 'Rayura viasora soa', 52105);
INSERT INTO public."PaymentTransaction" VALUES ('67c106e1-22d8-5ab8-aec6-1ceef28a5c7a', '2022-09-29 15:06:33.453', '2020-03-03 02:38:10', 'Rami viraso', 'Koyumi koaso', 'Somirayu soravi', 'Viso viyusora yuko', 'Sovikoa vira', 'Virami kovi koyurami', 'Soyusoyu yumira viso', 'Miravira yumira soavi', 'Yukomi yua', 'Viayu vira visomia', 'Soaso rako', 'Mira mia', 'Rami yukoravi', 'Raviyua visoyu raviyuso', 'Viyu yusora', 'Visomi korasomi mikomi', 'Misora koyu', 'Miyuko miyu', '{"Yuko": "Yua viso kovia"}', NULL, NULL, NULL, NULL, 'Rako mia', 'Yua koyu', 12392);
INSERT INTO public."PaymentTransaction" VALUES ('a990edf9-702d-59c0-9cd6-b15179cb4ad2', '2022-09-29 15:06:33.453', '2020-09-21 20:56:48', 'Miko mikovi', 'Yuako mikoviko viko', 'Kovi ramiravi', 'Soa kovi viako', 'Soraso yuayu', 'Yuso viavia', 'Korami koa', 'Koa raviko yuko', 'Raviko ravi', 'Koamia miso', 'Korayu raso', 'Yumiyu kovi', 'Misovi komi', 'Rami yurayua soyumi', 'Somi komiami', 'Viko komiako yukomira', 'Mira mikomiso', 'Kora mirakoyu yurako', '{"Rayumi": "Rayuvi komikomi soramia"}', NULL, NULL, NULL, NULL, 'Viako viso', 'Yusovi via', 4670);
INSERT INTO public."PaymentTransaction" VALUES ('ef2d102b-c2c2-52a1-af64-97d75c8f60d0', '2022-09-29 15:06:33.453', '2020-12-16 11:34:48', 'Koyuviyu yuso vikomia', 'Vikoavi ramikovi komi', 'Soa mira', 'Rami yuraviyu ravira', 'Koasovi raso soako', 'Yukora rayu viyuavi', 'Yumiavi somiraso yumi', 'Soviso kovi', 'Kovia yuso', 'Soyu miaviso viyuviso', 'Yuasomi koaso yumi', 'Komi visoyuvi', 'Viavira viyu rasoa', 'Yukoa koakomi yuso', 'Rako yusomiyu', 'Raviso ramiaso yuso', 'Soamiyu rasomi miyusovi', 'Vikomi yuaso sovi', '{"Soami": "Rakovi miyu mikomiyu"}', NULL, NULL, NULL, NULL, 'Soamiso koyuko', 'Korako miaviko viravi', 30402);
INSERT INTO public."PaymentTransaction" VALUES ('1e011518-5d86-5e92-936d-b05babe25622', '2022-09-29 15:06:33.453', '2020-07-03 18:57:32', 'Somiyu yukoako', 'Vikoyuso koyuaso', 'Koyu yukomira', 'Rako soravi', 'Yuasomi soako yumisora', 'Rasoyu mira rasoyu', 'Soyumi miso yua', 'Yuvikoa yumia rakoyuko', 'Ravi somia', 'Raso koayua', 'Miso ramirako', 'Koyumi miyukoa', 'Raviso koyukomi rami', 'Virakovi koyuko sovikoyu', 'Soakora viko', 'Yuko miramiko miamia', 'Soayumi viso', 'Yukoako miyu kovia', '{"Vira": "Viko ravira rasoyuvi"}', NULL, NULL, NULL, NULL, 'Koayuvi yuvirami', 'Soyu via', 37502);
INSERT INTO public."PaymentTransaction" VALUES ('d0164f0e-65e3-5e42-bb7e-cfaa784550d0', '2022-09-29 15:06:33.453', '2020-04-04 15:29:30', 'Viayu mira miyua', 'Miyu mia', 'Vikomi mirayuko', 'Yumiako koa soyuso', 'Miramiso vira rakorako', 'Koyuvi rami', 'Miyukora koraso', 'Ramia sovi vikomi', 'Soyuravi koyuko yusoa', 'Miyuko koyumiso misovi', 'Raviko kovi viyura', 'Yusoyumi mikomi viramira', 'Komira virasomi', 'Vikoraso rako yusomi', 'Soayura kovi', 'Koa vira mirayuso', 'Mia viayu sorako', 'Soyura vira', '{"Sovikoyu": "Visoyuvi yusoa yuko"}', NULL, NULL, NULL, NULL, 'Vira komikora', 'Ravi komikora', 31032);
INSERT INTO public."PaymentTransaction" VALUES ('07d04e93-4be8-51df-b68c-196ee77b3de1', '2022-09-29 15:06:33.453', '2020-05-01 04:10:04', 'Koyuviso yurami', 'Komikoyu sora', 'Soravia yua', 'Raviso soa', 'Virasoyu koravia rasovi', 'Soako mirami', 'Yukoyu via miakoa', 'Mia mikovira', 'Yuviravi via soviyua', 'Kora soa ramiko', 'Sora mikovi yua', 'Yukoyu mia miko', 'Visorako soyuvia sora', 'Raso viako', 'Yukorayu koviami yumi', 'Koviyu raso miasomi', 'Viasoyu rakomiso koasora', 'Rayu sovira soyua', '{"Viso": "Kovi rayura"}', NULL, NULL, NULL, NULL, 'Yurayu viyusomi yura', 'Miyua virako somisovi', 25087);
INSERT INTO public."PaymentTransaction" VALUES ('37c79d3b-cec6-56f1-b011-a90188aeffa4', '2022-09-29 15:06:33.453', '2020-10-10 09:19:32', 'Soamira ravia', 'Yua misomi mikoviko', 'Sorakora rayu yumiaso', 'Sora yuayu rayuso', 'Rasoavi soviyu', 'Yuravira yura', 'Miyuvi misoyuso', 'Viako vikomiyu viyu', 'Ravi koramira', 'Virayu ramisoyu', 'Rasoyuvi rakomi', 'Viyukoa sora', 'Yuso soviaso', 'Viso visovira yumi', 'Rami raviyuko', 'Soyumia soa koayuko', 'Miso somiraso', 'Miako rakovira', '{"Yukomiso": "Koyu koaviyu rako"}', NULL, NULL, NULL, NULL, 'Ravi korayua', 'Viyu yuviso soyua', 30581);
INSERT INTO public."PaymentTransaction" VALUES ('fdcc8556-828e-5b0e-8255-a378de629da1', '2022-09-29 15:06:33.453', '2020-07-23 06:45:04', 'Korako vikoviso ravira', 'Yusoa koyu', 'Miyumi mira', 'Soyumi komi', 'Mikora soa', 'Visoyu somi', 'Soramiso miyumi', 'Somiravi soakomi koviko', 'Ramira yusorami mirayu', 'Sorasoyu viyu', 'Vikoaso virasomi', 'Viyuko rako', 'Koyu sorakoyu', 'Yuviko via', 'Yusoraso rayua', 'Virami ravi', 'Yumiaso somiyu', 'Misomi ramiyuso koyu', '{"Sorayu": "Visomi soviyuvi viyuko"}', NULL, NULL, NULL, NULL, 'Visomi soayuko mira', 'Rakoyu sora viyusoyu', 52202);
INSERT INTO public."PaymentTransaction" VALUES ('9873b766-911e-55ae-b692-85f011db8eb5', '2022-09-29 15:06:33.453', '2020-08-16 19:58:11', 'Yusomiko via miso', 'Yua misoyuvi rayura', 'Mirakovi raso yumiso', 'Miraviyu viayu', 'Vikoyu komi', 'Miso ramiyu rako', 'Komi soraviso viayuso', 'Rakomi soramiko', 'Sovi yuviami yuso', 'Rasoravi ravira', 'Yuko vikorako komi', 'Rakomiyu miavi', 'Yumi rakora', 'Viyuso koyua somisoyu', 'Miyumi soyua', 'Vira koyura', 'Mira ramikovi rako', 'Raso yurami', '{"Rayumi": "Soyu yuavia koa"}', NULL, NULL, NULL, NULL, 'Sorami somi miyumiko', 'Sovirami virayu', 9179);
INSERT INTO public."PaymentTransaction" VALUES ('f720cd51-c99d-5b0e-8156-a247d6858f91', '2022-09-29 15:06:33.453', '2020-04-12 03:13:27', 'Miso visoraso', 'Viyu korayu koyusoa', 'Soviko rakoavi', 'Rako visoayu ramiraso', 'Sora raviso', 'Soasoa somi ramiso', 'Yumi viyusomi', 'Miyu miaso somikomi', 'Yumi rasomira', 'Rayumira raviko yumia', 'Soviaso ramiyuko viyuavi', 'Yuvikora koviko', 'Soavira koyukora', 'Kovisomi rayuvi yumi', 'Mira komia', 'Sovi misorako', 'Koyuraso visora', 'Miko ramiso viko', '{"Yurayura": "Virayura rayuso"}', NULL, NULL, NULL, NULL, 'Somi misoyu', 'Koyuso rayu miyuso', 29874);
INSERT INTO public."PaymentTransaction" VALUES ('afc34713-384a-5d17-b97a-629ba3927e4b', '2022-09-29 15:06:33.453', '2020-07-03 19:10:29', 'Sorayu miraviyu miyu', 'Soami rami', 'Vikoraso viso sovisovi', 'Ramia kovi', 'Yuami yukoami rayuvi', 'Ramia yuvi', 'Raviko misoa', 'Soyumira somira yukoyua', 'Miamira kovi', 'Misoyura sora', 'Yuso visoa', 'Raviko miaso', 'Rayua via', 'Vira yuako', 'Komiayu yuvi', 'Mikorayu yua koyusoyu', 'Miako soa', 'Somi ramira yuvi', '{"Mirayu": "Miyuvi yusomiso"}', NULL, NULL, NULL, NULL, 'Virayuso soviayu somisora', 'Misovi mia', 27578);
INSERT INTO public."PaymentTransaction" VALUES ('4f0fa00a-31de-549f-843d-dce546fc6676', '2022-09-29 15:06:33.453', '2020-04-24 03:28:41', 'Vikoa vikomiko yusovi', 'Virami soayu', 'Yuko soa', 'Komiaso kovikovi', 'Soviraso rayu miyuso', 'Virayumi miyuayu rako', 'Viyuvira via rami', 'Sovia soviko', 'Yuvi somia', 'Koyu soviso', 'Rako mia', 'Soviso rako viyuso', 'Yukoyu miko', 'Miasora viyu yurakomi', 'Rasoayu yuavi', 'Rayumi yuso soaviso', 'Yumiyumi viako raso', 'Korayura sorayu rayukoa', '{"Soayuko": "Miko ramira miso"}', NULL, NULL, NULL, NULL, 'Mirayura viko', 'Yumisovi rakomia', 34567);
INSERT INTO public."PaymentTransaction" VALUES ('98e9dc72-d0c2-5901-b1d5-c1026cb37986', '2022-09-29 15:06:33.453', '2020-04-04 03:42:06', 'Rayu soakomi', 'Ramiavi yurayu', 'Ravisomi visoa', 'Rasoyuso soyukoa', 'Rako viyuayu', 'Rako koviko yurayuko', 'Somikoyu koa', 'Kora vikomi viko', 'Somi miyusovi rakovia', 'Komira misoa yukoyuvi', 'Yuso rasomiso yuravi', 'Koyua rayumira visomi', 'Yusoviko soyu ramira', 'Miraso misoyua', 'Miavi soviyua mikoyuso', 'Mikoviso yusoa', 'Vira vikoako', 'Koami somi', '{"Viso": "Miyumi yuso koviako"}', NULL, NULL, NULL, NULL, 'Yurakora vikoyu', 'Viyumiko viyuvi', 24442);
INSERT INTO public."PaymentTransaction" VALUES ('234e0cd6-dc42-595c-a2de-6bdb2cb3f832', '2022-09-29 15:06:33.453', '2020-01-17 12:15:25', 'Kovirami mia', 'Koyukoyu virami', 'Ramiaso visovi', 'Rakomi viyurayu koami', 'Koyu kovira', 'Viyumi koyukomi yumi', 'Viyua yuvikoa koa', 'Komirami komiso', 'Raviko soa', 'Koviko somi', 'Koavi misomi yuayu', 'Yukora mira', 'Soaviyu komiyu yuami', 'Koviayu viami', 'Yurami rasoaso', 'Ravikoa komiko', 'Kovikomi yua', 'Somi koa ravi', '{"Yurako": "Rayuviyu visoavi miso"}', NULL, NULL, NULL, NULL, 'Soravi rako ramiraso', 'Raviko yusorami misoa', 36118);
INSERT INTO public."PaymentTransaction" VALUES ('dca184f6-9302-56d3-964a-2907a9491a72', '2022-09-29 15:06:33.453', '2020-02-22 13:59:02', 'Komiraso vikoyu virasoa', 'Yurako mirayua virasoyu', 'Sorami via', 'Sovirako raviyu', 'Yukomiko somi', 'Mikomia soyumi', 'Somi koyuso', 'Yuako visomi', 'Soaso virayu soviayu', 'Koako somikoyu vikora', 'Rayu miasora miyu', 'Ravikovi rako soa', 'Viyumi yuvi mikoyua', 'Soayua via viyuso', 'Yumiko vikoraso koamiso', 'Soravi somi', 'Ravisomi via mikorako', 'Rakomia visora soviako', '{"Sorayu": "Ravi ravisora komi"}', NULL, NULL, NULL, NULL, 'Raviko viami miavia', 'Sora miamiko', 58704);
INSERT INTO public."PaymentTransaction" VALUES ('7fc5275b-6c6b-5451-940b-6b2e77801f75', '2022-09-29 15:06:33.453', '2020-10-22 22:12:52', 'Yuayuvi raso rasovia', 'Rasoyu raso yuviyu', 'Miso miamiko', 'Rayura sovi', 'Miyu visoyumi koviyu', 'Koyuso mikomiso yuayura', 'Soaso rako virako', 'Miayu miyura viyumiyu', 'Rako yua', 'Rako rasorako virami', 'Komi yukomi', 'Vira yumisoyu', 'Kovi soyuviyu', 'Koyu rasorayu', 'Soamiyu yumikoyu yukomi', 'Rayuavi yukomi viako', 'Viyuso miyua', 'Koyurami koviso', '{"Yuvikora": "Koyuko soako koayumi"}', NULL, NULL, NULL, NULL, 'Miavi rayukoa', 'Korami rami', 65369);
INSERT INTO public."PaymentTransaction" VALUES ('3f89dee5-4105-5c86-b11f-0bc54f555683', '2022-09-29 15:06:33.453', '2020-12-08 11:29:53', 'Viaso vikovia miaso', 'Kovikora sovira', 'Yukovi koa yurayu', 'Rayu mirakovi', 'Komiyura yuako viko', 'Yumi koviaso', 'Miramia yua soviyu', 'Sora via sovisovi', 'Koasoa koayuso mirakoyu', 'Sovi viyurayu vikora', 'Kovi viayuko', 'Miso korasora viavi', 'Viyuko miayu yuvi', 'Koviko rayua', 'Raso ramirako', 'Miavi soamia yuso', 'Viko yumiso', 'Vikoa rasoayu mirako', '{"Ramikoyu": "Komi miyusomi"}', NULL, NULL, NULL, NULL, 'Yuviyuvi mia', 'Virami koavi rami', 20749);
INSERT INTO public."PaymentTransaction" VALUES ('93ccbe9d-389c-5ba2-8833-f64190305c74', '2022-09-29 15:06:33.453', '2020-01-17 00:50:43', 'Somiavi sovi mikoaso', 'Koa komiso koyumiko', 'Somirayu yura', 'Viavira miko mia', 'Miasora miyu', 'Vikoyu ramiayu sorakovi', 'Yukoviyu ravi', 'Ravi viaso vikovi', 'Raviyu yuvia', 'Viso rasomi', 'Sovi somiyu', 'Ravirako yumiko yua', 'Visora raviayu yurami', 'Viaviso yuramiyu', 'Rasoyuvi miko virayua', 'Ravisovi mikomi yuasovi', 'Yuso yusomi komi', 'Soviko misorami', '{"Rayu": "Viyuko rako"}', NULL, NULL, NULL, NULL, 'Komisoa miko', 'Miyu vikoami viraso', 29570);
INSERT INTO public."PaymentTransaction" VALUES ('5770eafc-7ea6-5ac1-aedc-00cd4a4a49fc', '2022-09-29 15:06:33.453', '2020-05-01 16:14:16', 'Yumiso miami rayurami', 'Misovi miso', 'Koyurayu misovi', 'Yuavi viyumia', 'Misoyuvi misoa', 'Ramiravi somi', 'Miamiso vikoyuso ramikoa', 'Yuvi koyuso', 'Soa ravisoyu korako', 'Rayu vikomia', 'Misomi miayu mikovi', 'Miso miyuvia yukoraso', 'Mira rasoviyu rami', 'Kovikoyu rayu miramiso', 'Ramiko miyu koako', 'Miayu komiko', 'Viko mikorami yuso', 'Rayu vikomia', '{"Komi": "Via ramiraso"}', NULL, NULL, NULL, NULL, 'Somiyu yuko', 'Mira miayu viramia', 33239);
INSERT INTO public."PaymentTransaction" VALUES ('8b3c5a20-7087-5f7d-99ab-2fd63e6c2088', '2022-09-29 15:06:33.453', '2020-04-16 03:41:22', 'Korayua viko rasoyumi', 'Soakoyu rakoyumi', 'Yuaso vikoyu sovi', 'Yukoako viyuravi', 'Sorayuvi rako', 'Kovirayu misoyu', 'Yuko soviyuvi viko', 'Yusoayu kovi mikoyuso', 'Komi yukovira', 'Vikora miyuvira miko', 'Koyuvira mikovia sorakora', 'Sorakoa misomi', 'Viso ramiyura', 'Somiyu yumikoyu', 'Visoviso somi', 'Virami yura soravi', 'Viko yukomi', 'Miko mirami visorako', '{"Sorami": "Yumi yumiravi"}', NULL, NULL, NULL, NULL, 'Komiami yura', 'Yuako yura', 19329);
INSERT INTO public."PaymentTransaction" VALUES ('b9bedb4d-a32c-560a-ba2c-792d74f2637f', '2022-09-29 15:06:33.453', '2020-11-07 10:46:20', 'Soavi yukomi soami', 'Korami somia miyuvi', 'Mia mikoako viakoa', 'Yusoayu ravi', 'Rayuko yukoviko rakora', 'Miyu somiraso viraso', 'Kora via', 'Komi somiyuso', 'Sorayu via soakoa', 'Yuako soyu virami', 'Rakoyu yukoa', 'Koyura vira visoviko', 'Rako visoyu', 'Yurakoyu raviavi yuko', 'Mira soraso', 'Yusomi yukoyura viraso', 'Mira miravi mira', 'Viso soako yua', '{"Koavi": "Ramiyuso rayuvi"}', NULL, NULL, NULL, NULL, 'Yusoako yua miasomi', 'Rasovia korayura rayu', 2639);
INSERT INTO public."PaymentTransaction" VALUES ('6dc36a76-a078-5d3b-899c-46cbaa12042f', '2022-09-29 15:06:33.453', '2020-11-19 11:03:40', 'Vikora rasoa miso', 'Viyura ramiraso somiso', 'Rayu rasorayu', 'Viasora yusoa', 'Sora soviravi yuayu', 'Yumikoa miyura viso', 'Kora viyuso koako', 'Misora komi ramira', 'Soaso koa viso', 'Rako somisoa miyu', 'Raviyu koyu koyura', 'Yuako somi', 'Yuko somira', 'Rayuviso miavi', 'Rasoraso kovi', 'Vikoyu vira miyuayu', 'Miamiko mirami', 'Miyu yukomi', '{"Yumi": "Soyu yusoaso mirako"}', NULL, NULL, NULL, NULL, 'Yukoyu miamira yura', 'Rasomi yua', 27162);
INSERT INTO public."PaymentTransaction" VALUES ('f5626bc0-5bf3-55d6-b2ce-a6affb2c791c', '2022-09-29 15:06:33.453', '2020-03-03 02:31:38', 'Koyumiko yua', 'Komisovi rakoavi', 'Mirayuko yua', 'Kora sorako', 'Via yuami', 'Rako koviavi rami', 'Yusomi rako', 'Koakovi koyu ramiko', 'Ramiko miami', 'Rayuso koyua rayuso', 'Yukora yuvi', 'Ravi vikoyumi', 'Miyua koviso', 'Miso rakomiyu', 'Koyumia viko yuviyuvi', 'Soyuko viami', 'Kovi somiso sovi', 'Soa misoayu virami', '{"Yuso": "Rayuso viyu koa"}', NULL, NULL, NULL, NULL, 'Yura mikoyu', 'Miso koyumi', 29460);
INSERT INTO public."PaymentTransaction" VALUES ('64b58bac-6a4c-5cf8-a286-c731bdb355c4', '2022-09-29 15:06:33.453', '2020-08-04 19:12:04', 'Sora raviako', 'Koviaso ravia yumira', 'Mikora miyu viaso', 'Miso yuviyuso', 'Raso misovi', 'Soviko miso', 'Soviso somirami', 'Koa misorayu misora', 'Mikoyu yuso ramiko', 'Viso soako rakoyu', 'Yukovi soa miayu', 'Ramiravi viako', 'Yuviso rakomia', 'Ravi virayu', 'Miyuvi miraviyu', 'Yumia yumirayu', 'Yuko korayuvi yuso', 'Visovia miyu viramiko', '{"Rakoravi": "Sovi soraso"}', NULL, NULL, NULL, NULL, 'Sovi yuvisoyu', 'Soyuraso koviyua', 14316);
INSERT INTO public."PaymentTransaction" VALUES ('8bd49d9e-30b9-544f-a9ba-396cc9129fd0', '2022-09-29 15:06:33.453', '2020-10-26 09:40:39', 'Mirayura kovira', 'Komiayu miyuko raso', 'Koviko soyu', 'Viakoyu visomi yusovira', 'Ravirami ramia miso', 'Misovia sorayumi miyu', 'Viravia kovi', 'Soako mia', 'Rasoako koayu viko', 'Vikoavi yumi mikomiko', 'Yuviyu sora', 'Koyura yukomira', 'Rami koasoa', 'Rasovi sovi miyumi', 'Yuasoa rakoyua', 'Somiko koyu koa', 'Yukomia miraso', 'Rasora rami', '{"Yumi": "Komisoa koviso yukomiko"}', NULL, NULL, NULL, NULL, 'Koyumi kovikovi', 'Yurasoa yuravi', 4266);
INSERT INTO public."PaymentTransaction" VALUES ('0bd8e80a-1f96-5e18-ba12-d22dafa71fa8', '2022-09-29 15:06:33.453', '2020-01-21 00:53:42', 'Soa yumi', 'Rami yurayuko', 'Somi raviso', 'Raso korakora viyura', 'Mikoyuko miyusoa', 'Soviyua ramiko somi', 'Sovi miamiyu', 'Yuso sovira komikoyu', 'Misoyua sora miyuavi', 'Ravisovi koyumi mikoviso', 'Viravira mikoa koyu', 'Kora sovirako miasoyu', 'Viayura soyuko', 'Koramira yusovi raviami', 'Yukoavi koyu soavia', 'Via rako', 'Viko yuviso vikoviso', 'Yusomi rakomira yukora', '{"Vikomi": "Soa miyu"}', NULL, NULL, NULL, NULL, 'Yumi soyukoa', 'Ramiyu mira yuayu', 26251);
INSERT INTO public."PaymentTransaction" VALUES ('5f808cff-44cd-540c-b822-08f9b0735486', '2022-09-29 15:06:33.453', '2020-01-09 12:12:22', 'Koyurayu yusoako sovira', 'Yumiako mirako', 'Koavia raso koviso', 'Vira virasovi sorayua', 'Rayuvi yuako', 'Yumiayu rako', 'Soyusomi mia koviso', 'Koviyumi yua somi', 'Raviako misovi sora', 'Miyua koyurako mia', 'Viso koyuraso', 'Ravi mikoviyu', 'Koyu ramiso', 'Yura mirami', 'Kora soaso', 'Ravi soviravi komiyu', 'Soayumi miyu koa', 'Virayu rayu sorakoyu', '{"Rayu": "Yuaso koraso mira"}', NULL, NULL, NULL, NULL, 'Miraso mikoyuvi', 'Koyu miyurako', 32731);
INSERT INTO public."PaymentTransaction" VALUES ('090468e1-81fa-5047-a038-88129f30626b', '2022-09-29 15:06:33.453', '2020-05-09 04:56:00', 'Korako yuvi mirami', 'Mikoyu yuko', 'Soa yumirami mikoavi', 'Soyu soaso', 'Korako soraviyu', 'Yurayuvi viyu sovikomi', 'Yuko ramira somi', 'Raso viyuso', 'Vikovi somikovi misomi', 'Komisovi koviko', 'Yuravi soasovi', 'Miko komiyuko', 'Rayuavi koviyu vira', 'Mia yurami raso', 'Kovi yukomi vira', 'Somikora viko koyusomi', 'Rayu rakoravi', 'Koasora kovi yuvikoyu', '{"Soa": "Misomi koviami"}', NULL, NULL, NULL, NULL, 'Soviso yuamiso yua', 'Sora via miyu', 52688);
INSERT INTO public."PaymentTransaction" VALUES ('6c7a09b9-4a7a-51c0-9937-89637f2fad70', '2022-09-29 15:06:33.453', '2020-06-18 05:32:55', 'Soavi viayuko ravirayu', 'Soa viko', 'Yuayu soyu', 'Mirako viayura', 'Soviyumi viayu rakoayu', 'Mikomi sora sorakovi', 'Ramiraso mikora soami', 'Viamiyu ramia', 'Ramisovi somi soako', 'Mira yurayura ravi', 'Mikoavi somisora', 'Vikora yumiami', 'Mikoviko soa viyuvi', 'Yukoayu rasoyuko komi', 'Viramiso soa miko', 'Mikovia komiko', 'Rasoa rasoviyu', 'Kovi rayusovi yua', '{"Viyumi": "Miyua rami"}', NULL, NULL, NULL, NULL, 'Rami rakoaso', 'Miyura mikoako', 15420);
INSERT INTO public."PaymentTransaction" VALUES ('0e43dacd-8af2-5f51-9219-cf2628a9748d', '2022-09-29 15:06:33.453', '2020-08-16 08:06:41', 'Rami soayu', 'Viyuaso komiko', 'Yumi virasoyu', 'Viso yuvira yuvi', 'Vikovi somi', 'Yuviso yurasovi', 'Visorami vikomi', 'Soyu koyukoa', 'Rami kovia miso', 'Ramiyuko vikoa', 'Soyu koyuviko yura', 'Miyuviso miavi rayuavi', 'Komiavi somirayu', 'Yumiyu mikorayu', 'Sorasomi koyu yuaviyu', 'Yuso virakovi', 'Misovi mia miami', 'Soyu soamiyu kovisora', '{"Yuviyu": "Rayusoa viko"}', NULL, NULL, NULL, NULL, 'Visoyuko soa raviyu', 'Rayurako rakoa', 52365);
INSERT INTO public."PaymentTransaction" VALUES ('c059d8d1-5a1b-540b-86e0-dceb5e5636c4', '2022-09-29 15:06:33.453', '2020-01-13 00:27:43', 'Yuravi soa', 'Yura miyurami rami', 'Koramiko yusovi raso', 'Sorayu mia sovira', 'Viravira rasomi misoa', 'Rasovi rasoami', 'Mikovi raso', 'Yura viavi', 'Miayu somira visoa', 'Raviko soa', 'Yuavi yumira yukoa', 'Yumiyu miaso yuvi', 'Soyu virayuso koviyu', 'Yuayu miko', 'Rakovi komiravi miyuvi', 'Ramiyuso yuravi viko', 'Koamira rami miramiko', 'Visoayu yuviso soyurami', '{"Korakoyu": "Yuakomi rayu"}', NULL, NULL, NULL, NULL, 'Viyu vikoviyu yua', 'Ramiko miyurami komia', 40577);
INSERT INTO public."PaymentTransaction" VALUES ('038c2509-2e01-5675-8221-e47c2ee6f5da', '2022-09-29 15:06:33.453', '2020-03-07 14:05:36', 'Kora soami', 'Komisora komi rayuko', 'Rasora koraviko', 'Viako koyu mirami', 'Ramia yuravi rayu', 'Viamia raviyuko miako', 'Mikomiso vikoyua koyu', 'Rasoyumi yusoaso raviyumi', 'Miyu koyuviso', 'Rayuviyu vira visoaso', 'Rakovira virakoa yumi', 'Rakora yuvi', 'Sovi koa viavi', 'Somi virayu', 'Mia koyusomi vira', 'Yusomiko vikoyu koa', 'Soyuvira koami', 'Soyu miyuvi', '{"Rasoavi": "Miakovi viko yuramiko"}', NULL, NULL, NULL, NULL, 'Visoavi mikomi rakoa', 'Miyu somiko somi', 46770);
INSERT INTO public."PaymentTransaction" VALUES ('0483c702-b3d9-56b1-951c-af645d6b68ff', '2022-09-29 15:06:33.453', '2020-06-10 17:45:56', 'Misora ravia', 'Viayumi yuvikovi mikoa', 'Viko rayuso', 'Vikoyu viramiko rami', 'Rakomi koaviyu', 'Koako korami viaviko', 'Misomiko mira viyura', 'Koyusora yuvira komi', 'Miso komisoa soyua', 'Soaviyu sovira yumi', 'Yumi sovisora somira', 'Rasoyu via raviaso', 'Yuko rakoyura', 'Koyu mia rasovia', 'Somira mira koasovi', 'Viaso yuviko', 'Sovia koviako rakoyu', 'Sovira ramisomi', '{"Soramia": "Soa yuayuso"}', NULL, NULL, NULL, NULL, 'Rayu yuayuvi vira', 'Miso visomiyu yuso', 57011);
INSERT INTO public."PaymentTransaction" VALUES ('7b734528-082e-5c19-bdab-56ac1d5c275b', '2022-09-29 15:06:33.453', '2020-09-21 21:00:11', 'Yua koavi raviso', 'Miasovi sorami', 'Yumi viramiso', 'Yua miko koyura', 'Koyua vira', 'Raviko raso', 'Rakora kovisoyu mikora', 'Rasomi kovikoa soavi', 'Vikomiyu ravi', 'Viyusoa sorayumi', 'Vikomiyu kora', 'Rakoayu koako sovikoa', 'Mira viyurako', 'Ravia yura', 'Kora komisomi', 'Raviraso rasoa', 'Rayu koyuvi', 'Korayuso soa', '{"Ramikoa": "Yukorami yuavia komi"}', NULL, NULL, NULL, NULL, 'Ravi mia mikoraso', 'Vikomi koayu miko', 28294);
INSERT INTO public."PaymentTransaction" VALUES ('bd4de743-d3db-5d6f-a00b-f7102d000423', '2022-09-29 15:06:33.453', '2020-12-20 11:46:59', 'Koraviyu koyura miko', 'Rasora rasoravi viasoyu', 'Yusora soa kovia', 'Miso mikoavi soa', 'Ramisoyu viso rayumi', 'Korayuko miyuko', 'Yumiyua mira yuamiyu', 'Kora yukoyura soyu', 'Soyu soa', 'Vikomiko sorayua soraviko', 'Vikoako mirakomi vira', 'Viaviso kovi', 'Yuvikoyu yumia', 'Misoyu korasomi soyuaso', 'Soayura rayu koviyu', 'Miyuaso komira', 'Miayumi yuako', 'Viyu rakomi', '{"Rayu": "Komiko koyu koakomi"}', NULL, NULL, NULL, NULL, 'Miako rayusomi yuviko', 'Visoyu raviako viyu', 29373);
INSERT INTO public."PaymentTransaction" VALUES ('f7a74e2b-b035-5672-ab34-d2e9e0799fc0', '2022-09-29 15:06:33.453', '2020-12-16 23:51:48', 'Ramiko ramisovi', 'Komi komirayu', 'Rako yurakora mirayu', 'Viso koraso mia', 'Miyuso viayuvi viso', 'Rakovi miko soraso', 'Yumiko ravi rakoa', 'Raso via soviko', 'Yuviravi kovi misovi', 'Miravi mikoami komirami', 'Miramira sora rakoa', 'Kora komisoyu via', 'Raso soyuvi miyusora', 'Yuko yuravia', 'Kovisora vikoyu', 'Visorayu rakoa vikoyuko', 'Mikoyu kovikomi kovi', 'Sorami yuramia', '{"Miso": "Vira viyumiso"}', NULL, NULL, NULL, NULL, 'Viravi ravi', 'Rakovira komiyu mia', 50998);
INSERT INTO public."PaymentTransaction" VALUES ('84cc1217-e792-5ed5-a36d-012b2941707f', '2022-09-29 15:06:33.453', '2020-02-22 01:14:59', 'Vikomi vira', 'Somira koyu', 'Yurako sora yua', 'Miyu sorasoyu', 'Sora yuviso', 'Somisomi ramira', 'Viakora viyu', 'Miavi yumiaso', 'Miako miyuako yumi', 'Soami vira', 'Vikomiko yuraso', 'Yuayuvi ramikoyu miaviso', 'Viayuso viami', 'Soyuso rasoako ravi', 'Raso virasomi', 'Vikomi miakora', 'Visomira kora', 'Misoako miko soayumi', '{"Sorami": "Kovi ramiraso"}', NULL, NULL, NULL, NULL, 'Soyu soako', 'Miavi miravi', 11093);
INSERT INTO public."PaymentTransaction" VALUES ('e1146e0f-0285-55f7-898a-361380caec5a', '2022-09-29 15:06:33.453', '2020-08-20 08:11:39', 'Mirasoyu miso', 'Koraso virayuko', 'Yumiko yura mirako', 'Komi ravira koayuso', 'Rako koaso via', 'Mirayumi mirako', 'Kovikomi viaviko', 'Yukorami via', 'Soamiyu viko', 'Miyu yumira yusoyua', 'Ravi soviraso', 'Raviso soviaso', 'Yuami sovi rayuayu', 'Koyuavi miaso sovi', 'Ramira sovikomi via', 'Misoravi rayu virayua', 'Koyu mikoyu ravi', 'Yuvia rakoaso koa', '{"Misoa": "Yumi koyuavi"}', NULL, NULL, NULL, NULL, 'Koa yukoyuso', 'Miyuvi ramisoa', 10876);
INSERT INTO public."PaymentTransaction" VALUES ('074bb76c-89e0-58e8-a045-d3fa57bb4238', '2022-09-29 15:06:33.453', '2020-06-14 17:29:06', 'Yuvi miraso', 'Vikoviyu sovi yumisomi', 'Soaviyu miravi viyukomi', 'Yusoa viraso', 'Koviko yumi', 'Yukoa via', 'Yurami soyuviso', 'Kovirayu viami yuko', 'Koaviso koyu yurasomi', 'Miayu rayu', 'Kovi somikoyu', 'Rasovi komi', 'Yusoa yusorayu yuko', 'Mira yuviko kora', 'Koa vikomira', 'Yusovi rasoyua yumi', 'Visoyu yuviyumi', 'Komi rakomiyu mikovi', '{"Yuamiko": "Yurayumi ravi kovikora"}', NULL, NULL, NULL, NULL, 'Yuamiko sora', 'Yukovia sora rayuvia', 43921);
INSERT INTO public."PaymentTransaction" VALUES ('8adc5172-a835-5079-898c-2f535f96936e', '2022-09-29 15:06:33.453', '2020-09-09 09:08:51', 'Koavi mikoami', 'Koakoa yukomiso yukomi', 'Koayu yumi', 'Viso koramira viyu', 'Yura rakovi misoyuso', 'Soramira vira rasoa', 'Yusoravi yumi', 'Yumirako sorayu', 'Rakomira miko soyura', 'Soa miyua', 'Yumiyuvi koa yumi', 'Ramiyura yukomi ravi', 'Mikorayu koa', 'Viso yusoyu', 'Komi virami kovi', 'Soavi via kovi', 'Vikorayu koa', 'Visoavi mikoyu yukorayu', '{"Komirayu": "Miami rami yukora"}', NULL, NULL, NULL, NULL, 'Misoayu koyurami', 'Miyu soyukomi miso', 56951);
INSERT INTO public."PaymentTransaction" VALUES ('3ddbc435-3d9d-513a-9f80-facf3d842e7a', '2022-09-29 15:06:33.453', '2020-05-21 04:38:08', 'Visoravi miyuko', 'Ramiami ramira yuvikoyu', 'Vikovi mirakomi', 'Viyu yurayu', 'Mira korayu', 'Rakoa mirakovi mikoyu', 'Mirako yumi miayu', 'Soyurako koyu', 'Misomiso yuamiso rayuko', 'Sorasovi viko koyuravi', 'Soa soyuviyu rayuso', 'Rami rasovi miso', 'Miayuso soa yukoa', 'Kovi koviravi', 'Soraso viko yuviso', 'Vira somiso soraviyu', 'Korayuko somiyu yuko', 'Soyu viyukora koviso', '{"Mira": "Viso miayuvi kovi"}', NULL, NULL, NULL, NULL, 'Yumira koa', 'Mikomi visovia soami', 5482);
INSERT INTO public."PaymentTransaction" VALUES ('5cf88405-9702-5838-aa7a-90a2eda6089a', '2022-09-29 15:06:33.453', '2020-08-20 19:51:01', 'Sora miraviso', 'Vikomiko yumiyu yumiyuso', 'Raviami mikoa', 'Koyu rasovira', 'Viavia ramisoa', 'Miso yuviko', 'Rasoa soavia yuvisoyu', 'Misoa ramiavi yusorami', 'Koyua vikomira sora', 'Koayumi soa komi', 'Somiso mikoraso', 'Yusoyu yuso viyura', 'Soviso yuvi soviyua', 'Viso viaviko korami', 'Yua kora korami', 'Somi rayurako', 'Raso sorayu miso', 'Yumisovi sovi miyukora', '{"Viko": "Rayu viyumia"}', NULL, NULL, NULL, NULL, 'Yumi viyuviyu', 'Rasovira miraso', 51622);
INSERT INTO public."PaymentTransaction" VALUES ('35d74183-8139-5fea-a4c3-9fd0a4f8b9c6', '2022-09-29 15:06:33.453', '2020-04-08 15:07:40', 'Yuvi soasora soraso', 'Rasoavi sovisomi koviko', 'Yuso yukora', 'Komi koravira', 'Miyura rami', 'Visoa somi', 'Soa rayu viyuviyu', 'Soaviyu yukorayu yumia', 'Yurakoyu soa miasoyu', 'Viyurako mia', 'Soyuraso yuraso', 'Yuraso miyu', 'Koayuvi yukorako', 'Sovia koyukomi yumiso', 'Via soaso', 'Sovi koyukora', 'Soyusoa rasomi', 'Yumia soa mikovi', '{"Vikoaso": "Mirayua rayusomi rami"}', NULL, NULL, NULL, NULL, 'Ramiaso soami virayuvi', 'Rasomiko soraso', 2709);
INSERT INTO public."PaymentTransaction" VALUES ('21235803-d56a-5549-ac0b-2049cd09f11b', '2022-09-29 15:06:33.453', '2020-03-23 03:03:05', 'Komikovi viyuso', 'Soyuaso soasoa koyu', 'Rayusora yuviyu yumi', 'Komi koa komi', 'Rasoyuko koyu somiako', 'Miyu yukomiso', 'Soyuvi somi virayu', 'Virayua visomiko', 'Kovisora komisoa sorayu', 'Komiso sovi', 'Raviako soviso', 'Vikoyu yuso rasora', 'Viyu soviyuko rasoa', 'Viravia viyura', 'Komi virako viako', 'Koakoyu mia miasovi', 'Mikomiko sora', 'Somiaso ravia misoako', '{"Koaviso": "Rako sorami"}', NULL, NULL, NULL, NULL, 'Viyuvi rasovia miyua', 'Virakoyu miyura', 3881);
INSERT INTO public."PaymentTransaction" VALUES ('e7b4f241-998a-571e-a219-d40dabb91846', '2022-09-29 15:06:33.453', '2020-02-10 01:25:17', 'Mia viami miyuami', 'Soavia viyu komirami', 'Komiraso rayu', 'Koami rasomiko', 'Koaviso yuvi raviyu', 'Miyu soaso', 'Ravirami komi', 'Rasoavi rayura yumi', 'Vikomiyu yurako yua', 'Korakora soyusoa mikomi', 'Soraviko raso', 'Rasovia mikomi', 'Koviyu koyusomi viamiko', 'Miyu komira', 'Misomi miyu viyuviyu', 'Sorakora rayumi', 'Soyusovi rakoyu', 'Viyukora soayu', '{"Koyuvi": "Mikoyu yumi"}', NULL, NULL, NULL, NULL, 'Vikoako yura koviko', 'Raviyuso korayu soayu', 27892);
INSERT INTO public."PaymentTransaction" VALUES ('4bf4dfe1-22e7-5984-894d-836d55359246', '2022-09-29 15:06:33.453', '2020-11-15 22:49:44', 'Koviyu yuvi', 'Viyu yurayu yusoyua', 'Raso soravira', 'Rayura kovia yurako', 'Vira mikovi', 'Viko koraso viayu', 'Koyu soa viramiso', 'Kovi komiyura koyumi', 'Misoaso misoyumi', 'Yusorami mia', 'Koyuso vikomia', 'Korayu viaso', 'Viraso miko koavi', 'Vikoa yua virayumi', 'Via vikomiyu', 'Miamiko miso', 'Rayuko viramiko miamiko', 'Viyu visoa mikoyu', '{"Komi": "Soyu kovia komi"}', NULL, NULL, NULL, NULL, 'Raso viyuvi mia', 'Koami mira', 16184);
INSERT INTO public."PaymentTransaction" VALUES ('8465bdd0-93ec-59ab-a902-6076e737b3c5', '2022-09-29 15:06:33.453', '2020-08-12 19:21:38', 'Yuso somiaso', 'Ramiyuso raviso miko', 'Somiko somiyuvi', 'Visoviyu mikoami koavia', 'Rasomia koyuko vikoviso', 'Koakovi yuavi', 'Misomiso viyuko sora', 'Rako rakomi', 'Miso mirayu', 'Miso yurami miayura', 'Raviko miyu soyuso', 'Komira via', 'Yuasovi soravi somi', 'Viravi vikoavi', 'Rasoa yumi koramiko', 'Rako vikoyu', 'Raso rakoa yuvirayu', 'Yuraso koa', '{"Raviyu": "Sora raviko"}', NULL, NULL, NULL, NULL, 'Viso rasorako', 'Rasorako sora', 7145);
INSERT INTO public."PaymentTransaction" VALUES ('7930f59c-fc7f-591d-a12a-10be4faf099a', '2022-09-29 15:06:33.453', '2020-07-07 06:18:21', 'Raso soyuravi', 'Vikovia raviyu soami', 'Viamia komia komiso', 'Koyu visoa', 'Viyu miakoyu', 'Ramirami yuavia sovi', 'Kovisovi mia yuraso', 'Yuavi yuakoa', 'Raso viyusovi ramia', 'Viako rayuavi', 'Yumi koa', 'Komira soa', 'Miyu vikomi rayua', 'Miyuso komi sorako', 'Miaso soayuvi komiso', 'Sora virayu raviami', 'Vikoavi via', 'Yura soviyu yuaso', '{"Koamiyu": "Yuvikomi miko miyusoa"}', NULL, NULL, NULL, NULL, 'Mikoayu viravi', 'Misora yuaviyu', 51325);
INSERT INTO public."PaymentTransaction" VALUES ('6c53ca66-9e9e-5d3e-bac0-d605c7911393', '2022-09-29 15:06:33.453', '2020-07-15 18:19:46', 'Visoa somira', 'Miravi mikoyua ravi', 'Visomiyu viyuso', 'Ravisomi miraso yura', 'Visomi ravia', 'Ravi koyumiko', 'Sorami soviyuvi', 'Yumi via somiyu', 'Misoami viso raviyura', 'Yuko yukoyu soyua', 'Vikomi sorakomi visoa', 'Yuvi vikorako yumi', 'Rako ravirami miyuvia', 'Yuso korasoyu koyu', 'Somiravi koakovi', 'Komi soviyu miraviso', 'Viraviso miayuko vikora', 'Miyua miso mirakoyu', '{"Via": "Mikovia vira yusora"}', NULL, NULL, NULL, NULL, 'Rayurami viko koyuvi', 'Miraso somi', 20019);
INSERT INTO public."PaymentTransaction" VALUES ('353bbc37-a470-5b2c-acd1-3aeac3432d28', '2022-09-29 15:06:33.453', '2020-09-05 08:45:42', 'Miko rayusora komiayu', 'Soyusoyu miyu korayu', 'Mikora soako yusoyuvi', 'Mia vikoayu', 'Sovia somi viyurako', 'Raviyumi yua yurasovi', 'Yusoa mira', 'Sovi komiso', 'Via raviko', 'Yukorami sovi vikoyuso', 'Somiko viko ravikoyu', 'Via somia', 'Soyukoyu komi', 'Soviko mikovira yuraso', 'Vira yusoyura', 'Soyumi ravi', 'Yukovi yumi', 'Komira viako yuvi', '{"Yusoayu": "Yua rakora"}', NULL, NULL, NULL, NULL, 'Rayurami yuavira rayu', 'Rasoayu soyuso miyu', 11781);
INSERT INTO public."PaymentTransaction" VALUES ('2bd6b078-3683-5dca-b689-e88a87e8e3eb', '2022-09-29 15:06:33.453', '2020-08-12 19:54:23', 'Yumira somi', 'Koraviyu viavi', 'Miko soyukomi', 'Ravisora via yuayu', 'Rasoa viyu', 'Soyu koavi', 'Yurakovi sovia rasoako', 'Yukoa yuayumi rayu', 'Rakoviso komiso yuvikoyu', 'Korakora ravia', 'Viyu soa', 'Ravisovi miso', 'Rako rayura miso', 'Koyu yusorayu viravi', 'Viyuami yumi ramiako', 'Yusomi miyua sovi', 'Raviako kovia ramiso', 'Ravia ravi', '{"Viraso": "Yukoravi somiso"}', NULL, NULL, NULL, NULL, 'Yumiko ramia visomi', 'Miso viavi', 40892);


--
-- TOC entry 4254 (class 0 OID 2148968)
-- Dependencies: 246
-- Data for Name: PickupPoint; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4255 (class 0 OID 2148975)
-- Dependencies: 247
-- Data for Name: PickupPointEvent; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4256 (class 0 OID 2148981)
-- Dependencies: 248
-- Data for Name: Platform; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."Platform" VALUES ('e3be2cde-5091-563a-89c2-816885e75f3f', 'Bonita Davis', 'Korayu viko yua', 175, 'Viayuvi rakomiyu rayura');
INSERT INTO public."Platform" VALUES ('90f68272-be6b-5bc7-88bc-4cceb316206d', 'Delores Stark', 'Mikomira rayumia miso', 1, 'Yumikoyu koyumi');
INSERT INTO public."Platform" VALUES ('74baffac-b2f8-5545-8e67-2d197aa7fc24', 'Alisha McGlynn', 'Koramira viayu miaviyu', 131, 'Somiaso yuayua');
INSERT INTO public."Platform" VALUES ('b7f8c74f-208e-5326-8121-43d9b4402f9a', 'Della Spinka', 'Koa miyu ramiso', 3, 'Rakoa rasorami');
INSERT INTO public."Platform" VALUES ('d3b394bd-64fd-5282-9a43-e1b17bf26c76', 'Lukas Hettinger', 'Ramiyuvi soyu miraso', 68, 'Yuvikovi miasoa koyu');
INSERT INTO public."Platform" VALUES ('65b53185-1520-5b55-8f11-27842f92466d', 'Burley Thompson', 'Rayura sovi', 204, 'Viakoa koyuami');
INSERT INTO public."Platform" VALUES ('cf5b7389-090e-5677-8b03-a8971fb9dcd9', 'Enid Rau', 'Virami sora', 22, 'Rasoyua yuvi');
INSERT INTO public."Platform" VALUES ('5623b5ec-57c5-5a0d-aa48-0b38cf746903', 'Parker Quigley', 'Soyurako yuraso sovi', 223, 'Visoraso sovi');
INSERT INTO public."Platform" VALUES ('bc66fcba-5468-5025-8262-ea5f3210b2e9', 'Priscilla Hoeger', 'Rayua misomi', 63, 'Soayuso soyu');
INSERT INTO public."Platform" VALUES ('7836d607-38e3-5af9-bb0b-dd2158de0efa', 'Lenna Deckow', 'Viavi mikomia soayu', 191, 'Yuraso mikorayu');
INSERT INTO public."Platform" VALUES ('7836d607-38e3-5af9-bb0b-dd2158de1efa', 'Lenna Deckow 1', 'Viavi mikomia soayu 1', 191, 'Yuraso mikorayu');
INSERT INTO public."Platform" VALUES ('7836d607-38e3-5af9-bb0b-dd2158de2efa', 'Lenna Deckow 2', 'Viavi mikomia soayu 2', 191, 'Yuraso mikorayu');
INSERT INTO public."Platform" VALUES ('7836d607-38e3-5af9-bb0b-dd2158de3efa', 'Lenna Deckow 3', 'Viavi mikomia soayu 3', 191, 'Yuraso mikorayu');
INSERT INTO public."Platform" VALUES ('7836d607-38e3-5af9-bb0b-dd2158de4efa', 'Lenna Deckow 4', 'Viavi mikomia soayu 4', 191, 'Yuraso mikorayu');
INSERT INTO public."Platform" VALUES ('7836d607-38e3-5af9-bb0b-dd2158de5efa', 'Lenna Deckow 5', 'Viavi mikomia soayu 5', 191, 'Yuraso mikorayu');
INSERT INTO public."Platform" VALUES ('7836d607-38e3-5af9-bb0b-dd2158de6efa', 'Lenna Deckow 6', 'Viavi mikomia soayu 6', 191, 'Yuraso mikorayu');


--
-- TOC entry 4257 (class 0 OID 2148986)
-- Dependencies: 249
-- Data for Name: Product; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."Product" VALUES ('899d114b-edd8-5d58-bac6-923e65a6b399', '2022-09-29 15:06:28.855', '2020-03-19 02:52:18', '4c:47:de:94:bb:d6', 'd5f6f584-f412-5e45-a4b0-c36ae18ccc57', 'e3be2cde-5091-563a-89c2-816885e75f3f', 'Miko komiami korayu', '5b7d4172-6579-5756-86c2-6d3eb717ac21', 'c2d0ae2e-aa88-5631-8234-686aac1c2510');
INSERT INTO public."Product" VALUES ('c24182ee-91e9-5eb1-99a5-b9cc92ef38ad', '2022-09-29 15:06:28.855', '2020-07-03 19:04:32', 'e7:fe:35:a4:17:11', 'a3c8946b-7629-51a6-8fc1-2df516e2bf20', '90f68272-be6b-5bc7-88bc-4cceb316206d', 'Ravi yumira kovi', 'a00b2d8a-3125-5032-b6b9-8bfe4ecde0cd', 'd211a977-71c7-57a4-8fda-12d03f20acd0');
INSERT INTO public."Product" VALUES ('ebe23927-b75b-511e-8a6b-827d564bfa74', '2022-09-29 15:06:28.855', '2020-02-02 01:53:27', '5d:0e:47:76:c4:47', '5b67511a-d1a5-544e-8f6b-6eda854869f9', '74baffac-b2f8-5545-8e67-2d197aa7fc24', 'Yuviyu soyuviyu', '3aa292a3-781a-5ff6-9eda-77e5885602c3', '3fb90236-b723-59ca-9bc2-a172f0d222ff');
INSERT INTO public."Product" VALUES ('4db578b9-d017-51b8-8d62-eea88d6dae3c', '2022-09-29 15:06:28.855', '2020-07-15 06:42:36', '7a:03:cf:1b:6e:c2', 'da3a4ae9-f9f9-5cc4-a6d8-bf333bab1a7a', 'b7f8c74f-208e-5326-8121-43d9b4402f9a', 'Ravi yumirayu', '85ce3358-1b05-5743-bd75-a3ebacc5ee44', '07be47cd-f34c-5675-b297-36c8ba66d956');
INSERT INTO public."Product" VALUES ('0ffedd83-34d2-5de4-a8cc-f06304a9f7ec', '2022-09-29 15:06:28.855', '2020-03-07 02:27:38', 'ac:e1:4a:4e:f1:ca', 'c6102f0a-3d58-51ad-916f-d6a9e2ddfbdf', 'd3b394bd-64fd-5282-9a43-e1b17bf26c76', 'Yuvira mikomia visoyu', '87e90fe7-930e-5602-8d4e-4c71ba9b89de', '4c90378f-a917-58cf-94e9-56c25396469f');
INSERT INTO public."Product" VALUES ('a338a623-365c-5773-9f38-13e2c35c138c', '2022-09-29 15:06:28.855', '2020-06-02 05:18:33', '72:db:b4:f5:02:2a', '9239ae58-0f0e-5e69-b8b8-44cbffcb6f7e', '65b53185-1520-5b55-8f11-27842f92466d', 'Yua korako soviako', '9d320192-ece2-53bc-b30a-eb1a0045585e', 'ddfa1e8c-b0fc-5117-ab6d-30fed2d81853');
INSERT INTO public."Product" VALUES ('5a06c0f9-863e-5d11-9be9-c5319750dfde', '2022-09-29 15:06:28.855', '2020-04-08 15:50:54', 'c1:cb:4e:12:7d:46', '41a532d2-6b08-51d0-95ae-819fce861220', 'cf5b7389-090e-5677-8b03-a8971fb9dcd9', 'Soyu miamia', '04f23833-0489-58de-8135-2329d515d0e4', '7beca622-0b69-52f3-bfb0-09152c8b6a2d');
INSERT INTO public."Product" VALUES ('01332422-a7de-5489-9332-57dd77d397d5', '2022-09-29 15:06:28.855', '2020-08-08 07:19:28', '69:fb:b0:60:61:35', '8abcdf6b-3212-5178-8da1-60645f6b493a', '5623b5ec-57c5-5a0d-aa48-0b38cf746903', 'Rasovi sovi', 'b3678c42-d71c-53a6-9960-35cc60df65c9', 'b4374abe-dab3-5543-a2ad-408dee7599be');
INSERT INTO public."Product" VALUES ('87bfa391-6900-54e5-84d9-a103ab39d112', '2022-09-29 15:06:28.855', '2020-06-22 05:08:51', '5f:cc:36:b5:16:28', '361f8a27-1b56-5f76-81ba-8987140f40d2', 'bc66fcba-5468-5025-8262-ea5f3210b2e9', 'Koviyu rayu', 'aeda0c3f-07b5-5d92-b679-03d3784a7dd3', '07bdbbf9-11a4-5f86-8de9-723cc31a7814');
INSERT INTO public."Product" VALUES ('907b8d2b-f42a-56d0-a988-50905ed6028e', '2022-09-29 15:06:28.855', '2020-07-23 07:04:31', '2b:65:a5:d2:5e:b6', 'a2d51b45-fa7c-5a68-9970-75e003c1c9c3', '7836d607-38e3-5af9-bb0b-dd2158de1efa', 'Mia soami sovi', '831a3b30-118c-5e76-99a4-5840c821227c', '8231445a-c17e-5adf-86e5-f17f56d69cc7');
INSERT INTO public."Product" VALUES ('3e9a9315-f0b2-5838-aa49-ad0747bd361f', '2022-09-29 15:06:28.855', '2020-07-23 07:04:31', '2b:65:a5:d2:5e:b6', 'a2d51b45-fa7c-5a68-9970-75e003c1c9c3', '7836d607-38e3-5af9-bb0b-dd2158de2efa', 'Mia soami sovi', '831a3b30-118c-5e76-99a4-5840c821227c', '8231445a-c17e-5adf-86e5-f17f56d69cc7');
INSERT INTO public."Product" VALUES ('9bd7f899-12cf-5938-adbf-1da9b61d3a23', '2022-09-29 15:06:28.855', '2020-07-23 07:04:31', '2b:65:a5:d2:5e:b6', 'a2d51b45-fa7c-5a68-9970-75e003c1c9c3', '7836d607-38e3-5af9-bb0b-dd2158de3efa', 'Mia soami sovi', '831a3b30-118c-5e76-99a4-5840c821227c', '8231445a-c17e-5adf-86e5-f17f56d69cc7');
INSERT INTO public."Product" VALUES ('37f9c208-0d5c-54fb-a558-c61ab9243520', '2022-09-29 15:06:28.855', '2020-07-23 07:04:31', '2b:65:a5:d2:5e:b6', 'a2d51b45-fa7c-5a68-9970-75e003c1c9c3', '7836d607-38e3-5af9-bb0b-dd2158de4efa', 'Mia soami sovi', '831a3b30-118c-5e76-99a4-5840c821227c', '8231445a-c17e-5adf-86e5-f17f56d69cc7');
INSERT INTO public."Product" VALUES ('7990700d-16be-5f39-adb6-0db5c0346552', '2022-09-29 15:06:28.855', '2020-07-23 07:04:31', '2b:65:a5:d2:5e:b6', 'a2d51b45-fa7c-5a68-9970-75e003c1c9c3', '7836d607-38e3-5af9-bb0b-dd2158de5efa', 'Mia soami sovi', '831a3b30-118c-5e76-99a4-5840c821227c', '8231445a-c17e-5adf-86e5-f17f56d69cc7');
INSERT INTO public."Product" VALUES ('cdcb05a7-2739-5514-9395-78fd441bd549', '2022-09-29 15:06:28.855', '2020-07-23 07:04:31', '2b:65:a5:d2:5e:b6', 'a2d51b45-fa7c-5a68-9970-75e003c1c9c3', '7836d607-38e3-5af9-bb0b-dd2158de6efa', 'Mia soami sovi', '831a3b30-118c-5e76-99a4-5840c821227c', '8231445a-c17e-5adf-86e5-f17f56d69cc7');



--
-- TOC entry 4258 (class 0 OID 2148993)
-- Dependencies: 250
-- Data for Name: ProductSnapshot; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4259 (class 0 OID 2148999)
-- Dependencies: 251
-- Data for Name: ProductSnapshotLog; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."ProductSnapshotLog" VALUES ('3356ba4a-038b-599f-bb2e-9f612d306247', 29583, '4403210652448651', '969706093377093', 'd5843f60-db99-5fc7-a877-fc3c20f25bda', '24476a13-cc54-526d-b780-09aa2344d7f8', NULL, 40545, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('452b20a9-b516-5457-b444-52faf97130c7', 60790, '2467990626925085', '203430194318822', '3625cf71-1583-59f7-ad9b-66ab7f3832bf', '0e419876-6554-5c08-8c81-cc1b7e1f4f7c', NULL, 43687, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('7887d0f6-61e7-511d-939f-cdee0189fe6a', 44728, '8923428991574464', '3284444552857158', '726c5e62-3abe-5f34-9e71-48d2ac22a000', '5a529eb6-2fca-539e-be66-6c6ab7c79c7e', NULL, 33167, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('3feb5489-90b5-5d8d-bcaa-488108cc2420', 17862, '5735859269689186', '8951983092755260', '8bf2de74-e3ac-5e8f-bc03-7210fcd3bd4d', '4eaff344-ea2a-50ff-bb24-8c1eff2c190b', NULL, 37098, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('75d3ab6b-6061-5ab7-bfa0-be686d1c1ebc', 14354, '6636053741943225', '6166183423690399', 'af00b3e6-2dae-51a9-9795-9fc841bbf934', 'd37c8766-213a-5389-b736-1f48e8727fd9', NULL, 42421, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('243191af-3272-5663-9c11-255fc741e918', 14311, '644926894837012', '8997557025365011', '9b1d75ae-73c1-5da4-9a94-bc07cb609757', '247f4427-d2ae-5a50-ae93-cbc726bb10a8', NULL, 54518, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('1b113bf5-33c0-5946-85c4-9af2fdc3f4ee', 31366, '6235969409082067', '7873920535811427', '377300a6-5a95-550c-861d-bc6e844db506', '4209de04-caf3-5bf3-9251-4ea6439e5d23', NULL, 2115, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('ef590d87-4aad-5a37-9553-eaa6ff968169', 20993, '2341042911491577', '443208213839367', '136c8b20-3ed8-5418-81cd-e0e112ed254a', '7a98f3cc-6d9c-560c-b439-ba0f6e7ad930', NULL, 43690, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('2dcd2836-4f85-50ce-ad52-34b50bc57c47', 25865, '2323249815932030', '255419983005460', '74de38ca-3868-5b62-80c4-c0c80b8ad7fe', '9c943319-851b-5c73-bba7-10f5d28560da', NULL, 16268, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('979f014a-7845-5bac-bf5c-ac6940201fec', 48236, '2244087342358407', '1957210721880776', 'aff283a7-7f10-59df-8155-3cfb43f7bb6d', 'a4f63104-d46f-5302-9339-1cc51374746c', NULL, 46408, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('c0fffe06-d97e-5da4-9e1b-6229d9a2dd21', 49997, '4359872852508634', '4212608903983192', 'bc7d0076-9188-5e22-96e1-8c23f8de8057', '40fcadd1-9cbe-5609-af4b-7b24dac9d69f', NULL, 61379, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('dccbbb92-1259-5082-98d2-4220eb83b0e8', 5662, '4707204042408219', '8163125345874389', '1634408a-0b5c-5c17-b692-aec9cad24576', 'ff071617-23be-577d-8d50-b57eb89a9eb1', NULL, 43782, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('73bfa8b9-8089-5d68-b68f-544cf02a8932', 26948, '264915244530568', '7857639272191661', 'd79f205a-f10b-54de-b140-efb3088d78ab', 'b04e5c2b-93fd-5948-bc85-8377dabf8a61', NULL, 32914, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('e6600ef3-7766-56f0-abf9-ae20bc332afc', 64094, '6850164594632239', '8904137655511423', 'e910a18f-f96f-57c9-abb5-3ad0e3bd6e3c', 'fcdffcec-d48c-5dee-b5f1-5a840dda4c71', NULL, 30471, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('d01dfd75-f887-5016-96cd-b53dd68494de', 43029, '2840100452176741', '6191414393982096', 'd9264c99-998a-5cb7-abe3-f89c9ca2d40b', 'bb741c01-541c-5d16-bc3e-d3dc59987eef', NULL, 6234, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('1e2af414-8bd9-5b32-b136-91f7472285c3', 5822, '4900307758398161', '5073000724762154', '6fa6b1fa-09a1-5f01-8a45-44305c8a6a4a', '21913ade-4e4a-5056-afbe-133e191aef99', NULL, 10146, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('02f394ad-e7ca-57b8-84ab-0306e27e1938', 34215, '6842914627547214', '3065043852285469', 'cb157840-1420-5b3d-a685-a323839bf50c', 'd7675a9b-690f-5c74-b733-a24f70e0b0fb', NULL, 5388, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('e6192d1b-70c0-54b6-94b1-bcaed960bf9e', 62399, '2018924261254572', '6190611410099096', '43e29ea7-9b8d-5acd-b910-d36ca38ea11b', '7f4df0f2-14dd-5d79-b4c0-261b652c5be0', NULL, 49583, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('9f8b3b0c-4e46-5ac3-ac53-509f6b6e567a', 47564, '8987568198501885', '7122639694918203', '6084a03a-ab22-5936-aecb-912c94c95cfb', '9fef3821-04d2-5e85-b788-510dd6ff5edf', NULL, 43868, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('d6c27193-3599-5838-875e-1f4c5e8e2048', 27137, '8621786164753884', '874231104914330', '819d8621-61f1-5acf-8b0f-69bce008b171', '021288fa-1c5a-5f7f-b2e1-e6403b0694d1', NULL, 65396, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('35b49f7c-d359-5deb-a792-636df6e5ca1d', 44868, '4235618929785193', '5961833577407277', 'ad1b3e6e-a6d0-5a44-a5be-b2c0deb4ba3b', 'b234e62c-3a5d-5887-bdf8-cd87fdc4bc64', NULL, 36054, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('1c6d4557-2bd5-5d51-95b2-6f60df3333a0', 10465, '5464450873570137', '1182503800942677', 'dc1c7d1d-b2f8-51c0-97e6-41644d1f9767', '1c9e8b10-2a44-59d8-bcec-304f1f694638', NULL, 17054, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('629486d3-01aa-5803-80c9-795c82cab162', 17929, '4497672256305252', '2208135647464483', '9453d721-8ac4-5ddb-9613-4cbc6f8741fb', 'bf5a6087-bdc9-577a-8bbd-f3705c0bf042', NULL, 52379, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('81275684-fc6a-5e36-b08d-dd4332194672', 49071, '2756632099652305', '575763409176371', '1426c2eb-279d-5a6b-a989-75485b1735f1', '7f2ea2ea-3489-5491-982f-b1b75bf58797', NULL, 1171, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('12312dfd-ab36-5be6-8613-ee908d431681', 49575, '1144630582919219', '6029812498452677', '5c44a35f-d94a-5503-b42d-7ca0e62c9596', 'dc0c1e1b-69d9-51bd-bcae-3c4b7d21abdb', NULL, 43910, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('3b673518-7f3e-52e4-8930-d32139cc1941', 25332, '5503242351985033', '3434763865658752', 'b1c9acb3-2552-54e6-b38a-e65b202f0dbe', '4b9e0e1f-31bf-5f2d-aebc-cdf6fd141b6a', NULL, 44689, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('4f01ba7f-cd62-5686-b63c-d7646b3796ab', 38131, '1491312748141146', '3041454378191612', '4242eb33-2c4e-585b-99bc-f2a958563abc', '696ee295-51e9-5cbd-b1a0-64b37c0bb3ff', NULL, 2058, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('01d80f91-8608-569a-b954-9bb1fd40d0ea', 43207, '6288648627381647', '3330084652281042', '27045efa-c741-5922-943b-83971747fc7c', 'f354ecc7-5524-54d2-a00c-55a0e7f5d156', NULL, 31905, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('a69f819c-ead6-5a1b-b53e-897b97d03708', 34364, '2562616759202100', '7414081159304789', '28994ba9-c3f3-5885-9e5c-905e30c48462', 'c5d6e2ac-46e9-5923-ad5e-67601207d0c3', NULL, 28350, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('3ea309f1-09f9-5601-b033-ad7268b5f888', 2345, '3394849892249041', '8558555578773254', '0377bc52-3584-597e-859c-a138650d33b4', '26bb6014-7e23-5817-9d7b-3c9cd6dff9b5', NULL, 62125, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('67bffbb6-e924-56f4-9edc-38a412cb43b7', 41598, '1294191363765860', '4824477460761311', '3b5d91fd-86ec-5b57-a286-9b5234fb616b', 'd34ec5d8-619f-5ef6-9429-b2343ee2beb3', NULL, 36161, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('1b280d60-135c-5d0c-b486-196c06fba799', 58756, '1461205094722590', '5712737573537011', 'cd68320f-134f-5c3a-ae26-65bf5e26fc13', '288b6ea9-b140-5897-8032-ee076f9cb08c', NULL, 7442, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('96b7f58d-d22d-5682-b03f-084956bdb378', 57684, '148985384723731', '3995241409644489', '5e58c0dc-cf22-588e-90a1-7bcf2be3c553', 'b72a74ef-4194-50fc-a390-7a067ae477f4', NULL, 46149, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('fddb15c3-29d3-5aa6-847b-9fe9ecc760ee', 8490, '3503053903263061', '3486689547913715', '94d018cf-268e-5dde-96d6-6f7d78f6a260', 'bb8f070c-032a-5874-93ae-621ace8ca7ca', NULL, 40080, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('c8d5de49-a540-5b1a-944a-bcd6eec97c7b', 37246, '1502427512230737', '5277750936509704', 'ef5270ec-8fbf-5f9f-93ba-630410d72141', 'e03dbb0f-529c-5d93-8055-36999bc48476', NULL, 53244, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('70a05ee0-6e94-5bd3-b316-cc86cf4f7581', 62505, '6648171878735272', '1973326991215807', 'cd0b572c-e26d-573c-afe1-d141f08676ca', '2f21c219-c153-5a41-9f96-7264af665225', NULL, 22582, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('6df82afb-1500-5f23-bb58-b9633841252f', 22938, '7104532733140796', '2990624360923134', '74183bd0-5c06-548a-b25f-ba7ea57a8f6d', '145a1746-7f74-5e2d-823a-fa2d7814e2e9', NULL, 58352, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('9ef3d35b-4ad1-5fb7-bd3b-8274e1b70f25', 13283, '4611384018785838', '4338731908311633', '33108bdb-ae8a-519d-883b-100e8ea04d33', 'dd175042-73e3-5092-bc53-01b3a79dae2e', NULL, 49061, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('26ebec93-782d-5e05-9997-8554b442c60f', 28502, '1302891028879876', '3625318931497940', '9ae4c22a-60fa-56be-8f53-1a1d4ca78c4d', 'c9b79274-6a9e-5945-9d49-6429a3ea014b', NULL, 44455, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('447da8e7-e4d3-5014-adb9-e7f1f5d68bfe', 21685, '1849615386711826', '7170900217683881', '9ddd9373-7687-5b7f-a4c3-dc957600e0ea', '509632f5-8944-5ebf-a432-9d8c885664ad', NULL, 22939, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('1e20bca9-1c3c-53d8-bb25-1d24369c0f08', 3506, '3296708532001788', '4707917030139386', 'd0524822-2145-59a9-b686-a509aa0f3cbb', '1ea704f9-483f-5fc5-a9a5-24e70663de7d', NULL, 47659, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('a691576a-3d71-5a9c-998a-e65e8c457aa0', 8211, '8721068160944391', '3485953488660952', 'f1602db9-75e7-5a9f-b638-2b6680a028b0', 'ca3117f6-bcc6-5d6c-a203-a87023ed761c', NULL, 6850, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('2b13e6c5-8cf2-5e41-a333-fbe7fd4cc74b', 39319, '1793474310430992', '4721390917190178', '725c8b47-d09d-55d6-9796-b6c14c4a4b67', 'cda29835-5768-5be7-b5a4-e820ffaacb63', NULL, 8350, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('ceef9267-507e-5e85-8d39-d5ff980ece7d', 28, '4072407738263244', '7772865031271151', 'b1873e14-79af-5d12-b57a-3b578aa88430', '6e776df9-fb9e-5dc3-9fa5-161f67a25e3e', NULL, 13036, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('f7382a91-6ab9-560b-abf9-2ae2ae4b702c', 19052, '8163308845650874', '2492993104140086', '7888a0fc-094d-503a-93b5-1ff7bb6fba36', 'b75be3c0-f388-5899-bb75-9ac35dd12120', NULL, 56495, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('4f62157e-205e-56fb-903f-924e406fd370', 23444, '4205775770810357', '7763961407480700', 'e37f58b1-084b-5687-bdce-c73d4e898d6f', 'f24fb361-e028-5829-b351-1dbc2449bf69', NULL, 25147, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('3ad69634-172b-5535-93cc-71ba646f4ffb', 36288, '817359190136883', '4402293361179288', '7130d13f-ba91-5a12-8244-c63c2617bea1', '83d61967-4337-509e-a5ce-9a1cc759dd68', NULL, 24778, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('a08dfa9b-0c91-5fbc-af12-d76d82c79d4e', 30995, '4224546057318600', '2082713368696856', '9308986e-45e2-539f-9312-5c894396ae2a', 'b1da5ed5-a0f5-514d-8580-f391f7324fbf', NULL, 27935, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('2b8fc4e6-3100-53ca-b040-33bff008330c', 21126, '4103095569492627', '4637825771625583', '10ca87cb-904a-5f6b-9f3f-107751ff3941', '4905829a-af1c-5c73-80de-7d31cadef735', NULL, 28215, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('60b8e755-4988-5251-a360-f7ecb2c5b558', 11268, '1885203902316118', '4714442676181467', '30b41b15-c5d6-5762-b876-c2e2636daf0e', '27c5a496-7c9e-5820-b4b0-5df7c609b9c9', NULL, 24722, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('f4b901c9-6a5f-5559-a307-7b72c3ec32ac', 4573, '5314892354886267', '7008558818082404', 'a0eb8027-af61-5e8f-a6bd-c47b42d314c1', '5fc945b3-32af-5e23-8104-f53644a81de8', NULL, 49818, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('52b53873-6ff8-5ef9-8550-c8aa58d238c8', 41098, '306953805659487', '5544348098393601', 'b9fd6aea-0157-597c-a2bc-3530493b13bc', '40dcafcb-96b3-57f4-9f91-b72429d105d3', NULL, 46104, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('0aa58ad9-d9a0-5611-ad06-fc3566190098', 48600, '4150196145711038', '1012132574494742', 'ef14f8d0-9f26-5c0a-8b09-5c54ad6cce79', '89a5db7f-73a3-553e-b89c-501d10d250de', NULL, 53584, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('22f23484-9aba-5bfb-a84f-ad4c4143fe35', 25447, '3505153361032112', '6424859275604365', '3cd45ad6-04fa-50ff-8137-5fea3a7c417d', '4f1ccf9f-e26c-58f8-b6c2-8c543fde91c6', NULL, 3702, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('46cfa31e-b50e-50ea-9830-04f0d749620a', 33681, '3358568493375367', '103149432509995', '96b0fa93-4b61-54b6-8675-e8b3554f6f54', '5a0a8dae-03bd-5c2d-94c4-2809d3c918cc', NULL, 36644, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('333a6c07-44af-5c9d-8a5b-d55256fab8b5', 4359, '3813892746190362', '5920987258237799', '67dc4478-fd32-5fea-a2b7-1ac5f7980d57', '98ae6745-c484-5f09-99ff-97bc5b60de6f', NULL, 7402, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('3dcdc083-8673-5ed8-b0a6-b079a097ebc5', 21223, '1615315059102693', '2444769233646012', 'a44bf395-165b-5a20-bf9f-b3c7244d7640', '51f418fc-727c-518f-a51c-8f9dc0646c3f', NULL, 5551, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('6c82edc5-105d-54e3-8234-e33f2d2811d8', 7217, '4524111790519540', '6040742962435605', '0757ff38-3eba-5659-bbb8-d1992928761b', '4484ce5e-df0f-5080-879a-6ca73edf360d', NULL, 40609, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('f2f7d84f-dbbf-5289-b4df-74ab2566b7a6', 31987, '443325003267875', '5530668037334300', '3c187595-b4c3-5d4d-b4cb-e80832ea56c5', 'e0b5468d-2a18-58b2-ba0c-86ddc9aa94c8', NULL, 108, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('1ac90e5a-c27b-5309-8e98-dcadadddcc37', 41343, '894879109111123', '4984453392309007', '2684791c-72a4-5c03-9937-a256bffe819d', '62f67399-5a54-505c-87ea-4d8ce87c3a9a', NULL, 32477, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('c164ac29-98b0-54af-b046-1752943b813c', 17995, '6563979983662721', '6995014878808773', 'bf226d6d-84f7-59d1-b375-61f09c92caa6', '0b35a819-c4ca-5079-bff0-5bd2c37a7e27', NULL, 14810, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('887539e7-89a4-5a3f-b46a-4b7b96e55910', 56365, '2052957119011963', '2374481755782127', '354f763f-ed13-5931-a62d-bc321eb154aa', '986cd104-aaa4-527c-8010-421ce886ca0f', NULL, 46950, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('970fbb3b-e87d-5bf3-bfd7-fe8882906b3b', 56074, '7246671860493490', '2345919115836930', '4c6338dc-c12f-5c45-a8df-5adb78039621', '558bd22b-c7cf-5288-8a4a-6abee03a33b7', NULL, 42117, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('8c661fc7-39ba-57b8-93ae-0954d081f859', 64367, '8853567217741786', '8846922847971320', 'b946697e-158f-53e6-94a1-fd2d3b2f9dd7', '6e0284fe-37d9-5429-ba64-3f4e0c7f6e20', NULL, 15776, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('d46d5ef4-22de-524f-8b19-ee703919df65', 26459, '1478665596221186', '6296832743925042', '74c79a22-5e4a-51b8-8f2b-ca4896143bcb', '69e09fda-745c-5dd7-91cd-f947c92fac7a', NULL, 35615, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('cbcc6f28-b8b6-5f5c-b936-c7e4300bcbbf', 45595, '4271016493634064', '5478400324906767', '25145f9e-fce3-53ae-9fde-ed10c619e767', 'cd23902f-ca03-5dd5-9ef7-b6ced8fa8eed', NULL, 27687, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('2329fd39-dff2-51e8-a883-9288f4e8f0ce', 36575, '2591986407922667', '7988611946463359', '5a062f4c-77f9-501d-905e-630ce0f7da56', '309d03ba-6dce-5f22-ba4d-6d6a00a3c27a', NULL, 25991, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('26256266-b1e8-561c-931b-a2675679cf3c', 37715, '8592169675233796', '191354862042911', '32f6d4dc-91bb-596d-98ca-37dd64e43c1d', '2485f890-a6ff-587b-be0a-9fb4309d7fed', NULL, 24968, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('ad0c35da-5d44-5778-a0bf-c7319859d5b2', 49415, '3146986603759680', '5276292152240246', '70d17572-6e19-5159-b9fa-7f482b3dc3c5', 'a01cf109-74dc-5a32-b4c8-56b4f77db6f0', NULL, 9050, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('8ab29bef-b954-56b4-be13-44d2f18af272', 33174, '6797224942610957', '6071592568248661', '69fedeae-66a6-5cc1-90c6-d0288f25ab7e', '28139135-2c40-5261-9d56-c0b27131af3b', NULL, 20139, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('657a0162-bd30-56ea-8239-5bd2b4df9cb4', 54416, '340356129315677', '7219272817570508', '5603a368-bcf3-5174-8911-a09b32db4de6', 'd1e11a45-7a94-5e47-bd11-9d83a10953f1', NULL, 7283, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('7664ae9b-6f98-5ff8-90c0-736732cb5769', 49933, '3323995022072001', '7322904185099719', '45b0b475-82d3-5795-8e6e-7170b0879987', '4fa0507d-8462-5318-8688-1fa587e4cd43', NULL, 41480, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('049e7f18-35f0-5989-aae5-5bc43076ecd8', 19354, '6256022032758872', '6371553878394784', 'b93ca458-7326-5df1-b4d8-b6e3192b7b6d', '119e2c3e-d324-5528-b091-395b13cb7c76', NULL, 54988, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('701eeadf-8d88-5aa8-addb-1f01feb2a9aa', 37115, '4894327014752368', '1837110930439068', '9290ba6c-adeb-5ad5-9a8b-cb13a9dec941', 'f26557c2-686c-5fea-babf-a75cc14b3630', NULL, 63022, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('2645ba45-d62c-5a0a-ada0-8b483398e309', 13774, '796030676821497', '8957560732093458', '8cf05d7d-7389-56df-bbe9-3126dfcf4fd7', '85efc26b-62f4-5ef8-812d-0e39191062bb', NULL, 63825, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('3d3e45b6-7bcc-5235-9570-44f70cb66843', 25924, '4071407933205989', '8566468218135752', '95033788-cec1-5afa-80b9-384fe24054e8', 'ab69520d-ce05-593a-8ca5-ce3839d8d580', NULL, 60964, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('01b3758a-5712-517c-8968-1be7d4316155', 46169, '5791046670380003', '5724372411909546', 'a06577b4-ff9a-51dd-874d-4d81c00ccf2a', 'd0e27ba6-b929-5d12-b000-b38731f81df1', NULL, 26678, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('82f14939-8021-5533-bfe0-8482a43618c9', 59918, '1723634115363532', '6460816436199153', '854cd43a-b034-5e5a-883a-5c2f201d495c', '2fc2d724-8fba-53b3-8be0-88352c36b888', NULL, 10508, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('5da46e65-21b0-5cba-b8bc-f1ca2c335da5', 27963, '736314553567955', '7132574358025484', 'cabf382d-f29a-5ad2-a750-6303e28ec310', 'a8e448f9-5ccd-51e2-aa1e-a502292303e2', NULL, 3232, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('dc7fd44b-4371-5a91-98a8-9f2409d99941', 56812, '5279567675879619', '1834664183815394', '9d4eaa82-18ce-51e4-8c4e-fa47a38a1e8b', '9fc77cbf-3cc7-58c9-9cff-88e633b8ef32', NULL, 42710, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('74c06696-f19e-5c44-846a-e9c6dc7fe676', 35467, '6977779146199721', '8033001590503385', '58256390-731b-5e57-aaf2-c6cd2eb1855e', '9fe447b0-7624-59b6-b892-8938a0ef3a1a', NULL, 17152, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('84f3a905-8e3e-5890-9dcf-130c80c93394', 10175, '7059732295593082', '1484041825742968', '952cf1d1-8258-548d-99d4-d001c5f140ee', '13ff9d9b-b22b-5997-ba7e-efa21ef7975e', NULL, 5152, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('308fbecf-4837-550e-b28d-70d7f663e346', 15966, '1899795195558082', '2952232947611773', '1dd606b2-9998-5965-a9b5-16bab2c8acd7', '070a77cb-9f40-56f2-85ae-81948c892ac7', NULL, 7981, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('706390fd-d843-5b2c-808c-1d5714b2c807', 63468, '7521138050400937', '7876455275850747', 'cf3fab26-338b-55eb-8ed4-8a62529e0711', '594995de-ca7b-5427-a458-a94cc2673089', NULL, 18629, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('8efcf1b4-5aa2-5ec3-aa1c-f24e44210d4e', 17748, '6769782349690119', '7194995381592165', '8a0d8a70-d403-562c-b8c8-8413aaf7e8ed', 'ca5ef749-f79e-5929-acab-15d609f26dc0', NULL, 38454, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('88f3292d-a82f-5d95-b0d9-2dce100166e3', 35069, '7311153890469417', '2929287699963139', 'a1d67eab-5c57-5e4c-bac8-3f06aa7e1e4f', '13c8703e-ef7d-5da9-84a5-ead21d3d1a52', NULL, 32705, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('a7690bec-7a68-5284-b560-6150039f4bdd', 4121, '2235088613850069', '8122798172302512', '44a0769c-bc37-5554-8051-f30e0e085786', 'b28bb473-3290-52c9-bad1-87d8b13c7d3f', NULL, 8888, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('575c7d80-b76e-5536-b941-448bcad0088a', 47305, '4116403494003092', '6213928426230469', '54ed4e8b-c47d-5616-b9cf-2d729c934368', '713d6bc7-d7d0-5695-96ac-27022e44cfbe', NULL, 20612, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('731d0d59-1cc9-59eb-ab22-ff7871b10401', 21971, '3312149838794946', '8502646355918527', '44d41fe7-942c-5666-89aa-10245aca2e5c', 'f9ce2817-1ebb-5eec-8db2-4438e5808887', NULL, 15772, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('ec18c876-1de0-5f4b-9cdb-152df8bcf2ce', 13550, '8134755522918808', '4334892006648795', '7ef2848a-abbc-5ffb-87fa-7c5b5879e23d', '15e0aaa5-4382-5031-b1a3-f6854b2f1319', NULL, 22254, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('d4aa2275-35ec-5266-a937-465332abb578', 37445, '7568911715935109', '1199120138204426', '8c3b64a6-845e-5303-92da-41e7e1517089', '9e85c255-99d2-5f9c-a70b-9c163073d65d', NULL, 22058, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('071cbd92-72d0-5ad6-a129-af5070e01d33', 55599, '4726853258666408', '1040370931217910', '7b253600-9104-5598-ad75-e5bde0cd516a', '8ab54799-a399-53f5-bacc-b9be4a3134fe', NULL, 15838, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('6ca51431-8776-5fb8-9736-faf16717baed', 49501, '5453935118811651', '5318969302203589', 'd4743f8d-7d3f-5e08-9268-7d874ac701d0', '5b5ef787-06c0-5c2d-ad9d-e581da55bdcc', NULL, 52992, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('2521fd59-84b7-58ae-b645-aae5f66437de', 1406, '4626735811995271', '2857505166587322', 'e79cc7f2-77a9-5363-8eba-e1fabde851d1', '589a79f8-a068-58b3-8a9e-a04555b6e62d', NULL, 37733, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('65c3bf2f-6426-5e0e-a75a-0ff671ce367c', 59963, '2906598421301575', '5789442829498577', '3a09b8c8-1ed0-5114-9f49-ed68e4a61ac8', '040fdf81-48b7-5f84-8333-c4dd1d33934e', NULL, 27751, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('ffe71b9d-5c27-5ee7-9413-dc74a2685400', 64326, '2141111623953601', '8691968700372480', '52a93063-dc3c-5c1f-9131-f6b804abf401', '76ea476f-74f8-563e-be7e-8dce736bc16a', NULL, 1091, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('2a1799ef-3b98-588a-bf79-6dd9b838b383', 37575, '7061328994166693', '5898161212681533', '01cfc1c1-76c0-5b30-a6e2-491959a7ff80', 'f2da710f-c856-5251-82da-0ec956c34478', NULL, 38444, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('4ffad828-1a88-5ae2-af8f-8740e56d0c82', 61908, '1988351720037091', '4324853344427716', 'b2590d5d-55ae-5847-96fa-71f74d42751f', 'd146fba7-a640-5fda-af4c-7d1ef163bb89', NULL, 49928, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('6551ceb0-0cc6-5490-8a6f-0095f379064f', 63398, '617928143398804', '2186472307720841', '12860995-82ee-56a9-9c4e-c6375607468a', 'f07d7904-daaf-5fbf-a5f7-f1d31f841657', NULL, 30562, '2022-09-29 15:06:28.693');
INSERT INTO public."ProductSnapshotLog" VALUES ('71b893bd-34d7-5be6-93cd-167bdc836bb7', 28455, '3749481773383376', '4698603224207082', '7a002a66-b7ac-53ee-95b2-483c6cba4672', '71366a37-528a-5f8c-b8f3-8cb508a6a6cc', NULL, 22277, '2022-09-29 15:06:28.693');


--
-- TOC entry 4260 (class 0 OID 2149006)
-- Dependencies: 252
-- Data for Name: ProductSnapshotReason; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4261 (class 0 OID 2149011)
-- Dependencies: 253
-- Data for Name: RejectReason; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."RejectReason" VALUES ('6ab91956-8dca-574c-9e1e-696209ab9824', 'Savion Schumm');
INSERT INTO public."RejectReason" VALUES ('1df53154-40d8-5c13-8bea-ae73c6c7d1d8', 'Natasha Walker');
INSERT INTO public."RejectReason" VALUES ('6d9d4aef-d8d4-5d4c-9f60-2b79cb7f4ac2', 'Madaline Hilll');
INSERT INTO public."RejectReason" VALUES ('d62b88c8-66c0-5327-89b6-91206746ed94', 'Hector Runte');
INSERT INTO public."RejectReason" VALUES ('ec4c3b7b-49b2-5e28-a301-22c405b15ac4', 'Joanie Romaguera');
INSERT INTO public."RejectReason" VALUES ('2c579ae8-50c7-50cd-921d-119113e6dabf', 'Kelly Kilback');
INSERT INTO public."RejectReason" VALUES ('bb0c8061-61cc-54d0-887a-45eedc11a83c', 'Sean Fisher');
INSERT INTO public."RejectReason" VALUES ('cf318b00-512d-5973-ad89-acc7cfb98330', 'Mariam Davis');
INSERT INTO public."RejectReason" VALUES ('a679fb4a-902a-54dc-9718-62f4812a3703', 'Pedro Quigley');
INSERT INTO public."RejectReason" VALUES ('60bfa944-fe2e-58f2-a5ef-274820157e47', 'Zella Tremblay');
INSERT INTO public."RejectReason" VALUES ('3e6f3888-0f64-5ba3-ac55-6cb111506610', 'Vernice Kautzer');
INSERT INTO public."RejectReason" VALUES ('679a6c0f-4ca5-59b0-a5a6-1dd2ad9cd112', 'Roger Moen');
INSERT INTO public."RejectReason" VALUES ('16615dc8-5789-562f-9c09-d2d3f240c64f', 'Aubree Purdy');
INSERT INTO public."RejectReason" VALUES ('6f547345-8891-58ad-9126-2700eccce449', 'Lavina Hane');
INSERT INTO public."RejectReason" VALUES ('b6d7cafc-81de-57cd-be71-b2ea39fee987', 'Toy Mayert');
INSERT INTO public."RejectReason" VALUES ('160d41b0-5916-5600-8a95-288f6bb2afef', 'Wilbert O''Keefe');
INSERT INTO public."RejectReason" VALUES ('77ee05c0-95d8-5c3f-a4a0-d742e90d47d1', 'Jerad Effertz');
INSERT INTO public."RejectReason" VALUES ('370521e3-8ca2-51f1-af86-e03ab71ea3d3', 'Yasmin Bauch');
INSERT INTO public."RejectReason" VALUES ('a264b127-6f8f-5be8-8dfd-1e8469148530', 'Green Pacocha');
INSERT INTO public."RejectReason" VALUES ('379bd071-4a77-54c0-9eed-7ef81de83cf3', 'Carli Hyatt');
INSERT INTO public."RejectReason" VALUES ('e9c7e011-37be-538b-905e-eb2e8c15b98a', 'Kira Roberts');
INSERT INTO public."RejectReason" VALUES ('b0784427-cba5-5735-b945-e12c7b767c6b', 'Scottie Dickinson');
INSERT INTO public."RejectReason" VALUES ('7d75a766-6078-58f8-ad65-4d5f11a11067', 'Toby Schulist');
INSERT INTO public."RejectReason" VALUES ('c1879078-dfee-58f5-b018-610cfe463c37', 'Julien Kihn');
INSERT INTO public."RejectReason" VALUES ('ec761574-7937-5bc6-a853-563ade9f1654', 'Simone Ledner');
INSERT INTO public."RejectReason" VALUES ('3ab509a4-efb6-5603-b34f-4da441f77153', 'Pauline Rau');
INSERT INTO public."RejectReason" VALUES ('3282a9ce-88cf-517d-8b27-82f3b38a197b', 'Bruce Weissnat');
INSERT INTO public."RejectReason" VALUES ('4078e69d-a6b7-5ba4-9d0e-62a3f1ba599b', 'Francis Ebert');
INSERT INTO public."RejectReason" VALUES ('7e5d7cae-2701-53c9-9d73-3660c9189f4b', 'Michele Blick');
INSERT INTO public."RejectReason" VALUES ('cf672e5a-8a68-56f7-8148-fa7c1d011e8c', 'Madelyn Hoeger');
INSERT INTO public."RejectReason" VALUES ('f10f6ec8-fd90-5acb-af29-f6a66ebc3501', 'Kayla Hamill');
INSERT INTO public."RejectReason" VALUES ('0b0c2598-3fb3-5a90-bd96-1c8f6b474ed5', 'Cullen Friesen');
INSERT INTO public."RejectReason" VALUES ('cdf653b2-7bc5-59f9-b0ac-8920da2c70b1', 'Aditya Schamberger');
INSERT INTO public."RejectReason" VALUES ('04f9b5b1-c108-5247-9d62-80ed8f56f65b', 'Vesta Weimann');
INSERT INTO public."RejectReason" VALUES ('8a6498d0-f7a3-5855-8f7e-fb4324601f1a', 'Brenna White');
INSERT INTO public."RejectReason" VALUES ('8e2db94e-64b4-53c5-819c-858caa6cb196', 'Davin Turcotte');
INSERT INTO public."RejectReason" VALUES ('fcc3726a-0a70-5208-9695-5caecff69815', 'Maia Auer');
INSERT INTO public."RejectReason" VALUES ('ce08ec26-b4b6-54f9-8b5a-848c19146389', 'Xander Spinka');
INSERT INTO public."RejectReason" VALUES ('3aba9b8e-e339-583c-8d17-4f29169c25d9', 'Princess Deckow');
INSERT INTO public."RejectReason" VALUES ('28386f06-57cb-5463-9ff8-eb4bc7e21980', 'Henriette Turner');
INSERT INTO public."RejectReason" VALUES ('29832a0d-4da9-58e9-aa12-3c378047544c', 'Morton Runolfsdottir');
INSERT INTO public."RejectReason" VALUES ('9a661236-4114-539d-8df4-6e2645a53576', 'Arianna Brown');
INSERT INTO public."RejectReason" VALUES ('6316854c-1a49-54f8-9ab7-1b5e371ceeef', 'River Jast');
INSERT INTO public."RejectReason" VALUES ('d3fda7c3-d3a6-5b68-999c-36ff29e66c25', 'Americo Keebler');
INSERT INTO public."RejectReason" VALUES ('b4c2a2fd-0972-57b6-9078-1bc69fb035b5', 'Candido McLaughlin');
INSERT INTO public."RejectReason" VALUES ('d0dfc929-011d-53ce-a73d-d1fc4308f575', 'Aron Shanahan');
INSERT INTO public."RejectReason" VALUES ('61dc2969-122e-5075-9e70-6eac2b936d74', 'Nella Boehm');
INSERT INTO public."RejectReason" VALUES ('40ab3c68-db37-5be0-961e-430589ce27fb', 'Marianna Hayes');
INSERT INTO public."RejectReason" VALUES ('aaa52b4e-a3d5-5cf8-ab49-22eb78ee0814', 'Kaleigh Friesen');
INSERT INTO public."RejectReason" VALUES ('ca89e7b2-650e-54fe-b0bb-f5d7e6b69f5a', 'Daija Stark');
INSERT INTO public."RejectReason" VALUES ('4d48836a-817d-5730-b28b-680b7d4192ca', 'Felipe Swift');
INSERT INTO public."RejectReason" VALUES ('b6182b49-2896-571f-91ea-aa3b6a0eaa6c', 'Julius Sauer');
INSERT INTO public."RejectReason" VALUES ('b0628226-9ea6-5179-a148-e6515a2e192d', 'Alva Stanton');
INSERT INTO public."RejectReason" VALUES ('9468d241-92b6-517e-a188-f0ddaf0080ec', 'Rigoberto Nolan');
INSERT INTO public."RejectReason" VALUES ('427e2833-5366-5ecb-9fd1-f2122924e2fd', 'Bettye Stokes');
INSERT INTO public."RejectReason" VALUES ('bbfb70e3-f146-5b07-90c3-9391eb6e32a4', 'Reed Kuphal');
INSERT INTO public."RejectReason" VALUES ('cf8d190e-b6fd-564f-9bcb-6ef4268066cf', 'Danny Von');
INSERT INTO public."RejectReason" VALUES ('a704dad6-9345-546e-9d2c-561168a747cb', 'Kelton Walker');
INSERT INTO public."RejectReason" VALUES ('9f8314b3-0368-54f1-8735-6a69fa3d3a8c', 'Xzavier Ortiz');
INSERT INTO public."RejectReason" VALUES ('89c807e9-0a38-5445-95f6-ad146f45295f', 'Cassandra Shanahan');
INSERT INTO public."RejectReason" VALUES ('06e0551a-10d8-5050-b40f-d1a0b6321526', 'Alford Hermann');
INSERT INTO public."RejectReason" VALUES ('494be9d6-504e-5497-9b31-79730af4efd2', 'Greyson Marks');
INSERT INTO public."RejectReason" VALUES ('67331df6-b77f-59cb-b0cd-b0ad3e44cc0c', 'Ken Tromp');
INSERT INTO public."RejectReason" VALUES ('8e6ebbbc-f5e1-5173-bab7-47ec2c3a95f5', 'Lizeth Bergstrom');
INSERT INTO public."RejectReason" VALUES ('f273900d-f878-5b7d-83e5-4e67c6f7e9e6', 'Kimberly Hills');
INSERT INTO public."RejectReason" VALUES ('ae09bb28-480e-54f0-9a0e-45e462456a18', 'Abner Schuppe');
INSERT INTO public."RejectReason" VALUES ('4234d105-7712-564c-b2ba-31fc835b0277', 'Hal Gutmann');
INSERT INTO public."RejectReason" VALUES ('8b35a057-3b5e-5a86-b7d0-7c12f72c048e', 'Kristofer Kemmer');
INSERT INTO public."RejectReason" VALUES ('9fef8ba6-fffd-52af-93e5-7c3f713f8f4f', 'Brook Frami');
INSERT INTO public."RejectReason" VALUES ('65a26139-9244-5a7a-9bf7-440abe8a086b', 'Braden Crist');
INSERT INTO public."RejectReason" VALUES ('b1f9f772-cd98-5031-95dc-16d5bc94ea67', 'Buford Mohr');
INSERT INTO public."RejectReason" VALUES ('20e7505d-84e7-5e81-be26-861c0bd85d44', 'Alessandra Ullrich');
INSERT INTO public."RejectReason" VALUES ('b7c0eb3c-196d-5cb3-8be3-4feedfbef491', 'Rebekah Jacobson');
INSERT INTO public."RejectReason" VALUES ('3f1ec8aa-4625-5007-8225-fa4ab33871e1', 'Jany Windler');
INSERT INTO public."RejectReason" VALUES ('3abde15e-1ac5-5b91-a44a-a7217c050ef6', 'Rebeka Hane');
INSERT INTO public."RejectReason" VALUES ('e0f51472-bc8c-56bd-a6a4-7ec311e79240', 'Diana Gaylord');
INSERT INTO public."RejectReason" VALUES ('20d5817a-d481-5abb-91ee-af458df4ef4d', 'Brooks Hammes');
INSERT INTO public."RejectReason" VALUES ('e61a00ba-cd02-56db-be04-dab9bdd1fb3d', 'Etha Nicolas');
INSERT INTO public."RejectReason" VALUES ('ccfcffc0-7cae-5f30-8a71-5060758a6199', 'Aimee Bergstrom');
INSERT INTO public."RejectReason" VALUES ('4b8e6948-34bc-57a9-9ee2-7c2eca7bcb78', 'Faye Hickle');
INSERT INTO public."RejectReason" VALUES ('0ece27f3-9a16-5072-bc83-2876abd6ab83', 'Brandt Stroman');
INSERT INTO public."RejectReason" VALUES ('455681b4-8151-54f1-b2ea-12ea78ba572e', 'Benedict Yost');
INSERT INTO public."RejectReason" VALUES ('bc957151-aaf1-5961-83f9-7e4d45e0ac6d', 'Willard Veum');
INSERT INTO public."RejectReason" VALUES ('79828c65-cbc8-59ff-829b-5d64d0f679a6', 'Dario Jaskolski');
INSERT INTO public."RejectReason" VALUES ('807b1055-37f3-5ff3-92a4-582d2c73a2a8', 'Orin Jerde');
INSERT INTO public."RejectReason" VALUES ('2f0c3d14-9ccf-5a97-9ddd-5d09c35d05a2', 'Elsa Jacobi');
INSERT INTO public."RejectReason" VALUES ('10dbebd7-bebd-539b-ac44-352579be4d05', 'Magnus Kirlin');
INSERT INTO public."RejectReason" VALUES ('13f93510-c04a-5cfc-827a-4c0f12626def', 'Tanya Rohan');
INSERT INTO public."RejectReason" VALUES ('9c748dd0-e88d-5348-b326-ec334c4ceae0', 'Naomi Bode');
INSERT INTO public."RejectReason" VALUES ('73408bb1-5b73-56f4-b6c2-fb7040e4515b', 'Jazmyne Jerde');
INSERT INTO public."RejectReason" VALUES ('163f790b-d2b7-5d33-9790-a2a48195c10d', 'Kristian Mitchell');
INSERT INTO public."RejectReason" VALUES ('96eb2e45-022a-5ca3-a321-eb1bdc23496f', 'Breanna Steuber');
INSERT INTO public."RejectReason" VALUES ('d3a1cc14-40aa-59e8-97a6-43837e7f4537', 'Elisabeth Pacocha');
INSERT INTO public."RejectReason" VALUES ('7d8b3763-336a-5dd5-a8b6-1cc96db870f4', 'Alexandre Fahey');
INSERT INTO public."RejectReason" VALUES ('713fd983-aee0-5793-a10e-49d02d96d189', 'Belle Sauer');
INSERT INTO public."RejectReason" VALUES ('e09ca46f-cfb3-5273-b4fa-11122d5084ee', 'Lindsay Braun');
INSERT INTO public."RejectReason" VALUES ('3bb116a2-7365-5854-a1c3-b26deb1e4a2d', 'Jerrold Reinger');
INSERT INTO public."RejectReason" VALUES ('84ac98af-76e9-5f71-b83e-ccc8144b966e', 'Kali Schroeder');
INSERT INTO public."RejectReason" VALUES ('1ef8332d-b7f3-5f51-ba89-8ab9297822f1', 'Eveline Stokes');
INSERT INTO public."RejectReason" VALUES ('5af74a79-9f32-50d6-ac56-e491ebbc1b1a', 'Kole Denesik');


--
-- TOC entry 4262 (class 0 OID 2149016)
-- Dependencies: 254
-- Data for Name: ReturnMethod; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."ReturnMethod" VALUES ('c958ff5c-06b4-5620-9a8b-1fd4dd9e5f72', 'Greta O''Connell');
INSERT INTO public."ReturnMethod" VALUES ('825ed0ac-da79-5cbc-8501-90640ef99ddc', 'Aliya Morissette');
INSERT INTO public."ReturnMethod" VALUES ('424b43ba-fa3f-5f99-ba6b-fba20d7078e4', 'Jarvis Schultz');
INSERT INTO public."ReturnMethod" VALUES ('8bfb4fea-4430-5105-a062-fda38247deb2', 'Edyth Beer');
INSERT INTO public."ReturnMethod" VALUES ('c9e28d8c-cf5d-51ad-91ee-c76424891868', 'Carlos Brown');
INSERT INTO public."ReturnMethod" VALUES ('66678e7e-a6f8-54c9-b53f-8e8cf9c469bd', 'Stone Bashirian');
INSERT INTO public."ReturnMethod" VALUES ('104e31a6-f30c-59f4-8ab0-d99d0f1bd15e', 'Merritt Wiegand');
INSERT INTO public."ReturnMethod" VALUES ('e876981c-e250-5391-bd5d-842c9eefb2a6', 'Hyman Wehner');
INSERT INTO public."ReturnMethod" VALUES ('f05135d6-e496-537c-b123-262a64324759', 'Tremaine Luettgen');
INSERT INTO public."ReturnMethod" VALUES ('e01633c8-b282-5ef8-86ba-de0b9d8ade12', 'Karianne Harris');
INSERT INTO public."ReturnMethod" VALUES ('3ece7fc8-f5f0-5cd6-bbd6-61eb5aa46f84', 'Jamaal Volkman');
INSERT INTO public."ReturnMethod" VALUES ('6a260acb-1418-544a-9b93-9de52e03bf06', 'Elvie Metz');
INSERT INTO public."ReturnMethod" VALUES ('3bd5a23e-442a-58ee-b719-e70c2802191a', 'Lucius Mayer');
INSERT INTO public."ReturnMethod" VALUES ('13022749-8eae-5cee-820f-8e1d760d214c', 'Reina Barton');
INSERT INTO public."ReturnMethod" VALUES ('78baa511-cfc0-59f2-ac33-1e3c84f83c30', 'Mallory Brown');
INSERT INTO public."ReturnMethod" VALUES ('d7a7db5d-583a-5dd2-ba1d-77d7cb73ee82', 'Beau MacGyver');
INSERT INTO public."ReturnMethod" VALUES ('0cb87ba4-a01e-5360-a714-fe1d4e8acd0c', 'Brennan Howe');
INSERT INTO public."ReturnMethod" VALUES ('1479967d-5cf2-5614-a8f0-f206ff721796', 'Hobart Rempel');
INSERT INTO public."ReturnMethod" VALUES ('dab4e707-acdc-5f5c-9d38-dc26c0e73201', 'Harold Corkery');
INSERT INTO public."ReturnMethod" VALUES ('e9a35826-cfd2-5348-b110-c1168278bd87', 'Belle Lowe');
INSERT INTO public."ReturnMethod" VALUES ('d3f24d83-d206-5d7b-a729-737f2f0274f5', 'Frederick Bahringer');
INSERT INTO public."ReturnMethod" VALUES ('c9e60005-d76e-55b4-aea1-7958bb506f00', 'Tristin Dicki');
INSERT INTO public."ReturnMethod" VALUES ('12e7536e-858a-5b89-a8e4-f4f3223b129a', 'Juliet Daniel');
INSERT INTO public."ReturnMethod" VALUES ('aa15d5e5-5535-5b00-86af-069a1c77049f', 'Mckenna Nader');
INSERT INTO public."ReturnMethod" VALUES ('670373e0-940d-5c51-96fa-b431fc37911f', 'Christian Klocko');
INSERT INTO public."ReturnMethod" VALUES ('ea878497-d83e-520e-943c-1ba00463a3b0', 'Toni Howe');
INSERT INTO public."ReturnMethod" VALUES ('f0c15117-13e3-528e-9a78-af8cbcc3bae9', 'Sheldon Feeney');
INSERT INTO public."ReturnMethod" VALUES ('e2f562ec-5e01-5c9a-99c8-bef3cd9cb0db', 'Karine Lowe');
INSERT INTO public."ReturnMethod" VALUES ('b7aab42e-5e15-5f1f-a76a-95c43fad2e80', 'Sabina Yost');
INSERT INTO public."ReturnMethod" VALUES ('b9cf9c9d-a380-5878-aa9b-dde6a8beb948', 'Sebastian Will');
INSERT INTO public."ReturnMethod" VALUES ('78726044-eb00-547d-8ffb-3966b721132e', 'Justen Crooks');
INSERT INTO public."ReturnMethod" VALUES ('7a26e82a-424f-5b5a-90ac-c0c8d913c879', 'May Bruen');
INSERT INTO public."ReturnMethod" VALUES ('18a262ec-e7f8-5337-af68-7cd704574eed', 'Rubie Lindgren');
INSERT INTO public."ReturnMethod" VALUES ('a2ec80b0-34c5-5b7f-86eb-9a45a33c3b18', 'Bennett Collins');
INSERT INTO public."ReturnMethod" VALUES ('cc645a72-f213-594b-8c07-3aa3cbbf9833', 'Elmer Boyle');
INSERT INTO public."ReturnMethod" VALUES ('a146b0d2-81be-5b9b-9275-22d348bb6016', 'Henderson Jast');
INSERT INTO public."ReturnMethod" VALUES ('46172bb6-f02c-50f9-8a6c-a7b5b954e58d', 'Lilian Mayer');
INSERT INTO public."ReturnMethod" VALUES ('d919f6e7-3289-5b21-8af3-9d530a1785fb', 'Stephen Cummings');
INSERT INTO public."ReturnMethod" VALUES ('0093bd69-4f00-5662-921b-a1a7933c43fa', 'Horace Hamill');
INSERT INTO public."ReturnMethod" VALUES ('12d66da7-3e61-5f56-b402-cb142f43f329', 'Sydney Blanda');
INSERT INTO public."ReturnMethod" VALUES ('c0b50dd5-d0c2-5d65-ada2-70bc2ded4003', 'Tabitha Zemlak');
INSERT INTO public."ReturnMethod" VALUES ('5091f9a5-81fe-5514-bc35-dd9726530358', 'Loyal Kuhlman');
INSERT INTO public."ReturnMethod" VALUES ('c247b70f-6290-5ce3-9dc9-c0ca93bcffae', 'Norene Cartwright');
INSERT INTO public."ReturnMethod" VALUES ('c7568763-febf-5bb0-a6b5-2f4f312916d3', 'Hillard Weissnat');
INSERT INTO public."ReturnMethod" VALUES ('f590b276-2f34-55eb-82fc-3d7b05faec46', 'Brent Rohan');
INSERT INTO public."ReturnMethod" VALUES ('c938fa73-c6ca-5699-a1e5-117b1d50f102', 'Robbie Terry');
INSERT INTO public."ReturnMethod" VALUES ('25697bfd-ecb1-5b67-8e6b-59bfcc86e153', 'Tomasa Keebler');
INSERT INTO public."ReturnMethod" VALUES ('af05e0c7-85a6-56de-bf71-87b4ce783c78', 'Dedric Pacocha');
INSERT INTO public."ReturnMethod" VALUES ('fdbc312a-cd7f-5be0-95bd-153bb62456b9', 'Hortense Sipes');
INSERT INTO public."ReturnMethod" VALUES ('27421f65-693f-5bf3-a3ff-909824e51fa8', 'Lavon Moen');
INSERT INTO public."ReturnMethod" VALUES ('21bbcbc2-18fb-508c-a5a6-5920636fe0ba', 'Beulah Gorczany');
INSERT INTO public."ReturnMethod" VALUES ('11e7a665-5432-571d-bcda-38bfeb9d2fc7', 'Zack Carter');
INSERT INTO public."ReturnMethod" VALUES ('0a3a6182-1f2d-5701-b1d5-87c3be16e112', 'Caleb Blick');
INSERT INTO public."ReturnMethod" VALUES ('79ebdddb-90e6-508c-be3b-a086485ebd4c', 'Leonard Reichert');
INSERT INTO public."ReturnMethod" VALUES ('6dfe6f4e-184d-5454-bb8a-2b2141088e9b', 'Jo DuBuque');
INSERT INTO public."ReturnMethod" VALUES ('7d98c30c-69ed-5a97-b653-6e2c23a27497', 'Gail Goyette');
INSERT INTO public."ReturnMethod" VALUES ('8aeb9109-79b5-5d9e-8f41-14afb4f3aee5', 'Velma Howell');
INSERT INTO public."ReturnMethod" VALUES ('2c7c2f60-120e-51ca-ae07-d4e2ef12df31', 'Triston Pfannerstill');
INSERT INTO public."ReturnMethod" VALUES ('8dbffc7e-118a-58b5-864f-bfe783009efd', 'Bud Botsford');
INSERT INTO public."ReturnMethod" VALUES ('c0636147-dc9b-59a0-abb5-246903da5db3', 'Anna Heathcote');
INSERT INTO public."ReturnMethod" VALUES ('8500626b-a5f0-5cec-a427-ac6079864168', 'Marlin Kunze');
INSERT INTO public."ReturnMethod" VALUES ('e6779efb-1278-5a43-a6e3-4cff09c47ffe', 'Santina Gutmann');
INSERT INTO public."ReturnMethod" VALUES ('b624980e-d89f-525c-9be4-474d06f74be3', 'Edythe Koss');
INSERT INTO public."ReturnMethod" VALUES ('a9687943-3682-5756-85db-e569a0192958', 'Francis Will');
INSERT INTO public."ReturnMethod" VALUES ('26a98d71-e755-570a-a43a-6ea22397ce25', 'Tara Champlin');
INSERT INTO public."ReturnMethod" VALUES ('24e048c4-544b-50b6-9eb1-675e2542d87a', 'Vivien Douglas');
INSERT INTO public."ReturnMethod" VALUES ('cfd6d445-5dee-5271-98a6-55573d70ccad', 'Susan Armstrong');
INSERT INTO public."ReturnMethod" VALUES ('6ba0bead-6533-58d0-9117-c29bf652d566', 'Francesca Kuhn');
INSERT INTO public."ReturnMethod" VALUES ('540f64e0-a2ee-52c1-b363-7b765c546f2e', 'Kirstin Batz');
INSERT INTO public."ReturnMethod" VALUES ('ae305a53-aed6-5832-81b5-8bc754ce74ec', 'Sonia Moen');
INSERT INTO public."ReturnMethod" VALUES ('ce4ac39a-bbfb-533a-87cd-0fc7f105bd88', 'Euna Gusikowski');
INSERT INTO public."ReturnMethod" VALUES ('9c4ed981-b54c-54e3-bbc6-dea2137a1787', 'Dale Jerde');
INSERT INTO public."ReturnMethod" VALUES ('8867102c-5a2b-5981-a1e4-0e338bfa7153', 'Julio Kohler');
INSERT INTO public."ReturnMethod" VALUES ('5277edfe-8b0d-5e9a-bf13-fa06e44fbcf9', 'Corine Abernathy');
INSERT INTO public."ReturnMethod" VALUES ('3d9a072d-e1a6-5c31-8fba-c11a979e0326', 'Selena Mueller');
INSERT INTO public."ReturnMethod" VALUES ('e927a765-b476-5710-8553-1766774fe6ac', 'Randy Klein');
INSERT INTO public."ReturnMethod" VALUES ('4618f004-8f6c-50b2-9628-b4433588ad10', 'Isabella Ratke');
INSERT INTO public."ReturnMethod" VALUES ('9629d576-5c7f-57ee-9ea6-4cbd1dff0f03', 'Aglae Hauck');
INSERT INTO public."ReturnMethod" VALUES ('95e7e44d-27eb-5b25-bf3b-c788e1229bed', 'Beverly Koss');
INSERT INTO public."ReturnMethod" VALUES ('8319d8af-0b23-5f94-a885-7d6b4de777b2', 'Casper Jakubowski');
INSERT INTO public."ReturnMethod" VALUES ('f1f8b5b8-798e-584e-b9b4-a2f9e5bafb4f', 'Godfrey Wehner');
INSERT INTO public."ReturnMethod" VALUES ('7210fe20-4969-5a6b-8de3-d03e4c7462fb', 'Baby Rosenbaum');
INSERT INTO public."ReturnMethod" VALUES ('6cf426c7-520d-52fe-bab3-b63f6217e814', 'Myriam Schinner');
INSERT INTO public."ReturnMethod" VALUES ('b5675f1a-33a8-5126-b83b-8eac8029b5ea', 'Jordan Paucek');
INSERT INTO public."ReturnMethod" VALUES ('cd6fc76c-f2f9-5a28-ae7b-07306d3bcb3c', 'Joaquin Quitzon');
INSERT INTO public."ReturnMethod" VALUES ('39bfccfa-ba8b-5bd1-8e10-0cc58849d279', 'Martin Vandervort');
INSERT INTO public."ReturnMethod" VALUES ('71cdd442-f0b3-5d10-98be-e32ed99c0004', 'Hiram Pacocha');
INSERT INTO public."ReturnMethod" VALUES ('6ef8ec4c-2b5c-5874-9d80-cae58174189f', 'Irwin Willms');
INSERT INTO public."ReturnMethod" VALUES ('9f8ae2af-d823-5a6e-acfb-ef4888a5a25e', 'Jolie Walker');
INSERT INTO public."ReturnMethod" VALUES ('93dc75a0-cfd8-536a-8671-3c2a438d737d', 'Jerrell Brakus');
INSERT INTO public."ReturnMethod" VALUES ('59f28f30-b6d3-5ba3-96ac-1ce5d0fa2d6f', 'Lenora Runolfsdottir');
INSERT INTO public."ReturnMethod" VALUES ('8e41dbb2-6079-57e9-a99a-494852683924', 'Verdie Macejkovic');
INSERT INTO public."ReturnMethod" VALUES ('655ebc5d-9116-5105-bf40-696f5c6313a8', 'Lora Orn');
INSERT INTO public."ReturnMethod" VALUES ('74c1de09-f282-5324-a738-a2f56d1ec446', 'Braxton Ernser');
INSERT INTO public."ReturnMethod" VALUES ('4d6840dc-9d22-5b65-b4d1-56c1e4d9fe60', 'Christopher Swift');
INSERT INTO public."ReturnMethod" VALUES ('a8dfb170-a54b-5900-a738-c32946fa0c1e', 'Greyson Wiegand');
INSERT INTO public."ReturnMethod" VALUES ('0726f6a1-a187-5ea0-8e57-0949d24759c4', 'Ayana Rodriguez');
INSERT INTO public."ReturnMethod" VALUES ('ccc8ff2c-3a54-5b54-9134-32b84ccfaab2', 'Allie Quigley');
INSERT INTO public."ReturnMethod" VALUES ('283fb5e8-543e-5c6f-8e2b-b6372c839c9e', 'Nathen Torphy');
INSERT INTO public."ReturnMethod" VALUES ('04bd82e8-78a7-50e0-91bc-705404bcf686', 'Karine Hermiston');


--
-- TOC entry 4263 (class 0 OID 2149021)
-- Dependencies: 255
-- Data for Name: ReturnReason; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."ReturnReason" VALUES ('fd6d3f66-79e7-5e94-af84-5e7ab00ebaeb', 'Eva Turcotte');
INSERT INTO public."ReturnReason" VALUES ('170b074f-3f6a-5cbc-b502-fcace76d7159', 'Jaren Weissnat');
INSERT INTO public."ReturnReason" VALUES ('291ce61e-d661-5436-98cf-574e53a9dd86', 'Karianne Corkery');
INSERT INTO public."ReturnReason" VALUES ('cb260ab9-e6f0-568b-b28d-d6aa3325b7ac', 'Cheyenne Abshire');
INSERT INTO public."ReturnReason" VALUES ('841282a2-7c3e-59d1-bfb4-e4816af23db3', 'Thelma Nitzsche');
INSERT INTO public."ReturnReason" VALUES ('6c83541d-43be-5932-bc7a-8e5182896e6e', 'Margarette Herzog');
INSERT INTO public."ReturnReason" VALUES ('845da2fc-564f-5937-a41f-00d5200462ce', 'Corbin Carter');
INSERT INTO public."ReturnReason" VALUES ('4d0e14de-6719-542e-ac92-232827795f76', 'Nicola Dare');
INSERT INTO public."ReturnReason" VALUES ('4bac9e7c-7a64-58d4-9f2d-11d818732c7c', 'Lucy Heller');
INSERT INTO public."ReturnReason" VALUES ('cc0a5125-d92a-520a-89d3-ff679649e55f', 'Bridget Harber');
INSERT INTO public."ReturnReason" VALUES ('a172edad-05ff-5393-910a-ecc96998e925', 'Lambert Schmeler');
INSERT INTO public."ReturnReason" VALUES ('cc7bf6fe-4441-5022-9a07-aa020d1f274d', 'Noe Nader');
INSERT INTO public."ReturnReason" VALUES ('f0699e3d-2834-59be-ac5d-103c321c8a92', 'Wiley Moore');
INSERT INTO public."ReturnReason" VALUES ('1efb9f9e-57e1-5605-9f00-aea8d1399be3', 'Charley Orn');
INSERT INTO public."ReturnReason" VALUES ('91bd9bef-8786-53ee-9bf7-e9155ff4f9c0', 'Cleve Lang');
INSERT INTO public."ReturnReason" VALUES ('6c3dfd62-8b24-5d80-9068-2eb281142ace', 'Rafaela Leffler');
INSERT INTO public."ReturnReason" VALUES ('08b7e26c-7699-5fde-a14a-03f739f24658', 'Selena Monahan');
INSERT INTO public."ReturnReason" VALUES ('8dabe2d3-9b6b-5fb8-ae72-70796c62f4e3', 'Abdullah Schumm');
INSERT INTO public."ReturnReason" VALUES ('a7323318-cf63-5d65-9310-52a5ec4f16b6', 'Nedra Anderson');
INSERT INTO public."ReturnReason" VALUES ('3f8da1c9-9fc6-58b8-943f-8cbebb81fcbd', 'Delphine Douglas');
INSERT INTO public."ReturnReason" VALUES ('49fce493-2b39-5583-a709-fe960eaf9f12', 'Waldo Jacobson');
INSERT INTO public."ReturnReason" VALUES ('6e62f5f9-6bef-5943-88a7-0497080c5a77', 'Keanu Murazik');
INSERT INTO public."ReturnReason" VALUES ('b6d28d66-259f-500f-80b0-3e9ab04f3e70', 'Name Volkman');
INSERT INTO public."ReturnReason" VALUES ('4ba4da30-5797-5b74-a6c3-54539cd5c0fa', 'Rachael Smith');
INSERT INTO public."ReturnReason" VALUES ('1910b283-cbe2-5687-a471-fdea3d1cd84c', 'Jacinto Quitzon');
INSERT INTO public."ReturnReason" VALUES ('aa7c5b45-7aa7-58ce-b230-48e78573aeb7', 'Leanne Wehner');
INSERT INTO public."ReturnReason" VALUES ('c8ceccf9-bd3c-5fff-82a1-0b520b94fe15', 'Emmett Watsica');
INSERT INTO public."ReturnReason" VALUES ('f427f96a-55fc-53c6-9f14-d4c384631e59', 'Maximillia Koss');
INSERT INTO public."ReturnReason" VALUES ('0302aef6-42c1-52f2-87c7-efb17567cf53', 'Jessica Abshire');
INSERT INTO public."ReturnReason" VALUES ('fec516f1-13b4-5bee-b96a-9dd2c58c85fe', 'Terry Daugherty');
INSERT INTO public."ReturnReason" VALUES ('f44dc261-322d-5d4c-aa49-e1360a487373', 'Leonel Goodwin');
INSERT INTO public."ReturnReason" VALUES ('edc9f1ab-5a66-59b9-b000-7733c367bf01', 'Hassie Stamm');
INSERT INTO public."ReturnReason" VALUES ('59b1a048-d32a-5220-9195-48f35c06a801', 'Ivory Moen');
INSERT INTO public."ReturnReason" VALUES ('cc4a5296-30a1-5194-a23a-3371ba09c7b9', 'Hassie Abernathy');
INSERT INTO public."ReturnReason" VALUES ('05488e72-a7a0-5737-93e3-467145a609f0', 'Alejandrin Roob');
INSERT INTO public."ReturnReason" VALUES ('0238e84b-18d9-51b0-bd7b-6a4de12fb7e1', 'Teresa Berge');
INSERT INTO public."ReturnReason" VALUES ('f8f1634a-abfa-5e69-932b-47c8fa8841bd', 'Pascale Flatley');
INSERT INTO public."ReturnReason" VALUES ('b4ee98c5-c867-56be-84f5-7879e7f3b812', 'Euna Harris');
INSERT INTO public."ReturnReason" VALUES ('5f84c860-6b7e-50be-b27f-62d1836325e7', 'Nova Kilback');
INSERT INTO public."ReturnReason" VALUES ('e164abd0-ca96-5fc0-86fa-18dcb42b22d6', 'Arvid Willms');
INSERT INTO public."ReturnReason" VALUES ('8a714ed2-7f4f-585b-be37-229198333759', 'Gerardo Harber');
INSERT INTO public."ReturnReason" VALUES ('d1d2f2c9-f127-5891-854c-75abfa403967', 'Kenton Hessel');
INSERT INTO public."ReturnReason" VALUES ('88598886-ccf5-51d9-b626-0170f5eab028', 'Kayla Emard');
INSERT INTO public."ReturnReason" VALUES ('a657b069-56fc-5aef-a9f7-d50d2a3642ba', 'Hosea Buckridge');
INSERT INTO public."ReturnReason" VALUES ('7f1cbdd1-6335-5a0d-8afa-22db0c05385e', 'Robyn Ankunding');
INSERT INTO public."ReturnReason" VALUES ('7372df45-13f4-53c1-8969-b1808999e720', 'Ernestina Dicki');
INSERT INTO public."ReturnReason" VALUES ('4928961a-85ca-5ab1-ab8f-eb8a2f082186', 'Sienna Sipes');
INSERT INTO public."ReturnReason" VALUES ('567f9a50-c185-5db1-894a-5b27d0d66d39', 'Marcellus Kihn');
INSERT INTO public."ReturnReason" VALUES ('bc94489b-6281-542c-9161-e2a6d9da0d84', 'Jayda Kerluke');
INSERT INTO public."ReturnReason" VALUES ('6e76165b-bf29-5c6e-b52c-5563d3db4e6a', 'Celestino Pacocha');
INSERT INTO public."ReturnReason" VALUES ('5144e096-860b-57df-82f9-4de70d5911be', 'Malcolm Bernier');
INSERT INTO public."ReturnReason" VALUES ('1757c8ed-0a4a-505f-893f-9674e81fc372', 'Colby Davis');
INSERT INTO public."ReturnReason" VALUES ('b4a00a32-cbc3-501c-92bb-21877650b25e', 'Barry Franey');
INSERT INTO public."ReturnReason" VALUES ('2aad709a-c9db-5569-81a5-ada55ba806b9', 'Lonnie Langworth');
INSERT INTO public."ReturnReason" VALUES ('60d168b4-5728-5e0b-a7ed-769336d46810', 'Moises Huel');
INSERT INTO public."ReturnReason" VALUES ('b88aa7eb-c48c-581b-9597-a1f8509f08f3', 'Eloy Ondricka');
INSERT INTO public."ReturnReason" VALUES ('dfd06367-f963-59bf-8005-edd1dcdac495', 'Bryce O''Kon');
INSERT INTO public."ReturnReason" VALUES ('f971eaad-55d5-5879-b2ae-557c5d989c42', 'Marcus Lebsack');
INSERT INTO public."ReturnReason" VALUES ('734ace26-c9f4-5cfd-b801-0ccbf834ed45', 'Lizzie Parisian');
INSERT INTO public."ReturnReason" VALUES ('4d386949-b34f-5bf6-bedb-06bc228f6308', 'Marlen Daniel');
INSERT INTO public."ReturnReason" VALUES ('13941701-0d41-5a90-934d-4f6348fdc644', 'Carmen Towne');
INSERT INTO public."ReturnReason" VALUES ('b1b9e96c-9b86-5fb8-992d-2b959b8d47e9', 'Judge Yundt');
INSERT INTO public."ReturnReason" VALUES ('09bc7105-9e4e-53a6-ba8f-ea478bd64c42', 'Evelyn Runolfsson');
INSERT INTO public."ReturnReason" VALUES ('85cb72de-f92c-59c9-93d2-5d9aec5a766e', 'Haskell Trantow');
INSERT INTO public."ReturnReason" VALUES ('c8f984ef-e29b-5f19-a6b7-77d2af76ae2d', 'Emmet Klein');
INSERT INTO public."ReturnReason" VALUES ('40e47223-4490-5aff-a54c-5401fe09b8f7', 'Chadrick Collins');
INSERT INTO public."ReturnReason" VALUES ('08a1286d-5b99-5897-a25a-5df0e91e2ad3', 'Zackary Collier');
INSERT INTO public."ReturnReason" VALUES ('bd133111-3521-5295-969b-bc55822c13e1', 'Devin McClure');
INSERT INTO public."ReturnReason" VALUES ('6eae6117-b8d3-5bda-871d-fe2a9dd50edf', 'Aubree Lowe');
INSERT INTO public."ReturnReason" VALUES ('fc6b3f27-2bca-511d-926c-4449eef19a52', 'Audie Kilback');
INSERT INTO public."ReturnReason" VALUES ('827c84bc-6fc3-5d34-8a67-410a73bf9d08', 'Nicolas Jones');
INSERT INTO public."ReturnReason" VALUES ('68962856-b4d7-5237-8d16-3cc18b9cd097', 'Morgan Hintz');
INSERT INTO public."ReturnReason" VALUES ('2c9039cc-016c-5d9d-8a73-c5e1007ccc82', 'Leonie Von');
INSERT INTO public."ReturnReason" VALUES ('38604594-a607-5d53-8a06-1b5332f33043', 'Robin Osinski');
INSERT INTO public."ReturnReason" VALUES ('b9229f72-48e5-522e-a5df-3048cabe3f55', 'Christina Zemlak');
INSERT INTO public."ReturnReason" VALUES ('d7b0ab64-6b70-51d6-a58d-24f9b421e945', 'Clementine Schuppe');
INSERT INTO public."ReturnReason" VALUES ('227861dd-4058-55be-adbb-ba0d1432d953', 'Cora Emmerich');
INSERT INTO public."ReturnReason" VALUES ('03bbc6f2-68ba-5ae8-bd86-ffb0beaf7195', 'Lambert Harber');
INSERT INTO public."ReturnReason" VALUES ('4dfc11b2-937b-5186-9e0a-6426f829373f', 'Madelyn Mann');
INSERT INTO public."ReturnReason" VALUES ('06da8e63-a867-5710-8f0c-e3374493d3f3', 'Keaton Kihn');
INSERT INTO public."ReturnReason" VALUES ('d1949932-f0e4-59d8-82ad-572069008893', 'Joanie Bode');
INSERT INTO public."ReturnReason" VALUES ('31a6551d-4fc0-5390-8a3a-748f626c7b92', 'Carolyne Auer');
INSERT INTO public."ReturnReason" VALUES ('a9c3d00d-5699-5598-9089-cd83aa4b7a7c', 'Otho Rath');
INSERT INTO public."ReturnReason" VALUES ('c5534959-2917-5f6b-99d8-396fc5cd09dd', 'Russ Tremblay');
INSERT INTO public."ReturnReason" VALUES ('71694c0a-650e-5b9d-bfdb-7289379a3ed0', 'Adrien Huel');
INSERT INTO public."ReturnReason" VALUES ('45ae167a-3111-5203-b404-2b5976338116', 'Stephanie Lang');
INSERT INTO public."ReturnReason" VALUES ('dd3cc4fc-a14c-553d-962b-db4e817ebe3e', 'Declan Schiller');
INSERT INTO public."ReturnReason" VALUES ('b97e1d50-04d1-5df7-b7aa-e47a1f31a910', 'Bud Gusikowski');
INSERT INTO public."ReturnReason" VALUES ('bd6589ed-e72a-5e6c-b5ee-6414f5c3b59b', 'Citlalli Buckridge');
INSERT INTO public."ReturnReason" VALUES ('6d50ad92-1aac-58e4-b0de-ae785aa57154', 'Matilda Marks');
INSERT INTO public."ReturnReason" VALUES ('c7636245-877e-5a6d-a2e4-6305b7964cc6', 'Brooke Wolf');
INSERT INTO public."ReturnReason" VALUES ('12b61ce5-d02d-520f-9b0e-e538229f5021', 'Conor Bahringer');
INSERT INTO public."ReturnReason" VALUES ('13ee4305-1f36-5242-9b6c-25b69bf4b6d5', 'Dane Raynor');
INSERT INTO public."ReturnReason" VALUES ('cffd3769-ecd0-5c82-a9a4-1e4178e459ad', 'Baby Shields');
INSERT INTO public."ReturnReason" VALUES ('bb1df718-cd71-5c54-8427-ecbf2fc08a0a', 'Mabel Morissette');
INSERT INTO public."ReturnReason" VALUES ('05099de9-9d7f-5918-9adf-65ce3555b8f7', 'Mackenzie Waelchi');
INSERT INTO public."ReturnReason" VALUES ('cde2ab26-da21-5d98-8116-b43e1b2a3a9f', 'Darrion Collins');
INSERT INTO public."ReturnReason" VALUES ('699d5a59-1a86-5836-afba-88500e71d9a5', 'Alexie Turner');
INSERT INTO public."ReturnReason" VALUES ('6880cd73-8276-50c1-b64b-b6d34fdecd93', 'Niko Jast');
INSERT INTO public."ReturnReason" VALUES ('de69e97a-4b68-50e9-89bf-b20653dcd522', 'Bernice Rohan');


--
-- TOC entry 4264 (class 0 OID 2149026)
-- Dependencies: 256
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."User" VALUES ('65e024a7-66e9-5650-bdff-7d2f9838b76a', '2022-09-29 15:06:28.17', '2020-05-05 16:31:56', '2004-05-17 16:18:58', 'Lauretta.Schmidt383@hotmail.com', 'Kira', 'Turcotte', 'RD#Xgijatph2No', false, 'Mira via', 'Kora viayu', 'Viso ramiko', 'Viami sovi', 'Virayu soako', NULL, NULL, NULL, 'Mikovi miko', false, NULL, false, '2012-05-05 17:01:10', NULL, 'Soa ravi viyuvi', NULL, NULL);
INSERT INTO public."User" VALUES ('bbb936a3-337d-5c4b-b7d3-c0af0978209a', '2022-09-29 15:06:28.17', '2020-07-07 18:42:13', '2001-02-22 13:02:31', 'Vanessa.O''Connell104@gmail.com', 'Nicklaus', 'Waelchi', 'vaQp$}B7HFanS', false, 'Koaso sorami', 'Yuamia mikoa', 'Viyumi sovikovi ramiko', 'Korayu soami miko', 'Koayua vira', NULL, NULL, NULL, 'Soyu viyuavi miyumi', false, NULL, false, '2011-04-20 15:58:12', NULL, 'Ramiyu somia yuasovi', NULL, NULL);
INSERT INTO public."User" VALUES ('4348530a-32bd-511d-95d3-bcb54f401b9f', '2022-09-29 15:06:28.17', '2020-04-28 15:55:53', '2010-11-27 22:14:10', 'Zoe_Simonis465@yahoo.com', 'Ines', 'Zulauf', '[C09n@D*!Mq5M', false, 'Miako soyu', 'Koyurami viavi soakoyu', 'Yua yurasora viyuvi', 'Yua yumiayu', 'Yura yuvisora soa', NULL, NULL, NULL, 'Koa yusoa ramira', false, NULL, false, '1983-04-08 03:07:40', NULL, 'Korakoa raviyu soyusora', NULL, NULL);
INSERT INTO public."User" VALUES ('bcca18c3-5e46-56cb-b58b-c74cf16609b1', '2022-09-29 15:06:28.17', '2020-02-02 13:41:21', '2004-05-13 16:05:29', 'Gretchen_Auer701@gmail.com', 'Jan', 'Muller', 's7j2z{RwtBHEjW', false, 'Komiami soyuso', 'Miraso soyukora yuviako', 'Rasovi viami', 'Mikomiso yukoa yuayuso', 'Mikoyu viramiso miyua', NULL, NULL, NULL, 'Yusoako yura', false, NULL, false, '2019-04-24 15:48:01', NULL, 'Rakoviko yuami', NULL, NULL);
INSERT INTO public."User" VALUES ('7aea35aa-5a77-5acf-8161-2fe91b29d3a2', '2022-09-29 15:06:28.17', '2020-04-12 03:55:44', '1996-01-01 00:36:35', 'Bria_Sauer423@yahoo.com', 'Minnie', 'Mayer', 'a{pJdnZh*vq{Y', false, 'Soaso viso', 'Misomiso vira', 'Soyusovi viayua', 'Miravi ravi komirami', 'Koraso rami soa', NULL, NULL, NULL, 'Yumisoyu soavira', false, NULL, false, '1987-12-17 00:03:28', NULL, 'Viyu koa soyuraso', NULL, NULL);
INSERT INTO public."User" VALUES ('73d964ac-98dd-523e-b9de-b4ca4c879ed2', '2022-09-29 15:06:28.17', '2020-06-06 05:07:11', '1982-07-23 18:51:35', 'Estell.Schaden582@gmail.com', 'Melisa', 'Schaden', '[RWAgWc&Xag0', false, 'Mia somi miraso', 'Mikorayu ravi soako', 'Soravi misoa mira', 'Vikoravi yuso', 'Rayuvi via yuakoa', NULL, NULL, NULL, 'Yuviyu komikomi yuaso', false, NULL, false, '2004-01-01 00:30:04', NULL, 'Koyurami yuravi viyuraso', NULL, NULL);
INSERT INTO public."User" VALUES ('5444f259-27c2-5313-bf11-7237b395a1c7', '2022-09-29 15:06:28.17', '2020-07-11 18:34:36', '1995-08-24 08:06:49', 'Telly.Goyette737@gmail.com', 'Lenora', 'Grant', 'C8$5W]y9PR^{', false, 'Ramiaso vikomi', 'Korayumi sora', 'Koyu sorasora somia', 'Yuami yurako', 'Ramiso viaviyu', NULL, NULL, NULL, 'Miyuko yumi visoa', false, NULL, false, '1999-12-28 12:01:54', NULL, 'Ramiko kovirami', NULL, NULL);
INSERT INTO public."User" VALUES ('5185357c-a790-5fc2-8e81-1e3bf79f63d6', '2022-09-29 15:06:28.17', '2020-05-01 04:51:19', '1990-11-19 10:17:53', 'Raleigh_Schiller715@hotmail.com', 'Mariam', 'Hegmann', '4bX$2HY4oBMU', false, 'Korayu sovi kovikoyu', 'Visomiso soa koyu', 'Rami vikoami', 'Somi yuvisovi mira', 'Vikoa rami yusoyu', NULL, NULL, NULL, 'Rami rasoa', false, NULL, false, '1995-12-12 23:43:00', NULL, 'Visoviso koa', NULL, NULL);
INSERT INTO public."User" VALUES ('f66355af-0ba5-5130-a19e-9b3fb66b7971', '2022-09-29 15:06:28.17', '2020-04-12 16:06:00', '2010-03-19 14:59:24', 'Alverta.Daugherty759@hotmail.com', 'Jordan', 'Runte', 'O}%PwW8o3*a#Bh', false, 'Koakovi ravira yura', 'Misoa koravi miyu', 'Yuko yuami miyu', 'Yuviyu yura', 'Kovisoa sovisomi', NULL, NULL, NULL, 'Yuko miyuako soavi', false, NULL, false, '2004-05-05 16:05:14', NULL, 'Viyu yuraso', NULL, NULL);
INSERT INTO public."User" VALUES ('e5941561-c4b9-5933-89cf-48fb7d6d2e60', '2022-09-29 15:06:28.17', '2020-01-09 12:39:46', '1998-03-07 02:41:50', 'Adella_Farrell911@gmail.com', 'Colt', 'Towne', 'X5AE47e1&52R', false, 'Yukovi somi ramiyu', 'Somiyu koviyuvi', 'Soviraso viso rakovia', 'Miraviyu miayua', 'Mikoa soasoa sovikoa', NULL, NULL, NULL, 'Yuvisomi raviako viyuko', false, NULL, false, '2002-03-19 14:12:34', NULL, 'Ravi koakoyu soa', NULL, NULL);


--
-- TOC entry 4265 (class 0 OID 2149035)
-- Dependencies: 257
-- Data for Name: UserRole; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."UserRole" VALUES ('ba781c33-dbf7-5f52-95d8-a187a75ddc21', 'Adolf Collins');


--
-- TOC entry 4266 (class 0 OID 2149040)
-- Dependencies: 258
-- Data for Name: Vendor; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."Vendor" VALUES ('1d765290-e92c-536c-aa07-eb9a75d300eb', 'Heaven Farrell', '3e8ab1b1-1b98-5720-b8d3-87cb16cab992');
INSERT INTO public."Vendor" VALUES ('dd941021-befa-51ba-a812-c42ce48d3ef1', 'Norval Abbott', '71e9ddba-dcfa-5f4f-a27c-d65addb6e793');
INSERT INTO public."Vendor" VALUES ('aba4cfec-d0d4-563f-be97-6a3cf9e7e3e2', 'Ethan Bauch', '84c98fde-0b82-5926-94a0-aee50b495953');
INSERT INTO public."Vendor" VALUES ('686c9685-256b-52c7-b3ce-8643fd4084a0', 'Diego Murazik', '395c83f2-16f0-5bb5-a750-8322e5f0b62f');
INSERT INTO public."Vendor" VALUES ('a3c81085-9317-5822-ba9d-79e7dc5c6624', 'Kenneth Abshire', '3b61a200-06bd-5340-86bc-c8a86cc7960e');
INSERT INTO public."Vendor" VALUES ('7f7ecae9-4060-5a62-8368-e7dcf546fea9', 'Maribel Bogan', 'c1d9dfbc-567e-5401-900e-566234731eac');
INSERT INTO public."Vendor" VALUES ('3f9f5b1f-0b2d-51aa-b870-66e1489a9b3f', 'Virginie Kemmer', 'b93889b9-bf67-5886-9a92-952f4829a0d3');
INSERT INTO public."Vendor" VALUES ('1bc2b9d3-25aa-5c91-ad42-271e901f73aa', 'John Herman', 'd9e33b5a-6d86-54c1-8236-d53bd42844fd');
INSERT INTO public."Vendor" VALUES ('6815db57-9d5f-5081-b425-9022da98b7ad', 'Gregory Huel', 'f2128af7-891f-5077-8e70-d3658c67546a');
INSERT INTO public."Vendor" VALUES ('d6102c1f-c983-535e-b671-8df7015f7d29', 'Vincent Walker', '7cd53cc7-d921-5ede-886a-725549c51acc');
INSERT INTO public."Vendor" VALUES ('1f682d78-1aad-5279-8cbf-46478dac6406', 'Francisca Funk', '8b9ed641-16c3-5c87-8e57-3916b2e3719a');
INSERT INTO public."Vendor" VALUES ('b1d7f40f-46cc-5927-9a3f-488485af295e', 'Penelope Vandervort', '95e12e69-2d5a-5409-97db-0b14da507d7e');
INSERT INTO public."Vendor" VALUES ('932fe36f-5ad2-5c7e-9b41-ca818b9bb469', 'Maryse Upton', '87c68722-eb11-5f1b-8ec1-592e8d2d4ec9');
INSERT INTO public."Vendor" VALUES ('edd5192b-bf2d-5ff1-9950-eefb72c16896', 'Rogelio Schoen', '7b04a205-067f-5606-9faa-3ebba1ece94c');
INSERT INTO public."Vendor" VALUES ('7c2c9147-6463-5eb2-9300-f85849abbe51', 'Zelma Klein', '750fa3dc-8b23-5328-9923-48a791729e88');
INSERT INTO public."Vendor" VALUES ('7f284580-9dd6-5897-9d6e-004d4b5ad91e', 'Maribel Fadel', 'd5a7e546-2024-5449-9fa9-fdc9406c2ad2');
INSERT INTO public."Vendor" VALUES ('054bf806-44c9-533f-99bc-79784ca686d8', 'Enos Corkery', 'dffffbc9-db88-5259-978c-f8c3b8df914a');
INSERT INTO public."Vendor" VALUES ('190a2223-b753-5de8-a943-33f32c4f7d77', 'King Harvey', '6e40a7fa-d15b-51b2-8b19-70a83e97896f');
INSERT INTO public."Vendor" VALUES ('e717b2b7-b09a-5595-b22d-18400ba9c24c', 'Emery Legros', '4208748c-6000-5709-8e7c-68beab7de6fa');
INSERT INTO public."Vendor" VALUES ('02c5afe6-b0c9-5e9d-bd9a-c826b1416faa', 'Orpha Hickle', 'fd7c0148-4a71-53ae-baf2-64456a7f82a5');
INSERT INTO public."Vendor" VALUES ('a0d03a1a-68b2-50e3-8ab9-fea4051bd9e9', 'Leone Beahan', 'a1721ca1-4a33-554c-9694-1d38ed957f02');
INSERT INTO public."Vendor" VALUES ('bed57d9f-e4ed-50c0-b961-19d7dc174065', 'Stevie Gorczany', 'f3796929-25e4-5a09-8aff-348a852a9b07');
INSERT INTO public."Vendor" VALUES ('56cea0fe-409e-5c71-84da-bbcbda3d6e2b', 'Bailey Rogahn', 'f98007be-48d5-5143-8586-1a228a9e089b');
INSERT INTO public."Vendor" VALUES ('a13e103a-8370-5e22-be2c-6460b5a9131f', 'Candida Steuber', 'a921c081-2e38-55dd-b117-4ddd6e1c87da');
INSERT INTO public."Vendor" VALUES ('f88a35bc-3336-5efe-b9f8-37001109e201', 'Carley Zulauf', '0c307829-fa0f-546e-964c-564c816224cc');
INSERT INTO public."Vendor" VALUES ('d2b23aa5-0628-51f6-8b21-bcda19f47244', 'Sarina Tremblay', '35bfa08e-e93f-582c-82b3-2cee372679db');
INSERT INTO public."Vendor" VALUES ('bbcd7a15-35aa-5967-9aa3-bae89c663b1a', 'Celestine Dooley', 'b7204666-c86c-57c3-b083-e14c07008672');
INSERT INTO public."Vendor" VALUES ('de99ea9c-49cc-54ba-92a3-3f3e9ed306d1', 'Mauricio Padberg', 'e643a5f9-fc56-5fc4-a243-39128710d0c6');
INSERT INTO public."Vendor" VALUES ('9a84fcc7-6007-5b19-9aba-0766ff94243a', 'Verlie King', 'e18d0f18-86b7-5b15-b57e-f5babe14c180');
INSERT INTO public."Vendor" VALUES ('abb8327a-7d5a-5d6f-9c83-2f1dd2304080', 'Tara Rath', 'e1037f7e-3c78-5aaa-8865-72e98eb9284b');
INSERT INTO public."Vendor" VALUES ('e2e4fc29-786c-5e23-b412-80f2566922bc', 'Quincy Kohler', '2f664099-0fb1-5e0a-bce7-5808d9ae2790');
INSERT INTO public."Vendor" VALUES ('7a495543-5444-5389-84d5-1baf0b25e757', 'Queenie Collins', '7a323025-b404-576d-adf9-1318ce56e0d3');
INSERT INTO public."Vendor" VALUES ('cfb3a613-2efa-5ac6-97f7-234ae5cc5c84', 'Connor O''Hara', 'aa1c983d-e3ee-5a15-893b-b3c18c02deda');
INSERT INTO public."Vendor" VALUES ('b669d975-ffe7-523c-97e7-e8f243da026a', 'Pearline Renner', 'ab535c65-c524-51b0-987d-27ea506f4975');
INSERT INTO public."Vendor" VALUES ('a63f25f0-2a28-5caf-84ae-7dfbb61de84e', 'Katharina Morissette', '244ccc59-5d22-5963-b2e1-08e282864081');
INSERT INTO public."Vendor" VALUES ('7b105a40-5f8f-5b68-8dfd-368a3ebb7d4d', 'Archibald Boyle', 'eede252b-6b8d-55d6-b456-80bb23fc21c2');
INSERT INTO public."Vendor" VALUES ('575027f0-3baa-5455-94e9-299a678d980e', 'Camren Huel', '29d75f47-1f9e-5d16-b02f-cb39f777c254');
INSERT INTO public."Vendor" VALUES ('b577e67e-de6a-5ea6-97ab-89f00c4389e0', 'Rico Green', '9416608c-7812-5b4a-9e8f-7329cad83c8f');
INSERT INTO public."Vendor" VALUES ('af0c3c33-6a6e-5eae-a782-e092d72e0fdb', 'Jacey Adams', '6045569e-e342-56ee-8125-71ac1ef4fb3d');
INSERT INTO public."Vendor" VALUES ('b8cb0108-c31f-51ed-a883-36189b38854b', 'Derek Jacobi', '3124ff08-786f-572d-a6ca-a979ae0de8d7');
INSERT INTO public."Vendor" VALUES ('0c541129-cfa6-58c2-af62-4c6a0f8c6505', 'Hayley Grady', 'e6d956f0-8365-5249-903c-366dbeb82ba1');
INSERT INTO public."Vendor" VALUES ('2c3c85e3-3fb1-5800-b883-32dd468282de', 'Lesly Feil', '6b9902ac-a431-56db-bda5-75ea0d8afb1d');
INSERT INTO public."Vendor" VALUES ('9f6a51c6-dde4-5476-9773-f9562a88536c', 'Krystel Bernhard', 'c41d538a-e55b-5dcb-816c-f53095192e55');
INSERT INTO public."Vendor" VALUES ('6f5127b7-e99f-5a00-b2c4-f9c13ea78297', 'Andreane Zboncak', 'e5298a2b-d662-53c7-a370-09498de18452');
INSERT INTO public."Vendor" VALUES ('aa316cb6-ce99-550b-b8e3-a91ff59075df', 'Lambert Buckridge', '64f42d54-54e5-548f-8589-7328a82b861f');
INSERT INTO public."Vendor" VALUES ('eec8e4b5-cfd2-5f7e-80bb-2bb980f256b9', 'Cecil Thompson', 'ba723f20-cfbe-5bd6-9ef2-65b7570121dd');
INSERT INTO public."Vendor" VALUES ('dc1cb2c2-7d6d-5960-99ce-f820eca965ed', 'Alysha Runte', '7c7e377c-fb47-503d-b25e-7c18d3bddefe');
INSERT INTO public."Vendor" VALUES ('cba26b1c-3cda-50fa-b577-6b0f3a23cf0b', 'Aletha Sanford', '76cb95af-345a-5f0e-adda-87baf8e4dc9a');
INSERT INTO public."Vendor" VALUES ('89463d5b-2086-5f7e-a931-7660091e19c3', 'Wilfredo Waters', 'ad611e88-3c03-5cc3-9d57-8f2161db4e30');
INSERT INTO public."Vendor" VALUES ('6add7fff-fdae-5fbd-8ff2-e8640d5a0a91', 'Vivian Kunze', 'eda58bd2-fd7a-5c0a-80c4-22e9bb29ae7e');
INSERT INTO public."Vendor" VALUES ('8e9842ab-9cf8-5d4f-b563-4af12664ca64', 'Amir Langworth', '1d3a7b52-c63c-5c28-a39d-ab3c61bc4c6a');
INSERT INTO public."Vendor" VALUES ('de33aa4c-373b-5f29-9a3f-5b8bc9b32353', 'Brando Larson', '503dfe32-b1cb-5610-b8ee-c116c344f243');
INSERT INTO public."Vendor" VALUES ('3ae83820-3fd5-5d9d-983d-48eb28bd93b5', 'Darrin Beer', '95a248e1-7981-519a-a97c-6ce1ea394f18');
INSERT INTO public."Vendor" VALUES ('27db311d-ccbe-5b8f-85cc-862761e2492e', 'Reuben Renner', '4277ead3-df3b-5491-8c2e-e0f121261990');
INSERT INTO public."Vendor" VALUES ('f947eb80-65d0-597c-b140-e04441ab5f0c', 'Cassandra Little', 'eb03e61e-acd5-5ee6-99ca-ace4e129ac0e');
INSERT INTO public."Vendor" VALUES ('30b57a6a-54c0-5a50-8603-749cd396cb3c', 'Rebeka Ward', 'c86d1a7f-2cdb-5177-94a2-124dad526276');
INSERT INTO public."Vendor" VALUES ('3265a1c5-3b33-54f9-8b23-e8c523d760a7', 'Oswald Hirthe', '82744338-44ed-54dd-a10a-7424f2c683ef');
INSERT INTO public."Vendor" VALUES ('3ce6190a-1b9b-5205-928e-7bb77bb7e256', 'Wilfred Corwin', '20466abf-d98e-566a-9694-13403bea5a57');
INSERT INTO public."Vendor" VALUES ('7402fa89-a933-5592-8133-ffef0e430315', 'Stella Beahan', 'dad065a9-d340-5cbf-9cbb-8db4f1928ed5');
INSERT INTO public."Vendor" VALUES ('442f8c19-06c3-52ec-96a8-4e2e05df2c0a', 'Hazel Schamberger', '559f499b-5921-55ad-8fd2-46e1fc985de2');
INSERT INTO public."Vendor" VALUES ('94056f2b-f1fc-5a54-8859-bc2ecb115f35', 'Cesar Von', '5a84d120-54b7-5f39-8f68-9d8beba1a9ed');
INSERT INTO public."Vendor" VALUES ('a1cbf01f-87dc-5894-a837-965b0220fe05', 'Erling Moore', '641b1d78-d55d-5715-a33e-e30e69a2b7f2');
INSERT INTO public."Vendor" VALUES ('ff727945-3ddb-5b14-80cd-304763599bd3', 'Kole Littel', '3a92d44f-39b6-5198-8b71-cb6de6a058e3');
INSERT INTO public."Vendor" VALUES ('0d488d1a-0dda-5fba-b1db-7c29b719db1b', 'Keith Emard', '1a2d7d61-0302-56f1-8fec-4233481ace85');
INSERT INTO public."Vendor" VALUES ('fb2eeaea-0328-5440-8b7a-3e44679a6947', 'Gilbert Emard', '34397bd5-c56a-586a-8690-f049cc02e7e0');
INSERT INTO public."Vendor" VALUES ('4feb1d2f-f8ea-5f9f-a14a-27d9f01851c2', 'Melvina Yundt', 'b8241ac7-c5e0-54db-a08f-94d53378c2bc');
INSERT INTO public."Vendor" VALUES ('ed078d6c-f5d7-5bd8-8cd2-d6c72b7188d6', 'Alessandra D''Amore', '8ba5d3c7-be03-545f-a55a-0dfedb42848f');
INSERT INTO public."Vendor" VALUES ('1b313f25-5692-5b0c-a36c-0d43ca6539e0', 'Makayla Robel', 'fcac02ab-0074-5459-b4d4-1687477fa2db');
INSERT INTO public."Vendor" VALUES ('969449e9-213c-51e5-8268-c467f88f354b', 'Jay Klein', '9fb54a19-5053-5229-82db-bf156981d192');
INSERT INTO public."Vendor" VALUES ('926bc761-8e19-5a13-a508-6882d3fa1ffa', 'Akeem Reichert', '67ba1d50-bf4b-5ce4-b5f4-23f3659a5bfe');
INSERT INTO public."Vendor" VALUES ('b73b9091-b16a-52bb-9df7-b9ce5fffb373', 'Reginald Leffler', '51ca6416-0278-5dde-acf6-ae96c0d2a13e');
INSERT INTO public."Vendor" VALUES ('7f4cb8e7-def8-5c2b-a0de-99c27e1eff8d', 'Ralph Abernathy', '9be597ad-b8c2-5c53-8ba8-71538f4a6a95');
INSERT INTO public."Vendor" VALUES ('cff4bc06-f05e-530f-81fd-056acb1a1b97', 'Maximus Hahn', '119669e3-1d00-5931-ba7b-bc1459f616cc');
INSERT INTO public."Vendor" VALUES ('3728fe72-5749-546f-be94-99ff9f9b5588', 'Mariah Ruecker', '65fe6c01-980b-55b2-8400-01f8619e6bd9');
INSERT INTO public."Vendor" VALUES ('01416630-d440-5f37-b7ba-ee1089ab1f10', 'Talia Kling', 'b6053bad-90a3-5ff3-ba63-2146003b8e25');
INSERT INTO public."Vendor" VALUES ('ef38c113-aacc-5149-a0fb-ed0e15359e0f', 'Bernie Leuschke', 'ebb52e43-46ef-578b-84b2-9a452279706d');
INSERT INTO public."Vendor" VALUES ('d4379534-0788-5587-b3b4-dab78a939e4f', 'Kiana Harvey', '4eebe2e0-087b-52b3-95ef-56799f00e008');
INSERT INTO public."Vendor" VALUES ('972d47f5-255d-51ce-ab87-a7cbfa3e7411', 'Theo O''Connell', '3934ae71-bc78-5f08-ab5d-8fc408737520');
INSERT INTO public."Vendor" VALUES ('73501e4d-4479-5f56-a7cc-490d0683e3a4', 'Josianne Pfeffer', 'b0628f0a-8956-5025-9e82-3ff0c73750b4');
INSERT INTO public."Vendor" VALUES ('106e1aca-9d46-5e28-a4bb-ab3573944931', 'Isac Orn', '09505597-9bf5-50a1-b8fe-5678395f903b');
INSERT INTO public."Vendor" VALUES ('76976a1e-b0e0-5579-95b0-85514f1fe215', 'Emely Rodriguez', 'a21136e0-8263-5e3e-ab18-7aa6b9799ce7');
INSERT INTO public."Vendor" VALUES ('306c0249-ec39-5e0c-928c-24ccf493b387', 'Keon Lockman', 'f5be688e-2b0c-5d09-a3a1-cc0d25d26a00');
INSERT INTO public."Vendor" VALUES ('90c985a1-e301-5bba-9b0c-4e141939c498', 'Maynard Shanahan', '7e838834-03d1-591d-ac43-2973192bfe51');
INSERT INTO public."Vendor" VALUES ('6463f0cd-4530-56f5-b419-f0c09b3785f6', 'Brennon Turner', '54a29b68-3154-554d-b026-89940e1e1868');
INSERT INTO public."Vendor" VALUES ('2ff1bc12-1c96-546b-85cd-72564be29edc', 'Jade Grant', '8153e041-480a-59ca-9431-835a5702c2a4');
INSERT INTO public."Vendor" VALUES ('dd5cb29f-336a-5ae8-9a25-b44916b329a3', 'Ibrahim Johnston', 'd892740e-2534-5f11-823c-456d13c36f59');
INSERT INTO public."Vendor" VALUES ('ff86e30e-761f-51a2-a206-8cfff6525e26', 'Jarod Welch', '9385473a-cc14-5920-85cd-f5ad1929965c');
INSERT INTO public."Vendor" VALUES ('db951117-e48a-5ce9-987c-cc6d6bbdbc9a', 'Alexandro Bergnaum', '9c7b9aea-9474-5a20-bc3f-2cbce851e0f4');
INSERT INTO public."Vendor" VALUES ('21c45b1b-489d-50ff-a73f-798ae1511fa8', 'Greyson Hayes', '8e7a38e8-9f82-5383-ba93-170e6851e9c9');
INSERT INTO public."Vendor" VALUES ('e61a6030-7aee-5f21-88a6-d9c931bcf495', 'Vella Ledner', 'e8f38ad2-8a35-558b-81ab-59d32019d395');
INSERT INTO public."Vendor" VALUES ('830f4796-79aa-5aaa-9b84-f95d70afca9a', 'Hugh Bechtelar', '4ab86e29-52f8-58e0-8d59-c368a9ad3eb0');
INSERT INTO public."Vendor" VALUES ('89aa396b-0059-50c5-a8b8-2fa455b843bc', 'Cornelius Breitenberg', '0b9058c1-75ad-5b6f-b217-93edbb3d6bca');
INSERT INTO public."Vendor" VALUES ('c50094de-9e38-51af-b74d-9810dbdeae8f', 'Otho Littel', 'd00c2110-32c8-5665-92c7-e605ac812515');
INSERT INTO public."Vendor" VALUES ('63867eae-bf2e-5fb9-81c3-9e6cc8d591ab', 'Gussie Daugherty', '0eb8928b-58fc-533a-a402-9b0a3567794a');
INSERT INTO public."Vendor" VALUES ('2c8ec972-7a88-546e-86cc-794b1a72a870', 'Ayana Frami', '1266dd58-4cf6-5ca5-879f-814774b2a50b');
INSERT INTO public."Vendor" VALUES ('20ca03bc-cde2-5aa9-b08b-bee88d1611c2', 'Sigrid Hodkiewicz', 'ce1af3a7-720b-51b4-ac2a-4ec36f76e798');
INSERT INTO public."Vendor" VALUES ('b9d342a4-5ab0-5083-8d4c-43b1cff0ff79', 'Dereck Schiller', 'c8404889-ab86-5c03-9931-e907134a9b07');
INSERT INTO public."Vendor" VALUES ('efbde9ff-d7f6-5b9d-b3f3-40faaae5c124', 'Cathy Hudson', 'feae62cc-98f6-5b4d-adc1-9ca5c5f43440');
INSERT INTO public."Vendor" VALUES ('4db7949c-b310-5ddc-ac98-8f1b83a20d49', 'Otis Lang', 'cdf59d28-974c-5a4f-8c56-e352c32a6cde');
INSERT INTO public."Vendor" VALUES ('e28db3fc-8883-5df6-a144-b9d0aed52d6a', 'Cristian Glover', '73a607c4-14d1-5523-a47c-632ae9777ab3');


--
-- TOC entry 4267 (class 0 OID 2149045)
-- Dependencies: 259
-- Data for Name: _CashFlowToInvoice; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4268 (class 0 OID 2149050)
-- Dependencies: 260
-- Data for Name: _DepositToLocker; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4269 (class 0 OID 2149055)
-- Dependencies: 261
-- Data for Name: _DepositToParcel; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4270 (class 0 OID 2149060)
-- Dependencies: 262
-- Data for Name: _IncidentToOrderItem; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."_IncidentToOrderItem" VALUES ('6bd5d518-3060-5d1c-9bbd-93be52b44bc5', 'e5404071-d1d1-52f8-a2d6-9ac99c2004d6');


--
-- TOC entry 4271 (class 0 OID 2149065)
-- Dependencies: 263
-- Data for Name: _UserToUserRole; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public."_UserToUserRole" VALUES ('e5941561-c4b9-5933-89cf-48fb7d6d2e60', 'ba781c33-dbf7-5f52-95d8-a187a75ddc21');


--
-- TOC entry 4272 (class 0 OID 2149070)
-- Dependencies: 264
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4284 (class 0 OID 0)
-- Dependencies: 240
-- Name: Order_po_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Order_po_seq"', 11, false);


--
-- TOC entry 3854 (class 2606 OID 2149079)
-- Name: Address Address_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Address"
    ADD CONSTRAINT "Address_pkey" PRIMARY KEY (id);


--
-- TOC entry 3856 (class 2606 OID 2149081)
-- Name: CartItem CartItem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CartItem"
    ADD CONSTRAINT "CartItem_pkey" PRIMARY KEY (id);


--
-- TOC entry 3859 (class 2606 OID 2149083)
-- Name: CashFlow CashFlow_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CashFlow"
    ADD CONSTRAINT "CashFlow_pkey" PRIMARY KEY (id);


--
-- TOC entry 3861 (class 2606 OID 2149085)
-- Name: CorreosList CorreosList_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CorreosList"
    ADD CONSTRAINT "CorreosList_pkey" PRIMARY KEY (id);


--
-- TOC entry 3863 (class 2606 OID 2149087)
-- Name: DeliveryAttempt DeliveryAttempt_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DeliveryAttempt"
    ADD CONSTRAINT "DeliveryAttempt_pkey" PRIMARY KEY (id);


--
-- TOC entry 3865 (class 2606 OID 2149089)
-- Name: Deposit Deposit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Deposit"
    ADD CONSTRAINT "Deposit_pkey" PRIMARY KEY (id);


--
-- TOC entry 3867 (class 2606 OID 2149091)
-- Name: Export Export_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Export"
    ADD CONSTRAINT "Export_pkey" PRIMARY KEY (id);


--
-- TOC entry 3873 (class 2606 OID 2149093)
-- Name: IncidentStatus IncidentStatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."IncidentStatus"
    ADD CONSTRAINT "IncidentStatus_pkey" PRIMARY KEY (id);


--
-- TOC entry 3876 (class 2606 OID 2149095)
-- Name: IncidentType IncidentType_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."IncidentType"
    ADD CONSTRAINT "IncidentType_pkey" PRIMARY KEY (id);


--
-- TOC entry 3870 (class 2606 OID 2149097)
-- Name: Incident Incident_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Incident"
    ADD CONSTRAINT "Incident_pkey" PRIMARY KEY (id);


--
-- TOC entry 3883 (class 2606 OID 2149099)
-- Name: InvoiceReport InvoiceReport_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."InvoiceReport"
    ADD CONSTRAINT "InvoiceReport_pkey" PRIMARY KEY (id);


--
-- TOC entry 3886 (class 2606 OID 2149101)
-- Name: InvoiceStatus InvoiceStatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."InvoiceStatus"
    ADD CONSTRAINT "InvoiceStatus_pkey" PRIMARY KEY (id);


--
-- TOC entry 3889 (class 2606 OID 2149103)
-- Name: InvoiceType InvoiceType_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."InvoiceType"
    ADD CONSTRAINT "InvoiceType_pkey" PRIMARY KEY (id);


--
-- TOC entry 3881 (class 2606 OID 2149105)
-- Name: Invoice Invoice_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Invoice"
    ADD CONSTRAINT "Invoice_pkey" PRIMARY KEY (id);


--
-- TOC entry 3894 (class 2606 OID 2149107)
-- Name: LockerEvent LockerEvent_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LockerEvent"
    ADD CONSTRAINT "LockerEvent_pkey" PRIMARY KEY (id);


--
-- TOC entry 3892 (class 2606 OID 2149109)
-- Name: Locker Locker_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Locker"
    ADD CONSTRAINT "Locker_pkey" PRIMARY KEY (id);


--
-- TOC entry 3897 (class 2606 OID 2149111)
-- Name: MailAttachment MailAttachment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MailAttachment"
    ADD CONSTRAINT "MailAttachment_pkey" PRIMARY KEY (id);


--
-- TOC entry 3899 (class 2606 OID 2149113)
-- Name: MailEvent MailEvent_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MailEvent"
    ADD CONSTRAINT "MailEvent_pkey" PRIMARY KEY (id);


--
-- TOC entry 3902 (class 2606 OID 2149115)
-- Name: ManageReturn ManageReturn_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ManageReturn"
    ADD CONSTRAINT "ManageReturn_pkey" PRIMARY KEY (id);


--
-- TOC entry 3904 (class 2606 OID 2149117)
-- Name: Message Message_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Message"
    ADD CONSTRAINT "Message_pkey" PRIMARY KEY (id);


--
-- TOC entry 3912 (class 2606 OID 2149119)
-- Name: OrderItemStatus OrderItemStatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItemStatus"
    ADD CONSTRAINT "OrderItemStatus_pkey" PRIMARY KEY (id);


--
-- TOC entry 3909 (class 2606 OID 2149121)
-- Name: OrderItem OrderItem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_pkey" PRIMARY KEY (id);


--
-- TOC entry 3914 (class 2606 OID 2149123)
-- Name: OrderItemsOnInvoices OrderItemsOnInvoices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItemsOnInvoices"
    ADD CONSTRAINT "OrderItemsOnInvoices_pkey" PRIMARY KEY ("orderItemId", "invoiceId");


--
-- TOC entry 3917 (class 2606 OID 2149125)
-- Name: OrderStatus OrderStatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderStatus"
    ADD CONSTRAINT "OrderStatus_pkey" PRIMARY KEY (id);


--
-- TOC entry 3906 (class 2606 OID 2149127)
-- Name: Order Order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_pkey" PRIMARY KEY (id);


--
-- TOC entry 3923 (class 2606 OID 2149129)
-- Name: ParcelContainer ParcelContainer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ParcelContainer"
    ADD CONSTRAINT "ParcelContainer_pkey" PRIMARY KEY (id);


--
-- TOC entry 3926 (class 2606 OID 2149131)
-- Name: ParcelLocationEvent ParcelLocationEvent_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ParcelLocationEvent"
    ADD CONSTRAINT "ParcelLocationEvent_pkey" PRIMARY KEY (id);


--
-- TOC entry 3919 (class 2606 OID 2149133)
-- Name: Parcel Parcel_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Parcel"
    ADD CONSTRAINT "Parcel_pkey" PRIMARY KEY (id);


--
-- TOC entry 3928 (class 2606 OID 2149135)
-- Name: PaymentCard PaymentCard_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PaymentCard"
    ADD CONSTRAINT "PaymentCard_pkey" PRIMARY KEY (id);


--
-- TOC entry 3931 (class 2606 OID 2149137)
-- Name: PaymentTransaction PaymentTransaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PaymentTransaction"
    ADD CONSTRAINT "PaymentTransaction_pkey" PRIMARY KEY (id);


--
-- TOC entry 3936 (class 2606 OID 2149139)
-- Name: PickupPointEvent PickupPointEvent_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PickupPointEvent"
    ADD CONSTRAINT "PickupPointEvent_pkey" PRIMARY KEY (id);


--
-- TOC entry 3934 (class 2606 OID 2149141)
-- Name: PickupPoint PickupPoint_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PickupPoint"
    ADD CONSTRAINT "PickupPoint_pkey" PRIMARY KEY (id);


--
-- TOC entry 3939 (class 2606 OID 2149143)
-- Name: Platform Platform_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Platform"
    ADD CONSTRAINT "Platform_pkey" PRIMARY KEY (id);


--
-- TOC entry 3946 (class 2606 OID 2149145)
-- Name: ProductSnapshotLog ProductSnapshotLog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductSnapshotLog"
    ADD CONSTRAINT "ProductSnapshotLog_pkey" PRIMARY KEY (id);


--
-- TOC entry 3949 (class 2606 OID 2149147)
-- Name: ProductSnapshotReason ProductSnapshotReason_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductSnapshotReason"
    ADD CONSTRAINT "ProductSnapshotReason_pkey" PRIMARY KEY (id);


--
-- TOC entry 3944 (class 2606 OID 2149149)
-- Name: ProductSnapshot ProductSnapshot_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductSnapshot"
    ADD CONSTRAINT "ProductSnapshot_pkey" PRIMARY KEY (id);


--
-- TOC entry 3942 (class 2606 OID 2149151)
-- Name: Product Product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product"
    ADD CONSTRAINT "Product_pkey" PRIMARY KEY (id);


--
-- TOC entry 3952 (class 2606 OID 2149153)
-- Name: RejectReason RejectReason_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."RejectReason"
    ADD CONSTRAINT "RejectReason_pkey" PRIMARY KEY (id);


--
-- TOC entry 3955 (class 2606 OID 2149155)
-- Name: ReturnMethod ReturnMethod_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ReturnMethod"
    ADD CONSTRAINT "ReturnMethod_pkey" PRIMARY KEY (id);


--
-- TOC entry 3958 (class 2606 OID 2149157)
-- Name: ReturnReason ReturnReason_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ReturnReason"
    ADD CONSTRAINT "ReturnReason_pkey" PRIMARY KEY (id);


--
-- TOC entry 3964 (class 2606 OID 2149159)
-- Name: UserRole UserRole_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UserRole"
    ADD CONSTRAINT "UserRole_pkey" PRIMARY KEY (id);


--
-- TOC entry 3961 (class 2606 OID 2149161)
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (id);


--
-- TOC entry 3967 (class 2606 OID 2149163)
-- Name: Vendor Vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Vendor"
    ADD CONSTRAINT "Vendor_pkey" PRIMARY KEY (id);


--
-- TOC entry 3979 (class 2606 OID 2149165)
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 3857 (class 1259 OID 2149166)
-- Name: CashFlow_concept_date_type_amount_balance_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "CashFlow_concept_date_type_amount_balance_key" ON public."CashFlow" USING btree (concept, date, type, amount, balance);


--
-- TOC entry 3871 (class 1259 OID 2149167)
-- Name: IncidentStatus_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IncidentStatus_name_key" ON public."IncidentStatus" USING btree (name);


--
-- TOC entry 3874 (class 1259 OID 2149168)
-- Name: IncidentType_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IncidentType_name_key" ON public."IncidentType" USING btree (name);


--
-- TOC entry 3868 (class 1259 OID 2149169)
-- Name: Incident_number_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Incident_number_key" ON public."Incident" USING btree (number);


--
-- TOC entry 3884 (class 1259 OID 2149170)
-- Name: InvoiceStatus_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "InvoiceStatus_name_key" ON public."InvoiceStatus" USING btree (name);


--
-- TOC entry 3887 (class 1259 OID 2149171)
-- Name: InvoiceType_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "InvoiceType_name_key" ON public."InvoiceType" USING btree (name);


--
-- TOC entry 3877 (class 1259 OID 2149172)
-- Name: Invoice_invoiceFileHash_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Invoice_invoiceFileHash_key" ON public."Invoice" USING btree ("invoiceFileHash");


--
-- TOC entry 3878 (class 1259 OID 2149173)
-- Name: Invoice_mailAttachmentId_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Invoice_mailAttachmentId_key" ON public."Invoice" USING btree ("mailAttachmentId");


--
-- TOC entry 3879 (class 1259 OID 2149174)
-- Name: Invoice_number_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Invoice_number_key" ON public."Invoice" USING btree (number);


--
-- TOC entry 3890 (class 1259 OID 2149175)
-- Name: Locker_megablokLockerId_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Locker_megablokLockerId_key" ON public."Locker" USING btree ("megablokLockerId");


--
-- TOC entry 3895 (class 1259 OID 2149176)
-- Name: MailAttachment_fileHash_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "MailAttachment_fileHash_key" ON public."MailAttachment" USING btree ("fileHash");


--
-- TOC entry 3900 (class 1259 OID 2149177)
-- Name: ManageReturn_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "ManageReturn_name_key" ON public."ManageReturn" USING btree (name);


--
-- TOC entry 3910 (class 1259 OID 2149178)
-- Name: OrderItemStatus_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "OrderItemStatus_name_key" ON public."OrderItemStatus" USING btree (name);


--
-- TOC entry 3915 (class 1259 OID 2149179)
-- Name: OrderStatus_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "OrderStatus_name_key" ON public."OrderStatus" USING btree (name);


--
-- TOC entry 3907 (class 1259 OID 2149180)
-- Name: Order_po_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Order_po_key" ON public."Order" USING btree (po);


--
-- TOC entry 3921 (class 1259 OID 2149181)
-- Name: ParcelContainer_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "ParcelContainer_name_key" ON public."ParcelContainer" USING btree (name);


--
-- TOC entry 3924 (class 1259 OID 2149182)
-- Name: ParcelLocationEvent_nextEventId_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "ParcelLocationEvent_nextEventId_key" ON public."ParcelLocationEvent" USING btree ("nextEventId");


--
-- TOC entry 3920 (class 1259 OID 2149183)
-- Name: Parcel_trackingNumber_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Parcel_trackingNumber_key" ON public."Parcel" USING btree ("trackingNumber");


--
-- TOC entry 3929 (class 1259 OID 2149184)
-- Name: PaymentCard_redsysIdentifier_userId_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "PaymentCard_redsysIdentifier_userId_key" ON public."PaymentCard" USING btree ("redsysIdentifier", "userId");


--
-- TOC entry 3932 (class 1259 OID 2149185)
-- Name: PickupPoint_megablokInstallationId_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "PickupPoint_megablokInstallationId_key" ON public."PickupPoint" USING btree ("megablokInstallationId");


--
-- TOC entry 3937 (class 1259 OID 2149186)
-- Name: Platform_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Platform_name_key" ON public."Platform" USING btree (name);


--
-- TOC entry 3947 (class 1259 OID 2149187)
-- Name: ProductSnapshotReason_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "ProductSnapshotReason_name_key" ON public."ProductSnapshotReason" USING btree (name);


--
-- TOC entry 3940 (class 1259 OID 2149188)
-- Name: Product_ean_platformId_platformSellerId_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Product_ean_platformId_platformSellerId_key" ON public."Product" USING btree (ean, "platformId", "platformSellerId");


--
-- TOC entry 3950 (class 1259 OID 2149189)
-- Name: RejectReason_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "RejectReason_name_key" ON public."RejectReason" USING btree (name);


--
-- TOC entry 3953 (class 1259 OID 2149190)
-- Name: ReturnMethod_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "ReturnMethod_name_key" ON public."ReturnMethod" USING btree (name);


--
-- TOC entry 3956 (class 1259 OID 2149191)
-- Name: ReturnReason_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "ReturnReason_name_key" ON public."ReturnReason" USING btree (name);


--
-- TOC entry 3962 (class 1259 OID 2149192)
-- Name: UserRole_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "UserRole_name_key" ON public."UserRole" USING btree (name);


--
-- TOC entry 3959 (class 1259 OID 2149193)
-- Name: User_email_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "User_email_key" ON public."User" USING btree (email);


--
-- TOC entry 3965 (class 1259 OID 2149194)
-- Name: Vendor_nif_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Vendor_nif_key" ON public."Vendor" USING btree (nif);


--
-- TOC entry 3968 (class 1259 OID 2149195)
-- Name: _CashFlowToInvoice_AB_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "_CashFlowToInvoice_AB_unique" ON public."_CashFlowToInvoice" USING btree ("A", "B");


--
-- TOC entry 3969 (class 1259 OID 2149710)
-- Name: _CashFlowToInvoice_B_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "_CashFlowToInvoice_B_index" ON public."_CashFlowToInvoice" USING btree ("B");


--
-- TOC entry 3970 (class 1259 OID 2149196)
-- Name: _DepositToLocker_AB_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "_DepositToLocker_AB_unique" ON public."_DepositToLocker" USING btree ("A", "B");


--
-- TOC entry 3971 (class 1259 OID 2149711)
-- Name: _DepositToLocker_B_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "_DepositToLocker_B_index" ON public."_DepositToLocker" USING btree ("B");


--
-- TOC entry 3972 (class 1259 OID 2149197)
-- Name: _DepositToParcel_AB_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "_DepositToParcel_AB_unique" ON public."_DepositToParcel" USING btree ("A", "B");


--
-- TOC entry 3973 (class 1259 OID 2149712)
-- Name: _DepositToParcel_B_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "_DepositToParcel_B_index" ON public."_DepositToParcel" USING btree ("B");


--
-- TOC entry 3974 (class 1259 OID 2149198)
-- Name: _IncidentToOrderItem_AB_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "_IncidentToOrderItem_AB_unique" ON public."_IncidentToOrderItem" USING btree ("A", "B");


--
-- TOC entry 3975 (class 1259 OID 2149713)
-- Name: _IncidentToOrderItem_B_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "_IncidentToOrderItem_B_index" ON public."_IncidentToOrderItem" USING btree ("B");


--
-- TOC entry 3976 (class 1259 OID 2149199)
-- Name: _UserToUserRole_AB_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "_UserToUserRole_AB_unique" ON public."_UserToUserRole" USING btree ("A", "B");


--
-- TOC entry 3977 (class 1259 OID 2149714)
-- Name: _UserToUserRole_B_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "_UserToUserRole_B_index" ON public."_UserToUserRole" USING btree ("B");


--
-- TOC entry 3980 (class 2606 OID 2149200)
-- Name: Address Address_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Address"
    ADD CONSTRAINT "Address_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3981 (class 2606 OID 2149205)
-- Name: CartItem CartItem_productId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CartItem"
    ADD CONSTRAINT "CartItem_productId_fkey" FOREIGN KEY ("productId") REFERENCES public."Product"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3982 (class 2606 OID 2149210)
-- Name: CartItem CartItem_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CartItem"
    ADD CONSTRAINT "CartItem_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3983 (class 2606 OID 2149215)
-- Name: DeliveryAttempt DeliveryAttempt_carrierId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DeliveryAttempt"
    ADD CONSTRAINT "DeliveryAttempt_carrierId_fkey" FOREIGN KEY ("carrierId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3984 (class 2606 OID 2149220)
-- Name: DeliveryAttempt DeliveryAttempt_parcelId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DeliveryAttempt"
    ADD CONSTRAINT "DeliveryAttempt_parcelId_fkey" FOREIGN KEY ("parcelId") REFERENCES public."Parcel"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3985 (class 2606 OID 2149225)
-- Name: Deposit Deposit_cancelledById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Deposit"
    ADD CONSTRAINT "Deposit_cancelledById_fkey" FOREIGN KEY ("cancelledById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3986 (class 2606 OID 2149230)
-- Name: Deposit Deposit_depositedById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Deposit"
    ADD CONSTRAINT "Deposit_depositedById_fkey" FOREIGN KEY ("depositedById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3987 (class 2606 OID 2149235)
-- Name: Deposit Deposit_pickupPointId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Deposit"
    ADD CONSTRAINT "Deposit_pickupPointId_fkey" FOREIGN KEY ("pickupPointId") REFERENCES public."PickupPoint"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3988 (class 2606 OID 2149240)
-- Name: Deposit Deposit_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Deposit"
    ADD CONSTRAINT "Deposit_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3989 (class 2606 OID 2149245)
-- Name: Incident Incident_affectedUserId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Incident"
    ADD CONSTRAINT "Incident_affectedUserId_fkey" FOREIGN KEY ("affectedUserId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3990 (class 2606 OID 2149250)
-- Name: Incident Incident_assigneeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Incident"
    ADD CONSTRAINT "Incident_assigneeId_fkey" FOREIGN KEY ("assigneeId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3991 (class 2606 OID 2149255)
-- Name: Incident Incident_cashFlowId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Incident"
    ADD CONSTRAINT "Incident_cashFlowId_fkey" FOREIGN KEY ("cashFlowId") REFERENCES public."CashFlow"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3992 (class 2606 OID 2149260)
-- Name: Incident Incident_completedById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Incident"
    ADD CONSTRAINT "Incident_completedById_fkey" FOREIGN KEY ("completedById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3993 (class 2606 OID 2149265)
-- Name: Incident Incident_createdById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Incident"
    ADD CONSTRAINT "Incident_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3994 (class 2606 OID 2149270)
-- Name: Incident Incident_incidentStatusId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Incident"
    ADD CONSTRAINT "Incident_incidentStatusId_fkey" FOREIGN KEY ("incidentStatusId") REFERENCES public."IncidentStatus"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3995 (class 2606 OID 2149275)
-- Name: Incident Incident_invoiceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Incident"
    ADD CONSTRAINT "Incident_invoiceId_fkey" FOREIGN KEY ("invoiceId") REFERENCES public."Invoice"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3996 (class 2606 OID 2149280)
-- Name: Incident Incident_orderId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Incident"
    ADD CONSTRAINT "Incident_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES public."Order"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3997 (class 2606 OID 2149285)
-- Name: Incident Incident_parcelId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Incident"
    ADD CONSTRAINT "Incident_parcelId_fkey" FOREIGN KEY ("parcelId") REFERENCES public."Parcel"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3998 (class 2606 OID 2149290)
-- Name: Incident Incident_typeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Incident"
    ADD CONSTRAINT "Incident_typeId_fkey" FOREIGN KEY ("typeId") REFERENCES public."IncidentType"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4007 (class 2606 OID 2149295)
-- Name: InvoiceReport InvoiceReport_invoiceTypeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."InvoiceReport"
    ADD CONSTRAINT "InvoiceReport_invoiceTypeId_fkey" FOREIGN KEY ("invoiceTypeId") REFERENCES public."InvoiceType"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3999 (class 2606 OID 2149300)
-- Name: Invoice Invoice_exportId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Invoice"
    ADD CONSTRAINT "Invoice_exportId_fkey" FOREIGN KEY ("exportId") REFERENCES public."Export"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4000 (class 2606 OID 2149305)
-- Name: Invoice Invoice_invoiceReportId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Invoice"
    ADD CONSTRAINT "Invoice_invoiceReportId_fkey" FOREIGN KEY ("invoiceReportId") REFERENCES public."InvoiceReport"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4001 (class 2606 OID 2149310)
-- Name: Invoice Invoice_invoiceStatusId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Invoice"
    ADD CONSTRAINT "Invoice_invoiceStatusId_fkey" FOREIGN KEY ("invoiceStatusId") REFERENCES public."InvoiceStatus"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4002 (class 2606 OID 2149315)
-- Name: Invoice Invoice_mailAttachmentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Invoice"
    ADD CONSTRAINT "Invoice_mailAttachmentId_fkey" FOREIGN KEY ("mailAttachmentId") REFERENCES public."MailAttachment"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4003 (class 2606 OID 2149320)
-- Name: Invoice Invoice_orderId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Invoice"
    ADD CONSTRAINT "Invoice_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES public."Order"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4004 (class 2606 OID 2149325)
-- Name: Invoice Invoice_primeUserId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Invoice"
    ADD CONSTRAINT "Invoice_primeUserId_fkey" FOREIGN KEY ("primeUserId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4005 (class 2606 OID 2149330)
-- Name: Invoice Invoice_typeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Invoice"
    ADD CONSTRAINT "Invoice_typeId_fkey" FOREIGN KEY ("typeId") REFERENCES public."InvoiceType"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4006 (class 2606 OID 2149335)
-- Name: Invoice Invoice_validatedById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Invoice"
    ADD CONSTRAINT "Invoice_validatedById_fkey" FOREIGN KEY ("validatedById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4009 (class 2606 OID 2149340)
-- Name: LockerEvent LockerEvent_depositId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LockerEvent"
    ADD CONSTRAINT "LockerEvent_depositId_fkey" FOREIGN KEY ("depositId") REFERENCES public."Deposit"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4010 (class 2606 OID 2149345)
-- Name: LockerEvent LockerEvent_lockerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LockerEvent"
    ADD CONSTRAINT "LockerEvent_lockerId_fkey" FOREIGN KEY ("lockerId") REFERENCES public."Locker"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4011 (class 2606 OID 2149350)
-- Name: LockerEvent LockerEvent_pickupPointEventId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LockerEvent"
    ADD CONSTRAINT "LockerEvent_pickupPointEventId_fkey" FOREIGN KEY ("pickupPointEventId") REFERENCES public."PickupPointEvent"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4012 (class 2606 OID 2149355)
-- Name: LockerEvent LockerEvent_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LockerEvent"
    ADD CONSTRAINT "LockerEvent_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4008 (class 2606 OID 2149360)
-- Name: Locker Locker_pickupPointId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Locker"
    ADD CONSTRAINT "Locker_pickupPointId_fkey" FOREIGN KEY ("pickupPointId") REFERENCES public."PickupPoint"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4013 (class 2606 OID 2149365)
-- Name: MailAttachment MailAttachment_mailEventId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MailAttachment"
    ADD CONSTRAINT "MailAttachment_mailEventId_fkey" FOREIGN KEY ("mailEventId") REFERENCES public."MailEvent"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4014 (class 2606 OID 2149370)
-- Name: Message Message_incidentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Message"
    ADD CONSTRAINT "Message_incidentId_fkey" FOREIGN KEY ("incidentId") REFERENCES public."Incident"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4015 (class 2606 OID 2149375)
-- Name: Message Message_orderId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Message"
    ADD CONSTRAINT "Message_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES public."Order"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4016 (class 2606 OID 2149380)
-- Name: Message Message_orderItemId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Message"
    ADD CONSTRAINT "Message_orderItemId_fkey" FOREIGN KEY ("orderItemId") REFERENCES public."OrderItem"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4017 (class 2606 OID 2149385)
-- Name: Message Message_sentById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Message"
    ADD CONSTRAINT "Message_sentById_fkey" FOREIGN KEY ("sentById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4026 (class 2606 OID 2149390)
-- Name: OrderItem OrderItem_cancelledById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_cancelledById_fkey" FOREIGN KEY ("cancelledById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4027 (class 2606 OID 2149395)
-- Name: OrderItem OrderItem_correosListId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_correosListId_fkey" FOREIGN KEY ("correosListId") REFERENCES public."CorreosList"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4028 (class 2606 OID 2149400)
-- Name: OrderItem OrderItem_deliveredById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_deliveredById_fkey" FOREIGN KEY ("deliveredById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4029 (class 2606 OID 2149405)
-- Name: OrderItem OrderItem_exportBackInvoiceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_exportBackInvoiceId_fkey" FOREIGN KEY ("exportBackInvoiceId") REFERENCES public."Invoice"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4030 (class 2606 OID 2149410)
-- Name: OrderItem OrderItem_exportInvoiceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_exportInvoiceId_fkey" FOREIGN KEY ("exportInvoiceId") REFERENCES public."Invoice"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4031 (class 2606 OID 2149415)
-- Name: OrderItem OrderItem_manageReturnId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_manageReturnId_fkey" FOREIGN KEY ("manageReturnId") REFERENCES public."ManageReturn"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4032 (class 2606 OID 2149420)
-- Name: OrderItem OrderItem_orderId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES public."Order"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4033 (class 2606 OID 2149425)
-- Name: OrderItem OrderItem_orderItemStatusId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_orderItemStatusId_fkey" FOREIGN KEY ("orderItemStatusId") REFERENCES public."OrderItemStatus"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4034 (class 2606 OID 2149430)
-- Name: OrderItem OrderItem_parcelId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_parcelId_fkey" FOREIGN KEY ("parcelId") REFERENCES public."Parcel"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4035 (class 2606 OID 2149435)
-- Name: OrderItem OrderItem_productId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_productId_fkey" FOREIGN KEY ("productId") REFERENCES public."Product"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4036 (class 2606 OID 2149440)
-- Name: OrderItem OrderItem_readyForPickupById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_readyForPickupById_fkey" FOREIGN KEY ("readyForPickupById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4037 (class 2606 OID 2149445)
-- Name: OrderItem OrderItem_rejectReasonId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_rejectReasonId_fkey" FOREIGN KEY ("rejectReasonId") REFERENCES public."RejectReason"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4038 (class 2606 OID 2149450)
-- Name: OrderItem OrderItem_replacementOfId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_replacementOfId_fkey" FOREIGN KEY ("replacementOfId") REFERENCES public."OrderItem"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4039 (class 2606 OID 2149455)
-- Name: OrderItem OrderItem_returnMethodId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_returnMethodId_fkey" FOREIGN KEY ("returnMethodId") REFERENCES public."ReturnMethod"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4040 (class 2606 OID 2149460)
-- Name: OrderItem OrderItem_returnReasonId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_returnReasonId_fkey" FOREIGN KEY ("returnReasonId") REFERENCES public."ReturnReason"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4041 (class 2606 OID 2149465)
-- Name: OrderItem OrderItem_returnRequestedById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_returnRequestedById_fkey" FOREIGN KEY ("returnRequestedById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4042 (class 2606 OID 2149470)
-- Name: OrderItem OrderItem_splitFromId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_splitFromId_fkey" FOREIGN KEY ("splitFromId") REFERENCES public."OrderItem"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4043 (class 2606 OID 2149475)
-- Name: OrderItem OrderItem_vendorInvoiceReportId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_vendorInvoiceReportId_fkey" FOREIGN KEY ("vendorInvoiceReportId") REFERENCES public."InvoiceReport"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4044 (class 2606 OID 2149480)
-- Name: OrderItem OrderItem_warehouseById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItem"
    ADD CONSTRAINT "OrderItem_warehouseById_fkey" FOREIGN KEY ("warehouseById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4045 (class 2606 OID 2149485)
-- Name: OrderItemsOnInvoices OrderItemsOnInvoices_invoiceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItemsOnInvoices"
    ADD CONSTRAINT "OrderItemsOnInvoices_invoiceId_fkey" FOREIGN KEY ("invoiceId") REFERENCES public."Invoice"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4046 (class 2606 OID 2149490)
-- Name: OrderItemsOnInvoices OrderItemsOnInvoices_orderItemId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OrderItemsOnInvoices"
    ADD CONSTRAINT "OrderItemsOnInvoices_orderItemId_fkey" FOREIGN KEY ("orderItemId") REFERENCES public."OrderItem"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4018 (class 2606 OID 2149495)
-- Name: Order Order_assigneeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_assigneeId_fkey" FOREIGN KEY ("assigneeId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4019 (class 2606 OID 2149500)
-- Name: Order Order_cancelledById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_cancelledById_fkey" FOREIGN KEY ("cancelledById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4020 (class 2606 OID 2149505)
-- Name: Order Order_markedPaidById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_markedPaidById_fkey" FOREIGN KEY ("markedPaidById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4021 (class 2606 OID 2149510)
-- Name: Order Order_orderStatusId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_orderStatusId_fkey" FOREIGN KEY ("orderStatusId") REFERENCES public."OrderStatus"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4022 (class 2606 OID 2149515)
-- Name: Order Order_paymentCardId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_paymentCardId_fkey" FOREIGN KEY ("paymentCardId") REFERENCES public."PaymentCard"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4023 (class 2606 OID 2149520)
-- Name: Order Order_pickupPointId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_pickupPointId_fkey" FOREIGN KEY ("pickupPointId") REFERENCES public."PickupPoint"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4024 (class 2606 OID 2149525)
-- Name: Order Order_platformId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_platformId_fkey" FOREIGN KEY ("platformId") REFERENCES public."Platform"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4025 (class 2606 OID 2149530)
-- Name: Order Order_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4047 (class 2606 OID 2149535)
-- Name: ParcelContainer ParcelContainer_pickupPointId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ParcelContainer"
    ADD CONSTRAINT "ParcelContainer_pickupPointId_fkey" FOREIGN KEY ("pickupPointId") REFERENCES public."PickupPoint"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4048 (class 2606 OID 2149540)
-- Name: ParcelLocationEvent ParcelLocationEvent_containerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ParcelLocationEvent"
    ADD CONSTRAINT "ParcelLocationEvent_containerId_fkey" FOREIGN KEY ("containerId") REFERENCES public."ParcelContainer"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4049 (class 2606 OID 2149545)
-- Name: ParcelLocationEvent ParcelLocationEvent_createdById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ParcelLocationEvent"
    ADD CONSTRAINT "ParcelLocationEvent_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4050 (class 2606 OID 2149550)
-- Name: ParcelLocationEvent ParcelLocationEvent_nextEventId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ParcelLocationEvent"
    ADD CONSTRAINT "ParcelLocationEvent_nextEventId_fkey" FOREIGN KEY ("nextEventId") REFERENCES public."ParcelLocationEvent"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4051 (class 2606 OID 2149555)
-- Name: ParcelLocationEvent ParcelLocationEvent_parcelId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ParcelLocationEvent"
    ADD CONSTRAINT "ParcelLocationEvent_parcelId_fkey" FOREIGN KEY ("parcelId") REFERENCES public."Parcel"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4052 (class 2606 OID 2149560)
-- Name: PaymentCard PaymentCard_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PaymentCard"
    ADD CONSTRAINT "PaymentCard_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4053 (class 2606 OID 2149565)
-- Name: PaymentTransaction PaymentTransaction_invoiceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PaymentTransaction"
    ADD CONSTRAINT "PaymentTransaction_invoiceId_fkey" FOREIGN KEY ("invoiceId") REFERENCES public."Invoice"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4054 (class 2606 OID 2149570)
-- Name: PaymentTransaction PaymentTransaction_orderId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PaymentTransaction"
    ADD CONSTRAINT "PaymentTransaction_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES public."Order"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4055 (class 2606 OID 2149575)
-- Name: PaymentTransaction PaymentTransaction_paymentCardId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PaymentTransaction"
    ADD CONSTRAINT "PaymentTransaction_paymentCardId_fkey" FOREIGN KEY ("paymentCardId") REFERENCES public."PaymentCard"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4056 (class 2606 OID 2149580)
-- Name: PaymentTransaction PaymentTransaction_primeUserId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PaymentTransaction"
    ADD CONSTRAINT "PaymentTransaction_primeUserId_fkey" FOREIGN KEY ("primeUserId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4058 (class 2606 OID 2149585)
-- Name: PickupPointEvent PickupPointEvent_pickupPointId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PickupPointEvent"
    ADD CONSTRAINT "PickupPointEvent_pickupPointId_fkey" FOREIGN KEY ("pickupPointId") REFERENCES public."PickupPoint"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4059 (class 2606 OID 2149590)
-- Name: PickupPointEvent PickupPointEvent_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PickupPointEvent"
    ADD CONSTRAINT "PickupPointEvent_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4057 (class 2606 OID 2149595)
-- Name: PickupPoint PickupPoint_addressId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PickupPoint"
    ADD CONSTRAINT "PickupPoint_addressId_fkey" FOREIGN KEY ("addressId") REFERENCES public."Address"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4064 (class 2606 OID 2149600)
-- Name: ProductSnapshotLog ProductSnapshotLog_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductSnapshotLog"
    ADD CONSTRAINT "ProductSnapshotLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4061 (class 2606 OID 2149605)
-- Name: ProductSnapshot ProductSnapshot_productId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductSnapshot"
    ADD CONSTRAINT "ProductSnapshot_productId_fkey" FOREIGN KEY ("productId") REFERENCES public."Product"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4062 (class 2606 OID 2149610)
-- Name: ProductSnapshot ProductSnapshot_snapshotReasonId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductSnapshot"
    ADD CONSTRAINT "ProductSnapshot_snapshotReasonId_fkey" FOREIGN KEY ("snapshotReasonId") REFERENCES public."ProductSnapshotReason"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4063 (class 2606 OID 2149615)
-- Name: ProductSnapshot ProductSnapshot_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductSnapshot"
    ADD CONSTRAINT "ProductSnapshot_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4060 (class 2606 OID 2149620)
-- Name: Product Product_platformId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product"
    ADD CONSTRAINT "Product_platformId_fkey" FOREIGN KEY ("platformId") REFERENCES public."Platform"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4065 (class 2606 OID 2149625)
-- Name: User User_defaultBillingAddressId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_defaultBillingAddressId_fkey" FOREIGN KEY ("defaultBillingAddressId") REFERENCES public."Address"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4066 (class 2606 OID 2149630)
-- Name: User User_defaultDeliveryAddressId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_defaultDeliveryAddressId_fkey" FOREIGN KEY ("defaultDeliveryAddressId") REFERENCES public."Address"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4067 (class 2606 OID 2149635)
-- Name: User User_defaultPaymentCardId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_defaultPaymentCardId_fkey" FOREIGN KEY ("defaultPaymentCardId") REFERENCES public."PaymentCard"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4068 (class 2606 OID 2149640)
-- Name: User User_defaultPickupPointId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_defaultPickupPointId_fkey" FOREIGN KEY ("defaultPickupPointId") REFERENCES public."PickupPoint"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4069 (class 2606 OID 2149645)
-- Name: User User_primeBillingAddressId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_primeBillingAddressId_fkey" FOREIGN KEY ("primeBillingAddressId") REFERENCES public."Address"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4070 (class 2606 OID 2149650)
-- Name: User User_primePaymentCardId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_primePaymentCardId_fkey" FOREIGN KEY ("primePaymentCardId") REFERENCES public."PaymentCard"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4071 (class 2606 OID 2149655)
-- Name: User User_worksAtPickupPointId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_worksAtPickupPointId_fkey" FOREIGN KEY ("worksAtPickupPointId") REFERENCES public."PickupPoint"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4072 (class 2606 OID 2149660)
-- Name: _CashFlowToInvoice _CashFlowToInvoice_A_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."_CashFlowToInvoice"
    ADD CONSTRAINT "_CashFlowToInvoice_A_fkey" FOREIGN KEY ("A") REFERENCES public."CashFlow"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4073 (class 2606 OID 2149665)
-- Name: _CashFlowToInvoice _CashFlowToInvoice_B_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."_CashFlowToInvoice"
    ADD CONSTRAINT "_CashFlowToInvoice_B_fkey" FOREIGN KEY ("B") REFERENCES public."Invoice"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4074 (class 2606 OID 2149670)
-- Name: _DepositToLocker _DepositToLocker_A_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."_DepositToLocker"
    ADD CONSTRAINT "_DepositToLocker_A_fkey" FOREIGN KEY ("A") REFERENCES public."Deposit"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4075 (class 2606 OID 2149675)
-- Name: _DepositToLocker _DepositToLocker_B_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."_DepositToLocker"
    ADD CONSTRAINT "_DepositToLocker_B_fkey" FOREIGN KEY ("B") REFERENCES public."Locker"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4076 (class 2606 OID 2149680)
-- Name: _DepositToParcel _DepositToParcel_A_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."_DepositToParcel"
    ADD CONSTRAINT "_DepositToParcel_A_fkey" FOREIGN KEY ("A") REFERENCES public."Deposit"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4077 (class 2606 OID 2149685)
-- Name: _DepositToParcel _DepositToParcel_B_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."_DepositToParcel"
    ADD CONSTRAINT "_DepositToParcel_B_fkey" FOREIGN KEY ("B") REFERENCES public."Parcel"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4078 (class 2606 OID 2149690)
-- Name: _IncidentToOrderItem _IncidentToOrderItem_A_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."_IncidentToOrderItem"
    ADD CONSTRAINT "_IncidentToOrderItem_A_fkey" FOREIGN KEY ("A") REFERENCES public."Incident"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4079 (class 2606 OID 2149695)
-- Name: _IncidentToOrderItem _IncidentToOrderItem_B_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."_IncidentToOrderItem"
    ADD CONSTRAINT "_IncidentToOrderItem_B_fkey" FOREIGN KEY ("B") REFERENCES public."OrderItem"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4080 (class 2606 OID 2149700)
-- Name: _UserToUserRole _UserToUserRole_A_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."_UserToUserRole"
    ADD CONSTRAINT "_UserToUserRole_A_fkey" FOREIGN KEY ("A") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4081 (class 2606 OID 2149705)
-- Name: _UserToUserRole _UserToUserRole_B_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."_UserToUserRole"
    ADD CONSTRAINT "_UserToUserRole_B_fkey" FOREIGN KEY ("B") REFERENCES public."UserRole"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4279 (class 0 OID 0)
-- Dependencies: 8
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


-- Completed on 2023-03-06 13:02:59 SAST

--
-- PostgreSQL database dump complete
--