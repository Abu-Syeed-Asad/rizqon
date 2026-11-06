import type { Request } from "express";
import { fromNodeHeaders } from "better-auth/node";

export const authHeaders = (req: Request): Headers => {
  const headers = fromNodeHeaders(req.headers);
  const sessionToken: unknown = req.cookies?.sessionToken;
  if (!headers.has("authorization") && typeof sessionToken === "string" && sessionToken) {
    headers.set("authorization", `Bearer ${sessionToken}`);
  }
  return headers;
};
