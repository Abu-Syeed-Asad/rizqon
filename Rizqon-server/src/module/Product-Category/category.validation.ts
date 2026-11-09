import { z } from "zod";

const idSchema = z.cuid("Invalid ID: expected a CUID");
const createCategorySchema = z.object({
  businessId: idSchema,
  name: z.string().trim().min(2).max(150)
    .refine(value => [...value].every(character => character.charCodeAt(0) >= 32 && character.charCodeAt(0) !== 127), "Name cannot contain control characters"),
  category_slug: z.string().trim().min(1).max(100)
    .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Slug must contain lowercase letters, numbers or single hyphens"),
  description: z.string().trim().max(2000).nullish(),
  parentId: idSchema.nullish(),
  isActive: z.boolean().default(true),
}).strict();

const updateCategorySchema = createCategorySchema.omit({ businessId: true }).partial()
  .extend({ isActive: z.boolean().optional() })
  .refine(payload => Object.values(payload).some(value => value !== undefined), {
    message: "Provide at least one field to update",
  });

export const categoryValidation = {
  createCategorySchema,
  updateCategorySchema,
  categoryParamsSchema: z.object({ id: idSchema }).strict(),
};

export type CreateCategoryInput = z.output<typeof createCategorySchema>;
export type UpdateCategoryInput = z.output<typeof updateCategorySchema>;
export type CategoryParams = z.output<typeof categoryValidation.categoryParamsSchema>;
