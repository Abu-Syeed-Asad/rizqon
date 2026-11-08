import { Router } from "express";
import { authController } from "./auth.controller.js";
import { validateBody } from "../../middleware/validateBody.js";
import { authValidation } from "./auth.validation.js";
import auth_Checker from "../../middleware/auth_Check.js";

const router = Router();

router.post("/create-user", validateBody(authValidation.createUser), authController.createUser);
router.post("/sign-in-user", validateBody(authValidation.signInUser), authController.signInUser);
router.post("/verify-email", validateBody(authValidation.verifyEmailWithOtp), authController.verifyEmailWithOtp);
router.post("/send-verification-otp", validateBody(authValidation.sendVerificationOtp), authController.sendVerificationOtp);
router.post("/sign-out-user", validateBody(authValidation.signOutUser), authController.signOutUser);
router.post("/forgot-password", validateBody(authValidation.forgotPassword), authController.forgotPassword);
router.post("/reset-password", validateBody(authValidation.resetPasswordWithOtp), authController.resetPasswordWithOtp);
router.post("/change-password", validateBody(authValidation.changePassword), authController.changePassword);
router.get("/get-session-user", authController.getSessionUser);


router.get("/sign-in-google-account", authController.signInWithGoogleAccount);


router.post("/sign-in-google-account", validateBody(authValidation.signInWithGoogleAccount), 
authController.signInWithGoogleAccount);
router.get("/complete-google-sign-in", authController.completeGoogleSignIn);
router.post("/complete-google-sign-in", validateBody(authValidation.completeGoogleSignIn), authController.completeGoogleSignIn);
router.get("/google-sign-in-error", authController.googleSignInError);  

router.get("/me",auth_Checker(),authController.getProfile)


export const authRouter: Router = router;
