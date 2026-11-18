import type { Prisma, SaleItem, ReturnItem } from "../../../prisma/generated/prisma/client.js";
import { audit, authorize, fail, tenantKey, transaction, type Actor, type Scope } from "./commission.common.js";
import { calculateCommission, calculateReversal, cumulativeAllocation, sum } from "./commission.math.js";
import { listSchema, idSchema } from "./commission.validation.js";

// Internal transaction hooks. There is deliberately no public entry-write route.
export async function accrueSaleItem(tx: Prisma.TransactionClient, scope: Scope, item: SaleItem, occurredAt: Date) {
  if (item.businessId !== scope.businessId) fail("Sale item tenant mismatch", 403);
  const existing = await tx.commissionEntry.findMany({ where: { businessId: scope.businessId, saleItemId: item.id, eventType: "SALE" } });
  if (existing.length > 1) fail("Multiple historical sale commissions require reconciliation");
  if (existing.length) {
    const expected = calculateCommission(item.unitPrice, item.quantity, item.discountAmount, existing[0].commissionPercent);
    if (!existing[0].grossBase.eq(expected.grossBase) || !existing[0].commissionAmount.eq(expected.commissionAmount) ||
      !existing[0].partnerPayable.eq(expected.partnerPayable)) fail("Existing sale commission does not match the original sale item");
    return existing[0];
  }
  const agreements = await tx.commissionAgreement.findMany({ where: {
    businessId: scope.businessId,
    assignments: { some: { businessId: scope.businessId, variantId: item.variantId } },
    activations: { some: { startsAt: { lte: occurredAt }, OR: [{ endsAt: null }, { endsAt: { gt: occurredAt } }] } },
  }, take: 2 });
  if (agreements.length > 1) fail("Multiple agreements apply to this sale item", 409, "AMBIGUOUS_AGREEMENT");
  const agreement = agreements[0];
  if (!agreement) {
    await tx.saleItem.update({ where: tenantKey(scope.businessId, item.id),
      data: { agreementId: null, commissionPercent: 0, commissionAmount: 0 } });
    return null;
  }
  const amounts = calculateCommission(item.unitPrice, item.quantity, item.discountAmount, agreement.commissionPercent);
  const entry = await tx.commissionEntry.create({ data: { ...amounts, businessId: scope.businessId,
    eventKey: `SALE:${item.id}:${agreement.id}`, eventType: "SALE", agreementId: agreement.id, saleItemId: item.id } });
  await tx.saleItem.update({ where: tenantKey(scope.businessId, item.id), data: { agreementId: agreement.id,
    commissionPercent: amounts.commissionPercent, commissionAmount: amounts.commissionAmount } });
  await audit(tx, scope, "COMMISSION_ACCRUED", "COMMISSION_ENTRY", entry.id, undefined, entry);
  return entry;
}

export async function reverseReturnItem(tx: Prisma.TransactionClient, scope: Scope, item: SaleItem,
  returned: ReturnItem, priorQuantity: Prisma.Decimal) {
  if (item.businessId !== scope.businessId || returned.businessId !== scope.businessId || returned.saleItemId !== item.id) {
    fail("Return item tenant or sale mismatch", 403);
  }
  const originals = await tx.commissionEntry.findMany({ where: { businessId: scope.businessId, saleItemId: item.id, eventType: "SALE" } });
  if (originals.length > 1) fail("Multiple historical sale commissions require reconciliation");
  const original = originals[0];
  if (!original) {
    if (item.agreementId) fail("Original commission is missing; reconcile legacy sale before returning it");
    return null;
  }
  const eventKey = `RETURN:${returned.id}:${original.agreementId}`;
  const existing = await tx.commissionEntry.findUnique({ where: { businessId_eventKey: { businessId: scope.businessId, eventKey } } });
  if (existing) return existing;
  const previous = await tx.commissionEntry.findMany({ where: { businessId: scope.businessId, saleItemId: item.id,
    agreementId: original.agreementId, eventType: "RETURN" } });
  for (const field of ["grossBase", "commissionAmount", "partnerPayable"] as const) {
    const expected = cumulativeAllocation(original, item.quantity, priorQuantity)[field];
    if (!sum(previous.map(e => e[field])).eq(expected.negated())) fail("Historical return commissions require reconciliation");
  }
  const amounts = calculateReversal(original, item.quantity, priorQuantity, returned.quantity);
  const entry = await tx.commissionEntry.create({ data: { ...amounts, businessId: scope.businessId, eventKey,
    eventType: "RETURN", agreementId: original.agreementId, saleItemId: item.id, returnItemId: returned.id,
    commissionPercent: original.commissionPercent } });
  await tx.returnItem.update({ where: tenantKey(scope.businessId, returned.id), data: { commissionReversal: amounts.commissionAmount.negated() } });
  await audit(tx, scope, "COMMISSION_REVERSED", "COMMISSION_ENTRY", entry.id, undefined, entry);
  return entry;
}

async function list(actor: Actor, tenant: string, query: unknown) {
  const { partnerId, settlementId, unsettled, page, limit } = listSchema.parse(query);
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "read");
    return tx.commissionEntry.findMany({ where: { businessId: scope.businessId,
      ...(partnerId ? { agreement: { businessId: scope.businessId, partnerId } } : {}),
      ...(unsettled === "true" ? { settlementId: null } : settlementId ? { settlementId } :
        unsettled === "false" ? { settlementId: { not: null } } : {}) },
      orderBy: [{ createdAt: "desc" }, { id: "asc" }], skip: (page - 1) * limit, take: limit });
  });
}

async function get(actor: Actor, tenant: string, id: string) {
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "read");
    const entry = await tx.commissionEntry.findUnique({ where: tenantKey(scope.businessId, idSchema.parse(id)) });
    if (!entry) fail("Commission entry not found", 404);
    return entry;
  });
}
export const entryService = { list, get };
