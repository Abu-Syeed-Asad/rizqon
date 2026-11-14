import { StatusCodes } from "http-status-codes";
import { Prisma } from "../../../prisma/generated/prisma/client.js";
import { EMPLOYEE_JOB_TITLE, SYSTEM_USER_ROLE } from "../../../prisma/generated/prisma/enums.js";
import { AppError } from "../../errors/App.error.js";
import { prisma } from "../../lib/prisma.js";
import {
  employeeValidation,
  type BusinessParams,
  type CreateEmployeeInput,
  type EmployeeParams,
  type UpdateEmployeeInput,
} from "./employee.validation.js";

type Actor = { id: string; user_role: string };

const rankForJobTitle = (jobTitle: EMPLOYEE_JOB_TITLE): number => {
  if (jobTitle === EMPLOYEE_JOB_TITLE.OWNER) return 0;
  if (jobTitle === EMPLOYEE_JOB_TITLE.CO_OWNER) return 1;
  if (jobTitle === EMPLOYEE_JOB_TITLE.MANAGING_DIRECTOR) return 2;
  if (jobTitle.endsWith("_MANAGER")) return 3;
  return 4;
};

const assertCanManageEmployee = (actor: Actor, actorJobTitle: EMPLOYEE_JOB_TITLE, targetJobTitle: EMPLOYEE_JOB_TITLE) => {
  const actorRank = actor.user_role === SYSTEM_USER_ROLE.RIZQON_CEO
    ? Math.min(rankForJobTitle(actorJobTitle), 1)
    : rankForJobTitle(actorJobTitle);

  if (rankForJobTitle(targetJobTitle) <= actorRank) {
    throw new AppError(
      StatusCodes.FORBIDDEN,
      "You can only manage employees in a lower authorization category",
      true,
      "EMPLOYEE_HIERARCHY_FORBIDDEN",
    );
  }
};

const requireBusinessEmployee = async (
  tx: Prisma.TransactionClient,
  businessId: string,
  userId: string,
) => {
  const actorEmployee = await tx.employee.findUnique({
    where: { businessId_userId: { businessId, userId } },
    select: { Employee_jobTitle: true, isActive: true },
  });
  if (!actorEmployee?.isActive) {
    throw new AppError(
      StatusCodes.FORBIDDEN,
      "You are not an active employee of this business",
      true,
      "BUSINESS_EMPLOYEE_REQUIRED",
    );
  }
  return actorEmployee;
};

const createEmployee = async (actor: Actor, payload: CreateEmployeeInput) => {
  const data = employeeValidation.createEmployeeSchema.parse(payload);

  return prisma.$transaction(async (tx) => {
    const business = await tx.business.findUnique({
      where: { id: data.businessId },
      select: { id: true },
    });
    if (!business) {
      throw new AppError(StatusCodes.NOT_FOUND, "Business not found", true, "BUSINESS_NOT_FOUND");
    }

    const actorEmployee = await requireBusinessEmployee(tx, data.businessId, actor.id);
    assertCanManageEmployee(actor, actorEmployee.Employee_jobTitle, data.jobTitle);

    const user = await tx.user.findUnique({
      where: { email: data.email },
      select: { id: true, name: true, phone: true, email: true, user_role: true, status: true },
    });
    if (!user) {
      throw new AppError(StatusCodes.NOT_FOUND, "This user does not exist in the system", true, "SYSTEM_USER_NOT_FOUND");
    }
    if (user.user_role !== SYSTEM_USER_ROLE.RIZQON_USER) {
      throw new AppError(
        StatusCodes.BAD_REQUEST,
        "Only a Rizqon user account can be added as a business employee",
        true,
        "INVALID_SYSTEM_USER_ROLE",
      );
    }
    if (user.status !== "ACTIVE") {
      throw new AppError(StatusCodes.BAD_REQUEST, "The system user account is not active", true, "SYSTEM_USER_INACTIVE");
    }
    if (!user.phone) {
      throw new AppError(StatusCodes.BAD_REQUEST, "The system user must have a phone number", true, "EMPLOYEE_PHONE_REQUIRED");
    }

    const branch = await tx.branch.findUnique({
      where: { businessId_id: { businessId: data.businessId, id: data.branchId } },
      select: { id: true, isActive: true },
    });
    if (!branch) {
      throw new AppError(
        StatusCodes.NOT_FOUND,
        "Branch not found in this business",
        true,
        "BRANCH_NOT_FOUND",
      );
    }
    if (!branch.isActive) {
      throw new AppError(
        StatusCodes.BAD_REQUEST,
        "Cannot assign an employee to an inactive branch",
        true,
        "BRANCH_INACTIVE",
      );
    }

    const existingEmployee = await tx.employee.findUnique({
      where: { businessId_userId: { businessId: data.businessId, userId: user.id } },
      select: { Employee_id: true },
    });
    if (existingEmployee) {
      throw new AppError(
        StatusCodes.CONFLICT,
        "This user is already included in the business",
        true,
        "USER_ALREADY_IN_BUSINESS",
      );
    }

    const existingCode = await tx.employee.findUnique({
      where: { businessId_employeeCode: { businessId: data.businessId, employeeCode: data.employeeCode } },
      select: { Employee_id: true },
    });
    if (existingCode) {
      throw new AppError(StatusCodes.CONFLICT, "Employee code already exists in this business", true, "EMPLOYEE_CODE_EXISTS");
    }

    const employee = await tx.employee.create({
      data: {
        businessId: data.businessId,
        userId: user.id,
        employeeCode: data.employeeCode,
        Employee_name: user.name,
        Employee_phone: user.phone,
        Employee_email: user.email,
        Employee_jobTitle: data.jobTitle,
        Employee_baseSalary: data.baseSalary,
      },
      include: { user: { select: { id: true, name: true, email: true } } },
    });

    await tx.employeeBranch.create({
      data: {
        businessId: data.businessId,
        employeeId: employee.Employee_id,
        branchId: branch.id,
      },
    });

    const branchAssignments = await tx.employeeBranch.findMany({
      where: { businessId: data.businessId, employeeId: employee.Employee_id },
      include: { branch: true },
      orderBy: { createdAt: "asc" },
    });

    return { ...employee, employeeBranch_employee: branchAssignments };
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
};

const getAllEmployees = async (actor: Actor, params: BusinessParams) => {
  const { businessId } = employeeValidation.businessParamsSchema.parse(params);
  return prisma.$transaction(async (tx) => {
    await requireBusinessEmployee(tx, businessId, actor.id);
    return tx.employee.findMany({
      where: { businessId, isActive: true },
      orderBy: [{ createdAt: "desc" }, { Employee_id: "asc" }],
      include: { user: { select: { id: true, name: true, email: true } } },
    });
  });
};

const getEmployee = async (actor: Actor, params: EmployeeParams) => {
  const { businessId, id } = employeeValidation.employeeParamsSchema.parse(params);
  return prisma.$transaction(async (tx) => {
    const actorEmployee = await requireBusinessEmployee(tx, businessId, actor.id);
    const target = await tx.employee.findFirst({
      where: { businessId, Employee_id: id, isActive: true },
      select: { Employee_jobTitle: true, userId: true },
    });
    if (!target) {
      throw new AppError(StatusCodes.NOT_FOUND, "Employee not found in this business", true, "EMPLOYEE_NOT_FOUND");
    }
    if (target.userId !== actor.id) {
      assertCanManageEmployee(actor, actorEmployee.Employee_jobTitle, target.Employee_jobTitle);
    }

    const employee = await tx.employee.findFirst({
      where: { businessId, Employee_id: id, isActive: true },
      include: {
        business: true,
        user: true,
        employeeBranch_employee: { include: { branch: true } },
        stockMovement_actor: true,
        cart_creator: true,
        sale_cashier: true,
        purchase_creator: true,
        payment_recorder: true,
        saleReturn_processor: true,
        expense_employee: true,
        expense_creator: true,
        commissionSettlement_creator: true,
        auditLog_actor: true,
      },
    });
    if (!employee) {
      throw new AppError(StatusCodes.NOT_FOUND, "Employee not found in this business", true, "EMPLOYEE_NOT_FOUND");
    }
    return employee;
  });
};

const updateEmployee = async (actor: Actor, params: EmployeeParams, payload: UpdateEmployeeInput) => {
  const { businessId, id } = employeeValidation.employeeParamsSchema.parse(params);
  const data = employeeValidation.updateEmployeeSchema.parse(payload);

  return prisma.$transaction(async (tx) => {
    const actorEmployee = await requireBusinessEmployee(tx, businessId, actor.id);
    const employee = await tx.employee.findFirst({
      where: { businessId, Employee_id: id },
      select: {
        Employee_id: true,
        Employee_jobTitle: true,
        employeeCode: true,
        Employee_phone: true,
        Employee_email: true,
        userId: true,
      },
    });
    if (!employee) {
      throw new AppError(StatusCodes.NOT_FOUND, "Employee not found in this business", true, "EMPLOYEE_NOT_FOUND");
    }

    const isSelf = employee.userId === actor.id;
    if (isSelf) {
      if (Object.keys(data).some((field) => field !== "name" && field !== "phone")) {
        throw new AppError(
          StatusCodes.FORBIDDEN,
          "You can only update your own name and phone number",
          true,
          "SELF_UPDATE_FIELDS_FORBIDDEN",
        );
      }
    } else {
      assertCanManageEmployee(actor, actorEmployee.Employee_jobTitle, employee.Employee_jobTitle);
      if (data.jobTitle) {
        assertCanManageEmployee(actor, actorEmployee.Employee_jobTitle, data.jobTitle);
      }
    }

    if (data.employeeCode && data.employeeCode !== employee.employeeCode) {
      const codeOwner = await tx.employee.findUnique({
        where: { businessId_employeeCode: { businessId, employeeCode: data.employeeCode } },
        select: { Employee_id: true },
      });
      if (codeOwner && codeOwner.Employee_id !== employee.Employee_id) {
        throw new AppError(StatusCodes.CONFLICT, "Employee code already exists in this business", true, "EMPLOYEE_CODE_EXISTS");
      }
    }

    if (data.email) {
      const emailOwner = await tx.user.findUnique({
        where: { email: data.email },
        select: { id: true },
      });
      if (emailOwner && emailOwner.id !== employee.userId) {
        throw new AppError(StatusCodes.CONFLICT, "Email already belongs to another system user", true, "SYSTEM_USER_EMAIL_EXISTS");
      }
    }

    if (data.phone && employee.userId) {
      const phoneOwner = await tx.user.findUnique({
        where: { phone: data.phone },
        select: { id: true },
      });
      if (phoneOwner && phoneOwner.id !== employee.userId) {
        throw new AppError(StatusCodes.CONFLICT, "Phone number already belongs to another system user", true, "SYSTEM_USER_PHONE_EXISTS");
      }
    }

    const employeeData: Prisma.EmployeeUpdateInput = {};
    const userData: Prisma.UserUpdateInput = {};
    if (data.name !== undefined) {
      employeeData.Employee_name = data.name;
      userData.name = data.name;
    }
    if (data.phone !== undefined) {
      employeeData.Employee_phone = data.phone;
      userData.phone = data.phone;
      if (data.phone !== employee.Employee_phone) userData.phone_verified_at = null;
    }
    if (data.employeeCode !== undefined) employeeData.employeeCode = data.employeeCode;
    if (data.jobTitle !== undefined) employeeData.Employee_jobTitle = data.jobTitle;
    if (data.baseSalary !== undefined) employeeData.Employee_baseSalary = data.baseSalary;
    if (data.email !== undefined) {
      employeeData.Employee_email = data.email;
      userData.email = data.email;
      if (data.email !== employee.Employee_email) {
        userData.emailVerified = false;
        userData.email_verified_at = null;
      }
    }
    if (data.isActive !== undefined) employeeData.isActive = data.isActive;

    if (employee.userId && Object.keys(userData).length > 0) {
      await tx.user.update({ where: { id: employee.userId }, data: userData });
    }

    return tx.employee.update({
      where: { Employee_id: employee.Employee_id },
      data: employeeData,
      include: { user: { select: { id: true, name: true, email: true } } },
    });
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
};

const deleteEmployee = async (actor: Actor, params: EmployeeParams) => {
  const { businessId, id } = employeeValidation.employeeParamsSchema.parse(params);
  return prisma.$transaction(async (tx) => {
    const actorEmployee = await requireBusinessEmployee(tx, businessId, actor.id);
    const employee = await tx.employee.findFirst({
      where: { businessId, Employee_id: id, isActive: true },
      select: { Employee_id: true, Employee_jobTitle: true },
    });
    if (!employee) {
      throw new AppError(StatusCodes.NOT_FOUND, "Employee not found in this business", true, "EMPLOYEE_NOT_FOUND");
    }
    assertCanManageEmployee(actor, actorEmployee.Employee_jobTitle, employee.Employee_jobTitle);

    return tx.employee.update({
      where: { Employee_id: employee.Employee_id, businessId },
      data: { isActive: false },
    });
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
};

export const employeeService = {
  createEmployee,
  getAllEmployees,
  getEmployee,
  updateEmployee,
  deleteEmployee
};
