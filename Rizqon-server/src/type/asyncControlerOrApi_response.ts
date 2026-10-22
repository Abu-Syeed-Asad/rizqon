import type { NextFunction, Request, Response } from "express";

export type IAsyncController = (
  req: Request,
  res: Response,
  next: NextFunction,
) => Promise<unknown>;

export interface IApiResponse<T> {
  statusCode: number;
  message: string;
  data: T;
}
