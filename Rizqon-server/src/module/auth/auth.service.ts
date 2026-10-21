import type {
  ICreateUserPayload,
} from "../../type/auth-type/auth.type.js";
import { auth } from "../../lib/auth.js";
import { prisma } from "../../lib/prisma.js";
import { AppError } from "../../errors/App.error.js";
import { StatusCodes } from "http-status-codes";
import { env } from "../../config/env.js";


const createUser = async (payload: ICreateUserPayload) => {
  if (!payload.email) {
    throw new AppError(StatusCodes.BAD_REQUEST,`The Email is undefined`)
  }

  const allUser = await prisma.user.findMany();
  console.log(allUser)
  const isExistUserIn_Db = await prisma.user.findUnique({
    where: {
      email:payload.email
    }
  })
  if (isExistUserIn_Db) {
    throw new AppError(
      StatusCodes.CONFLICT,
      ` ${payload.email}  This email is already registered. Please sign in.`,
    );
  }
  const sign_Up_User = auth.api.signUpEmail({
    body: payload,
  })
  if (!sign_Up_User) {
    throw new AppError(StatusCodes.BAD_GATEWAY,"sign up failed please try again !")
  }
  const response = {
    data: sign_Up_User,
    redirectUrl: `${env.FRONTEND_ORIGIN}/auth/verify-email`,
  };
  return response;
};



export const authService = {
  createUser,
};
