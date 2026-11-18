import { existsSync, readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { parse } from "dotenv";

if (existsSync(".env.commission-test.local")) process.loadEnvFile(".env.commission-test.local");
const target = process.env.COMMISSION_TEST_DATABASE_URL;
if (!target || process.env.COMMISSION_TEST_ALLOW_WRITES !== "1") throw new Error("Set COMMISSION_TEST_DATABASE_URL and COMMISSION_TEST_ALLOW_WRITES=1 for an isolated test database");
const source = existsSync(".env") ? parse(readFileSync(".env")) : {};
const host = value => new URL(value).hostname.replace("-pooler", "");
for (const value of [source.DATABASE_URL, source.DATABASE_URL_UNPOOLED]) {
  if (value && host(value) === host(target)) throw new Error("Refusing to test against the application database host");
}
if (new URL(target).hostname.includes("-pooler")) throw new Error("Use a direct connection for migration tests");
const action = process.argv[2];
const args = action === "migrate" ? ["node_modules/prisma/build/index.js", "migrate", "deploy"]
  : action === "status" ? ["node_modules/prisma/build/index.js", "migrate", "status"]
  : action === "test" ? ["node_modules/tsx/dist/cli.mjs", "--test", "tests/commission.integration.test.ts"]
  : action === "test-history" ? ["node_modules/tsx/dist/cli.mjs", "--test", "tests/commission-history.integration.test.ts"] : null;
if (!args) throw new Error("Usage: node scripts/commission-db.mjs status|migrate|test|test-history");
const result = spawnSync(process.execPath, args, { stdio: "inherit", env: { ...process.env, DATABASE_URL: target, DATABASE_URL_UNPOOLED: target } });
if (result.error) throw result.error;
process.exitCode = result.status ?? 1;
