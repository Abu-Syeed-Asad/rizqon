
import { ZodError } from "zod";
import { isAPIError } from "better-auth/api";
import { StatusCodes } from "http-status-codes";
import { AppError } from "./App.error";
import { Prisma } from "../../prisma/generated/prisma/client";
import type { NormalizedError } from "../type/errorType";

const INTERNAL_ERROR: NormalizedError = {
  statusCode: StatusCodes.INTERNAL_SERVER_ERROR,
  code: "INTERNAL_SERVER_ERROR",
  message: "Internal server error",
};

function hasErrorType(error: unknown, type: string): boolean {
  return error instanceof Error && "type" in error && error.type === type;
}

export function normalizeError(error: unknown): NormalizedError {
  if (error instanceof AppError) {
    return {
      statusCode: error.statusCode,
      code: error.code,
      message: error.message,
    };
  }

  if (error instanceof ZodError) {
    return {
      statusCode: StatusCodes.BAD_REQUEST,
      code: "VALIDATION_ERROR",
      message: "Request validation failed",
      details: error.issues.map((issue) => ({
        field: issue.path.map(String).join(".") || "request",
        message: issue.message,
      })),
    };
  }

  if (isAPIError(error)) {
    const statusCode = error.statusCode;

    if (
      !Number.isInteger(statusCode) ||
      statusCode < StatusCodes.BAD_REQUEST ||
      statusCode >= StatusCodes.INTERNAL_SERVER_ERROR
    ) {
      return {
        statusCode: StatusCodes.INTERNAL_SERVER_ERROR,
        code: "AUTH_SERVICE_ERROR",
        message: "Authentication service error",
      };
    }

    return {
      statusCode,
      code: error.body?.code ?? "AUTH_ERROR",
      message: error.body?.message ?? "Authentication request failed",
    };
  }

  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    switch (error.code) {
      case "P2002":
        return {
          statusCode: StatusCodes.CONFLICT,
          code: "RESOURCE_CONFLICT",
          message: "A record with this unique value already exists",
        };

      case "P2003":
        return {
          statusCode: StatusCodes.CONFLICT,
          code: "RELATION_CONFLICT",
          message: "This operation conflicts with a related record",
        };

      case "P2025":
        return {
          statusCode: StatusCodes.NOT_FOUND,
          code: "RECORD_NOT_FOUND",
          message: "The required record was not found",
        };

      case "P2024":
        return {
          statusCode: StatusCodes.SERVICE_UNAVAILABLE,
          code: "SERVICE_UNAVAILABLE",
          message: "Service temporarily unavailable",
        };

      default:
        return { ...INTERNAL_ERROR };
    }
  }

  if (error instanceof Prisma.PrismaClientInitializationError) {
    return {
      statusCode: StatusCodes.SERVICE_UNAVAILABLE,
      code: "SERVICE_UNAVAILABLE",
      message: "Service temporarily unavailable",
    };
  }

  // Invalid Prisma query arguments indicate an internal bug.
  if (error instanceof Prisma.PrismaClientValidationError) {
    return { ...INTERNAL_ERROR };
  }

  if (
    error instanceof SyntaxError &&
    hasErrorType(error, "entity.parse.failed")
  ) {
    return {
      statusCode: StatusCodes.BAD_REQUEST,
      code: "INVALID_JSON",
      message: "Request body contains invalid JSON",
    };
  }

  if (hasErrorType(error, "entity.too.large")) {
    return {
      statusCode: StatusCodes.REQUEST_TOO_LONG,
      code: "PAYLOAD_TOO_LARGE",
      message: "Request body is too large",
    };
  }

  return { ...INTERNAL_ERROR };
}
