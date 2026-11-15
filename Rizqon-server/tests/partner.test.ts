import assert from "node:assert/strict";
import { test } from "node:test";
import { partnerValidation } from "../src/module/Partner/partner.validation.js";
import { partnerService } from "../src/module/Partner/partner.service.js";
import { prisma } from "../src/lib/prisma.js";

const id = "cm123456789012345678901234";
const linkedId = "cm223456789012345678901234";
const payload = {
  businessId: id, name: " Test Partner ", phone: "+8801712345678",
  email: " PARTNER@example.com ", address: " Dhaka ", kind: "SUPPLIER" as const,
};

test("partner validation normalizes input and rejects invalid or unsafe updates", () => {
  const parsed = partnerValidation.createPartnerSchema.parse(payload);
  assert.equal(parsed.name, "Test Partner");
  assert.equal(parsed.email, "partner@example.com");
  for (const data of [{ ...payload, kind: "INVALID" }, { ...payload, phone: "bad" }, { ...payload, businessId: "bad" }]) {
    assert.equal(partnerValidation.createPartnerSchema.safeParse(data).success, false);
  }
  for (const data of [{}, { businessId: linkedId }, { id }, { email: "bad" }]) {
    assert.equal(partnerValidation.updatePartnerSchema.safeParse(data).success, false);
  }
  assert.deepEqual(partnerValidation.updatePartnerSchema.parse({ linkedBusinessId: null }), { linkedBusinessId: null });
});

test("partner CRUD checks references, handles missing records, and preserves delete restrictions", async () => {
  const originals = {
    business: prisma.business.findUnique, get: prisma.partner.findUnique,
    create: prisma.partner.create, update: prisma.partner.update,
    delete: prisma.partner.delete, all: prisma.partner.findMany,
  };
  const partner = { ...partnerValidation.createPartnerSchema.parse(payload), id };
  let missingBusiness = false;
  let missingPartner = false;
  let restricted = false;
  let writes = 0;
  prisma.business.findUnique = (async () => missingBusiness ? null : { id }) as typeof prisma.business.findUnique;
  prisma.partner.findUnique = (async () => missingPartner ? null : partner) as typeof prisma.partner.findUnique;
  prisma.partner.create = (async () => { writes++; return partner; }) as typeof prisma.partner.create;
  prisma.partner.update = (async ({ data }: { data: object }) => { writes++; return { ...partner, ...data }; }) as typeof prisma.partner.update;
  const restriction = Object.assign(new Error("Foreign key restriction"), { code: "P2003" });
  prisma.partner.delete = (async () => { if (restricted) throw restriction; writes++; return partner; }) as typeof prisma.partner.delete;
  prisma.partner.findMany = (async () => [partner]) as typeof prisma.partner.findMany;
  try {
    assert.equal(await partnerService.createPartner(payload), partner);
    assert.equal(await partnerService.getPartner({ id }), partner);
    assert.deepEqual(await partnerService.getAllPartners(), [partner]);
    assert.equal((await partnerService.updatePartner({ id }, { name: "Updated" })).name, "Updated");
    assert.equal((await partnerService.updatePartner({ id }, { linkedBusinessId: null })).linkedBusinessId, null);
    missingBusiness = true;
    const before = writes;
    await assert.rejects(() => partnerService.createPartner(payload), /Business not found/);
    await assert.rejects(() => partnerService.updatePartner({ id }, { linkedBusinessId: linkedId }), /Linked business not found/);
    assert.equal(writes, before);
    missingBusiness = false;
    missingPartner = true;
    await assert.rejects(() => partnerService.getPartner({ id }), /Partner not found/);
    await assert.rejects(() => partnerService.updatePartner({ id }, { name: "Updated" }), /Partner not found/);
    await assert.rejects(() => partnerService.deletePartner({ id }), /Partner not found/);
    assert.equal(writes, before);
    missingPartner = false;
    restricted = true;
    await assert.rejects(() => partnerService.deletePartner({ id }), (error) => error === restriction);
    restricted = false;
    assert.equal(await partnerService.deletePartner({ id }), partner);
  } finally {
    prisma.business.findUnique = originals.business;
    prisma.partner.findUnique = originals.get;
    prisma.partner.create = originals.create;
    prisma.partner.update = originals.update;
    prisma.partner.delete = originals.delete;
    prisma.partner.findMany = originals.all;
  }
});
