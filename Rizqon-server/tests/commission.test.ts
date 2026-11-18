import assert from "node:assert/strict";
import { test } from "node:test";
import { Prisma } from "../prisma/generated/prisma/client.js";
import { prisma } from "../src/lib/prisma.js";
import { authorize, transaction } from "../src/module/Commission/commission.common.js";
import { calculateCommission, calculateReversal, decimal, sum } from "../src/module/Commission/commission.math.js";
import { createAgreementSchema, updateAgreementSchema, settlementSchema, paymentSchema, reconciliationSchema } from "../src/module/Commission/commission.validation.js";
import { partnerPaymentService } from "../src/module/Commission/payment.service.js";

const agreement = { partnerId: "partner_123", commissionPercent: "10.00", startsAt: "2026-11-18T00:00:00.000Z", endsAt: null, productVariantIds: ["variant_001"] };

test("agreement validation accepts the requested format and protects decimal percentages", () => {
  assert.equal(createAgreementSchema.parse(agreement).commissionPercent, "10.00");
  for (const commissionPercent of ["-1", "100.01", "0.001", "NaN", "Infinity", "1e2", 10]) {
    assert.equal(createAgreementSchema.safeParse({ ...agreement, commissionPercent }).success, false);
  }
  for (const commissionPercent of ["0", "100", "99.99"]) assert.equal(createAgreementSchema.safeParse({ ...agreement, commissionPercent }).success, true);
});

test("agreement date validation rejects empty or reversed ranges and duplicate variants", () => {
  for (const endsAt of [agreement.startsAt, "2026-11-17T00:00:00.000Z", "bad"]) {
    assert.equal(createAgreementSchema.safeParse({ ...agreement, endsAt }).success, false);
  }
  assert.equal(createAgreementSchema.safeParse({ ...agreement, productVariantIds: ["same", "same"] }).success, false);
  assert.equal(updateAgreementSchema.safeParse({}).success, false);
  for (const field of ["businessId", "employeeId", "isActive", "firstActivatedAt"]) {
    assert.equal(createAgreementSchema.safeParse({ ...agreement, [field]: "spoof" }).success, false);
  }
});

test("sale calculation uses net discount base before tax and exact decimal amounts", () => {
  const result = calculateCommission("1200", "1", "200", "10");
  assert.equal(result.grossBase.toFixed(2), "1000.00");
  assert.equal(result.commissionAmount.toFixed(2), "100.00");
  assert.equal(result.partnerPayable.toFixed(2), "900.00");
  assert.throws(() => calculateCommission("1", "1", "2", "10"));
});

test("large amounts and half-cent boundaries do not use JavaScript floating point", () => {
  assert.equal(calculateCommission("0.05", "1", "0", "10").commissionAmount.toFixed(2), "0.01");
  const large = calculateCommission("99999999999999.99", "1.001", "0.01", "99.99");
  assert.equal(large.grossBase.toFixed(2), "100099999999999.98");
  assert.equal(large.commissionAmount.plus(large.partnerPayable).toString(), large.grossBase.toString());
  assert.throws(() => calculateCommission("9999999999999999.99", "2", "0", "10"));
});

test("full return reverses the exact original amounts", () => {
  const original = calculateCommission("1200", "1", "200", "10");
  const result = calculateReversal(original, "1", "0", "1");
  assert.equal(result.grossBase.toFixed(2), "-1000.00");
  assert.equal(result.commissionAmount.toFixed(2), "-100.00");
  assert.equal(result.partnerPayable.toFixed(2), "-900.00");
});

test("partial returns allocate residual cents exactly and reject excessive cumulative returns", () => {
  const original = calculateCommission("0.05", "3", "0", "10");
  const reversals = [0, 1, 2].map(prior => calculateReversal(original, "3", String(prior), "1"));
  assert.equal(sum(reversals.map(r => r.commissionAmount)).toFixed(2), "-0.02");
  assert.equal(sum(reversals.map(r => r.partnerPayable)).toFixed(2), "-0.13");
  assert.throws(() => calculateReversal(original, "3", "2.5", "1"));
  assert.throws(() => calculateReversal(original, "3", "0", "0"));
});

test("settlement sum includes negative adjustments and rejects duplicate selections", () => {
  assert.equal(sum(["900", "1800", "-450"]).toFixed(2), "2250.00");
  assert.equal(settlementSchema.safeParse({ partnerId: "p", commissionEntryIds: ["e", "e"], idempotencyKey: "settlement-1" }).success, false);
});

test("small-value partial returns never create positive payables and sum to the original", () => {
  for (const percent of ["0", "10", "33.33", "50", "99.99", "100"]) {
    for (let cents = 1; cents <= 30; cents++) {
      const original = calculateCommission(decimal(cents).div(100), "1", "0", percent);
      const reversals = ["0", "0.25", "0.50", "0.75"].map(prior => calculateReversal(original, "1", prior, "0.25"));
      for (const field of ["grossBase", "commissionAmount", "partnerPayable"] as const) {
        assert.ok(reversals.every(r => r[field].lte(0)));
        assert.ok(sum(reversals.map(r => r[field])).eq(original[field].negated()));
      }
    }
  }
});

test("payment input cannot claim success, inject amounts with excess precision, or omit reconciliation evidence", () => {
  const payment = { amount: "10.00", method: "CASH", idempotencyKey: "payment-1" };
  assert.equal(paymentSchema.safeParse(payment).success, true);
  for (const amount of ["0", "-1", "1.001", 10]) assert.equal(paymentSchema.safeParse({ ...payment, amount }).success, false);
  assert.equal(paymentSchema.safeParse({ ...payment, status: "SUCCEEDED" }).success, false);
  assert.equal(reconciliationSchema.safeParse({ status: "SUCCEEDED" }).success, false);
});

test("tenant authorization derives scope from active employee and stored role", async () => {
  const employee = { Employee_id: "employee", businessId: "tenant", Employee_jobTitle: "ACCOUNTANT", business: { currency: "BDT", Business_name: "Business" } };
  const tx = { employee: { findFirst: async ({ where }: { where: Record<string, unknown> }) => {
    assert.deepEqual(where.user, { status: "ACTIVE" });
    assert.deepEqual(where.business, { Business_status: "ACTIVE" });
    return where.businessId === "tenant" && where.userId === "user" ? employee : null;
  } } } as unknown as Prisma.TransactionClient;
  assert.equal((await authorize(tx, { id: "user" }, "tenant", "read")).employeeId, "employee");
  await assert.rejects(() => authorize(tx, { id: "user" }, "other", "read"), /permission/);
  await assert.rejects(() => authorize(tx, { id: "user" }, "tenant", "agreement"), /permission/);
  await assert.rejects(() => authorize(tx, { id: "" }, "tenant", "read"), /Authentication/);
});

test("serialization retries are bounded and rerun the complete transaction", async () => {
  const original = prisma.$transaction;
  let attempts = 0;
  prisma.$transaction = (async (fn: (tx: Prisma.TransactionClient) => Promise<unknown>, options: { isolationLevel: string }) => {
    assert.equal(options.isolationLevel, "Serializable");
    attempts++;
    if (attempts === 1) throw new Prisma.PrismaClientKnownRequestError("raw serialization", { code: "P2010", clientVersion: "test", meta: { code: "40001" } });
    if (attempts === 2) throw new Prisma.PrismaClientKnownRequestError("retry", { code: "P2034", clientVersion: "test" });
    return fn({} as Prisma.TransactionClient);
  }) as typeof prisma.$transaction;
  try {
    assert.equal(await transaction(async () => decimal("1.01").toFixed(2)), "1.01");
    assert.equal(attempts, 3);
    attempts = 0;
    prisma.$transaction = (async () => {
      attempts++;
      throw new Prisma.PrismaClientKnownRequestError("raw deadlock", { code: "P2010", clientVersion: "test", meta: { code: "40P01" } });
    }) as typeof prisma.$transaction;
    await assert.rejects(() => transaction(async () => "unreachable"), (error: unknown) =>
      error instanceof Error && "statusCode" in error && error.statusCode === 409);
    assert.equal(attempts, 4);
  } finally { prisma.$transaction = original; }
});

test("a later return blocks new payouts but does not hide an already reserved confirmed payout", async () => {
  const original = prisma.$transaction;
  let debitReads = 0;
  const payment = { id: "payment", businessId: "tenant", settlementId: "settlement", direction: "OUT",
    status: "PENDING", amount: decimal("100"), currency: "BDT" };
  const tx = {
    employee: { findFirst: async () => ({ Employee_id: "employee", businessId: "tenant", Employee_jobTitle: "FINANCE_MANAGER",
      business: { currency: "BDT", Business_name: "Test" } }) },
    partner: { findUnique: async () => ({ id: "partner", kind: "COMMISSION_PARTNER" }) },
    $queryRaw: async () => [],
    commissionSettlement: { findUnique: async () => ({ id: "settlement", partnerId: "partner", currency: "BDT", settlement_status: "FINALIZED", amount: decimal("100") }) },
    commissionEntry: { findFirst: async () => { debitReads++; return { id: "later-return" }; } },
    payment: {
      findUnique: async ({ where }: { where: Record<string, unknown> }) => where.businessId_idempotencyKey ? null : payment,
      findMany: async () => [payment],
      update: async ({ data }: { data: object }) => ({ ...payment, ...data }),
    },
    paymentEvent: { findUnique: async () => null, create: async () => ({ id: "event" }) },
    auditLog: { create: async () => ({ id: "audit" }) },
  };
  prisma.$transaction = (async (fn: (client: Prisma.TransactionClient) => Promise<unknown>) => fn(tx as unknown as Prisma.TransactionClient)) as typeof prisma.$transaction;
  try {
    const result = await partnerPaymentService.reconcile({ id: "user" }, "tenant", "settlement", "payment",
      { status: "SUCCEEDED", evidenceReference: "bank-confirmation", note: "Transfer confirmed before the return was recorded" });
    assert.equal(result.status, "SUCCEEDED");
    assert.equal(debitReads, 0);
    await assert.rejects(() => partnerPaymentService.create({ id: "user" }, "tenant", "settlement",
      { amount: "1", method: "CASH", idempotencyKey: "new-payout" }), /outstanding return/);
    assert.equal(debitReads, 1);
  } finally { prisma.$transaction = original; }
});
