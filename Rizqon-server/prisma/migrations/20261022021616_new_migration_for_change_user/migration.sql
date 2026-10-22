-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "commerce";

-- CreateEnum
CREATE TYPE "commerce"."role_code" AS ENUM ('OWNER', 'CEO', 'MANAGER', 'BRANCH_MANAGER', 'PRODUCT_MANAGER', 'SECURITY', 'SELLER', 'ACCOUNTANT', 'SELLER_COMPANY_ADMIN');

-- CreateEnum
CREATE TYPE "commerce"."USER_STATUS" AS ENUM ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'DELETED');

-- CreateEnum
CREATE TYPE "commerce"."payment_method_type" AS ENUM ('CARD', 'MOBILE_FINANCIAL_SERVICE', 'BANK_TRANSFER', 'CASH');

-- CreateEnum
CREATE TYPE "commerce"."payment_status" AS ENUM ('PENDING', 'PROCESSING', 'AUTHORIZED', 'SUCCEEDED', 'FAILED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "commerce"."refund_status" AS ENUM ('REQUESTED', 'APPROVED', 'PROCESSING', 'SUCCEEDED', 'FAILED', 'REJECTED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "commerce"."order_channel" AS ENUM ('ONLINE_STORE', 'PHYSICAL_POS', 'SOCIAL_COMMERCE', 'MARKETPLACE');

-- CreateEnum
CREATE TYPE "commerce"."order_status" AS ENUM ('DRAFT', 'PLACED', 'CONFIRMED', 'CANCELLED', 'COMPLETED');

-- CreateEnum
CREATE TYPE "commerce"."collection_channel" AS ENUM ('ONLINE', 'COUNTER', 'CARD_TERMINAL', 'COURIER');

-- CreateEnum
CREATE TYPE "commerce"."collection_timing" AS ENUM ('PREPAID', 'ON_PICKUP', 'ON_DELIVERY', 'ON_ACCOUNT');

-- CreateEnum
CREATE TYPE "commerce"."cash_session_status" AS ENUM ('OPEN', 'CLOSED_PENDING_AUDIT', 'AUDITED_BALANCED', 'DISCREPANCY_FLAGGED');

-- CreateEnum
CREATE TYPE "commerce"."journal_status" AS ENUM ('DRAFT', 'POSTED');

-- CreateEnum
CREATE TYPE "commerce"."scope_type" AS ENUM ('TENANT', 'BRANCH', 'DEPARTMENT', 'LOCATION');

-- CreateEnum
CREATE TYPE "commerce"."cash_movement_type" AS ENUM ('RECEIPT', 'REFUND', 'PAID_IN', 'PAID_OUT', 'DEPOSIT_OUT');

-- CreateEnum
CREATE TYPE "commerce"."ledger_account_type" AS ENUM ('ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE');

-- CreateEnum
CREATE TYPE "commerce"."approval_decision_type" AS ENUM ('APPROVE', 'REJECT');

-- CreateTable
CREATE TABLE "commerce"."ledger_account" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "parent_id" UUID,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "commerce"."ledger_account_type" NOT NULL,
    "currency" VARCHAR(3),
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "ledger_account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."fiscal_period" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "starts_on" DATE NOT NULL,
    "ends_on" DATE NOT NULL,
    "status" TEXT NOT NULL,
    "closed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "fiscal_period_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."journal_entry" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "period_id" UUID NOT NULL,
    "reversal_of_id" UUID,
    "number" TEXT NOT NULL,
    "effective_date" DATE NOT NULL,
    "source_type" TEXT NOT NULL,
    "source_id" TEXT NOT NULL,
    "status" "commerce"."journal_status" NOT NULL DEFAULT 'DRAFT',
    "posted_by" UUID,
    "posted_at" TIMESTAMPTZ(6),
    "description" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "journal_entry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."journal_line" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "entry_id" UUID NOT NULL,
    "account_id" UUID NOT NULL,
    "branch_id" UUID,
    "debit" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "credit" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "currency" VARCHAR(3) NOT NULL,
    "description" TEXT,
    "functional_currency" VARCHAR(3) NOT NULL,
    "functional_debit" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "functional_credit" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "exchange_rate" DECIMAL(24,12) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "journal_line_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."bank_account" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "ledger_account_id" UUID NOT NULL,
    "masked_number" TEXT NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "status" TEXT NOT NULL,
    "institution_name" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "bank_account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."bank_statement_line" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "bank_account_id" UUID NOT NULL,
    "external_reference" TEXT NOT NULL,
    "transaction_date" DATE NOT NULL,
    "amount" DECIMAL(20,4) NOT NULL,
    "description" TEXT,
    "import_batch_reference" TEXT NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "bank_statement_line_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."reconciliation_match" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "statement_line_id" UUID NOT NULL,
    "journal_line_id" UUID NOT NULL,
    "matched_amount" DECIMAL(20,4) NOT NULL,
    "matched_at" TIMESTAMPTZ(6) NOT NULL,
    "matched_by" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "reconciliation_match_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."expense" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "branch_id" UUID,
    "supplier_id" UUID,
    "account_id" UUID NOT NULL,
    "file_id" UUID,
    "amount" DECIMAL(20,4) NOT NULL,
    "tax_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "currency" VARCHAR(3) NOT NULL,
    "status" TEXT NOT NULL,
    "incurred_at" TIMESTAMPTZ(6) NOT NULL,
    "description" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "expense_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."supplier_payment" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "supplier_id" UUID NOT NULL,
    "bank_account_id" UUID,
    "cash_session_id" UUID,
    "amount" DECIMAL(20,4) NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "status" TEXT NOT NULL,
    "reference" TEXT,
    "paid_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "supplier_payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."supplier_payment_allocation" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "payment_id" UUID NOT NULL,
    "invoice_id" UUID NOT NULL,
    "allocated_amount" DECIMAL(20,4) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "supplier_payment_allocation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."analytics_job" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "data_cutoff" TIMESTAMPTZ(6) NOT NULL,
    "status" TEXT NOT NULL,
    "started_at" TIMESTAMPTZ(6),
    "completed_at" TIMESTAMPTZ(6),
    "error_summary" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "analytics_job_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."model_version" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID,
    "name" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "artifact_reference" TEXT NOT NULL,
    "training_data_reference" TEXT NOT NULL,
    "metrics" JSONB NOT NULL,
    "deployed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "model_version_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."demand_forecast" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "location_id" UUID NOT NULL,
    "model_version_id" UUID NOT NULL,
    "generated_at" TIMESTAMPTZ(6) NOT NULL,
    "forecast_date" DATE NOT NULL,
    "predicted_qty" DECIMAL(20,6) NOT NULL,
    "lower_bound" DECIMAL(20,6),
    "upper_bound" DECIMAL(20,6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "demand_forecast_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."business_insight" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "branch_id" UUID,
    "model_version_id" UUID,
    "type" TEXT NOT NULL,
    "evidence_reference" TEXT NOT NULL,
    "explanation" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "generated_at" TIMESTAMPTZ(6) NOT NULL,
    "expires_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "business_insight_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."recommendation_decision" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "insight_id" UUID NOT NULL,
    "decided_by" UUID NOT NULL,
    "decision" TEXT NOT NULL,
    "reason" TEXT,
    "decided_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "recommendation_decision_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."report_job" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "requested_by" UUID NOT NULL,
    "file_id" UUID,
    "type" TEXT NOT NULL,
    "filters" JSONB NOT NULL,
    "data_cutoff" TIMESTAMPTZ(6) NOT NULL,
    "status" TEXT NOT NULL,
    "expires_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "report_job_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."tenant" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "currency" VARCHAR(3) NOT NULL DEFAULT 'BDT',
    "timezone" TEXT NOT NULL DEFAULT 'Asia/Dhaka',
    "legal_name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "default_locale" TEXT NOT NULL DEFAULT 'en',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "tenant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."tenant_setting" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "key" TEXT NOT NULL,
    "value_json" JSONB NOT NULL,
    "config_version" INTEGER NOT NULL DEFAULT 1,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "tenant_setting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."branch" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "address_id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "timezone" TEXT NOT NULL,
    "phone" TEXT,
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "branch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."department" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "branch_id" UUID,
    "parent_id" UUID,
    "name" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "department_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."location" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "branch_id" UUID NOT NULL,
    "parent_id" UUID,
    "type" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "location_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."address" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "line1" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "country" TEXT NOT NULL,
    "line2" TEXT,
    "region" TEXT,
    "postal_code" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "address_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."business_registration" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "file_id" UUID,
    "type" TEXT NOT NULL,
    "identifier" TEXT NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "issuing_country" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "business_registration_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."document_sequence" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "branch_id" UUID,
    "document_type" TEXT NOT NULL,
    "period" TEXT NOT NULL,
    "next_number" BIGINT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "document_sequence_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."pos_terminal" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "branch_id" UUID NOT NULL,
    "device_identifier" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "pos_terminal_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."cash_drawer" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "branch_id" UUID NOT NULL,
    "terminal_id" UUID,
    "currency" VARCHAR(3) NOT NULL,
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "cash_drawer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."cash_session" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "drawer_id" UUID NOT NULL,
    "cashier_id" UUID NOT NULL,
    "opening_float" DECIMAL(20,4) NOT NULL,
    "expected_cash" DECIMAL(20,4),
    "counted_cash" DECIMAL(20,4),
    "variance" DECIMAL(20,4),
    "status" "commerce"."cash_session_status" NOT NULL DEFAULT 'OPEN',
    "opened_at" TIMESTAMPTZ(6) NOT NULL,
    "closed_at" TIMESTAMPTZ(6),
    "audited_by" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "cash_session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."cash_movement" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "payment_id" UUID,
    "refund_id" UUID,
    "type" "commerce"."cash_movement_type" NOT NULL,
    "amount" DECIMAL(20,4) NOT NULL,
    "tendered_cash" DECIMAL(20,4),
    "change_given" DECIMAL(20,4),
    "reason" TEXT,
    "actor_id" UUID NOT NULL,
    "occurred_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "cash_movement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."cash_count" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "denomination" DECIMAL(20,4) NOT NULL,
    "quantity" DECIMAL(20,6) NOT NULL,
    "count_stage" TEXT NOT NULL,
    "counted_at" TIMESTAMPTZ(6) NOT NULL,
    "counted_by" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "cash_count_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."cash_deposit" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "branch_id" UUID NOT NULL,
    "session_id" UUID,
    "bank_account_id" UUID NOT NULL,
    "amount" DECIMAL(20,4) NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "status" TEXT NOT NULL,
    "deposit_reference" TEXT NOT NULL,
    "deposited_at" TIMESTAMPTZ(6),
    "verified_by" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "cash_deposit_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."cod_collection" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "shipment_id" UUID NOT NULL,
    "payment_id" UUID,
    "collector_reference" TEXT NOT NULL,
    "amount_due" DECIMAL(20,4) NOT NULL,
    "amount_collected" DECIMAL(20,4) NOT NULL,
    "status" TEXT NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "collected_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "cod_collection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."cod_remittance" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "collection_id" UUID NOT NULL,
    "carrier_id" UUID NOT NULL,
    "gross_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "fee_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "net_amount" DECIMAL(20,4) NOT NULL,
    "status" TEXT NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "received_at" TIMESTAMPTZ(6),
    "settlement_reference" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "cod_remittance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."product" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "brand_id" UUID,
    "name" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "product_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."product_variant" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "product_id" UUID NOT NULL,
    "unit_id" UUID NOT NULL,
    "sku" TEXT NOT NULL,
    "barcode" TEXT,
    "tracking_mode" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "allow_backorder" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "product_variant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."category" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "parent_id" UUID,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "category_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."product_category" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "product_id" UUID NOT NULL,
    "category_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "product_category_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."brand" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "brand_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."unit_of_measure" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "quantity_precision" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "unit_of_measure_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."product_attribute" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "data_type" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "product_attribute_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."variant_attribute_value" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "attribute_id" UUID NOT NULL,
    "value" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "variant_attribute_value_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."product_media" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "product_id" UUID NOT NULL,
    "variant_id" UUID,
    "file_id" UUID NOT NULL,
    "display_order" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "product_media_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."price_list" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "branch_id" UUID,
    "segment_id" UUID,
    "name" TEXT NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "valid_from" TIMESTAMPTZ(6) NOT NULL,
    "valid_until" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "price_list_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."price_list_item" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "price_list_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "min_quantity" DECIMAL(20,6) NOT NULL,
    "unit_price" DECIMAL(20,4) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "price_list_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."customer" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "linked_user_id" UUID,
    "name" TEXT NOT NULL,
    "phone" TEXT,
    "status" TEXT NOT NULL,
    "customer_number" TEXT NOT NULL,
    "email" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "customer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."customer_address" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "address_id" UUID NOT NULL,
    "label" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "customer_address_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."customer_consent" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "purpose" TEXT NOT NULL,
    "channel" TEXT NOT NULL,
    "policy_version" TEXT NOT NULL,
    "granted_at" TIMESTAMPTZ(6) NOT NULL,
    "withdrawn_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "customer_consent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."customer_segment" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "definition_json" JSONB NOT NULL,
    "segment_type" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "customer_segment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."customer_segment_member" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "segment_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "customer_segment_member_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."customer_credit_account" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "credit_limit" DECIMAL(20,4) NOT NULL,
    "terms_days" INTEGER NOT NULL,
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "customer_credit_account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."carrier" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "integration_type" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "carrier_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."shipment" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "carrier_id" UUID,
    "origin_id" UUID NOT NULL,
    "tracking_number" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "shipping_address_snapshot" JSONB NOT NULL,
    "packed_by" UUID,
    "packed_at" TIMESTAMPTZ(6),
    "shipped_at" TIMESTAMPTZ(6),
    "delivered_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "shipment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."shipment_item" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "shipment_id" UUID NOT NULL,
    "order_item_id" UUID NOT NULL,
    "quantity" DECIMAL(20,6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "shipment_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."shipment_event" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "shipment_id" UUID NOT NULL,
    "external_event_id" TEXT,
    "status" TEXT NOT NULL,
    "occurred_at" TIMESTAMPTZ(6) NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "shipment_event_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."delivery_proof" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "shipment_id" UUID NOT NULL,
    "file_id" UUID,
    "recipient_name" TEXT,
    "delivered_at" TIMESTAMPTZ(6) NOT NULL,
    "confirmation_reference" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "delivery_proof_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."return_policy" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "eligibility_rules" JSONB NOT NULL,
    "window_days" TEXT NOT NULL,
    "effective_from" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "return_policy_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."return_request" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "customer_id" UUID,
    "policy_id" UUID NOT NULL,
    "reason" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "requested_at" TIMESTAMPTZ(6) NOT NULL,
    "approved_by" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "return_request_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."return_item" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "request_id" UUID NOT NULL,
    "order_item_id" UUID NOT NULL,
    "requested_qty" DECIMAL(20,6) NOT NULL,
    "received_qty" DECIMAL(20,6) NOT NULL,
    "condition" TEXT NOT NULL,
    "resolution" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "return_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."return_inspection" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "return_item_id" UUID NOT NULL,
    "inspector_id" UUID NOT NULL,
    "location_id" UUID NOT NULL,
    "disposition" TEXT NOT NULL,
    "inspected_at" TIMESTAMPTZ(6) NOT NULL,
    "condition_notes" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "return_inspection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."replacement_link" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "return_item_id" UUID NOT NULL,
    "replacement_item_id" UUID NOT NULL,
    "quantity" DECIMAL(20,6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "replacement_link_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."employee_profile" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "membership_id" UUID NOT NULL,
    "department_id" UUID,
    "job_title" TEXT NOT NULL,
    "hire_date" DATE,
    "employment_status" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "employee_profile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."employee_branch_assignment" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "employee_id" UUID NOT NULL,
    "branch_id" UUID NOT NULL,
    "starts_at" TIMESTAMPTZ(6) NOT NULL,
    "ends_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "employee_branch_assignment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."work_shift" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "employee_id" UUID NOT NULL,
    "branch_id" UUID NOT NULL,
    "scheduled_start" TIMESTAMPTZ(6) NOT NULL,
    "actual_start" TIMESTAMPTZ(6),
    "scheduled_end" TIMESTAMPTZ(6) NOT NULL,
    "actual_end" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "work_shift_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."task" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "assignee_id" UUID NOT NULL,
    "branch_id" UUID,
    "title" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "due_at" TIMESTAMPTZ(6),
    "description" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "task_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."approval_policy" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "scope_id" UUID NOT NULL,
    "required_role_id" UUID NOT NULL,
    "action_type" TEXT NOT NULL,
    "threshold_amount" DECIMAL(20,4),
    "currency" VARCHAR(3),
    "required_approvals" INTEGER NOT NULL DEFAULT 1,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "approval_policy_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."approval_request" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "policy_id" UUID NOT NULL,
    "requested_by" UUID NOT NULL,
    "resource_type" TEXT NOT NULL,
    "resource_id" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "resource_version" INTEGER NOT NULL DEFAULT 1,
    "reason" TEXT,
    "completed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "approval_request_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."approval_step" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "request_id" UUID NOT NULL,
    "sequence" INTEGER NOT NULL,
    "required_role_id" UUID NOT NULL,
    "status" TEXT NOT NULL,
    "tenant_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "approval_step_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."approval_decision" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "step_id" UUID NOT NULL,
    "decided_by" UUID NOT NULL,
    "decision" "commerce"."approval_decision_type" NOT NULL,
    "reason" TEXT,
    "decided_at" TIMESTAMPTZ(6) NOT NULL,
    "tenant_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "approval_decision_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."payment_settlement_item" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "settlement_id" UUID NOT NULL,
    "payment_id" UUID,
    "refund_id" UUID,
    "type" TEXT NOT NULL,
    "gross_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "fee_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "net_amount" DECIMAL(20,4) NOT NULL,
    "tenant_id" UUID NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "payment_settlement_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."refund_attempt" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "refund_id" UUID NOT NULL,
    "provider_reference" TEXT,
    "status" TEXT NOT NULL,
    "failure_code" TEXT,
    "attempted_at" TIMESTAMPTZ(6) NOT NULL,
    "tenant_id" UUID NOT NULL,
    "completed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "refund_attempt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."refund_allocation" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "refund_id" UUID NOT NULL,
    "payment_allocation_id" UUID NOT NULL,
    "return_item_id" UUID,
    "amount" DECIMAL(20,4) NOT NULL,
    "tenant_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "refund_allocation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."daily_sales_snapshot" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "branch_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "business_date" DATE NOT NULL,
    "units_sold" DECIMAL(20,6) NOT NULL,
    "units_returned" DECIMAL(20,6) NOT NULL,
    "net_revenue" DECIMAL(20,4) NOT NULL,
    "cost_of_goods_sold" DECIMAL(20,4) NOT NULL,
    "closing_stock" DECIMAL(20,6) NOT NULL,
    "was_on_promotion" BOOLEAN NOT NULL DEFAULT false,
    "data_cutoff" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "daily_sales_snapshot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."inventory_cost_layer" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "receipt_item_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "location_id" UUID NOT NULL,
    "quantity_remaining" DECIMAL(20,6) NOT NULL DEFAULT 0,
    "unit_cost" DECIMAL(20,4) NOT NULL,
    "received_at" TIMESTAMPTZ(6) NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "inventory_cost_layer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."inventory_cost_allocation" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "layer_id" UUID NOT NULL,
    "movement_id" UUID NOT NULL,
    "quantity" DECIMAL(20,6) NOT NULL,
    "unit_cost" DECIMAL(20,4) NOT NULL,
    "cost_amount" DECIMAL(20,4) NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "inventory_cost_allocation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."user" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "email" TEXT NOT NULL,
    "phone" TEXT,
    "display_name" TEXT NOT NULL,
    "status" "commerce"."USER_STATUS" NOT NULL DEFAULT 'ACTIVE',
    "email_verified_at" TIMESTAMPTZ(6),
    "phone_verified_at" TIMESTAMPTZ(6),
    "last_login_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,
    "email_verified" BOOLEAN NOT NULL DEFAULT false,
    "image" TEXT,

    CONSTRAINT "user_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."auth_identity" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "provider" TEXT NOT NULL,
    "provider_subject" TEXT NOT NULL,
    "password_hash" TEXT,
    "last_authenticated_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "auth_identity_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."session" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "token_hash" TEXT NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "revoked_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."mfa_factor" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "encrypted_secret" TEXT,
    "verified_at" TIMESTAMPTZ(6) NOT NULL,
    "public_key" TEXT,
    "last_used_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "mfa_factor_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."auth_challenge" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID,
    "purpose" TEXT NOT NULL,
    "token_hash" TEXT NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "consumed_at" TIMESTAMPTZ(6),
    "attempt_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "auth_challenge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."tenant_membership" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "status" TEXT NOT NULL,
    "employee_code" TEXT,
    "joined_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "tenant_membership_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."role" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "code" "commerce"."role_code" NOT NULL,
    "name" TEXT NOT NULL,
    "is_system_role" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "role_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."permission" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "resource" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "permission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."role_permission" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "role_id" UUID NOT NULL,
    "permission_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "role_permission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."access_scope" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "branch_id" UUID,
    "department_id" UUID,
    "location_id" UUID,
    "type" "commerce"."scope_type" NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "access_scope_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."role_assignment" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "membership_id" UUID NOT NULL,
    "role_id" UUID NOT NULL,
    "scope_id" UUID NOT NULL,
    "valid_until" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "role_assignment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."invitation" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "role_id" UUID NOT NULL,
    "scope_id" UUID NOT NULL,
    "token_hash" TEXT NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "email_or_phone" TEXT NOT NULL,
    "accepted_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "invitation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."better_auth_session" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "token" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "user_id" UUID NOT NULL,

    CONSTRAINT "better_auth_session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."account" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "account_id" TEXT NOT NULL,
    "provider_id" TEXT NOT NULL,
    "user_id" UUID NOT NULL,
    "access_token" TEXT,
    "refresh_token" TEXT,
    "id_token" TEXT,
    "access_token_expires_at" TIMESTAMPTZ(6),
    "refresh_token_expires_at" TIMESTAMPTZ(6),
    "scope" TEXT,
    "password" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."verification" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "identifier" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "verification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."jwks" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "public_key" TEXT NOT NULL,
    "private_key" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMPTZ(6),
    "alg" TEXT,
    "crv" TEXT,

    CONSTRAINT "jwks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."inventory_balance" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "location_id" UUID NOT NULL,
    "lot_id" UUID,
    "on_hand" DECIMAL(20,6) NOT NULL DEFAULT 0,
    "reserved" DECIMAL(20,6) NOT NULL DEFAULT 0,
    "version" INTEGER NOT NULL DEFAULT 1,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "inventory_balance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."stock_movement" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "location_id" UUID NOT NULL,
    "lot_id" UUID,
    "quantity_delta" DECIMAL(20,6) NOT NULL,
    "type" TEXT NOT NULL,
    "source_type" TEXT NOT NULL,
    "source_id" TEXT NOT NULL,
    "occurred_at" TIMESTAMPTZ(6) NOT NULL,
    "performed_by" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "stock_movement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."stock_reservation" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "order_item_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "location_id" UUID NOT NULL,
    "lot_id" UUID,
    "quantity" DECIMAL(20,6) NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "stock_reservation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."inventory_lot" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "lot_number" TEXT NOT NULL,
    "expires_at" TIMESTAMPTZ(6),
    "unit_cost" DECIMAL(20,4) NOT NULL,
    "manufactured_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "inventory_lot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."serialized_item" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "lot_id" UUID,
    "location_id" UUID,
    "serial_number" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "sold_order_item_id" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "serialized_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."stock_transfer" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "from_location_id" UUID NOT NULL,
    "to_location_id" UUID NOT NULL,
    "status" TEXT NOT NULL,
    "shipped_at" TIMESTAMPTZ(6) NOT NULL,
    "received_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "stock_transfer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."stock_transfer_item" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "transfer_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "lot_id" UUID,
    "requested_qty" DECIMAL(20,6) NOT NULL,
    "shipped_qty" DECIMAL(20,6) NOT NULL,
    "received_qty" DECIMAL(20,6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "stock_transfer_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."stock_count" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "location_id" UUID NOT NULL,
    "counted_by" UUID NOT NULL,
    "status" TEXT NOT NULL,
    "finalized_at" TIMESTAMPTZ(6),
    "approved_by" UUID,
    "started_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "stock_count_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."stock_count_item" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "count_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "lot_id" UUID,
    "expected_qty" DECIMAL(20,6) NOT NULL,
    "counted_qty" DECIMAL(20,6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "stock_count_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."reorder_policy" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "location_id" UUID NOT NULL,
    "supplier_id" UUID,
    "minimum_qty" DECIMAL(20,6) NOT NULL,
    "target_qty" DECIMAL(20,6) NOT NULL,
    "safety_stock" DECIMAL(20,6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "reorder_policy_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."marketplace_listing" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "company_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "public_title" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "published_at" TIMESTAMPTZ(6),
    "tenant_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "marketplace_listing_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."checkout_group" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "buyer_user_id" UUID,
    "currency" VARCHAR(3) NOT NULL,
    "status" TEXT NOT NULL,
    "checkout_reference" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "checkout_group_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."commission_rule" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "company_id" UUID,
    "category_id" UUID,
    "rate" DECIMAL(9,6) NOT NULL,
    "fixed_fee" DECIMAL(20,4) NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "valid_from" TIMESTAMPTZ(6) NOT NULL,
    "valid_until" TIMESTAMPTZ(6),
    "tenant_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "commission_rule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."seller_earning" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "company_id" UUID NOT NULL,
    "order_item_id" UUID NOT NULL,
    "rule_id" UUID NOT NULL,
    "gross_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "commission_amount" DECIMAL(20,4) NOT NULL,
    "net_amount" DECIMAL(20,4) NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "status" TEXT NOT NULL,
    "tenant_id" UUID NOT NULL,
    "recognized_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "seller_earning_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."seller_payout" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "company_id" UUID NOT NULL,
    "payout_account_id" UUID NOT NULL,
    "amount" DECIMAL(20,4) NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "status" TEXT NOT NULL,
    "idempotency_key" TEXT NOT NULL,
    "tenant_id" UUID NOT NULL,
    "requested_at" TIMESTAMPTZ(6) NOT NULL,
    "completed_at" TIMESTAMPTZ(6),
    "provider_reference" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "seller_payout_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."seller_payout_item" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "payout_id" UUID NOT NULL,
    "earning_id" UUID NOT NULL,
    "allocated_amount" DECIMAL(20,4) NOT NULL,
    "tenant_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "seller_payout_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."notification_template" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "event_type" TEXT NOT NULL,
    "channel" TEXT NOT NULL,
    "locale" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "body" TEXT NOT NULL,
    "subject" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notification_template_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."notification" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "template_id" UUID NOT NULL,
    "recipient_reference" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "status" TEXT NOT NULL,
    "channel" TEXT NOT NULL,
    "scheduled_at" TIMESTAMPTZ(6),
    "customer_id" UUID,
    "membership_id" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."notification_attempt" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "notification_id" UUID NOT NULL,
    "provider_reference" TEXT,
    "attempted_at" TIMESTAMPTZ(6) NOT NULL,
    "status" TEXT NOT NULL,
    "error_code" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "notification_attempt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."notification_preference" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "customer_id" UUID,
    "membership_id" UUID,
    "channel" TEXT NOT NULL,
    "purpose" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "notification_preference_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."support_ticket" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "customer_id" UUID,
    "order_id" UUID,
    "assigned_to" UUID,
    "subject" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "priority" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "support_ticket_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."support_message" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "ticket_id" UUID NOT NULL,
    "file_id" UUID,
    "sender_type" TEXT NOT NULL,
    "sender_reference" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "sent_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "support_message_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."payment_method" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "type" "commerce"."payment_method_type" NOT NULL,
    "display_name" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "payment_method_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."payment_provider_account" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "provider" TEXT NOT NULL,
    "merchant_reference" TEXT NOT NULL,
    "secret_reference" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "payment_provider_account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."payment" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "customer_id" UUID,
    "method_id" UUID NOT NULL,
    "provider_account_id" UUID,
    "amount" DECIMAL(20,4) NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "status" "commerce"."payment_status" NOT NULL DEFAULT 'PENDING',
    "idempotency_key" TEXT NOT NULL,
    "direction" TEXT NOT NULL DEFAULT 'INBOUND',
    "COLLECTION_CHANNEL" "commerce"."collection_channel" NOT NULL DEFAULT 'ONLINE',
    "COLLECTION_TIMING" "commerce"."collection_timing" NOT NULL DEFAULT 'PREPAID',
    "received_at" TIMESTAMPTZ(6),
    "confirmed_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."payment_attempt" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "payment_id" UUID NOT NULL,
    "provider_transaction_reference" TEXT,
    "status" TEXT NOT NULL,
    "failure_code" TEXT,
    "provider_account_id" UUID NOT NULL,
    "provider_request_reference" TEXT NOT NULL,
    "initiated_at" TIMESTAMPTZ(6) NOT NULL,
    "completed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "payment_attempt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."payment_event" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "payment_id" UUID NOT NULL,
    "attempt_id" UUID,
    "event_type" TEXT NOT NULL,
    "amount" DECIMAL(20,4),
    "occurred_at" TIMESTAMPTZ(6) NOT NULL,
    "provider_event_reference" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "payment_event_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."payment_allocation" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "payment_id" UUID NOT NULL,
    "invoice_id" UUID NOT NULL,
    "allocated_amount" DECIMAL(20,4) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "payment_allocation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."payment_webhook_event" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "provider_account_id" UUID NOT NULL,
    "provider_event_id" TEXT NOT NULL,
    "payload_hash" TEXT NOT NULL,
    "verification_status" TEXT NOT NULL,
    "processing_status" TEXT NOT NULL,
    "tenant_id" UUID NOT NULL,
    "received_at" TIMESTAMPTZ(6) NOT NULL,
    "processed_at" TIMESTAMPTZ(6),
    "payload_reference" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "payment_webhook_event_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."refund" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "payment_id" UUID NOT NULL,
    "return_id" UUID,
    "amount" DECIMAL(20,4) NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "status" "commerce"."refund_status" NOT NULL DEFAULT 'REQUESTED',
    "idempotency_key" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "approved_by" UUID,
    "completed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "refund_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."payment_dispute" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "payment_id" UUID NOT NULL,
    "provider_case_id" TEXT NOT NULL,
    "amount" DECIMAL(20,4) NOT NULL,
    "status" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "response_due_at" TIMESTAMPTZ(6),
    "resolved_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "payment_dispute_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."payment_settlement" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "provider_account_id" UUID NOT NULL,
    "external_id" TEXT NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "gross_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "fee_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "net_amount" DECIMAL(20,4) NOT NULL,
    "status" TEXT NOT NULL,
    "settled_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "payment_settlement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."supplier" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "payment_terms" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "email" TEXT,
    "phone" TEXT,
    "address_id" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "supplier_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."supplier_product" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "supplier_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "lead_time_days" INTEGER NOT NULL,
    "minimum_order_quantity" DECIMAL(20,6) NOT NULL,
    "supplier_sku" TEXT,
    "quoted_cost" DECIMAL(20,4),
    "currency" VARCHAR(3),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "supplier_product_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."purchase_order" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "supplier_id" UUID NOT NULL,
    "destination_id" UUID NOT NULL,
    "number" TEXT NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "status" TEXT NOT NULL,
    "expected_at" TIMESTAMPTZ(6),
    "approved_by" UUID,
    "ordered_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "purchase_order_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."purchase_order_item" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "purchase_order_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "quantity" DECIMAL(20,6) NOT NULL,
    "unit_cost" DECIMAL(20,4) NOT NULL,
    "tax_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "discount_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "line_total" DECIMAL(20,4) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "purchase_order_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."goods_receipt" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "supplier_id" UUID NOT NULL,
    "purchase_order_id" UUID,
    "location_id" UUID NOT NULL,
    "received_at" TIMESTAMPTZ(6) NOT NULL,
    "status" TEXT NOT NULL,
    "received_by" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "goods_receipt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."goods_receipt_item" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "receipt_id" UUID NOT NULL,
    "po_item_id" UUID,
    "variant_id" UUID NOT NULL,
    "lot_id" UUID,
    "accepted_qty" DECIMAL(20,6) NOT NULL,
    "rejected_qty" DECIMAL(20,6) NOT NULL,
    "unit_cost" DECIMAL(20,4) NOT NULL,
    "received_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "goods_receipt_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."supplier_invoice" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "supplier_id" UUID NOT NULL,
    "purchase_order_id" UUID,
    "number" TEXT NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "total" DECIMAL(20,4) NOT NULL,
    "due_at" TIMESTAMPTZ(6) NOT NULL,
    "issued_at" TIMESTAMPTZ(6) NOT NULL,
    "status" TEXT NOT NULL,
    "subtotal" DECIMAL(20,4) NOT NULL,
    "tax_total" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "discount_total" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "supplier_invoice_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."supplier_invoice_item" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "invoice_id" UUID NOT NULL,
    "po_item_id" UUID,
    "variant_id" UUID,
    "quantity" DECIMAL(20,6) NOT NULL,
    "unit_cost" DECIMAL(20,4) NOT NULL,
    "description" TEXT NOT NULL,
    "line_total" DECIMAL(20,4) NOT NULL,
    "tax_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "supplier_invoice_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."audit_event" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID,
    "actor_id" UUID,
    "action" TEXT NOT NULL,
    "resource_type" TEXT NOT NULL,
    "resource_id" TEXT NOT NULL,
    "redacted_changes" JSONB NOT NULL,
    "occurred_at" TIMESTAMPTZ(6) NOT NULL,
    "request_id" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "audit_event_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."security_event" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID,
    "user_id" UUID,
    "type" TEXT NOT NULL,
    "severity" TEXT NOT NULL,
    "occurred_at" TIMESTAMPTZ(6) NOT NULL,
    "ip_address" INET,
    "device_reference" TEXT,
    "description" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "security_event_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."file_object" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID,
    "uploaded_by" UUID,
    "storage_key" TEXT NOT NULL,
    "content_type" TEXT NOT NULL,
    "checksum" TEXT NOT NULL,
    "scan_status" TEXT NOT NULL,
    "size_bytes" BIGINT NOT NULL,
    "retention_until" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "file_object_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."idempotency_record" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "operation" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "request_hash" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "response_reference" TEXT,
    "completed_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "idempotency_record_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."outbox_event" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "aggregate_type" TEXT NOT NULL,
    "aggregate_id" TEXT NOT NULL,
    "event_type" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "published_at" TIMESTAMPTZ(6),
    "occurred_at" TIMESTAMPTZ(6) NOT NULL,
    "attempt_count" INTEGER NOT NULL DEFAULT 0,
    "last_error" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "outbox_event_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."inbox_event" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "consumer_name" TEXT NOT NULL,
    "event_id" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "processed_at" TIMESTAMPTZ(6),
    "received_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "inbox_event_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."integration_connection" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "secret_reference" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "configuration" JSONB NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "integration_connection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."cart" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "customer_id" UUID,
    "branch_id" UUID,
    "guest_token_hash" TEXT,
    "currency" VARCHAR(3) NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "cart_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."cart_item" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "cart_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "quantity" DECIMAL(20,6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "cart_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."order" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "branch_id" UUID NOT NULL,
    "customer_id" UUID,
    "checkout_group_id" UUID,
    "number" TEXT NOT NULL,
    "channel" "commerce"."order_channel" NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "status" "commerce"."order_status" NOT NULL DEFAULT 'DRAFT',
    "grand_total" DECIMAL(20,4) NOT NULL,
    "seller_id" UUID,
    "PAYMENT_STATUS" TEXT NOT NULL,
    "fulfillment_status" TEXT NOT NULL,
    "subtotal" DECIMAL(20,4) NOT NULL,
    "discount_total" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "tax_total" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "shipping_total" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "placed_at" TIMESTAMPTZ(6),
    "cancelled_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "order_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."order_item" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "variant_id" UUID,
    "sku_snapshot" TEXT NOT NULL,
    "name_snapshot" TEXT NOT NULL,
    "quantity" DECIMAL(20,6) NOT NULL,
    "unit_price" DECIMAL(20,4) NOT NULL,
    "tax_total" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "line_total" DECIMAL(20,4) NOT NULL,
    "discount_total" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "cost_total" DECIMAL(20,4),
    "fulfilled_quantity" DECIMAL(20,6) NOT NULL DEFAULT 0,
    "returned_quantity" DECIMAL(20,6) NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "order_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."order_address" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "address_snapshot" JSONB NOT NULL,
    "recipient_name" TEXT NOT NULL,
    "phone" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "order_address_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."order_status_event" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "from_status" TEXT NOT NULL,
    "to_status" TEXT NOT NULL,
    "occurred_at" TIMESTAMPTZ(6) NOT NULL,
    "actor_id" UUID,
    "reason" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "order_status_event_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."tax_rate" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "jurisdiction" TEXT NOT NULL,
    "rate" DECIMAL(9,6) NOT NULL,
    "valid_from" TIMESTAMPTZ(6) NOT NULL,
    "valid_until" TIMESTAMPTZ(6),
    "name" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "tax_rate_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."order_item_tax" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "order_item_id" UUID NOT NULL,
    "tax_rate_id" UUID,
    "rate_snapshot" DECIMAL(9,6) NOT NULL,
    "taxable_amount" TEXT NOT NULL,
    "tax_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "name_snapshot" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "order_item_tax_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."promotion" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "eligibility_rules" JSONB NOT NULL,
    "starts_at" TIMESTAMPTZ(6) NOT NULL,
    "ends_at" TIMESTAMPTZ(6) NOT NULL,
    "usage_limit" INTEGER,
    "currency" VARCHAR(3),
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "promotion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."coupon" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "promotion_id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "usage_limit" INTEGER,
    "per_customer_limit" INTEGER,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "coupon_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."promotion_redemption" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "promotion_id" UUID NOT NULL,
    "coupon_id" UUID,
    "order_id" UUID NOT NULL,
    "customer_id" UUID,
    "discount_amount" DECIMAL(20,4) NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "promotion_redemption_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."sales_invoice" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "number" TEXT NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "totals_snapshot" JSONB NOT NULL,
    "status" TEXT NOT NULL,
    "issued_at" TIMESTAMPTZ(6) NOT NULL,
    "due_at" TIMESTAMPTZ(6),
    "total" DECIMAL(20,4) NOT NULL,
    "cancelled_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "sales_invoice_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."seller_company" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "display_name" TEXT NOT NULL,
    "legal_name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "onboarding_status" TEXT NOT NULL,
    "verification_status" TEXT NOT NULL,
    "description" TEXT,
    "website_url" TEXT,
    "support_email" TEXT,
    "support_phone" TEXT,
    "logo_file_id" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "seller_company_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."company_ownership" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "company_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "ownership_percent" DECIMAL(9,6) NOT NULL,
    "is_authorized_signatory" BOOLEAN NOT NULL DEFAULT false,
    "valid_from" TIMESTAMPTZ(6) NOT NULL,
    "valid_until" TIMESTAMPTZ(6),
    "tenant_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "company_ownership_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."company_verification" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "company_id" UUID NOT NULL,
    "file_id" UUID,
    "reviewer_id" UUID,
    "check_type" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "reviewed_at" TIMESTAMPTZ(6),
    "tenant_id" UUID NOT NULL,
    "review_notes" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "company_verification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."company_contact" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "company_id" UUID NOT NULL,
    "user_id" UUID,
    "type" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "tenant_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "company_contact_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."seller_agreement" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "company_id" UUID NOT NULL,
    "file_id" UUID,
    "version" INTEGER NOT NULL DEFAULT 1,
    "accepted_by" UUID NOT NULL,
    "accepted_at" TIMESTAMPTZ(6),
    "status" TEXT NOT NULL,
    "tenant_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "seller_agreement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commerce"."seller_payout_account" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "company_id" UUID NOT NULL,
    "provider_account_id" UUID,
    "masked_destination" TEXT NOT NULL,
    "secret_reference" TEXT NOT NULL,
    "currency" VARCHAR(3) NOT NULL,
    "verification_status" TEXT NOT NULL,
    "tenant_id" UUID NOT NULL,
    "verified_at" TIMESTAMPTZ(6),
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_version" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "seller_payout_account_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ledger_account_tenant_id_id_key" ON "commerce"."ledger_account"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "ledger_account_tenant_id_code_key" ON "commerce"."ledger_account"("tenant_id", "code");

-- CreateIndex
CREATE UNIQUE INDEX "fiscal_period_tenant_id_id_key" ON "commerce"."fiscal_period"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "journal_entry_tenant_id_id_key" ON "commerce"."journal_entry"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "journal_entry_tenant_id_number_key" ON "commerce"."journal_entry"("tenant_id", "number");

-- CreateIndex
CREATE UNIQUE INDEX "journal_line_tenant_id_id_key" ON "commerce"."journal_line"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "bank_account_tenant_id_id_key" ON "commerce"."bank_account"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "bank_statement_line_tenant_id_id_key" ON "commerce"."bank_statement_line"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "bank_statement_line_tenant_id_bank_account_id_external_refe_key" ON "commerce"."bank_statement_line"("tenant_id", "bank_account_id", "external_reference");

-- CreateIndex
CREATE UNIQUE INDEX "reconciliation_match_tenant_id_id_key" ON "commerce"."reconciliation_match"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "expense_tenant_id_id_key" ON "commerce"."expense"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "supplier_payment_tenant_id_id_key" ON "commerce"."supplier_payment"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "supplier_payment_allocation_tenant_id_id_key" ON "commerce"."supplier_payment_allocation"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "analytics_job_tenant_id_id_key" ON "commerce"."analytics_job"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "model_version_tenant_id_id_key" ON "commerce"."model_version"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "model_version_tenant_id_name_version_key" ON "commerce"."model_version"("tenant_id", "name", "version");

-- CreateIndex
CREATE UNIQUE INDEX "demand_forecast_tenant_id_id_key" ON "commerce"."demand_forecast"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "business_insight_tenant_id_id_key" ON "commerce"."business_insight"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "recommendation_decision_tenant_id_id_key" ON "commerce"."recommendation_decision"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "report_job_tenant_id_id_key" ON "commerce"."report_job"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "tenant_slug_key" ON "commerce"."tenant"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "tenant_setting_tenant_id_id_key" ON "commerce"."tenant_setting"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "tenant_setting_tenant_id_key_key" ON "commerce"."tenant_setting"("tenant_id", "key");

-- CreateIndex
CREATE UNIQUE INDEX "branch_tenant_id_id_key" ON "commerce"."branch"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "branch_tenant_id_code_key" ON "commerce"."branch"("tenant_id", "code");

-- CreateIndex
CREATE UNIQUE INDEX "department_tenant_id_id_key" ON "commerce"."department"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "location_tenant_id_id_key" ON "commerce"."location"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "address_tenant_id_id_key" ON "commerce"."address"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "business_registration_tenant_id_id_key" ON "commerce"."business_registration"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "document_sequence_tenant_id_id_key" ON "commerce"."document_sequence"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "document_sequence_tenant_id_branch_id_document_type_period_key" ON "commerce"."document_sequence"("tenant_id", "branch_id", "document_type", "period");

-- CreateIndex
CREATE UNIQUE INDEX "pos_terminal_tenant_id_id_key" ON "commerce"."pos_terminal"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "pos_terminal_tenant_id_device_identifier_key" ON "commerce"."pos_terminal"("tenant_id", "device_identifier");

-- CreateIndex
CREATE UNIQUE INDEX "cash_drawer_tenant_id_id_key" ON "commerce"."cash_drawer"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "cash_session_tenant_id_id_key" ON "commerce"."cash_session"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "cash_movement_tenant_id_id_key" ON "commerce"."cash_movement"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "cash_count_tenant_id_id_key" ON "commerce"."cash_count"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "cash_deposit_tenant_id_id_key" ON "commerce"."cash_deposit"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "cod_collection_tenant_id_id_key" ON "commerce"."cod_collection"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "cod_remittance_tenant_id_id_key" ON "commerce"."cod_remittance"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "product_tenant_id_id_key" ON "commerce"."product"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "product_variant_tenant_id_id_key" ON "commerce"."product_variant"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "product_variant_tenant_id_sku_key" ON "commerce"."product_variant"("tenant_id", "sku");

-- CreateIndex
CREATE UNIQUE INDEX "category_tenant_id_id_key" ON "commerce"."category"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "category_tenant_id_slug_key" ON "commerce"."category"("tenant_id", "slug");

-- CreateIndex
CREATE UNIQUE INDEX "product_category_tenant_id_id_key" ON "commerce"."product_category"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "product_category_tenant_id_product_id_category_id_key" ON "commerce"."product_category"("tenant_id", "product_id", "category_id");

-- CreateIndex
CREATE UNIQUE INDEX "brand_tenant_id_id_key" ON "commerce"."brand"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "brand_tenant_id_name_key" ON "commerce"."brand"("tenant_id", "name");

-- CreateIndex
CREATE UNIQUE INDEX "unit_of_measure_tenant_id_id_key" ON "commerce"."unit_of_measure"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "unit_of_measure_tenant_id_code_key" ON "commerce"."unit_of_measure"("tenant_id", "code");

-- CreateIndex
CREATE UNIQUE INDEX "product_attribute_tenant_id_id_key" ON "commerce"."product_attribute"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "product_attribute_tenant_id_name_key" ON "commerce"."product_attribute"("tenant_id", "name");

-- CreateIndex
CREATE UNIQUE INDEX "variant_attribute_value_tenant_id_id_key" ON "commerce"."variant_attribute_value"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "variant_attribute_value_tenant_id_variant_id_attribute_id_key" ON "commerce"."variant_attribute_value"("tenant_id", "variant_id", "attribute_id");

-- CreateIndex
CREATE UNIQUE INDEX "product_media_tenant_id_id_key" ON "commerce"."product_media"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "price_list_tenant_id_id_key" ON "commerce"."price_list"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "price_list_item_tenant_id_id_key" ON "commerce"."price_list_item"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "price_list_item_tenant_id_price_list_id_variant_id_min_quan_key" ON "commerce"."price_list_item"("tenant_id", "price_list_id", "variant_id", "min_quantity");

-- CreateIndex
CREATE UNIQUE INDEX "customer_tenant_id_id_key" ON "commerce"."customer"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "customer_tenant_id_customer_number_key" ON "commerce"."customer"("tenant_id", "customer_number");

-- CreateIndex
CREATE UNIQUE INDEX "customer_address_tenant_id_id_key" ON "commerce"."customer_address"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "customer_consent_tenant_id_id_key" ON "commerce"."customer_consent"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "customer_segment_tenant_id_id_key" ON "commerce"."customer_segment"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "customer_segment_member_tenant_id_id_key" ON "commerce"."customer_segment_member"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "customer_segment_member_tenant_id_segment_id_customer_id_key" ON "commerce"."customer_segment_member"("tenant_id", "segment_id", "customer_id");

-- CreateIndex
CREATE UNIQUE INDEX "customer_credit_account_tenant_id_id_key" ON "commerce"."customer_credit_account"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "customer_credit_account_tenant_id_customer_id_currency_key" ON "commerce"."customer_credit_account"("tenant_id", "customer_id", "currency");

-- CreateIndex
CREATE UNIQUE INDEX "carrier_tenant_id_id_key" ON "commerce"."carrier"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "shipment_tenant_id_id_key" ON "commerce"."shipment"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "shipment_item_tenant_id_id_key" ON "commerce"."shipment_item"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "shipment_event_tenant_id_id_key" ON "commerce"."shipment_event"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "delivery_proof_tenant_id_id_key" ON "commerce"."delivery_proof"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "return_policy_tenant_id_id_key" ON "commerce"."return_policy"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "return_policy_tenant_id_version_key" ON "commerce"."return_policy"("tenant_id", "version");

-- CreateIndex
CREATE UNIQUE INDEX "return_request_tenant_id_id_key" ON "commerce"."return_request"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "return_item_tenant_id_id_key" ON "commerce"."return_item"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "return_inspection_tenant_id_id_key" ON "commerce"."return_inspection"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "replacement_link_tenant_id_id_key" ON "commerce"."replacement_link"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "employee_profile_tenant_id_id_key" ON "commerce"."employee_profile"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "employee_profile_tenant_id_membership_id_key" ON "commerce"."employee_profile"("tenant_id", "membership_id");

-- CreateIndex
CREATE UNIQUE INDEX "employee_branch_assignment_tenant_id_id_key" ON "commerce"."employee_branch_assignment"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "work_shift_tenant_id_id_key" ON "commerce"."work_shift"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "task_tenant_id_id_key" ON "commerce"."task"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "approval_policy_tenant_id_id_key" ON "commerce"."approval_policy"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "approval_request_tenant_id_id_key" ON "commerce"."approval_request"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "approval_step_tenant_id_id_key" ON "commerce"."approval_step"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "approval_step_tenant_id_request_id_sequence_key" ON "commerce"."approval_step"("tenant_id", "request_id", "sequence");

-- CreateIndex
CREATE UNIQUE INDEX "approval_decision_tenant_id_id_key" ON "commerce"."approval_decision"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "approval_decision_tenant_id_step_id_decided_by_key" ON "commerce"."approval_decision"("tenant_id", "step_id", "decided_by");

-- CreateIndex
CREATE UNIQUE INDEX "payment_settlement_item_tenant_id_id_key" ON "commerce"."payment_settlement_item"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "refund_attempt_tenant_id_id_key" ON "commerce"."refund_attempt"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "refund_allocation_tenant_id_id_key" ON "commerce"."refund_allocation"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "daily_sales_snapshot_tenant_id_id_key" ON "commerce"."daily_sales_snapshot"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "daily_sales_snapshot_tenant_id_branch_id_variant_id_busines_key" ON "commerce"."daily_sales_snapshot"("tenant_id", "branch_id", "variant_id", "business_date");

-- CreateIndex
CREATE UNIQUE INDEX "inventory_cost_layer_tenant_id_id_key" ON "commerce"."inventory_cost_layer"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "inventory_cost_allocation_tenant_id_id_key" ON "commerce"."inventory_cost_allocation"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "user_email_key" ON "commerce"."user"("email");

-- CreateIndex
CREATE UNIQUE INDEX "user_phone_key" ON "commerce"."user"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "auth_identity_provider_provider_subject_key" ON "commerce"."auth_identity"("provider", "provider_subject");

-- CreateIndex
CREATE UNIQUE INDEX "session_token_hash_key" ON "commerce"."session"("token_hash");

-- CreateIndex
CREATE UNIQUE INDEX "auth_challenge_token_hash_key" ON "commerce"."auth_challenge"("token_hash");

-- CreateIndex
CREATE UNIQUE INDEX "tenant_membership_tenant_id_id_key" ON "commerce"."tenant_membership"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "tenant_membership_tenant_id_user_id_key" ON "commerce"."tenant_membership"("tenant_id", "user_id");

-- CreateIndex
CREATE UNIQUE INDEX "tenant_membership_tenant_id_employee_code_key" ON "commerce"."tenant_membership"("tenant_id", "employee_code");

-- CreateIndex
CREATE UNIQUE INDEX "role_tenant_id_id_key" ON "commerce"."role"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "role_tenant_id_code_key" ON "commerce"."role"("tenant_id", "code");

-- CreateIndex
CREATE UNIQUE INDEX "permission_code_key" ON "commerce"."permission"("code");

-- CreateIndex
CREATE UNIQUE INDEX "permission_resource_action_key" ON "commerce"."permission"("resource", "action");

-- CreateIndex
CREATE UNIQUE INDEX "role_permission_tenant_id_id_key" ON "commerce"."role_permission"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "role_permission_tenant_id_role_id_permission_id_key" ON "commerce"."role_permission"("tenant_id", "role_id", "permission_id");

-- CreateIndex
CREATE UNIQUE INDEX "access_scope_tenant_id_id_key" ON "commerce"."access_scope"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "role_assignment_tenant_id_id_key" ON "commerce"."role_assignment"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "role_assignment_tenant_id_membership_id_role_id_scope_id_key" ON "commerce"."role_assignment"("tenant_id", "membership_id", "role_id", "scope_id");

-- CreateIndex
CREATE UNIQUE INDEX "invitation_tenant_id_id_key" ON "commerce"."invitation"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "invitation_token_hash_key" ON "commerce"."invitation"("token_hash");

-- CreateIndex
CREATE UNIQUE INDEX "better_auth_session_token_key" ON "commerce"."better_auth_session"("token");

-- CreateIndex
CREATE INDEX "better_auth_session_user_id_idx" ON "commerce"."better_auth_session"("user_id");

-- CreateIndex
CREATE INDEX "better_auth_session_expires_at_idx" ON "commerce"."better_auth_session"("expires_at");

-- CreateIndex
CREATE INDEX "account_user_id_idx" ON "commerce"."account"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "account_provider_id_account_id_key" ON "commerce"."account"("provider_id", "account_id");

-- CreateIndex
CREATE INDEX "verification_identifier_idx" ON "commerce"."verification"("identifier");

-- CreateIndex
CREATE INDEX "verification_expires_at_idx" ON "commerce"."verification"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "inventory_balance_tenant_id_id_key" ON "commerce"."inventory_balance"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "inventory_balance_tenant_id_variant_id_location_id_lot_id_key" ON "commerce"."inventory_balance"("tenant_id", "variant_id", "location_id", "lot_id");

-- CreateIndex
CREATE UNIQUE INDEX "stock_movement_tenant_id_id_key" ON "commerce"."stock_movement"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "stock_reservation_tenant_id_id_key" ON "commerce"."stock_reservation"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "inventory_lot_tenant_id_id_key" ON "commerce"."inventory_lot"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "inventory_lot_tenant_id_variant_id_lot_number_key" ON "commerce"."inventory_lot"("tenant_id", "variant_id", "lot_number");

-- CreateIndex
CREATE UNIQUE INDEX "serialized_item_tenant_id_id_key" ON "commerce"."serialized_item"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "serialized_item_tenant_id_variant_id_serial_number_key" ON "commerce"."serialized_item"("tenant_id", "variant_id", "serial_number");

-- CreateIndex
CREATE UNIQUE INDEX "stock_transfer_tenant_id_id_key" ON "commerce"."stock_transfer"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "stock_transfer_item_tenant_id_id_key" ON "commerce"."stock_transfer_item"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "stock_transfer_item_tenant_id_transfer_id_variant_id_lot_id_key" ON "commerce"."stock_transfer_item"("tenant_id", "transfer_id", "variant_id", "lot_id");

-- CreateIndex
CREATE UNIQUE INDEX "stock_count_tenant_id_id_key" ON "commerce"."stock_count"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "stock_count_item_tenant_id_id_key" ON "commerce"."stock_count_item"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "stock_count_item_tenant_id_count_id_variant_id_lot_id_key" ON "commerce"."stock_count_item"("tenant_id", "count_id", "variant_id", "lot_id");

-- CreateIndex
CREATE UNIQUE INDEX "reorder_policy_tenant_id_id_key" ON "commerce"."reorder_policy"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "reorder_policy_tenant_id_variant_id_location_id_key" ON "commerce"."reorder_policy"("tenant_id", "variant_id", "location_id");

-- CreateIndex
CREATE UNIQUE INDEX "marketplace_listing_tenant_id_id_key" ON "commerce"."marketplace_listing"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "marketplace_listing_tenant_id_company_id_variant_id_key" ON "commerce"."marketplace_listing"("tenant_id", "company_id", "variant_id");

-- CreateIndex
CREATE UNIQUE INDEX "checkout_group_checkout_reference_key" ON "commerce"."checkout_group"("checkout_reference");

-- CreateIndex
CREATE UNIQUE INDEX "commission_rule_tenant_id_id_key" ON "commerce"."commission_rule"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "seller_earning_tenant_id_id_key" ON "commerce"."seller_earning"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "seller_payout_tenant_id_id_key" ON "commerce"."seller_payout"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "seller_payout_tenant_id_idempotency_key_key" ON "commerce"."seller_payout"("tenant_id", "idempotency_key");

-- CreateIndex
CREATE UNIQUE INDEX "seller_payout_item_tenant_id_id_key" ON "commerce"."seller_payout_item"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "seller_payout_item_tenant_id_payout_id_earning_id_key" ON "commerce"."seller_payout_item"("tenant_id", "payout_id", "earning_id");

-- CreateIndex
CREATE UNIQUE INDEX "notification_template_tenant_id_id_key" ON "commerce"."notification_template"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "notification_template_tenant_id_event_type_channel_locale_v_key" ON "commerce"."notification_template"("tenant_id", "event_type", "channel", "locale", "version");

-- CreateIndex
CREATE UNIQUE INDEX "notification_tenant_id_id_key" ON "commerce"."notification"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "notification_attempt_tenant_id_id_key" ON "commerce"."notification_attempt"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "notification_preference_tenant_id_id_key" ON "commerce"."notification_preference"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "notification_preference_tenant_id_customer_id_membership_id_key" ON "commerce"."notification_preference"("tenant_id", "customer_id", "membership_id", "channel", "purpose");

-- CreateIndex
CREATE UNIQUE INDEX "support_ticket_tenant_id_id_key" ON "commerce"."support_ticket"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "support_message_tenant_id_id_key" ON "commerce"."support_message"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_method_tenant_id_id_key" ON "commerce"."payment_method"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_provider_account_tenant_id_id_key" ON "commerce"."payment_provider_account"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_tenant_id_id_key" ON "commerce"."payment"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_tenant_id_idempotency_key_key" ON "commerce"."payment"("tenant_id", "idempotency_key");

-- CreateIndex
CREATE UNIQUE INDEX "payment_attempt_tenant_id_id_key" ON "commerce"."payment_attempt"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_event_tenant_id_id_key" ON "commerce"."payment_event"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_allocation_tenant_id_id_key" ON "commerce"."payment_allocation"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_allocation_tenant_id_payment_id_invoice_id_key" ON "commerce"."payment_allocation"("tenant_id", "payment_id", "invoice_id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_webhook_event_tenant_id_id_key" ON "commerce"."payment_webhook_event"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_webhook_event_provider_account_id_provider_event_id_key" ON "commerce"."payment_webhook_event"("provider_account_id", "provider_event_id");

-- CreateIndex
CREATE UNIQUE INDEX "refund_tenant_id_id_key" ON "commerce"."refund"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "refund_tenant_id_idempotency_key_key" ON "commerce"."refund"("tenant_id", "idempotency_key");

-- CreateIndex
CREATE UNIQUE INDEX "payment_dispute_tenant_id_id_key" ON "commerce"."payment_dispute"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_dispute_tenant_id_payment_id_provider_case_id_key" ON "commerce"."payment_dispute"("tenant_id", "payment_id", "provider_case_id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_settlement_tenant_id_id_key" ON "commerce"."payment_settlement"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_settlement_tenant_id_provider_account_id_external_i_key" ON "commerce"."payment_settlement"("tenant_id", "provider_account_id", "external_id");

-- CreateIndex
CREATE UNIQUE INDEX "supplier_tenant_id_id_key" ON "commerce"."supplier"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "supplier_product_tenant_id_id_key" ON "commerce"."supplier_product"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "supplier_product_tenant_id_supplier_id_variant_id_key" ON "commerce"."supplier_product"("tenant_id", "supplier_id", "variant_id");

-- CreateIndex
CREATE UNIQUE INDEX "purchase_order_tenant_id_id_key" ON "commerce"."purchase_order"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "purchase_order_tenant_id_number_key" ON "commerce"."purchase_order"("tenant_id", "number");

-- CreateIndex
CREATE UNIQUE INDEX "purchase_order_item_tenant_id_id_key" ON "commerce"."purchase_order_item"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "goods_receipt_tenant_id_id_key" ON "commerce"."goods_receipt"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "goods_receipt_item_tenant_id_id_key" ON "commerce"."goods_receipt_item"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "supplier_invoice_tenant_id_id_key" ON "commerce"."supplier_invoice"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "supplier_invoice_tenant_id_supplier_id_number_key" ON "commerce"."supplier_invoice"("tenant_id", "supplier_id", "number");

-- CreateIndex
CREATE UNIQUE INDEX "supplier_invoice_item_tenant_id_id_key" ON "commerce"."supplier_invoice_item"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "audit_event_tenant_id_id_key" ON "commerce"."audit_event"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "security_event_tenant_id_id_key" ON "commerce"."security_event"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "file_object_tenant_id_id_key" ON "commerce"."file_object"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "idempotency_record_tenant_id_id_key" ON "commerce"."idempotency_record"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "idempotency_record_tenant_id_operation_key_key" ON "commerce"."idempotency_record"("tenant_id", "operation", "key");

-- CreateIndex
CREATE UNIQUE INDEX "outbox_event_tenant_id_id_key" ON "commerce"."outbox_event"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "inbox_event_consumer_name_event_id_key" ON "commerce"."inbox_event"("consumer_name", "event_id");

-- CreateIndex
CREATE UNIQUE INDEX "integration_connection_tenant_id_id_key" ON "commerce"."integration_connection"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "cart_tenant_id_id_key" ON "commerce"."cart"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "cart_item_tenant_id_id_key" ON "commerce"."cart_item"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "cart_item_tenant_id_cart_id_variant_id_key" ON "commerce"."cart_item"("tenant_id", "cart_id", "variant_id");

-- CreateIndex
CREATE UNIQUE INDEX "order_tenant_id_id_key" ON "commerce"."order"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "order_tenant_id_number_key" ON "commerce"."order"("tenant_id", "number");

-- CreateIndex
CREATE UNIQUE INDEX "order_item_tenant_id_id_key" ON "commerce"."order_item"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "order_address_tenant_id_id_key" ON "commerce"."order_address"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "order_status_event_tenant_id_id_key" ON "commerce"."order_status_event"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "tax_rate_tenant_id_id_key" ON "commerce"."tax_rate"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "order_item_tax_tenant_id_id_key" ON "commerce"."order_item_tax"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "promotion_tenant_id_id_key" ON "commerce"."promotion"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "coupon_tenant_id_id_key" ON "commerce"."coupon"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "coupon_tenant_id_code_key" ON "commerce"."coupon"("tenant_id", "code");

-- CreateIndex
CREATE UNIQUE INDEX "promotion_redemption_tenant_id_id_key" ON "commerce"."promotion_redemption"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "sales_invoice_tenant_id_id_key" ON "commerce"."sales_invoice"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "sales_invoice_tenant_id_number_key" ON "commerce"."sales_invoice"("tenant_id", "number");

-- CreateIndex
CREATE UNIQUE INDEX "seller_company_tenant_id_id_key" ON "commerce"."seller_company"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "seller_company_tenant_id_key" ON "commerce"."seller_company"("tenant_id");

-- CreateIndex
CREATE UNIQUE INDEX "seller_company_slug_key" ON "commerce"."seller_company"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "company_ownership_tenant_id_id_key" ON "commerce"."company_ownership"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "company_ownership_tenant_id_company_id_user_id_valid_from_key" ON "commerce"."company_ownership"("tenant_id", "company_id", "user_id", "valid_from");

-- CreateIndex
CREATE UNIQUE INDEX "company_verification_tenant_id_id_key" ON "commerce"."company_verification"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "company_contact_tenant_id_id_key" ON "commerce"."company_contact"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "seller_agreement_tenant_id_id_key" ON "commerce"."seller_agreement"("tenant_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "seller_payout_account_tenant_id_id_key" ON "commerce"."seller_payout_account"("tenant_id", "id");

-- AddForeignKey
ALTER TABLE "commerce"."ledger_account" ADD CONSTRAINT "fk_ledger_account_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."ledger_account" ADD CONSTRAINT "fk_ledger_account_parent_id" FOREIGN KEY ("tenant_id", "parent_id") REFERENCES "commerce"."ledger_account"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."fiscal_period" ADD CONSTRAINT "fk_fiscal_period_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."journal_entry" ADD CONSTRAINT "fk_journal_entry_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."journal_entry" ADD CONSTRAINT "fk_journal_entry_period_id" FOREIGN KEY ("tenant_id", "period_id") REFERENCES "commerce"."fiscal_period"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."journal_entry" ADD CONSTRAINT "fk_journal_entry_reversal_of_id" FOREIGN KEY ("tenant_id", "reversal_of_id") REFERENCES "commerce"."journal_entry"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."journal_entry" ADD CONSTRAINT "fk_journal_entry_posted_by" FOREIGN KEY ("tenant_id", "posted_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."journal_line" ADD CONSTRAINT "fk_journal_line_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."journal_line" ADD CONSTRAINT "fk_journal_line_entry_id" FOREIGN KEY ("tenant_id", "entry_id") REFERENCES "commerce"."journal_entry"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."journal_line" ADD CONSTRAINT "fk_journal_line_account_id" FOREIGN KEY ("tenant_id", "account_id") REFERENCES "commerce"."ledger_account"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."journal_line" ADD CONSTRAINT "fk_journal_line_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."bank_account" ADD CONSTRAINT "fk_bank_account_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."bank_account" ADD CONSTRAINT "fk_bank_account_ledger_account_id" FOREIGN KEY ("tenant_id", "ledger_account_id") REFERENCES "commerce"."ledger_account"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."bank_statement_line" ADD CONSTRAINT "fk_bank_statement_line_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."bank_statement_line" ADD CONSTRAINT "fk_bank_statement_line_bank_account_id" FOREIGN KEY ("tenant_id", "bank_account_id") REFERENCES "commerce"."bank_account"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."reconciliation_match" ADD CONSTRAINT "fk_reconciliation_match_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."reconciliation_match" ADD CONSTRAINT "fk_reconciliation_match_statement_line_id" FOREIGN KEY ("tenant_id", "statement_line_id") REFERENCES "commerce"."bank_statement_line"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."reconciliation_match" ADD CONSTRAINT "fk_reconciliation_match_journal_line_id" FOREIGN KEY ("tenant_id", "journal_line_id") REFERENCES "commerce"."journal_line"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."reconciliation_match" ADD CONSTRAINT "fk_reconciliation_match_matched_by" FOREIGN KEY ("tenant_id", "matched_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."expense" ADD CONSTRAINT "fk_expense_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."expense" ADD CONSTRAINT "fk_expense_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."expense" ADD CONSTRAINT "fk_expense_supplier_id" FOREIGN KEY ("tenant_id", "supplier_id") REFERENCES "commerce"."supplier"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."expense" ADD CONSTRAINT "fk_expense_account_id" FOREIGN KEY ("tenant_id", "account_id") REFERENCES "commerce"."ledger_account"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."expense" ADD CONSTRAINT "fk_expense_file_id" FOREIGN KEY ("file_id") REFERENCES "commerce"."file_object"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_payment" ADD CONSTRAINT "fk_supplier_payment_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_payment" ADD CONSTRAINT "fk_supplier_payment_supplier_id" FOREIGN KEY ("tenant_id", "supplier_id") REFERENCES "commerce"."supplier"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_payment" ADD CONSTRAINT "fk_supplier_payment_bank_account_id" FOREIGN KEY ("tenant_id", "bank_account_id") REFERENCES "commerce"."bank_account"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_payment" ADD CONSTRAINT "fk_supplier_payment_cash_session_id" FOREIGN KEY ("tenant_id", "cash_session_id") REFERENCES "commerce"."cash_session"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_payment_allocation" ADD CONSTRAINT "fk_supplier_payment_allocation_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_payment_allocation" ADD CONSTRAINT "fk_supplier_payment_allocation_payment_id" FOREIGN KEY ("tenant_id", "payment_id") REFERENCES "commerce"."supplier_payment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_payment_allocation" ADD CONSTRAINT "fk_supplier_payment_allocation_invoice_id" FOREIGN KEY ("tenant_id", "invoice_id") REFERENCES "commerce"."supplier_invoice"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."analytics_job" ADD CONSTRAINT "fk_analytics_job_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."model_version" ADD CONSTRAINT "fk_model_version_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."demand_forecast" ADD CONSTRAINT "fk_demand_forecast_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."demand_forecast" ADD CONSTRAINT "fk_demand_forecast_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."demand_forecast" ADD CONSTRAINT "fk_demand_forecast_location_id" FOREIGN KEY ("tenant_id", "location_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."demand_forecast" ADD CONSTRAINT "fk_demand_forecast_model_version_id" FOREIGN KEY ("model_version_id") REFERENCES "commerce"."model_version"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."business_insight" ADD CONSTRAINT "fk_business_insight_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."business_insight" ADD CONSTRAINT "fk_business_insight_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."business_insight" ADD CONSTRAINT "fk_business_insight_model_version_id" FOREIGN KEY ("model_version_id") REFERENCES "commerce"."model_version"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."recommendation_decision" ADD CONSTRAINT "fk_recommendation_decision_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."recommendation_decision" ADD CONSTRAINT "fk_recommendation_decision_insight_id" FOREIGN KEY ("tenant_id", "insight_id") REFERENCES "commerce"."business_insight"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."recommendation_decision" ADD CONSTRAINT "fk_recommendation_decision_decided_by" FOREIGN KEY ("tenant_id", "decided_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."report_job" ADD CONSTRAINT "fk_report_job_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."report_job" ADD CONSTRAINT "fk_report_job_requested_by" FOREIGN KEY ("tenant_id", "requested_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."report_job" ADD CONSTRAINT "fk_report_job_file_id" FOREIGN KEY ("file_id") REFERENCES "commerce"."file_object"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."tenant_setting" ADD CONSTRAINT "fk_tenant_setting_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."branch" ADD CONSTRAINT "fk_branch_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."branch" ADD CONSTRAINT "fk_branch_address_id" FOREIGN KEY ("tenant_id", "address_id") REFERENCES "commerce"."address"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."department" ADD CONSTRAINT "fk_department_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."department" ADD CONSTRAINT "fk_department_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."department" ADD CONSTRAINT "fk_department_parent_id" FOREIGN KEY ("tenant_id", "parent_id") REFERENCES "commerce"."department"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."location" ADD CONSTRAINT "fk_location_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."location" ADD CONSTRAINT "fk_location_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."location" ADD CONSTRAINT "fk_location_parent_id" FOREIGN KEY ("tenant_id", "parent_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."address" ADD CONSTRAINT "fk_address_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."business_registration" ADD CONSTRAINT "fk_business_registration_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."business_registration" ADD CONSTRAINT "fk_business_registration_file_id" FOREIGN KEY ("file_id") REFERENCES "commerce"."file_object"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."document_sequence" ADD CONSTRAINT "fk_document_sequence_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."document_sequence" ADD CONSTRAINT "fk_document_sequence_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."pos_terminal" ADD CONSTRAINT "fk_pos_terminal_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."pos_terminal" ADD CONSTRAINT "fk_pos_terminal_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_drawer" ADD CONSTRAINT "fk_cash_drawer_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_drawer" ADD CONSTRAINT "fk_cash_drawer_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_drawer" ADD CONSTRAINT "fk_cash_drawer_terminal_id" FOREIGN KEY ("tenant_id", "terminal_id") REFERENCES "commerce"."pos_terminal"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_session" ADD CONSTRAINT "fk_cash_session_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_session" ADD CONSTRAINT "fk_cash_session_drawer_id" FOREIGN KEY ("tenant_id", "drawer_id") REFERENCES "commerce"."cash_drawer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_session" ADD CONSTRAINT "fk_cash_session_cashier_id" FOREIGN KEY ("tenant_id", "cashier_id") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_session" ADD CONSTRAINT "fk_cash_session_audited_by" FOREIGN KEY ("tenant_id", "audited_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_movement" ADD CONSTRAINT "fk_cash_movement_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_movement" ADD CONSTRAINT "fk_cash_movement_session_id" FOREIGN KEY ("tenant_id", "session_id") REFERENCES "commerce"."cash_session"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_movement" ADD CONSTRAINT "fk_cash_movement_payment_id" FOREIGN KEY ("tenant_id", "payment_id") REFERENCES "commerce"."payment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_movement" ADD CONSTRAINT "fk_cash_movement_refund_id" FOREIGN KEY ("tenant_id", "refund_id") REFERENCES "commerce"."refund"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_movement" ADD CONSTRAINT "fk_cash_movement_actor_id" FOREIGN KEY ("tenant_id", "actor_id") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_count" ADD CONSTRAINT "fk_cash_count_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_count" ADD CONSTRAINT "fk_cash_count_session_id" FOREIGN KEY ("tenant_id", "session_id") REFERENCES "commerce"."cash_session"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_count" ADD CONSTRAINT "fk_cash_count_counted_by" FOREIGN KEY ("tenant_id", "counted_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_deposit" ADD CONSTRAINT "fk_cash_deposit_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_deposit" ADD CONSTRAINT "fk_cash_deposit_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_deposit" ADD CONSTRAINT "fk_cash_deposit_session_id" FOREIGN KEY ("tenant_id", "session_id") REFERENCES "commerce"."cash_session"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_deposit" ADD CONSTRAINT "fk_cash_deposit_bank_account_id" FOREIGN KEY ("tenant_id", "bank_account_id") REFERENCES "commerce"."bank_account"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cash_deposit" ADD CONSTRAINT "fk_cash_deposit_verified_by" FOREIGN KEY ("tenant_id", "verified_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cod_collection" ADD CONSTRAINT "fk_cod_collection_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cod_collection" ADD CONSTRAINT "fk_cod_collection_shipment_id" FOREIGN KEY ("tenant_id", "shipment_id") REFERENCES "commerce"."shipment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cod_collection" ADD CONSTRAINT "fk_cod_collection_payment_id" FOREIGN KEY ("tenant_id", "payment_id") REFERENCES "commerce"."payment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cod_remittance" ADD CONSTRAINT "fk_cod_remittance_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cod_remittance" ADD CONSTRAINT "fk_cod_remittance_collection_id" FOREIGN KEY ("tenant_id", "collection_id") REFERENCES "commerce"."cod_collection"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cod_remittance" ADD CONSTRAINT "fk_cod_remittance_carrier_id" FOREIGN KEY ("tenant_id", "carrier_id") REFERENCES "commerce"."carrier"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."product" ADD CONSTRAINT "fk_product_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."product" ADD CONSTRAINT "fk_product_brand_id" FOREIGN KEY ("tenant_id", "brand_id") REFERENCES "commerce"."brand"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."product_variant" ADD CONSTRAINT "fk_product_variant_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."product_variant" ADD CONSTRAINT "fk_product_variant_product_id" FOREIGN KEY ("tenant_id", "product_id") REFERENCES "commerce"."product"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."product_variant" ADD CONSTRAINT "fk_product_variant_unit_id" FOREIGN KEY ("tenant_id", "unit_id") REFERENCES "commerce"."unit_of_measure"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."category" ADD CONSTRAINT "fk_category_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."category" ADD CONSTRAINT "fk_category_parent_id" FOREIGN KEY ("tenant_id", "parent_id") REFERENCES "commerce"."category"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."product_category" ADD CONSTRAINT "fk_product_category_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."product_category" ADD CONSTRAINT "fk_product_category_product_id" FOREIGN KEY ("tenant_id", "product_id") REFERENCES "commerce"."product"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."product_category" ADD CONSTRAINT "fk_product_category_category_id" FOREIGN KEY ("tenant_id", "category_id") REFERENCES "commerce"."category"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."brand" ADD CONSTRAINT "fk_brand_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."unit_of_measure" ADD CONSTRAINT "fk_unit_of_measure_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."product_attribute" ADD CONSTRAINT "fk_product_attribute_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."variant_attribute_value" ADD CONSTRAINT "fk_variant_attribute_value_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."variant_attribute_value" ADD CONSTRAINT "fk_variant_attribute_value_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."variant_attribute_value" ADD CONSTRAINT "fk_variant_attribute_value_attribute_id" FOREIGN KEY ("tenant_id", "attribute_id") REFERENCES "commerce"."product_attribute"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."product_media" ADD CONSTRAINT "fk_product_media_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."product_media" ADD CONSTRAINT "fk_product_media_product_id" FOREIGN KEY ("tenant_id", "product_id") REFERENCES "commerce"."product"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."product_media" ADD CONSTRAINT "fk_product_media_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."product_media" ADD CONSTRAINT "fk_product_media_file_id" FOREIGN KEY ("file_id") REFERENCES "commerce"."file_object"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."price_list" ADD CONSTRAINT "fk_price_list_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."price_list" ADD CONSTRAINT "fk_price_list_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."price_list" ADD CONSTRAINT "fk_price_list_segment_id" FOREIGN KEY ("tenant_id", "segment_id") REFERENCES "commerce"."customer_segment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."price_list_item" ADD CONSTRAINT "fk_price_list_item_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."price_list_item" ADD CONSTRAINT "fk_price_list_item_price_list_id" FOREIGN KEY ("tenant_id", "price_list_id") REFERENCES "commerce"."price_list"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."price_list_item" ADD CONSTRAINT "fk_price_list_item_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."customer" ADD CONSTRAINT "fk_customer_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."customer" ADD CONSTRAINT "fk_customer_linked_user_id" FOREIGN KEY ("linked_user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."customer_address" ADD CONSTRAINT "fk_customer_address_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."customer_address" ADD CONSTRAINT "fk_customer_address_customer_id" FOREIGN KEY ("tenant_id", "customer_id") REFERENCES "commerce"."customer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."customer_address" ADD CONSTRAINT "fk_customer_address_address_id" FOREIGN KEY ("tenant_id", "address_id") REFERENCES "commerce"."address"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."customer_consent" ADD CONSTRAINT "fk_customer_consent_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."customer_consent" ADD CONSTRAINT "fk_customer_consent_customer_id" FOREIGN KEY ("tenant_id", "customer_id") REFERENCES "commerce"."customer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."customer_segment" ADD CONSTRAINT "fk_customer_segment_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."customer_segment_member" ADD CONSTRAINT "fk_customer_segment_member_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."customer_segment_member" ADD CONSTRAINT "fk_customer_segment_member_segment_id" FOREIGN KEY ("tenant_id", "segment_id") REFERENCES "commerce"."customer_segment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."customer_segment_member" ADD CONSTRAINT "fk_customer_segment_member_customer_id" FOREIGN KEY ("tenant_id", "customer_id") REFERENCES "commerce"."customer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."customer_credit_account" ADD CONSTRAINT "fk_customer_credit_account_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."customer_credit_account" ADD CONSTRAINT "fk_customer_credit_account_customer_id" FOREIGN KEY ("tenant_id", "customer_id") REFERENCES "commerce"."customer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."carrier" ADD CONSTRAINT "fk_carrier_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."shipment" ADD CONSTRAINT "fk_shipment_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."shipment" ADD CONSTRAINT "fk_shipment_order_id" FOREIGN KEY ("tenant_id", "order_id") REFERENCES "commerce"."order"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."shipment" ADD CONSTRAINT "fk_shipment_carrier_id" FOREIGN KEY ("tenant_id", "carrier_id") REFERENCES "commerce"."carrier"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."shipment" ADD CONSTRAINT "fk_shipment_origin_id" FOREIGN KEY ("tenant_id", "origin_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."shipment" ADD CONSTRAINT "fk_shipment_packed_by" FOREIGN KEY ("tenant_id", "packed_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."shipment_item" ADD CONSTRAINT "fk_shipment_item_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."shipment_item" ADD CONSTRAINT "fk_shipment_item_shipment_id" FOREIGN KEY ("tenant_id", "shipment_id") REFERENCES "commerce"."shipment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."shipment_item" ADD CONSTRAINT "fk_shipment_item_order_item_id" FOREIGN KEY ("tenant_id", "order_item_id") REFERENCES "commerce"."order_item"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."shipment_event" ADD CONSTRAINT "fk_shipment_event_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."shipment_event" ADD CONSTRAINT "fk_shipment_event_shipment_id" FOREIGN KEY ("tenant_id", "shipment_id") REFERENCES "commerce"."shipment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."delivery_proof" ADD CONSTRAINT "fk_delivery_proof_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."delivery_proof" ADD CONSTRAINT "fk_delivery_proof_shipment_id" FOREIGN KEY ("tenant_id", "shipment_id") REFERENCES "commerce"."shipment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."delivery_proof" ADD CONSTRAINT "fk_delivery_proof_file_id" FOREIGN KEY ("file_id") REFERENCES "commerce"."file_object"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."return_policy" ADD CONSTRAINT "fk_return_policy_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."return_request" ADD CONSTRAINT "fk_return_request_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."return_request" ADD CONSTRAINT "fk_return_request_order_id" FOREIGN KEY ("tenant_id", "order_id") REFERENCES "commerce"."order"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."return_request" ADD CONSTRAINT "fk_return_request_customer_id" FOREIGN KEY ("tenant_id", "customer_id") REFERENCES "commerce"."customer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."return_request" ADD CONSTRAINT "fk_return_request_policy_id" FOREIGN KEY ("tenant_id", "policy_id") REFERENCES "commerce"."return_policy"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."return_request" ADD CONSTRAINT "fk_return_request_approved_by" FOREIGN KEY ("tenant_id", "approved_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."return_item" ADD CONSTRAINT "fk_return_item_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."return_item" ADD CONSTRAINT "fk_return_item_request_id" FOREIGN KEY ("tenant_id", "request_id") REFERENCES "commerce"."return_request"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."return_item" ADD CONSTRAINT "fk_return_item_order_item_id" FOREIGN KEY ("tenant_id", "order_item_id") REFERENCES "commerce"."order_item"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."return_inspection" ADD CONSTRAINT "fk_return_inspection_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."return_inspection" ADD CONSTRAINT "fk_return_inspection_return_item_id" FOREIGN KEY ("tenant_id", "return_item_id") REFERENCES "commerce"."return_item"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."return_inspection" ADD CONSTRAINT "fk_return_inspection_inspector_id" FOREIGN KEY ("tenant_id", "inspector_id") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."return_inspection" ADD CONSTRAINT "fk_return_inspection_location_id" FOREIGN KEY ("tenant_id", "location_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."replacement_link" ADD CONSTRAINT "fk_replacement_link_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."replacement_link" ADD CONSTRAINT "fk_replacement_link_return_item_id" FOREIGN KEY ("tenant_id", "return_item_id") REFERENCES "commerce"."return_item"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."replacement_link" ADD CONSTRAINT "fk_replacement_link_replacement_item_id" FOREIGN KEY ("tenant_id", "replacement_item_id") REFERENCES "commerce"."order_item"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."employee_profile" ADD CONSTRAINT "fk_employee_profile_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."employee_profile" ADD CONSTRAINT "fk_employee_profile_membership_id" FOREIGN KEY ("tenant_id", "membership_id") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."employee_profile" ADD CONSTRAINT "fk_employee_profile_department_id" FOREIGN KEY ("tenant_id", "department_id") REFERENCES "commerce"."department"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."employee_branch_assignment" ADD CONSTRAINT "fk_employee_branch_assignment_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."employee_branch_assignment" ADD CONSTRAINT "fk_employee_branch_assignment_employee_id" FOREIGN KEY ("tenant_id", "employee_id") REFERENCES "commerce"."employee_profile"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."employee_branch_assignment" ADD CONSTRAINT "fk_employee_branch_assignment_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."work_shift" ADD CONSTRAINT "fk_work_shift_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."work_shift" ADD CONSTRAINT "fk_work_shift_employee_id" FOREIGN KEY ("tenant_id", "employee_id") REFERENCES "commerce"."employee_profile"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."work_shift" ADD CONSTRAINT "fk_work_shift_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."task" ADD CONSTRAINT "fk_task_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."task" ADD CONSTRAINT "fk_task_assignee_id" FOREIGN KEY ("tenant_id", "assignee_id") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."task" ADD CONSTRAINT "fk_task_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."approval_policy" ADD CONSTRAINT "fk_approval_policy_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."approval_policy" ADD CONSTRAINT "fk_approval_policy_scope_id" FOREIGN KEY ("tenant_id", "scope_id") REFERENCES "commerce"."access_scope"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."approval_policy" ADD CONSTRAINT "fk_approval_policy_required_role_id" FOREIGN KEY ("tenant_id", "required_role_id") REFERENCES "commerce"."role"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."approval_request" ADD CONSTRAINT "fk_approval_request_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."approval_request" ADD CONSTRAINT "fk_approval_request_policy_id" FOREIGN KEY ("tenant_id", "policy_id") REFERENCES "commerce"."approval_policy"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."approval_request" ADD CONSTRAINT "fk_approval_request_requested_by" FOREIGN KEY ("tenant_id", "requested_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."approval_step" ADD CONSTRAINT "fk_approval_step_request_id" FOREIGN KEY ("tenant_id", "request_id") REFERENCES "commerce"."approval_request"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."approval_step" ADD CONSTRAINT "fk_approval_step_required_role_id" FOREIGN KEY ("tenant_id", "required_role_id") REFERENCES "commerce"."role"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."approval_step" ADD CONSTRAINT "fk_approval_step_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."approval_decision" ADD CONSTRAINT "fk_approval_decision_step_id" FOREIGN KEY ("tenant_id", "step_id") REFERENCES "commerce"."approval_step"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."approval_decision" ADD CONSTRAINT "fk_approval_decision_decided_by" FOREIGN KEY ("tenant_id", "decided_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."approval_decision" ADD CONSTRAINT "fk_approval_decision_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_settlement_item" ADD CONSTRAINT "fk_payment_settlement_item_settlement_id" FOREIGN KEY ("tenant_id", "settlement_id") REFERENCES "commerce"."payment_settlement"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_settlement_item" ADD CONSTRAINT "fk_payment_settlement_item_payment_id" FOREIGN KEY ("tenant_id", "payment_id") REFERENCES "commerce"."payment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_settlement_item" ADD CONSTRAINT "fk_payment_settlement_item_refund_id" FOREIGN KEY ("tenant_id", "refund_id") REFERENCES "commerce"."refund"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_settlement_item" ADD CONSTRAINT "fk_payment_settlement_item_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."refund_attempt" ADD CONSTRAINT "fk_refund_attempt_refund_id" FOREIGN KEY ("tenant_id", "refund_id") REFERENCES "commerce"."refund"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."refund_attempt" ADD CONSTRAINT "fk_refund_attempt_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."refund_allocation" ADD CONSTRAINT "fk_refund_allocation_refund_id" FOREIGN KEY ("tenant_id", "refund_id") REFERENCES "commerce"."refund"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."refund_allocation" ADD CONSTRAINT "fk_refund_allocation_payment_allocation_id" FOREIGN KEY ("tenant_id", "payment_allocation_id") REFERENCES "commerce"."payment_allocation"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."refund_allocation" ADD CONSTRAINT "fk_refund_allocation_return_item_id" FOREIGN KEY ("tenant_id", "return_item_id") REFERENCES "commerce"."return_item"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."refund_allocation" ADD CONSTRAINT "fk_refund_allocation_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."daily_sales_snapshot" ADD CONSTRAINT "fk_daily_sales_snapshot_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."daily_sales_snapshot" ADD CONSTRAINT "fk_daily_sales_snapshot_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."daily_sales_snapshot" ADD CONSTRAINT "fk_daily_sales_snapshot_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."inventory_cost_layer" ADD CONSTRAINT "fk_inventory_cost_layer_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."inventory_cost_layer" ADD CONSTRAINT "fk_inventory_cost_layer_receipt_item_id" FOREIGN KEY ("tenant_id", "receipt_item_id") REFERENCES "commerce"."goods_receipt_item"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."inventory_cost_layer" ADD CONSTRAINT "fk_inventory_cost_layer_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."inventory_cost_layer" ADD CONSTRAINT "fk_inventory_cost_layer_location_id" FOREIGN KEY ("tenant_id", "location_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."inventory_cost_allocation" ADD CONSTRAINT "fk_inventory_cost_allocation_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."inventory_cost_allocation" ADD CONSTRAINT "fk_inventory_cost_allocation_layer_id" FOREIGN KEY ("tenant_id", "layer_id") REFERENCES "commerce"."inventory_cost_layer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."inventory_cost_allocation" ADD CONSTRAINT "fk_inventory_cost_allocation_movement_id" FOREIGN KEY ("tenant_id", "movement_id") REFERENCES "commerce"."stock_movement"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."auth_identity" ADD CONSTRAINT "fk_auth_identity_user_id" FOREIGN KEY ("user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."session" ADD CONSTRAINT "fk_session_user_id" FOREIGN KEY ("user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."mfa_factor" ADD CONSTRAINT "fk_mfa_factor_user_id" FOREIGN KEY ("user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."auth_challenge" ADD CONSTRAINT "fk_auth_challenge_user_id" FOREIGN KEY ("user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."tenant_membership" ADD CONSTRAINT "fk_tenant_membership_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."tenant_membership" ADD CONSTRAINT "fk_tenant_membership_user_id" FOREIGN KEY ("user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."role" ADD CONSTRAINT "fk_role_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."role_permission" ADD CONSTRAINT "fk_role_permission_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."role_permission" ADD CONSTRAINT "fk_role_permission_role_id" FOREIGN KEY ("tenant_id", "role_id") REFERENCES "commerce"."role"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."role_permission" ADD CONSTRAINT "fk_role_permission_permission_id" FOREIGN KEY ("permission_id") REFERENCES "commerce"."permission"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."access_scope" ADD CONSTRAINT "fk_access_scope_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."access_scope" ADD CONSTRAINT "fk_access_scope_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."access_scope" ADD CONSTRAINT "fk_access_scope_department_id" FOREIGN KEY ("tenant_id", "department_id") REFERENCES "commerce"."department"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."access_scope" ADD CONSTRAINT "fk_access_scope_location_id" FOREIGN KEY ("tenant_id", "location_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."role_assignment" ADD CONSTRAINT "fk_role_assignment_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."role_assignment" ADD CONSTRAINT "fk_role_assignment_membership_id" FOREIGN KEY ("tenant_id", "membership_id") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."role_assignment" ADD CONSTRAINT "fk_role_assignment_role_id" FOREIGN KEY ("tenant_id", "role_id") REFERENCES "commerce"."role"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."role_assignment" ADD CONSTRAINT "fk_role_assignment_scope_id" FOREIGN KEY ("tenant_id", "scope_id") REFERENCES "commerce"."access_scope"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."invitation" ADD CONSTRAINT "fk_invitation_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."invitation" ADD CONSTRAINT "fk_invitation_role_id" FOREIGN KEY ("tenant_id", "role_id") REFERENCES "commerce"."role"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."invitation" ADD CONSTRAINT "fk_invitation_scope_id" FOREIGN KEY ("tenant_id", "scope_id") REFERENCES "commerce"."access_scope"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."better_auth_session" ADD CONSTRAINT "better_auth_session_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."account" ADD CONSTRAINT "account_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."inventory_balance" ADD CONSTRAINT "fk_inventory_balance_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."inventory_balance" ADD CONSTRAINT "fk_inventory_balance_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."inventory_balance" ADD CONSTRAINT "fk_inventory_balance_location_id" FOREIGN KEY ("tenant_id", "location_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."inventory_balance" ADD CONSTRAINT "fk_inventory_balance_lot_id" FOREIGN KEY ("tenant_id", "lot_id") REFERENCES "commerce"."inventory_lot"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_movement" ADD CONSTRAINT "fk_stock_movement_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_movement" ADD CONSTRAINT "fk_stock_movement_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_movement" ADD CONSTRAINT "fk_stock_movement_location_id" FOREIGN KEY ("tenant_id", "location_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_movement" ADD CONSTRAINT "fk_stock_movement_lot_id" FOREIGN KEY ("tenant_id", "lot_id") REFERENCES "commerce"."inventory_lot"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_movement" ADD CONSTRAINT "fk_stock_movement_performed_by" FOREIGN KEY ("tenant_id", "performed_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_reservation" ADD CONSTRAINT "fk_stock_reservation_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_reservation" ADD CONSTRAINT "fk_stock_reservation_order_item_id" FOREIGN KEY ("tenant_id", "order_item_id") REFERENCES "commerce"."order_item"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_reservation" ADD CONSTRAINT "fk_stock_reservation_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_reservation" ADD CONSTRAINT "fk_stock_reservation_location_id" FOREIGN KEY ("tenant_id", "location_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_reservation" ADD CONSTRAINT "fk_stock_reservation_lot_id" FOREIGN KEY ("tenant_id", "lot_id") REFERENCES "commerce"."inventory_lot"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."inventory_lot" ADD CONSTRAINT "fk_inventory_lot_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."inventory_lot" ADD CONSTRAINT "fk_inventory_lot_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."serialized_item" ADD CONSTRAINT "fk_serialized_item_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."serialized_item" ADD CONSTRAINT "fk_serialized_item_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."serialized_item" ADD CONSTRAINT "fk_serialized_item_lot_id" FOREIGN KEY ("tenant_id", "lot_id") REFERENCES "commerce"."inventory_lot"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."serialized_item" ADD CONSTRAINT "fk_serialized_item_location_id" FOREIGN KEY ("tenant_id", "location_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."serialized_item" ADD CONSTRAINT "fk_serialized_item_sold_order_item_id" FOREIGN KEY ("tenant_id", "sold_order_item_id") REFERENCES "commerce"."order_item"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_transfer" ADD CONSTRAINT "fk_stock_transfer_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_transfer" ADD CONSTRAINT "fk_stock_transfer_from_location_id" FOREIGN KEY ("tenant_id", "from_location_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_transfer" ADD CONSTRAINT "fk_stock_transfer_to_location_id" FOREIGN KEY ("tenant_id", "to_location_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_transfer_item" ADD CONSTRAINT "fk_stock_transfer_item_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_transfer_item" ADD CONSTRAINT "fk_stock_transfer_item_transfer_id" FOREIGN KEY ("tenant_id", "transfer_id") REFERENCES "commerce"."stock_transfer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_transfer_item" ADD CONSTRAINT "fk_stock_transfer_item_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_transfer_item" ADD CONSTRAINT "fk_stock_transfer_item_lot_id" FOREIGN KEY ("tenant_id", "lot_id") REFERENCES "commerce"."inventory_lot"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_count" ADD CONSTRAINT "fk_stock_count_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_count" ADD CONSTRAINT "fk_stock_count_location_id" FOREIGN KEY ("tenant_id", "location_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_count" ADD CONSTRAINT "fk_stock_count_counted_by" FOREIGN KEY ("tenant_id", "counted_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_count" ADD CONSTRAINT "fk_stock_count_approved_by" FOREIGN KEY ("tenant_id", "approved_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_count_item" ADD CONSTRAINT "fk_stock_count_item_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_count_item" ADD CONSTRAINT "fk_stock_count_item_count_id" FOREIGN KEY ("tenant_id", "count_id") REFERENCES "commerce"."stock_count"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_count_item" ADD CONSTRAINT "fk_stock_count_item_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."stock_count_item" ADD CONSTRAINT "fk_stock_count_item_lot_id" FOREIGN KEY ("tenant_id", "lot_id") REFERENCES "commerce"."inventory_lot"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."reorder_policy" ADD CONSTRAINT "fk_reorder_policy_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."reorder_policy" ADD CONSTRAINT "fk_reorder_policy_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."reorder_policy" ADD CONSTRAINT "fk_reorder_policy_location_id" FOREIGN KEY ("tenant_id", "location_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."reorder_policy" ADD CONSTRAINT "fk_reorder_policy_supplier_id" FOREIGN KEY ("tenant_id", "supplier_id") REFERENCES "commerce"."supplier"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."marketplace_listing" ADD CONSTRAINT "fk_marketplace_listing_company_id" FOREIGN KEY ("tenant_id", "company_id") REFERENCES "commerce"."seller_company"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."marketplace_listing" ADD CONSTRAINT "fk_marketplace_listing_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."marketplace_listing" ADD CONSTRAINT "fk_marketplace_listing_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."checkout_group" ADD CONSTRAINT "fk_checkout_group_buyer_user_id" FOREIGN KEY ("buyer_user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."commission_rule" ADD CONSTRAINT "fk_commission_rule_company_id" FOREIGN KEY ("tenant_id", "company_id") REFERENCES "commerce"."seller_company"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."commission_rule" ADD CONSTRAINT "fk_commission_rule_category_id" FOREIGN KEY ("tenant_id", "category_id") REFERENCES "commerce"."category"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."commission_rule" ADD CONSTRAINT "fk_commission_rule_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_earning" ADD CONSTRAINT "fk_seller_earning_company_id" FOREIGN KEY ("tenant_id", "company_id") REFERENCES "commerce"."seller_company"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_earning" ADD CONSTRAINT "fk_seller_earning_order_item_id" FOREIGN KEY ("tenant_id", "order_item_id") REFERENCES "commerce"."order_item"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_earning" ADD CONSTRAINT "fk_seller_earning_rule_id" FOREIGN KEY ("tenant_id", "rule_id") REFERENCES "commerce"."commission_rule"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_earning" ADD CONSTRAINT "fk_seller_earning_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_payout" ADD CONSTRAINT "fk_seller_payout_company_id" FOREIGN KEY ("tenant_id", "company_id") REFERENCES "commerce"."seller_company"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_payout" ADD CONSTRAINT "fk_seller_payout_payout_account_id" FOREIGN KEY ("tenant_id", "payout_account_id") REFERENCES "commerce"."seller_payout_account"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_payout" ADD CONSTRAINT "fk_seller_payout_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_payout_item" ADD CONSTRAINT "fk_seller_payout_item_payout_id" FOREIGN KEY ("tenant_id", "payout_id") REFERENCES "commerce"."seller_payout"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_payout_item" ADD CONSTRAINT "fk_seller_payout_item_earning_id" FOREIGN KEY ("tenant_id", "earning_id") REFERENCES "commerce"."seller_earning"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_payout_item" ADD CONSTRAINT "fk_seller_payout_item_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."notification_template" ADD CONSTRAINT "fk_notification_template_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."notification" ADD CONSTRAINT "fk_notification_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."notification" ADD CONSTRAINT "fk_notification_template_id" FOREIGN KEY ("tenant_id", "template_id") REFERENCES "commerce"."notification_template"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."notification" ADD CONSTRAINT "fk_notification_customer_id" FOREIGN KEY ("tenant_id", "customer_id") REFERENCES "commerce"."customer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."notification" ADD CONSTRAINT "fk_notification_membership_id" FOREIGN KEY ("tenant_id", "membership_id") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."notification_attempt" ADD CONSTRAINT "fk_notification_attempt_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."notification_attempt" ADD CONSTRAINT "fk_notification_attempt_notification_id" FOREIGN KEY ("tenant_id", "notification_id") REFERENCES "commerce"."notification"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."notification_preference" ADD CONSTRAINT "fk_notification_preference_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."notification_preference" ADD CONSTRAINT "fk_notification_preference_customer_id" FOREIGN KEY ("tenant_id", "customer_id") REFERENCES "commerce"."customer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."notification_preference" ADD CONSTRAINT "fk_notification_preference_membership_id" FOREIGN KEY ("tenant_id", "membership_id") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."support_ticket" ADD CONSTRAINT "fk_support_ticket_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."support_ticket" ADD CONSTRAINT "fk_support_ticket_customer_id" FOREIGN KEY ("tenant_id", "customer_id") REFERENCES "commerce"."customer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."support_ticket" ADD CONSTRAINT "fk_support_ticket_order_id" FOREIGN KEY ("tenant_id", "order_id") REFERENCES "commerce"."order"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."support_ticket" ADD CONSTRAINT "fk_support_ticket_assigned_to" FOREIGN KEY ("tenant_id", "assigned_to") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."support_message" ADD CONSTRAINT "fk_support_message_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."support_message" ADD CONSTRAINT "fk_support_message_ticket_id" FOREIGN KEY ("tenant_id", "ticket_id") REFERENCES "commerce"."support_ticket"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."support_message" ADD CONSTRAINT "fk_support_message_file_id" FOREIGN KEY ("file_id") REFERENCES "commerce"."file_object"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_method" ADD CONSTRAINT "fk_payment_method_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_provider_account" ADD CONSTRAINT "fk_payment_provider_account_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment" ADD CONSTRAINT "fk_payment_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment" ADD CONSTRAINT "fk_payment_customer_id" FOREIGN KEY ("tenant_id", "customer_id") REFERENCES "commerce"."customer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment" ADD CONSTRAINT "fk_payment_method_id" FOREIGN KEY ("tenant_id", "method_id") REFERENCES "commerce"."payment_method"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment" ADD CONSTRAINT "fk_payment_provider_account_id" FOREIGN KEY ("tenant_id", "provider_account_id") REFERENCES "commerce"."payment_provider_account"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_attempt" ADD CONSTRAINT "fk_payment_attempt_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_attempt" ADD CONSTRAINT "fk_payment_attempt_payment_id" FOREIGN KEY ("tenant_id", "payment_id") REFERENCES "commerce"."payment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_attempt" ADD CONSTRAINT "fk_payment_attempt_provider_account_id" FOREIGN KEY ("tenant_id", "provider_account_id") REFERENCES "commerce"."payment_provider_account"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_event" ADD CONSTRAINT "fk_payment_event_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_event" ADD CONSTRAINT "fk_payment_event_payment_id" FOREIGN KEY ("tenant_id", "payment_id") REFERENCES "commerce"."payment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_event" ADD CONSTRAINT "fk_payment_event_attempt_id" FOREIGN KEY ("tenant_id", "attempt_id") REFERENCES "commerce"."payment_attempt"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_allocation" ADD CONSTRAINT "fk_payment_allocation_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_allocation" ADD CONSTRAINT "fk_payment_allocation_payment_id" FOREIGN KEY ("tenant_id", "payment_id") REFERENCES "commerce"."payment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_allocation" ADD CONSTRAINT "fk_payment_allocation_invoice_id" FOREIGN KEY ("tenant_id", "invoice_id") REFERENCES "commerce"."sales_invoice"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_webhook_event" ADD CONSTRAINT "fk_payment_webhook_event_provider_account_id" FOREIGN KEY ("tenant_id", "provider_account_id") REFERENCES "commerce"."payment_provider_account"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_webhook_event" ADD CONSTRAINT "fk_payment_webhook_event_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."refund" ADD CONSTRAINT "fk_refund_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."refund" ADD CONSTRAINT "fk_refund_payment_id" FOREIGN KEY ("tenant_id", "payment_id") REFERENCES "commerce"."payment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."refund" ADD CONSTRAINT "fk_refund_return_id" FOREIGN KEY ("tenant_id", "return_id") REFERENCES "commerce"."return_request"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."refund" ADD CONSTRAINT "fk_refund_approved_by" FOREIGN KEY ("tenant_id", "approved_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_dispute" ADD CONSTRAINT "fk_payment_dispute_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_dispute" ADD CONSTRAINT "fk_payment_dispute_payment_id" FOREIGN KEY ("tenant_id", "payment_id") REFERENCES "commerce"."payment"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_settlement" ADD CONSTRAINT "fk_payment_settlement_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."payment_settlement" ADD CONSTRAINT "fk_payment_settlement_provider_account_id" FOREIGN KEY ("tenant_id", "provider_account_id") REFERENCES "commerce"."payment_provider_account"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier" ADD CONSTRAINT "fk_supplier_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier" ADD CONSTRAINT "fk_supplier_address_id" FOREIGN KEY ("tenant_id", "address_id") REFERENCES "commerce"."address"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_product" ADD CONSTRAINT "fk_supplier_product_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_product" ADD CONSTRAINT "fk_supplier_product_supplier_id" FOREIGN KEY ("tenant_id", "supplier_id") REFERENCES "commerce"."supplier"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_product" ADD CONSTRAINT "fk_supplier_product_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."purchase_order" ADD CONSTRAINT "fk_purchase_order_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."purchase_order" ADD CONSTRAINT "fk_purchase_order_supplier_id" FOREIGN KEY ("tenant_id", "supplier_id") REFERENCES "commerce"."supplier"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."purchase_order" ADD CONSTRAINT "fk_purchase_order_destination_id" FOREIGN KEY ("tenant_id", "destination_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."purchase_order" ADD CONSTRAINT "fk_purchase_order_approved_by" FOREIGN KEY ("tenant_id", "approved_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."purchase_order_item" ADD CONSTRAINT "fk_purchase_order_item_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."purchase_order_item" ADD CONSTRAINT "fk_purchase_order_item_purchase_order_id" FOREIGN KEY ("tenant_id", "purchase_order_id") REFERENCES "commerce"."purchase_order"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."purchase_order_item" ADD CONSTRAINT "fk_purchase_order_item_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."goods_receipt" ADD CONSTRAINT "fk_goods_receipt_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."goods_receipt" ADD CONSTRAINT "fk_goods_receipt_supplier_id" FOREIGN KEY ("tenant_id", "supplier_id") REFERENCES "commerce"."supplier"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."goods_receipt" ADD CONSTRAINT "fk_goods_receipt_purchase_order_id" FOREIGN KEY ("tenant_id", "purchase_order_id") REFERENCES "commerce"."purchase_order"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."goods_receipt" ADD CONSTRAINT "fk_goods_receipt_location_id" FOREIGN KEY ("tenant_id", "location_id") REFERENCES "commerce"."location"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."goods_receipt" ADD CONSTRAINT "fk_goods_receipt_received_by" FOREIGN KEY ("tenant_id", "received_by") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."goods_receipt_item" ADD CONSTRAINT "fk_goods_receipt_item_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."goods_receipt_item" ADD CONSTRAINT "fk_goods_receipt_item_receipt_id" FOREIGN KEY ("tenant_id", "receipt_id") REFERENCES "commerce"."goods_receipt"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."goods_receipt_item" ADD CONSTRAINT "fk_goods_receipt_item_po_item_id" FOREIGN KEY ("tenant_id", "po_item_id") REFERENCES "commerce"."purchase_order_item"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."goods_receipt_item" ADD CONSTRAINT "fk_goods_receipt_item_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."goods_receipt_item" ADD CONSTRAINT "fk_goods_receipt_item_lot_id" FOREIGN KEY ("tenant_id", "lot_id") REFERENCES "commerce"."inventory_lot"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_invoice" ADD CONSTRAINT "fk_supplier_invoice_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_invoice" ADD CONSTRAINT "fk_supplier_invoice_supplier_id" FOREIGN KEY ("tenant_id", "supplier_id") REFERENCES "commerce"."supplier"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_invoice" ADD CONSTRAINT "fk_supplier_invoice_purchase_order_id" FOREIGN KEY ("tenant_id", "purchase_order_id") REFERENCES "commerce"."purchase_order"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_invoice_item" ADD CONSTRAINT "fk_supplier_invoice_item_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_invoice_item" ADD CONSTRAINT "fk_supplier_invoice_item_invoice_id" FOREIGN KEY ("tenant_id", "invoice_id") REFERENCES "commerce"."supplier_invoice"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_invoice_item" ADD CONSTRAINT "fk_supplier_invoice_item_po_item_id" FOREIGN KEY ("tenant_id", "po_item_id") REFERENCES "commerce"."purchase_order_item"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."supplier_invoice_item" ADD CONSTRAINT "fk_supplier_invoice_item_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."audit_event" ADD CONSTRAINT "fk_audit_event_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."audit_event" ADD CONSTRAINT "fk_audit_event_actor_id" FOREIGN KEY ("actor_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."security_event" ADD CONSTRAINT "fk_security_event_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."security_event" ADD CONSTRAINT "fk_security_event_user_id" FOREIGN KEY ("user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."file_object" ADD CONSTRAINT "fk_file_object_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."file_object" ADD CONSTRAINT "fk_file_object_uploaded_by" FOREIGN KEY ("uploaded_by") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."idempotency_record" ADD CONSTRAINT "fk_idempotency_record_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."outbox_event" ADD CONSTRAINT "fk_outbox_event_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."integration_connection" ADD CONSTRAINT "fk_integration_connection_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cart" ADD CONSTRAINT "fk_cart_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cart" ADD CONSTRAINT "fk_cart_customer_id" FOREIGN KEY ("tenant_id", "customer_id") REFERENCES "commerce"."customer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cart" ADD CONSTRAINT "fk_cart_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cart_item" ADD CONSTRAINT "fk_cart_item_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cart_item" ADD CONSTRAINT "fk_cart_item_cart_id" FOREIGN KEY ("tenant_id", "cart_id") REFERENCES "commerce"."cart"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."cart_item" ADD CONSTRAINT "fk_cart_item_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order" ADD CONSTRAINT "fk_order_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order" ADD CONSTRAINT "fk_order_branch_id" FOREIGN KEY ("tenant_id", "branch_id") REFERENCES "commerce"."branch"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order" ADD CONSTRAINT "fk_order_customer_id" FOREIGN KEY ("tenant_id", "customer_id") REFERENCES "commerce"."customer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order" ADD CONSTRAINT "fk_order_checkout_group_id" FOREIGN KEY ("checkout_group_id") REFERENCES "commerce"."checkout_group"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order" ADD CONSTRAINT "fk_order_seller_id" FOREIGN KEY ("tenant_id", "seller_id") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order_item" ADD CONSTRAINT "fk_order_item_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order_item" ADD CONSTRAINT "fk_order_item_order_id" FOREIGN KEY ("tenant_id", "order_id") REFERENCES "commerce"."order"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order_item" ADD CONSTRAINT "fk_order_item_variant_id" FOREIGN KEY ("tenant_id", "variant_id") REFERENCES "commerce"."product_variant"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order_address" ADD CONSTRAINT "fk_order_address_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order_address" ADD CONSTRAINT "fk_order_address_order_id" FOREIGN KEY ("tenant_id", "order_id") REFERENCES "commerce"."order"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order_status_event" ADD CONSTRAINT "fk_order_status_event_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order_status_event" ADD CONSTRAINT "fk_order_status_event_order_id" FOREIGN KEY ("tenant_id", "order_id") REFERENCES "commerce"."order"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order_status_event" ADD CONSTRAINT "fk_order_status_event_actor_id" FOREIGN KEY ("tenant_id", "actor_id") REFERENCES "commerce"."tenant_membership"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."tax_rate" ADD CONSTRAINT "fk_tax_rate_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order_item_tax" ADD CONSTRAINT "fk_order_item_tax_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order_item_tax" ADD CONSTRAINT "fk_order_item_tax_order_item_id" FOREIGN KEY ("tenant_id", "order_item_id") REFERENCES "commerce"."order_item"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."order_item_tax" ADD CONSTRAINT "fk_order_item_tax_tax_rate_id" FOREIGN KEY ("tenant_id", "tax_rate_id") REFERENCES "commerce"."tax_rate"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."promotion" ADD CONSTRAINT "fk_promotion_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."coupon" ADD CONSTRAINT "fk_coupon_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."coupon" ADD CONSTRAINT "fk_coupon_promotion_id" FOREIGN KEY ("tenant_id", "promotion_id") REFERENCES "commerce"."promotion"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."promotion_redemption" ADD CONSTRAINT "fk_promotion_redemption_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."promotion_redemption" ADD CONSTRAINT "fk_promotion_redemption_promotion_id" FOREIGN KEY ("tenant_id", "promotion_id") REFERENCES "commerce"."promotion"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."promotion_redemption" ADD CONSTRAINT "fk_promotion_redemption_coupon_id" FOREIGN KEY ("tenant_id", "coupon_id") REFERENCES "commerce"."coupon"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."promotion_redemption" ADD CONSTRAINT "fk_promotion_redemption_order_id" FOREIGN KEY ("tenant_id", "order_id") REFERENCES "commerce"."order"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."promotion_redemption" ADD CONSTRAINT "fk_promotion_redemption_customer_id" FOREIGN KEY ("tenant_id", "customer_id") REFERENCES "commerce"."customer"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."sales_invoice" ADD CONSTRAINT "fk_sales_invoice_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."sales_invoice" ADD CONSTRAINT "fk_sales_invoice_order_id" FOREIGN KEY ("tenant_id", "order_id") REFERENCES "commerce"."order"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_company" ADD CONSTRAINT "fk_seller_company_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_company" ADD CONSTRAINT "fk_seller_company_logo_file_id" FOREIGN KEY ("logo_file_id") REFERENCES "commerce"."file_object"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."company_ownership" ADD CONSTRAINT "fk_company_ownership_company_id" FOREIGN KEY ("tenant_id", "company_id") REFERENCES "commerce"."seller_company"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."company_ownership" ADD CONSTRAINT "fk_company_ownership_user_id" FOREIGN KEY ("user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."company_ownership" ADD CONSTRAINT "fk_company_ownership_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."company_verification" ADD CONSTRAINT "fk_company_verification_company_id" FOREIGN KEY ("tenant_id", "company_id") REFERENCES "commerce"."seller_company"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."company_verification" ADD CONSTRAINT "fk_company_verification_file_id" FOREIGN KEY ("file_id") REFERENCES "commerce"."file_object"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."company_verification" ADD CONSTRAINT "fk_company_verification_reviewer_id" FOREIGN KEY ("reviewer_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."company_verification" ADD CONSTRAINT "fk_company_verification_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."company_contact" ADD CONSTRAINT "fk_company_contact_company_id" FOREIGN KEY ("tenant_id", "company_id") REFERENCES "commerce"."seller_company"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."company_contact" ADD CONSTRAINT "fk_company_contact_user_id" FOREIGN KEY ("user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."company_contact" ADD CONSTRAINT "fk_company_contact_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_agreement" ADD CONSTRAINT "fk_seller_agreement_company_id" FOREIGN KEY ("tenant_id", "company_id") REFERENCES "commerce"."seller_company"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_agreement" ADD CONSTRAINT "fk_seller_agreement_file_id" FOREIGN KEY ("file_id") REFERENCES "commerce"."file_object"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_agreement" ADD CONSTRAINT "fk_seller_agreement_accepted_by" FOREIGN KEY ("accepted_by") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_agreement" ADD CONSTRAINT "fk_seller_agreement_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_payout_account" ADD CONSTRAINT "fk_seller_payout_account_company_id" FOREIGN KEY ("tenant_id", "company_id") REFERENCES "commerce"."seller_company"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_payout_account" ADD CONSTRAINT "fk_seller_payout_account_provider_account_id" FOREIGN KEY ("tenant_id", "provider_account_id") REFERENCES "commerce"."payment_provider_account"("tenant_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."seller_payout_account" ADD CONSTRAINT "fk_seller_payout_account_tenant_id" FOREIGN KEY ("tenant_id") REFERENCES "commerce"."tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
