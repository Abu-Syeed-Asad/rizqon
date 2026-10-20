import express, { type ErrorRequestHandler, type Request, type Response } from "express";
import cors from "cors";
import helmet from "helmet";
import { toNodeHandler } from "better-auth/node";

import { env } from "./config/env.js";
import { createAuth } from "./lib/auth.js";
import { AppError } from "./errors/App.error.js";
import { StatusCodes } from "http-status-codes";
import { errorHandler } from "./middleware/errorhandler.js";


const auth = createAuth();


export const app = express();

app.disable("x-powered-by");

app.use(helmet());

app.use(
  cors({
    origin: env.FRONTEND_ORIGIN,
    credentials: true,
  }),
);

app.all("/api/auth/*splat", toNodeHandler(auth));

app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: false, limit: "1mb" }));

app.get("/", (req:Request, res:Response) => {
  res.status(200).json({
    status: "ok",
    App: " RIZQON ",
    message:"This Server Is running ..."
   });
});



app.use((_req, _res, next) => {
  next(
    new AppError(StatusCodes.NOT_FOUND,"ROUTE_NOT_FOUND"),
  );
});

app.use(errorHandler);
