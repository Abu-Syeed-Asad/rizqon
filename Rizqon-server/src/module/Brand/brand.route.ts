import { Router } from "express";
import { SYSTEM_USER_ROLE } from "../../../prisma/generated/prisma/enums.js";
import auth_Checker from "../../middleware/auth_Check.js";
import { validateBody } from "../../middleware/validateBody.js";
import { validateParams } from "../../middleware/validateParams.js";
import { brandValidation } from "./brand.validation.js";
import { brandController } from "./brand.controller.js";

const router = Router();

router.post(
  "/create-brand",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  validateBody(brandValidation.createBrandSchema),
  brandController.createBrand,
);

router.get(
  "/get-all-brands",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  brandController.getAllBrands,
);

router.patch(
  "/update-brand/:id",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  validateParams(brandValidation.brandParamsSchema),
  validateBody(brandValidation.updateBrandSchema),
  brandController.updateBrand,
);

router.delete(
  "/delete-brand/:id",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  validateParams(brandValidation.brandParamsSchema),
  brandController.deleteBrand,
);

export const brandRoutes = router;
