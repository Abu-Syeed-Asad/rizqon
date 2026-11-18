import { StatusCodes } from "http-status-codes";
import {
  Prisma,
  EMPLOYEE_JOB_TITLE,
} from "../../../prisma/generated/prisma/client.js";
import { AppError } from "../../errors/App.error.js";
import { prisma } from "../../lib/prisma.js";
import {
  productValidation,
  type DeleteProductInput,
  type ProductParams,
  type BranchParams,
  type ProductMutationParams,
  type CreateProductInput,
  type UpdateProductInput,
} from "./product.validation.js";

type Actor = { id: string; email: string };
const allowedTitles: EMPLOYEE_JOB_TITLE[] = [
  EMPLOYEE_JOB_TITLE.INVENTORY_MANAGER,
  EMPLOYEE_JOB_TITLE.INVENTORY_OFFICER,
  EMPLOYEE_JOB_TITLE.WAREHOUSE_MANAGER,
];

const authorize = async (
  tx: Prisma.TransactionClient,
  actor: Actor,
  requestedBusinessId: string,
  branchId: string,
) => {
  if (!actor?.id || !actor.email)
    throw new AppError(StatusCodes.UNAUTHORIZED, "Authentication required");
  // Email comes from the authenticated database user, never from the request body.
  const employees = await tx.employee.findMany({
    where: {
      Employee_email: { equals: actor.email.trim(), mode: "insensitive" },
      userId: actor.id,
    },
    select: {
      Employee_id: true,
      businessId: true,
      Employee_jobTitle: true,
      isActive: true,
    },
  });
  const employee = employees.find(
    (record) => record.businessId === requestedBusinessId,
  );
  if (
    !employee?.isActive ||
    !allowedTitles.includes(employee.Employee_jobTitle)
  ) {
    throw new AppError(
      StatusCodes.FORBIDDEN,
      "Business ID must match an active inventory manager, inventory officer or warehouse manager employee record",
    );
  }
  const { businessId, Employee_id: employeeId } = employee;
  const business = await tx.business.findUnique({
    where: { id: businessId },
    select: { id: true },
  });
  if (!business)
    throw new AppError(StatusCodes.NOT_FOUND, "Business not found");
  const assignment = await tx.employeeBranch.findFirst({
    where: { businessId, employeeId, branchId, branch: { businessId, isActive: true } },
    select: { branchId: true },
    orderBy: { id: "asc" },
  });
  if (!assignment)
    throw new AppError(
      StatusCodes.FORBIDDEN,
      "Employee must be assigned to the requested active branch in this business",
    );
  return { businessId, employeeId, branchId: assignment.branchId };
};

const checkReferences = async (
  tx: Prisma.TransactionClient,
  businessId: string,
  data: Omit<UpdateProductInput, "businessId">,
) => {
  if (data.categoryId !== undefined) {
    const category = await tx.category.findUnique({
      where: { businessId_id: { businessId, id: data.categoryId } },
      select: { id: true, isActive: true },
    });
    if (!category?.isActive)
      throw new AppError(
        StatusCodes.BAD_REQUEST,
        "An active category in this business is required",
      );
  }
  if (data.brandId) {
    const brand = await tx.brand.findUnique({
      where: { businessId_id: { businessId, id: data.brandId } },
      select: { id: true },
    });
    if (!brand)
      throw new AppError(
        StatusCodes.BAD_REQUEST,
        "Brand not found in this business",
      );
  }
};

const createProduct = async (actor: Actor, params: BranchParams, payload: CreateProductInput) => {
  const { branchId } = productValidation.branchParamsSchema.parse(params);
  const data = productValidation.createProductSchema.parse(payload);
  return prisma.$transaction(
    async (tx) => {
      const scope = await authorize(tx, actor, data.businessId, branchId);
      await checkReferences(tx, scope.businessId, data);
      return tx.product.create({
        data: { ...data, businessId: scope.businessId },
      });
    },
    { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
  );
};

const updateProduct = async (
  actor: Actor,
  params: ProductMutationParams,
  payload: UpdateProductInput,
) => {
  const { id, branchId } = productValidation.mutationParamsSchema.parse(params);
  const { businessId, ...data } =
    productValidation.updateProductSchema.parse(payload);
  return prisma.$transaction(
    async (tx) => {
      const scope = await authorize(tx, actor, businessId, branchId);
      const where = { businessId_id: { businessId: scope.businessId, id } };
      if (!(await tx.product.findUnique({ where, select: { id: true } }))) {
        throw new AppError(
          StatusCodes.NOT_FOUND,
          "Product not found in this business",
        );
      }
      await checkReferences(tx, scope.businessId, data);
      return tx.product.update({ where, data });
    },
    { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
  );
};

const deleteProduct = async (
  actor: Actor,
  params: ProductMutationParams,
  payload: DeleteProductInput,
) => {
  const { id, branchId } = productValidation.mutationParamsSchema.parse(params);
  const { businessId } = productValidation.deleteProductSchema.parse(payload);
  return prisma.$transaction(
    async (tx) => {
      const scope = await authorize(tx, actor, businessId, branchId);
      const where = { businessId_id: { businessId: scope.businessId, id } };
      if (!(await tx.product.findUnique({ where, select: { id: true } }))) {
        throw new AppError(
          StatusCodes.NOT_FOUND,
          "Product not found in this business",
        );
      }
      // Foreign-key restrictions prevent deleting products with dependent variants.
      return tx.product.delete({ where });
    },
    { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
  );
};

const getProduct = async (params: ProductParams) => {
  const { id } = productValidation.productParamsSchema.parse(params);
  const product = await prisma.product.findUnique({ where: { id, isActive: true } });
  if (!product) {
    throw new AppError(StatusCodes.NOT_FOUND, "Product not found");
  }
  return product;
};

const getAllProducts = async () => prisma.product.findMany({
  where: { isActive: true },
  orderBy: [{ createdAt: "desc" }, { id: "asc" }],
});

export const productService = { createProduct, updateProduct, deleteProduct, getProduct, getAllProducts };
