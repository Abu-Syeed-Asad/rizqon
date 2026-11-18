import { randomUUID } from "node:crypto";
import { audit, authorize, fail, hash, requireBranch, tenantKey, transaction, type Actor } from "../Commission/commission.common.js";
import { calculateReversal, cumulativeAllocation, decimal, sum } from "../Commission/commission.math.js";
import { reverseReturnItem } from "../Commission/entry.service.js";
import { createReturnSchema } from "./return.validation.js";
import { idSchema } from "../Commission/commission.validation.js";

const include = { returnItem_saleReturn: { include: { saleItem: true } }, sale: true };

async function create(actor: Actor, tenant: string, payload: unknown) {
  const data = createReturnSchema.parse(payload);
  data.items.sort((a, b) => a.saleItemId.localeCompare(b.saleItemId));
  const requestHash = hash(data);
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "sale");
    const sale = await tx.sale.findUnique({ where: tenantKey(scope.businessId, data.saleId), include: { saleItem_sale: true } });
    if (!sale || sale.status !== "COMPLETED") fail("A completed sale in this business is required", 404);
    await requireBranch(tx, scope, sale.branchId);
    // Serialize return requests/retries with completion of returns for the same sale.
    await tx.$queryRaw`SELECT id FROM commerce."Sale" WHERE "businessId" = ${scope.businessId} AND id = ${sale.id} FOR UPDATE`;
    const existing = await tx.saleReturn.findUnique({ where: { businessId_idempotencyKey: { businessId: scope.businessId, idempotencyKey: data.idempotencyKey } }, include });
    if (existing) {
      if (existing.requestHash !== requestHash) fail("Return idempotency key was used with another request");
      return existing;
    }
    const items = [];
    for (const input of data.items) {
      const item = sale.saleItem_sale.find(i => i.id === input.saleItemId);
      if (!item || decimal(input.quantity).gt(item.quantity)) fail("Invalid return item or quantity", 400);
      // Final amounts are recalculated at completion, after other completed returns.
      const amount = calculateReversal({ grossBase: item.lineTotal, commissionAmount: "0" }, item.quantity, "0", input.quantity).grossBase.negated();
      items.push({ ...input, refundAmount: amount });
    }
    const result = await tx.saleReturn.create({ data: { businessId: scope.businessId, saleId: sale.id,
      returnNumber: `RET-${randomUUID()}`, idempotencyKey: data.idempotencyKey, requestHash, reason: data.reason,
      processorId: scope.employeeId, totalAmount: sum(items.map(i => i.refundAmount)), returnItem_saleReturn: { create: items } }, include });
    await audit(tx, scope, "RETURN_REQUESTED", "SALE_RETURN", result.id, undefined, result);
    return result;
  });
}

async function transition(actor: Actor, tenant: string, id: string, action: "approve" | "reject" | "complete") {
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "finalize");
    const where = tenantKey(scope.businessId, idSchema.parse(id));
    const returned = await tx.saleReturn.findUnique({ where, include });
    if (!returned) fail("Return not found", 404);
    await requireBranch(tx, scope, returned.sale.branchId);
    await tx.$queryRaw`SELECT id FROM commerce."Sale" WHERE "businessId" = ${scope.businessId} AND id = ${returned.saleId} FOR UPDATE`;
    if (action === "approve" || action === "reject") {
      const status = action === "approve" ? "APPROVED" : "REJECTED";
      if (returned.status === status) return returned;
      if (returned.status !== "REQUESTED") fail("Only a requested return can be approved or rejected");
      const result = await tx.saleReturn.update({ where, data: { status, processorId: scope.employeeId }, include });
      await audit(tx, scope, action === "approve" ? "RETURN_APPROVED" : "RETURN_REJECTED", "SALE_RETURN", id, returned, result);
      return result;
    }
    if (returned.status === "COMPLETED") return returned;
    if (returned.status !== "APPROVED" || returned.sale.status !== "COMPLETED") fail("An approved return on a completed sale is required");
    if (!returned.returnItem_saleReturn.length) fail("Return has no items");
    const amounts = [];
    for (const item of [...returned.returnItem_saleReturn].sort((a, b) => a.saleItem.variantId.localeCompare(b.saleItem.variantId) || a.id.localeCompare(b.id))) {
      if (item.saleItem.saleId !== returned.saleId) fail("Return item does not belong to this sale", 400);
      const previous = await tx.returnItem.findMany({ where: { businessId: scope.businessId, saleItemId: item.saleItemId,
        saleReturn: { businessId: scope.businessId, status: "COMPLETED" } } });
      const priorQuantity = sum(previous.map(r => r.quantity));
      const refund = calculateReversal({ grossBase: item.saleItem.lineTotal, commissionAmount: "0" },
        item.saleItem.quantity, priorQuantity, item.quantity).grossBase.negated();
      const previousAmount = sum(previous.map(r => r.refundAmount));
      const expectedPrior = cumulativeAllocation({ grossBase: item.saleItem.lineTotal, commissionAmount: "0" }, item.saleItem.quantity, priorQuantity).grossBase;
      if (!previousAmount.eq(expectedPrior)) fail("Historical refund allocations require reconciliation");
      if (previousAmount.plus(refund).gt(item.saleItem.lineTotal)) fail("Cumulative refund exceeds original sale amount");
      await reverseReturnItem(tx, scope, item.saleItem, item, priorQuantity);
      await tx.returnItem.update({ where: tenantKey(scope.businessId, item.id), data: { refundAmount: refund } });
      amounts.push(refund);
      if (item.restock) {
        const inventory = await tx.inventory.upsert({ where: { businessId_branchId_variantId: {
          businessId: scope.businessId, branchId: returned.sale.branchId, variantId: item.saleItem.variantId } },
        create: { businessId: scope.businessId, branchId: returned.sale.branchId, variantId: item.saleItem.variantId, quantity: item.quantity },
        update: { quantity: { increment: item.quantity } } });
        await tx.stockMovement.create({ data: { businessId: scope.businessId, inventoryId: inventory.id, actorId: scope.employeeId,
          kind: "RETURN", delta: item.quantity, sourceType: "RETURN_ITEM", sourceId: item.id, eventKey: `RETURN:${item.id}` } });
      }
    }
    const result = await tx.saleReturn.update({ where, data: { status: "COMPLETED", processedAt: new Date(),
      processorId: scope.employeeId, totalAmount: sum(amounts) }, include });
    await audit(tx, scope, "RETURN_COMPLETED", "SALE_RETURN", id, returned, result);
    return result;
  });
}
export const returnService = { create, transition };
