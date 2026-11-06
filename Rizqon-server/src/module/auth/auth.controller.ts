import type { Request, Response } from "express";
import { fromNodeHeaders } from "better-auth/node";
import { authHeaders } from "../../utils/authHeaders.js";
import { cookieUtills } from "../../utils/cookie/cookieUtil.js";
import {
  catchAsync,
  send_Response,
} from "../../utils/asyncHandlerOrsendResponse";
import type {
  ICreateUserPayload,
  IVerifyEmailPayload,
} from "../../type/auth-type/auth.type";
import { authService } from "./auth.service";
import { StatusCodes } from "http-status-codes";
import { AppError } from "../../errors/App.error";
const createUser = catchAsync(async (req: Request, res: Response) => {
  const payload: ICreateUserPayload = req.body;
  const response = await authService.createUser(payload);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Successfully user created please verify your email to login ",
    data: response,
  });
});
const verifyEmailWithOtp = catchAsync(async (req: Request, res: Response) => {
  const payload: IVerifyEmailPayload = req.body;
  const response = await authService.verifyEmailWithOtp(payload,res);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Successfully Email Verified",
    data: response,
  });
});
const sendVerificationOtp = catchAsync(async (req: Request, res: Response) => {
  const email = req.body?.email;
  const response = await authService.sendVerificationOtpInEmail(email);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Verification OTP sent. Please check your email.",
    data: response,
  });
});
const signInUser = catchAsync(async (req: Request, res: Response) => {
  const payload = req.body;
  const response = await authService.signInUser(payload,res);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "you are signin successfully ",
    data:response
  })
})
const signOutUser = catchAsync(async (req: Request, res: Response) => { 
  const response = await authService.signOutUser(res);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "you are signout successfully ",
    data:response
  })  
})
const getSessionUser = catchAsync(async (req: Request, res: Response) => {
  const response = await authService.getSessionUser(authHeaders(req));
  res.setHeader("Cache-Control", "no-store");
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Session user retrieved successfully",
    data: response
  });
});
const resetPasswordWithOtp = catchAsync(async (req: Request, res: Response) => {
  const { email, otp, newPassword } = req.body;
  const response = await authService.resetPasswordWithOtp(email, otp, newPassword); 
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Password reset successfully. Please sign in with your new password.",
    data: response,
  });
});
const forgotPassword = catchAsync(async (req: Request, res: Response) => {
  const { email } = req.body;
  const response = await authService.forgotPassword(email); 
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "OTP sent successfully. Please check your email.",
    data: response,
  });
}); 
const changePassword = catchAsync(async (req: Request, res: Response) => {

  const { currentPassword, newPassword } = req.body ?? {};
  if (typeof currentPassword !== "string" || !currentPassword ||
      typeof newPassword !== "string" || !newPassword) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Current password and new password are required.");
  } 
  const headers = fromNodeHeaders(req.headers);
  const sessionToken = cookieUtills.getCookie(req, "sessionToken");
  if (!headers.has("authorization") && sessionToken) {
    headers.set("authorization", `Bearer ${sessionToken}`);
  }
  const response = await authService.changePassword(res,headers, currentPassword, newPassword);
  if (response.token) {
    cookieUtills.setSessionCookie(res, response.token);
  }
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Password changed successfully.",
    data: response,
  });
}); 
const signInWithGoogleAccount = catchAsync(
  async (req: Request, res: Response) => {
    const result = await authService.signInWithGoogleAccount(
      fromNodeHeaders(req.headers),
    );

    for (const cookie of result.cookies) {
      res.append("Set-Cookie", cookie);
    }
    res.setHeader("Cache-Control", "no-store");
    res.redirect(303, result.url);
  },
);

const completeGoogleSignIn = catchAsync(async (req: Request, res: Response) => {
  const result = await authService.completeGoogleSignIn(
    authHeaders(req),
    res,
    
  );

  for (const cookie of result.cookies) {
    res.append("Set-Cookie", cookie);
  }

  cookieUtills.setSessionCookie(res, result.sessionToken);

  res.setHeader("Cache-Control", "no-store");

  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Google sign-in completed successfully.",
    data: result.user,
  });
});

const googleSignInError = (_req: Request, res: Response) => {
  res.status(StatusCodes.BAD_REQUEST).json({
    success: false,
    message: "Google sign-in could not be completed. Please try again.",
  });
};




export const authController = {
  createUser,
  verifyEmailWithOtp,
  sendVerificationOtp,
  signInUser,
  signOutUser,
  getSessionUser,
  resetPasswordWithOtp,
  forgotPassword, 
  changePassword,
  signInWithGoogleAccount,
  completeGoogleSignIn,
  googleSignInError,  
};

// #	Method	Endpoint	কাজ

// 10	POST	/revoke-session	নির্দিষ্ট session logout
// 11	GET	/list-sessions	User-এর active sessions দেখা
// 12	POST	/revoke-other-sessions
