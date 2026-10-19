import "dotenv/config";
import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z
    .enum(["development", "test", "production"])
    .default("development"),

  PORT: z.coerce.number().int().min(1).max(65535).default(5000),

  DATABASE_URL: z.string().min(1),

  FRONTEND_ORIGIN: z.url(),

  BETTER_AUTH_URL: z.url(),
  BETTER_AUTH_SECRET: z.string().min(32),
  GOOGLE_CLIENT_ID: z.string().min(20),
  GOOGLE_CLIENT_SECRET: z.string(),
  SMTP_MAIL: {
      
    SMTP_HOST: z.string().min(1),
    SMTP_PORT: z.coerce.number().int().min(1).max(65535),
    SMTP_USER: z.string().min(1),
    SMTP_PASS: z.string().min(1),
    MAIL_FROM: z.string().min(1),
  }

  
});

const result = envSchema.safeParse(process.env);

if (!result.success) {
  // Report invalid variable names without printing their values.
  const fields = result.error.issues
    .map((issue) => issue.path.join("."))
    .join(", ");

  throw new Error(`Invalid environment configuration: ${fields}`);
}

export const env = result.data;
