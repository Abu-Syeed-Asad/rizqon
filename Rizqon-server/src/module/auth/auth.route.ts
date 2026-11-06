import { Router } from "express";
import { authController } from "./auth.controller.js";

const router = Router();

router.post("/create-user", authController.createUser);
router.post("/sign-in-user", authController.signInUser);
router.post("/verify-email", authController.verifyEmailWithOtp);
router.post("/send-verification-otp", authController.sendVerificationOtp);
router.post("/sign-out-user", authController.signOutUser);

export const authRouter: Router = router;
