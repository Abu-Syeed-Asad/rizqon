import { z } from "zod";
import { decimal } from "./commission.math.js";

export const idSchema = z.string().min(1).max(128).regex(/^[a-zA-Z0-9_-]+$/);
export const idempotencySchema = z.string().trim().min(8).max(128).regex(/^[a-zA-Z0-9_:.-]+$/);
export const moneySchema = z.string().regex(/^(0|[1-9]\d{0,15})(\.\d{1,2})?$/).transform(v => decimal(v).toFixed(2));
export const quantitySchema = z.string().regex(/^(0|[1-9]\d{0,14})(\.\d{1,3})?$/)
  .refine(v => decimal(v).gt(0), "Quantity must be positive").transform(v => decimal(v).toFixed(3));
const percent = z.string().regex(/^(0|[1-9]\d{0,2})(\.\d{1,2})?$/)
  .refine(v => decimal(v).lte(100), "Commission must be between 0 and 100").transform(v => decimal(v).toFixed(2));
const date = z.iso.datetime({ offset: true }).transform(v => new Date(v));
export const uniqueIds = z.array(idSchema).min(1).max(500).refine(ids => new Set(ids).size === ids.length, "Duplicate IDs are not allowed");
const agreementFields = { partnerId: idSchema, commissionPercent: percent, startsAt: date,
  endsAt: date.nullable().default(null), productVariantIds: uniqueIds };
export const createAgreementSchema = z.strictObject(agreementFields).refine(v => !v.endsAt || v.endsAt > v.startsAt,
  { message: "endsAt must be after startsAt", path: ["endsAt"] });
export const updateAgreementSchema = z.strictObject({ ...agreementFields, endsAt: date.nullable() }).partial()
  .refine(v => Object.keys(v).length > 0, "An update is required");
export const settlementSchema = z.strictObject({ partnerId: idSchema, commissionEntryIds: uniqueIds, idempotencyKey: idempotencySchema });
export const editSettlementSchema = z.strictObject({ commissionEntryIds: uniqueIds });
export const paymentSchema = z.strictObject({
  amount: moneySchema.refine(v => decimal(v).gt(0), "Payment must be positive"),
  method: z.enum(["CASH", "CARD", "MOBILE_BANKING", "BANK_TRANSFER"]),
  idempotencyKey: idempotencySchema, note: z.string().trim().min(1).max(1000).optional(),
});
// This records a human reconciliation of evidence, never executes a transfer.
export const reconciliationSchema = z.strictObject({
  status: z.enum(["SUCCEEDED", "FAILED", "CANCELLED"]),
  evidenceReference: z.string().trim().min(3).max(200),
  note: z.string().trim().min(3).max(1000),
});
export const listSchema = z.strictObject({
  partnerId: idSchema.optional(), settlementId: idSchema.optional(),
  unsettled: z.enum(["true", "false"]).optional(),
  page: z.coerce.number().int().min(1).max(100000).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(25),
});
export const emptySchema = z.strictObject({});
