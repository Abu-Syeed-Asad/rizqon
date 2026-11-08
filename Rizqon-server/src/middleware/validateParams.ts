import type { RequestHandler } from "express";
import type { ZodType } from "zod";

export const validateParams = (schema: ZodType<Record<string, string>>): RequestHandler => {
  return async (req, _res, next) => {
    try {
      req.params = await schema.parseAsync(req.params);
      next();
    } catch (error) {
      next(error);
    }
  };
};
