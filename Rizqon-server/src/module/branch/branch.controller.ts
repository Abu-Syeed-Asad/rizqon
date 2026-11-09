import type { Request, Response } from "express";
import { StatusCodes } from "http-status-codes";
import { catchAsync, send_Response } from "../../utils/asyncHandlerOrsendResponse.js";
import { branchService } from "./branch.service.js";
import type { BranchParams, CreateBranchInput, UpdateBranchInput } from "./branch.validation.js";

// Authentication, authorization and request validation run in the router.
const createBranch = catchAsync(async (
  req: Request<Record<string, string>, unknown, CreateBranchInput>,
  res: Response,
) => {
  const result = await branchService.createBranch(req.body);
  send_Response(res, {
    statusCode: StatusCodes.CREATED,
    message: "Branch created successfully",
    data: result,
  });
});

const updateBranch = catchAsync(async (
  req: Request<BranchParams, unknown, UpdateBranchInput>,
  res: Response,
) => {
  const result = await branchService.updateBranch(req.params, req.body);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Branch updated successfully",
    data: result,
  });
});

const deleteBranch = catchAsync(async (req: Request<BranchParams>, res: Response) => {
  const result = await branchService.deleteBranch(req.params);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Branch deleted successfully",
    data: result,
  });
});

const getAllBranches = catchAsync(async (_req: Request, res: Response) => {
  const result = await branchService.getAllBranches();
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Branches retrieved successfully",
    data: result,
  });
});

export const branchController = { createBranch, updateBranch, deleteBranch, getAllBranches };

