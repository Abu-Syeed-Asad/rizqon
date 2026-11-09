/* eslint-disable @typescript-eslint/no-explicit-any */
import { StatusCodes } from "http-status-codes";
import { AppError } from "../../errors/App.error";
import { prisma } from "../../lib/prisma";
import type { ICreateBusiness, IUpdateBusiness, ISearchBusiness } from "./business.validaton";
import { Prisma, SYSTEM_USER_ROLE, type User } from "../../../prisma/generated/prisma/client";

const createBusiness = async (payload: ICreateBusiness, user:User) => {
  if (!user) {
    throw new AppError(StatusCodes.UNAUTHORIZED, "User not found");
  }

  if (user.user_role !== SYSTEM_USER_ROLE.RIZQON_CEO) {
    throw new AppError(StatusCodes.FORBIDDEN, "Only CEO system users can create a business");
  }

  const existingBusiness = await prisma.business.findUnique({
    where: {
      business_slug: payload.business_slug,
    },
    select: { id: true },
  });

  if (existingBusiness) {
    throw new AppError(
      StatusCodes.CONFLICT,
      "Business slug already exists. Choose another slug.",
    );
  }
  try {
    const firstBusiness = await prisma.$transaction(async (tx) => {
       const business = await tx.business.create({
      data: payload
       })
      if (!business) {
        throw new AppError(StatusCodes.INTERNAL_SERVER_ERROR, "business creation failde please try again ");
      }
      const branch = await tx.branch.create({
        data: {
          businessId: business.id,
          name: "Main Branch",
          branch_code: "BR00",
          address: business.address,
          phone: business.phone,
        },
        include: {
          business: true,
        },
      });
      return {
        branch
        
      }
   
    });
    return firstBusiness
    
  } catch (error :any) {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === "P2002"
    ) {
      throw new AppError(StatusCodes.CONFLICT, "Business slug already exists");
    }

    throw error;
  }
};

const updateBusiness = async (id: string, payload: IUpdateBusiness) => {
  if (!id) {
    throw new AppError(StatusCodes.NOT_FOUND, "required bisiness id ")
  }
  const isExistBusiness = await prisma.business.findUnique({
    where: {
      id
    }
  })
  if (!isExistBusiness) {
    throw new AppError(StatusCodes.NOT_FOUND,"you business not found in the data base ")
  }
  const updateBusiness = await prisma.business.update({
    where: {
      id
    },
    data:payload
  })
  if (!updateBusiness) {
   throw new AppError(StatusCodes.INTERNAL_SERVER_ERROR,"failed to update bussiness")
  }
  return updateBusiness

};

const deleteBusiness = async (id: string) => {
 if (!id) {
   throw new AppError(StatusCodes.NOT_FOUND, "required bisiness id ");
 }
 const isExistBusiness = await prisma.business.findUnique({
   where: {
     id,
   },
 });
 if (!isExistBusiness) {
   throw new AppError(
     StatusCodes.NOT_FOUND,
     "you business not found in the data base ",
   );
 }
  const deleteBusiness = await prisma.business.delete({
    where: {
      id
    }
  })
  if (!deleteBusiness) {
    throw new AppError(StatusCodes.INTERNAL_SERVER_ERROR,"failed to bussiness delete please try again ")
  }
  return deleteBusiness;
};

const getAllBusiness = async () => {
  return prisma.business.findMany({
    orderBy: [
      { createdAt: "desc" },
      { id: "asc" },
    ],
    
  });
};

const searchBusiness = async (query: ISearchBusiness) => {
  const { searchTerm } = query;
  const textMatch = { contains: searchTerm, mode: "insensitive" as const };
  return prisma.business.findMany({
    where: {
      OR: [
        { id: searchTerm },
        { business_slug: textMatch },
        { name: textMatch },
        { phone: textMatch },
        { email: textMatch },
        { legalName: textMatch },
        { registrationNumber: textMatch },
        { taxIdentificationNumber: textMatch },
      ],
    },
    orderBy: [{ createdAt: "desc" }, { id: "asc" }],
    include: {
      branch_business:true
    }
  });
};

export const businessService = {
  searchBusiness,
  getAllBusiness,
  createBusiness,
  updateBusiness,
  deleteBusiness,
};
