import { z } from "zod";

const idSchema = z.cuid("Invalid ID: expected a CUID");
const textSchema = (max: number) => z.string().trim().min(1).max(max)
  .refine(value => [...value].every(character => character.charCodeAt(0) >= 32 && character.charCodeAt(0) !== 127),
    "Text cannot contain control characters");

const createBranchSchema = z.object({
  businessId: idSchema,
  name: textSchema(150).min(2),
  branch_code: z.string().trim().min(1).max(50)
    .regex(/^[A-Za-z0-9]+(?:[-_][A-Za-z0-9]+)*$/, "Branch code must contain letters, numbers, hyphens or underscores"),
  address: textSchema(500).nullish(),
  phone: z.string().trim().regex(/^\+?[0-9]{7,15}$/, "Invalid phone number").nullish(),
  isActive: z.boolean().default(true),
}).strict();

const updateBranchSchema = createBranchSchema.omit({ businessId: true }).partial()
  .extend({ isActive: z.boolean().optional() })
  .refine(payload => Object.values(payload).some(value => value !== undefined), {
    message: "Provide at least one field to update",
  });

export const branchValidation = {
  createBranchSchema,
  updateBranchSchema,
  branchParamsSchema: z.object({ id: idSchema }).strict(),
};

export type CreateBranchInput = z.output<typeof createBranchSchema>;
export type UpdateBranchInput = z.output<typeof updateBranchSchema>;
export type BranchParams = z.output<typeof branchValidation.branchParamsSchema>;
