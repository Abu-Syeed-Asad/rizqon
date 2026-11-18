import assert from "node:assert/strict";
import { test } from "node:test";
import { prisma } from "../src/lib/prisma.js";
import { productService } from "../src/module/Product/product.service.js";
import { productValidation } from "../src/module/Product/product.validation.js";

const id = "cm123456789012345678901234";
const scope = { businessId: id };
const branchParams = { branchId: id };
const params = { id, ...branchParams };
const payload = { businessId: id, name: "Test product", slug: "test-product", price: "100.25", categoryId: id, unit: "piece" };

test("product validation protects scope and decimal precision", () => {
  assert.equal(productValidation.createProductSchema.parse({ ...payload, price: 12.5 }).price, "12.5");
  for (const price of ["-1", "1.001", "10000000000000000", "NaN", "1e5"]) {
    assert.equal(productValidation.createProductSchema.safeParse({ ...payload, price }).success, false);
  }
  for (const update of [{}, { businessId: id }, { employeeId: id }, { userId: id }, { branchId: id }]) {
    assert.equal(productValidation.updateProductSchema.safeParse(update).success, false);
  }
  assert.deepEqual(productValidation.updateProductSchema.parse({ businessId: id, brandId: null }), { businessId: id, brandId: null });
  for (const spoof of [{ employeeId: id }, { branchId: id }, { email: "other@example.com" }, { userId: id }]) {
    assert.equal(productValidation.createProductSchema.safeParse({ ...payload, ...spoof }).success, false);
    assert.equal(productValidation.updateProductSchema.safeParse({ businessId: id, name: "Updated", ...spoof }).success, false);
    assert.equal(productValidation.deleteProductSchema.safeParse({ businessId: id, ...spoof }).success, false);
  }
  assert.equal(productValidation.deleteProductSchema.safeParse({}).success, false);
  assert.equal(productValidation.branchParamsSchema.safeParse({}).success, false);
  assert.equal(productValidation.branchParamsSchema.safeParse({ branchId: "invalid" }).success, false);
  assert.equal(productValidation.mutationParamsSchema.safeParse({ id }).success, false);
});

test("all product mutations enforce actor, title, business and branch before writing", async () => {
  const original = prisma.$transaction;
  let title = "INVENTORY_MANAGER";
  let active = true;
  let employeeBusinessId = id;
  let businessExists = true;
  
  
  let assigned = true;
  let branchActive = true;
  let branchBusinessId = id;
  let employeeExists = true;
  let productExists = true;
  let categoryExists = true;
  let brandExists = true;
  let writes = 0;
  const actor = { id: "authenticated-user", email: "staff@example.com" };
  const product = { id, businessId: id };
  const tx = {
    employee: { findMany: async (args: unknown) => {
      assert.deepEqual(args, {
        where: { Employee_email: { equals: actor.email, mode: "insensitive" }, userId: actor.id },
        select: { Employee_id: true, businessId: true, Employee_jobTitle: true, isActive: true },
      });
      return employeeExists ? [{ Employee_id: id, businessId: employeeBusinessId, Employee_jobTitle: title, isActive: active }] : [];
    } },
    business: { findUnique: async () => businessExists ? { id } : null },
    employeeBranch: { findFirst: async ({ where }: { where: { businessId: string; employeeId: string; branchId: string; branch: { businessId: string; isActive: boolean } } }) => {
      assert.equal(where.businessId, id);
      assert.equal(where.employeeId, id);
      assert.deepEqual(where.branch, { businessId: id, isActive: true });
      return assigned && where.branchId === id && branchActive && branchBusinessId === where.branch.businessId ? { branchId: id } : null;
    } },    category: { findUnique: async () => categoryExists ? { id, isActive: true } : null },
    brand: { findUnique: async () => brandExists ? { id } : null },
    product: {
      findUnique: async ({ where }: { where: unknown }) => {
        assert.deepEqual(where, { businessId_id: { businessId: id, id } });
        return productExists ? product : null;
      },
      create: async ({ data }: { data: object }) => { writes++; assert.deepEqual(data, { ...payload, businessId: id }); return product; },
      update: async ({ where }: { where: unknown }) => { writes++; assert.deepEqual(where, { businessId_id: { businessId: id, id } }); return product; },
      delete: async ({ where }: { where: unknown }) => { writes++; assert.deepEqual(where, { businessId_id: { businessId: id, id } }); return product; },
    },
  };
  prisma.$transaction = (async (callback: (client: typeof tx) => unknown) => callback(tx)) as typeof prisma.$transaction;
  const operations = [
    () => productService.createProduct(actor, branchParams, payload),
    () => productService.updateProduct(actor, params, { businessId: id, name: "Updated" }),
    () => productService.deleteProduct(actor, params, scope),
  ];
  const denied = async () => {
    const before = writes;
    for (const operation of operations) await assert.rejects(operation);
    assert.equal(writes, before);
  };
  try {
    for (title of ["INVENTORY_MANAGER", "INVENTORY_OFFICER", "WAREHOUSE_MANAGER"]) {
      for (const operation of operations) assert.equal(await operation(), product);
    }
    title = "OWNER"; await denied();
    title = "INVENTORY_MANAGER";
    active = false; await denied(); active = true;
    employeeBusinessId = "another-business"; await denied(); employeeBusinessId = id;
    employeeExists = false; await denied(); employeeExists = true;
    businessExists = false; await denied(); businessExists = true;


    assigned = false; await denied(); assigned = true;
    branchActive = false; await denied(); branchActive = true;
    branchBusinessId = "another-business"; await denied(); branchBusinessId = id;
    const before = writes;
    const otherBranch = { branchId: "cm223456789012345678901234" };
    for (const operation of [
      () => productService.createProduct(actor, otherBranch, payload),
      () => productService.updateProduct(actor, { id, ...otherBranch }, { businessId: id, name: "Updated" }),
      () => productService.deleteProduct(actor, { id, ...otherBranch }, scope),
    ]) {
      await assert.rejects(operation, /requested active branch/);
    }
    assert.equal(writes, before);
    await assert.rejects(() => productService.createProduct({ id: "", email: actor.email }, branchParams, payload), /Authentication required/);
    productExists = false;
    await assert.rejects(operations[1], /Product not found/);
    await assert.rejects(operations[2], /Product not found/);
    productExists = true;
    categoryExists = false;
    await assert.rejects(operations[0], /category/);
    await assert.rejects(() => productService.updateProduct(actor, params, { businessId: id, categoryId: id }), /category/);
    categoryExists = true;
    brandExists = false;
    await assert.rejects(() => productService.createProduct(actor, branchParams, { ...payload, brandId: id }), /Brand/);
    await assert.rejects(() => productService.updateProduct(actor, params, { businessId: id, brandId: id }), /Brand/);
    assert.equal(writes, before);
  } finally {
    prisma.$transaction = original;
  }
});


