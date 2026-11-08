import { z } from "zod";

const optionalText = (maxLength: number) =>
  z.string().trim().max(maxLength).nullish();

 const createBusinessSchema = z
  .object({
    name: z
      .string()
      .trim()
      .min(2, "Business name must contain at least 2 characters")
      .max(150, "Business name is too long"),

    business_slug: z
      .string()
      .trim()
      .min(3, "Business slug must contain at least 3 characters")
      .max(80, "Business slug is too long")
      .regex(
        /^[a-z0-9]+(?:-[a-z0-9]+)*$/,
        "Slug must contain lowercase letters, numbers or hyphens",
      ),

    legalName: optionalText(200),

    registrationNumber: optionalText(100),

    taxIdentificationNumber: optionalText(100),

    phone: z
      .string()
      .trim()
      .regex(/^\+?[0-9]{7,15}$/, "Invalid phone number")
      .nullish(),

    email: z
      .email("Invalid business email")
      .trim()
      .toLowerCase()
      .max(254)
      .nullish(),

    address: optionalText(500),

    currency: z.enum(["BDT", "USD", "EUR"]).default("BDT"),
  })
  .strict();


const updateBusinessSchema = createBusinessSchema
  .partial()
  .extend({ currency: z.enum(["BDT", "USD", "EUR"]).optional() })
  .refine((payload) => Object.values(payload).some((value) => value !== undefined), {
    message: "Provide at least one field to update",
  });

const businessIdSchema = z.string().trim().min(1, "Business id is required");
const businessParamsSchema = z.object({ id: businessIdSchema });
const searchBusinessSchema = z.object({
  searchTerm: z.string().trim().min(1, "Enter a business search term").max(254),
}).strict();


export const bussinessValidation = {
  createBusinessSchema,
  updateBusinessSchema,
  businessIdSchema,
  businessParamsSchema,
  searchBusinessSchema,
}
export type ISearchBusiness = z.output<typeof searchBusinessSchema>;
export type IUpdateBusiness = z.output<typeof updateBusinessSchema>;
export type ICreateBusiness = z.output<typeof createBusinessSchema>;
