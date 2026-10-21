import "dotenv/config";
import { defineConfig, env } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema",

  migrations: {
    path: "prisma/migrations",
  },

  datasource: {
    // Schema operations should bypass Neon's PgBouncer pool. Application
    // traffic continues to use the pooled DATABASE_URL in src/lib/prisma.ts.
    url: process.env.DATABASE_URL_UNPOOLED ?? env("DATABASE_URL"),
  },
});
