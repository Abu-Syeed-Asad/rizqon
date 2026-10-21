# Authentication API

Authentication is provided by Better Auth at `/api/v1/auth`. Request bodies are
validated by Better Auth's Zod schemas. Browser requests should use
`credentials: "include"` so the HTTP-only session cookie is sent.

## Email and password

| Action | Method | Endpoint | Body |
| --- | --- | --- | --- |
| Register | POST | `/api/v1/auth/create-user` (or `/api/v1/auth/sign-up/email`) | `{ "name", "email", "password" }` |
| Verify email | POST | `/api/v1/auth/verify-email` | `{ "email", "otp" }` |
| Sign in / login | POST | `/api/v1/auth/sign-in` (or `/api/v1/auth/sign-in/email`) | `{ "email", "password", "rememberMe"? }` |
| Sign out / logout | POST | `/api/v1/auth/sign-out` | none |
| Current session | GET | `/api/v1/auth/get-session` | none |

Passwords must contain between 8 and 128 characters. An email/password account
cannot sign in until its email is verified.

### Postman / Thunder Client

Send signup as a JSON `POST`, not by opening the endpoint in a browser tab:

```http
POST http://localhost:5000/api/v1/auth/create-user
Content-Type: application/json
Origin: http://localhost:3000

{
  "name": "Test User",
  "email": "test@example.com",
  "password": "password123"
}
```

If the client has retained an old Better Auth cookie, either keep the trusted
`Origin` header above or clear the client's cookies. Do not disable Better
Auth's origin/CSRF checks to make API-testing tools work.

## Email verification with OTP

1. Send or resend an OTP with `POST /api/v1/auth/email-otp/send-verification-otp`:

   ```json
   { "email": "user@example.com", "type": "email-verification" }
   ```

2. Verify it with `POST /api/v1/auth/verify-email` (or the native
   `/api/v1/auth/email-otp/verify-email` endpoint):

   ```json
   { "email": "user@example.com", "otp": "123456" }
   ```

The OTP expires after five minutes, is stored hashed, and permits three failed
attempts. Successful verification creates the database session and returns the
signed HTTP-only session cookie. Send subsequent browser requests with
`credentials: "include"`.

## Forgot/reset password with OTP

1. Request an OTP with `POST /api/v1/auth/email-otp/request-password-reset`:

   ```json
   { "email": "user@example.com" }
   ```

2. Reset with `POST /api/v1/auth/email-otp/reset-password`:

   ```json
   {
     "email": "user@example.com",
     "otp": "123456",
     "password": "new-password"
   }
   ```

Successful password reset revokes the user's existing sessions. The request
endpoint intentionally returns a generic response so callers cannot enumerate
registered email addresses.

## Google login

Start OAuth with `POST /api/v1/auth/sign-in/social`:

```json
{
  "provider": "google",
  "callbackURL": "http://localhost:3000/auth/callback"
}
```

Register this backend callback in Google Cloud for local development:
`http://localhost:5000/api/v1/auth/callback/google`. Add the production equivalent
when deploying. The application callback origin must be in `trustedOrigins`.

## Profile

Both endpoints require a session cookie or Better Auth bearer session token.

| Action | Method | Endpoint | Body |
| --- | --- | --- | --- |
| Read profile | GET | `/api/users/me` | none |
| Update profile | PATCH | `/api/users/me` | `{ "name"?, "image"? }` |

Profile updates use a strict Zod schema. Unknown properties are rejected.

## JWT access

Call `GET /api/v1/auth/access-token` (or `/api/v1/auth/token`) with an authenticated
session to receive a 15-minute
EdDSA JWT for the `rizqon-api` audience. Verification keys are published at
`GET /api/v1/auth/jwks`. JWTs are intended for APIs and external services; browser
login continues to use the safer HTTP-only session cookie.

Before starting the server with JWT support, apply
`prisma/sql/add_better_auth_jwks.sql` to the database once.
