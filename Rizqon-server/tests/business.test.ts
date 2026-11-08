import assert from "node:assert/strict";
import { test, mock } from "node:test";
import { bussinessValidation } from "../src/module/bussiness/business.validaton.js";
import { businessService } from "../src/module/bussiness/business.service.js";
import { prisma } from "../src/lib/prisma.js";
import { Prisma, SYSTEM_USER_ROLE } from "../prisma/generated/prisma/client.js";

test("partial business updates preserve omitted fields and reject invalid bodies", () => {
  const schema = bussinessValidation.updateBusinessSchema;
  assert.deepEqual(schema.parse({ name: " Updated business " }), { name: "Updated business" });
  assert.deepEqual(schema.parse({ phone: null }), { phone: null });
  for (const body of [{}, { status: "ACTIVE" }, { name: "" }, { currency: "INVALID" }, { business_slug: "Invalid Slug" }]) {
    assert.equal(schema.safeParse(body).success, false);
  }
});

test("business mutations enforce roles and map missing records and conflicts", async () => {
  const ceo = { user_role: SYSTEM_USER_ROLE.RIZQON_CEO };
  const manager = { user_role: SYSTEM_USER_ROLE.RIZQON_MANAGER };
  let failure: string | undefined;
  const mutation = async (args: { where: { id: string }; data?: unknown }) => {
    if (failure) {
      throw new Prisma.PrismaClientKnownRequestError("test failure", { code: failure, clientVersion: "test" });
    }
    return { id: args.where.id, ...(args.data as object) };
  };
  const originalUpdate = prisma.business.update;
  const originalDelete = prisma.business.delete;
  const update = mock.fn(mutation);
  const remove = mock.fn(mutation);
  prisma.business.update = update as unknown as typeof originalUpdate;
  prisma.business.delete = remove as unknown as typeof originalDelete;
  try {
    await assert.rejects(businessService.updateBusiness("business-id", { name: "New name" }, manager), { statusCode: 403 });
    await assert.rejects(businessService.deleteBusiness("business-id", manager), { statusCode: 403 });
    assert.equal(update.mock.callCount(), 0);
    assert.equal(remove.mock.callCount(), 0);
    assert.deepEqual(await businessService.updateBusiness("business-id", { name: "New name" }, ceo), { id: "business-id", name: "New name" });
    assert.deepEqual(await businessService.deleteBusiness("business-id", ceo), { id: "business-id" });
    failure = "P2025";
    await assert.rejects(businessService.updateBusiness("missing", { name: "New name" }, ceo), { statusCode: 404 });
    await assert.rejects(businessService.deleteBusiness("missing", ceo), { statusCode: 404 });
    failure = "P2002";
    await assert.rejects(businessService.updateBusiness("business-id", { business_slug: "taken" }, ceo), { statusCode: 409 });
    failure = "P2003";
    await assert.rejects(businessService.deleteBusiness("business-id", ceo), { statusCode: 409 });
  } finally {
    prisma.business.update = originalUpdate;
    prisma.business.delete = originalDelete;
  }
});
