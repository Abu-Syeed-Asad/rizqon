import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { test } from "node:test";

const enabled = process.env.COMMISSION_TEST_ALLOW_WRITES === "1" && !!process.env.COMMISSION_TEST_DATABASE_URL;
test("scheduled agreement deactivation, reassignment and expiration preserve historical windows", { skip: !enabled, timeout: 120000 }, async () => {
  assert.equal(process.env.DATABASE_URL, process.env.COMMISSION_TEST_DATABASE_URL);
  const { prisma } = await import("../src/lib/prisma.js");
  const { agreementService } = await import("../src/module/Commission/agreement.service.js");
  const suffix = randomUUID();
  try {
    const business = await prisma.business.create({ data: { Business_name: "History test", business_slug: `history-${suffix}` } });
    const user = await prisma.user.create({ data: { name: "History tester", email: `history-${suffix}@example.invalid` } });
    await prisma.employee.create({ data: { businessId: business.id, userId: user.id, employeeCode: "TEST",
      Employee_name: "History tester", Employee_phone: "000", Employee_jobTitle: "OWNER" } });
    const partner = await prisma.partner.create({ data: { businessId: business.id, name: "Test", phone: "000", email: "history@example.invalid", address: "Test", kind: "COMMISSION_PARTNER" } });
    const category = await prisma.category.create({ data: { businessId: business.id, name: "Test", category_slug: "test" } });
    const product = await prisma.product.create({ data: { businessId: business.id, categoryId: category.id, name: "Test", slug: "test", price: "1" } });
    const variant = await prisma.productVariant.create({ data: { businessId: business.id, productId: product.id, sku: "TEST", sellingPrice: "1" } });
    const actor = { id: user.id };
    const start = new Date(Date.now() + 86400000).toISOString();
    const first = await agreementService.create(actor, business.id, { partnerId: partner.id, productVariantIds: [variant.id], commissionPercent: "10", startsAt: start });
    await agreementService.transition(actor, business.id, first.id, "activate");
    const inactive = await agreementService.transition(actor, business.id, first.id, "deactivate");
    assert.equal(inactive.activations[0].startsAt.getTime(), inactive.activations[0].endsAt?.getTime());
    // The zero-length cancelled future activation must not reserve the product.
    const replacement = await agreementService.create(actor, business.id, { partnerId: partner.id, productVariantIds: [variant.id], commissionPercent: "20", startsAt: new Date().toISOString() });
    await agreementService.transition(actor, business.id, replacement.id, "activate");
    await assert.rejects(() => agreementService.transition(actor, business.id, first.id, "activate"), /overlapping/);
    const expired = await agreementService.transition(actor, business.id, replacement.id, "expire");
    assert.ok(expired.expiredAt);
    assert.ok(expired.activations[0].endsAt);
    await assert.rejects(() => agreementService.transition(actor, business.id, replacement.id, "activate"), /expired/);
    await assert.rejects(() => prisma.commissionAgreementActivation.update({ where: { id: expired.activations[0].id }, data: { endsAt: null } }));
    const reactivated = await agreementService.transition(actor, business.id, first.id, "activate");
    assert.equal(reactivated.activations.length, 2);
    assert.equal(reactivated.commissionPercent.toFixed(2), "10.00");
  } finally { await prisma.$disconnect(); }
});
