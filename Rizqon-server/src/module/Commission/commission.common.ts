import { createHash } from "node:crypto";
import { setTimeout } from "node:timers/promises";
import { Prisma, type EMPLOYEE_JOB_TITLE, type AUDIT_LOG_TYPE, type ENTITY_TYPE } from "../../../prisma/generated/prisma/client.js";
import { AppError } from "../../errors/App.error.js";
import { prisma } from "../../lib/prisma.js";

export type Actor = { id: string };
export type Scope = { businessId: string; employeeId: string; currency: string; businessName: string };
export type Permission = "read" | "agreement" | "settlement" | "finalize" | "payment" | "sale";
const managers: EMPLOYEE_JOB_TITLE[] = ["OWNER", "CEO", "CO_OWNER", "MANAGING_DIRECTOR", "FINANCE_MANAGER"];
const finance: EMPLOYEE_JOB_TITLE[] = [...managers, "SENIOR_ACCOUNTANT", "ACCOUNTANT"];
const permissions: Record<Permission, EMPLOYEE_JOB_TITLE[]> = {
  read: finance, agreement: managers, settlement: finance, finalize: managers, payment: finance,
  sale: [...managers, "BRANCH_MANAGER", "SALES_MANAGER", "CASHIER", "SALES_EXECUTIVE", "SALES_ASSOCIATE"],
};

export function fail(message: string, status = 409, code = "COMMISSION_CONFLICT"): never {
  throw new AppError(status, message, true, code);
}

export async function authorize(tx: Prisma.TransactionClient, actor: Actor, requestedBusinessId: string, permission: Permission): Promise<Scope> {
  if (!actor?.id) fail("Authentication required", 401, "AUTH_REQUIRED");
  const employee = await tx.employee.findFirst({
    where: { businessId: requestedBusinessId, userId: actor.id, isActive: true,
      user: { status: "ACTIVE" }, business: { Business_status: "ACTIVE" } },
    include: { business: true },
  });
  if (!employee || !permissions[permission].includes(employee.Employee_jobTitle)) {
    fail("An active employee with permission in this business is required", 403, "TENANT_PERMISSION_DENIED");
  }
  return { businessId: employee.businessId, employeeId: employee.Employee_id,
    currency: employee.business.currency, businessName: employee.business.Business_name };
}

export async function requireBranch(tx: Prisma.TransactionClient, scope: Scope, branchId: string) {
  const assignment = await tx.employeeBranch.findFirst({ where: {
    businessId: scope.businessId, employeeId: scope.employeeId, branchId,
    branch: { businessId: scope.businessId, isActive: true },
  } });
  if (!assignment) fail("Employee must be assigned to this active branch", 403, "BRANCH_PERMISSION_DENIED");
}

// No external effects in the callback: the whole transaction may be retried.
export async function transaction<T>(callback: (tx: Prisma.TransactionClient) => Promise<T>): Promise<T> {
  for (let attempt = 0; ; attempt++) {
    try {
      return await prisma.$transaction(callback, { isolationLevel: "Serializable", maxWait: 10000, timeout: 30000 });
    } catch (error) {
      const code = error instanceof Prisma.PrismaClientKnownRequestError ? error.code : undefined;
      const sqlState = error instanceof Prisma.PrismaClientKnownRequestError ? error.meta?.code : undefined;
      const rawConflict = code === "P2010" && (sqlState === "40001" || sqlState === "40P01");
      // A concurrently inserted idempotency/event key may surface as P2002 rather
      // than a serialization failure. A new transaction can read its committed row.
      // Explicit row locks report PostgreSQL serialization/deadlock codes as P2010.
      if (!rawConflict && code !== "P2034" && code !== "P2002") throw error;
      if (attempt >= 3) {
        if (rawConflict || code === "P2034") fail("The operation conflicted with another transaction; please retry", 409, "TRANSACTION_CONFLICT");
        throw error;
      }
      await setTimeout(20 * (attempt + 1));
    }
  }
}

export const tenantKey = (businessId: string, id: string) => ({ businessId_id: { businessId, id } });
export const hash = (value: unknown) => createHash("sha256").update(JSON.stringify(value)).digest("hex");
export const json = (value: unknown): Prisma.InputJsonValue => JSON.parse(JSON.stringify(value)) as Prisma.InputJsonValue;

export async function audit(tx: Prisma.TransactionClient, scope: Scope, action: AUDIT_LOG_TYPE, entityType: ENTITY_TYPE,
  entityId: string, before: unknown, after: unknown) {
  await tx.auditLog.create({ data: { businessId: scope.businessId, actorId: scope.employeeId, action, entityType, entityId,
    ...(before === undefined ? {} : { before: json(before) }), ...(after === undefined ? {} : { after: json(after) }) } });
}

export async function requirePartner(tx: Prisma.TransactionClient, businessId: string, id: string) {
  const partner = await tx.partner.findUnique({ where: tenantKey(businessId, id) });
  if (!partner || partner.kind === "SUPPLIER") fail("Commission partner not found in this business", 404, "PARTNER_NOT_FOUND");
  return partner;
}
