import { randomUUID } from "node:crypto";
import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { bearer, emailOTP, jwt } from "better-auth/plugins";

import { prisma } from "./prisma.js";
import { env } from "../config/env.js";
import { sendOtpMail } from "../services/email.service.js";
import { USER_STATUS } from "../../prisma/generated/prisma/enums.js";

export function createAuth() {
  return betterAuth({
    appName: "RIZQON",
    secret: env.BETTER_AUTH_SECRET,
    baseURL: env.BETTER_AUTH_URL,
    basePath: "/api/v1/auth",

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
      minPasswordLength: 8,
      maxPasswordLength: 128,
      revokeSessionsOnPasswordReset: true,
    },

    emailVerification: {
      sendOnSignUp: true,
      // The OTP verification response creates the database session and sends
      // Better Auth's signed, HttpOnly session cookie.
      autoSignInAfterVerification: true,
    },

    // Plugins
    plugins: [
      // Short-lived, asymmetric tokens for APIs and external services.
      // Browser authentication continues to use Better Auth's secure session cookie.
      jwt({
        jwt: {
          issuer: env.BETTER_AUTH_URL,
          audience: "rizqon-api",
          expirationTime: "15m",
        },
        jwks: {
          rotationInterval: 60 * 60 * 24 * 30,
          gracePeriod: 60 * 60 * 24 * 7,
        },
      }),
      // Allows protected API routes to accept a Better Auth session token in
      // Authorization: Bearer <session-token> when cookies are unavailable.
      bearer(),
      emailOTP({
        // Replaces the built-in link-based email verification with OTP.
        overrideDefaultEmailVerification: true,

        otpLength: 6,
        expiresIn: 300, // 5 minutes
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
        email_verified_at: {
          type: "date",
          required: false,
        },
        phone_verified_at: {
          type: "date",
          required: false,
        },
        last_login_at: {
          type: "date",
          required: false,
        },
        row_version: {
          type: "number",
          required: false,
        },

        phone: {
          type: "string",
          required: false,
          input: false,
        },
        status: {
          type: "boolean",
          required: true,
          defaultValue: USER_STATUS.ACTIVE
        },
      },
    },
  });
}

export type Auth = ReturnType<typeof createAuth>;

// A single instance prevents every importing module from creating its own
// handler/plugin state.
export const auth = createAuth();
