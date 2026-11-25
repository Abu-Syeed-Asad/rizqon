import { z } from "zod";

export const providerSchema = z.enum(["STRIPE", "SSLCOMMERZ"]);
export type Provider = z.infer<typeof providerSchema>;
export const checkoutSchema = z.object({
  provider: providerSchema,
  idempotencyKey: z.string().trim().min(8).max(100),
  customer: z.object({
    name: z.string().trim().min(1).max(50),
    email: z.email().max(50),
    phone: z.string().trim().min(5).max(20),
    address: z.string().trim().min(1).max(50),
    city: z.string().trim().min(1).max(50),
    postcode: z.string().trim().min(1).max(30),
    country: z.string().trim().min(2).max(50),
  }).strict(),
}).strict();
export type CheckoutInput = z.infer<typeof checkoutSchema>;

export const sslNotificationSchema = z.object({
  tran_id: z.string().min(1).max(30),
  val_id: z.string().min(1).max(100).optional(),
});
