import type { RequestHandler } from "express";
import type { AsyncController } from "../type/asyncControler";

export const asyncHandler = (fn: AsyncController): RequestHandler => {
  return (req, res, next): void => {
    Promise.resolve()
      .then(() => fn(req, res, next))
      .catch(next)
  };
}