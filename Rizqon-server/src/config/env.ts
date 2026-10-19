import "dotenv/config";
import { z } from "zod";


const envSchema = z.object({
  // ── Server ────────────────────────────────────────────────────────────────
  NODE_ENV: z
    .enum(["development", "test", "production"])
    .default("development"),

  PORT: z.coerce.number().int().min(1).max(65535).default(5000),

  // ── Database ──────────────────────────────────────────────────────────────
  DATABASE_URL: z.string().min(1),

  // ── App URLs ──────────────────────────────────────────────────────────────
  FRONTEND_ORIGIN: z.string().url(),
  BETTER_AUTH_URL: z.string().url(),

  // ── Better Auth ───────────────────────────────────────────────────────────
  BETTER_AUTH_SECRET: z.string().min(32),

  // ── Google OAuth ─────────────────────────────────────────────────────────
  GOOGLE_CLIENT_ID: z.string().min(20),
  GOOGLE_CLIENT_SECRET: z.string().min(1),

  // ── SMTP / Email ──────────────────────────────────────────────────────────
  SMTP_HOST: z.string().min(1),
  SMTP_PORT: z.coerce.number().int().min(1).max(65535),
  SMTP_USER: z.string().min(1),
  SMTP_PASS: z.string().min(1),
  MAIL_FROM: z.string().min(1),
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


