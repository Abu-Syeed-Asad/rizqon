import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { test } from "node:test";

const enabled = process.env.COMMISSION_TEST_ALLOW_WRITES === "1" && !!process.env.COMMISSION_TEST_DATABASE_URL;

test("commission PostgreSQL integration (isolated database required)", { skip: !enabled, timeout: 600000 }, async t => {
  assert.equal(process.env.DATABASE_URL, process.env.COMMISSION_TEST_DATABASE_URL, "Use scripts/commission-db.mjs test");
  const { prisma } = await import("../src/lib/prisma.js");
  const { agreementService } = await import("../src/module/Commission/agreement.service.js");
  const { entryService } = await import("../src/module/Commission/entry.service.js");
  const { settlementService } = await import("../src/module/Commission/settlement.service.js");
  const { partnerPaymentService } = await import("../src/module/Commission/payment.service.js");
  const { saleService } = await import("../src/module/Sale/sale.service.js");
  const { returnService } = await import("../src/module/SaleReturn/return.service.js");
  const { decimal, money } = await import("../src/module/Commission/commission.math.js");
  const suffix = randomUUID();
  const business = await prisma.business.create({ data: { Business_name: "Commission integration", business_slug: `commission-${suffix}` } });
  const other = await prisma.business.create({ data: { Business_name: "Other tenant", business_slug: `other-${suffix}` } });
  const user = await prisma.user.create({ data: { name: "Finance tester", email: `commission-${suffix}@example.invalid` } });
  const outsider = await prisma.user.create({ data: { name: "Unprivileged tester", email: `outsider-${suffix}@example.invalid` } });
  const employee = await prisma.employee.create({ data: { businessId: business.id, userId: user.id,
    employeeCode: "TEST", Employee_name: "Finance tester", Employee_phone: "000", Employee_jobTitle: "OWNER" } });
  await prisma.employee.create({ data: { businessId: business.id, userId: outsider.id,
    employeeCode: "OTHER", Employee_name: "Ordinary tester", Employee_phone: "001", Employee_jobTitle: "CASHIER" } });
  const branch = await prisma.branch.create({ data: { businessId: business.id, Brance_name: "Test", branch_code: "TEST" } });
  await prisma.employeeBranch.create({ data: { businessId: business.id, employeeId: employee.Employee_id, branchId: branch.id } });
  const partner = await prisma.partner.create({ data: { businessId: business.id, name: "Test partner", phone: "000", email: "partner@example.invalid", address: "Test", kind: "COMMISSION_PARTNER" } });
  const secondPartner = await prisma.partner.create({ data: { businessId: business.id, name: "Second", phone: "001", email: "second@example.invalid", address: "Test", kind: "BOTH" } });
  const category = await prisma.category.create({ data: { businessId: business.id, name: "Test", category_slug: "test" } });
  const product = await prisma.product.create({ data: { businessId: business.id, categoryId: category.id, name: "Test product", slug: "test", price: "1200" } });
  const variant = await prisma.productVariant.create({ data: { businessId: business.id, productId: product.id, sku: "TEST", sellingPrice: "1200" } });
  const plain = await prisma.productVariant.create({ data: { businessId: business.id, productId: product.id, sku: "PLAIN", sellingPrice: "1200" } });
  for (const v of [variant, plain]) await prisma.inventory.create({ data: { businessId: business.id, branchId: branch.id, variantId: v.id, quantity: "100" } });
  const actor = { id: user.id }, tenant = business.id;
  const agreementInput = { partnerId: partner.id, commissionPercent: "10.00", startsAt: new Date(Date.now() - 60000).toISOString(), endsAt: null, productVariantIds: [variant.id] };
  let agreementId = "";
  let soldId = "";
  let saleItemId = "";
  let saleEntryId = "";
  let settlementId = "";

  async function draft(variantId = variant.id, quantity = "1", unitPrice = "1200", discountAmount = "200") {
    const subtotal = money(decimal(quantity).mul(unitPrice));
    const total = subtotal.minus(discountAmount);
    return prisma.sale.create({ data: { businessId: tenant, branchId: branch.id, cashierId: employee.Employee_id,
      invoiceNumber: `INV-${randomUUID()}`, idempotencyKey: randomUUID(), requestHash: randomUUID(), sellerNameSnapshot: "Test",
      subtotal, discountTotal: discountAmount, grandTotal: total,
      saleItem_sale: { create: { variantId, productName: "Test", sku: "TEST", quantity, unitPrice, unitCost: "0", discountAmount, lineTotal: total } } }, include: { saleItem_sale: true } });
  }

  async function completedSale(variantId = variant.id, quantity = "1", price = "1200", discount = "200") {
    const sale = await draft(variantId, quantity, price, discount);
    await saleService.complete(actor, tenant, sale.id);
    return sale;
  }

  async function returned(saleId: string, itemId: string, quantity: string) {
    const result = await returnService.create(actor, tenant, { saleId, idempotencyKey: randomUUID(), reason: "Customer return", items: [{ saleItemId: itemId, quantity }] });
    await returnService.transition(actor, tenant, result.id, "approve");
    await returnService.transition(actor, tenant, result.id, "complete");
    return result;
  }

  try {
    await t.test("valid draft creation, history and activation", async () => {
      const agreement = await agreementService.create(actor, tenant, agreementInput);
      agreementId = agreement.id;
      assert.equal(agreement.isActive, false);
      assert.equal(agreement.assignments.length, 1);
      const edited = await agreementService.update(actor, tenant, agreement.id, { commissionPercent: "10.00" });
      assert.equal(edited.endsAt, null);
      const active = await agreementService.transition(actor, tenant, agreement.id, "activate");
      assert.equal(active.isActive, true);
      assert.equal(active.activations.length, 1);
      const history = await agreementService.get(actor, tenant, agreement.id, true);
      assert.ok(Array.isArray(history) && history.length === 3);
    });
    await t.test("overlaps across any partner are rejected; activated rates cannot change", async () => {
      await assert.rejects(() => agreementService.create(actor, tenant, { ...agreementInput, partnerId: secondPartner.id }), /overlapping/);
      await assert.rejects(() => agreementService.update(actor, tenant, agreementId, { commissionPercent: "20" }), /unused draft/);
    });
    await t.test("cross-tenant product, partner, reads and unauthorized writes fail", async () => {
      const otherCategory = await prisma.category.create({ data: { businessId: other.id, name: "Other", category_slug: "other" } });
      const otherProduct = await prisma.product.create({ data: { businessId: other.id, categoryId: otherCategory.id, name: "Other", slug: "other", price: "1" } });
      const otherVariant = await prisma.productVariant.create({ data: { businessId: other.id, productId: otherProduct.id, sku: "OTHER", sellingPrice: "1" } });
      await assert.rejects(() => agreementService.create(actor, tenant, { ...agreementInput, productVariantIds: [otherVariant.id] }), /Every variant/);
      await assert.rejects(() => agreementService.create(actor, other.id, agreementInput), /permission/);
      await assert.rejects(() => agreementService.get(actor, other.id, agreementId), /permission/);
      await assert.rejects(() => agreementService.transition({ id: outsider.id }, tenant, agreementId, "deactivate"), /permission/);
    });
    await t.test("discounted sale, automatic snapshots and duplicate sale processing", async () => {
      const sale = await completedSale(variant.id, "2", "1200", "400");
      soldId = sale.id; saleItemId = sale.saleItem_sale[0].id;
      await saleService.complete(actor, tenant, sale.id);
      const entries = await prisma.commissionEntry.findMany({ where: { businessId: tenant, saleItemId } });
      assert.equal(entries.length, 1);
      saleEntryId = entries[0].id;
      assert.equal(entries[0].grossBase.toFixed(2), "2000.00");
      assert.equal(entries[0].commissionAmount.toFixed(2), "200.00");
      assert.equal(entries[0].partnerPayable.toFixed(2), "1800.00");
      const snapshot = await prisma.saleItem.findUniqueOrThrow({ where: { id: saleItemId } });
      assert.equal(snapshot.agreementId, agreementId);
      assert.equal(snapshot.commissionPercent.toFixed(2), "10.00");
      assert.equal(await prisma.stockMovement.count({ where: { businessId: tenant, sourceId: saleItemId } }), 1);
      await assert.rejects(() => prisma.saleItem.update({ where: { id: saleItemId }, data: { quantity: "99" } }));
    });
    await t.test("no agreement produces no commission; failed sale rolls back inventory and state", async () => {
      const sale = await completedSale(plain.id);
      assert.equal(await prisma.commissionEntry.count({ where: { businessId: tenant, saleItemId: sale.saleItem_sale[0].id } }), 0);
      const invalid = await draft(variant.id, "1000", "1", "0");
      await assert.rejects(() => saleService.complete(actor, tenant, invalid.id), /Insufficient inventory/);
      assert.equal((await prisma.sale.findUniqueOrThrow({ where: { id: invalid.id } })).status, "DRAFT");
      assert.equal(await prisma.commissionEntry.count({ where: { businessId: tenant, saleItemId: invalid.saleItem_sale[0].id } }), 0);
    });
    await t.test("partial return and duplicate return processing are atomic", async () => {
      const result = await returned(soldId, saleItemId, "0.5");
      const replay = await returnService.create(actor, tenant, { saleId: soldId, idempotencyKey: result.idempotencyKey,
        reason: "Customer return", items: [{ saleItemId, quantity: "0.500" }] });
      assert.equal(replay.id, result.id);
      await assert.rejects(() => returnService.create(actor, tenant, { saleId: soldId, idempotencyKey: result.idempotencyKey,
        reason: "Customer return", items: [{ saleItemId, quantity: "1" }] }), /idempotency key/);
      await returnService.transition(actor, tenant, result.id, "complete");
      const entries = await prisma.commissionEntry.findMany({ where: { businessId: tenant, returnItemId: result.returnItem_saleReturn[0].id } });
      assert.equal(entries.length, 1);
      assert.equal(entries[0].grossBase.toFixed(2), "-500.00");
      assert.equal(entries[0].commissionAmount.toFixed(2), "-50.00");
      assert.equal(entries[0].partnerPayable.toFixed(2), "-450.00");
    });
    await t.test("settlement calculation, idempotency and concurrent entry claims", async () => {
      const entries = await prisma.commissionEntry.findMany({ where: { businessId: tenant, saleItemId } });
      const input = { partnerId: partner.id, commissionEntryIds: entries.map(e => e.id), idempotencyKey: randomUUID() };
      const results = await Promise.allSettled([
        settlementService.create(actor, tenant, input),
        settlementService.create(actor, tenant, { ...input, idempotencyKey: randomUUID() }),
      ]);
      assert.equal(results.filter(r => r.status === "fulfilled").length, 1);
      const winner = results.find(r => r.status === "fulfilled");
      assert.ok(winner?.status === "fulfilled");
      settlementId = winner.value.id;
      const replay = await settlementService.create(actor, tenant, { ...input, idempotencyKey: winner.value.idempotencyKey! });
      assert.equal(replay.id, settlementId);
      assert.equal(winner.value.amount.toFixed(2), "1350.00");
      await settlementService.update(actor, tenant, settlementId, { commissionEntryIds: entries.map(e => e.id) });
      await settlementService.transition(actor, tenant, settlementId, "finalize");
      await assert.rejects(() => settlementService.update(actor, tenant, settlementId, { commissionEntryIds: [saleEntryId] }), /Only draft/);
      await assert.rejects(() => prisma.commissionEntry.update({ where: { id: saleEntryId }, data: { partnerPayable: "1" } }));
    });
    await t.test("partial payments, pending reservations, failures and manual reconciliation", async () => {
      const first = await partnerPaymentService.create(actor, tenant, settlementId, { amount: "350", method: "BANK_TRANSFER", idempotencyKey: "first-" + suffix });
      assert.equal(first.status, "PENDING");
      assert.equal((await partnerPaymentService.create(actor, tenant, settlementId, { amount: "350.00", method: "BANK_TRANSFER", idempotencyKey: "first-" + suffix })).id, first.id);
      const evidence = { status: "SUCCEEDED", evidenceReference: `bank-${suffix}`, note: "Matched against confirmed bank statement" };
      await partnerPaymentService.reconcile(actor, tenant, settlementId, first.id, evidence);
      await partnerPaymentService.reconcile(actor, tenant, settlementId, first.id, evidence);
      let balance = await partnerPaymentService.list(actor, tenant, settlementId);
      assert.equal(balance.successfulPaidAmount.toFixed(2), "350.00");
      assert.equal(balance.remainingPayable.toFixed(2), "1000.00");
      const failed = await partnerPaymentService.create(actor, tenant, settlementId, { amount: "500", method: "BANK_TRANSFER", idempotencyKey: "failed-" + suffix });
      await assert.rejects(() => partnerPaymentService.create(actor, tenant, settlementId, { amount: "501", method: "CASH", idempotencyKey: randomUUID() }), /exceed/);
      await partnerPaymentService.reconcile(actor, tenant, settlementId, failed.id, { status: "FAILED", evidenceReference: `failed-${suffix}`, note: "Bank rejected this attempt" });
      balance = await partnerPaymentService.list(actor, tenant, settlementId);
      assert.equal(balance.availableToPay.toFixed(2), "1000.00");
    });
    await t.test("concurrent payouts cannot overpay; successful payments derive PAID status", async () => {
      const results = await Promise.allSettled([1, 2].map(() => partnerPaymentService.create(actor, tenant, settlementId,
        { amount: "1000", method: "CASH", idempotencyKey: randomUUID() })));
      assert.equal(results.filter(r => r.status === "fulfilled").length, 1);
      const winner = results.find(r => r.status === "fulfilled");
      assert.ok(winner?.status === "fulfilled");
      await partnerPaymentService.reconcile(actor, tenant, settlementId, winner.value.id, { status: "SUCCEEDED", evidenceReference: `cash-${suffix}`, note: "Signed cash receipt verified" });
      const balance = await partnerPaymentService.list(actor, tenant, settlementId);
      assert.equal(balance.paymentStatus, "PAID");
      assert.equal(balance.remainingPayable.toFixed(2), "0.00");
      assert.equal((await prisma.commissionSettlement.findUniqueOrThrow({ where: { id: settlementId } })).settlement_status, "FINALIZED");
      await assert.rejects(() => partnerPaymentService.create(actor, tenant, settlementId, { amount: "0.01", method: "CASH", idempotencyKey: randomUUID() }), /exceed/);
    });
    await t.test("return after new agreement uses original rate and preserves paid settlement", async () => {
      await agreementService.transition(actor, tenant, agreementId, "deactivate");
      const newAgreement = await agreementService.create(actor, tenant, { ...agreementInput, startsAt: new Date().toISOString(), commissionPercent: "20" });
      await agreementService.transition(actor, tenant, newAgreement.id, "activate");
      const before = await prisma.commissionSettlement.findUniqueOrThrow({ where: { id: settlementId } });
      await returned(soldId, saleItemId, "1.5");
      const entries = await prisma.commissionEntry.findMany({ where: { businessId: tenant, saleItemId, eventType: "RETURN" } });
      assert.equal(entries.length, 2);
      assert.ok(entries.every(e => e.commissionPercent.eq(10) && e.agreementId === agreementId));
      const total = entries.reduce((s, e) => s.plus(e.partnerPayable), decimal(0));
      assert.equal(total.toFixed(2), "-1800.00");
      const after = await prisma.commissionSettlement.findUniqueOrThrow({ where: { id: settlementId } });
      assert.deepEqual(after, before);
      const extra = await returnService.create(actor, tenant, { saleId: soldId, reason: "Too much", idempotencyKey: randomUUID(), items: [{ saleItemId, quantity: "0.001" }] });
      await returnService.transition(actor, tenant, extra.id, "approve");
      await assert.rejects(() => returnService.transition(actor, tenant, extra.id, "complete"), /exceeds/);
    });
    await t.test("negative adjustments cannot be paid or omitted and can be carried forward", async () => {
      const negatives = await prisma.commissionEntry.findMany({ where: { businessId: tenant, settlementId: null, partnerPayable: { lt: 0 } } });
      const negative = await settlementService.create(actor, tenant, { partnerId: partner.id, commissionEntryIds: negatives.map(e => e.id), idempotencyKey: randomUUID() });
      await assert.rejects(() => settlementService.transition(actor, tenant, negative.id, "finalize"), /Negative adjustments/);
      const sale = await completedSale(variant.id, "2", "1200", "0");
      const positive = await prisma.commissionEntry.findFirstOrThrow({ where: { businessId: tenant, saleItemId: sale.saleItem_sale[0].id } });
      assert.equal(positive.commissionPercent.toFixed(2), "20.00");
      await assert.rejects(() => settlementService.create(actor, tenant, { partnerId: partner.id, commissionEntryIds: [positive.id], idempotencyKey: randomUUID() }), /outstanding return/);
      await settlementService.update(actor, tenant, negative.id, { commissionEntryIds: [...negatives.map(e => e.id), positive.id] });
      const finalized = await settlementService.transition(actor, tenant, negative.id, "finalize");
      assert.equal(finalized.amount.toFixed(2), "570.00");
    });
    await t.test("full return and rounding at low values reverse every original cent", async () => {
      const sale = await completedSale(variant.id, "3", "0.01", "0.01");
      for (let i = 0; i < 3; i++) await returned(sale.id, sale.saleItem_sale[0].id, "1");
      const entries = await prisma.commissionEntry.findMany({ where: { businessId: tenant, saleItemId: sale.saleItem_sale[0].id } });
      for (const field of ["grossBase", "commissionAmount", "partnerPayable"] as const) {
        assert.equal(entries.reduce((s, e) => s.plus(e[field]), decimal(0)).toFixed(2), "0.00");
      }
    });
    await t.test("entry reads are tenant scoped and agreement history is retained", async () => {
      await assert.rejects(() => entryService.get(actor, other.id, saleEntryId), /permission/);
      const entry = await entryService.get(actor, tenant, saleEntryId);
      assert.equal(entry.partnerPayable.toFixed(2), "1800.00");
      const history = await agreementService.get(actor, tenant, agreementId, true);
      assert.ok(Array.isArray(history) && history.length >= 4);
    });
    await t.test("concurrent overlapping agreements and concurrent sale completion have one result", async () => {
      const input = { ...agreementInput, startsAt: new Date().toISOString(), productVariantIds: [plain.id] };
      const agreements = await Promise.allSettled([
        agreementService.create(actor, tenant, input), agreementService.create(actor, tenant, { ...input, partnerId: secondPartner.id }),
      ]);
      assert.equal(agreements.filter(r => r.status === "fulfilled").length, 1);
      const sale = await draft();
      const completed = await Promise.all([saleService.complete(actor, tenant, sale.id), saleService.complete(actor, tenant, sale.id)]);
      assert.equal(completed[0].id, completed[1].id);
      assert.equal(await prisma.commissionEntry.count({ where: { businessId: tenant, saleItemId: sale.saleItem_sale[0].id } }), 1);
    });
    await t.test("concurrent return completions cannot exceed original quantity", async () => {
      const sale = await completedSale();
      const makeReturn = async () => {
        const r = await returnService.create(actor, tenant, { saleId: sale.id, idempotencyKey: randomUUID(), reason: "Concurrency check",
          items: [{ saleItemId: sale.saleItem_sale[0].id, quantity: "1" }] });
        await returnService.transition(actor, tenant, r.id, "approve");
        return r;
      };
      const first = await makeReturn(), second = await makeReturn();
      const results = await Promise.allSettled([first, second].map(r => returnService.transition(actor, tenant, r.id, "complete")));
      assert.equal(results.filter(r => r.status === "fulfilled").length, 1);
      assert.equal(await prisma.commissionEntry.count({ where: { businessId: tenant, saleItemId: sale.saleItem_sale[0].id, eventType: "RETURN" } }), 1);
    });
  } finally { await prisma.$disconnect(); }
});
