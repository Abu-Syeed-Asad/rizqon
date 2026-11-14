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
    Employee_email: " OWNER@example.com ",
  },
};

test("business creation validates the system user email and updates use model field names", () => {
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
  assert.deepEqual(bussinessValidation.updateBusinessSchema.parse({ Business_name: "New name" }), { Business_name: "New name" });
  assert.equal(bussinessValidation.updateBusinessSchema.safeParse({ employee: payload.employee }).success, false);
});

test("creation returns its result, links the existing owner and rejects an unmatched user before writes", async () => {
  const original = prisma.$transaction;
  const originalBusiness = prisma.business.findFirst;
  const originalUser = prisma.user.findUnique;
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
  prisma.user.findUnique = (async ({ where }: { where: { email: string } }) => {
    assert.equal(where.email, "owner@example.com");
    return conflict ? null : { id: "owner-user", name: "Stored Owner", email: where.email, phone: "+8801712345678" };
  }) as typeof prisma.user.findUnique;
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
    prisma.user.findUnique = originalUser;
  }
});


test("update validation accepts owner email without employeeId and rejects unsafe or empty fields", () => {
  const schema = bussinessValidation.updateBusinessSchema;
  const owner = { Employee_email: " OWNER@example.com " };
  assert.deepEqual(schema.parse({ owner }), {
    owner: { Employee_email: "owner@example.com" },
  });
  for (const invalid of [{}, { owner: {} }, { owner: { Employee_email: "invalid" } }, { employeeId: "employee-id" },
    { name: "Old name" }, { owner: { ...owner, Employee_name: "Injected" }, employeeId: "employee-id" }]) {
    assert.equal(schema.safeParse(invalid).success, false);
  }
});

test("updates return the business and synchronize only its owner from the system user", async () => {
  const original = prisma.$transaction;
  const business = { id: "business-id", currency: "USD" };
  const writes: { model: string; args: any }[] = [];
  let missingBusiness = false;
  let missingOwner = false;
  let missingUser = false;
  let phone: string | null = "+8801712345678";
  let duplicate = false;
  let multipleOwners = false;
  let sameOwner = false;
  const tx = {
    business: {
      findUnique: async () => missingBusiness ? null : business,
      update: async (args: any) => { writes.push({ model: "business", args }); return { ...business, ...args.data }; },
    },
    user: { findUnique: async () => missingUser ? null : { id: "user-id", name: "Stored Owner", email: "owner@example.com", phone } },
    employee: {
      findMany: async ({ where, take }: any) => {
        assert.deepEqual(where, { businessId: business.id, Employee_jobTitle: "OWNER" });
        assert.equal(take, 2);
        if (missingOwner) return [];
        return multipleOwners ? [{ Employee_id: "employee-id" }, { Employee_id: "second-owner" }] : [{ Employee_id: "employee-id" }];
      },
      findUnique: async ({ where }: any) => {
        assert.deepEqual(where, { businessId_userId: { businessId: business.id, userId: "user-id" } });
        return duplicate ? { Employee_id: "another-employee" } : sameOwner ? { Employee_id: "employee-id" } : null;
      },
      update: async (args: any) => { writes.push({ model: "employee", args }); return {}; },
    },
  };
  prisma.$transaction = (async (callback: (client: typeof tx) => unknown) => callback(tx)) as typeof prisma.$transaction;
  const update = bussinessValidation.updateBusinessSchema.parse({
    Business_name: "Updated business", owner: { Employee_email: "owner@example.com" },
  });
  try {
    const result = await businessService.updateBusiness(business.id, update);
    assert.equal(result.Business_name, "Updated business");
    assert.deepEqual(writes[0].args.where, { Employee_id: "employee-id", businessId: business.id, Employee_jobTitle: "OWNER" });
    assert.deepEqual(writes[0].args.data, { userId: "user-id", Employee_name: "Stored Owner", Employee_phone: phone, Employee_email: "owner@example.com" });
    assert.deepEqual(writes[1].args.data, { Business_name: "Updated business" });
    writes.length = 0;
    assert.equal(await businessService.updateBusiness(business.id, { owner: update.owner }), business);
    assert.deepEqual(writes.map((write) => write.model), ["employee"]);
    writes.length = 0;
    await businessService.updateBusiness(business.id, { Business_name: "Only business" });
    assert.deepEqual(writes.map((write) => write.model), ["business"]);
    writes.length = 0;
    sameOwner = true;
    await businessService.updateBusiness(business.id, { owner: update.owner });
    sameOwner = false;
    writes.length = 0;
    multipleOwners = true;
    await assert.rejects(() => businessService.updateBusiness(business.id, update), /Multiple owners/);
    multipleOwners = false;
    missingBusiness = true;
    await assert.rejects(() => businessService.updateBusiness(business.id, update), /Business not found/);
    missingBusiness = false;
    missingOwner = true;
    await assert.rejects(() => businessService.updateBusiness(business.id, update), /Owner not found/);
    missingOwner = false;
    missingUser = true;
    await assert.rejects(() => businessService.updateBusiness(business.id, update), /does not exist/);
    missingUser = false;
    phone = null;
    await assert.rejects(() => businessService.updateBusiness(business.id, update), /phone number/);
    phone = "+8801712345678";
    duplicate = true;
    await assert.rejects(() => businessService.updateBusiness(business.id, update), /already an employee/);
    await assert.rejects(() => businessService.updateBusiness("", update), /id is required/);
    assert.equal(writes.length, 0);
  } finally {
    prisma.$transaction = original;
  }
});
