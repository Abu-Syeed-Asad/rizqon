# Neon setup

The backend is linked to project `empty-bird-65932254`, branch `production`,
in organization `org-snowy-sea-85061124`. `neon.ts` declares managed Auth;
Postgres is the underlying database. `neon deploy` provisions services and
pulls environment variables; it does not host this Express server.

## Run

```powershell
npx.cmd --yes neon@latest deploy
npm.cmd run build
npm.cmd start
```

On Windows, `.cmd` avoids PowerShell's script execution-policy restriction.
Keep `.env` private. The app uses pooled `DATABASE_URL` through the existing
Prisma PostgreSQL adapter and `pg`; migrations use `DATABASE_URL_UNPOOLED`.
Prisma source schemas and migration history were restored from Git after
their deletion. Generated clients are recreated by the build.

## Managed login

`/api/v1/auth/*` forwards to `NEON_AUTH_BASE_URL`, preserving response status,
session cookies, and the browser Origin. Authentication no longer uses the
local Better Auth server or its password/session tables. Google OAuth and
authentication email settings belong in Neon, not local OAuth/SMTP variables.
Production requires email verification by OTP, with automatic sign-in after
verification and verification email on signup.

Routes:

| App route | Managed Auth route |
| --- | --- |
| POST `/api/v1/auth/create-user` | `sign-up/email` |
| POST `/api/v1/auth/verify-email` | `email-otp/verify-email` |
| POST `/api/v1/auth/resend-verify-email-otp` | `email-otp/send-verification-otp` |
| POST `/api/v1/auth/sign-in/email` | `sign-in/email` |
| GET `/api/v1/auth/get-session` | `get-session` |
| POST `/api/v1/auth/sign-out` | `sign-out` |

Auth responses now use Neon's native JSON shape rather than the old custom
`send_Response` envelope. Browser requests must include credentials. For a
future frontend, use the managed `@neondatabase/auth` client and follow its
OAuth callback/verifier flow; no frontend application exists in this checkout.

`GET /api/v1/me` checks the managed session, rejects unverified users, and
upserts the `commerce.user` profile by the managed user UUID. Inactive local
profiles remain forbidden. It does not merge accounts based on email.
The new project's commerce schema was empty; users from the previously linked
project were not copied, and its passwords/sessions were not migrated.

## Verification

```powershell
node_modules/.bin/tsc.cmd --noEmit
npm.cmd run build
node scripts/test-neon.mjs
```

The E2E script requires `.env.validation.local` for the named isolated branch
`setup-validation-20261028`. It refuses a production branch and removes only
its own randomly named fixture. It tests signup, signin, session restoration,
protected access, the Prisma/Postgres profile round trip, and signout.
The test marks only its own fixture verified directly in the isolated DB;
it does **not** verify real email delivery or OTP redemption. Those require
a real test mailbox. Browser Google OAuth also needs a separate interactive test.

The validation branch expires at `2026-10-29T18:00:00Z`. After expiry, recreate
a test branch and pull its environment before rerunning the script.
