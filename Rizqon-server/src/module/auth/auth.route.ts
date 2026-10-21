import express, { Router } from "express";
import { authController } from "./auth.controller.js";

const router = Router();


router.post("/create-user",authController.createUser,
);


export const authRouter: Router = router;
