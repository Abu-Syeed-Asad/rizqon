import "dotenv/config";
import { defineConfig } from "prisma/config";

export default defineConfig({
  schema: "prisma",

  migrations: {
    path: "prisma/migrations",
  },

  datasource: {
    // Schema operations should bypass Neon's PgBouncer pool. Application
    // traffic continues to use the pooled DATABASE_URL in src/lib/prisma.ts.
    // Client generation can run without a database connection. Database
    // commands still require a configured URL.
    url: process.env.DATABASE_URL_UNPOOLED || process.env.DATABASE_URL,
  },
});
