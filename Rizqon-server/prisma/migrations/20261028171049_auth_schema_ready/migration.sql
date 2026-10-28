-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "commerce";

-- CreateEnum
CREATE TYPE "commerce"."role_code" AS ENUM ('OWNER', 'CEO', 'MANAGER', 'BRANCH_MANAGER', 'PRODUCT_MANAGER', 'SECURITY', 'SELLER', 'ACCOUNTANT', 'SELLER_COMPANY_ADMIN', 'USER');

-- CreateEnum
CREATE TYPE "commerce"."SYSTEM_USER_ROLE" AS ENUM ('RIZQON_OWNER', 'RIZQON_CEO', 'RIZQON_MANAGER', 'RIZQON_BRANCH_MANAGER', 'RIZQON_PRODUCT_MANAGER', 'RIZQON_OFFICE_STAFF', 'RIZQON_SELLER', 'RIZQON_ACCOUNTANT', 'RIZQON_USER');

-- CreateEnum
CREATE TYPE "commerce"."STATUS" AS ENUM ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'DELETED');

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
CREATE TABLE "commerce"."user" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "email" TEXT NOT NULL,
    "phone" TEXT,
    "display_name" TEXT NOT NULL,
    "user_role" "commerce"."SYSTEM_USER_ROLE" NOT NULL DEFAULT 'RIZQON_USER',
    "status" "commerce"."STATUS" NOT NULL DEFAULT 'ACTIVE',
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

-- CreateIndex
CREATE UNIQUE INDEX "user_email_key" ON "commerce"."user"("email");

-- CreateIndex
CREATE UNIQUE INDEX "user_phone_key" ON "commerce"."user"("phone");

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

-- AddForeignKey
ALTER TABLE "commerce"."better_auth_session" ADD CONSTRAINT "better_auth_session_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commerce"."account" ADD CONSTRAINT "account_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "commerce"."user"("id") ON DELETE CASCADE ON UPDATE CASCADE;
