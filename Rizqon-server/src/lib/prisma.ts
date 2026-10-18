import { existsSync } from "node:fs";
import { Pool } from "pg";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../../prisma/generated/prisma/client.ts";

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
  const pool = new Pool({ connectionString });
  const adapter = new PrismaPg(pool);
  return new PrismaClient({ adapter });
}

export const prisma =
  globalForPrisma.prismaClient ?? createPrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prismaClient = prisma;
}
