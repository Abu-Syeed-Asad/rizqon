import { randomUUID } from "node:crypto";
import type { Prisma } from "../../../prisma/generated/prisma/client.js";
import { audit, authorize, fail, hash, requirePartner, tenantKey, transaction, type Actor, type Scope } from "./commission.common.js";
import { money, sum } from "./commission.math.js";
import { editSettlementSchema, idSchema, listSchema, settlementSchema } from "./commission.validation.js";

export async function lockPartner(tx: Prisma.TransactionClient, scope: Scope, partnerId: string) {
  await requirePartner(tx, scope.businessId, partnerId);
  await tx.$queryRaw`SELECT id FROM commerce."Partner" WHERE "businessId" = ${scope.businessId} AND id = ${partnerId} FOR UPDATE`;
}

export async function requireNoUnallocatedDebits(tx: Prisma.TransactionClient, businessId: string, partnerId: string, allowedIds: string[] = []) {
  const debit = await tx.commissionEntry.findFirst({ where: { businessId, agreement: { businessId, partnerId },
    partnerPayable: { lt: 0 }, ...(allowedIds.length ? { id: { notIn: allowedIds } } : {}),
    OR: [{ settlementId: null }, { settlement: { businessId, settlement_status: "DRAFT" } }] } });
  if (debit) fail("Include all outstanding return adjustments before finalizing or paying this partner", 409, "UNALLOCATED_RETURN_ADJUSTMENT");
}

async function eligibleEntries(tx: Prisma.TransactionClient, scope: Scope, partnerId: string, ids: string[], settlementId?: string) {
  const entries = await tx.commissionEntry.findMany({ where: { businessId: scope.businessId, id: { in: ids },
    agreement: { businessId: scope.businessId, partnerId } }, include: { saleItem: { include: { sale: true } }, returnItem: { include: { saleReturn: true } } } });
  if (entries.length !== ids.length) fail("All entries must belong to this business and partner", 400, "INVALID_ENTRIES");
  for (const entry of entries) {
    if (entry.settlementId && entry.settlementId !== settlementId) fail("An entry is already claimed by another settlement");
    if (entry.saleItem.sale.status !== "COMPLETED" || (entry.eventType === "RETURN" && entry.returnItem?.saleReturn.status !== "COMPLETED")) {
      fail("Only completed sale and return entries are eligible");
    }
    if (entry.saleItem.sale.currency !== scope.currency) fail("Cannot settle entries in a different currency");
  }
  await requireNoUnallocatedDebits(tx, scope.businessId, partnerId, ids);
  return { entries, amount: money(sum(entries.map(e => e.partnerPayable))) };
}

async function claim(tx: Prisma.TransactionClient, businessId: string, settlementId: string, ids: string[]) {
  const result = await tx.commissionEntry.updateMany({ where: { businessId, id: { in: ids }, settlementId: null }, data: { settlementId } });
  if (result.count !== ids.length) fail("Entries were claimed concurrently; reload and retry");
}

async function create(actor: Actor, tenant: string, payload: unknown) {
  const data = settlementSchema.parse(payload);
  data.commissionEntryIds.sort();
  const requestHash = hash(data);
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "settlement");
    await lockPartner(tx, scope, data.partnerId);
    const existing = await tx.commissionSettlement.findUnique({ where: { businessId_idempotencyKey: { businessId: scope.businessId, idempotencyKey: data.idempotencyKey } } });
    if (existing) {
      if (existing.requestHash !== requestHash) fail("Settlement idempotency key was used with another request");
      return existing;
    }
    const { amount } = await eligibleEntries(tx, scope, data.partnerId, data.commissionEntryIds);
    const result = await tx.commissionSettlement.create({ data: { businessId: scope.businessId, partnerId: data.partnerId,
      creatorId: scope.employeeId, settlement_reference: `CS-${randomUUID()}`, amount, currency: scope.currency,
      idempotencyKey: data.idempotencyKey, requestHash, settlement_status: "DRAFT" } });
    await claim(tx, scope.businessId, result.id, data.commissionEntryIds);
    await audit(tx, scope, "CREATED", "COMMISSION_SETTLEMENT", result.id, undefined, { ...result, entryIds: data.commissionEntryIds });
    return result;
  });
}

async function update(actor: Actor, tenant: string, id: string, payload: unknown) {
  const { commissionEntryIds } = editSettlementSchema.parse(payload);
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "settlement");
    const where = tenantKey(scope.businessId, idSchema.parse(id));
    const before = await tx.commissionSettlement.findUnique({ where, include: { commissionEntry_settlement: true } });
    if (!before) fail("Settlement not found", 404);
    await lockPartner(tx, scope, before.partnerId);
    if (before.settlement_status !== "DRAFT") fail("Only draft settlements may be edited");
    const { amount } = await eligibleEntries(tx, scope, before.partnerId, commissionEntryIds, id);
    await tx.commissionEntry.updateMany({ where: { businessId: scope.businessId, settlementId: id }, data: { settlementId: null } });
    await claim(tx, scope.businessId, id, commissionEntryIds);
    const after = await tx.commissionSettlement.update({ where, data: { amount, currency: scope.currency } });
    await audit(tx, scope, "UPDATED", "COMMISSION_SETTLEMENT", id, before, { ...after, entryIds: commissionEntryIds });
    return after;
  });
}

async function transition(actor: Actor, tenant: string, id: string, action: "finalize" | "cancel") {
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "finalize");
    const where = tenantKey(scope.businessId, idSchema.parse(id));
    const before = await tx.commissionSettlement.findUnique({ where, include: { commissionEntry_settlement: true } });
    if (!before) fail("Settlement not found", 404);
    await lockPartner(tx, scope, before.partnerId);
    const status = action === "finalize" ? "FINALIZED" : "CANCELLED";
    if (before.settlement_status === status) return before;
    if (before.settlement_status !== "DRAFT") fail("Only a draft settlement may be finalized or cancelled");
    if (action === "finalize") {
      const ids = before.commissionEntry_settlement.map(e => e.id);
      if (!ids.length) fail("Cannot finalize an empty settlement");
      const { amount } = await eligibleEntries(tx, scope, before.partnerId, ids, id);
      if (!amount.eq(before.amount) || before.currency !== scope.currency) fail("Review the draft amount and currency before finalization");
      if (amount.lt(0)) fail("Negative adjustments must be carried forward into a nonnegative settlement");
    } else {
      await tx.commissionEntry.updateMany({ where: { businessId: scope.businessId, settlementId: id }, data: { settlementId: null } });
    }
    const after = await tx.commissionSettlement.update({ where, data: { settlement_status: status,
      ...(action === "finalize" ? { finalizedAt: new Date() } : {}) } });
    await audit(tx, scope, action === "finalize" ? "SETTLEMENT_FINALIZED" : "SETTLEMENT_CANCELLED", "COMMISSION_SETTLEMENT", id, before, after);
    return after;
  });
}

export async function paymentBalance(tx: Prisma.TransactionClient, businessId: string, settlementId: string, amount: Prisma.Decimal) {
  const payments = await tx.payment.findMany({ where: { businessId, settlementId, direction: "OUT" }, select: { amount: true, status: true } });
  const successfulPaidAmount = sum(payments.filter(p => p.status === "SUCCEEDED").map(p => p.amount));
  const reservedAmount = sum(payments.filter(p => ["PENDING", "PROCESSING", "AUTHORIZED"].includes(p.status)).map(p => p.amount));
  const remainingPayable = amount.minus(successfulPaidAmount);
  return { successfulPaidAmount, remainingPayable, reservedAmount, availableToPay: remainingPayable.minus(reservedAmount),
    paymentStatus: remainingPayable.eq(0) ? "PAID" : successfulPaidAmount.gt(0) ? "PARTIALLY_PAID" : "UNPAID" };
}

async function get(actor: Actor, tenant: string, id: string) {
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "read");
    const settlement = await tx.commissionSettlement.findUnique({ where: tenantKey(scope.businessId, idSchema.parse(id)), include: { commissionEntry_settlement: true } });
    if (!settlement) fail("Settlement not found", 404);
    return { ...settlement, ...await paymentBalance(tx, scope.businessId, id, settlement.amount) };
  });
}

async function list(actor: Actor, tenant: string, query: unknown) {
  const { partnerId, page, limit } = listSchema.parse(query);
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "read");
    return tx.commissionSettlement.findMany({ where: { businessId: scope.businessId, partnerId },
      orderBy: [{ createdAt: "desc" }, { id: "asc" }], skip: (page - 1) * limit, take: limit });
  });
}
export const settlementService = { create, update, transition, list, get };
