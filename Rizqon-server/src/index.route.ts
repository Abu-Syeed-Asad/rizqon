import { Router } from "express";
import { authRouter } from "./module/auth/auth.route";
import { businessRoutes } from "./module/bussiness/bussiness.route";

const router = Router();
router.use("/auth", authRouter);
router.use("/business",businessRoutes)

export const index_router:Router = router;
