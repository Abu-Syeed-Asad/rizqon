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
  if (!id?.trim()) {
    throw new AppError(StatusCodes.BAD_REQUEST, "Business id is required");
  }
  const { owner, ...businessData } = payload;

  return prisma.$transaction(async (tx) => {
    const business = await tx.business.findUnique({ where: { id } });
    if (!business) {
      throw new AppError(StatusCodes.NOT_FOUND, "Business not found");
    }

    if (owner) {
      const owners = await tx.employee.findMany({
        where: { businessId: id, Employee_jobTitle: EMPLOYEE_JOB_TITLE.OWNER },
        select: { Employee_id: true },
        take: 2,
      });
      const existingOwner = owners[0];
      if (!existingOwner) {
        throw new AppError(StatusCodes.NOT_FOUND, "Owner not found for this business");
      }
      if (owners.length > 1) {
        throw new AppError(StatusCodes.CONFLICT, "Multiple owners found for this business");
      }
      const employeeWhere = {
        Employee_id: existingOwner.Employee_id,
        businessId: id,
        Employee_jobTitle: EMPLOYEE_JOB_TITLE.OWNER,
      };
      const checkSystemUser = await tx.user.findUnique({
        where: { email: owner.Employee_email },
      });
      if (!checkSystemUser) {
        throw new AppError(StatusCodes.NOT_FOUND, "This email user does not exist in our system");
      }
      if (!checkSystemUser.phone) {
        throw new AppError(StatusCodes.BAD_REQUEST, "The system user must have a phone number");
      }
      const linkedEmployee = await tx.employee.findUnique({
        where: { businessId_userId: { businessId: id, userId: checkSystemUser.id } },
      });
      if (linkedEmployee && linkedEmployee.Employee_id !== existingOwner.Employee_id) {
        throw new AppError(StatusCodes.CONFLICT, "This user is already an employee of this business");
      }
      await tx.employee.update({
        where: employeeWhere,
        data: {
          userId: checkSystemUser.id,
          Employee_name: checkSystemUser.name,
          Employee_phone: checkSystemUser.phone,
          Employee_email: checkSystemUser.email,
        },
      });
    }

    return Object.values(businessData).some((value) => value !== undefined)
      ? tx.business.update({ where: { id }, data: businessData })
      : business;
  });
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
