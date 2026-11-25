import assert from "node:assert/strict";
import { afterEach, beforeEach, test } from "node:test";
import { once } from "node:events";
import express from "express";
import jwt from "jsonwebtoken";
import type Stripe from "stripe";
import { Prisma, type Payment } from "../prisma/generated/prisma/client.js";
import { env } from "../src/config/env.js";
import { prisma } from "../src/lib/prisma.js";
import { decimal } from "../src/module/Commission/commission.math.js";
import { applyVerifiedPayment, paymentService } from "../src/module/Payment/payment.service.js";
import { minorUnits, querySsl, startCheckout, stripeClient, stripePayment, validateSsl, type GatewayRequest, type VerifiedPayment } from "../src/module/Payment/payment.gateway.js";
import { paymentRoutes, paymentCallbackRoutes, stripeWebhookRoute } from "../src/module/Payment/payment.route.js";
import { errorHandler } from "../src/middleware/errorhandler.js";

const originalEnv = { ...env };
const originalFetch = globalThis.fetch;
const original = { transaction: prisma.$transaction, find: prisma.payment.findUnique, updateMany: prisma.payment.updateMany, user: prisma.user.findUnique };
const customer = { name: "Customer", email: "buyer@example.com", phone: "01700000000", address: "Road 1", city: "Dhaka", postcode: "1200", country: "Bangladesh" };
const request: GatewayRequest = { paymentId: "payment1", businessId: "tenant", saleId: "sale1", invoice: "INV-1", amount: "100.25", currency: "BDT",
  customer, returnUrl: "https://shop.example/payments/result", callbackBase: "https://api.example/api/v1/payments" };
let payments: Payment[];
let events: { provider: string; providerEventId: string; paymentId: string; payloadHash: string }[];
let audits: unknown[];
let branchAccess: boolean;
let saleStatus: string;
let returns: number;
const actor = { id: "user" };
function seed(overrides: Partial<Payment> = {}) {
  const payment = { id: "payment1", businessId: "tenant", saleId: "sale1", direction: "IN", provider: "SSLCOMMERZ",
    providerReference: "payment1", method: "ONLINE_GATEWAY", amount: decimal("100.25"), currency: "BDT", status: "PROCESSING",
    idempotencyKey: "request-123", requestHash: null, paidAt: null, note: null, createdAt: new Date(), updatedAt: new Date(),
    purchaseId: null, expenseId: null, settlementId: null, recorderId: "employee", checkoutUrl: null, checkoutExpiresAt: null,
    gatewaySessionId: "session1", initializationStartedAt: null, gatewayRequest: request, ...overrides } as Payment;
  payments.push(payment);
  return payment;
}
function verified(overrides: Partial<VerifiedPayment> = {}): VerifiedPayment {
  return { paymentId: "payment1", provider: "SSLCOMMERZ", reference: "payment1", eventId: "validation1:safe", amount: "100.25", currency: "BDT", status: "SUCCEEDED", ...overrides };
}
function session(overrides: Record<string, unknown> = {}) {
  return { id: "cs_test_1", metadata: { paymentId: "payment1" }, client_reference_id: "payment1", mode: "payment",
    amount_total: 10025, currency: "bdt", status: "complete", payment_status: "paid", ...overrides } as unknown as Stripe.Checkout.Session;
}

beforeEach(() => {
  payments = []; events = []; audits = []; branchAccess = true; saleStatus = "COMPLETED"; returns = 0;
  Object.assign(env, { STRIPE_SECRET_KEY: "sk_test_example", STRIPE_WEBHOOK_SECRET: "whsec_example", SSLCOMMERZ_STORE_ID: "test_store",
    SSLCOMMERZ_STORE_PASSWORD: "test_password", SSLCOMMERZ_SANDBOX: true, PAYMENT_PUBLIC_BASE_URL: "https://api.example",
    PAYMENT_RETURN_URL: "https://shop.example/payments/result", PAYMENT_BUSINESS_IDS: "tenant", JWT_ACCESS_TOKEN_SECRET: "payment-test-token-secret" });
  const sale = () => ({ id: "sale1", businessId: "tenant", branchId: "branch", status: saleStatus, grandTotal: decimal("100.25"), currency: "BDT", invoiceNumber: "INV-1" });
  const find = async ({ where, include }: { where: Record<string, unknown>; include?: unknown }) => {
    const key = (where.businessId_id ?? where.businessId_idempotencyKey ?? where) as Record<string, unknown>;
    const found = payments.find(p => Object.entries(key).every(([field, value]) => p[field as keyof Payment] === value));
    return found ? { ...found, ...(include ? { sale: sale() } : {}) } : null;
  };
  const tx = {
    $queryRaw: async () => [],
    employee: { findFirst: async ({ where }: { where: { businessId: string } }) => where.businessId === "tenant" ? {
      businessId: "tenant", Employee_id: "employee", Employee_jobTitle: "CASHIER", business: { currency: "BDT", Business_name: "Test" } } : null },
    employeeBranch: { findFirst: async () => branchAccess ? {} : null },
    sale: { findUnique: async () => sale() }, saleReturn: { count: async () => returns },
    payment: {
      findUnique: find, findUniqueOrThrow: find,
      findMany: async () => payments.filter(p => ["PENDING", "PROCESSING", "AUTHORIZED", "SUCCEEDED"].includes(p.status)),
      create: async ({ data }: { data: Partial<Payment> }) => seed(data),
      update: async ({ where, data }: { where: { id: string }; data: Partial<Payment> }) => {
        const index = payments.findIndex(p => p.id === where.id);
        payments[index] = { ...payments[index], ...data };
        return { ...payments[index] };
      },
    },
    paymentEvent: {
      findUnique: async ({ where }: { where: { provider_providerEventId: { provider: string; providerEventId: string } } }) =>
        events.find(e => e.provider === where.provider_providerEventId.provider && e.providerEventId === where.provider_providerEventId.providerEventId) ?? null,
      create: async ({ data }: { data: typeof events[number] }) => { events.push(data); return data; },
    },
    auditLog: { create: async ({ data }: { data: unknown }) => { audits.push(data); return data; } },
  };
  prisma.$transaction = (async (fn: (client: Prisma.TransactionClient) => Promise<unknown>) => fn(tx as unknown as Prisma.TransactionClient)) as typeof prisma.$transaction;
  prisma.payment.findUnique = find as unknown as typeof prisma.payment.findUnique;
  prisma.payment.updateMany = (async ({ where }: { where: { id: string } }) => {
    const payment = payments.find(p => p.id === where.id)!;
    if (payment.initializationStartedAt) return { count: 0 };
    payment.initializationStartedAt = new Date(); payment.status = "PROCESSING";
    return { count: 1 };
  }) as unknown as typeof prisma.payment.updateMany;
  prisma.user.findUnique = (async () => ({ id: "user", status: "ACTIVE", user_role: "RIZQON_USER" })) as unknown as typeof prisma.user.findUnique;
});
afterEach(() => {
  Object.assign(env, originalEnv);
  for (const key of Object.keys(env)) if (!(key in originalEnv)) delete (env as unknown as Record<string, unknown>)[key];
  globalThis.fetch = originalFetch;
  prisma.$transaction = original.transaction; prisma.payment.findUnique = original.find;
  prisma.payment.updateMany = original.updateMany; prisma.user.findUnique = original.user;
});

test("amount conversion is exact and refuses unsupported or invalid amounts", () => {
  assert.equal(minorUnits("100.25", "BDT"), 10025);
  for (const value of ["0", "-1", "1.001", "Infinity", "1000000"]) assert.throws(() => minorUnits(value, "BDT"));
  assert.throws(() => minorUnits("100", "JPY"));
});

test("verified success is processed once, and stale failure cannot reverse it", async () => {
  seed();
  await applyVerifiedPayment(verified()); await applyVerifiedPayment(verified());
  assert.equal(payments[0].status, "SUCCEEDED"); assert.ok(payments[0].paidAt);
  assert.equal(events.length, 1); assert.equal(audits.length, 1);
  await applyVerifiedPayment(verified({ eventId: "late-failure", status: "FAILED" }));
  assert.equal(payments[0].status, "SUCCEEDED"); assert.equal(audits.length, 1);
});

test("amount, currency, reference, direction and provider mismatches cannot mark a payment paid", async () => {
  seed();
  for (const change of [{ amount: "0.25" }, { currency: "USD" }, { reference: "another" }, { provider: "STRIPE" as const }]) {
    await assert.rejects(applyVerifiedPayment(verified(change)));
  }
  payments[0].direction = "OUT";
  await assert.rejects(applyVerifiedPayment(verified()));
  assert.equal(events.length, 0); assert.equal(payments[0].status, "PROCESSING");
});

test("an event ID cannot be reused with a different verified payload", async () => {
  seed(); await applyVerifiedPayment(verified());
  await assert.rejects(applyVerifiedPayment(verified({ status: "FAILED" })), /event mismatch/);
});

test("risk hold cannot be downgraded by stale failure and may later become successful", async () => {
  seed(); await applyVerifiedPayment(verified({ status: "AUTHORIZED", eventId: "review" }));
  await applyVerifiedPayment(verified({ status: "FAILED", eventId: "failure" }));
  assert.equal(payments[0].status, "AUTHORIZED");
  await applyVerifiedPayment(verified()); assert.equal(payments[0].status, "SUCCEEDED");
});

test("delayed success records the truth after a failure", async () => {
  seed({ status: "FAILED" }); await applyVerifiedPayment(verified());
  assert.equal(payments[0].status, "SUCCEEDED");
});

test("Stripe only marks paid sessions successful and supports delayed and expired payments", () => {
  assert.equal(stripePayment(session(), "evt1").status, "SUCCEEDED");
  assert.equal(stripePayment(session({ payment_status: "unpaid" }), "evt2").status, "PROCESSING");
  assert.equal(stripePayment(session({ payment_status: "unpaid", status: "expired" }), "evt3").status, "CANCELLED");
  assert.equal(stripePayment(session({ payment_status: "unpaid" }), "evt4", true).status, "FAILED");
  assert.throws(() => stripePayment(session({ client_reference_id: "different" }), "evt5"));
});

test("SSLCommerz validates server-side and holds risky or unknown-risk transactions", async () => {
  for (const risk of ["0", "1", undefined]) {
    globalThis.fetch = (async (url: URL) => {
      assert.equal(url.hostname, "sandbox.sslcommerz.com");
      assert.equal(url.searchParams.get("val_id"), "validation1");
      assert.equal(url.searchParams.get("store_id"), "test_store");
      return Response.json({ status: "VALIDATED", tran_id: "payment1", val_id: "validation1", amount: "100.25", currency: "BDT", risk_level: risk });
    }) as typeof fetch;
    assert.equal((await validateSsl("payment1", "validation1")).status, risk === "0" ? "SUCCEEDED" : "AUTHORIZED");
  }
  globalThis.fetch = (async () => Response.json({ status: "VALID", tran_id: "someone-else", val_id: "validation1", amount: "100.25", currency: "BDT" })) as typeof fetch;
  await assert.rejects(validateSsl("payment1", "validation1"));
});

test("an empty SSLCommerz query or failed attempt does not release an uncertain reservation", async () => {
  globalThis.fetch = (async () => Response.json({ APIConnect: "DONE", element: [] })) as typeof fetch;
  assert.equal(await querySsl("payment1", null), null);
  globalThis.fetch = (async () => Response.json({ APIConnect: "DONE", element: [{ status: "FAILED", tran_id: "payment1", amount: "100.25", currency: "BDT" }] })) as typeof fetch;
  assert.equal(await querySsl("payment1", null), null);
});

test("SSLCommerz errors never expose credentials", async () => {
  globalThis.fetch = (async () => { throw new Error("store_passwd=test_password"); }) as typeof fetch;
  await assert.rejects(validateSsl("payment1", "validation1"), error => error instanceof Error && !error.message.includes("test_password"));
});

test("SSLCommerz checkout posts stored totals and all notification URLs", async () => {
  globalThis.fetch = (async (_url: URL, init: RequestInit) => {
    const body = init.body as URLSearchParams;
    assert.equal(body.get("total_amount"), "100.25"); assert.equal(body.get("tran_id"), "payment1");
    for (const field of ["success_url", "fail_url", "cancel_url", "ipn_url"]) assert.match(body.get(field)!, /^https:\/\/api.example\/api\/v1\/payments\/sslcommerz\//);
    return Response.json({ status: "SUCCESS", sessionkey: "session1", GatewayPageURL: "https://sandbox.sslcommerz.com/checkout" });
  }) as typeof fetch;
  const result = await startCheckout("SSLCOMMERZ", request);
  assert.equal(result.sessionId, "session1"); assert.equal(result.reference, "payment1");
});

test("Stripe checkout sends exact minor units, correlation metadata and a stable idempotency key", async () => {
  const keys: string[] = [];
  globalThis.fetch = (async (url: string, init: RequestInit) => {
    assert.equal(new URL(url).hostname, "api.stripe.com");
    const body = new URLSearchParams(String(init.body));
    assert.equal(body.get("line_items[0][price_data][unit_amount]"), "10025");
    assert.equal(body.get("metadata[paymentId]"), "payment1");
    assert.equal(body.get("client_reference_id"), "payment1");
    assert.equal(body.get("mode"), "payment");
    keys.push(new Headers(init.headers).get("Idempotency-Key")!);
    return Response.json({ id: "cs_test_1", url: "https://checkout.stripe.com/test", expires_at: 1900000000 });
  }) as typeof fetch;
  const first = await startCheckout("STRIPE", request);
  const retry = await startCheckout("STRIPE", request);
  assert.equal(first.reference, retry.reference);
  assert.deepEqual(keys, ["rizqon-payment-payment1", "rizqon-payment-payment1"]);
});

test("refresh recovers a missed Stripe success webhook", async () => {
  seed({ provider: "STRIPE", providerReference: "cs_test_1" });
  globalThis.fetch = (async () => Response.json(session())) as typeof fetch;
  const result = await paymentService.refresh(actor, "tenant", "payment1");
  assert.equal(result.status, "SUCCEEDED"); assert.equal(events.length, 1);
});

test("checkout uses the database balance and the same key reuses one session", async () => {
  let calls = 0;
  globalThis.fetch = (async (_url: URL, init: RequestInit) => {
    calls++; assert.equal((init.body as URLSearchParams).get("total_amount"), "100.25");
    return Response.json({ status: "SUCCESS", sessionkey: "session1", GatewayPageURL: "https://sandbox.sslcommerz.com/checkout" });
  }) as typeof fetch;
  const input = { provider: "SSLCOMMERZ", idempotencyKey: "request-123", customer };
  const first = await paymentService.checkout(actor, "tenant", "sale1", input);
  const second = await paymentService.checkout(actor, "tenant", "sale1", input);
  assert.equal(first.id, second.id); assert.equal(calls, 1); assert.equal(payments.length, 1);
  await assert.rejects(paymentService.checkout(actor, "tenant", "sale1", { ...input, provider: "STRIPE" }), /Idempotency/);
  await assert.rejects(paymentService.checkout(actor, "tenant", "sale1", { ...input, idempotencyKey: "different-key" }), /pending/);
});

test("checkout rejects client totals, another tenant, unassigned branches, drafts, returns and fully paid sales", async () => {
  const input = { provider: "SSLCOMMERZ", idempotencyKey: "request-123", customer };
  await assert.rejects(paymentService.checkout(actor, "tenant", "sale1", { ...input, amount: "1" }));
  await assert.rejects(paymentService.checkout(actor, "other", "sale1", input));
  branchAccess = false; await assert.rejects(paymentService.checkout(actor, "tenant", "sale1", input)); branchAccess = true;
  saleStatus = "DRAFT"; await assert.rejects(paymentService.checkout(actor, "tenant", "sale1", input)); saleStatus = "COMPLETED";
  returns = 1; await assert.rejects(paymentService.checkout(actor, "tenant", "sale1", input)); returns = 0;
  seed({ status: "SUCCEEDED", idempotencyKey: "previous-payment" });
  await assert.rejects(paymentService.checkout(actor, "tenant", "sale1", input));
});

test("uncertain SSLCommerz initialization cannot create a second session", async () => {
  let calls = 0;
  globalThis.fetch = (async () => { calls++; throw new Error("timeout"); }) as typeof fetch;
  const input = { provider: "SSLCOMMERZ", idempotencyKey: "request-123", customer };
  await assert.rejects(paymentService.checkout(actor, "tenant", "sale1", input));
  const retry = await paymentService.checkout(actor, "tenant", "sale1", input);
  assert.equal(retry.status, "PROCESSING"); assert.equal(retry.checkoutUrl, null); assert.equal(calls, 1);
});

test("HTTP routes verify raw Stripe signatures, require auth, and do not trust SSL callback fields", async () => {
  seed({ provider: "STRIPE", providerReference: "cs_test_1" });
  const app = express();
  app.use("/api/v1/payments", stripeWebhookRoute);
  app.use(express.json()); app.use(express.urlencoded({ extended: false }));
  app.use("/api/v1/payments", paymentCallbackRoutes);
  app.use("/api/v1/business/:businessId", paymentRoutes); app.use(errorHandler);
  const server = app.listen(0, "127.0.0.1"); await once(server, "listening");
  const address = server.address(); assert.ok(address && typeof address !== "string");
  const base = `http://127.0.0.1:${address.port}`;
  const body = JSON.stringify({ id: "evt1", type: "checkout.session.completed", data: { object: session() } });
  const signature = stripeClient().webhooks.generateTestHeaderString({ payload: body, secret: env.STRIPE_WEBHOOK_SECRET! });
  try {
    const webhook = (payload: string, sig: string) => originalFetch(`${base}/api/v1/payments/stripe/webhook`, { method: "POST", headers: { "Content-Type": "application/json", "Stripe-Signature": sig }, body: payload });
    assert.equal((await webhook(body, "invalid")).status, 400);
    assert.equal((await webhook(body + " ", signature)).status, 400);
    assert.equal((await webhook(body, signature)).status, 200);
    assert.equal((await webhook(body, signature)).status, 200); assert.equal(events.length, 1);
    const statusUrl = `${base}/api/v1/business/tenant/payments/payment1`;
    assert.equal((await originalFetch(statusUrl)).status, 401);
    const token = jwt.sign({ id: "user" }, env.JWT_ACCESS_TOKEN_SECRET!);
    const response = await originalFetch(statusUrl, { headers: { Authorization: `Bearer ${token}` } });
    assert.equal(response.status, 200);
    const publicData = (await response.json()).data;
    assert.equal(publicData.status, "SUCCEEDED"); assert.equal(publicData.gatewayRequest, undefined);
    assert.equal(publicData.checkoutUrl, null);
    payments = []; seed();
    globalThis.fetch = (async () => Response.json({ APIConnect: "DONE", status: "PENDING", sessionkey: "session1", tran_id: "payment1" })) as typeof fetch;
    const callback = await originalFetch(`${base}/api/v1/payments/sslcommerz/ipn`, { method: "POST", body: new URLSearchParams({ tran_id: "payment1", status: "VALID", amount: "100.25" }) });
    assert.equal(callback.status, 200); assert.equal(payments[0].status, "PROCESSING");
  } finally { server.closeAllConnections(); await new Promise<void>((resolve, reject) => server.close(error => error ? reject(error) : resolve())); }
});
