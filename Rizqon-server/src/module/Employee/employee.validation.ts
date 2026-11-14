import { EMPLOYEE_JOB_TITLE } from "../../../prisma/generated/prisma/enums.js";
import { z } from "zod";

const idSchema = z.cuid("Invalid ID: expected a CUID");

const createEmployeeSchema = z.object({
  businessId: idSchema,
  branchId: idSchema,
  email: z.string().trim().toLowerCase().max(254).pipe(z.email()),
  employeeCode: z.string().trim().min(1).max(50)
    .regex(/^[A-Za-z0-9]+(?:[-_][A-Za-z0-9]+)*$/, "Employee code must contain letters, numbers, hyphens or underscores"),
  jobTitle: z.enum(EMPLOYEE_JOB_TITLE),
  baseSalary: z.number().finite().min(0).default(0),
}).strict();

const updateEmployeeSchema = z.object({
  name: z.string().trim().min(2).max(150).optional(),
  phone: z.string().trim().regex(/^\+?[0-9]{7,15}$/, "Invalid phone number").optional(),
  employeeCode: z.string().trim().min(1).max(50)
    .regex(/^[A-Za-z0-9]+(?:[-_][A-Za-z0-9]+)*$/, "Employee code must contain letters, numbers, hyphens or underscores")
    .optional(),
  jobTitle: z.enum(EMPLOYEE_JOB_TITLE).optional(),
  baseSalary: z.number().finite().min(0).optional(),
  email: z.string().trim().toLowerCase().max(254).pipe(z.email()).optional(),
  isActive: z.boolean().optional(),
}).strict().refine((payload) => Object.values(payload).some((value) => value !== undefined), {
  message: "Provide at least one field to update",
});

const businessParamsSchema = z.object({ businessId: idSchema }).strict();
const employeeParamsSchema = z.object({ businessId: idSchema, id: idSchema }).strict();

export const employeeValidation = {
  createEmployeeSchema,
  updateEmployeeSchema,
  businessParamsSchema,
  employeeParamsSchema,
};

export type CreateEmployeeInput = z.output<typeof createEmployeeSchema>;
export type UpdateEmployeeInput = z.output<typeof updateEmployeeSchema>;
export type BusinessParams = z.output<typeof businessParamsSchema>;
export type EmployeeParams = z.output<typeof employeeParamsSchema>;
