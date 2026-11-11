import assert from "node:assert/strict";
import { test } from "node:test";
import { bussinessValidation } from "../src/module/bussiness/business.validaton.js";
import { businessService } from "../src/module/bussiness/business.service.js";
import { prisma } from "../src/lib/prisma.js";

const payload = {
  business: {
    Business_name: "Rahim Electronics",
    business_slug: "rahim-electronics",
    legalName: "Rahim Electronics Ltd.",
    registrationNumber: "TRAD-2026-001",
    taxIdentificationNumber: "TIN123456789",
    Business_phone: "01712345678",
    Business_email: "contact@rahimelectronics.com",
    Business_Main_address: "Dhaka, Bangladesh",
    currency: "BDT",
  },
  employee: {
    Employee_phone: "+8801712345678",
    Employee_email: " OWNER@example.com ",
  },
};

test("business creation requires a separate valid employee while updates remain business-only", () => {
  const schema = bussinessValidation.createBusinessSchema;
  const parsed = schema.parse(payload);
  assert.equal(parsed.employee.Employee_email, "owner@example.com");
  assert.equal(parsed.business.currency, "BDT");
  assert.equal(schema.safeParse({ business: payload.business }).success, false);
  assert.equal(schema.safeParse({ ...payload, employee: { ...payload.employee, Employee_phone: "bad" } }).success, false);
  assert.equal(schema.safeParse({ ...payload, employee: { ...payload.employee, userId: "injected" } }).success, false);
  for (const email of [undefined, null, "", "invalid"]) {
    assert.equal(schema.safeParse({ ...payload, employee: { ...payload.employee, Employee_email: email } }).success, false);
  }
  assert.equal(schema.safeParse({ ...payload, business: { ...payload.business, name: "Old field" } }).success, false);
  assert.deepEqual(bussinessValidation.updateBusinessSchema.parse({ name: "New name" }), { name: "New name" });
  assert.equal(bussinessValidation.updateBusinessSchema.safeParse({ employee: payload.employee }).success, false);
});

test("creation returns its result, links the existing owner and rejects an unmatched user before writes", async () => {
  const original = prisma.$transaction;
  const originalBusiness = prisma.business.findFirst;
  const originalUser = prisma.user.findFirst;
  const writes: { model: string; data: Record<string, unknown> }[] = [];
  let conflict = false;
  const create = (model: string, result: object) => async ({ data }: { data: Record<string, unknown> }) => {
    writes.push({ model, data });
    return result;
  };
  const tx = {

    business: { findUnique: async () => null, create: create("business", { id: "business-id" }) },
    branch: { create: create("branch", { id: "branch-id" }) },
    employee: { create: create("employee", { Employee_id: "employee-id" }) },
    employeeBranch: { create: create("employeeBranch", { id: "assignment-id" }) },
  };
  prisma.business.findFirst = (async () => null) as typeof prisma.business.findFirst;
  prisma.user.findFirst = (async ({ where }: { where: { email: string; phone: string } }) => {
    assert.equal(where.email, "owner@example.com");
    assert.equal(where.phone, payload.employee.Employee_phone);
    return conflict ? null : { id: "owner-user", name: "Stored Owner", email: where.email, phone: where.phone };
  }) as typeof prisma.user.findFirst;
  prisma.$transaction = (async (callback: (client: typeof tx) => unknown) => callback(tx)) as typeof prisma.$transaction;
  try {
    const result = await businessService.createBusiness(bussinessValidation.createBusinessSchema.parse(payload));
    assert.equal(result.business.id, "business-id");
    assert.equal(result.businessOwner.Employee_id, "employee-id");
    assert.deepEqual(writes.map(({ model }) => model), ["business", "branch", "employee", "employeeBranch"]);
    assert.equal(writes[0].data.employee, undefined);
    assert.equal(writes[0].data.Business_name, payload.business.Business_name);
    assert.equal(writes[2].data.Employee_name, "Stored Owner");
    assert.equal(writes[2].data.userId, "owner-user");
    assert.equal(writes[2].data.Employee_jobTitle, "OWNER");
    assert.equal(writes[2].data.Employee_baseSalary, "0.00");
    assert.equal(writes[3].data.employeeId, "employee-id");
    conflict = true;
    writes.length = 0;
    await assert.rejects(() => businessService.createBusiness(bussinessValidation.createBusinessSchema.parse(payload)), /Not Exist/);
    assert.equal(writes.length, 0);
  } finally {
    prisma.$transaction = original;
    prisma.business.findFirst = originalBusiness;
    prisma.user.findFirst = originalUser;
  }
});
