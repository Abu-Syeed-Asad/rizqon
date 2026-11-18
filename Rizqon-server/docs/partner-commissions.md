# Partner commissions

This module manages business commission and partner payable amounts. It does not calculate customer promotions or initiate external money transfers.

## Architecture review and implementation order

The original schema already provided tenant-scoped composite foreign keys, fixed-scale Decimal columns, SALE/RETURN event types, event-key uniqueness, employee actors, and AuditLog. `Payment.direction = OUT` and `Payment.settlementId` already represented partner payouts, so no competing payout table was needed.

There were no Sale, SaleReturn, Payment, or Commission services/routes. Partner CRUD was protected by global system roles but queried records without tenant membership checks. Product writes checked employee/branch assignments; the repository had no general permission-table RBAC. This implementation uses stored employee job titles and active user/business status inside every service transaction. It does not reuse the unscoped Partner service or modify unrelated legacy CRUD.

The original `ProductVariant.agreementId` could hold only one current agreement. Replacing that pointer would lose historical applicability. New `CommissionAgreementVariant` assignments and `CommissionAgreementActivation` periods permit successive contracts without changing historical rates. Existing SaleItem agreement/rate fields remain the sale snapshot. Every CommissionEntry also preserves the original rate and agreement. One agreement, across all partners, may apply to a variant at a time; revenue splitting across several partners is deliberately unsupported.

Implemented phases: additive schema and guards; authorization/validation and agreement services; automatic sale/return ledger integration; settlements and payments; unit/HTTP/PostgreSQL tests and documentation. Existing uncommitted Employee/Product work was preserved.

## Tenant context and permissions

All endpoints are under `/api/v1/business/:businessId` and require the existing `Authorization: Bearer <access-token>` middleware. The URL selects a business; it grants no access. Services resolve an active Employee by authenticated user ID and requested business, verify active User and Business records, check the stored job title, and use the resulting employee's business ID for all work. Body tenant IDs, actor IDs, status overrides and calculated commission fields are rejected.

| Operation | Employee job titles |
| --- | --- |
| Agreement changes, finalization/cancellation, payment reconciliation, return approval/completion | OWNER, CEO, CO_OWNER, MANAGING_DIRECTOR, FINANCE_MANAGER |
| Commission reads, settlement drafts, pending payments | Above plus SENIOR_ACCOUNTANT, ACCOUNTANT |
| Sale completion and return requests | Managers above plus BRANCH_MANAGER, SALES_MANAGER, CASHIER, SALES_EXECUTIVE, SALES_ASSOCIATE |

Sale and return operations additionally require assignment to the sale's active branch. A global system-owner role alone does not authorize a commission operation. Authorization is repeated inside service transactions, including callers outside HTTP.

## Agreement lifecycle

Create returns an inactive draft (`isActive=false`, `firstActivatedAt=null`). PATCH can replace assignments, partner, dates, or rate only before first activation. Both endpoints reject overlapping draft reservations or activation periods for any shared variant, including different partners. Date windows are half open: `[startsAt, endsAt)`, with null meaning no scheduled end.

Activation starts at the later of server time and configured startsAt, and ends at the configured endsAt. New activations never retrospectively apply to completed sales. Deactivation closes the current interval, retaining earlier intervals. Reactivation creates another interval after checking overlap again. Explicit expiration sets `expiredAt` permanently. Scheduled expiry follows endsAt even if the stored isActive flag has not been changed by a background task. A used or previously activated contract is immutable; deactivate/expire it and create a new contract to change the rate or product set.

State is derived: explicit expiredAt or a past endsAt means EXPIRED; otherwise isActive means ACTIVE (possibly scheduled); otherwise firstActivatedAt means INACTIVE; otherwise DRAFT. The existing agreement boolean is retained for compatibility; no new agreement status enum is required.

## Sale and return integration

`POST /sales/:id/complete` completes an existing trusted DRAFT sale. The repository has no checkout/draft-creation API; its future checkout service must construct authoritative price, quantity, allocated discount, tax, and header totals before calling this transition. This endpoint accepts `{}` and cannot set prices or discounts. COMPLETED is the recognition state and the server-generated `completedAt` is the agreement lookup timestamp. Repeating completion returns the existing completed sale without reconstructing missing historical entries.

Completion validates item/header totals, decrements branch inventory conditionally, records stock movements, records commission snapshots and entries, marks the cart checked out when present, and marks the sale complete in one transaction. Insufficient inventory or ambiguous contracts rolls everything back. Products without an applicable activation produce no commission entry.

All money calculations use an isolated 48-digit Prisma.Decimal constructor and explicit half-up rounding to two decimals. Inputs are decimal strings, never binary floating-point amounts. Quantities support three decimals. The after-discount, before-tax base is `(unitPrice * quantity) - discountAmount`; business commission is rounded `base * rate / 100`; partner payable is the difference. Header discounts must already be allocated to SaleItem.discountAmount; the service never reallocates them.

Return requests contain sale ID, item IDs, quantities and restock flags, not refund or commission amounts. They start REQUESTED, require approval, and recognize reversal only on COMPLETED. Completion locks the original sale, rechecks cumulative completed quantities, allocates refunds from original line totals including tax, reverses commissions from the original SALE entries, optionally restocks inventory, and writes audit records atomically. Refund entitlement is recorded; no customer refund transfer is executed.

Partial reversals use the difference between cumulative allocations. Gross base is prorated by cumulative returned quantity. Commission is prorated from the original commission against that rounded gross base, preventing tiny returns from having commission greater than gross. Payable is their difference. The final return consumes all residual cents and exactly negates the original entry. Historical allocations that do not reconcile are blocked for review rather than rewritten.

Ledger event keys are `SALE:<saleItemId>:<agreementId>` and `RETURN:<returnItemId>:<agreementId>`. Database uniqueness also limits one SALE per item and one RETURN per ReturnItem. SALE records are never deleted or changed by returns.

## Settlements, adjustments and payments

Draft creation claims a nonempty unique list of eligible entries from one tenant/partner. The amount is their partner-payable sum and currency must match the originating sales and business. Entry claims use conditional updates and count checks inside a serializable transaction. References use `CS-<UUID>` and have tenant-scoped uniqueness (the older global unique index is also retained).

Draft PATCH releases/reclaims entries atomically and recalculates amount. Finalization revalidates entries, amount and currency; FINALIZED and CANCELLED records cannot be edited. Cancel is allowed only from DRAFT and releases claims. A negative draft can be held and combined with future positive entries, but cannot be finalized or paid. Zero settlements may be finalized and require no payment.

Returns after settlement/payment create new, unclaimed negative entries. They do not change old settled amounts or successful payments. All outstanding negative entries for a partner, including entries held in another draft, must be consolidated before finalization or initiating a further payment. This conservative carry-forward rule can hold an older unpaid settlement until future sales offset the return. Reconciliation may still record an already reserved payout confirmed after a return, so actual money sent is never hidden; the return debt continues to block new payment initiation. It does not silently net a finalized document, write off a receivable, or execute a negative payout.

Payment creation records a PENDING outbound Payment and reserves its amount. Successfully paid amounts alone reduce remaining payable. PENDING, PROCESSING and AUTHORIZED amounts reduce the amount available for a new payment. The partner row lock and serializable retry protect concurrent reservations. Failed/cancelled payments release their reservation and require a new idempotency key for another attempt.

`POST /commission-settlements/:id/payments/:paymentId/reconcile` is **manual reconciliation**, restricted to finance managers/owners. The operator must independently verify a bank/mobile/card confirmation or signed cash receipt, supply its unique evidenceReference and a note, and attest SUCCEEDED, FAILED or CANCELLED. The endpoint records that attestation and a PaymentEvent; it does not verify a payment provider, transfer funds, or accept public provider callbacks. Automated provider verification requires a future authenticated provider adapter. Do not use pending creation as evidence that a transfer occurred.

Terminal payment status, identity and amounts are immutable. Reconciliation is idempotent by payment/event identity and payload hash; reused evidence references are constrained by the existing provider-reference uniqueness. Settlement status stays FINALIZED because the existing enum has only DRAFT, FINALIZED and CANCELLED. Read responses derive paymentStatus as UNPAID/PARTIALLY_PAID/PAID using `remainingPayable = amount - successfulPaidAmount`, alongside reservedAmount and availableToPay.

## API

All paths below follow the tenant prefix. Mutations validate strict Zod objects in services. Action endpoints require JSON `{}`. Lists accept page (default 1), limit (default 25, max 100), and partnerId. Entries additionally accept settlementId or unsettled=true/false.

| Method | Path | Request |
| --- | --- | --- |
| POST / GET | `/commission-agreements` | Create example below / list filters |
| GET / PATCH | `/commission-agreements/:id` | Details / nonempty draft patch |
| GET | `/commission-agreements/:id/history` | Audited before/after snapshots |
| POST | `/commission-agreements/:id/activate`, `/deactivate`, `/expire` | `{}` |
| GET | `/commission-entries`, `/commission-entries/:id` | Read only |
| POST / GET | `/commission-settlements` | Selection example below / filters |
| GET / PATCH | `/commission-settlements/:id` | Details and balance / `{ "commissionEntryIds": [...] }` |
| POST | `/commission-settlements/:id/finalize`, `/cancel` | `{}` |
| POST / GET | `/commission-settlements/:id/payments` | Pending payment example / payments and balance |
| POST | `/commission-settlements/:id/payments/:paymentId/reconcile` | Status, evidenceReference, note |
| POST | `/sales/:id/complete` | `{}` |
| POST | `/sale-returns` | Return example below |
| POST | `/sale-returns/:id/approve`, `/reject`, `/complete` | `{}` |

Create agreement:

```json
{"partnerId":"partner_123","commissionPercent":"10.00","startsAt":"2026-11-18T00:00:00.000Z","endsAt":null,"productVariantIds":["variant_001","variant_002"]}
```

Create settlement (idempotency key is required):

```json
{"partnerId":"partner_123","commissionEntryIds":["entry_001","entry_002","entry_003"],"idempotencyKey":"settlement-20261118-001"}
```

Record partial payment, then reconcile after independently confirming the transfer:

```json
{"amount":"500.00","method":"BANK_TRANSFER","idempotencyKey":"partner-payment-001","note":"First installment"}
```

```json
{"status":"SUCCEEDED","evidenceReference":"bank-statement-reference-001","note":"Matched the bank confirmation to this partner and amount"}
```

Request return:

```json
{"saleId":"sale_001","idempotencyKey":"return-20261118-001","reason":"Customer return","items":[{"saleItemId":"item_001","quantity":"0.500","restock":true}]}
```

Success responses use the existing envelope; Decimal fields serialize as strings (trailing zeros are not guaranteed):

```json
{"success":true,"message":"Settlement retrieved","data":{"id":"settlement_001","settlement_status":"FINALIZED","amount":"2250","currency":"BDT","successfulPaidAmount":"500","remainingPayable":"1750","reservedAmount":"0","availableToPay":"1750","paymentStatus":"PARTIALLY_PAID"}}
```

This is an abbreviated response; details also include stored fields and claimed entries. Standard errors use the existing error handler: 400 invalid input, 401 authentication, 403 tenant/role/branch permission, 404 missing scoped record, 409 overlap, claimed entries, inconsistent history, overpayment or transaction conflict. Financial idempotency keys are bound to normalized request hashes; reuse with different content fails with 409. Lists and action responses retain the existing project envelope. No public writable commission-entry route exists.

Import `docs/partner-commissions.postman_collection.json` for executable request templates and example responses. Set baseUrl, accessToken and tenant/resource variables. A trusted draft sale must already exist before the completion request.

## Concurrency and audit

Operations use PostgreSQL Serializable transactions with at most four attempts for serialization/unique-key races. No external side effects occur inside callbacks. Sale/return completion locks the original sale; settlement/payment operations lock the partner; conditional entry/inventory updates and database indexes provide additional protection. Locks are transaction-scoped; see [PostgreSQL explicit locking](https://www.postgresql.org/docs/current/explicit-locking.html).

AuditLog records actor, tenant, action, entity, before/after states for agreements, entries, settlements, payments, sale and return transitions. PaymentEvent records reconciliation identity and payload hash. Existing structured request-error logging is reused. Database triggers enforce append-only commission amounts, immutable finalized settlement claims/documents, frozen activated configuration/assignments, and immutable terminal partner payments. A second additive migration (`20261118001000_commission_history_guards`) freezes completed sale/return documents and items, preserves activation periods, and checks payout currency and reserved/successful totals. Voiding an already completed sale requires a future explicit reversal workflow; completed sales cannot simply be changed to VOID.

## Migration and rollout

`20261118000000_partner_commission` is additive and transactional. It adds two relationship/history tables, nullable agreement lifecycle metadata, settlement currency/idempotency/hash fields, and payment/return request hashes. Existing global reference/event uniqueness is retained. No existing financial amount is recalculated, no sale/return commission is retroactively created, and no legacy relation is dropped.

The migration copies current ProductVariant agreement links into the junction and freezes all pre-existing agreements using createdAt as a conservative metadata marker. It adds activation intervals only for existing active agreements using their stored effective dates. Previous deactivation history cannot be reconstructed from the old schema. Do not treat migrated activation windows as independently verified historical evidence. Inactive legacy contracts can be reactivated prospectively; changing their configuration requires a new contract.

Old settlements retain null currency because deriving historical currency from today's Business would be unsafe. Legacy drafts must be reviewed through PATCH to validate their entries/currency before finalization. Legacy finalized settlements with missing currency are not payable through this API; reconcile them through a separately reviewed data migration. Existing malformed financial records are retained by NOT VALID checks, but writes touching them can be rejected. Resolve those records explicitly before rollout. Constraint validation after remediation is a separate operation.

Before applying to production, run these read-only checks on an isolated branch and review any returned rows:

```sql
SELECT "businessId", "saleItemId", count(*) FROM commerce."CommissionEntry"
WHERE "eventType" = 'SALE' GROUP BY 1, 2 HAVING count(*) > 1;
SELECT "businessId", "returnItemId", count(*) FROM commerce."CommissionEntry"
WHERE "eventType" = 'RETURN' GROUP BY 1, 2 HAVING count(*) > 1;
SELECT id FROM commerce."CommissionAgreement" WHERE "commissionPercent" NOT BETWEEN 0 AND 100
  OR ("endsAt" IS NOT NULL AND "endsAt" <= "startsAt");
SELECT id FROM commerce."CommissionEntry" WHERE "grossBase" <> "commissionAmount" + "partnerPayable";
SELECT id FROM commerce."Payment" WHERE "settlementId" IS NOT NULL AND
  (direction <> 'OUT' OR amount <= 0 OR "saleId" IS NOT NULL OR "purchaseId" IS NOT NULL OR "expenseId" IS NOT NULL);
```

Duplicate historical entries deliberately stop migration; no automated deletion/deduplication is performed. Coordinate deployment so all new commission writes use these services. Old writers must not keep changing ProductVariant.agreementId as a commission configuration mechanism. Direct database writers remain privileged and must respect lifecycle/authorization rules; this module does not introduce database RLS for the whole application. Existing unscoped Partner/other legacy APIs still need their own security review before claiming application-wide tenant isolation.

## Run and test

From `E:\Rizqon\Rizqon-server`, with existing dependencies installed:

```powershell
node node_modules/prisma/build/index.js generate
node node_modules/prisma/build/index.js validate
node node_modules/typescript/bin/tsc --noEmit
node node_modules/tsx/dist/cli.mjs --test tests/commission.test.ts tests/commission.routes.test.ts
node node_modules/tsx/dist/cli.mjs --test tests/*.test.ts
node node_modules/eslint/bin/eslint.js src/module/Commission src/module/Sale src/module/SaleReturn tests/commission*.ts scripts/commission-db.mjs
node node_modules/tsdown/dist/run.mjs
```

For real PostgreSQL tests, put a direct connection to an **isolated branch** in ignored `.env.commission-test.local`:

```dotenv
COMMISSION_TEST_DATABASE_URL=postgresql://<test-branch-credentials>/<database>?sslmode=require
COMMISSION_TEST_ALLOW_WRITES=1
```

```powershell
node scripts/commission-db.mjs status
node scripts/commission-db.mjs migrate
node scripts/commission-db.mjs test
node scripts/commission-db.mjs test-history
```

The runner refuses the application's configured database hostname and overrides child-process database URLs only. It never rewrites `.env`. Integration tests create uniquely named synthetic tenants and leave their audit/financial records on the isolated branch. They skip in the ordinary test command unless the explicit test environment is set. Remove the test branch through the normal approved database lifecycle when finished.

Production rollout, after reviewing preflight results and testing a copy, uses `node node_modules/prisma/build/index.js migrate deploy` with the target's direct `DATABASE_URL_UNPOOLED`, followed by generate/build and deployment. Do not run migrate reset or db push against existing data. This implementation does not deploy the migration to production.

## Changed files

- Schema: CommissionAgreement.prisma, ProductVariant.prisma, CommissionSettlement.prisma, Payment.prisma, SaleReturn.prisma, two additive migrations, and regenerated tracked Prisma client files.
- New Commission module: common authorization/transactions/audit helpers; validation; decimal math; agreement, entry, settlement, payment services; controller and routes.
- New Sale completion service and SaleReturn validation/service; route registration in src/index.route.ts.
- Tests: commission.test.ts (validation/math/authorization/retries), commission.routes.test.ts (HTTP authentication/scoping/input guards), commission.integration.test.ts (real database lifecycle, concurrency and history), commission-history.integration.test.ts (scheduled activations and immutable periods).
- Tooling/docs: scripts/commission-db.mjs, this document, and the Postman collection. No runtime dependencies were added.

The pre-existing full-suite failure in `tests/business.test.ts` is unrelated: its transaction mock lacks `tx.partner.create` used by the Business service. Commission work does not alter that module or its tests.
