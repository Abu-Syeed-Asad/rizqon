import { Router } from "express";
import auth_Checker from "../../middleware/auth_Check.js";
import { validateBody } from "../../middleware/validateBody.js";
import { emptySchema } from "./commission.validation.js";
import { commissionController as c } from "./commission.controller.js";

const router = Router({ mergeParams: true });
router.use(auth_Checker());
// Services validate payloads and authorize the authenticated user against tenant employee records.
// No client businessId, employeeId, commission amount, status, or timestamps are trusted.
router.post("/commission-agreements", c.createAgreement);
router.get("/commission-agreements", c.listAgreements);
router.get("/commission-agreements/:id/history", c.history);
router.get("/commission-agreements/:id", c.getAgreement);
router.patch("/commission-agreements/:id", c.updateAgreement);
for (const action of ["activate", "deactivate", "expire"] as const) {
  router.post(`/commission-agreements/:id/${action}`, validateBody(emptySchema), c.agreementAction(action));
}
router.get("/commission-entries", c.listEntries);
router.get("/commission-entries/:id", c.getEntry);
router.post("/commission-settlements", c.createSettlement);
router.get("/commission-settlements", c.listSettlements);
router.get("/commission-settlements/:id", c.getSettlement);
router.patch("/commission-settlements/:id", c.updateSettlement);
for (const action of ["finalize", "cancel"] as const) {
  router.post(`/commission-settlements/:id/${action}`, validateBody(emptySchema), c.settlementAction(action));
}
router.post("/commission-settlements/:id/payments", c.createPayment);
router.get("/commission-settlements/:id/payments", c.listPayments);
router.post("/commission-settlements/:id/payments/:paymentId/reconcile", c.reconcilePayment);
router.post("/sales/:id/complete", validateBody(emptySchema), c.completeSale);
router.post("/sale-returns", c.createReturn);
for (const action of ["approve", "reject", "complete"] as const) {
  router.post(`/sale-returns/:id/${action}`, validateBody(emptySchema), c.returnAction(action));
}
export const commissionRoutes = router;
