import { createServer } from "node:http";
import { app } from "./app.js";
import { env } from "./config/env.js";
import { prisma } from "./lib/prisma.js";

const server = createServer(app);

server.requestTimeout = 30_000;
server.headersTimeout = 15_000;
server.keepAliveTimeout = 5_000;

let shuttingDown = false;

async function shutdown(reason: string, exitCode = 0): Promise<void> {
  if (shuttingDown) return;
  shuttingDown = true;

  console.info(`Shutting down: ${reason}`);

  const forceExitTimer = setTimeout(() => {
    console.error("Shutdown deadline exceeded");
    server.closeAllConnections();
    process.exit(1);
  }, 15_000);

  forceExitTimer.unref();

  try {
    if (server.listening) {
      await new Promise<void>((resolve, reject) => {
        server.close((error) => {
          if (error) reject(error);
          else resolve();
        });
      });
    }

    await prisma.$disconnect();

    clearTimeout(forceExitTimer);
    process.exitCode = exitCode;
  } catch {
    console.error("Shutdown failed");
    process.exit(1);
  }
}

process.once("SIGINT", () => {
  void shutdown("SIGINT");
});

process.once("SIGTERM", () => {
  void shutdown("SIGTERM");
});

process.once("unhandledRejection", () => {
  void shutdown("Unhandled promise rejection", 1);
});

process.once("uncaughtException", () => {
  void shutdown("Uncaught exception", 1);
});

server.on("error", (error: NodeJS.ErrnoException) => {
  console.error("HTTP server error", {
    code: error.code,
  });

  void shutdown("HTTP server error", 1);
});

async function start(): Promise<void> {
  try {
    await prisma.$connect();

    if (shuttingDown) {
      await prisma.$disconnect();
      return;
    }

    server.listen(env.PORT, () => {
      console.info(`API listening at http://localhost:${env.PORT}`);
    });
  } catch {
    console.error("Application startup failed");
    await shutdown("Startup failure", 1);
  }
}

void start();
