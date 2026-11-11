import "dotenv/config";
import { defineConfig } from "prisma/config";

const databaseUrl = process.env.DATABASE_URL_UNPOOLED || process.env.DATABASE_URL;
const migrationUrl = databaseUrl ? new URL(databaseUrl) : undefined;
// Allow time for Neon compute to wake up, preserving explicit timeout settings.
if (migrationUrl && !migrationUrl.searchParams.has("connect_timeout")) {
  migrationUrl.searchParams.set("connect_timeout", "15");
}

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
    url: migrationUrl?.toString(),
  },
});
