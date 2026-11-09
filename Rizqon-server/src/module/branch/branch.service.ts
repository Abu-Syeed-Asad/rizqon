import { StatusCodes } from "http-status-codes";
import { AppError } from "../../errors/App.error.js";
import { prisma } from "../../lib/prisma.js";
import { branchValidation, type BranchParams, type CreateBranchInput, type UpdateBranchInput } from "./branch.validation.js";

const createBranch = async (payload: CreateBranchInput) => {
  if (!payload) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Branch data is required", true, "BRANCH_DATA_REQUIRED");
  }
  if (!payload.businessId) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Business ID is required", true, "BUSINESS_ID_REQUIRED");
  }
  const data = branchValidation.createBranchSchema.parse(payload);
  const existingBusiness = await prisma.business.findUnique({
    where: { id: data.businessId },
    select: { id: true },
  });
  if (!existingBusiness) {
    throw new AppError(StatusCodes.NOT_FOUND, "Business not found", true, "BUSINESS_NOT_FOUND");
  }
  return prisma.branch.create({ data });
};

const updateBranch = async (params: BranchParams, payload: UpdateBranchInput) => {
  if (!params?.id) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Branch ID is required", true, "BRANCH_ID_REQUIRED");
  }
  if (!payload) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Branch data is required", true, "BRANCH_DATA_REQUIRED");
  }
  const { id } = branchValidation.branchParamsSchema.parse(params);
  const data = branchValidation.updateBranchSchema.parse(payload);
  const existingBranch = await prisma.branch.findUnique({ where: { id }, select: { id: true } });
  if (!existingBranch) {
    throw new AppError(StatusCodes.NOT_FOUND, "Branch not found", true, "BRANCH_NOT_FOUND");
  }
  return prisma.branch.update({ where: { id }, data });
};

const deleteBranch = async (params: BranchParams) => {
  if (!params?.id) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Branch ID is required", true, "BRANCH_ID_REQUIRED");
  }
  const { id } = branchValidation.branchParamsSchema.parse(params);
  const existingBranch = await prisma.branch.findUnique({ where: { id }, select: { id: true } });
  if (!existingBranch) {
    throw new AppError(StatusCodes.NOT_FOUND, "Branch not found", true, "BRANCH_NOT_FOUND");
  }
  return prisma.branch.delete({ where: { id } });
};

const getAllBranches = async () => {
  return prisma.branch.findMany({ orderBy: [{ createdAt: "desc" }, { id: "asc" }] });
};

export const branchService = { createBranch, updateBranch, deleteBranch, getAllBranches };


