import { z } from "zod";
import { idempotencySchema, idSchema, quantitySchema } from "../Commission/commission.validation.js";

export const createReturnSchema = z.strictObject({
  saleId: idSchema, idempotencyKey: idempotencySchema, reason: z.string().trim().min(3).max(1000),
  items: z.array(z.strictObject({ saleItemId: idSchema, quantity: quantitySchema, restock: z.boolean().default(true) }))
    .min(1).max(500).refine(items => new Set(items.map(i => i.saleItemId)).size === items.length, "Duplicate sale items"),
});
