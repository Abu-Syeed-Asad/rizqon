import type {
  ICreateUserPayload,
  IverifyEmailOtp,
} from "../../type/auth-type/auth.type.js";
import { auth } from "../../lib/auth.js";
import { prisma } from "../../lib/prisma.js";
import { AppError } from "../../errors/App.error.js";
import { StatusCodes } from "http-status-codes";
import { env } from "../../config/env.js";

const createUser = async (payload: ICreateUserPayload) => {
  if (!payload.email) {
    throw new AppError(StatusCodes.BAD_REQUEST, `The Email is undefined`);
  }
  const email = payload.email.trim().toLowerCase();

  const isExistUserIn_Db = await prisma.user.findUnique({
    where: {
      email,
    },
  });
  if (isExistUserIn_Db) {
    throw new AppError(
      StatusCodes.CONFLICT,
      ` ${payload.email}  This email is already registered. Please sign in.`,
    );
  }
  const sign_Up_User = await auth.api.signUpEmail({
    body: payload,
  });
  if (!sign_Up_User) {
    throw new AppError(
      StatusCodes.BAD_GATEWAY,
      "sign up failed please try again !",
    );
  }
  const response = {
    data: sign_Up_User,
    redirectUrl: `${env.FRONTEND_ORIGIN}/auth/verify-email`,
  };
  return response;
};

const verifyEmailWithOtp = async (payload: IverifyEmailOtp) => {
  const email = payload.email.trim().toLowerCase();

  const existingUser = await prisma.user.findUnique({
    where: { email },
    select: {
      id: true,
      emailVerified: true,
    },
  });

  if (!existingUser) {
    throw new AppError(
      StatusCodes.NOT_FOUND,
      "Account not found. Please sign up first.",
    );
  }

  if (existingUser.emailVerified) {
    throw new AppError(
      StatusCodes.BAD_GATEWAY,
      "Email is already verified. Please sign in.",
    );
  }
  const result = await auth.api.verifyEmailOTP({
    body: {
      email,
      otp: payload.otp,
    },
  });

  if (!result.status) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Email verification failed.");
  }

  return result;
};

export const authService = {
  createUser,
  verifyEmailWithOtp,
};
