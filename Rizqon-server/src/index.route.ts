import { Router } from "express";
import { authRouter } from "./module/auth/auth.route";
import { businessRoutes } from "./module/bussiness/bussiness.route";
import { brandRoutes } from "./module/Brand/brand.route.js";

const router = Router();
router.use("/auth", authRouter);
router.use("/business",businessRoutes)
router.use("/brand", brandRoutes);

export const index_router:Router = router;
