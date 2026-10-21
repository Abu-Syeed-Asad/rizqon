import type { RequestHandler } from "express";
import { fromNodeHeaders } from "better-auth/node";
import { StatusCodes } from "http-status-codes";

import { AppError } from "../errors/App.error.js";
import { auth } from "../lib/auth.js";

export const requireAuth: RequestHandler = async (req, res, next) => {
  try {
    const session = await auth.api.getSession({
      headers: fromNodeHeaders(req.headers),
    });

    if (!session) {
      next(
        new AppError(
          StatusCodes.UNAUTHORIZED,
          "Authentication is required",
          true,
          "UNAUTHENTICATED",
        ),
      );
      return;
    }

    if ((session.user as typeof session.user & { status?: string }).status !== "ACTIVE") {
      next(
        new AppError(
          StatusCodes.FORBIDDEN,
          "This account is not active",
          true,
          "ACCOUNT_INACTIVE",
        ),
      );
      return;
    }

    res.locals.auth = session;
    next();
  } catch (error) {
    next(error);
  }
};
