import { Router } from "express";
import { authRouter } from "./module/auth/auth.route";

const router = Router();
router.use("/auth", authRouter);

export const index_router:Router = router;
