import { StatusCodes } from "http-status-codes";
import { AppError } from "../../errors/App.error";
import { prisma } from "../../lib/prisma";
import {  type ICreateBusiness, type IUpdateBusiness, type ISearchBusiness } from "./business.validaton";
import { EMPLOYEE_JOB_TITLE,  } from "../../../prisma/generated/prisma/client";






const createBusiness = async (payload: ICreateBusiness) => {
    const checkBusinessinIntheSystem = await prisma.business.findFirst({
      where: {
        business_slug: payload.business.business_slug,
      },
    });
    if (checkBusinessinIntheSystem) {
      throw new AppError(
        StatusCodes.CONFLICT,
        "Already Exist Business in the System ",
      );
  }
  const checkSystemUser = await prisma.user.findUnique({
    where: {
      email: payload.employee.Employee_email
    },
  });
  if (!checkSystemUser) {
  throw new AppError (StatusCodes.NOT_FOUND,"This Email User Not Exist in Our system ")
  };
  if (!checkSystemUser.phone) {
    throw new AppError(StatusCodes.NOT_FOUND,"Here are Phone Number Require ")
  }
  
  return prisma.$transaction(async (tx) => {
    const business = await tx.business.create({
      data: payload.business
    });
    const branch = await tx.branch.create({
      data: {
        Brance_name: "Main Branch",
        businessId: business.id,
        branch_code: "BR00",

      }
    })
    const businessOwner = await tx.employee.create({
      data: {
        businessId: business.id,
        Employee_jobTitle: EMPLOYEE_JOB_TITLE.OWNER,
        userId: checkSystemUser.id,
        employeeCode: "EMP00",
        Employee_name: checkSystemUser.name,
        Employee_phone: checkSystemUser.phone as string,
        Employee_email: checkSystemUser.email,
        Employee_baseSalary:"0.00"
        
      }
    })
    const employeeBrannch = await tx.employeeBranch.create({
      data: {
        businessId: business.id,
        employeeId: businessOwner.Employee_id,
        branchId:branch.id
      }
    })
    return {
      business,
      branch,
      businessOwner,
      employeeBrannch
  }
  })


}

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
    data:(payload)
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
        { Business_name: textMatch },
        { Business_phone: textMatch },
        { Business_email: textMatch },
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
