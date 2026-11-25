import { Router } from "express";
import { paymentRoutes, paymentCallbackRoutes } from "./module/Payment/payment.route.js";
import { commissionRoutes } from "./module/Commission/commission.route.js";
import { productRoutes } from "./module/Product/product.route.js";
import { authRouter } from "./module/auth/auth.route";
import { businessRoutes } from "./module/bussiness/bussiness.route";
import { brandRoutes } from "./module/Brand/brand.route.js";
import { branchRoutes } from "./module/branch/branch.route.js";
import { categoryRoutes } from "./module/Product-Category/category.route.js";
import { employeeRoutes } from "./module/Employee/employee.route.js";
import { partnerRoutes } from "./module/Partner/partner.route.js";

const router = Router();
router.use("/payments", paymentCallbackRoutes);
router.use("/business/:businessId", paymentRoutes);
router.use("/business/:businessId", commissionRoutes);
router.use("/product", productRoutes);
router.use("/auth", authRouter);
router.use("/business",businessRoutes)
router.use("/brand", brandRoutes);
router.use("/branch", branchRoutes);
router.use("/category", categoryRoutes);
router.use("/employee", employeeRoutes);
router.use("/partner", partnerRoutes);

export const index_router:Router = router;
