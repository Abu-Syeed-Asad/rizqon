import { StatusCodes } from "http-status-codes";
import { AppError } from "../../errors/App.error.js";
import { prisma } from "../../lib/prisma.js";
import { partnerValidation, type CreatePartnerInput, type UpdatePartnerInput, type PartnerParams } from "./partner.validation.js";

const requireBusiness = async (id: string, linked = false) => {
  const business = await prisma.business.findUnique({ where: { id }, select: { id: true } });
  if (!business) {
    throw new AppError(StatusCodes.NOT_FOUND, linked ? "Linked business not found" : "Business not found");
  }
};

const getPartner = async (params: PartnerParams) => {
  const { id } = partnerValidation.partnerParamsSchema.parse(params);
  const partner = await prisma.partner.findUnique({ where: { id } });
  if (!partner) {
    throw new AppError(StatusCodes.NOT_FOUND, "Partner not found");
  }
  return partner;
};

const createPartner = async (payload: CreatePartnerInput) => {
  const data = partnerValidation.createPartnerSchema.parse(payload);
  await requireBusiness(data.businessId);
  if (data.linkedBusinessId) await requireBusiness(data.linkedBusinessId, true);
  return prisma.partner.create({ data });
};

const updatePartner = async (params: PartnerParams, payload: UpdatePartnerInput) => {
  const data = partnerValidation.updatePartnerSchema.parse(payload);
  const partner = await getPartner(params);
  if (data.linkedBusinessId) await requireBusiness(data.linkedBusinessId, true);
  return prisma.partner.update({ where: { id: partner.id }, data });
};

const deletePartner = async (params: PartnerParams) => {
  const partner = await getPartner(params);
  // Existing foreign-key restrictions protect purchases and commission records.
  return prisma.partner.delete({ where: { id: partner.id } });
};

const getAllPartners = async () => prisma.partner.findMany({
  orderBy: [{ createdAt: "desc" }, { id: "asc" }],
});

export const partnerService = { createPartner, updatePartner, deletePartner, getPartner, getAllPartners };
