import { audit, authorize, fail, requireBranch, tenantKey, transaction, type Actor } from "../Commission/commission.common.js";
import { accrueSaleItem } from "../Commission/entry.service.js";
import { calculateCommission, decimal, money, sum } from "../Commission/commission.math.js";
import { idSchema } from "../Commission/commission.validation.js";

// Completes an existing trusted draft. Prices and allocated discounts are loaded from the database.
async function complete(actor: Actor, tenant: string, id: string) {
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "sale");
    const where = tenantKey(scope.businessId, idSchema.parse(id));
    await tx.$queryRaw`SELECT id FROM commerce."Sale" WHERE "businessId" = ${scope.businessId} AND id = ${id} FOR UPDATE`;
    const sale = await tx.sale.findUnique({ where, include: { saleItem_sale: true } });
    if (!sale) fail("Sale not found", 404);
    await requireBranch(tx, scope, sale.branchId);
    if (sale.status === "COMPLETED") return sale;
    if (sale.status !== "DRAFT") fail("Only a draft sale can be completed");
    if (!sale.saleItem_sale.length) fail("A sale must contain items", 400);
    if (sale.currency !== scope.currency) fail("Sale currency differs from business currency");
    const items = sale.saleItem_sale;
    for (const item of items) {
      const base = calculateCommission(item.unitPrice, item.quantity, item.discountAmount, 0).grossBase;
      if (item.taxAmount.lt(0) || !base.plus(item.taxAmount).eq(item.lineTotal)) fail("Stored sale item totals are inconsistent");
    }
    if (!sum(items.map(i => money(decimal(i.unitPrice).mul(i.quantity)))).eq(sale.subtotal) ||
      !sum(items.map(i => i.discountAmount)).eq(sale.discountTotal) ||
      !sum(items.map(i => i.taxAmount)).eq(sale.taxTotal) || !sum(items.map(i => i.lineTotal)).eq(sale.grandTotal)) {
      fail("Sale totals must match the original item discount and tax allocations");
    }
    const completedAt = new Date();
    for (const item of [...items].sort((a, b) => a.variantId.localeCompare(b.variantId) || a.id.localeCompare(b.id))) {
      const inventory = await tx.inventory.findUnique({ where: { businessId_branchId_variantId: {
        businessId: scope.businessId, branchId: sale.branchId, variantId: item.variantId } } });
      if (!inventory) fail("Inventory not found for sale variant");
      const changed = await tx.inventory.updateMany({ where: { businessId: scope.businessId, id: inventory.id,
        quantity: { gte: item.quantity } }, data: { quantity: { decrement: item.quantity } } });
      if (changed.count !== 1) fail("Insufficient inventory");
      await tx.stockMovement.create({ data: { businessId: scope.businessId, actorId: scope.employeeId,
        inventoryId: inventory.id, delta: decimal(item.quantity).negated(), kind: "SALE", sourceType: "SALE_ITEM",
        sourceId: item.id, eventKey: `SALE:${item.id}` } });
      await accrueSaleItem(tx, scope, item, completedAt);
    }
    if (sale.cartId) await tx.cart.update({ where: tenantKey(scope.businessId, sale.cartId), data: { status: "CHECKED_OUT" } });
    const result = await tx.sale.update({ where, data: { status: "COMPLETED", completedAt }, include: { saleItem_sale: true } });
    await audit(tx, scope, "SALE_COMPLETED", "SALE", id, sale, result);
    return result;
  });
}
export const saleService = { complete };
