import { Router } from "express";
import { SYSTEM_USER_ROLE } from "../../../prisma/generated/prisma/enums.js";
import auth_Checker from "../../middleware/auth_Check.js";
import { validateBody } from "../../middleware/validateBody.js";
import { validateParams } from "../../middleware/validateParams.js";
import { branchValidation } from "./branch.validation.js";
import { branchController } from "./branch.controller.js";

const router = Router();

router.post(
  "/create-branch",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  validateBody(branchValidation.createBranchSchema),
  branchController.createBranch,
);

router.get(
  "/get-all-branches",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  branchController.getAllBranches,
);

router.patch(
  "/update-branch/:id",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  validateParams(branchValidation.branchParamsSchema),
  validateBody(branchValidation.updateBranchSchema),
  branchController.updateBranch,
);

router.delete(
  "/delete-branch/:id",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  validateParams(branchValidation.branchParamsSchema),
  branchController.deleteBranch,
);

export const branchRoutes = router;

