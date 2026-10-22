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
  const response = await authService.verifyEmailWithOtp(payload);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Successfully Email Verified",
    data: response,
  });
});

export const authController = {
  createUser,
  verifyEmailWithOtp,
};
