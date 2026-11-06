import type { Request, Response } from "express";
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
import { cookieUtills } from "../../utils/cookie/cookieUtil";

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

export const authController = {
  createUser,
  verifyEmailWithOtp,
  sendVerificationOtp,
  signInUser,
  signOutUser
};

// #	Method	Endpoint	কাজ

// 5	POST	/sign-out	Logout
// 6	GET	/get-session	Current logged-in user ও session
// 7	POST	/email-otp/request-password-reset	Forgot password OTP পাঠানো
// 8	POST	/email-otp/reset-password	OTP দিয়ে নতুন password set
// 9	POST	/change-password	Logged-in user-এর password change
// 10	POST	/revoke-session	নির্দিষ্ট session logout
// 11	GET	/list-sessions	User-এর active sessions দেখা
// 12	POST	/revoke-other-sessions