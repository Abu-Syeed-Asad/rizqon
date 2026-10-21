import type { Request, Response } from "express";
import { catchAsync } from "../../utils/asyncHandler.js";
import type {
  ICreateUserPayload,
} from "../../type/auth-type/auth.type.js";
import { authService } from "./auth.service.js";


const createUser = catchAsync(async (req: Request, res: Response) => {
  const payload: ICreateUserPayload = req.body;
  const response = await authService.createUser(payload)
  res.send(response)
});


export const authController = {
  createUser,
 
};
