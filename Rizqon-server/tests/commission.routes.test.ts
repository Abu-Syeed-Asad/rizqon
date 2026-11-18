import assert from "node:assert/strict";
import { once } from "node:events";
import { test } from "node:test";
import express from "express";
import jwt from "jsonwebtoken";
import { prisma } from "../src/lib/prisma.js";
import { env } from "../src/config/env.js";
import { errorHandler } from "../src/middleware/errorhandler.js";
import { commissionRoutes } from "../src/module/Commission/commission.route.js";
import type { Prisma } from "../prisma/generated/prisma/client.js";

test("commission HTTP routes require authentication, verify tenant membership and reject financial injection", async () => {
  const originals = { user: prisma.user.findUnique, transaction: prisma.$transaction, secret: env.JWT_ACCESS_TOKEN_SECRET };
  env.JWT_ACCESS_TOKEN_SECRET = "commission-test-secret";
  const token = jwt.sign({ id: "user" }, env.JWT_ACCESS_TOKEN_SECRET, { expiresIn: "5m" });
  prisma.user.findUnique = (async () => ({ id: "user", status: "ACTIVE", user_role: "RIZQON_OWNER" })) as unknown as typeof prisma.user.findUnique;
  let title = "CASHIER";
  let writes = 0;
  const tx = {
    employee: { findFirst: async ({ where }: { where: { businessId: string; userId: string } }) => {
      assert.equal(where.userId, "user");
      return where.businessId === "tenant" ? { businessId: "tenant", Employee_id: "employee", Employee_jobTitle: title,
        business: { currency: "BDT", Business_name: "Test" } } : null;
    } },
    commissionEntry: { findMany: async ({ where }: { where: { businessId: string } }) => { assert.equal(where.businessId, "tenant"); return []; },
      create: async () => { writes++; } },
  };
  prisma.$transaction = (async (fn: (client: Prisma.TransactionClient) => Promise<unknown>) => fn(tx as unknown as Prisma.TransactionClient)) as typeof prisma.$transaction;
  const app = express();
  app.use(express.json());
  app.use("/api/v1/business/:businessId", commissionRoutes);
  app.use(errorHandler);
  const server = app.listen(0, "127.0.0.1");
  await once(server, "listening");
  const address = server.address();
  assert.ok(address && typeof address !== "string");
  const base = `http://127.0.0.1:${address.port}/api/v1/business`;
  const request = (method: string, path: string, body?: unknown, authorization = `Bearer ${token}`) => fetch(base + path, {
    method, headers: { "Content-Type": "application/json", Authorization: authorization },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  try {
    assert.equal((await request("GET", "/tenant/commission-entries", undefined, "")).status, 401);
    assert.equal((await request("GET", "/tenant/commission-entries", undefined, "Bearer invalid")).status, 401);
    assert.equal((await request("GET", "/tenant/commission-entries")).status, 403);
    assert.equal((await request("POST", "/tenant/commission-agreements/a/activate", {})).status, 403);
    title = "OWNER";
    assert.equal((await request("GET", "/other/commission-entries")).status, 403);
    const list = await request("GET", "/tenant/commission-entries?limit=10");
    assert.equal(list.status, 200);
    assert.deepEqual((await list.json()).data, []);
    assert.equal((await request("GET", "/tenant/commission-entries?businessId=other")).status, 400);
    assert.equal((await request("POST", "/tenant/commission-settlements/s/payments", { amount: "10", method: "CASH", idempotencyKey: "payment-1", status: "SUCCEEDED" })).status, 400);
    assert.equal((await request("POST", "/tenant/sales/s/complete", { commissionAmount: "999" })).status, 400);
    assert.equal((await request("POST", "/tenant/commission-entries", { partnerPayable: "999" })).status, 404);
    assert.equal(writes, 0);
  } finally {
    server.closeAllConnections();
    await new Promise<void>((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
    prisma.user.findUnique = originals.user;
    prisma.$transaction = originals.transaction;
    env.JWT_ACCESS_TOKEN_SECRET = originals.secret;
  }
});
