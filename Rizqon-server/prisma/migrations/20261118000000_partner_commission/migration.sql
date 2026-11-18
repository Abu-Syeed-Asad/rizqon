-- Additive migration. No historical financial amount or legacy relation is rewritten.
BEGIN;
SET LOCAL lock_timeout = '10s';

-- AlterTable
ALTER TABLE "commerce"."CommissionAgreement" ADD COLUMN     "expiredAt" TIMESTAMP(3),
ADD COLUMN     "firstActivatedAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "commerce"."CommissionSettlement" ADD COLUMN     "currency" TEXT,
ADD COLUMN     "idempotencyKey" TEXT,
ADD COLUMN     "requestHash" TEXT;

-- AlterTable
ALTER TABLE "commerce"."Payment" ADD COLUMN     "requestHash" TEXT;

-- AlterTable
ALTER TABLE "commerce"."SaleReturn" ADD COLUMN     "requestHash" TEXT;

-- CreateTable
CREATE TABLE "commerce"."CommissionAgreementVariant" (
    "businessId" TEXT NOT NULL,
    "agreementId" TEXT NOT NULL,
    "variantId" TEXT NOT NULL,

    CONSTRAINT "CommissionAgreementVariant_pkey" PRIMARY KEY ("businessId","agreementId","variantId")
);

-- CreateTable
CREATE TABLE "commerce"."CommissionAgreementActivation" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "agreementId" TEXT NOT NULL,
    "startsAt" TIMESTAMP(3) NOT NULL,
    "endsAt" TIMESTAMP(3),

    CONSTRAINT "CommissionAgreementActivation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "CommissionAgreementVariant_businessId_variantId_idx" ON "commerce"."CommissionAgreementVariant"("businessId", "variantId");

-- CreateIndex
CREATE INDEX "CommissionAgreementActivation_businessId_agreementId_starts_idx" ON "commerce"."CommissionAgreementActivation"("businessId", "agreementId", "startsAt");

-- CreateIndex
CREATE UNIQUE INDEX "CommissionSettlement_businessId_idempotencyKey_key" ON "commerce"."CommissionSettlement"("businessId", "idempotencyKey");

-- AddForeignKey
ALTER TABLE "commerce"."CommissionAgreementVariant" ADD CONSTRAINT "CommissionAgreementVariant_businessId_agreementId_fkey" FOREIGN KEY ("businessId", "agreementId") REFERENCES "commerce"."CommissionAgreement"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CommissionAgreementVariant" ADD CONSTRAINT "CommissionAgreementVariant_businessId_variantId_fkey" FOREIGN KEY ("businessId", "variantId") REFERENCES "commerce"."ProductVariant"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "commerce"."CommissionAgreementActivation" ADD CONSTRAINT "CommissionAgreementActivation_businessId_agreementId_fkey" FOREIGN KEY ("businessId", "agreementId") REFERENCES "commerce"."CommissionAgreement"("businessId", "id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- Preserve current legacy assignments. The old ProductVariant.agreementId remains readable,
-- but new commission resolution exclusively uses this junction and activation intervals.
INSERT INTO commerce."CommissionAgreementVariant" ("businessId", "agreementId", "variantId")
SELECT "businessId", "agreementId", id FROM commerce."ProductVariant" WHERE "agreementId" IS NOT NULL;

-- Existing agreements are frozen conservatively; their historical draft/activation state was not recorded.
UPDATE commerce."CommissionAgreement" SET "firstActivatedAt" = "createdAt";
INSERT INTO commerce."CommissionAgreementActivation" (id, "businessId", "agreementId", "startsAt", "endsAt")
SELECT 'legacy:' || id, "businessId", id, "startsAt", "endsAt"
FROM commerce."CommissionAgreement" WHERE "isActive" AND ("endsAt" IS NULL OR "endsAt" > "startsAt");

-- NOT VALID leaves legacy rows intact while enforcing constraints on new/updated rows.
ALTER TABLE commerce."CommissionAgreement" ADD CONSTRAINT commission_agreement_rate_dates
CHECK ("commissionPercent" BETWEEN 0 AND 100 AND ("endsAt" IS NULL OR "endsAt" > "startsAt")) NOT VALID;
ALTER TABLE commerce."CommissionAgreementActivation" ADD CONSTRAINT commission_activation_dates
CHECK ("endsAt" IS NULL OR "endsAt" >= "startsAt");
ALTER TABLE commerce."CommissionEntry" ADD CONSTRAINT commission_entry_amounts
CHECK ("commissionPercent" BETWEEN 0 AND 100 AND "grossBase" = "commissionAmount" + "partnerPayable"
AND (("eventType" = 'SALE' AND "returnItemId" IS NULL AND "grossBase" >= 0 AND "commissionAmount" >= 0 AND "partnerPayable" >= 0)
OR ("eventType" = 'RETURN' AND "returnItemId" IS NOT NULL AND "grossBase" <= 0 AND "commissionAmount" <= 0 AND "partnerPayable" <= 0))) NOT VALID;
ALTER TABLE commerce."Payment" ADD CONSTRAINT partner_payment_shape
CHECK ("settlementId" IS NULL OR (direction = 'OUT' AND amount > 0 AND "saleId" IS NULL AND "purchaseId" IS NULL AND "expenseId" IS NULL)) NOT VALID;

-- Fail rather than silently remove pre-existing duplicates. See docs/partner-commissions.md preflight.
CREATE UNIQUE INDEX commission_one_sale_per_item ON commerce."CommissionEntry" ("businessId", "saleItemId") WHERE "eventType" = 'SALE';
CREATE UNIQUE INDEX commission_one_return_per_item ON commerce."CommissionEntry" ("businessId", "returnItemId") WHERE "eventType" = 'RETURN';

CREATE FUNCTION commerce.protect_commission_entry() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE target commerce."CommissionSettlement"%ROWTYPE;
BEGIN
  IF TG_OP = 'DELETE' THEN RAISE EXCEPTION 'Commission entries are append-only' USING ERRCODE = '23514'; END IF;
  IF TG_OP = 'UPDATE' THEN
    IF (to_jsonb(NEW) - 'settlementId' - 'updatedAt') IS DISTINCT FROM (to_jsonb(OLD) - 'settlementId' - 'updatedAt') THEN
      RAISE EXCEPTION 'Commission financial records are immutable' USING ERRCODE = '23514';
    END IF;
    IF OLD."settlementId" IS NOT NULL AND EXISTS (SELECT 1 FROM commerce."CommissionSettlement"
      WHERE "businessId" = OLD."businessId" AND id = OLD."settlementId" AND settlement_status <> 'DRAFT') THEN
      RAISE EXCEPTION 'Finalized settlement entries are immutable' USING ERRCODE = '23514';
    END IF;
  END IF;
  IF NEW."settlementId" IS NOT NULL THEN
    SELECT * INTO target FROM commerce."CommissionSettlement" WHERE "businessId" = NEW."businessId" AND id = NEW."settlementId" FOR UPDATE;
    IF target.settlement_status <> 'DRAFT' OR NOT EXISTS (SELECT 1 FROM commerce."CommissionAgreement"
      WHERE "businessId" = NEW."businessId" AND id = NEW."agreementId" AND "partnerId" = target."partnerId") THEN
      RAISE EXCEPTION 'Entry must belong to the draft settlement partner' USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER protect_commission_entry BEFORE INSERT OR UPDATE OR DELETE ON commerce."CommissionEntry"
FOR EACH ROW EXECUTE FUNCTION commerce.protect_commission_entry();

CREATE FUNCTION commerce.protect_commission_settlement() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN RAISE EXCEPTION 'Settlements must be cancelled, not deleted' USING ERRCODE = '23514'; END IF;
  IF OLD.settlement_status <> 'DRAFT' AND NEW IS DISTINCT FROM OLD THEN
    RAISE EXCEPTION 'Finalized or cancelled settlements are immutable' USING ERRCODE = '23514';
  END IF;
  IF NEW.settlement_status = 'FINALIZED' AND OLD.settlement_status = 'DRAFT' THEN
    IF NEW.amount < 0 OR NEW.currency IS NULL OR NEW."finalizedAt" IS NULL OR
      NEW.amount IS DISTINCT FROM (SELECT SUM("partnerPayable") FROM commerce."CommissionEntry" WHERE "businessId" = NEW."businessId" AND "settlementId" = NEW.id) THEN
      RAISE EXCEPTION 'Finalization requires reconciled entries, currency and nonnegative amount' USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER protect_commission_settlement BEFORE UPDATE OR DELETE ON commerce."CommissionSettlement"
FOR EACH ROW EXECUTE FUNCTION commerce.protect_commission_settlement();

CREATE FUNCTION commerce.protect_commission_agreement() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD."firstActivatedAt" IS NOT NULL AND
    ROW(NEW."businessId", NEW."partnerId", NEW."commissionPercent", NEW."startsAt", NEW."endsAt", NEW."firstActivatedAt") IS DISTINCT FROM
    ROW(OLD."businessId", OLD."partnerId", OLD."commissionPercent", OLD."startsAt", OLD."endsAt", OLD."firstActivatedAt") THEN
    RAISE EXCEPTION 'Activated agreement configuration is immutable' USING ERRCODE = '23514';
  END IF;
  IF OLD."expiredAt" IS NOT NULL AND NEW."expiredAt" IS DISTINCT FROM OLD."expiredAt" THEN
    RAISE EXCEPTION 'Agreement expiration is permanent' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER protect_commission_agreement BEFORE UPDATE ON commerce."CommissionAgreement"
FOR EACH ROW EXECUTE FUNCTION commerce.protect_commission_agreement();

CREATE FUNCTION commerce.protect_commission_assignment() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE row_business text; row_agreement text;
BEGIN
  IF TG_OP = 'UPDATE' THEN RAISE EXCEPTION 'Replace draft assignments using delete/insert' USING ERRCODE = '23514'; END IF;
  IF TG_OP = 'DELETE' THEN row_business := OLD."businessId"; row_agreement := OLD."agreementId";
  ELSE row_business := NEW."businessId"; row_agreement := NEW."agreementId"; END IF;
  IF EXISTS (SELECT 1 FROM commerce."CommissionAgreement" WHERE "businessId" = row_business AND id = row_agreement AND "firstActivatedAt" IS NOT NULL) THEN
    RAISE EXCEPTION 'Activated product assignments are immutable' USING ERRCODE = '23514';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER protect_commission_assignment BEFORE INSERT OR UPDATE OR DELETE ON commerce."CommissionAgreementVariant"
FOR EACH ROW EXECUTE FUNCTION commerce.protect_commission_assignment();

CREATE FUNCTION commerce.protect_partner_payment() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD."settlementId" IS NOT NULL THEN
    IF TG_OP = 'DELETE' THEN RAISE EXCEPTION 'Partner payments cannot be deleted' USING ERRCODE = '23514'; END IF;
    IF OLD.status IN ('SUCCEEDED', 'FAILED', 'CANCELLED') AND NEW IS DISTINCT FROM OLD THEN
      RAISE EXCEPTION 'Terminal partner payments are immutable' USING ERRCODE = '23514';
    END IF;
    IF ROW(NEW."businessId", NEW."settlementId", NEW.amount, NEW.currency, NEW.direction, NEW.method, NEW."idempotencyKey", NEW."requestHash") IS DISTINCT FROM
      ROW(OLD."businessId", OLD."settlementId", OLD.amount, OLD.currency, OLD.direction, OLD.method, OLD."idempotencyKey", OLD."requestHash") THEN
      RAISE EXCEPTION 'Partner payment amounts and identity are immutable' USING ERRCODE = '23514';
    END IF;
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER protect_partner_payment BEFORE UPDATE OR DELETE ON commerce."Payment"
FOR EACH ROW EXECUTE FUNCTION commerce.protect_partner_payment();

COMMIT;
