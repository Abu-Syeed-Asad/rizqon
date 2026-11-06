# Test Google sign-in with Postman

Use `http://localhost:5000` as `baseUrl` if running on the default port. Use the same hostname throughout; do not mix `localhost` and `127.0.0.1`.

## Configuration

Set `BETTER_AUTH_URL` to your backend origin, and configure `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` for a Google Web application OAuth client. Restart the server after changes.

In Google's Authorized redirect URIs, register exactly:

```text
http://localhost:5000/api/v1/auth/callback/google
```

Use your actual backend origin if different. If the Google consent app is in testing mode, use an allowed test account.

## Recommended browser + Postman flow

1. Open `http://localhost:5000/api/v1/auth/sign-in-google-account` in your browser. This GET alias starts the same flow as POST and stores the OAuth cookies in the browser.
2. Complete Google consent. Google redirects to `/api/v1/auth/callback/google`, where Better Auth verifies state and creates the session. It then redirects to GET `/api/v1/auth/complete-google-sign-in`. Expect a successful JSON response containing your user.
3. In browser developer tools, open Application/Storage > Cookies for the backend. Copy the `sessionToken` cookie into Postman's Cookies manager for `localhost`, with path `/`. Treat it as a password; do not share it.
4. Send `GET {{baseUrl}}/api/v1/auth/get-session-user` with no body. Postman sends the cookie; expect HTTP 200 and `data.session`.
5. Send `POST {{baseUrl}}/api/v1/auth/complete-google-sign-in` with JSON `{}` and `Content-Type: application/json`. Expect HTTP 200 and the user. This endpoint requires an existing session; it does not exchange Google's authorization code.
6. Send `GET {{baseUrl}}/api/v1/auth/google-sign-in-error`. Expect HTTP 400 and the friendly failure message. This is an error landing route.

For session lookup or completion, you may instead use Authorization > Bearer Token with the Better Auth session token. Do not use a Google access token, Google authorization code, email address, or the application's custom JWT access token.

## Test the POST start route

Send `POST {{baseUrl}}/api/v1/auth/sign-in-google-account`, body `{}`, with automatic redirect following disabled in the request settings. Expect HTTP 303, a Google URL in `Location`, and OAuth `Set-Cookie` headers.

Opening that Location in another browser is insufficient by itself: the browser must also have the OAuth state cookies from this request before Google redirects back. Use a cookie-synchronization tool or transfer those cookies to the same backend host in the browser, preserving their values. The recommended browser flow above avoids this transfer.

## Negative cases

- Empty Postman cookie jar and no Authorization header: session lookup and completion return 401.
- Unexpected JSON fields on either Google POST route: 400 `VALIDATION_ERROR`.
- Missing Google credentials: starting sign-in returns 503.
- A Google callback without valid OAuth state fails; do not call the callback manually to create a session.

Local verification: `node --import tsx --test tests/google-auth.test.ts`. Service calls are mocked; successful real Google consent requires configured credentials and a browser.
