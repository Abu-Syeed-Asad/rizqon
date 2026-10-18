import { toNodeHandler } from "better-auth/node";
import type { IncomingMessage, ServerResponse } from "node:http";

import { createAuth } from "./src/lib/auth";
import { sendMail } from "./src/lib/email";

const authHandler = toNodeHandler(createAuth(sendMail));

function sendJson(
  response: ServerResponse<IncomingMessage>,
  status: number,
  body: Record<string, string>,
): void {
  response.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
  });
  response.end(JSON.stringify(body));
}

export function app(
  request: IncomingMessage,
  response: ServerResponse<IncomingMessage>,
): void {
  const pathname = new URL(request.url ?? "/", "http://localhost").pathname;

  if (request.method === "GET" && pathname === "/") {
    sendJson(response, 200, {
      status: "ok",
      message:"welcome to server"
     });
    return;
  }

  if (pathname === "/api/auth" || pathname.startsWith("/api/auth/")) {
    authHandler(request, response);
    return;
  }

  sendJson(response, 404, { error: "Not found" });
}