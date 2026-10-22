import type { RequestHandler, Response } from "express";
import type { IApiResponse, IAsyncController } from "../type/asyncControlerOrApi_response.js";

export const catchAsync = (fn: IAsyncController): RequestHandler => {
  return (req, res, next): void => {
    Promise.resolve()
      .then(() => fn(req, res, next))
      .catch(next)
  };
}

export const send_Response = <T>(res: Response, response: IApiResponse<T>): void => {
  res.status(response.statusCode).json(response);
};
