import { audit, authorize, fail, hash, tenantKey, transaction, type Actor } from "./commission.common.js";
import { decimal } from "./commission.math.js";
import { idSchema, paymentSchema, reconciliationSchema } from "./commission.validation.js";
import { lockPartner, paymentBalance, requireNoUnallocatedDebits } from "./settlement.service.js";

async function create(actor: Actor, tenant: string, settlementId: string, payload: unknown) {
  const data = paymentSchema.parse(payload);
  const requestHash = hash({ settlementId, ...data });
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "payment");
    const settlement = await tx.commissionSettlement.findUnique({ where: tenantKey(scope.businessId, idSchema.parse(settlementId)) });
    if (!settlement) fail("Settlement not found", 404);
    await lockPartner(tx, scope, settlement.partnerId);
    const existing = await tx.payment.findUnique({ where: { businessId_idempotencyKey: { businessId: scope.businessId, idempotencyKey: data.idempotencyKey } } });
    if (existing) {
      if (existing.requestHash !== requestHash || existing.settlementId !== settlementId) fail("Payment idempotency key was used with another request");
      return existing;
    }
    if (settlement.settlement_status !== "FINALIZED" || !settlement.currency || settlement.amount.lte(0)) {
      fail("Payments require a finalized positive settlement with a verified currency");
    }
    await requireNoUnallocatedDebits(tx, scope.businessId, settlement.partnerId);
    const balance = await paymentBalance(tx, scope.businessId, settlementId, settlement.amount);
    if (decimal(data.amount).gt(balance.availableToPay)) fail("Payment would exceed the unreserved remaining payable", 409, "OVERPAYMENT");
    const payment = await tx.payment.create({ data: { ...data, requestHash, businessId: scope.businessId, settlementId,
      currency: settlement.currency, direction: "OUT", status: "PENDING", recorderId: scope.employeeId } });
    await audit(tx, scope, "PAYMENT_INITIATED", "PAYMENT", payment.id, undefined, payment);
    return payment;
  });
}

// An authorized finance manager records evidence they have independently verified.
// No provider API is called, no transfer is executed, and arbitrary provider webhooks are not accepted.
async function reconcile(actor: Actor, tenant: string, settlementId: string, paymentId: string, payload: unknown) {
  const data = reconciliationSchema.parse(payload);
  const payloadHash = hash(data);
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "finalize");
    const settlement = await tx.commissionSettlement.findUnique({ where: tenantKey(scope.businessId, idSchema.parse(settlementId)) });
    if (!settlement || settlement.settlement_status !== "FINALIZED") fail("Finalized settlement not found", 404);
    await lockPartner(tx, scope, settlement.partnerId);
    const payment = await tx.payment.findUnique({ where: tenantKey(scope.businessId, idSchema.parse(paymentId)) });
    if (!payment || payment.settlementId !== settlementId || payment.direction !== "OUT") fail("Partner payment not found", 404);
    const provider = `manual-reconciliation:${scope.businessId}`;
    const providerEventId = `PAYMENT:${payment.id}`;
    const event = await tx.paymentEvent.findUnique({ where: { provider_providerEventId: { provider, providerEventId } } });
    if (event) {
      if (event.payloadHash !== payloadHash) fail("A different reconciliation has already been recorded");
      return payment;
    }
    if (!["PENDING", "PROCESSING", "AUTHORIZED"].includes(payment.status)) fail("A terminal payment cannot be changed");
    if (payment.currency !== settlement.currency || payment.amount.lte(0)) fail("Invalid payment currency or amount");
    if (data.status === "SUCCEEDED") {
      // Record the truth of an already reserved, independently confirmed payout.
      // A return arriving after initiation must not prevent recording money already sent;
      // its new negative entry still blocks subsequent payment initiation.
      const balance = await paymentBalance(tx, scope.businessId, settlementId, settlement.amount);
      if (payment.amount.gt(balance.remainingPayable)) fail("Payment would overpay the settlement", 409, "OVERPAYMENT");
    }
    const after = await tx.payment.update({ where: tenantKey(scope.businessId, paymentId), data: {
      status: data.status, provider, providerReference: data.evidenceReference,
      paidAt: data.status === "SUCCEEDED" ? new Date() : null, note: data.note,
    } });
    await tx.paymentEvent.create({ data: { businessId: scope.businessId, paymentId, provider, providerEventId, payloadHash, processedAt: new Date() } });
    await audit(tx, scope, data.status === "SUCCEEDED" ? "PAYMENT_SUCCEEDED" : data.status === "FAILED" ? "PAYMENT_FAILED" : "PAYMENT_CANCELLED",
      "PAYMENT", paymentId, payment, { ...after, reconciliationSource: "MANUAL_VERIFIED_EVIDENCE", evidenceReference: data.evidenceReference });
    return after;
  });
}

async function list(actor: Actor, tenant: string, settlementId: string) {
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "read");
    const settlement = await tx.commissionSettlement.findUnique({ where: tenantKey(scope.businessId, idSchema.parse(settlementId)) });
    if (!settlement) fail("Settlement not found", 404);
    const payments = await tx.payment.findMany({ where: { businessId: scope.businessId, settlementId, direction: "OUT" },
      include: { paymentEvent_payment: true }, orderBy: [{ createdAt: "desc" }, { id: "asc" }] });
    return { payments, ...await paymentBalance(tx, scope.businessId, settlementId, settlement.amount) };
  });
}
export const partnerPaymentService = { create, reconcile, list };
