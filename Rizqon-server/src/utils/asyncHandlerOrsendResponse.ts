import type { RequestHandler } from "express";
import type { AsyncController } from "../type/asyncControlerOrApi_response.js";

export const catchAsync = (fn: AsyncController): RequestHandler => {
  return (req, res, next): void => {
    Promise.resolve()
      .then(() => fn(req, res, next))
      .catch(next)
  };
}
