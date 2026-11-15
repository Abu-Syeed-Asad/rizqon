import { z } from "zod";
import { PARTNER_KIND } from "../../../prisma/generated/prisma/enums.js";

const idSchema = z.cuid("Invalid ID: expected a CUID");
const partnerFieldsSchema = z.object({
  name: z.string().trim().min(2).max(150),
  phone: z.string().trim().regex(/^\+?[0-9]{7,15}$/, "Invalid phone number"),
  email: z.string().trim().toLowerCase().max(254).pipe(z.email()),
  address: z.string().trim().min(1).max(500),
  kind: z.enum(PARTNER_KIND),
  linkedBusinessId: idSchema.nullable().optional(),
}).strict();

export const partnerValidation = {
  createPartnerSchema: partnerFieldsSchema.extend({ businessId: idSchema }),
  updatePartnerSchema: partnerFieldsSchema.partial().refine(
    (data) => Object.values(data).some((value) => value !== undefined),
    { message: "Provide at least one field to update" },
  ),
  partnerParamsSchema: z.object({ id: idSchema }).strict(),
};

export type CreatePartnerInput = z.output<typeof partnerValidation.createPartnerSchema>;
export type UpdatePartnerInput = z.output<typeof partnerValidation.updatePartnerSchema>;
export type PartnerParams = z.output<typeof partnerValidation.partnerParamsSchema>;
