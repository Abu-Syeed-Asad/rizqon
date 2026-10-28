import "dotenv/config";
import type { StringValue } from "ms";
import { z } from "zod";

const durationSchema = z
  .string()
  .regex(
    /^[1-9]\d*(ms|s|m|h|d|w|y)$/,
    "Invalid duration. Use 15m, 1d, 30d, etc.",
  )
  .transform((value) => value as StringValue);

const envSchema = z.object({
  //  Server
  NODE_ENV: z
    .enum(["development", "test", "production"])
    .default("development"),

  PORT: z.coerce.number().int().min(1).max(65535).default(5000),

  //  Database
  DATABASE_URL: z.string().min(1),
  NEON_AUTH_BASE_URL: z.string().url(),
  NEON_AUTH_JWKS_URL: z.string().url(),

  //  App URLs
  FRONTEND_ORIGIN: z.string().url(),
  BETTER_AUTH_URL: z.string().url().optional(),

  // Legacy integrations are optional; managed Neon Auth owns login and email.
  BETTER_AUTH_SECRET: z.string().min(32).optional(),

  //  Google OAuth
  GOOGLE_CLIENT_ID: z.string().min(20).optional(),
  GOOGLE_CLIENT_SECRET: z.string().min(1).optional(),

  // SMTP / Email
  SMTP_HOST: z.string().min(1).optional(),
  SMTP_PORT: z.coerce.number().int().min(1).max(65535).default(587),
  SMTP_USER: z.string().min(1).optional(),
  SMTP_PASS: z.string().min(1).optional(),
  MAIL_FROM: z.string().min(1).optional(),
  //-- JWT INFO
  JWT_EXPIRES_IN: z.string().min(1).default("15m"),
  JWT_ACCESS_TOKEN_SECRET: z.string().min(20).optional(),
  JWT_REFRESH_TOKEN_SECRET: z.string().min(20).optional(),

  JWT_REFRESH_TOKEN_EXPIRE_TIME: durationSchema.default("30d"),
  JWT_ACCESS_TOKEN_EXPIRE_TIME: durationSchema.default("15m"),
  SESSION_TOKEN_EXPIRE_TIME:durationSchema.default("7d"),
  JWT_ISSUER: z.string().min(2).optional(),
  JWT_AUDIENCE: z.string().min(1).optional(),
  JWT_ALGORITHM: z.string().min(1).optional(),
});

// ENV Element  Validate


const result = envSchema.safeParse(process.env);

if (!result.success) {
  // Report invalid/missing variable names only — never print values.
  const fields = result.error.issues
    .map((issue) => issue.path.join("."))
    .filter(Boolean)
    .join(", ");

  throw new Error(`Invalid environment configuration — fix these variables: ${fields}`);
}


// Export


export const env = result.data;

export type Env = typeof env;


