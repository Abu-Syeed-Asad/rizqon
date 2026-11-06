import type {
  ICreateUserPayload,
  ISignInPayload,
  IVerifyEmailPayload,
} from "../../type/auth-type/auth.type.js";
import { auth } from "../../lib/auth.js";
import { prisma } from "../../lib/prisma.js";
import { AppError } from "../../errors/App.error.js";
import { StatusCodes } from "http-status-codes";
import { env } from "../../config/env.js";
import { STATUS } from "../../../prisma/generated/prisma/enums.js";
import { tokenUtilitis } from "../../utils/token/tokenUtilitis.js";
import type { ITokenPayload } from "../../type/token_Type/token_payload_Type.js";
import { cookieUtills } from "../../utils/cookie/cookieUtil.js";
import type { Response } from "express";

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
const verifyEmailWithOtp = async (
  payload: IVerifyEmailPayload,
  res: Response,
) => {
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
  const user = await auth.api.verifyEmailOTP({
    body: {
      email,
      otp: payload.otp,
    },
  });

  if (!user.user.emailVerified) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Email verification failed.");
  }
  const tokenPayload: ITokenPayload = {
    name: user?.user?.name,
    email: user?.user?.email,
    id: user?.user?.id,
    role: user?.user?.user_role as string,
    emailVerified: user?.user?.emailVerified,
    createdAt: user?.user?.createdAt.toISOString(),
    updatedAt: user?.user?.updatedAt.toISOString(),
    phone: user?.user?.phone as string,
  };
  const accessToken = tokenUtilitis.createToken(
    tokenPayload,
    env.JWT_ACCESS_TOKEN_SECRET as string,
    env.JWT_ACCESS_TOKEN_EXPIRE_TIME,
  );
  const refreshToken = tokenUtilitis.createToken(
    tokenPayload,
    env.JWT_REFRESH_TOKEN_SECRET as string,
    env.JWT_REFRESH_TOKEN_EXPIRE_TIME,
  );
  // set token in cookie
  const sessionToken = user?.token as string;
  cookieUtills.setAuthCookies(res, accessToken, refreshToken, sessionToken);

  return {
    accessToken,
    refreshToken,
    user,
  };
};
const sendVerificationOtpInEmail = async (email: unknown) => {
  if (typeof email !== "string" || !email.trim()) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Email is required.");
  }

  return auth.api.sendVerificationOTP({
    body: {
      email: email.trim().toLowerCase(),
      type: "email-verification",
    },
  });
};
const signInUser = async (payload: ISignInPayload, res: Response) => {
  if (!payload.email) {
    throw new AppError(StatusCodes.BAD_REQUEST, `The Email is undefined`);
  }
  const email = payload.email.trim().toLowerCase();
  const isExistUserIn_Db = await prisma.user.findUnique({
    where: {
      email,
    },
  });
  if (!isExistUserIn_Db) {
    throw new AppError(
      StatusCodes.NOT_FOUND,
      "Your Email and Password NOt Found In Data-Base please signup again",
    );
  }
  if (!isExistUserIn_Db.emailVerified) {
    throw new AppError(
      StatusCodes.BAD_REQUEST,
      "your account not verified please verify your account",
    );
  }
  if (isExistUserIn_Db.status === STATUS.DELETED) {
    throw new AppError(StatusCodes.FORBIDDEN, "Your account is deleted ");
  }
  const user = await auth.api.signInEmail({
    body: payload,
  });
  if (!user) {
    throw new AppError(StatusCodes.INTERNAL_SERVER_ERROR, "server error");
  }

  const tokenPayload: ITokenPayload = {
    name: user?.user?.name,
    email: user?.user?.email,
    id: user?.user?.id,
    role: user?.user?.user_role as string,
    emailVerified: user?.user?.emailVerified,
    createdAt: user?.user?.createdAt.toISOString(),
    updatedAt: user?.user?.updatedAt.toISOString(),
    phone: user?.user?.phone as string,
  };
  const accessToken = tokenUtilitis.createToken(
    tokenPayload,
    env.JWT_ACCESS_TOKEN_SECRET as string,
    env.JWT_ACCESS_TOKEN_EXPIRE_TIME,
  );
  const refreshToken = tokenUtilitis.createToken(
    tokenPayload,
    env.JWT_REFRESH_TOKEN_SECRET as string,
    env.JWT_REFRESH_TOKEN_EXPIRE_TIME,
  );
  // set token in cookie
  const sessionToken = user?.token;
  cookieUtills.setAuthCookies(res, accessToken, refreshToken, sessionToken);

  return {
    accessToken,
    refreshToken,
    user,
  };
};
const signOutUser = async (res: Response) => {
  const signOutUser = await auth.api.signOut({
    headers: {
      Authorization: `Bearer ${res.locals.sessionToken}`,
    },
  });
  if (!signOutUser) {
    throw new AppError(
      StatusCodes.INTERNAL_SERVER_ERROR,
      "sign out failed please try again",
    );
  }
  cookieUtills.clearAuthCookies(res);
  return {
    redirectUrl: `${env.FRONTEND_ORIGIN}/auth/signin`,
  };
};
const getSessionUser = async (headers: Headers) => {
  const sessionUser = await auth.api.getSession({
    headers,
  });
  if (!sessionUser) {
    throw new AppError(
      StatusCodes.UNAUTHORIZED,
      "Session expired. Please sign in again.",
    );
  }
  return {
    session: sessionUser,
  };
};
const forgotPassword = async (email: string) => {
  if (!email) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Email is required.");
  }
  const user = await prisma.user.findUnique({
    where: { email: email.trim().toLowerCase() },
  });
  if (!user) {
    throw new AppError(
      StatusCodes.NOT_FOUND,
      "Account not found. Please sign up first.",
    );
  }
  if (!user.emailVerified) {
    throw new AppError(
      StatusCodes.BAD_REQUEST,
      "Email is not verified. Please verify your email first.",
    );
  }
  if (user.status === STATUS.DELETED) {
    throw new AppError(
      StatusCodes.FORBIDDEN,
      "Your account is deleted. Please contact support.",
    );
  }
  const forgotPasswordOtp = await auth.api.sendVerificationOTP({
    body: {
      email: email.trim().toLowerCase(),
      type: "forget-password",
    },
  });
  if (!forgotPasswordOtp) {
    throw new AppError(
      StatusCodes.INTERNAL_SERVER_ERROR,
      "Failed to send OTP. Please try again.",
    );
  }
  return {
    message: "OTP sent successfully. Please check your email.",
    redirectUrl: `${env.FRONTEND_ORIGIN}/auth/reset-password`,
    email: email.trim().toLowerCase(),
  };
};
const resetPasswordWithOtp = async (
  email: string,
  otp: string,
  newPassword: string,
) => {
  if (!email || !otp || !newPassword) {
    throw new AppError(
      StatusCodes.BAD_REQUEST,
      "Email, OTP, and new password are required.",
    );
  }
  const user = await prisma.user.findUnique({
    where: { email: email.trim().toLowerCase() },
  });
  if (!user) {
    throw new AppError(
      StatusCodes.NOT_FOUND,
      "Account not found. Please sign up first.",
    );
  }
  if (!user.emailVerified) {
    throw new AppError(
      StatusCodes.BAD_REQUEST,
      "Email is not verified. Please verify your email first.",
    );
  }
  if (user.status === STATUS.DELETED) {
    throw new AppError(
      StatusCodes.FORBIDDEN,
      "Your account is deleted. Please contact support.",
    );
  }
  const resetPasswordResponse = await auth.api.resetPasswordEmailOTP({
    body: {
      email: email.trim().toLowerCase(),
      otp,
      password: newPassword,
    },
  });
  if (!resetPasswordResponse) {
    throw new AppError(
      StatusCodes.INTERNAL_SERVER_ERROR,
      "Failed to reset password. Please try again.",
    );
  }
  return {
    message:
      "Password reset successfully. Please sign in with your new password.",
    redirectUrl: `${env.FRONTEND_ORIGIN}/auth/signin`,
  };
};
const changePassword = async (
  res: Response,
  headers: Headers,
  oldPassword: string,
  newPassword: string,
) => {
  if (!oldPassword || !newPassword) {
    throw new AppError(
      StatusCodes.BAD_REQUEST,
      "Current password and new password are required.",
    );
  }
  const session = await auth.api.getSession({ headers });
  if (!session) {
    throw new AppError(
      StatusCodes.UNAUTHORIZED,
      "Session expired. Please sign in again.",
    );
  }
  const user = await prisma.user.findUnique({
    where: { id: session.user.id },
  });
  if (!user) {
    throw new AppError(
      StatusCodes.NOT_FOUND,
      "Account not found. Please sign in first.",
    );
  }
  if (!user.emailVerified) {
    throw new AppError(
      StatusCodes.BAD_REQUEST,
      "Email is not verified. Please verify your email first.",
    );
  }
  if (user.status === STATUS.DELETED) {
    throw new AppError(
      StatusCodes.FORBIDDEN,
      "Your account is deleted. Please contact support.",
    );
  }
  const changePasswordResponse = await auth.api.changePassword({
    headers,
    body: {
      currentPassword: oldPassword,
      newPassword: newPassword,
      revokeOtherSessions: true,
    },
  });
  if (!changePasswordResponse) {
    throw new AppError(
      StatusCodes.INTERNAL_SERVER_ERROR,
      "Failed to change password. Please try again.",
    );
  }

  const tokenPayload: ITokenPayload = {
    name: user?.name,
    email: user?.email,
    id: user?.id,
    role: user?.user_role as string,
    emailVerified: user?.emailVerified,
    createdAt: user?.createdAt.toISOString(),
    updatedAt: user?.updatedAt.toISOString(),
    phone: user?.phone as string,
  };
  const accessToken = tokenUtilitis.createToken(
    tokenPayload,
    env.JWT_ACCESS_TOKEN_SECRET as string,
    env.JWT_ACCESS_TOKEN_EXPIRE_TIME,
  );
  const refreshToken = tokenUtilitis.createToken(
    tokenPayload,
    env.JWT_REFRESH_TOKEN_SECRET as string,
    env.JWT_REFRESH_TOKEN_EXPIRE_TIME,
  );
  const sessionToken = changePasswordResponse?.token as string;
  cookieUtills.setAuthCookies(res,
    accessToken,
    refreshToken,
    sessionToken,
  );

  return {
    message: "Password changed successfully.",
    token: changePasswordResponse.token,
  };
};

const signInWithGoogleAccount = async (headers: Headers) => {
  if (!env.GOOGLE_CLIENT_ID || !env.GOOGLE_CLIENT_SECRET || !env.BETTER_AUTH_URL) {
    throw new AppError(StatusCodes.SERVICE_UNAVAILABLE, "Google sign-in is not configured.");
  }
  const { response, headers: responseHeaders } =
    await auth.api.signInSocial({
      headers,
      body: {
        provider: "google",

        callbackURL:
          new URL("/api/v1/auth/complete-google-sign-in", env.BETTER_AUTH_URL).href,

        errorCallbackURL:
          new URL("/api/v1/auth/google-sign-in-error", env.BETTER_AUTH_URL).href,
      },
      returnHeaders: true,
    });

  if (!response.url) {
    throw new AppError(
      StatusCodes.INTERNAL_SERVER_ERROR,
      "Failed to start Google sign-in.",
    );
  }

  return {
    url: response.url,
    cookies: responseHeaders.getSetCookie(),
  };
};

const completeGoogleSignIn = async (headers: Headers, res: Response) => {
  const { response: session, headers: responseHeaders } =
    await auth.api.getSession({
      headers,
      returnHeaders: true,
    });

  if (!session) {
    throw new AppError(
      StatusCodes.UNAUTHORIZED,
      "Google sign-in failed or the session has expired.",
    );
  }
  const user = await prisma.user.findUnique({
    where: {
      id: session.user.id,
    },
    select: {
      id: true,
      name: true,
      email: true,
      emailVerified: true,
      status: true,
      user_role: true,
      phone: true,
    },
  });
 

  if (!user) {
    throw new AppError(
      StatusCodes.NOT_FOUND,
      "User account not found.",
    );
  }

  if (user.status === STATUS.DELETED) {
    throw new AppError(
      StatusCodes.FORBIDDEN,
      "Your account is deleted. Please contact support.",
    );
  }

 if (!user.emailVerified) {
    throw new AppError(
      StatusCodes.BAD_REQUEST,
      "Email is not verified. Please verify your email first.",
    );
  } 
  const tokenPayload: ITokenPayload = {
    name: user?.name,
    email: user?.email,
    id: user?.id,
    role: session.user.user_role as string,
    emailVerified: user?.emailVerified,
    createdAt: session.user.createdAt.toISOString(),
    updatedAt: session.user.updatedAt.toISOString(),
    phone: session.user.phone as string,
  };
  const accessToken = tokenUtilitis.createToken(
    tokenPayload,
    env.JWT_ACCESS_TOKEN_SECRET as string,
    env.JWT_ACCESS_TOKEN_EXPIRE_TIME,
  );
  const refreshToken = tokenUtilitis.createToken(
    tokenPayload,
    env.JWT_REFRESH_TOKEN_SECRET as string,
    env.JWT_REFRESH_TOKEN_EXPIRE_TIME,
  );
  cookieUtills.setAuthCookies(
    res,
    accessToken,
    refreshToken,
    session.session.token,
  );  

  return {
    user,
    sessionToken: session.session.token,
    cookies: responseHeaders.getSetCookie(),
  };
};

export const authService = {
  createUser,
  verifyEmailWithOtp,
  sendVerificationOtpInEmail,
  signInUser,
  signOutUser,
  getSessionUser,
  resetPasswordWithOtp,
  forgotPassword,
  changePassword,
  signInWithGoogleAccount,
  completeGoogleSignIn,
};
