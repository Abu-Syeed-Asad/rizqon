import { StatusCodes } from "http-status-codes";
import { Prisma } from "../../../prisma/generated/prisma/client.js";
import { AppError } from "../../errors/App.error.js";
import { prisma } from "../../lib/prisma.js";
import { categoryValidation, type CategoryParams, type CreateCategoryInput, type UpdateCategoryInput } from "./category.validation.js";

const createCategory = async (payload: CreateCategoryInput) => {
  if (!payload) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Category data is required", true, "CATEGORY_DATA_REQUIRED");
  }
  if (!payload.businessId) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Business ID is required", true, "BUSINESS_ID_REQUIRED");
  }
  const data = categoryValidation.createCategorySchema.parse(payload);
  const existingBusiness = await prisma.business.findUnique({
    where: { id: data.businessId },
    select: { id: true },
  });
  if (!existingBusiness) {
    throw new AppError(StatusCodes.NOT_FOUND, "Business not found", true, "BUSINESS_NOT_FOUND");
  }
  if (data.parentId) {
    const parent = await prisma.category.findUnique({
      where: { businessId_id: { businessId: data.businessId, id: data.parentId } },
      select: { id: true },
    });
    if (!parent) {
      throw new AppError(StatusCodes.NOT_FOUND, "Parent category not found in this business", true, "PARENT_CATEGORY_NOT_FOUND");
    }
  }
  return prisma.category.create({ data });
};

const updateCategory = async (params: CategoryParams, payload: UpdateCategoryInput) => {
  if (!params?.id) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Category ID is required", true, "CATEGORY_ID_REQUIRED");
  }
  if (!payload) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Category data is required", true, "CATEGORY_DATA_REQUIRED");
  }
  const { id } = categoryValidation.categoryParamsSchema.parse(params);
  const data = categoryValidation.updateCategorySchema.parse(payload);
  // Serializable reads and writes prevent concurrent reparenting from creating a cycle.
  return prisma.$transaction(async (tx) => {
    const existingCategory = await tx.category.findUnique({ where: { id }, select: { id: true, businessId: true } });
    if (!existingCategory) {
      throw new AppError(StatusCodes.NOT_FOUND, "Category not found", true, "CATEGORY_NOT_FOUND");
    }
    const visited = new Set<string>([id]);
    let parentId = data.parentId;
    while (parentId) {
      if (visited.has(parentId)) {
        throw new AppError(StatusCodes.CONFLICT, "A category cannot be its own ancestor", true, "CATEGORY_PARENT_CYCLE");
      }
      visited.add(parentId);
      const parent = await tx.category.findUnique({
        where: { businessId_id: { businessId: existingCategory.businessId, id: parentId } },
        select: { parentId: true },
      });
      if (!parent) {
        throw new AppError(StatusCodes.NOT_FOUND, "Parent category not found in this business", true, "PARENT_CATEGORY_NOT_FOUND");
      }
      parentId = parent.parentId;
    }
    return tx.category.update({ where: { id }, data });
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
};

const deleteCategory = async (params: CategoryParams) => {
  if (!params?.id) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Category ID is required", true, "CATEGORY_ID_REQUIRED");
  }
  const { id } = categoryValidation.categoryParamsSchema.parse(params);
  const existingCategory = await prisma.category.findUnique({ where: { id }, select: { id: true } });
  if (!existingCategory) {
    throw new AppError(StatusCodes.NOT_FOUND, "Category not found", true, "CATEGORY_NOT_FOUND");
  }
  return prisma.category.delete({ where: { id } });
};

const getAllCategories = async () => {
  return prisma.category.findMany({ orderBy: [{ createdAt: "desc" }, { id: "asc" }] });
};

const getCategoryById = async (params: CategoryParams) => {
  const { id } = categoryValidation.categoryParamsSchema.parse(params);
  const category = await prisma.category.findUnique({ where: { id } });
  if (!category) {
    throw new AppError(StatusCodes.NOT_FOUND, "Category not found", true, "CATEGORY_NOT_FOUND");
  }
  return category;
};

export const categoryService = { createCategory, updateCategory, deleteCategory, getAllCategories, getCategoryById };



