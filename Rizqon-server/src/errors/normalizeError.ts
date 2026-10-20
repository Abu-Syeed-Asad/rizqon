
import { ZodError } from "zod";
import { isAPIError } from "better-auth/api";
import { StatusCodes } from "http-status-codes";
import { AppError } from "./App.error.js";
import { Prisma } from "../../prisma/generated/prisma/client.js";
import type { NormalizedError } from "../type/errorType.js";

const INTERNAL_ERROR: NormalizedError = {
  statusCode: StatusCodes.INTERNAL_SERVER_ERROR,
  code: "INTERNAL_SERVER_ERROR",
  message: "Internal server error",
};

function hasErrorType(error: unknown, type: string): boolean {
  return error instanceof Error && "type" in error && error.type === type;
}

const PRISMA_BAD_REQUEST_CODES = new Set([
  "P2000", // Value too long for the column.
  "P2006", // Invalid value supplied for a field.
  "P2007", // Data validation error.
  "P2019", // Input error.
  "P2020", // Value out of range.
  "P2033", // Number does not fit in a signed 64-bit integer.
]);

const PRISMA_NOT_FOUND_CODES = new Set([
  "P2001", // Record searched for does not exist.
  "P2015", // Related record not found.
  "P2018", // Required connected records not found.
  "P2025", // Required record not found.
]);

const PRISMA_CONFLICT_CODES = new Set([
  "P2002", // Unique constraint violation.
  "P2003", // Foreign-key constraint violation.
  "P2004", // Database constraint violation.
  "P2011", // Null constraint violation.
  "P2014", // Required relation violation.
  "P2017", // Relation records are not connected.
]);

const PRISMA_UNAVAILABLE_CODES = new Set([
  "P1000", // Database authentication failed.
  "P1001", // Database server unreachable.
  "P1002", // Database connection timed out.
  "P1008", // Database operation timed out.
  "P1010", // Database access denied.
  "P1011", // TLS connection failed.
  "P1017", // Server closed the connection.
  "P2024", // Connection-pool timeout.
  "P2037", // Too many database connections.
  "P6004", // Prisma Accelerate query timeout.
  "P6008", // Prisma Accelerate connection/engine error.
]);

function normalizeKnownPrismaError(
  error: Prisma.PrismaClientKnownRequestError,
): NormalizedError {
  if (PRISMA_BAD_REQUEST_CODES.has(error.code)) {
    return {
      statusCode: StatusCodes.BAD_REQUEST,
      code: "INVALID_DATABASE_INPUT",
      message: "One or more values are invalid",
    };
  }

  if (PRISMA_NOT_FOUND_CODES.has(error.code)) {
    return {
      statusCode: StatusCodes.NOT_FOUND,
      code: "RECORD_NOT_FOUND",
      message: "The required record was not found",
    };
  }

  if (error.code === "P2002") {
    return {
      statusCode: StatusCodes.CONFLICT,
      code: "RESOURCE_CONFLICT",
      message: "A record with this unique value already exists",
    };
  }

  if (PRISMA_CONFLICT_CODES.has(error.code)) {
    return {
      statusCode: StatusCodes.CONFLICT,
      code: "RELATION_CONFLICT",
      message: "This operation conflicts with an existing record",
    };
  }

  if (error.code === "P2034") {
    return {
      statusCode: StatusCodes.CONFLICT,
      code: "TRANSACTION_CONFLICT",
      message: "The operation conflicted with another transaction; please retry",
    };
  }

  if (error.code === "P5011") {
    return {
      statusCode: StatusCodes.TOO_MANY_REQUESTS,
      code: "RATE_LIMIT_EXCEEDED",
      message: "Too many requests; please try again later",
    };
  }

  if (PRISMA_UNAVAILABLE_CODES.has(error.code)) {
    return {
      statusCode: StatusCodes.SERVICE_UNAVAILABLE,
      code: "DATABASE_UNAVAILABLE",
      message: "Service temporarily unavailable",
    };
  }

  // Schema, raw-query, engine, and unknown Prisma errors are server defects.
  return { ...INTERNAL_ERROR };
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
    return normalizeKnownPrismaError(error);
  }

  if (error instanceof Prisma.PrismaClientInitializationError) {
    return {
      statusCode: StatusCodes.SERVICE_UNAVAILABLE,
      code: "DATABASE_UNAVAILABLE",
      message: "Service temporarily unavailable",
    };
  }

  // These errors have no safe client-facing detail and indicate a server defect.
  if (
    error instanceof Prisma.PrismaClientValidationError ||
    error instanceof Prisma.PrismaClientUnknownRequestError ||
    error instanceof Prisma.PrismaClientRustPanicError
  ) {
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
