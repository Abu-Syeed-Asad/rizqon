import { Router } from "express";
import { SYSTEM_USER_ROLE } from "../../../prisma/generated/prisma/enums.js";
import auth_Checker from "../../middleware/auth_Check.js";
import { validateBody } from "../../middleware/validateBody.js";
import { validateParams } from "../../middleware/validateParams.js";
import { categoryValidation } from "./category.validation.js";
import { categoryController } from "./category.controller.js";

const router = Router();

router.post(
  "/create-category",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  validateBody(categoryValidation.createCategorySchema),
  categoryController.createCategory,
);

router.get(
  "/get-all-categories",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  categoryController.getAllCategories,
);

router.patch(
  "/update-category/:id",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  validateParams(categoryValidation.categoryParamsSchema),
  validateBody(categoryValidation.updateCategorySchema),
  categoryController.updateCategory,
);

router.delete(
  "/delete-category/:id",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  validateParams(categoryValidation.categoryParamsSchema),
  categoryController.deleteCategory,
);

router.get(
  "/get-category/:id",
  auth_Checker(
    SYSTEM_USER_ROLE.RIZQON_CEO,
    SYSTEM_USER_ROLE.RIZQON_MANAGER,
    SYSTEM_USER_ROLE.RIZQON_OWNER
  ),
  validateParams(categoryValidation.categoryParamsSchema),
  categoryController.getCategoryById,
);

export const categoryRoutes = router;


