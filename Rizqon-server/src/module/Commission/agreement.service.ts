import { Prisma } from "../../../prisma/generated/prisma/client.js";
import { audit, authorize, fail, requirePartner, tenantKey, transaction, type Actor } from "./commission.common.js";
import { createAgreementSchema, updateAgreementSchema, listSchema, idSchema } from "./commission.validation.js";

const include = { assignments: true, activations: { orderBy: { startsAt: "asc" as const } } };

async function requireVariants(tx: Prisma.TransactionClient, businessId: string, ids: string[]) {
  const count = await tx.productVariant.count({ where: { businessId, id: { in: ids }, isActive: true, product: { isActive: true } } });
  if (count !== ids.length) fail("Every variant must be active and belong to this business", 400, "INVALID_VARIANTS");
}

async function checkOverlap(tx: Prisma.TransactionClient, businessId: string, ids: string[], startsAt: Date, endsAt: Date | null, exclude?: string) {
  const beforeEnd = endsAt ? { lt: endsAt } : undefined;
  const overlap = await tx.commissionAgreement.findFirst({ where: {
    businessId, ...(exclude ? { id: { not: exclude } } : {}),
    assignments: { some: { businessId, variantId: { in: ids } } },
    OR: [
      { firstActivatedAt: null, expiredAt: null, startsAt: beforeEnd, OR: [{ endsAt: null }, { endsAt: { gt: startsAt } }] },
      { activations: { some: { startsAt: beforeEnd, AND: [
        { OR: [{ endsAt: null }, { endsAt: { gt: startsAt } }] },
        // Deactivating before a scheduled start retains a zero-length historical window.
        { OR: [{ endsAt: null }, { endsAt: { gt: tx.commissionAgreementActivation.fields.startsAt } }] },
      ] } } },
    ],
  }, select: { id: true } });
  if (overlap) fail("An overlapping agreement already reserves one of these variants", 409, "AGREEMENT_OVERLAP");
}

async function create(actor: Actor, tenant: string, payload: unknown) {
  const data = createAgreementSchema.parse(payload);
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "agreement");
    const { businessId } = scope;
    await requirePartner(tx, businessId, data.partnerId);
    await requireVariants(tx, businessId, data.productVariantIds);
    if (data.endsAt && data.endsAt <= new Date()) fail("A new agreement must not already be expired", 400);
    await checkOverlap(tx, businessId, data.productVariantIds, data.startsAt, data.endsAt);
    const { productVariantIds, ...configuration } = data;
    const agreement = await tx.commissionAgreement.create({ data: { ...configuration, businessId,
      business_name: scope.businessName, isActive: false,
      assignments: { create: productVariantIds.map(variantId => ({ variantId })) } }, include });
    await audit(tx, scope, "CREATED", "COMMISSION_AGREEMENT", agreement.id, undefined, agreement);
    return agreement;
  });
}

async function update(actor: Actor, tenant: string, id: string, payload: unknown) {
  const data = updateAgreementSchema.parse(payload);
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "agreement");
    const where = tenantKey(scope.businessId, idSchema.parse(id));
    const before = await tx.commissionAgreement.findUnique({ where, include });
    if (!before) fail("Agreement not found", 404);
    if (before.firstActivatedAt || before.expiredAt || before.isActive ||
      await tx.commissionEntry.count({ where: { businessId: scope.businessId, agreementId: id } })) {
      fail("Only an unused draft may be edited; create a new agreement for a new rate");
    }
    const startsAt = data.startsAt ?? before.startsAt;
    const endsAt = data.endsAt === undefined ? before.endsAt : data.endsAt;
    if (endsAt && (endsAt <= startsAt || endsAt <= new Date())) fail("Invalid agreement effective dates", 400);
    const ids = data.productVariantIds ?? before.assignments.map(v => v.variantId);
    await requirePartner(tx, scope.businessId, data.partnerId ?? before.partnerId);
    await requireVariants(tx, scope.businessId, ids);
    await checkOverlap(tx, scope.businessId, ids, startsAt, endsAt, id);
    const { productVariantIds: _ids, ...configuration } = data;
    await tx.commissionAgreementVariant.deleteMany({ where: { businessId: scope.businessId, agreementId: id } });
    const after = await tx.commissionAgreement.update({ where, data: { ...configuration,
      assignments: { create: ids.map(variantId => ({ variantId })) } }, include });
    await audit(tx, scope, "UPDATED", "COMMISSION_AGREEMENT", id, before, after);
    return after;
  });
}

async function transition(actor: Actor, tenant: string, id: string, action: "activate" | "deactivate" | "expire") {
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "agreement");
    const where = tenantKey(scope.businessId, idSchema.parse(id));
    const before = await tx.commissionAgreement.findUnique({ where, include });
    if (!before) fail("Agreement not found", 404);
    const now = new Date();
    if (action === "activate") {
      if (before.expiredAt || (before.endsAt && before.endsAt <= now)) fail("An expired agreement cannot be activated");
      if (before.isActive) return before;
      const ids = before.assignments.map(a => a.variantId);
      if (!ids.length) fail("Assign variants before activation", 400);
      await requirePartner(tx, scope.businessId, before.partnerId);
      await requireVariants(tx, scope.businessId, ids);
      const startsAt = before.startsAt > now ? before.startsAt : now;
      await checkOverlap(tx, scope.businessId, ids, startsAt, before.endsAt, id);
      await tx.commissionAgreementActivation.create({ data: { businessId: scope.businessId, agreementId: id,
        startsAt, endsAt: before.endsAt } });
    } else {
      if (action === "expire" && before.expiredAt) return before;
      if (action === "deactivate" && !before.isActive) return before;
      // End future/open windows without erasing the periods that applied to older sales.
      for (const activation of before.activations) {
        if (!activation.endsAt || activation.endsAt > now) {
          await tx.commissionAgreementActivation.update({ where: { id: activation.id },
            data: { endsAt: activation.startsAt > now ? activation.startsAt : now } });
        }
      }
    }
    const after = await tx.commissionAgreement.update({ where, data: {
      isActive: action === "activate",
      ...(action === "activate" ? { firstActivatedAt: before.firstActivatedAt ?? now } : {}),
      ...(action === "expire" ? { expiredAt: now } : {}),
    }, include });
    await audit(tx, scope, action === "activate" ? "ACTIVATED" : "DEACTIVATED", "COMMISSION_AGREEMENT", id, before, after);
    return after;
  });
}

async function list(actor: Actor, tenant: string, query: unknown) {
  const { partnerId, page, limit } = listSchema.parse(query);
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "read");
    return tx.commissionAgreement.findMany({ where: { businessId: scope.businessId, partnerId }, include,
      orderBy: [{ createdAt: "desc" }, { id: "asc" }], take: limit, skip: (page - 1) * limit });
  });
}

async function get(actor: Actor, tenant: string, id: string, history = false) {
  return transaction(async tx => {
    const scope = await authorize(tx, actor, idSchema.parse(tenant), "read");
    const agreement = await tx.commissionAgreement.findUnique({ where: tenantKey(scope.businessId, idSchema.parse(id)), include });
    if (!agreement) fail("Agreement not found", 404);
    if (!history) return agreement;
    return tx.auditLog.findMany({ where: { businessId: scope.businessId, entityType: "COMMISSION_AGREEMENT", entityId: id },
      orderBy: [{ createdAt: "asc" }, { id: "asc" }] });
  });
}

export const agreementService = { create, update, transition, list, get };
