import { Router } from "express";
import { SYSTEM_USER_ROLE } from "../../../prisma/generated/prisma/enums.js";
import auth_Checker from "../../middleware/auth_Check.js";
import { validateBody } from "../../middleware/validateBody.js";
import { validateParams } from "../../middleware/validateParams.js";
import { partnerValidation } from "./partner.validation.js";
import { partnerController } from "./partner.controller.js";

const router = Router();

router.use(auth_Checker(
  SYSTEM_USER_ROLE.RIZQON_CEO,
  SYSTEM_USER_ROLE.RIZQON_OWNER,
));

router.post("/create-partner", validateBody(partnerValidation.createPartnerSchema), partnerController.createPartner);
router.get("/get-all-partners", partnerController.getAllPartners);
router.get("/get-partner/:id", validateParams(partnerValidation.partnerParamsSchema), partnerController.getPartner);
router.patch("/update-partner/:id", validateParams(partnerValidation.partnerParamsSchema), validateBody(partnerValidation.updatePartnerSchema), partnerController.updatePartner);
router.delete("/delete-partner/:id", validateParams(partnerValidation.partnerParamsSchema), partnerController.deletePartner);

export const partnerRoutes = router;
