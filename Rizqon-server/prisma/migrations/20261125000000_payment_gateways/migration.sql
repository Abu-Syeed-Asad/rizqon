ALTER TYPE commerce."PAYMENT_METHOD" ADD VALUE 'ONLINE_GATEWAY';

ALTER TABLE commerce."Payment"
  ADD COLUMN "gatewaySessionId" TEXT,
  ADD COLUMN "checkoutUrl" TEXT,
  ADD COLUMN "checkoutExpiresAt" TIMESTAMP(3),
  ADD COLUMN "gatewayRequest" JSONB,
  ADD COLUMN "initializationStartedAt" TIMESTAMP(3);
