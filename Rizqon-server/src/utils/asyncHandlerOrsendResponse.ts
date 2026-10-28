import type { RequestHandler, Response } from "express";
import type {
  IAsyncController,
  IApiResponse,
} from "../type/asyncControlerOrApi_response";

export const catchAsync = (fn: IAsyncController): RequestHandler => {
  return (req, res, next): void => {
    Promise.resolve()
      .then(() => fn(req, res, next))
      .catch(next);
  };
};

export const send_Response = <T>(res: Response, payload: IApiResponse<T>) => {
  return res.status(payload.statusCode).json({
    success: true,
    message: payload.message,
    data: payload.data,
  });
};
