# Rizqon server

Express backend with Prisma/PostgreSQL and managed Neon Auth.
See [NEON_SETUP.md](NEON_SETUP.md) for project configuration, auth routes,
environment variables, migration notes, and end-to-end testing.

```powershell
npm.cmd run build
npm.cmd start
```

The server starts at http://localhost:5000 by default. `neon deploy` provisions
backend services and pulls environment variables; deploy the Express process
on a Node.js host separately. For development, use `pnpm.cmd run dev`.
