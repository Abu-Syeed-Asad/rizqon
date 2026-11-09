import { StatusCodes } from "http-status-codes";
import { AppError } from "../../errors/App.error.js";
import { prisma } from "../../lib/prisma.js";
import { brandValidation, type BrandParams, type CreateBrandInput, type UpdateBrandInput } from "./brand.validation.js";

const createBrand = async (payload: CreateBrandInput) => {
  if (!payload) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Brand data is required", true, "BRAND_DATA_REQUIRED");
  }
  if (!payload.businessId) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Business ID is required", true, "BUSINESS_ID_REQUIRED");
  }
  const data = brandValidation.createBrandSchema.parse(payload);
  const existingBusiness = await prisma.business.findUnique({
    where: { id: data.businessId },
    select: { id: true },
  });
  if (!existingBusiness) {
    throw new AppError(StatusCodes.NOT_FOUND, "Business not found", true, "BUSINESS_NOT_FOUND");
  }
  return prisma.brand.create({ data });
};

const updateBrand = async (params: BrandParams, payload: UpdateBrandInput) => {
  if (!params?.id) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Brand ID is required", true, "BRAND_ID_REQUIRED");
  }
  if (!payload) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Brand data is required", true, "BRAND_DATA_REQUIRED");
  }
  const { id } = brandValidation.brandParamsSchema.parse(params);
  const data = brandValidation.updateBrandSchema.parse(payload);
  const existingBrand = await prisma.brand.findUnique({ where: { id }, select: { id: true } });
  if (!existingBrand) {
    throw new AppError(StatusCodes.NOT_FOUND, "Brand not found", true, "BRAND_NOT_FOUND");
  }
  return prisma.brand.update({ where: { id }, data });
};

const deleteBrand = async (params: BrandParams) => {
  if (!params?.id) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Brand ID is required", true, "BRAND_ID_REQUIRED");
  }
  const { id } = brandValidation.brandParamsSchema.parse(params);
  const existingBrand = await prisma.brand.findUnique({ where: { id }, select: { id: true } });
  if (!existingBrand) {
    throw new AppError(StatusCodes.NOT_FOUND, "Brand not found", true, "BRAND_NOT_FOUND");
  }
  return prisma.brand.delete({ where: { id } });
};

const getAllBrands = async () => {
  return prisma.brand.findMany({ orderBy: [{ createdAt: "desc" }, { id: "asc" }] });
};

export const brandService = { createBrand, updateBrand, deleteBrand, getAllBrands };

