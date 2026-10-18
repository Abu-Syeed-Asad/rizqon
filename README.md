# RIZQON Database Schema

The backend uses a multi-file Prisma schema based on the `DemoSchema` reference. Models are split by business area under `Rizqon-server/prisma/schema`.

## Run locally

From the repository root, run the backend directly:

```bash
pnpm --dir Rizqon-server run dev
```

This starts the HTTP server on `PORT` (default `3000`), serves `/health` and Better Auth under `/api/auth/*`, and generates Prisma Client from the schema folder before starting.

## Prerequisites

- Node.js and npm
- PostgreSQL database
- Prisma CLI and Prisma Client

## Setup

1. Create a PostgreSQL database.
2. Create `.env` in the backend project (do not commit real credentials):

   ```env
   DATABASE_URL="postgresql://USER:PASSWORD@localhost:5432/rizqon?schema=commerce"
   BETTER_AUTH_SECRET="generate-a-long-random-secret"
   BETTER_AUTH_URL="http://localhost:3000"
   FRONTEND_ORIGIN="http://localhost:5173"
   SMTP_HOST="smtp.example.com"
   SMTP_PORT="587"
   SMTP_FROM="Rizqon <no-reply@example.com>"
   SMTP_USER="smtp-user"
   SMTP_PASS="smtp-password"
   ```

3. Install Prisma in your backend project:

   ```bash
   pnpm --dir Rizqon-server install
   pnpm --dir Rizqon-server run db:validate
   pnpm --dir Rizqon-server run db:generate
   ```

4. Review the [DemoSchema migration notes](./DemoSchema/README.md) before changing a database. The schema includes legacy tables and custom SQL features that must not be replaced by an unreviewed generated migration.

## Important implementation notes

- SMTP settings are used to send Better Auth verification and password-reset emails. `SMTP_USER` and `SMTP_PASS` are optional, but must be set together when the SMTP server requires authentication.
- The schema is a blueprint; it does not create or connect to your live database by itself.
- All tenant-owned records must be queried through a verified business membership and business scope.
- Add PostgreSQL row-level security only if the team can configure, test, and maintain it correctly; it is an extra layer, not a substitute for backend authorization.
- Test tenant isolation, inventory concurrency, order/payment idempotency, return quantities, and webhook signature verification.
- Provider enum values are examples. Keep only the payment providers actually supported by the project.
- Some business rules (for example, `quantity > 0`, nonnegative totals, and return quantities not exceeding purchased quantities) need database check constraints or transactional backend validation. Prisma's schema DSL does not express every PostgreSQL constraint directly; add custom SQL to a migration where required.
- The current model uses a single inventory balance per product. For multi-warehouse inventory, add a `Warehouse` table and change the unique balance key to `(warehouse_id, product_id)`.
- Run `pnpm --dir Rizqon-server run db:validate` before using this schema.
