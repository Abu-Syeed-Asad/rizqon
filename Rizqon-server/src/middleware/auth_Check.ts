import jwt from "jsonwebtoken"
import type { NextFunction, Request, Response } from "express";
import { env } from "../config/env";
import { AppError } from "../errors/App.error";
import { StatusCodes } from "http-status-codes";
import type { ITokenPayload } from "../type/token_Type/token_payload_Type";
import { prisma } from "../lib/prisma";

const auth_Checker = (...allowedRoles: string[]) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authorizationHeader = req.headers.authorization;
      if (!authorizationHeader) {
        return res.status(401).json({
          success: false,
          message: "Authorization header missing"
        });
      }
      const token = /^Bearer ([^\s]+)$/i.exec(authorizationHeader)?.[1];
      if (!token) {
        return res.status(401).json({
          success: false,
          message: "A Bearer access token is required"
        });
      }
      const decod = jwt.verify(token, env.JWT_ACCESS_TOKEN_SECRET as string) as ITokenPayload;
      if (!decod) {
        throw new AppError(StatusCodes.UNAUTHORIZED, "Unauthorized access");
      }
      if (!decod.id) {
        throw new AppError(StatusCodes.UNAUTHORIZED, "User id is missing");
      }
      const user = await prisma.user.findUnique({
        where: {
          id: decod.id
        }
      });
      if (!user) {
        throw new AppError(StatusCodes.UNAUTHORIZED, "User account not found");
      }
      if (user?.status === "DELETED") {
        throw new AppError(StatusCodes.NOT_FOUND, "your account has been deleted ");
      };
      if (user?.status === "INACTIVE") {
        throw new AppError(StatusCodes.NOT_FOUND, "your account has been Inactive ");
      };
      if (user?.status === "SUSPENDED") {
        throw new AppError(StatusCodes.NOT_FOUND, "your account has been Suspend ");
      };

      if (allowedRoles.length > 0 && !allowedRoles.includes(user.user_role)) {
        throw new AppError(StatusCodes.FORBIDDEN, "you do not have permission");
      }
      res.locals.user = user;
      next();
    }
   catch (error) {
     if (error instanceof jwt.JsonWebTokenError) {
       res.status(401).json({
         success: false,
         message: "Invalid or expired token",
       });
       return;
     }

     next(error);
   }
  }
}

export default auth_Checker
