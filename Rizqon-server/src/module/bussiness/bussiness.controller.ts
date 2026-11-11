import type {  Request, Response } from "express";
import { catchAsync } from "../../utils/asyncHandlerOrsendResponse";
import { StatusCodes } from "http-status-codes";
import { businessService } from "./business.service";

const createBusiness = catchAsync(async (
  req: Request,
  res: Response,
) => {
    const result = await businessService.createBusiness(req.body);
    res.status(201).json({
      success: true,
      statusCode: 201,
      message: "Business created successfully",
      data: result,
    });
 
});

const updateBusiness = catchAsync(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const result = await businessService.updateBusiness(id, req.body);
  res.status(StatusCodes.OK).json({
    success: true,
    statusCode: StatusCodes.OK,
    message: "Business updated successfully",
    data: result,
  });
});

const deleteBusiness = catchAsync(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const result = await businessService.deleteBusiness(id);
  res.status(StatusCodes.OK).json({
    success: true,
    statusCode: StatusCodes.OK,
    message: "Business deleted successfully",
    data: result,
  });
});

const getAllBusiness = catchAsync(async (_req: Request, res: Response) => {
  const result = await businessService.getAllBusiness();
  res.status(StatusCodes.OK).json({
    success: true,
    statusCode: StatusCodes.OK,
    message: "Businesses retrieved successfully",
    data: result,
  });
});

const searchBusiness = catchAsync(async (_req: Request, res: Response) => {
  const result = await businessService.searchBusiness(res.locals.validatedQuery);
  res.status(StatusCodes.OK).json({
    success: true,
    statusCode: StatusCodes.OK,
    message: "Businesses retrieved successfully",
    data: result,
  });
});

export const businessController = {
  searchBusiness,
  getAllBusiness,
  createBusiness,
  updateBusiness,
  deleteBusiness,
};
