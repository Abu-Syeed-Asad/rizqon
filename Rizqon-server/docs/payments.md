# Stripe and SSLCommerz payments

The backend collects the remaining balance of an existing **completed sale** through hosted checkout. It supports Stripe and SSLCommerz, verified notifications, status reconciliation, branch/tenant authorization and idempotent payment records. Sale completion already handles inventory and commission accrual; payment callbacks record collection without repeating those operations. Partner settlement payouts remain a separate manual reconciliation flow.

## Setup

1. Install dependencies with `pnpm install`.
2. Configure the variables below in your private `.env` or deployment secrets.
3. Test the migration on an isolated database, then apply it to the intended deployment with `pnpm run migrate:deploy`.
4. Run `pnpm run build` and restart the server.
5. Register the provider callbacks below and complete sandbox checkout tests before enabling live credentials.

```dotenv
PAYMENT_BUSINESS_IDS=your-business-id
PAYMENT_PUBLIC_BASE_URL=https://api.example.com
PAYMENT_RETURN_URL=https://app.example.com/payments/result
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
SSLCOMMERZ_STORE_ID=your-sandbox-store-id
SSLCOMMERZ_STORE_PASSWORD=your-sandbox-store-password
SSLCOMMERZ_SANDBOX=true
```

Providers are optional: configure the one(s) you use. `PAYMENT_BUSINESS_IDS` is a comma-separated allowlist of businesses authorized to collect into these merchant accounts. This implementation uses one account per provider for the deployment; it does not onboard independent merchants or split funds. Do not allowlist an unrelated business. Credentials and stored customer details never appear in payment API responses. Keep the same account and sandbox/live mode for the lifetime of pending payments; use separate deployments/databases for test and live payments.

Both public URLs must be HTTPS in production. `PAYMENT_PUBLIC_BASE_URL` is the public API origin; callback paths are appended by the server. `PAYMENT_RETURN_URL` is a fixed frontend page you control. The frontend directory in this repository is empty, so the return page and checkout button need to be provided by the consuming client.

The migration adds checkout persistence columns to `commerce.Payment` and the `ONLINE_GATEWAY` payment method. It leaves existing payments intact. Do not use `db push` in place of the migration.

## API

All business routes require the existing Bearer access token, an active employee with sale permission, and assignment to the sale's active branch. Amount and currency come exclusively from the database. The strict request schema rejects client totals, payment status and redirect URLs.

| Method | Path under `/api/v1` | Purpose |
| --- | --- | --- |
| POST | `/business/:businessId/sales/:saleId/payments/checkout` | Create or reuse a checkout |
| GET | `/business/:businessId/sales/:saleId/payments` | List collections and remaining balance |
| GET | `/business/:businessId/payments/:paymentId` | Read persisted payment status |
| POST | `/business/:businessId/payments/:paymentId/refresh` | Reconcile against the provider; body `{}` |

Example checkout body (use `STRIPE` or `SSLCOMMERZ`):

```json
{
  "provider": "SSLCOMMERZ",
  "idempotencyKey": "sale-123-attempt-1",
  "customer": {
    "name": "Customer Name",
    "email": "customer@example.com",
    "phone": "01700000000",
    "address": "House 1, Road 2",
    "city": "Dhaka",
    "postcode": "1200",
    "country": "Bangladesh"
  }
}
```

Redirect the browser to `response.data.checkoutUrl` when it is present. Persist the payment ID. Repeating the same request with the same key returns the same payment; changing its body with the same key returns a conflict. Only one outstanding checkout can reserve a sale at a time, including across providers. Already successful collections are subtracted from the stored total. Draft/void sales, fully paid sales, and sales with unresolved/completed returns cannot start checkout.

The return URL includes `paymentId` and an advisory `outcome`. Those query parameters do **not** prove payment. An authenticated staff client must read or refresh the payment and show success only for `status: "SUCCEEDED"`. A browser cancellation alone never releases a reservation. There is no public customer payment-status endpoint.

Stripe currency support in this integration is deliberately limited to BDT, USD, EUR, GBP, CAD, AUD, SGD, INR and MYR, with exact two-decimal conversion; acceptance also depends on the configured Stripe account. SSLCommerz is restricted to BDT 10.00–500000.00.

## Stripe notifications

Register a **snapshot-event** webhook at:

```text
https://api.example.com/api/v1/payments/stripe/webhook
```

Subscribe to:

- `checkout.session.completed`
- `checkout.session.async_payment_succeeded`
- `checkout.session.async_payment_failed`
- `checkout.session.expired`

Copy that endpoint's signing secret into `STRIPE_WEBHOOK_SECRET`. Locally, use:

```sh
stripe listen --forward-to localhost:5000/api/v1/payments/stripe/webhook
```

Use the listener's signing secret during local testing. The route reads the raw body before JSON middleware and verifies the signature with Stripe's SDK. Completion with an unpaid session stays `PROCESSING`. Only a verified paid session becomes `SUCCEEDED`; an expired unpaid session becomes `CANCELLED`.

## SSLCommerz notifications

The server supplies these URLs when creating a session:

```text
POST /api/v1/payments/sslcommerz/ipn
POST /api/v1/payments/sslcommerz/success
POST /api/v1/payments/sslcommerz/fail
POST /api/v1/payments/sslcommerz/cancel
```

Enable IPN in the merchant dashboard with the full public IPN URL. Local testing requires a publicly reachable HTTPS tunnel. These endpoints accept form-encoded data without user authentication; the server independently calls SSLCommerz before accepting payment information. It checks the validation ID, transaction ID, amount and currency against the stored payment. Success/failure/cancel browser callbacks redirect using HTTP 303 only after provider verification/query; they never trust the submitted status.

A verified risky payment (or one missing a risk level) is held as `AUTHORIZED` with no `paidAt`; it continues reserving the balance. Review it with SSLCommerz support/dashboard and refresh after the provider reports a safe validated payment. This integration has no manual override for risk holds.

## Retries and recovery

- Notification IDs and normalized verified payload hashes prevent duplicate accounting. Payment changes and event records commit in one serializable transaction, with a sale row lock.
- Success cannot be reversed by delayed failure/expiry notifications. A later verified success is retained even after an earlier failure, preserving the truth of money received.
- If a Stripe initialization response is lost, retry the same request or refresh after 60 seconds. The persisted request and stable Stripe idempotency key recover the session. Automatic recreation stops after 23 hours to stay within the provider's idempotency retention window.
- If SSLCommerz initialization times out, keep the payment ID and refresh. The server queries the existing transaction, without initiating another charge. An unknown transaction or a failed individual attempt does not prove the hosted session is closed and does not release the reservation.
- A provider-confirmed terminal session allows a new checkout with a new idempotency key. Missing/uncertain SSLCommerz sessions and Stripe initialization older than the retry window require operator investigation with the provider; no automatic deletion, cancellation or forced retry is provided.
- Refund execution, disputes, subscriptions, multi-merchant onboarding and outgoing transfers are outside this sale-collection API.

## Verification

```sh
pnpm exec tsx --test tests/payment.test.ts
pnpm exec tsc --noEmit
pnpm exec prisma validate
pnpm run build
```

Tests mock gateway transport and database operations; they verify financial binding, duplicate events, signature validation, risk handling, access checks and retries without charging cards. Live credentials and public callback delivery must be tested separately in the provider sandbox.

For real PostgreSQL concurrency and rollback coverage, configure the existing isolated database harness (`.env.commission-test.local`, `COMMISSION_TEST_DATABASE_URL`, `COMMISSION_TEST_ALLOW_WRITES=1`). The harness refuses the application database host. Run `node scripts/commission-db.mjs migrate`, then `node scripts/commission-db.mjs test-payments`. Gateway transport is still mocked; uniquely named fixtures are retained in the isolated test database.

Provider references: [Stripe Checkout fulfillment](https://docs.stripe.com/checkout/fulfillment), [Stripe webhook signatures](https://docs.stripe.com/webhooks), [Stripe Checkout API](https://docs.stripe.com/api/checkout/sessions/create), [SSLCommerz v4 integration](https://developer.sslcommerz.com/doc/v4/index.html).
