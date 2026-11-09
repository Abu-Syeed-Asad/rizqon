import type { Request, Response } from "express";
import { StatusCodes } from "http-status-codes";
import { catchAsync, send_Response } from "../../utils/asyncHandlerOrsendResponse.js";
import { categoryService } from "./category.service.js";
import type { CategoryParams, CreateCategoryInput, UpdateCategoryInput } from "./category.validation.js";

// Authentication, authorization and request validation run in the router.
const createCategory = catchAsync(async (
  req: Request<Record<string, string>, unknown, CreateCategoryInput>,
  res: Response,
) => {
  const result = await categoryService.createCategory(req.body);
  send_Response(res, {
    statusCode: StatusCodes.CREATED,
    message: "Category created successfully",
    data: result,
  });
});

const updateCategory = catchAsync(async (
  req: Request<CategoryParams, unknown, UpdateCategoryInput>,
  res: Response,
) => {
  const result = await categoryService.updateCategory(req.params, req.body);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Category updated successfully",
    data: result,
  });
});

const deleteCategory = catchAsync(async (req: Request<CategoryParams>, res: Response) => {
  const result = await categoryService.deleteCategory(req.params);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Category deleted successfully",
    data: result,
  });
});

const getAllCategories = catchAsync(async (_req: Request, res: Response) => {
  const result = await categoryService.getAllCategories();
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Categories retrieved successfully",
    data: result,
  });
});

const getCategoryById = catchAsync(async (req: Request<CategoryParams>, res: Response) => {
  const result = await categoryService.getCategoryById(req.params);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Category retrieved successfully",
    data: result,
  });
});

export const categoryController = { createCategory, updateCategory, deleteCategory, getAllCategories, getCategoryById };


