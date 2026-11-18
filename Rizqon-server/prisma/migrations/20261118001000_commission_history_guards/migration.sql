-- Preserve the source snapshots used by immutable commission records.
-- No data is rewritten by this migration.
BEGIN;
SET LOCAL lock_timeout = '10s';

CREATE FUNCTION commerce.protect_commission_activation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN RAISE EXCEPTION 'Activation history cannot be deleted' USING ERRCODE = '23514'; END IF;
  IF ROW(NEW.id, NEW."businessId", NEW."agreementId", NEW."startsAt") IS DISTINCT FROM
    ROW(OLD.id, OLD."businessId", OLD."agreementId", OLD."startsAt") OR NEW."endsAt" IS NULL OR
    (OLD."endsAt" IS NOT NULL AND NEW."endsAt" > OLD."endsAt") THEN
    RAISE EXCEPTION 'Activation periods may only be closed, not rewritten or extended' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER protect_commission_activation BEFORE UPDATE OR DELETE ON commerce."CommissionAgreementActivation"
FOR EACH ROW EXECUTE FUNCTION commerce.protect_commission_activation();

CREATE FUNCTION commerce.protect_completed_sale_item() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE row_business text; row_sale text;
BEGIN
  IF TG_OP = 'INSERT' THEN row_business := NEW."businessId"; row_sale := NEW."saleId";
  ELSE row_business := OLD."businessId"; row_sale := OLD."saleId"; END IF;
  IF EXISTS (SELECT 1 FROM commerce."Sale" WHERE "businessId" = row_business AND id = row_sale AND status <> 'DRAFT') THEN
    RAISE EXCEPTION 'Items of completed or void sales are immutable' USING ERRCODE = '23514';
  END IF;
  IF TG_OP = 'UPDATE' AND ROW(NEW."businessId", NEW."saleId") IS DISTINCT FROM ROW(OLD."businessId", OLD."saleId") THEN
    RAISE EXCEPTION 'Sale items cannot move between sales or tenants' USING ERRCODE = '23514';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER protect_completed_sale_item BEFORE INSERT OR UPDATE OR DELETE ON commerce."SaleItem"
FOR EACH ROW EXECUTE FUNCTION commerce.protect_completed_sale_item();

CREATE FUNCTION commerce.protect_completed_return_item() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE row_business text; row_return text;
BEGIN
  IF TG_OP = 'INSERT' THEN row_business := NEW."businessId"; row_return := NEW."saleReturnId";
  ELSE row_business := OLD."businessId"; row_return := OLD."saleReturnId"; END IF;
  IF EXISTS (SELECT 1 FROM commerce."SaleReturn" WHERE "businessId" = row_business AND id = row_return AND status = 'COMPLETED') THEN
    RAISE EXCEPTION 'Completed return items are immutable' USING ERRCODE = '23514';
  END IF;
  IF TG_OP = 'UPDATE' AND ROW(NEW."businessId", NEW."saleReturnId", NEW."saleItemId") IS DISTINCT FROM ROW(OLD."businessId", OLD."saleReturnId", OLD."saleItemId") THEN
    RAISE EXCEPTION 'Return item source references are immutable' USING ERRCODE = '23514';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER protect_completed_return_item BEFORE INSERT OR UPDATE OR DELETE ON commerce."ReturnItem"
FOR EACH ROW EXECUTE FUNCTION commerce.protect_completed_return_item();

CREATE FUNCTION commerce.protect_completed_commission_source() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.status = 'COMPLETED' THEN
    IF TG_OP = 'DELETE' THEN RAISE EXCEPTION 'Completed financial sources cannot be deleted' USING ERRCODE = '23514'; END IF;
    IF (to_jsonb(NEW) - 'updatedAt') IS DISTINCT FROM (to_jsonb(OLD) - 'updatedAt') THEN
      RAISE EXCEPTION 'Completed financial sources are immutable; record a return/adjustment' USING ERRCODE = '23514';
    END IF;
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER protect_completed_sale BEFORE UPDATE OR DELETE ON commerce."Sale"
FOR EACH ROW EXECUTE FUNCTION commerce.protect_completed_commission_source();
CREATE TRIGGER protect_completed_return BEFORE UPDATE OR DELETE ON commerce."SaleReturn"
FOR EACH ROW EXECUTE FUNCTION commerce.protect_completed_commission_source();

-- Also enforce payout shape, currency and reserved/successful totals for privileged database writers.
CREATE FUNCTION commerce.check_partner_payment_balance() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE target commerce."CommissionSettlement"%ROWTYPE; committed numeric;
BEGIN
  IF NEW."settlementId" IS NULL THEN RETURN NEW; END IF;
  SELECT * INTO target FROM commerce."CommissionSettlement"
    WHERE "businessId" = NEW."businessId" AND id = NEW."settlementId" FOR UPDATE;
  IF target.id IS NULL OR target.settlement_status <> 'FINALIZED' OR target.currency IS NULL OR
    NEW.currency <> target.currency OR NEW.direction <> 'OUT' OR NEW.amount <= 0 THEN
    RAISE EXCEPTION 'Partner payment requires a finalized settlement and matching currency' USING ERRCODE = '23514';
  END IF;
  IF NEW.status IN ('PENDING', 'PROCESSING', 'AUTHORIZED', 'SUCCEEDED') THEN
    SELECT COALESCE(SUM(amount), 0) INTO committed FROM commerce."Payment"
      WHERE "businessId" = NEW."businessId" AND "settlementId" = NEW."settlementId" AND id <> NEW.id
      AND direction = 'OUT' AND status IN ('PENDING', 'PROCESSING', 'AUTHORIZED', 'SUCCEEDED');
    IF committed + NEW.amount > target.amount THEN
      RAISE EXCEPTION 'Partner payment would overpay or overreserve settlement' USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER check_partner_payment_balance BEFORE INSERT OR UPDATE ON commerce."Payment"
FOR EACH ROW EXECUTE FUNCTION commerce.check_partner_payment_balance();

COMMIT;
