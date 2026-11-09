import { Router } from "express";
import { authRouter } from "./module/auth/auth.route";
import { businessRoutes } from "./module/bussiness/bussiness.route";
import { brandRoutes } from "./module/Brand/brand.route.js";
import { branchRoutes } from "./module/branch/branch.route.js";
import { categoryRoutes } from "./module/Product-Category/category.route.js";

const router = Router();
router.use("/auth", authRouter);
router.use("/business",businessRoutes)
router.use("/brand", brandRoutes);
router.use("/branch", branchRoutes);
router.use("/category", categoryRoutes);

export const index_router:Router = router;
