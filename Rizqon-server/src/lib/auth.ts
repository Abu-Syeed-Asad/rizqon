import "dotenv/config";

import { randomUUID } from "node:crypto";
import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { emailOTP } from "better-auth/plugins";
import { z } from "zod";

import { prisma } from "./prisma.js";
import { env } from "../config/env.js";

export type MailSender = (mail: {
  to: string;
  subject: string;
  text: string;
}) => Promise<void>;

const authEnvSchema = z.object({
  BETTER_AUTH_SECRET:env.BETTER_AUTH_SECRET ,
  BETTER_AUTH_URL: env.BETTER_AUTH_URL,
  FRONTEND_ORIGIN: env.FRONTEND_ORIGIN,
  GOOGLE_CLIENT_ID: env.
  GOOGLE_CLIENT_SECRET: z.string().min(1),
});

export function createAuth() {
  const result = authEnvSchema.safeParse(process.env);

  if (!result.success) {
    const invalidFields = [
      ...new Set(result.error.issues.map((issue) => issue.path.join("."))),
    ];

    throw new Error(
      `Invalid authentication configuration: ${invalidFields.join(", ")}`,
    );
  }

  const env = result.data;

  return betterAuth({
    appName: "Product App",

    secret: env.BETTER_AUTH_SECRET,
    baseURL: env.BETTER_AUTH_URL,
    basePath: "/api/auth",

    trustedOrigins: [env.FRONTEND_ORIGIN],

    database: prismaAdapter(prisma, {
      provider: "postgresql",
    }),

    advanced: {
      database: {
        generateId: () => randomUUID(),
      },
    },

    socialProviders: {
      google: {
        clientId: env.GOOGLE_CLIENT_ID,
        clientSecret: env.GOOGLE_CLIENT_SECRET,
      },
    },

    emailAndPassword: {
      enabled: true,
      requireEmailVerification: true,

      minPasswordLength: 12,
      maxPasswordLength: 128,

      revokeSessionsOnPasswordReset: true,

      // Password reset emails are handled by the OTP plugin.
    },

    emailVerification: {
      sendOnSignUp: true,
      autoSignInAfterVerification: false,

      // The OTP plugin replaces verification links.
    },

    plugins: [
      emailOTP({
        overrideDefaultEmailVerification: true,

        otpLength: 6,
        expiresIn: 300,
        allowedAttempts: 3,
        storeOTP: "hashed",

        // Email/password registration remains available.
        // This prevents automatic registration through OTP sign-in.
        disableSignUp: true,

        async sendVerificationOTP({ email, otp, type }) {
          const subject =
            type === "email-verification"
              ? "Verify your email"
              : type === "forget-password"
                ? "Reset your password"
                : "Your sign-in code";

          await ({
            to: email,
            subject,
            text: [
              `Your verification code is: ${otp}`,
              "",
              "This code expires in 5 minutes.",
              "Do not share this code with anyone.",
              "If you did not request this code, ignore this email.",
            ].join("\n"),
          });
        },
      }),
    ],

    user: {
      additionalFields: {
        status: {
          type: "string",
          required: false,
          defaultValue: "ACTIVE",
          input: false,
        },
      },
    },
  });
}

export type Auth = ReturnType<typeof createAuth>;
