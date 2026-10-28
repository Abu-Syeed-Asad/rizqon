import { randomUUID } from "node:crypto";
import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { bearer, emailOTP, jwt } from "better-auth/plugins";

import { prisma } from "./prisma.js";
import { env } from "../config/env.js";
import { sendOtpMail } from "../services/email.service.js";
import { STATUS, SYSTEM_USER_ROLE } from "../../prisma/generated/prisma/enums.js";


export function createAuth() {
  if (!env.BETTER_AUTH_SECRET || !env.BETTER_AUTH_URL) {
    throw new Error("BETTER_AUTH_SECRET and BETTER_AUTH_URL are required for Better Auth");
  }

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
    socialProviders: env.GOOGLE_CLIENT_ID && env.GOOGLE_CLIENT_SECRET ? {
      google: {
        clientId: env.GOOGLE_CLIENT_ID,
        clientSecret: env.GOOGLE_CLIENT_SECRET,
      },
    } : {},

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
      autoSignInAfterVerification: true,
    },

    // Plugins
    plugins: [
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
      bearer(),
      emailOTP({
        overrideDefaultEmailVerification: true,

        otpLength: 6,
        expiresIn: 300, // 5 minutes
        allowedAttempts: 3,
        storeOTP: "hashed",
        disableSignUp: true,

        async sendVerificationOTP({ email, otp, type }) {
          await sendOtpMail({ to: email, otp, type });
        },
      }),
    ],

    user: {
      additionalFields: {
        user_role: {
          type: Object.values(SYSTEM_USER_ROLE),
          required: false,
          input: false,
          defaultValue: SYSTEM_USER_ROLE.RIZQON_USER,
        },
        email_verified_at: {
          type: "date",
          required: false,
          input: false,
        },
        phone_verified_at: {
          type: "date",
          required: false,
          input: false,
        },
        last_login_at: {
          type: "date",
          required: false,
          input: false,
        },
        row_version: {
          type: "number",
          required: false,
          input: false,
          defaultValue: 1,
        },

        phone: {
          type: "string",
          required: false,
          input: false,
        },
        status: {
          type: Object.values(STATUS),
          required: false,
          input: false,
          defaultValue: STATUS.ACTIVE,
        },
      },
    },
  });
}

export type Auth = ReturnType<typeof createAuth>;

export const auth = createAuth();
