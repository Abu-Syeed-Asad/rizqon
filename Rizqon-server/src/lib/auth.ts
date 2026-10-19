import { randomUUID } from "node:crypto";
import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { emailOTP } from "better-auth/plugins";

import { prisma } from "./prisma.js";
import { env } from "../config/env.js";
import { sendOtpMail } from "../services/email.service.js";

export function createAuth() {
  return betterAuth({
    appName: "RIZQON",
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

    // ── Social providers ───────────────────────────────────────────────────
    socialProviders: {
      google: {
        clientId: env.GOOGLE_CLIENT_ID,
        clientSecret: env.GOOGLE_CLIENT_SECRET,
      },
    },

    //  Email & Password 
    emailAndPassword: {
      enabled: true,
      requireEmailVerification: true,
      minPasswordLength: 6,
      maxPasswordLength: 128,
      revokeSessionsOnPasswordReset: true,
    },

    emailVerification: {
      sendOnSignUp: true,
      autoSignInAfterVerification: false,
    },

    // Plugins 
    plugins: [
      emailOTP({
        // Replaces the built-in link-based email verification with OTP.
        overrideDefaultEmailVerification: true,

        otpLength: 6,
        expiresIn: 300,        // 5 minutes
        allowedAttempts: 3,
        storeOTP: "hashed",

        // Prevents automatic account creation via OTP sign-in;
        // users must register through email/password first.
        disableSignUp: true,

        async sendVerificationOTP({ email, otp, type }) {
          await sendOtpMail({ to: email, otp, type });
        },
      }),
    ],

    // ── User model extras ─────────────────────────────────────────────────
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
