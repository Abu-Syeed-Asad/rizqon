import assert from "node:assert/strict";
import { test } from "node:test";
import { prisma } from "../src/lib/prisma.js";
import { employeeService } from "../src/module/Employee/employee.service.js";
import { employeeValidation } from "../src/module/Employee/employee.validation.js";

const businessId = "cm12345678901234567890123";
const id = "cm12345678901234567890124";
const branchId = "cm12345678901234567890125";
const actor = { id: "manager-user", user_role: "RIZQON_USER" };

test("employee updates accept a branch assignment and reject invalid IDs", () => {
  assert.deepEqual(employeeValidation.updateEmployeeSchema.parse({ branchId }), { branchId });
  assert.equal(employeeValidation.updateEmployeeSchema.safeParse({ branchId: "invalid" }).success, false);
});

test("employee branch changes are scoped, authorized, and included in reads and writes", async () => {
  const original = prisma.$transaction;
  const writes: { operation: string; args: unknown }[] = [];
  let branch: { id: string; isActive: boolean } | null = { id: branchId, isActive: true };
  let self = false;
  let targetTitle = "CASHIER";
  const target = () => ({ Employee_id: id, Employee_jobTitle: targetTitle, userId: self ? actor.id : "employee-user" });
  const tx = {
    employee: {
      findUnique: async () => ({ Employee_jobTitle: "OWNER", isActive: true }),
      findFirst: async () => target(),
      findMany: async (args: unknown) => { writes.push({ operation: "list", args }); return []; },
      update: async (args: unknown) => { writes.push({ operation: "update", args }); return target(); },
    },
    branch: {
      findUnique: async (args: unknown) => {
        assert.deepEqual(args, { where: { businessId_id: { businessId, id: branchId } }, select: { id: true, isActive: true } });
        return branch;
      },
    },
    employeeBranch: {
      deleteMany: async (args: unknown) => { writes.push({ operation: "remove", args }); return { count: 1 }; },
      upsert: async (args: unknown) => { writes.push({ operation: "assign", args }); return {}; },
    },
  };
  prisma.$transaction = (async (callback: (client: typeof tx) => unknown) => callback(tx)) as typeof prisma.$transaction;
  try {
    await employeeService.updateEmployee(actor, { businessId, id }, { branchId });
    assert.deepEqual(writes.map(write => write.operation), ["remove", "assign", "update"]);
    assert.deepEqual(writes[0].args, { where: { businessId, employeeId: id, branchId: { not: branchId } } });
    assert.deepEqual(writes[1].args, {
      where: { businessId_employeeId_branchId: { businessId, employeeId: id, branchId } },
      create: { businessId, employeeId: id, branchId }, update: {},
    });
    assert.ok((writes[2].args as { include: { employeeBranch_employee: unknown } }).include.employeeBranch_employee);
    writes.length = 0;
    await employeeService.updateEmployee(actor, { businessId, id }, { baseSalary: 100 });
    assert.deepEqual(writes.map(write => write.operation), ["update"]);
    writes.length = 0;
    branch = null;
    await assert.rejects(employeeService.updateEmployee(actor, { businessId, id }, { branchId }), /Branch not found/);
    branch = { id: branchId, isActive: false };
    await assert.rejects(employeeService.updateEmployee(actor, { businessId, id }, { branchId }), /inactive branch/);
    branch.isActive = true;
    self = true;
    await assert.rejects(employeeService.updateEmployee(actor, { businessId, id }, { branchId }), /own name and phone/);
    self = false;
    targetTitle = "OWNER";
    await assert.rejects(employeeService.updateEmployee(actor, { businessId, id }, { branchId }), /lower authorization/);
    await assert.rejects(employeeService.deleteEmployee(actor, { businessId, id }), /lower authorization/);
    assert.equal(writes.length, 0);
    targetTitle = "CASHIER";
    await employeeService.deleteEmployee(actor, { businessId, id });
    assert.deepEqual(writes.map(write => write.operation), ["remove", "update"]);
    assert.deepEqual(writes[0].args, { where: { businessId, employeeId: id } });
    assert.deepEqual((writes[1].args as { data: unknown }).data, { isActive: false });
    writes.length = 0;
    await employeeService.getAllEmployees(actor, { businessId });
    assert.ok((writes[0].args as { include: { employeeBranch_employee: unknown } }).include.employeeBranch_employee);
  } finally {
    prisma.$transaction = original;
  }
});
