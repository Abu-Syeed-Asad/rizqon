import assert from "node:assert/strict";
import { once } from "node:events";
import { test, mock } from "node:test";
import type { AddressInfo } from "node:net";

test("Google routes preserve cookies, validate bodies, and accept redirects", async () => {
  // Service calls are mocked: this test never signs in or changes database records.
  const { authService } = await import("../src/module/auth/auth.service.js");
  const { app } = await import("../src/app.js");
  mock.method(authService, "signInWithGoogleAccount", async () => ({
    url: "https://accounts.google.com/test",
    cookies: ["oauth_state=test; Path=/; HttpOnly"],
  }));
  mock.method(authService, "completeGoogleSignIn", async () => ({
    user: { id: "test-user" }, sessionToken: "test-session", cookies: [],
  }));
  mock.method(authService, "getSessionUser", async (headers: Headers) => ({
    authorization: headers.get("authorization"), cookie: headers.get("cookie"),
  }));
  const server = app.listen(0, "127.0.0.1");
  await once(server, "listening");
  const base = `http://127.0.0.1:${(server.address() as AddressInfo).port}/api/v1/auth`;
  try {
    for (const method of ["GET", "POST"]) {
      const start = await fetch(`${base}/sign-in-google-account`, { method, redirect: "manual" });
      assert.equal(start.status, 303);
      assert.equal(start.headers.get("location"), "https://accounts.google.com/test");
      assert.match(start.headers.get("set-cookie") ?? "", /oauth_state=test/);
      const complete = await fetch(`${base}/complete-google-sign-in`, { method });
      assert.equal(complete.status, 200);
      assert.match(complete.headers.get("set-cookie") ?? "", /sessionToken=test-session/);
      assert.equal(complete.headers.get("cache-control"), "no-store");
    }
    for (const path of ["sign-in-google-account", "complete-google-sign-in"]) {
      const invalid = await fetch(`${base}/${path}`, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ unexpected: true }),
      });
      assert.equal(invalid.status, 400);
      assert.equal((await invalid.json()).error.code, "VALIDATION_ERROR");
    }
    const session = await fetch(`${base}/get-session-user`, {
      headers: { Cookie: "sessionToken=cookie-session" },
    });
    assert.equal((await session.json()).data.authorization, "Bearer cookie-session");
    const bearer = await fetch(`${base}/get-session-user`, {
      headers: { Authorization: "Bearer explicit", Cookie: "sessionToken=cookie-session" },
    });
    assert.equal((await bearer.json()).data.authorization, "Bearer explicit");
    assert.equal((await fetch(`${base}/google-sign-in-error`)).status, 400);
    // A callback without an OAuth code must fail through Better Auth, not a 404.
    const callback = await fetch(`${base}/callback/google`, { redirect: "manual" });
    assert.notEqual(callback.status, 404);
    assert.ok(callback.status >= 300 && callback.status < 500);
  } finally {
    mock.restoreAll();
    await new Promise<void>((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
  }
});
