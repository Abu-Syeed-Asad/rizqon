import { Router } from "express";
import auth_Checker from "../../middleware/auth_Check";
import { SYSTEM_USER_ROLE } from "../../../prisma/generated/prisma/enums";
import { bussinessValidation } from "./business.validaton";
import { validateBody } from "../../middleware/validateBody";
import { validateParams } from "../../middleware/validateParams";
import { validateQuery } from "../../middleware/validateQuery";
import { businessController } from "./bussiness.controller";

const router = Router();

router.get(
  "/search-business",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  validateQuery(bussinessValidation.searchBusinessSchema),
  businessController.searchBusiness
);

router.get(
  "/get-all-business",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  businessController.getAllBusiness
);

router.post(
  "/create-business",
  auth_Checker(SYSTEM_USER_ROLE.RIZQON_CEO ,SYSTEM_USER_ROLE.RIZQON_MANAGER,SYSTEM_USER_ROLE.RIZQON_OWNER),
  validateBody(bussinessValidation.createBusinessSchema),
  businessController.createBusiness
);

router.patch(
  "/update-business/:id",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  validateBody(bussinessValidation.updateBusinessSchema),
  validateParams(bussinessValidation.businessParamsSchema),
  businessController.updateBusiness,
);

router.delete(
  "/delete-business/:id",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  validateParams(bussinessValidation.businessParamsSchema),
  businessController.deleteBusiness,
);

export const businessRoutes = router;
