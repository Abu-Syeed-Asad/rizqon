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
import { categoryRoutes } from "../src/module/Product-Category/category.route.js";
import { categoryValidation } from "../src/module/Product-Category/category.validation.js";

const id = "cm12345678901234567890124";
const businessId = "cm12345678901234567890123";
const payload = { businessId, name: "Dhaka", category_slug: "mobile-phone" };

test("category schemas validate create and partial updates without resetting omitted fields", () => {
  assert.equal(categoryValidation.createCategorySchema.parse(payload).isActive, true);
  const schema = categoryValidation.updateCategorySchema;
  assert.deepEqual(schema.parse({ name: " Updated category " }), { name: "Updated category" });
  assert.deepEqual(schema.parse({ parentId: null, description: null, isActive: false }), { parentId: null, description: null, isActive: false });
  for (const body of [{}, { name: " " }, { name: "a".repeat(151) }, { category_slug: "BAD CODE" }, { category_slug: "" }, { parentId: "invalid" }, { isActive: "false" }, { description: "a".repeat(2001) }, { name: "Valid", businessId }]) {
    assert.equal(schema.safeParse(body).success, false);
  }
  assert.equal(categoryValidation.createCategorySchema.safeParse({ businessId, name: "Valid" }).success, false);
  assert.equal(categoryValidation.categoryParamsSchema.safeParse({ id: "bad" }).success, false);
});

test("category routes enforce roles, validate requests and handle missing records and database conflicts", async () => {
  let role: User["user_role"] = SYSTEM_USER_ROLE.RIZQON_CEO;
  let status: User["status"] = "ACTIVE";
  let missing = false;
  let failure: string | undefined;
  let empty = false;
  let parentMode: "root" | "missing" | "cycle" = "root";
  const originals = { user: prisma.user.findUnique, business: prisma.business.findUnique, find: prisma.category.findUnique, create: prisma.category.create, update: prisma.category.update, delete: prisma.category.delete, list: prisma.category.findMany, transaction: prisma.$transaction };
  const mutation = mock.fn(async (..._args: unknown[]) => {
    if (failure) throw new Prisma.PrismaClientKnownRequestError("private database detail", { code: failure, clientVersion: "test" });
    return { id, ...payload };
  });
  prisma.user.findUnique = mock.fn(async () => ({ id: "user-id", user_role: role, status })) as unknown as typeof prisma.user.findUnique;
  prisma.business.findUnique = mock.fn(async () => missing ? null : ({ id: businessId })) as unknown as typeof prisma.business.findUnique;
  prisma.category.findUnique = mock.fn(async (args: { where: { id?: string; businessId_id?: { businessId: string; id: string } } }) => {
    if (missing) return null;
    if (args.where.businessId_id) {
      assert.equal(args.where.businessId_id.businessId, businessId);
      return parentMode === "missing" ? null : { id: args.where.businessId_id.id, parentId: parentMode === "cycle" ? id : null };
    }
    return { id, ...payload, parentId: null };
  }) as unknown as typeof prisma.category.findUnique;
  prisma.$transaction = mock.fn(async (callback: (tx: Prisma.TransactionClient) => Promise<unknown>, options: { isolationLevel: string }) => {
    assert.equal(options.isolationLevel, "Serializable");
    return callback(prisma);
  }) as unknown as typeof prisma.$transaction;
  prisma.category.create = mutation as unknown as typeof prisma.category.create;
  prisma.category.update = mutation as unknown as typeof prisma.category.update;
  prisma.category.delete = mutation as unknown as typeof prisma.category.delete;
  prisma.category.findMany = mock.fn(async () => empty ? [] : [await mutation()]) as unknown as typeof prisma.category.findMany;
  const secret = env.JWT_ACCESS_TOKEN_SECRET;
  env.JWT_ACCESS_TOKEN_SECRET = "category-test-secret-for-local-tests-only";
  const token = jwt.sign({ id: "user-id" }, env.JWT_ACCESS_TOKEN_SECRET, { expiresIn: "5m" });
  const app = express();
  app.use(express.json());
  app.use("/api/v1/category", categoryRoutes);
  app.use(errorHandler);
  const server = app.listen(0, "127.0.0.1");
  await once(server, "listening");
  const base = `http://127.0.0.1:${(server.address() as AddressInfo).port}/api/v1/category`;
  const request = (method: string, path: string, body?: unknown, authorization = `Bearer ${token}`) => fetch(base + path, {
    method, headers: { Authorization: authorization, "Content-Type": "application/json" },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  const cases = [["POST", "/create-category", payload, 201], ["PATCH", `/update-category/${id}`, { name: "Updated" }, 200], ["DELETE", `/delete-category/${id}`, undefined, 200], ["GET", "/get-all-categories", undefined, 200], ["GET", `/get-category/${id}`, undefined, 200]] as const;
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
    assert.equal((await request("PATCH", `/update-category/${id}`, {})).status, 400);
    assert.equal((await request("PATCH", `/update-category/${id}`, { businessId })).status, 400);
    assert.equal((await request("DELETE", "/delete-category/bad")).status, 400);
    assert.equal(mutation.mock.callCount(), beforeInvalid);
    missing = true;
    for (const [method, path, body] of cases.slice(0, 3)) assert.equal((await request(method, path, body)).status, 404);
    assert.equal(mutation.mock.callCount(), beforeInvalid);
    assert.equal((await request("GET", `/get-category/${id}`)).status, 404);
    missing = false;
    assert.equal((await request("GET", "/get-category/bad")).status, 400);
    assert.equal((await (await request("GET", `/get-category/${id}`)).json()).data.id, id);
    const parentId = "cm12345678901234567890125";
    parentMode = "missing";
    assert.equal((await request("POST", "/create-category", { ...payload, parentId })).status, 404);
    assert.equal((await request("PATCH", `/update-category/${id}`, { parentId })).status, 404);
    parentMode = "cycle";
    assert.equal((await request("PATCH", `/update-category/${id}`, { parentId })).status, 409);
    assert.equal((await request("PATCH", `/update-category/${id}`, { parentId: id })).status, 409);
    parentMode = "root";
    assert.equal((await request("POST", "/create-category", { ...payload, parentId })).status, 201);
    assert.equal((await request("PATCH", `/update-category/${id}`, { parentId })).status, 200);
    assert.equal((await request("PATCH", `/update-category/${id}`, { parentId: null })).status, 200);
    empty = true;
    assert.deepEqual((await (await request("GET", "/get-all-categories")).json()).data, []);
    empty = false;
    for (const [code, expected, errorCode] of [["P2002", 409, "RESOURCE_CONFLICT"], ["P2003", 409, "RELATION_CONFLICT"], ["P2025", 404, "RECORD_NOT_FOUND"], ["P1001", 503, "DATABASE_UNAVAILABLE"], ["P9999", 500, "INTERNAL_SERVER_ERROR"]] as const) {
      failure = code;
      const response = await request("PATCH", `/update-category/${id}`, { name: "Updated" });
      assert.equal(response.status, expected);
      const body = await response.json();
      assert.equal(body.error.code, errorCode);
      assert.equal(JSON.stringify(body).includes("private database detail"), false);
    }
  } finally {
    prisma.user.findUnique = originals.user;
    prisma.business.findUnique = originals.business;
    prisma.category.findUnique = originals.find;
    prisma.category.create = originals.create;
    prisma.category.update = originals.update;
    prisma.category.delete = originals.delete;
    prisma.category.findMany = originals.list;
    prisma.$transaction = originals.transaction;
    env.JWT_ACCESS_TOKEN_SECRET = secret;
    await new Promise<void>((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
  }
});

