import express, { Router } from "express";
import { authController } from "./auth.controller.js";

const router = Router();

router.post("/create-user", authController.createUser);
router.post("/verify-email", authController.verifyEmailWithOtp);

export const authRouter: Router = router;
