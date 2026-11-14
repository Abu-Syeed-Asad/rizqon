import type { Request, Response } from "express";
import { StatusCodes } from "http-status-codes";
import { catchAsync, send_Response } from "../../utils/asyncHandlerOrsendResponse.js";
import { employeeService } from "./employee.service.js";
import type {
  BusinessParams,
  CreateEmployeeInput,
  EmployeeParams,
  UpdateEmployeeInput,
} from "./employee.validation.js";

const createEmployee = catchAsync(async (
  req: Request<Record<string, string>, unknown, CreateEmployeeInput>,
  res: Response,
) => {
  const result = await employeeService.createEmployee(res.locals.user, req.body);
  send_Response(res, {
    statusCode: StatusCodes.CREATED,
    message: "Employee created successfully",
    data: result,
  });
});

const getAllEmployees = catchAsync(async (req: Request<BusinessParams>, res: Response) => {
  const result = await employeeService.getAllEmployees(res.locals.user, req.params);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Employees retrieved successfully",
    data: result,
  });
});

const getEmployee = catchAsync(async (req: Request<EmployeeParams>, res: Response) => {
  const result = await employeeService.getEmployee(res.locals.user, req.params);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Employee retrieved successfully",
    data: result,
  });
});

const updateEmployee = catchAsync(async (
  req: Request<EmployeeParams, unknown, UpdateEmployeeInput>,
  res: Response,
) => {
  const result = await employeeService.updateEmployee(res.locals.user, req.params, req.body);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Employee updated successfully",
    data: result,
  });
});

const deleteEmployee = catchAsync(async (req: Request<EmployeeParams>, res: Response) => {
  const result = await employeeService.deleteEmployee(res.locals.user, req.params);
  send_Response(res, {
    statusCode: StatusCodes.OK,
    message: "Employee deleted successfully",
    data: result,
  });
});

export const employeeController = {
  createEmployee,
  getAllEmployees,
  getEmployee,
  updateEmployee,
  deleteEmployee
};
