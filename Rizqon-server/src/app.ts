import express, { type Request, type Response } from "express";
import cookieParser from "cookie-parser";
import { toNodeHandler } from "better-auth/node";
import { auth } from "./lib/auth.js";
import cors from "cors";
import helmet from "helmet";

import { env } from "./config/env.js";

import { AppError } from "./errors/App.error.js";
import { StatusCodes } from "http-status-codes";
import { errorHandler } from "./middleware/errorhandler.js";

import { index_router } from "./index.route.js";

export const app = express();


app.disable("x-powered-by");
app.use(helmet());
app.use(
  cors({
    origin: env.FRONTEND_ORIGIN,
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"],
  }),
);


// Google returns its authorization code here; Better Auth verifies OAuth state.
app.get("/api/v1/auth/callback/google", toNodeHandler(auth));

app.use(express.json({ limit: "1mb" }));
app.use(cookieParser())
app.use(express.urlencoded({ extended: false, limit: "1mb" }));



app.use("/api/v1/", index_router);

app.get("/", (req: Request, res: Response) => {
  res.status(200).json({
    status: "ok",
    App: " RIZQON ",
    message: "This Server Is running ...",
  });
});


app.use((_req, _res, next) => {
  next(
    new AppError(
      StatusCodes.NOT_FOUND,
      "Route not found",
      true,
      "ROUTE_NOT_FOUND",
    ),
  );
});

app.use(errorHandler);
