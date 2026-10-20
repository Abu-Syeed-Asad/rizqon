// src/middlewares/errorHandler.ts

import { randomUUID } from "node:crypto";
import type { ErrorRequestHandler } from "express";
import { StatusCodes } from "http-status-codes";

import { normalizeError } from "../errors/normalizeError.js";

export const errorHandler: ErrorRequestHandler = (
  error: unknown,
  req,
  res,
  next,
): void => {
  if (res.headersSent) {
    next(error);
    return;
  }

  const normalized = normalizeError(error);

  // Reuse an ID assigned by your request middleware if present.
  const requestId =
    typeof res.locals.requestId === "string"
      ? res.locals.requestId
      : randomUUID();

  res.setHeader("X-Request-ID", requestId);

  if (normalized.statusCode >= StatusCodes.INTERNAL_SERVER_ERROR) {
    
    console.error({
      event: "request_failed",
      requestId,
      method: req.method,
      statusCode: normalized.statusCode,
      code: normalized.code,
      errorName: error instanceof Error ? error.name : "UnknownError",
    });
  }

  res.status(normalized.statusCode).json({
    success: false,
    error: {
      code: normalized.code,
      message: normalized.message,
      ...(normalized.details ? { details: normalized.details } : {}),
    },
    requestId,
  });
};
