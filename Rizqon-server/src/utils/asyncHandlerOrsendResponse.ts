import type { NextFunction, Request, RequestHandler, Response } from "express";
import type {
  IApiResponse,
} from "../type/asyncControlerOrApi_response";

export const catchAsync = <Params = Request["params"]>(
  fn: (req: Request<Params>, res: Response, next: NextFunction) => Promise<unknown>,
): RequestHandler<Params> => {
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
