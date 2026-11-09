import assert from "node:assert/strict";
import { once } from "node:events";
import type { AddressInfo } from "node:net";
import { test, mock } from "node:test";
import express from "express";
import jwt from "jsonwebtoken";
import { Prisma, SYSTEM_USER_ROLE, type User } from "../prisma/generated/prisma/client.js";
import { prisma } from "../src/lib/prisma.js";
import { env } from "../src/config/env.js";
import { errorHandler } from "../src/middleware/errorhandler.js";
import { branchRoutes } from "../src/module/branch/branch.route.js";
import { branchValidation } from "../src/module/branch/branch.validation.js";

const id = "cm12345678901234567890124";
const businessId = "cm12345678901234567890123";
const payload = { businessId, name: "Dhaka", branch_code: "BR001" };

test("branch schemas validate create and partial updates without resetting omitted fields", () => {
  assert.equal(branchValidation.createBranchSchema.parse(payload).isActive, true);
  const schema = branchValidation.updateBranchSchema;
  assert.deepEqual(schema.parse({ name: " Updated branch " }), { name: "Updated branch" });
  assert.deepEqual(schema.parse({ phone: null, address: null, isActive: false }), { phone: null, address: null, isActive: false });
  for (const body of [{}, { name: " " }, { name: "a".repeat(151) }, { branch_code: "BAD CODE" }, { branch_code: "" }, { phone: "invalid" }, { isActive: "false" }, { address: " " }, { name: "Valid", businessId }]) {
    assert.equal(schema.safeParse(body).success, false);
  }
  assert.equal(branchValidation.createBranchSchema.safeParse({ businessId, name: "Valid" }).success, false);
  assert.equal(branchValidation.branchParamsSchema.safeParse({ id: "bad" }).success, false);
});

test("branch routes enforce roles, validate requests and handle missing records and database conflicts", async () => {
  let role: User["user_role"] = SYSTEM_USER_ROLE.RIZQON_CEO;
  let status: User["status"] = "ACTIVE";
  let missing = false;
  let failure: string | undefined;
  let empty = false;
  const originals = { user: prisma.user.findUnique, business: prisma.business.findUnique, find: prisma.branch.findUnique, create: prisma.branch.create, update: prisma.branch.update, delete: prisma.branch.delete, list: prisma.branch.findMany };
  const mutation = mock.fn(async (..._args: unknown[]) => {
    if (failure) throw new Prisma.PrismaClientKnownRequestError("private database detail", { code: failure, clientVersion: "test" });
    return { id, ...payload };
  });
  prisma.user.findUnique = mock.fn(async () => ({ id: "user-id", user_role: role, status })) as unknown as typeof prisma.user.findUnique;
  prisma.business.findUnique = mock.fn(async () => missing ? null : ({ id: businessId })) as unknown as typeof prisma.business.findUnique;
  prisma.branch.findUnique = mock.fn(async () => missing ? null : ({ id })) as unknown as typeof prisma.branch.findUnique;
  prisma.branch.create = mutation as unknown as typeof prisma.branch.create;
  prisma.branch.update = mutation as unknown as typeof prisma.branch.update;
  prisma.branch.delete = mutation as unknown as typeof prisma.branch.delete;
  prisma.branch.findMany = mock.fn(async () => empty ? [] : [await mutation()]) as unknown as typeof prisma.branch.findMany;
  const secret = env.JWT_ACCESS_TOKEN_SECRET;
  env.JWT_ACCESS_TOKEN_SECRET = "branch-test-secret-for-local-tests-only";
  const token = jwt.sign({ id: "user-id" }, env.JWT_ACCESS_TOKEN_SECRET, { expiresIn: "5m" });
  const app = express();
  app.use(express.json());
  app.use("/api/v1/branch", branchRoutes);
  app.use(errorHandler);
  const server = app.listen(0, "127.0.0.1");
  await once(server, "listening");
  const base = `http://127.0.0.1:${(server.address() as AddressInfo).port}/api/v1/branch`;
  const request = (method: string, path: string, body?: unknown, authorization = `Bearer ${token}`) => fetch(base + path, {
    method, headers: { Authorization: authorization, "Content-Type": "application/json" },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  const cases = [["POST", "/create-branch", payload, 201], ["PATCH", `/update-branch/${id}`, { name: "Updated" }, 200], ["DELETE", `/delete-branch/${id}`, undefined, 200], ["GET", "/get-all-branches", undefined, 200]] as const;
  try {
    for (const [method, path, body] of cases) {
      assert.equal((await request(method, path, body, "")).status, 401);
      assert.equal((await request(method, path, body, "Bearer invalid")).status, 401);
    }
    for (const candidate of Object.values(SYSTEM_USER_ROLE)) {
      role = candidate;
      const allowed = ["RIZQON_CEO", "RIZQON_MANAGER", "RIZQON_OWNER"].includes(role);
      for (const [method, path, body, expected] of cases) {
        assert.equal((await request(method, path, body)).status, allowed ? expected : 403);
      }
    }
    role = SYSTEM_USER_ROLE.RIZQON_CEO;
    for (const inactive of ["INACTIVE", "SUSPENDED", "DELETED"] as const) {
      status = inactive;
      for (const [method, path, body] of cases) assert.equal((await request(method, path, body)).status, 404);
    }
    status = "ACTIVE";
    const beforeInvalid = mutation.mock.callCount();
    assert.equal((await request("PATCH", `/update-branch/${id}`, {})).status, 400);
    assert.equal((await request("PATCH", `/update-branch/${id}`, { businessId })).status, 400);
    assert.equal((await request("DELETE", "/delete-branch/bad")).status, 400);
    assert.equal(mutation.mock.callCount(), beforeInvalid);
    missing = true;
    for (const [method, path, body] of cases.slice(0, 3)) assert.equal((await request(method, path, body)).status, 404);
    assert.equal(mutation.mock.callCount(), beforeInvalid);
    missing = false;
    empty = true;
    assert.deepEqual((await (await request("GET", "/get-all-branches")).json()).data, []);
    empty = false;
    for (const [code, expected, errorCode] of [["P2002", 409, "RESOURCE_CONFLICT"], ["P2003", 409, "RELATION_CONFLICT"], ["P2025", 404, "RECORD_NOT_FOUND"], ["P1001", 503, "DATABASE_UNAVAILABLE"], ["P9999", 500, "INTERNAL_SERVER_ERROR"]] as const) {
      failure = code;
      const response = await request("PATCH", `/update-branch/${id}`, { name: "Updated" });
      assert.equal(response.status, expected);
      const body = await response.json();
      assert.equal(body.error.code, errorCode);
      assert.equal(JSON.stringify(body).includes("private database detail"), false);
    }
  } finally {
    prisma.user.findUnique = originals.user;
    prisma.business.findUnique = originals.business;
    prisma.branch.findUnique = originals.find;
    prisma.branch.create = originals.create;
    prisma.branch.update = originals.update;
    prisma.branch.delete = originals.delete;
    prisma.branch.findMany = originals.list;
    env.JWT_ACCESS_TOKEN_SECRET = secret;
    await new Promise<void>((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
  }
});
