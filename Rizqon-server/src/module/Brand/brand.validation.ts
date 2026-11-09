import { z } from "zod";

const idSchema = z.cuid("Invalid ID: expected a CUID");
const brandNameSchema = z.string().trim().min(2).max(150)
  .refine(value => [...value].every(character => character.charCodeAt(0) >= 32 && character.charCodeAt(0) !== 127),
    "Brand name cannot contain control characters");

export const brandValidation = {
  createBrandSchema: z.object({ businessId: idSchema, brand_name: brandNameSchema }).strict(),
  updateBrandSchema: z.object({ brand_name: brandNameSchema }).strict(),
  brandParamsSchema: z.object({ id: idSchema }).strict(),
};

export type CreateBrandInput = z.output<typeof brandValidation.createBrandSchema>;
export type UpdateBrandInput = z.output<typeof brandValidation.updateBrandSchema>;
export type BrandParams = z.output<typeof brandValidation.brandParamsSchema>;

