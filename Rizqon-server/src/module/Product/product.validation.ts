import { z } from "zod";

const id = z.cuid("Invalid ID: expected a CUID");
const businessSchema = z.object({ businessId: id }).strict();
const fields = z.object({
  name: z.string().trim().min(2).max(150),
  slug: z.string().trim().min(1).max(150).regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/),
  description: z.string().trim().max(5000).nullable().optional(),
  unit: z.string().trim().min(1).max(50),
  price: z.union([z.string(), z.number().finite().nonnegative()])
    .transform(String).pipe(z.string().regex(/^(0|[1-9]\d{0,15})(\.\d{1,2})?$/, "Price must be nonnegative with up to 16 integer digits and 2 decimal places")),
  categoryId: id,
  brandId: id.nullable().optional(),
  isActive: z.boolean().optional(),
}).strict();

export const productValidation = {
  deleteProductSchema: businessSchema,
  productParamsSchema: z.object({ id }).strict(),
  branchParamsSchema: z.object({ branchId: id }).strict(),
  mutationParamsSchema: z.object({ branchId: id, id }).strict(),
  createProductSchema: fields.extend({ businessId: id, unit: fields.shape.unit.default("piece") }),
  updateProductSchema: fields.partial().extend({ businessId: id }).refine(
    (data) => Object.entries(data).some(([key, value]) => key !== "businessId" && value !== undefined),
    { message: "Provide at least one field to update" },
  ),
};
export type DeleteProductInput = z.output<typeof businessSchema>;
export type ProductParams = z.output<typeof productValidation.productParamsSchema>;
export type BranchParams = z.output<typeof productValidation.branchParamsSchema>;
export type ProductMutationParams = z.output<typeof productValidation.mutationParamsSchema>;
export type CreateProductInput = z.output<typeof productValidation.createProductSchema>;
export type UpdateProductInput = z.output<typeof productValidation.updateProductSchema>;
