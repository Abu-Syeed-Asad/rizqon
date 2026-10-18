import { randomUUID } from "node:crypto";
import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";

import { prisma } from "./prisma";

type MailSender = (mail: {
  to: string;
  subject: string;
  text: string;
}) => Promise<void>;

export function createAuth(sendMail: MailSender) {
  const secret = process.env.BETTER_AUTH_SECRET;
  const baseURL = process.env.BETTER_AUTH_URL;
  const frontendOrigin = process.env.FRONTEND_ORIGIN;

  if (!secret || !baseURL || !frontendOrigin) {
    throw new Error(
      "Set BETTER_AUTH_SECRET, BETTER_AUTH_URL, and FRONTEND_ORIGIN",
    );
  }

  return betterAuth({
    secret,
    baseURL,
    trustedOrigins: [frontendOrigin],
    database: prismaAdapter(prisma, { provider: "postgresql" }),
    advanced: {
      database: { generateId: () => randomUUID() },
    },
    emailAndPassword: {
      enabled: true,
      requireEmailVerification: true,
      sendResetPassword: async ({ user, url }) => {
        await sendMail({
          to: user.email,
          subject: "Reset your password",
          text: `Open this link to reset your password: ${url}`,
        });
      },
    },
    emailVerification: {
      sendOnSignUp: true,
      sendVerificationEmail: async ({ user, url }) => {
        await sendMail({
          to: user.email,
          subject: "Verify your email",
          text: `Open this link to verify your email: ${url}`,
        });
      },
    },
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
