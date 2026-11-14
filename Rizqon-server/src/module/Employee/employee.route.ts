import { Router } from "express";
import auth_Checker from "../../middleware/auth_Check.js";
import { validateBody } from "../../middleware/validateBody.js";
import { validateParams } from "../../middleware/validateParams.js";
import { employeeController } from "./employee.controller.js";
import { employeeValidation } from "./employee.validation.js";

const router = Router();

router.post(
  "/create-employee",
  auth_Checker(),
  validateBody(employeeValidation.createEmployeeSchema),
  employeeController.createEmployee,
);

router.get(
  "/get-all-employees/:businessId",
  auth_Checker(),
  validateParams(employeeValidation.businessParamsSchema),
  employeeController.getAllEmployees,
);

router.get(
  "/get-employee/:businessId/:id",
  auth_Checker(),
  validateParams(employeeValidation.employeeParamsSchema),
  employeeController.getEmployee,
);

router.patch(
  "/update-employee/:businessId/:id",
  auth_Checker(),
  validateParams(employeeValidation.employeeParamsSchema),
  validateBody(employeeValidation.updateEmployeeSchema),
  employeeController.updateEmployee,
);

router.delete(
  "/delete-employee/:businessId/:id",
  auth_Checker(),
  validateParams(employeeValidation.employeeParamsSchema),
  employeeController.deleteEmployee,
);

export const employeeRoutes = router;
