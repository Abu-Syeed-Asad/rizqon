# RIZQON Database Schema

This folder contains the proposed Prisma schema for RIZQON's 22 core PostgreSQL tables.

## Prerequisites

- Node.js and npm
- PostgreSQL database
- Prisma CLI and Prisma Client

## Setup

1. Create a PostgreSQL database.
2. Create `.env` in the backend project (do not commit real credentials):

   ```env
   DATABASE_URL="postgresql://USER:PASSWORD@localhost:5432/rizqon?schema=public"
   ```

3. Install Prisma in your backend project:

   ```bash
   npm install prisma @prisma/client
   npx prisma validate
   npx prisma generate
   npx prisma migrate dev --name init_rizqon
   ```

4. Inspect the generated migration before applying it to any shared or production database.

## Important implementation notes

- This is a schema blueprint; it does not create or connect to your live database by itself.
- All tenant-owned records must be queried through a verified business membership and business scope.
- Add PostgreSQL row-level security only if the team can configure, test, and maintain it correctly; it is an extra layer, not a substitute for backend authorization.
- Test tenant isolation, inventory concurrency, order/payment idempotency, return quantities, and webhook signature verification.
- Provider enum values are examples. Keep only the payment providers actually supported by the project.
- Some business rules (for example, `quantity > 0`, nonnegative totals, and return quantities not exceeding purchased quantities) need database check constraints or transactional backend validation. Prisma's schema DSL does not express every PostgreSQL constraint directly; add custom SQL to a migration where required.
- The current model uses a single inventory balance per product. For multi-warehouse inventory, add a `Warehouse` table and change the unique balance key to `(warehouse_id, product_id)`.
- Run `npx prisma validate` against your installed Prisma version before using this schema.
