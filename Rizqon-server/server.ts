import { createServer } from "node:http";

import { app } from "./app";
import { prisma } from "./src/lib/prisma";

const port = Number(process.env.PORT ?? "3000");


if (!Number.isInteger(port) || port < 0 || port > 65535) {
  throw new Error("PORT must be an integer between 0 and 65535");
}

const server = createServer(app);

server.on("error", (error: Error) => {
  console.error("HTTP server failed:", error);
  process.exitCode = 1;
});

server.listen(port,  () => {
  const address = server.address();
  const listeningPort =
    address && typeof address === "object" ? address.port : port;
  console.log(`Rizqon API listening at http://:${listeningPort}`);
});

let shuttingDown = false;

function shutdown(signal: NodeJS.Signals): void {
  if (shuttingDown) {
    return;
  }
  shuttingDown = true;
  console.log(`${signal} received; shutting down HTTP server`);

  const timeout = setTimeout(() => {
    console.error("Graceful shutdown timed out; closing active connections");
    server.closeAllConnections();
  }, 10_000);
  timeout.unref();

  server.close((error) => {
    clearTimeout(timeout);
    if (error) {
      console.error("Failed to close HTTP server:", error);
      process.exitCode = 1;
    }

    void prisma.$disconnect().catch((disconnectError: unknown) => {
      console.error("Failed to disconnect Prisma:", disconnectError);
      process.exitCode = 1;
    });
  });
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);