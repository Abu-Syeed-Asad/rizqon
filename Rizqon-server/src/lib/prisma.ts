import { existsSync } from "node:fs";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../../prisma/generated/prisma/client.js";

if (existsSync(".env")) {
  process.loadEnvFile();
}

const globalForPrisma = globalThis as typeof globalThis & {
  prismaClient?: PrismaClient;
};

function createPrismaClient(): PrismaClient {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error("DATABASE_URL environment variable is not set");
  }

  const databaseUrl = new URL(connectionString);
  const sslMode = databaseUrl.searchParams.get("sslmode");
  if (sslMode === "prefer" || sslMode === "require" || sslMode === "verify-ca") {
    databaseUrl.searchParams.set("sslmode", "verify-full");
  }

  // Let the adapter own the pool so $disconnect() closes it on shutdown.
  const adapter = new PrismaPg({ connectionString: databaseUrl.toString() });
  return new PrismaClient({ adapter });
}

export const prisma =
  globalForPrisma.prismaClient ?? createPrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prismaClient = prisma;
}
