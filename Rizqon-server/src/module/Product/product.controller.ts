import type { Request, Response } from "express";
import { StatusCodes } from "http-status-codes";
import { catchAsync, send_Response } from "../../utils/asyncHandlerOrsendResponse.js";
import { productService } from "./product.service.js";
import type { BranchParams, ProductMutationParams, DeleteProductInput, ProductParams, CreateProductInput, UpdateProductInput } from "./product.validation.js";

const createProduct = catchAsync(async (req: Request<BranchParams, unknown, CreateProductInput>, res: Response) => {
  const result = await productService.createProduct(res.locals.user, req.params, req.body);
  send_Response(res, {
    statusCode: StatusCodes.CREATED,
    message: "Product created successfully",
    data: result,
  });
});

const updateProduct = catchAsync(async (req: Request<ProductMutationParams, unknown, UpdateProductInput>, res: Response) => {
  const result = await productService.updateProduct(res.locals.user, req.params, req.body);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Product updated successfully",
    data: result,
  });
});

const deleteProduct = catchAsync(async (req: Request<ProductMutationParams, unknown, DeleteProductInput>, res: Response) => {
  const result = await productService.deleteProduct(res.locals.user, req.params, req.body);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Product deleted successfully",
    data: result,
  });
});

const getProduct = catchAsync(async (req: Request<ProductParams>, res: Response) => {
  const result = await productService.getProduct(req.params);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Product retrieved successfully",
    data: result,
  });
});

const getAllProducts = catchAsync(async (_req: Request, res: Response) => {
  const result = await productService.getAllProducts();
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Products retrieved successfully",
    data: result,
  });
});

export const productController = { createProduct, updateProduct, deleteProduct, getProduct, getAllProducts };
