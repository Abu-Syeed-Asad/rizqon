import type { Request, Response } from "express";
import { StatusCodes } from "http-status-codes";
import { catchAsync, send_Response } from "../../utils/asyncHandlerOrsendResponse.js";
import { brandService } from "./brand.service.js";
import type { BrandParams, CreateBrandInput, UpdateBrandInput } from "./brand.validation.js";

// Authentication, authorization and request validation run in the router.
const createBrand = catchAsync(async (
  req: Request<Record<string, string>, unknown, CreateBrandInput>,
  res: Response,
) => {
  const result = await brandService.createBrand(req.body);
  send_Response(res, {
    statusCode: StatusCodes.CREATED,
    message: "Brand created successfully",
    data: result,
  });
});

const updateBrand = catchAsync(async (
  req: Request<BrandParams, unknown, UpdateBrandInput>,
  res: Response,
) => {
  const result = await brandService.updateBrand(req.params, req.body);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Brand updated successfully",
    data: result,
  });
});

const deleteBrand = catchAsync(async (req: Request<BrandParams>, res: Response) => {
  const result = await brandService.deleteBrand(req.params);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Brand deleted successfully",
    data: result,
  });
});

const getAllBrands = catchAsync(async (_req: Request, res: Response) => {
  const result = await brandService.getAllBrands();
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Brands retrieved successfully",
    data: result,
  });
});

export const brandController = { createBrand, updateBrand, deleteBrand, getAllBrands };
