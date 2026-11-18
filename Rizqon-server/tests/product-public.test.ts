import assert from "node:assert/strict";
import { test } from "node:test";
import express, { type ErrorRequestHandler } from "express";
import { once } from "node:events";
import { prisma } from "../src/lib/prisma.js";
import { productRoutes } from "../src/module/Product/product.route.js";

test("public product reads work without a token while mutations remain protected", async () => {
  const originalGet = prisma.product.findUnique;
  const originalAll = prisma.product.findMany;
  const id = "cm123456789012345678901234";
  const product = { id, name: "Public product", isActive: true };
  let found = true;
  prisma.product.findUnique = (async ({ where }: { where: unknown }) => {
    assert.deepEqual(where, { id, isActive: true });
    return found ? product : null;
  }) as typeof prisma.product.findUnique;
  prisma.product.findMany = (async (args: unknown) => {
    assert.deepEqual(args, { where: { isActive: true }, orderBy: [{ createdAt: "desc" }, { id: "asc" }] });
    return found ? [product] : [];
  }) as typeof prisma.product.findMany;
  const app = express();
  app.use(express.json());
  app.use("/product", productRoutes);
  const errors: ErrorRequestHandler = (error, _req, res, _next) => {
    res.status(error.statusCode ?? 400).json({ message: error.message });
  };
  app.use(errors);
  const server = app.listen(0, "127.0.0.1");
  try {
    await once(server, "listening");
    const address = server.address();
    assert.ok(address && typeof address !== "string");
    const base = `http://127.0.0.1:${address.port}/product`;
    const all = await fetch(`${base}/get-all-products`);
    assert.equal(all.status, 200);
    assert.deepEqual((await all.json()).data, [product]);
    const single = await fetch(`${base}/get-product/${id}`);
    assert.equal(single.status, 200);
    assert.deepEqual((await single.json()).data, product);
    assert.equal((await fetch(`${base}/get-product/invalid`)).status, 400);
    found = false;
    assert.equal((await fetch(`${base}/get-product/${id}`)).status, 404);
    assert.deepEqual((await (await fetch(`${base}/get-all-products`)).json()).data, []);
    for (const [method, path] of [["POST", `create-product/${id}`], ["PATCH", `update-product/${id}/${id}`], ["DELETE", `delete-product/${id}/${id}`]]) {
      assert.equal((await fetch(`${base}/${path}`, { method })).status, 401);
    }
  } finally {
    server.closeAllConnections();
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    prisma.product.findUnique = originalGet;
    prisma.product.findMany = originalAll;
  }
});

