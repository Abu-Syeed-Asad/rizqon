import express, { type ErrorRequestHandler, type Request, type Response } from "express";
import cors from "cors";
import helmet from "helmet";
import { toNodeHandler } from "better-auth/node";

import { env } from "./config/env.js";
import { createAuth } from "./lib/auth.js";
// import { sendMail } from "./lib/email.js";

// const auth = createAuth(sendMail);
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

// Liveness: the application process is responding.
app.get("/", (req:Request, res:Response) => {
  res.status(200).json({
    status: "ok",
    App: " RIZQON ",
    message:"This Server Is running ..."
   });
});



app.use((req:Request, res:Response) => {
  res.status(404).json({
    success: false,
    message: "Route not found",
  });
});

