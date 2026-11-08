import type { RequestHandler } from "express";
import type { ZodType } from "zod";

export const validateQuery = (schema: ZodType): RequestHandler => {
  return async (req, res, next) => {
    try {
      // Express 5 exposes req.query as a getter; keep parsed values in locals.
      res.locals.validatedQuery = await schema.parseAsync(req.query);
      next();
    } catch (error) {
      next(error);
    }
  };
};
