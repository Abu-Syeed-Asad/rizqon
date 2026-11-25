import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { test } from "node:test";

const enabled = process.env.COMMISSION_TEST_ALLOW_WRITES === "1" && !!process.env.COMMISSION_TEST_DATABASE_URL;
test("payment PostgreSQL integration (isolated database required)", { skip: !enabled, timeout: 180000 }, async t => {
  assert.equal(process.env.DATABASE_URL, process.env.COMMISSION_TEST_DATABASE_URL, "Use scripts/commission-db.mjs test-payments");
  const { prisma } = await import("../src/lib/prisma.js");
  const { env } = await import("../src/config/env.js");
  const { applyVerifiedPayment, paymentService } = await import("../src/module/Payment/payment.service.js");
  const originalEnv = { ...env }, originalFetch = globalThis.fetch;
  const suffix = randomUUID();
  const business = await prisma.business.create({ data: { Business_name: "Payment integration", business_slug: `payment-${suffix}` } });
  const user = await prisma.user.create({ data: { name: "Payment tester", email: `payment-${suffix}@example.invalid` } });
  const employee = await prisma.employee.create({ data: { businessId: business.id, userId: user.id, employeeCode: "PAYMENT-TEST",
    Employee_name: "Payment tester", Employee_phone: "000", Employee_jobTitle: "CASHIER" } });
  const branch = await prisma.branch.create({ data: { businessId: business.id, Brance_name: "Payment test", branch_code: "PAYMENT-TEST" } });
  await prisma.employeeBranch.create({ data: { businessId: business.id, employeeId: employee.Employee_id, branchId: branch.id } });
  const sale = () => prisma.sale.create({ data: { businessId: business.id, branchId: branch.id, cashierId: employee.Employee_id,
    invoiceNumber: randomUUID(), idempotencyKey: randomUUID(), requestHash: "fixture", status: "COMPLETED", sellerNameSnapshot: "Payment integration",
    currency: "BDT", subtotal: "100.25", grandTotal: "100.25", completedAt: new Date() } });
  const customer = { name: "Test", email: "test@example.invalid", phone: "01700000000", address: "Test road", city: "Dhaka", postcode: "1200", country: "Bangladesh" };
  const input = () => ({ provider: "SSLCOMMERZ", idempotencyKey: randomUUID(), customer });
  let calls = 0;
  Object.assign(env, { PAYMENT_BUSINESS_IDS: business.id, PAYMENT_PUBLIC_BASE_URL: "https://api.example.invalid",
    PAYMENT_RETURN_URL: "https://app.example.invalid/payments", SSLCOMMERZ_STORE_ID: "test", SSLCOMMERZ_STORE_PASSWORD: "test", SSLCOMMERZ_SANDBOX: true });
  globalThis.fetch = (async (_url: URL, init: RequestInit) => {
    calls++;
    const id = (init.body as URLSearchParams).get("tran_id");
    return Response.json({ status: "SUCCESS", sessionkey: `session-${id}`, GatewayPageURL: `https://sandbox.sslcommerz.com/checkout?session=${id}` });
  }) as typeof fetch;
  try {
    await t.test("concurrent requests with the same key persist one payment and start one provider session", async () => {
      const invoice = await sale(), payload = input(), before = calls;
      const results = await Promise.all([1, 2, 3].map(() => paymentService.checkout(user, business.id, invoice.id, payload)));
      assert.equal(new Set(results.map(p => p.id)).size, 1);
      assert.equal(calls - before, 1);
      assert.equal(await prisma.payment.count({ where: { saleId: invoice.id } }), 1);
      const persisted = await prisma.payment.findUniqueOrThrow({ where: { id: results[0].id } });
      assert.equal(persisted.amount.toFixed(2), "100.25"); assert.ok(persisted.checkoutUrl);
    });
    await t.test("different concurrent checkout keys cannot reserve the same sale twice", async () => {
      const invoice = await sale(), before = calls;
      const results = await Promise.allSettled([1, 2].map(() => paymentService.checkout(user, business.id, invoice.id, input())));
      assert.equal(results.filter(r => r.status === "fulfilled").length, 1);
      assert.equal(calls - before, 1);
      assert.equal(await prisma.payment.count({ where: { saleId: invoice.id } }), 1);
    });
    await t.test("concurrent duplicate notifications commit one event and one success audit", async () => {
      const invoice = await sale();
      const payment = await paymentService.checkout(user, business.id, invoice.id, input());
      const event = { paymentId: payment.id, provider: "SSLCOMMERZ" as const, reference: payment.id,
        eventId: `validation-${randomUUID()}`, amount: "100.25", currency: "BDT", status: "SUCCEEDED" as const };
      await Promise.all([1, 2, 3].map(() => applyVerifiedPayment(event)));
      assert.equal(await prisma.paymentEvent.count({ where: { paymentId: payment.id } }), 1);
      assert.equal(await prisma.auditLog.count({ where: { entityId: payment.id, action: "PAYMENT_SUCCEEDED" } }), 1);
      const paid = await prisma.payment.findUniqueOrThrow({ where: { id: payment.id } });
      assert.equal(paid.status, "SUCCEEDED"); assert.ok(paid.paidAt);
      await applyVerifiedPayment({ ...event, eventId: `late-${randomUUID()}`, status: "FAILED" });
      assert.equal((await prisma.payment.findUniqueOrThrow({ where: { id: payment.id } })).status, "SUCCEEDED");
      await assert.rejects(paymentService.checkout(user, business.id, invoice.id, input()));
    });
    await t.test("an invalid provider amount rolls back without an event or status change", async () => {
      const invoice = await sale();
      const payment = await paymentService.checkout(user, business.id, invoice.id, input());
      await assert.rejects(applyVerifiedPayment({ paymentId: payment.id, provider: "SSLCOMMERZ", reference: payment.id,
        eventId: randomUUID(), amount: "0.25", currency: "BDT", status: "SUCCEEDED" }));
      assert.equal(await prisma.paymentEvent.count({ where: { paymentId: payment.id } }), 0);
      assert.equal((await prisma.payment.findUniqueOrThrow({ where: { id: payment.id } })).status, "PROCESSING");
    });
  } finally {
    globalThis.fetch = originalFetch; Object.assign(env, originalEnv);
    // Keep uniquely named fixtures in this isolated database, matching the existing integration suite.
    await prisma.$disconnect();
  }
});
