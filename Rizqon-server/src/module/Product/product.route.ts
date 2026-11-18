import { Router } from "express";
import auth_Checker from "../../middleware/auth_Check.js";
import { validateBody } from "../../middleware/validateBody.js";
import { validateParams } from "../../middleware/validateParams.js";
import { productController } from "./product.controller.js";
import { productValidation } from "./product.validation.js";

const router = Router();
router.get("/get-all-products", productController.getAllProducts);
router.get("/get-product/:id",
  validateParams(productValidation.productParamsSchema),
  productController.getProduct,
);

router.use(auth_Checker());
router.post("/create-product/:branchId",
  validateParams(productValidation.branchParamsSchema),
  validateBody(productValidation.createProductSchema),
  productController.createProduct,
);
router.patch("/update-product/:branchId/:id",
  validateParams(productValidation.mutationParamsSchema),
  validateBody(productValidation.updateProductSchema),
  productController.updateProduct,
);
router.delete("/delete-product/:branchId/:id",
  validateParams(productValidation.mutationParamsSchema),
  validateBody(productValidation.deleteProductSchema),
  productController.deleteProduct,
);
export const productRoutes = router;
